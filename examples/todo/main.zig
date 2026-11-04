//! Todo app: server-rendered pages, z.js fragments, works without JS.
const std = @import("std");
const zw = @import("zigworks");
const Store = @import("store.zig");
const views = @import("views.zig");

var store: Store = undefined;

const app = .{
    .routes = .{
        .{ "GET /", index },
        .{ "POST /todos", create },
        .{ "PATCH /todos/:id", toggle },
        .{ "DELETE /todos/:id", remove },
    },
    .css = views.css,
};

pub fn main(init: std.process.Init) !void {
    store = .{ .gpa = init.gpa };
    try zw.serve(init, app, .{});
}

fn index(c: *zw.Ctx) !void {
    const todos = try store.list(c.io, c.arena);
    try c.page(zw.ui.layout(.{
        .title = "Todos",
        .toolbar = try views.remaining(c.arena, Store.remaining(todos), false),
        .body = zw.view("{form}{list}", .{ .form = views.form(), .list = views.list(todos) }),
    }));
}

fn create(c: *zw.Ctx) !void {
    const title = std.mem.trim(u8, c.form("title") orelse "", " \t\r\n");
    if (title.len == 0 or title.len > 500) {
        if (!c.isPartial()) return c.redirect("/");
        return c.send(.bad_request, "text/plain", "title must be 1-500 characters");
    }
    const todo = try store.add(c.io, c.arena, title);
    if (!c.isPartial()) return c.redirect("/");
    try fragment(c, views.row(todo));
}

fn toggle(c: *zw.Ctx) !void {
    const todo = try store.toggle(c.io, c.arena, id(c) orelse return notFound(c)) orelse return notFound(c);
    try fragment(c, views.row(todo));
}

fn remove(c: *zw.Ctx) !void {
    if (!try store.remove(c.io, id(c) orelse return notFound(c))) return notFound(c);
    try fragment(c, "");
}

/// Sends `body` plus the updated toolbar count (out-of-band).
fn fragment(c: *zw.Ctx, body: anytype) !void {
    const n = Store.remaining(try store.list(c.io, c.arena));
    try c.html("{body}{count}", .{ .body = body, .count = try views.remaining(c.arena, n, true) });
}

fn id(c: *zw.Ctx) ?u32 {
    return std.fmt.parseInt(u32, c.param("id") orelse return null, 10) catch null;
}

fn notFound(c: *zw.Ctx) !void {
    try c.send(.not_found, "text/plain", "no such todo");
}

test {
    _ = Store;
}
