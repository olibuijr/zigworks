//! Per-request context: read the request, send one response. All memory comes from `arena`
//! and is freed after the response.
const std = @import("std");
const Io = std.Io;
const http = std.http;
const view = @import("view.zig").view;

pub const Param = struct { name: []const u8, value: []const u8 };
pub const max_params = 8;
pub const Params = struct {
    items: [max_params]Param = undefined,
    len: usize = 0,
};

pub const Ctx = struct {
    io: Io,
    arena: std.mem.Allocator,
    method: http.Method,
    /// Path without query string, still percent-encoded.
    path: []const u8,
    raw_query: []const u8,
    body: []const u8 = "",
    status: http.Status = .ok,
    responded: bool = false,
    /// Set by `pass()`: the router tries the next matching route, then static files.
    passed: bool = false,
    params: Params = .{},
    headers: std.ArrayList(http.Header) = .empty,
    req: *http.Server.Request,
    /// Copy of the raw request head (reading the body invalidates the original).
    head: []const u8,

    /// Route param, percent-decoded: `c.param("id")` for `/todos/:id`.
    pub fn param(c: *Ctx, name: []const u8) ?[]const u8 {
        for (c.params.items[0..c.params.len]) |p| {
            if (std.mem.eql(u8, p.name, name)) return decode(c.arena, p.value) catch null;
        }
        return null;
    }

    /// Query string value, decoded.
    pub fn query(c: *Ctx, name: []const u8) ?[]const u8 {
        return formValue(c.arena, c.raw_query, name);
    }

    /// Field of an `application/x-www-form-urlencoded` body, decoded.
    pub fn form(c: *Ctx, name: []const u8) ?[]const u8 {
        return formValue(c.arena, c.body, name);
    }

    /// Parses a JSON body into `T`.
    pub fn json(c: *Ctx, comptime T: type) !T {
        return std.json.parseFromSliceLeaky(T, c.arena, c.body, .{ .ignore_unknown_fields = true });
    }

    /// Request header, case-insensitive.
    pub fn header(c: *Ctx, name: []const u8) ?[]const u8 {
        var it = http.HeaderIterator.init(c.head);
        while (it.next()) |h| if (std.ascii.eqlIgnoreCase(h.name, name)) return h.value;
        return null;
    }

    /// True when z.js sent the request: answer with a fragment, not a full page.
    pub fn isPartial(c: *Ctx) bool {
        return c.header("z-request") != null;
    }

    /// Adds a response header. Name and value must not contain CR/LF.
    pub fn setHeader(c: *Ctx, name: []const u8, value: []const u8) !void {
        try c.headers.append(c.arena, .{ .name = name, .value = value });
    }

    /// Renders an inline template as the HTML response.
    pub fn html(c: *Ctx, comptime src: []const u8, data: anytype) !void {
        try c.page(view(src, data));
    }

    /// Sends a component (any value with `render(self, *Writer)`) as the HTML response.
    pub fn page(c: *Ctx, component: anytype) !void {
        var out: Io.Writer.Allocating = .init(c.arena);
        try component.render(&out.writer);
        try c.send(c.status, "text/html; charset=utf-8", out.written());
    }

    pub fn text(c: *Ctx, body: []const u8) !void {
        try c.send(c.status, "text/plain; charset=utf-8", body);
    }

    pub fn sendJson(c: *Ctx, value: anytype) !void {
        const body = try std.json.Stringify.valueAlloc(c.arena, value, .{});
        try c.send(c.status, "application/json", body);
    }

    /// Full-page redirect: 303 for normal requests, `z-redirect` header for z.js requests.
    pub fn redirect(c: *Ctx, location: []const u8) !void {
        if (c.isPartial()) {
            try c.setHeader("z-redirect", location);
            return c.send(.no_content, "text/plain", "");
        }
        try c.setHeader("location", location);
        try c.send(.see_other, "text/plain", "");
    }

    /// Declines the request without responding: the next matching route runs, then `public/`,
    /// then 404. Use it in catch-all routes like `GET /:page` for paths they don't know.
    pub fn pass(c: *Ctx) void {
        c.passed = true;
    }

    /// Sends the response. Call exactly once per request.
    pub fn send(c: *Ctx, status: http.Status, content_type: []const u8, body: []const u8) !void {
        std.debug.assert(!c.responded);
        c.status = status;
        c.responded = true;
        try c.headers.append(c.arena, .{ .name = "content-type", .value = content_type });
        try c.req.respond(body, .{ .status = status, .extra_headers = c.headers.items });
    }
};

/// Finds `name` in `a=1&b=2` and returns the decoded value.
pub fn formValue(arena: std.mem.Allocator, data: []const u8, name: []const u8) ?[]const u8 {
    var it = std.mem.splitScalar(u8, data, '&');
    while (it.next()) |pair| {
        const k, const v = std.mem.cutScalar(u8, pair, '=') orelse .{ pair, "" };
        const key = decode(arena, k) catch return null;
        if (std.mem.eql(u8, key, name)) return decode(arena, v) catch null;
    }
    return null;
}

/// Percent-decodes into a new slice; `+` becomes a space.
pub fn decode(arena: std.mem.Allocator, s: []const u8) ![]u8 {
    const out = try arena.dupe(u8, s);
    std.mem.replaceScalar(u8, out, '+', ' ');
    return std.Uri.percentDecodeInPlace(out);
}

test "form decoding" {
    var arena: std.heap.ArenaAllocator = .init(std.testing.allocator);
    defer arena.deinit();
    const a = arena.allocator();
    try std.testing.expectEqualStrings("buy milk & eggs", formValue(a, "x=1&title=buy+milk+%26+eggs", "title").?);
    try std.testing.expectEqualStrings("", formValue(a, "empty", "empty").?);
    try std.testing.expect(formValue(a, "a=1", "b") == null);
}
