//! HTTP/1.1 server on std.http: one concurrent task per connection, keep-alive, per-request arena.
//! Request order: built-in assets (/_zw/*) -> routes -> public files -> 404.
const std = @import("std");
const Io = std.Io;
const http = std.http;
const log = std.log.scoped(.zigworks);
const Ctx = @import("ctx.zig").Ctx;
const router = @import("router.zig");
const static = @import("static.zig");
const client = @import("client.zig");
const css = @import("css.zig");

pub const Options = struct {
    /// Every interface, so apps are reachable on the LAN. "127.0.0.1" keeps an app local.
    /// Overridden by the HOST environment variable.
    host: []const u8 = "0.0.0.0",
    /// Overridden by the PORT environment variable.
    port: u16 = 8080,
    /// Directory served as static files at "/". Null disables it.
    public: ?[]const u8 = "public",
    /// Request bodies larger than this get 413.
    max_body: usize = 1 << 20,
};

const State = struct {
    io: Io,
    gpa: std.mem.Allocator,
    opts: Options,
    public: ?Io.Dir,
};

/// Serves `app` until the process exits.
/// `app`: `.{ .routes = .{ .{ "GET /", index }, ... }, .tokens = .{...}, .css = "..." }`.
/// `tokens`, `css` (app styles, appended to /_zw/zw.css) and `not_found` (a handler run with
/// status 404 when no route or static file answered) are optional.
pub fn serve(init: std.process.Init, comptime app: anytype, options: Options) !void {
    const io = init.io;
    var opts = options;
    if (init.environ_map.get("HOST")) |h| opts.host = h;
    if (init.environ_map.get("PORT")) |p| opts.port = std.fmt.parseInt(u16, p, 10) catch return error.InvalidPort;

    const public: ?Io.Dir = if (opts.public) |p| Io.Dir.cwd().openDir(io, p, .{}) catch |err| switch (err) {
        error.FileNotFound => null,
        else => return err,
    } else null;
    defer if (public) |d| d.close(io);

    const address = try Io.net.IpAddress.parse(opts.host, opts.port);
    var listener = try address.listen(io, .{ .reuse_address = true });
    defer listener.socket.close(io);
    log.info("listening on http://{s}:{d}", .{ opts.host, listener.socket.address.getPort() });

    const state: State = .{ .io = io, .gpa = init.gpa, .opts = opts, .public = public };
    var group: Io.Group = .init;
    defer group.cancel(io);
    while (true) {
        const stream = listener.accept(io) catch |err| switch (err) {
            error.Canceled => return,
            else => {
                log.err("accept: {t}", .{err});
                continue;
            },
        };
        // ponytail: unbounded tasks, no idle timeout; put a reverse proxy in front on the open internet.
        group.concurrent(io, Connection(app).run, .{ &state, stream }) catch {
            stream.close(io);
        };
    }
}

fn Connection(comptime app: anytype) type {
    return struct {
        fn run(state: *const State, stream: Io.net.Stream) void {
            connection(app, state, stream);
        }
    };
}

fn connection(comptime app: anytype, state: *const State, stream: Io.net.Stream) void {
    const io = state.io;
    defer stream.close(io);
    var recv: [16 * 1024]u8 = undefined;
    var send: [16 * 1024]u8 = undefined;
    var r = stream.reader(io, &recv);
    var w = stream.writer(io, &send);
    var server = http.Server.init(&r.interface, &w.interface);
    requests(app, state, &server);
}

/// Answers requests until the connection closes or fails.
fn requests(comptime app: anytype, state: *const State, server: *http.Server) void {
    var arena: std.heap.ArenaAllocator = .init(state.gpa);
    defer arena.deinit();
    while (server.reader.state == .ready) {
        // Bounded so one large static file doesn't pin its memory for the whole keep-alive connection.
        _ = arena.reset(.{ .retain_with_limit = 256 * 1024 });
        var req = server.receiveHead() catch |err| switch (err) {
            error.HttpConnectionClosing => return,
            error.HttpHeadersOversize => {
                server.out.writeAll("HTTP/1.1 431 Request Header Fields Too Large\r\nconnection: close\r\ncontent-length: 0\r\n\r\n") catch {};
                server.out.flush() catch {};
                return log.debug("closing connection: {t}", .{err});
            },
            else => return log.debug("closing connection: {t}", .{err}),
        };
        handle(app, state, arena.allocator(), &req) catch |err| {
            return log.debug("closing connection: {t}", .{err});
        };
    }
}

