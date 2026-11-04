//! Live demos for docs/pages/components/tooltip.md (```demo tooltip``` fences).
const std = @import("std");
const Writer = std.Io.Writer;
const zw = @import("zigworks");
const ui = zw.ui;
const d = @import("demo.zig");

/// Fence name, block layout (stacked) or inline (wrapping row), render function.
pub const demos = [_]d.Demo{
    .{ "tooltip", true, hero },
    .{ "tooltip-sides", true, sides },
    .{ "tooltip-content", true, content },
    .{ "tooltip-states", true, states },
    .{ "tooltip-live", true, live },
    .{ "tooltip-compose", true, compose },
};
/// Extra CSS for these demos (scope it under a demo-specific class).
pub const css =
    \\.demo-tooltip-bar{display:flex;align-items:center;gap:2px;width:fit-content;max-width:100%;padding:4px;border-radius:999px}
    \\.demo-tooltip-bar .zw-btn{color:var(--label)}
    \\.demo-tooltip-sep{width:1px;height:18px;margin:0 4px;background:var(--separator)}
    \\.demo-tooltip-cells{display:grid;grid-template-columns:repeat(auto-fit,minmax(120px,1fr));gap:24px 12px;justify-items:center;width:100%}
    \\.demo-tooltip-sides{display:flex;justify-content:space-between;gap:12px;width:100%}
    \\.demo-tooltip-cell{display:flex;flex-direction:column;align-items:center;gap:8px;text-align:center}
    \\.demo-tooltip-item small{display:block}
    \\.demo-tooltip-people{margin-inline-start:4px}
    \\.demo-tooltip-people .zw-tip+.zw-tip{margin-inline-start:-10px}
    \\.demo-tooltip-who{display:inline-grid;border-radius:50%}
    \\
;
/// Server routes these demos need, e.g. `.{ "POST /demo/tooltip/x", handler }`.
pub const routes = .{
    .{ "POST /demo/tooltip/star", starToggle },
    .{ "POST /demo/tooltip/copy", copyLink },
};

const svg = "<svg viewBox=\"0 0 18 18\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"1.5\" stroke-linecap=\"round\" stroke-linejoin=\"round\">";
const new_note = svg ++ "<path d=\"M9 3H4.5A1.5 1.5 0 0 0 3 4.5v9A1.5 1.5 0 0 0 4.5 15h9a1.5 1.5 0 0 0 1.5-1.5V9M13.5 2.5l2 2L9 11l-3 1 1-3z\"/></svg>";
const checklist = svg ++ "<path d=\"M3 5l1.5 1.5L7 4M3 12l1.5 1.5L7 11M9.5 5H15M9.5 12H15\"/></svg>";
const share = svg ++ "<path d=\"M9 11V2.5M6 5l3-3 3 3M5 8H4a1 1 0 0 0-1 1v6a1 1 0 0 0 1 1h10a1 1 0 0 0 1-1V9a1 1 0 0 0-1-1h-1\"/></svg>";
const trash = svg ++ "<path d=\"M3 5h12M7 5V3h4v2M5 5l.7 10h6.6L13 5\"/></svg>";
const link = svg ++ "<path d=\"M7.5 10.5a3 3 0 0 0 4.2 0l2.3-2.3a3 3 0 0 0-4.2-4.2l-.8.8M10.5 7.5a3 3 0 0 0-4.2 0L4 9.8A3 3 0 0 0 8.2 14l.8-.8\"/></svg>";
const more = svg ++ "<circle cx=\"4\" cy=\"9\" r=\".8\"/><circle cx=\"9\" cy=\"9\" r=\".8\"/><circle cx=\"14\" cy=\"9\" r=\".8\"/></svg>";
const refresh = svg ++ "<path d=\"M14.5 9a5.5 5.5 0 1 1-1.8-4.1M14.5 3v3h-3\"/></svg>";
const star_off = svg ++ "<path d=\"M9 2l2 4.3 4.7.6-3.4 3.2.9 4.7L9 12.5l-4.2 2.3.9-4.7L2.3 6.9 7 6.3z\"/></svg>";
const star_on = "<svg viewBox=\"0 0 18 18\" fill=\"currentColor\" stroke=\"currentColor\" stroke-width=\"1.5\" stroke-linejoin=\"round\"><path d=\"M9 2l2 4.3 4.7.6-3.4 3.2.9 4.7L9 12.5l-4.2 2.3.9-4.7L2.3 6.9 7 6.3z\"/></svg>";

