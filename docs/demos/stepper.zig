//! Live demos for docs/pages/components/stepper.md (```demo stepper``` fences).
const std = @import("std");
const Writer = std.Io.Writer;
const zw = @import("zigworks");
const ui = zw.ui;
const d = @import("demo.zig");

/// Fence name, block layout (stacked) or inline (wrapping row), render function.
pub const demos = [_]d.Demo{
    .{ "stepper", true, stepper },
    .{ "stepper-props", true, props },
    .{ "stepper-states", true, states },
    .{ "stepper-cart", true, cart },
    .{ "stepper-alarm", true, alarm },
};
/// Extra CSS for these demos (scope it under a demo-specific class).
pub const css =
    \\.demo-stepper-out{display:flex;flex-direction:column;gap:10px;margin-top:var(--space);padding-top:12px;border-top:1px solid var(--separator);font:var(--callout);color:var(--secondary)}
    \\.demo-stepper-out strong{color:var(--label)}
    \\.demo-stepper-time{flex-wrap:wrap;justify-content:flex-end}
    \\
;
/// Server routes these demos need, e.g. `.{ "POST /demo/stepper/x", handler }`.
pub const routes = .{
    .{ "POST /demo/stepper/cart", cartUpdate },
    .{ "POST /demo/stepper/alarm", alarmUpdate },
};

// Hero: a print dialog. Each step saves through POST /demo.
fn stepper(w: *Writer) Writer.Error!void {
    try ui.card(.{ .title = "Print", .subtitle = "Quarterly report.pdf", .body = zw.view("{a}{b}{c}", .{
        .a = ui.setting(.{ .label = "Copies", .control = ui.stepper(.{ .name = "copies", .label = "Copies", .value = 1, .min = 1, .max = 99, .z = d.save }) }),
        .b = ui.setting(.{ .label = "Scale", .control = ui.stepper(.{ .name = "scale", .label = "Scale", .value = 100, .min = 25, .max = 400, .step = 25, .unit = "%", .z = d.save }) }),
        .c = ui.setting(.{ .label = "Margins", .control = ui.stepper(.{ .name = "margins", .label = "Margins", .value = 20, .min = 0, .max = 50, .step = 5, .unit = "mm", .z = d.save }) }),
    }) }).render(w);
}

// Each row names the prop it shows.
fn props(w: *Writer) Writer.Error!void {
    try ui.card(.{ .body = zw.view("{a}{b}{c}{d}{e}", .{
        .a = ui.setting(.{ .label = "Copies", .description = "value, min, max", .control = ui.stepper(.{ .name = "p-copies", .label = "Copies", .value = 1, .min = 1, .max = 99, .z = d.save }) }),
        .b = ui.setting(.{ .label = "Cache size", .description = "unit: GB", .control = ui.stepper(.{ .name = "p-cache", .label = "Cache size", .value = 4, .min = 1, .max = 32, .unit = "GB", .z = d.save }) }),
        .c = ui.setting(.{ .label = "Opacity", .description = "step: 10", .control = ui.stepper(.{ .name = "p-opacity", .label = "Opacity", .value = 80, .min = 0, .max = 100, .step = 10, .unit = "%", .z = d.save }) }),
        .d = ui.setting(.{ .label = "Font size", .description = "editable: false", .control = ui.stepper(.{ .name = "p-font", .label = "Font size", .value = 13, .min = 9, .max = 72, .unit = "pt", .editable = false, .z = d.save }) }),
        .e = ui.setting(.{ .label = "Hour", .description = "wrap: true, editable: false", .control = ui.stepper(.{ .name = "p-hour", .label = "Hour", .value = 23, .min = 0, .max = 23, .wrap = true, .editable = false, .z = d.save }) }),
    }) }).render(w);
}

// The bounds, wrapping and disabled, side by side.
fn states(w: *Writer) Writer.Error!void {
    try ui.card(.{ .body = zw.view("{a}{b}{c}{f}{d}{e}", .{
        .a = ui.setting(.{ .label = "At the minimum", .description = "value equals min: the − button is off", .control = ui.stepper(.{ .name = "s-min", .label = "Guests at the minimum", .value = 1, .min = 1, .max = 10, .z = d.save }) }),
        .b = ui.setting(.{ .label = "At the maximum", .description = "value equals max: the + button is off", .control = ui.stepper(.{ .name = "s-max", .label = "Guests at the maximum", .value = 10, .min = 1, .max = 10, .z = d.save }) }),
        .c = ui.setting(.{ .label = "Wrapping", .description = "+ at 23 goes to 0; buttons never turn off", .control = ui.stepper(.{ .name = "s-wrap", .label = "Wrapping hour", .value = 23, .min = 0, .max = 23, .wrap = true, .editable = false, .z = d.save }) }),
        .f = ui.setting(.{ .label = "Invalid", .description = "invalid: true; typing a value out of range shows it too", .control = ui.stepper(.{ .name = "s-bad", .label = "Guests, invalid", .value = 12, .min = 1, .max = 10, .invalid = true }) }),
        .d = ui.setting(.{ .label = "Disabled", .description = "disabled: true", .control = ui.stepper(.{ .name = "s-off", .label = "Retries", .value = 3, .min = 0, .max = 5, .disabled = true }) }),
        .e = ui.setting(.{ .label = "Locked by policy", .description = "the whole row is disabled", .disabled = true, .control = ui.stepper(.{ .name = "s-row", .label = "Sync interval in minutes", .value = 15, .min = 5, .max = 60, .unit = "min" }) }),
    }) }).render(w);
}