fn handle(comptime app: anytype, state: *const State, arena: std.mem.Allocator, req: *http.Server.Request) !void {
    const target = try arena.dupe(u8, req.head.target);
    const path, const query = std.mem.cutScalar(u8, target, '?') orelse .{ target, "" };
    var c: Ctx = .{
        .io = state.io,
        .arena = arena,
        .req = req,
        .method = req.head.method,
        .path = path,
        .raw_query = query,
        .head = try arena.dupe(u8, req.head_buffer),
    };
    if (req.head.method.requestHasBody()) {
        if ((req.head.content_length orelse 0) > state.opts.max_body) return tooLarge(&c);
        var buf: [4096]u8 = undefined;
        const body = if (req.head.expect != null) try req.readerExpectContinue(&buf) else req.readerExpectNone(&buf);
        c.body = body.allocRemaining(arena, .limited(state.opts.max_body)) catch |err| switch (err) {
            error.StreamTooLong => return tooLarge(&c),
            else => return err,
        };
    }
    route(app, state, &c) catch |err| {
        if (err == error.WriteFailed) return err;
        log.warn("{t} {s}: {t}", .{ c.method, c.path, err }); // warn: the test runner fails on err logs
        if (!c.responded) try c.send(.internal_server_error, "text/plain", "internal server error");
    };
    if (!c.responded) try c.send(.no_content, "text/plain", "");
    log.info("{t} {s} {d}", .{ c.method, c.path, @intFromEnum(c.status) });
}

fn route(comptime app: anytype, state: *const State, c: *Ctx) !void {
    if (std.mem.eql(u8, c.path, "/_zw/z.js")) return asset(c, "text/javascript; charset=utf-8", client.js);
    if (std.mem.eql(u8, c.path, "/_zw/zw.css")) {
        const tokens: css.Tokens = if (@hasField(@TypeOf(app), "tokens")) app.tokens else .{};
        const extra: []const u8 = if (@hasField(@TypeOf(app), "css")) app.css else "";
        return asset(c, "text/css; charset=utf-8", comptime css.build(tokens) ++ extra);
    }
    if (try router.dispatch(app.routes, c)) return;
    if (state.public) |dir| if (try static.serve(c, dir)) return;
    c.status = .not_found;
    if (@hasField(@TypeOf(app), "not_found")) {
        try app.not_found(c);
        if (c.responded) return;
    }
    try c.send(.not_found, "text/plain", "not found");
}

/// Revalidated on every use (no-cache) but answered with 304 while the ETag matches.
fn asset(c: *Ctx, content_type: []const u8, comptime body: []const u8) !void {
    const etag = comptime etag: {
        @setEvalBranchQuota(1_000_000); // Wyhash over ~45 KB at comptime
        break :etag std.fmt.comptimePrint("\"{x}\"", .{std.hash.Wyhash.hash(0, body)});
    };
    try c.setHeader("cache-control", "no-cache");
    try c.setHeader("etag", etag);
    if (std.mem.eql(u8, c.header("if-none-match") orelse "", etag)) return c.send(.not_modified, content_type, "");
    try c.send(.ok, content_type, body);
}

/// Answers 413 and closes the connection (the unread body makes it unusable).
fn tooLarge(c: *Ctx) !void {
    c.status = .payload_too_large;
    c.responded = true;
    try c.req.respond("request body too large", .{ .status = .payload_too_large, .keep_alive = false });
    return error.BodyTooLarge;
}

/// Runs `raw` (one or more requests) through the request loop without sockets; returns the raw responses.
fn testServe(comptime app: anytype, raw: []const u8) ![]u8 {
    // Read through a 16 KiB buffer like a real connection, so oversized heads fail the same way.
    var src: Io.Reader = .fixed(raw);
    var recv: [16 * 1024]u8 = undefined;
    var in = src.limited(.unlimited, &recv);
    var out: Io.Writer.Allocating = .init(std.testing.allocator);
    defer out.deinit();
    var server = http.Server.init(&in.interface, &out.writer);
    const state: State = .{ .io = std.testing.io, .gpa = std.testing.allocator, .opts = .{ .public = null, .max_body = 16 }, .public = null };
    requests(app, &state, &server);
    return out.toOwnedSlice();
}

const test_app = .{
    .routes = .{
        .{ "GET /hello/:name", struct {
            fn h(c: *Ctx) !void {
                try c.text(c.param("name").?);
            }
        }.h },
        .{ "GET /:page", struct {
            fn h(c: *Ctx) !void {
                c.pass();
            }
        }.h },
        .{ "GET /boom", struct {
            fn h(_: *Ctx) !void {
                return error.Boom;
            }
        }.h },
        .{ "POST /nothing", struct {
            fn h(_: *Ctx) !void {}
        }.h },
        .{ "GET /go", struct {
            fn h(c: *Ctx) !void {
                try c.redirect("/there");
            }
        }.h },
    },
};

fn expectResponse(res: []const u8, status_line: []const u8, body: []const u8) !void {
    try std.testing.expectStringStartsWith(res, status_line);
    try std.testing.expectStringEndsWith(res, body);
    try std.testing.expectStringEndsWith(res[0 .. res.len - body.len], "\r\n\r\n");
}

