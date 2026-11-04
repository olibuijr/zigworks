//! Comptime router. Routes are `.{ "METHOD /path/:param/*", handler }`; handlers are `fn (*Ctx) !void`.
//! GET routes also answer HEAD. `*` (last segment only) captures the rest as param "*".
const std = @import("std");
const http = std.http;
const Ctx = @import("ctx.zig").Ctx;
const Params = @import("ctx.zig").Params;
const max_params = @import("ctx.zig").max_params;

/// Runs the first matching route. Returns false when none matched.
pub fn dispatch(comptime routes: anytype, c: *Ctx) !bool {
    inline for (routes) |route| {
        const method, const pattern = comptime std.mem.cutScalar(u8, route[0], ' ') orelse
            @compileError("route must look like \"GET /path\", got \"" ++ route[0] ++ "\"");
        const m = comptime std.meta.stringToEnum(http.Method, method) orelse
            @compileError("unknown method in route \"" ++ route[0] ++ "\"");
        if (comptime pattern.len == 0 or pattern[0] != '/') @compileError("route path must start with '/': " ++ route[0]);
        if ((c.method == m or (m == .GET and c.method == .HEAD)) and match(pattern, c.path, &c.params)) {
            try route[1](c);
            return true;
        }
    }
    return false;
}

/// Matches `/todos/:id` against `/todos/42`.
pub fn match(comptime pattern: []const u8, path: []const u8, params: *Params) bool {
    params.len = 0;
    if (path.len == 0 or path[0] != '/') return false;
    var pit = std.mem.splitScalar(u8, pattern[1..], '/');
    var it = std.mem.splitScalar(u8, path[1..], '/');
    while (pit.next()) |p| {
        if (std.mem.eql(u8, p, "*")) {
            params.items[params.len] = .{ .name = "*", .value = it.rest() };
            params.len += 1;
            return true;
        }
        const s = it.next() orelse return false;
        if (p.len > 0 and p[0] == ':') {
            if (s.len == 0 or params.len == max_params) return false;
            params.items[params.len] = .{ .name = p[1..], .value = s };
            params.len += 1;
        } else if (!std.mem.eql(u8, p, s)) return false;
    }
    return it.next() == null;
}

test match {
    var p: Params = .{};
    try std.testing.expect(match("/", "/", &p));
    try std.testing.expect(!match("/", "/x", &p));
    try std.testing.expect(match("/todos/:id", "/todos/42", &p));
    try std.testing.expectEqualStrings("42", p.items[0].value);
    try std.testing.expect(!match("/todos/:id", "/todos/", &p));
    try std.testing.expect(!match("/todos/:id", "/todos/1/x", &p));
    try std.testing.expect(match("/files/*", "/files/a/b.txt", &p));
    try std.testing.expectEqualStrings("a/b.txt", p.items[0].value);
    try std.testing.expect(!match("/x", "*", &p));
}