// Cart: the form posts on every step and the server answers with the total, a progress bar
// and (out of band) the count badge. All state is in the request.
const prices = [3]i64{ 4, 6, 3 };
const free_from = 40;

const Summary = zw.View(
    "{#if items}<div class=\"zw-row\"><span class=\"zw-grow\">Total</span><strong>${total}</strong></div>{bar}" ++
        "{:else}<span>Your order is empty.</span>{/if}{#if oob}{badge}{/if}",
    struct { items: i64, total: i64, bar: ui.Progress, badge: ui.Badge, oob: bool },
);

fn countBadge(items: i64, oob: bool) ui.Badge {
    const n: u32 = @intCast(items);
    return ui.badge(.{ .id = "demo-stepper-count", .oob = oob, .count = n, .tone = .red, .solid = true, .hide_zero = true });
}

fn summary(qty: [3]i64, oob: bool) Summary {
    var items: i64 = 0;
    var total: i64 = 0;
    for (qty, prices) |q, price| {
        items += q;
        total += q * price;
    }
    const reached = total >= free_from;
    const pct: u8 = @intCast(@min(100, @divTrunc(total * 100, free_from)));
    return .{ .data = .{
        .items = items,
        .total = total,
        .bar = ui.progress(.{
            .value = pct,
            .label = "Progress to free delivery",
            .text = if (reached) "Free delivery" else "Free delivery from $40",
            .tone = if (reached) .success else .accent,
            .size = .small,
        }),
        .badge = countBadge(items, oob),
        .oob = oob,
    } };
}

fn cart(w: *Writer) Writer.Error!void {
    try zw.view("<form{z}>{card}</form>", .{
        .z = ui.Z{ .post = "/demo/stepper/cart", .trigger = "change", .target = "#demo-stepper-summary", .swap = .inner, .keep = true },
        .card = ui.card(.{
            .title = "Your order",
            .accessory = countBadge(3, false),
            .body = zw.view("{a}{b}{c}<div id=\"demo-stepper-summary\" class=\"demo-stepper-out\">{s}</div>", .{
                .a = ui.setting(.{ .label = "Notebook", .description = "$4 each", .control = ui.stepper(.{ .name = "demo-stepper-notebook", .label = "Notebooks", .value = 1, .min = 0, .max = 9 }) }),
                .b = ui.setting(.{ .label = "Pencil set", .description = "$6 a set", .control = ui.stepper(.{ .name = "demo-stepper-pencils", .label = "Pencil sets", .value = 2, .min = 0, .max = 9 }) }),
                .c = ui.setting(.{ .label = "Sticky notes", .description = "$3 a pad", .control = ui.stepper(.{ .name = "demo-stepper-notes", .label = "Sticky note pads", .value = 0, .min = 0, .max = 9 }) }),
                .s = summary(.{ 1, 2, 0 }, false),
            }),
        }),
    }).render(w);
}

fn quantity(c: *zw.Ctx, name: []const u8) i64 {
    const n = std.fmt.parseInt(i64, c.form(name) orelse "", 10) catch 0;
    return std.math.clamp(n, 0, 9);
}

fn cartUpdate(c: *zw.Ctx) !void {
    try c.page(summary(.{ quantity(c, "demo-stepper-notebook"), quantity(c, "demo-stepper-pencils"), quantity(c, "demo-stepper-notes") }, true));
}

// Alarm: two wrapping, button-only steppers and a switch share one form.
const Alarm = zw.View(
    "{#if on}Rings at <strong>{time}</strong>{:else}Alarm is off{/if}",
    struct { time: []const u8, on: bool },
);

fn alarmText(buf: *[8]u8, hour: i64, minute: i64, on: bool) Alarm {
    const time = std.fmt.bufPrint(buf, "{d:0>2}:{d:0>2}", .{ @as(u8, @intCast(hour)), @as(u8, @intCast(minute)) }) catch unreachable;
    return .{ .data = .{ .time = time, .on = on } };
}

fn alarm(w: *Writer) Writer.Error!void {
    var buf: [8]u8 = undefined;
    try ui.card(.{ .title = "Alarm", .body = zw.view("<form{z}>{a}{b}<p id=\"demo-stepper-alarm\" class=\"demo-stepper-out\">{s}</p></form>", .{
        .z = ui.Z{ .post = "/demo/stepper/alarm", .trigger = "change", .target = "#demo-stepper-alarm", .swap = .inner, .keep = true },
        .a = ui.toggle(.{ .name = "demo-stepper-on", .label = "Alarm", .on = true }),
        .b = ui.setting(.{ .label = "Time", .control = zw.view("<span class=\"zw-row demo-stepper-time\">{h}<span aria-hidden=\"true\">:</span>{m}</span>", .{
            .h = ui.stepper(.{ .name = "demo-stepper-hour", .label = "Hour", .value = 7, .min = 0, .max = 23, .wrap = true, .editable = false }),
            .m = ui.stepper(.{ .name = "demo-stepper-minute", .label = "Minute", .value = 30, .min = 0, .max = 55, .step = 5, .wrap = true, .editable = false }),
        }) }),
        .s = alarmText(&buf, 7, 30, true),
    }) }).render(w);
}

fn alarmUpdate(c: *zw.Ctx) !void {
    const hour = std.math.clamp(std.fmt.parseInt(i64, c.form("demo-stepper-hour") orelse "", 10) catch 0, 0, 23);
    const minute = std.math.clamp(std.fmt.parseInt(i64, c.form("demo-stepper-minute") orelse "", 10) catch 0, 0, 59);
    const buf = try c.arena.create([8]u8);
    try c.page(alarmText(buf, hour, minute, c.form("demo-stepper-on") != null));
}