// Hero: a Notes-style toolbar. Toolbar tips open below, as in macOS.
fn hero(w: *Writer) Writer.Error!void {
    try zw.view("<div class=\"demo-tooltip-bar zw-glass\" role=\"group\" aria-label=\"Note\">{new}{list}<span class=\"demo-tooltip-sep\"></span>{share}{trash}</div>{note}", .{
        .new = ui.tooltip(.{
            .text = "New Note",
            .shortcut = "⌘N",
            .side = .below,
            .body = ui.button(.{ .label = "New Note", .variant = .plain, .icon = new_note, .icon_only = true, .z = d.save }),
        }),
        .list = ui.tooltip(.{
            .text = "Checklist",
            .shortcut = "⇧⌘L",
            .side = .below,
            .body = ui.button(.{ .label = "Checklist", .variant = .plain, .icon = checklist, .icon_only = true, .z = d.save }),
        }),
        .share = ui.tooltip(.{
            .id = "demo-tooltip-share",
            .text = "Share",
            .detail = "Send a copy or invite people to edit.",
            .side = .below,
            .body = ui.button(.{ .label = "Share", .variant = .plain, .icon = share, .icon_only = true, .describedby = "demo-tooltip-share", .z = d.save }),
        }),
        .trash = ui.tooltip(.{
            .id = "demo-tooltip-trash",
            .text = "Delete Note",
            .shortcut = "⌘⌫",
            .side = .below,
            .body = ui.button(.{ .label = "Delete Note", .variant = .plain, .icon = trash, .icon_only = true, .describedby = "demo-tooltip-trash", .z = d.save }),
        }),
        .note = ui.card(.{
            .title = "Weekend plans",
            .subtitle = "Edited today at 9:41",
            .body = "Farmers market at ten, then the climbing gym. Renew the library books before Monday.",
            .footer = "Rest the pointer on a toolbar button, or press Tab, to see its tip.",
        }),
    }).render(w);
}

// Variants: the four sides. Left and right triggers sit at the edges so the tip has room.
fn sides(w: *Writer) Writer.Error!void {
    try zw.view(
        \\<div class="demo-tooltip-sides">
        \\<div class="demo-tooltip-cell">{right}<code>.right</code></div>
        \\<div class="demo-tooltip-cell">{above}<code>.above</code></div>
        \\<div class="demo-tooltip-cell">{below}<code>.below</code></div>
        \\<div class="demo-tooltip-cell">{left}<code>.left</code></div>
        \\</div>
    , .{
        .right = ui.tooltip(.{ .text = "Opens to the right", .side = .right, .body = ui.button(.{ .label = "Right", .variant = .plain }) }),
        .above = ui.tooltip(.{ .text = "Above (default)", .body = ui.button(.{ .label = "Above", .variant = .plain }) }),
        .below = ui.tooltip(.{ .text = "Below the trigger", .side = .below, .body = ui.button(.{ .label = "Below", .variant = .plain }) }),
        .left = ui.tooltip(.{ .text = "Opens to the left", .side = .left, .body = ui.button(.{ .label = "Left", .variant = .plain }) }),
    }).render(w);
}

