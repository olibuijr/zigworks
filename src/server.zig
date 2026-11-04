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
    host: []const u8 = "127.0.0.1",
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
/// `tokens` and `css` (app styles, appended to /_zw/zw.css) are optional.
pub fn serve(init: std.process.Init, comptime app: anytype, options: Options) !void {
    const io = init.io;
    var opts = options;
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
    var arena: std.heap.ArenaAllocator = .init(state.gpa);
    defer arena.deinit();
    while (server.reader.state == .ready) {
        _ = arena.reset(.retain_capacity);
        var req = server.receiveHead() catch |err| switch (err) {
            error.HttpConnectionClosing => return,
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
        log.err("{t} {s}: {t}", .{ c.method, c.path, err });
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
    try c.send(.not_found, "text/plain", "not found");
}

fn asset(c: *Ctx, content_type: []const u8, body: []const u8) !void {
    try c.setHeader("cache-control", "no-cache");
    try c.send(.ok, content_type, body);
}

/// Answers 413 and closes the connection (the unread body makes it unusable).
fn tooLarge(c: *Ctx) !void {
    c.status = .payload_too_large;
    c.responded = true;
    try c.req.respond("request body too large", .{ .status = .payload_too_large, .keep_alive = false });
    return error.BodyTooLarge;
}
