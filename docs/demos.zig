//! Live component demos for ```demo <name>``` fences. Each demo renders real components;
//! controls post to /demo, which logs and answers 204.
const std = @import("std");
const Writer = std.Io.Writer;
const zw = @import("zigworks");
const ui = zw.ui;
const d = @import("demos/demo.zig");

pub const css =
    \\.zw-demo{display:flex;flex-wrap:wrap;align-items:center;gap:12px;padding:28px;border-radius:var(--radius);background:var(--window);box-shadow:inset 0 0 0 .5px var(--separator);font:var(--body);letter-spacing:-.08px}
    \\.zw-demo--block{display:block}
    \\.zw-demo--block>*+*{margin-top:12px}
    \\@media (max-width:599px){.zw-demo{padding:16px}}
    \\.zw-demo :not(pre)>code{font:.86em var(--mono);padding:1px 5px;border-radius:5px;background:var(--fill)}
    \\.zw-demo .zw-card,.zw-demo .zw-list{flex:1}
    \\.zw-demo .is-done{color:var(--secondary);text-decoration:line-through}
    \\@media (hover:hover){#hero-list .zw-btn--destructive{opacity:0;transition:opacity var(--speed)}#hero-list li:hover .zw-btn--destructive,#hero-list li:focus-within .zw-btn--destructive{opacity:1}}
    \\
++ layout.css ++ sidebar.css ++ card.css ++ list.css ++ setting.css ++ sheet.css ++ button.css ++ field.css ++ search.css ++ check.css ++ toggle.css ++ segmented.css ++ slider.css ++ picker.css ++ menu.css ++ badge.css ++ progress.css ++ callout.css ++ code.css ++ table.css ++ island.css ++ tabs.css ++ textarea.css ++ stepper.css ++ checkbox.css ++ radio.css ++ disclosure.css ++ tooltip.css ++ toast.css ++ avatar.css ++ tag.css ++ empty.css ++ skeleton.css ++ kbd.css ++ path.css;

const layout = @import("demos/layout.zig");
const sidebar = @import("demos/sidebar.zig");
const card = @import("demos/card.zig");
const list = @import("demos/list.zig");
const setting = @import("demos/setting.zig");
const sheet = @import("demos/sheet.zig");
const button = @import("demos/button.zig");
const field = @import("demos/field.zig");
const search = @import("demos/search.zig");
const check = @import("demos/check.zig");
const toggle = @import("demos/toggle.zig");
const segmented = @import("demos/segmented.zig");
const slider = @import("demos/slider.zig");
const picker = @import("demos/picker.zig");
const menu = @import("demos/menu.zig");
const badge = @import("demos/badge.zig");
const progress = @import("demos/progress.zig");
const callout = @import("demos/callout.zig");
const code = @import("demos/code.zig");
const table = @import("demos/table.zig");
const island = @import("demos/island.zig");
const tabs = @import("demos/tabs.zig");
const textarea = @import("demos/textarea.zig");
const stepper = @import("demos/stepper.zig");
const checkbox = @import("demos/checkbox.zig");
const radio = @import("demos/radio.zig");
const disclosure = @import("demos/disclosure.zig");
const tooltip = @import("demos/tooltip.zig");
const toast = @import("demos/toast.zig");
const avatar = @import("demos/avatar.zig");
const tag = @import("demos/tag.zig");
const empty = @import("demos/empty.zig");
const skeleton = @import("demos/skeleton.zig");
const kbd = @import("demos/kbd.zig");
const path = @import("demos/path.zig");

const demos = [_]d.Demo{.{ "hero", true, hero }} ++ layout.demos ++ sidebar.demos ++ card.demos ++ list.demos ++ setting.demos ++ sheet.demos ++ button.demos ++ field.demos ++ search.demos ++ check.demos ++ toggle.demos ++ segmented.demos ++ slider.demos ++ picker.demos ++ menu.demos ++ badge.demos ++ progress.demos ++ callout.demos ++ code.demos ++ table.demos ++ island.demos ++ tabs.demos ++ textarea.demos ++ stepper.demos ++ checkbox.demos ++ radio.demos ++ disclosure.demos ++ tooltip.demos ++ toast.demos ++ avatar.demos ++ tag.demos ++ empty.demos ++ skeleton.demos ++ kbd.demos ++ path.demos;

/// Routes the demo files add (main.zig mounts them).
pub const routes = layout.routes ++ sidebar.routes ++ card.routes ++ list.routes ++ setting.routes ++ sheet.routes ++ button.routes ++ field.routes ++ search.routes ++ check.routes ++ toggle.routes ++ segmented.routes ++ slider.routes ++ picker.routes ++ menu.routes ++ badge.routes ++ progress.routes ++ callout.routes ++ code.routes ++ table.routes ++ island.routes ++ tabs.routes ++ textarea.routes ++ stepper.routes ++ checkbox.routes ++ radio.routes ++ disclosure.routes ++ tooltip.routes ++ toast.routes ++ avatar.routes ++ tag.routes ++ empty.routes ++ skeleton.routes ++ kbd.routes ++ path.routes;

/// Markdown fence hook: ```demo name``` renders a live demo; other fences fall through.
pub const Fences = struct {
    pub fn fence(_: Fences, w: *Writer, lang: []const u8, body: []const u8) Writer.Error!bool {
        if (!std.mem.eql(u8, lang, "demo")) return false;
        for (demos) |demo| if (std.mem.eql(u8, demo[0], std.mem.trim(u8, body, " \n"))) {
            try w.writeAll(if (demo[1]) "<div class=\"zw-demo zw-demo--block zw-not-prose\">" else "<div class=\"zw-demo zw-not-prose\">");
            try demo[2](w);
            try w.writeAll("</div>");
            return true;
        };
        try w.writeAll("<p><strong>Missing demo:</strong> ");
        try zw.writeEscaped(w, body);
        try w.writeAll("</p>");
        return true;
    }
};

// The home page todo works for real: rows are rendered by the server (POST /demo/todos,
// /demo/toggle, DELETE /demo/todo in main.zig). State lives in the page, not on the server,
// so every visitor gets a fresh list; the toggle URL carries the row's title and state.
pub const TodoRow = zw.View(
    \\<li>{check}<span class="zw-grow{#if done} is-done{/if}">{title}</span>{del}</li>
, struct { check: ui.Check, title: []const u8, done: bool, del: ui.Button });

pub fn todoRow(arena: std.mem.Allocator, done: bool, title: []const u8) !TodoRow {
    return .{ .data = .{
        .check = ui.check(.{ .on = done, .label = title, .z = .{
            .post = try std.fmt.allocPrint(arena, "/demo/toggle?d={d}&t={f}", .{ @intFromBool(done), std.fmt.alt(std.Uri.Component{ .raw = title }, .formatEscaped) }),
            .target = "closest li",
            .swap = .outer,
        } }),
        .title = title,
        .done = done,
        .del = ui.button(.{ .label = "Delete", .variant = .destructive, .z = .{ .delete = "/demo/todo", .target = "closest li", .swap = .delete } }),
    } };
}

fn hero(w: *Writer) Writer.Error!void {
    var buf: [4096]u8 = undefined;
    var fba: std.heap.FixedBufferAllocator = .init(&buf);
    const a = fba.allocator();
    const rows = .{
        todoRow(a, true, "Read the docs") catch unreachable,
        todoRow(a, false, "zig build run") catch unreachable,
        todoRow(a, false, "Ship it") catch unreachable,
    };
    try zw.view("<form class=\"zw-row\" style=\"margin-bottom:12px\"{z}>{f}{b}</form>{l}", .{
        .z = ui.Z{ .post = "/demo/todos", .target = "#hero-list", .swap = .beforeend },
        .f = ui.field(.{ .name = "title", .label = "New todo", .placeholder = "New todo", .required = true }),
        .b = ui.button(.{ .label = "Add", .variant = .primary, .type = .submit }),
        .l = ui.list(.{ .id = "hero-list", .empty = "All done. Add another.", .body = zw.view("{a}{b}{c}", .{ .a = rows[0], .b = rows[1], .c = rows[2] }) }),
    }).render(w);
}