// Variants: what a tip can say, then how fast it appears.
fn content(w: *Writer) Writer.Error!void {
    try zw.view(
        \\<div class="demo-tooltip-cells">
        \\<div class="demo-tooltip-cell">{text}<code>text</code></div>
        \\<div class="demo-tooltip-cell">{shortcut}<code>shortcut</code></div>
        \\<div class="demo-tooltip-cell">{detail}<code>detail</code></div>
        \\<div class="demo-tooltip-cell">{all}<code>id + all three</code></div>
        \\</div>
        \\<div class="demo-tooltip-cells">
        \\<div class="demo-tooltip-cell">{instant}<code>delay = 0</code></div>
        \\<div class="demo-tooltip-cell">{normal}<code>delay = 500</code></div>
        \\<div class="demo-tooltip-cell">{slow}<code>delay = 1500</code></div>
        \\</div>
    , .{
        .text = ui.tooltip(.{ .text = "Rename this note", .side = .below, .body = ui.button(.{ .label = "Rename" }) }),
        .shortcut = ui.tooltip(.{ .text = "Save", .shortcut = "⌘S", .side = .below, .body = ui.button(.{ .label = "Save" }) }),
        .detail = ui.tooltip(.{ .text = "Export as PDF", .detail = "Includes attachments and comments.", .side = .below, .body = ui.button(.{ .label = "Export" }) }),
        .all = ui.tooltip(.{
            .id = "demo-tooltip-print",
            .text = "Print",
            .shortcut = "⌘P",
            .detail = "Opens the print dialog.",
            .side = .below,
            .body = ui.button(.{ .label = "Print", .variant = .primary, .describedby = "demo-tooltip-print" }),
        }),
        .instant = ui.tooltip(.{ .text = "Appears at once", .delay = 0, .body = ui.button(.{ .label = "Instant", .variant = .plain }) }),
        .normal = ui.tooltip(.{ .text = "The macOS delay", .delay = 500, .body = ui.button(.{ .label = "Default", .variant = .plain }) }),
        .slow = ui.tooltip(.{ .text = "Waits a moment longer", .delay = 1500, .body = ui.button(.{ .label = "Slow", .variant = .plain }) }),
    }).render(w);
}

// States: a tip is the place to say why a control is unavailable. The tip belongs to the wrapper,
// so it still shows over a disabled or loading button.
fn states(w: *Writer) Writer.Error!void {
    try zw.view(
        \\{to}
        \\<div class="demo-tooltip-cells">
        \\<div class="demo-tooltip-cell">{send}<code>disabled</code></div>
        \\<div class="demo-tooltip-cell">{sync}<code>loading</code></div>
        \\<div class="demo-tooltip-cell">{discard}<code>destructive</code></div>
        \\</div>
    , .{
        .to = ui.field(.{ .name = "demo-tooltip-to", .label = "Recipient", .prefix = "To", .type = "email", .value = "ada@", .invalid = "Enter a full address, like name@example.com" }),
        .send = ui.tooltip(.{
            .id = "demo-tooltip-send",
            .text = "Add a valid recipient",
            .body = ui.button(.{ .label = "Send", .variant = .primary, .disabled = true, .describedby = "demo-tooltip-send" }),
        }),
        .sync = ui.tooltip(.{
            .text = "Checking for new mail",
            .delay = 200,
            .body = ui.button(.{ .label = "Sync", .loading = true, .icon = refresh }),
        }),
        .discard = ui.tooltip(.{
            .text = "Discard Draft",
            .shortcut = "⌘⌫",
            .detail = "This can't be undone.",
            .body = ui.button(.{ .label = "Discard", .variant = .destructive }),
        }),
    }).render(w);
}

// Interactive: the server answers with a new tooltip, so its text follows the state, and an
// out-of-band badge. The state (on, count) travels in the URL.
fn star(on: bool, url: []const u8) ui.Tooltip(ui.Button) {
    const text: []const u8 = if (on) "Remove from Favorites" else "Add to Favorites";
    const label: []const u8 = if (on) "Unfavorite" else "Favorite";
    const icon: []const u8 = if (on) star_on else star_off;
    return ui.tooltip(.{
        .id = "demo-tooltip-star-tip",
        .text = text,
        .body = ui.button(.{
            .label = label,
            .variant = .plain,
            .icon = icon,
            .icon_only = true,
            .describedby = "demo-tooltip-star-tip",
            .z = .{ .post = url, .target = "closest .zw-tip", .swap = .outer },
        }),
    });
}