test "404, route params, pass, 500, 204" {
    const cases = [_]struct { []const u8, []const u8, []const u8 }{
        .{ "GET /nope/x HTTP/1.1\r\n\r\n", "HTTP/1.1 404 Not Found\r\n", "not found" },
        .{ "GET /hello/w%C3%B6rld HTTP/1.1\r\n\r\n", "HTTP/1.1 200 OK\r\n", "w\xc3\xb6rld" },
        .{ "GET /about HTTP/1.1\r\n\r\n", "HTTP/1.1 404 Not Found\r\n", "not found" },
        .{ "GET /boom HTTP/1.1\r\n\r\n", "HTTP/1.1 500 Internal Server Error\r\n", "internal server error" },
        .{ "POST /nothing HTTP/1.1\r\ncontent-length: 2\r\n\r\nok", "HTTP/1.1 204 No Content\r\n", "" },
    };
    // /boom's 500 logs a warning on purpose; keep it out of the test output.
    std.testing.log_level = .err;
    defer std.testing.log_level = .warn;
    for (cases) |case| {
        const res = try testServe(test_app, case[0]);
        defer std.testing.allocator.free(res);
        try expectResponse(res, case[1], case[2]);
    }
}

test "oversized request head gets 431" {
    const long: [20_000]u8 = @splat('x');
    const res = try testServe(test_app, "GET /?q=" ++ long ++ " HTTP/1.1\r\n\r\n");
    defer std.testing.allocator.free(res);
    try std.testing.expect(std.mem.startsWith(u8, res, "HTTP/1.1 431 "));
}

test "HEAD on a GET route sends headers only" {
    const res = try testServe(test_app, "HEAD /hello/abc HTTP/1.1\r\n\r\n");
    defer std.testing.allocator.free(res);
    try expectResponse(res, "HTTP/1.1 200 OK\r\n", "");
    try std.testing.expect(std.mem.find(u8, res, "content-length: 3\r\n") != null);
}

test "body above max_body gets 413 and closes" {
    const res = try testServe(test_app, "POST /nothing HTTP/1.1\r\ncontent-length: 100\r\n\r\nx" ++
        "GET /hello/a HTTP/1.1\r\n\r\n");
    defer std.testing.allocator.free(res);
    try expectResponse(res, "HTTP/1.1 413 Payload Too Large\r\n", "request body too large");
    try std.testing.expect(std.mem.find(u8, res, "connection: close\r\n") != null);
}

test "app.not_found" {
    const app = .{ .routes = .{}, .not_found = struct {
        fn h(c: *Ctx) !void {
            try c.text("custom");
        }
    }.h };
    const res = try testServe(app, "GET /x HTTP/1.1\r\n\r\n");
    defer std.testing.allocator.free(res);
    try expectResponse(res, "HTTP/1.1 404 Not Found\r\n", "custom");
}

test "built-in css: content type, ETag, 304" {
    const res = try testServe(test_app, "GET /_zw/zw.css HTTP/1.1\r\n\r\n");
    defer std.testing.allocator.free(res);
    try std.testing.expectStringStartsWith(res, "HTTP/1.1 200 OK\r\n");
    try std.testing.expect(std.mem.find(u8, res, "content-type: text/css; charset=utf-8\r\n") != null);
    const start = (std.mem.find(u8, res, "etag: ") orelse return error.NoEtag) + "etag: ".len;
    const etag = res[start..][0..std.mem.findScalar(u8, res[start..], '\r').?];

    const req = try std.fmt.allocPrint(std.testing.allocator, "GET /_zw/zw.css HTTP/1.1\r\nif-none-match: {s}\r\n\r\n", .{etag});
    defer std.testing.allocator.free(req);
    const res304 = try testServe(test_app, req);
    defer std.testing.allocator.free(res304);
    try expectResponse(res304, "HTTP/1.1 304 Not Modified\r\n", "");
}

test "redirect: 303 for pages, z-redirect for z.js" {
    const page = try testServe(test_app, "GET /go HTTP/1.1\r\n\r\n");
    defer std.testing.allocator.free(page);
    try expectResponse(page, "HTTP/1.1 303 See Other\r\n", "");
    try std.testing.expect(std.mem.find(u8, page, "location: /there\r\n") != null);

    const partial = try testServe(test_app, "GET /go HTTP/1.1\r\nz-request: 1\r\n\r\n");
    defer std.testing.allocator.free(partial);
    try expectResponse(partial, "HTTP/1.1 204 No Content\r\n", "");
    try std.testing.expect(std.mem.find(u8, partial, "z-redirect: /there\r\n") != null);
}

test "keep-alive: two requests, two responses" {
    const res = try testServe(test_app, "GET /hello/a HTTP/1.1\r\n\r\nGET /hello/b HTTP/1.1\r\n\r\n");
    defer std.testing.allocator.free(res);
    try std.testing.expectEqual(2, std.mem.count(u8, res, "HTTP/1.1 200 OK\r\n"));
    try std.testing.expectStringEndsWith(res, "\r\n\r\nb");
}
