//! Todo feature components, composed from zigworks ui. `css` is appended to /_zw/zw.css.
const std = @import("std");
const zw = @import("zigworks");
const ui = zw.ui;
const Todo = @import("store.zig").Todo;

pub const css =
    \\.todo-title{transition:color var(--speed)}
    \\.todo.is-done .todo-title{color:var(--secondary);text-decoration:line-through;text-decoration-color:var(--tertiary)}
    \\@media (hover:hover){.todo .zw-btn--destructive{opacity:0}.todo:hover .zw-btn--destructive,.todo:focus-within .zw-btn--destructive{opacity:1}}
    \\.todo-form{margin-bottom:12px}
    \\
;

pub const Row = zw.View(
    \\<li class="todo{#if t.done} is-done{/if}">{done}<span class="zw-grow todo-title">{t.title}</span>{delete}</li>
, struct { t: Todo, done: ui.Check, delete: ui.Button });

/// One list row: completion check, title, delete.
pub fn row(t: Todo) Row {
    return .{ .data = .{
        .t = t,
        .done = ui.check(.{ .on = t.done, .label = t.title, .z = .{ .patch = t.path, .target = "closest li", .swap = .outer } }),
        .delete = ui.button(.{ .label = "Delete", .variant = .destructive, .z = .{ .delete = t.path, .target = "closest li", .swap = .delete } }),
    } };
}

/// "3 left" badge in the toolbar. `oob` lets a fragment response update it in place.
pub fn remaining(arena: std.mem.Allocator, n: usize, oob: bool) !ui.Badge {
    return ui.badge(.{ .text = try arena.print("{d} left", .{n}), .id = "remaining", .oob = oob });
}

pub const Form = zw.View(
    \\<form class="zw-row todo-form" method="post" action="/todos"{z}>{input}{submit}</form>
, struct { z: ui.Z, input: ui.Field, submit: ui.Button });

/// Add form. Works without JS too (plain POST + redirect).
pub fn form() Form {
    return .{ .data = .{
        .z = .{ .post = "/todos", .target = "#todos", .swap = .beforeend },
        .input = ui.field(.{ .name = "title", .label = "New todo", .placeholder = "New todo", .required = true, .autofocus = true }),
        .submit = ui.button(.{ .label = "Add", .variant = .primary, .type = .submit }),
    } };
}

pub fn list(todos: []const Todo) ui.List(zw.Each([]const Todo, row)) {
    return ui.list(.{ .id = "todos", .empty = "No todos yet. Add one above.", .body = zw.each(todos, row) });
}