fn starToggle(c: *zw.Ctx) !void {
    const was_on = std.mem.eql(u8, c.query("on") orelse "0", "1");
    const n = std.fmt.parseInt(u32, c.query("n") orelse "0", 10) catch 0;
    const now_on = !was_on;
    const count = if (now_on) @min(n +| 1, 999) else n -| 1;
    const url = try std.fmt.allocPrint(c.arena, "/demo/tooltip/star?on={d}&n={d}", .{ @intFromBool(now_on), count });
    try c.page(zw.view("{star}{count}", .{
        .star = star(now_on, url),
        .count = ui.badge(.{ .id = "demo-tooltip-count", .oob = true, .count = count, .tone = .accent, .hide_zero = true }),
    }));
}

fn copyLink(c: *zw.Ctx) !void {
    try c.page(ui.toast(.{ .text = "Link copied", .kind = .success }));
}

fn live(w: *Writer) Writer.Error!void {
    try ui.card(.{
        .title = "Reading list",
        .subtitle = "Press a button, then look at its tip again.",
        .body = zw.view(
            \\<div class="demo-tooltip-item zw-row">
            \\<span class="zw-grow"><strong>Designing for Liquid Glass</strong><small class="zw-secondary">example.com · 6 min read</small></span>
            \\{copy}{star}</div>
            \\<div class="zw-row"><span class="zw-secondary">Favorites</span>{count}</div>
        , .{
            .copy = ui.tooltip(.{
                .text = "Copy Link",
                .shortcut = "⇧⌘C",
                .body = ui.button(.{ .label = "Copy Link", .variant = .plain, .icon = link, .icon_only = true, .z = .{ .post = "/demo/tooltip/copy", .swap = .none } }),
            }),
            .star = star(false, "/demo/tooltip/star?on=0&n=2"),
            .count = ui.badge(.{ .id = "demo-tooltip-count", .count = 2, .tone = .accent, .hide_zero = true }),
        }),
    }).render(w);
}

// Composition: tooltips on card actions (one also opens a menu) and on avatars. Avatars are not
// focusable, so each gets a tabindex wrapper to make its tip reachable from the keyboard.
fn compose(w: *Writer) Writer.Error!void {
    const who = "<span class=\"demo-tooltip-who\" tabindex=\"0\">{a}</span>";
    try ui.card(.{
        .title = "Q3 roadmap",
        .subtitle = "Shared document",
        .accessory = zw.view("{share}{more}{menu}", .{
            .share = ui.tooltip(.{
                .text = "Share",
                .shortcut = "⇧⌘S",
                .side = .below,
                .body = ui.button(.{ .label = "Share", .variant = .plain, .icon = share, .icon_only = true, .z = d.save }),
            }),
            .more = ui.tooltip(.{
                .text = "More",
                .side = .below,
                .body = ui.button(.{ .label = "More", .variant = .plain, .icon = more, .icon_only = true, .opens = "demo-tooltip-menu" }),
            }),
            .menu = ui.menu(.{ .id = "demo-tooltip-menu", .label = "More", .alignment = .end, .items = &.{
                .{ .label = "Duplicate", .shortcut = "⌘D", .z = d.save },
                .{ .label = "Rename", .z = d.save },
                .{ .label = "Move to Trash", .shortcut = "⌘⌫", .destructive = true, .separated = true, .z = d.save },
            } }),
        }),
        .body = zw.view("<div class=\"zw-row\"><span class=\"zw-secondary\">Shared with</span><div class=\"zw-avatars demo-tooltip-people\">{a}{b}{c}{d}</div></div>", .{
            .a = ui.tooltip(.{ .text = "Ada Lovelace", .detail = "Can edit", .body = zw.view(who, .{ .a = ui.avatar(.{ .name = "Ada Lovelace" }) }) }),
            .b = ui.tooltip(.{ .text = "Grace Hopper", .detail = "Can comment", .body = zw.view(who, .{ .a = ui.avatar(.{ .name = "Grace Hopper" }) }) }),
            .c = ui.tooltip(.{ .text = "Alan Turing", .detail = "Can view", .body = zw.view(who, .{ .a = ui.avatar(.{ .name = "Alan Turing" }) }) }),
            .d = ui.tooltip(.{ .text = "2 more people", .detail = "Margaret Hamilton and Katherine Johnson", .body = zw.view(who, .{ .a = ui.avatar(.{ .name = "More people", .more = 2 }) }) }),
        }),
    }).render(w);
}
