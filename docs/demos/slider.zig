//! Live demos for docs/pages/components/slider.md (```demo slider``` fences).
const std = @import("std");
const Writer = std.Io.Writer;
const zw = @import("zigworks");
const ui = zw.ui;
const d = @import("demo.zig");

/// Fence name, block layout (stacked) or inline (wrapping row), render function.
pub const demos = [_]d.Demo{
    .{ "slider", true, slider },
    .{ "slider-extras", true, extras },
    .{ "slider-states", true, states },
    .{ "slider-text-size", true, textSize },
    .{ "slider-export", true, exportPhoto },
};
/// Extra CSS for these demos (scope it under a demo-specific class).
pub const css = ".demo-slider-sample{margin:12px 0 0;padding:12px 14px;border-radius:10px;background:var(--fill);font-size:var(--demo-size,13px);line-height:1.4;overflow-wrap:anywhere}";
/// Server routes these demos need, e.g. `.{ "POST /demo/slider/x", handler }`.
pub const routes = .{
    .{ "POST /demo/slider/text-size", textSizeRoute },
    .{ "POST /demo/slider/estimate", estimateRoute },
    .{ "POST /demo/slider/export", exportRoute },
};

/// A form value as a number inside [lo, hi]; `fallback` when missing or not a number.
fn num(v: ?[]const u8, lo: i64, hi: i64, fallback: i64) i64 {
    const n = std.fmt.parseInt(i64, v orelse return fallback, 10) catch return fallback;
    return std.math.clamp(n, lo, hi);
}

// Hero: a System Settings "Sound" pane. Sliders save when the thumb is released.
fn slider(w: *Writer) Writer.Error!void {
    try ui.card(.{
        .title = "Sound",
        .subtitle = "Output: MacBook Pro Speakers",
        .body = zw.view("{a}{b}{c}", .{
            .a = ui.setting(.{ .label = "Output volume", .control = ui.slider(.{ .name = "volume", .label = "Output volume", .value = 65, .min_label = "Quiet", .max_label = "Loud", .z = d.save }) }),
            .b = ui.setting(.{ .label = "Alert volume", .control = ui.slider(.{ .name = "alert-volume", .label = "Alert volume", .value = 40, .show_value = true, .unit = "%", .z = d.save }) }),
            .c = ui.setting(.{ .label = "Balance", .control = ui.slider(.{ .name = "balance", .label = "Balance", .min = -50, .max = 50, .step = 10, .value = 0, .ticks = 10, .min_label = "Left", .max_label = "Right", .z = d.save }) }),
        }),
    }).render(w);
}

// Each row names the props it shows.
fn extras(w: *Writer) Writer.Error!void {
    try ui.card(.{ .body = zw.view("{a}{b}{c}{d}{e}", .{
        .a = ui.setting(.{ .label = "Plain", .description = ".min .max .value", .control = ui.slider(.{ .name = "plain", .label = "Plain", .value = 50, .z = d.save }) }),
        .b = ui.setting(.{ .label = "End labels", .description = ".min_label .max_label", .control = ui.slider(.{ .name = "ends", .label = "End labels", .value = 30, .min_label = "Quiet", .max_label = "Loud", .z = d.save }) }),
        .c = ui.setting(.{ .label = "Value readout", .description = ".show_value .unit", .control = ui.slider(.{ .name = "readout", .label = "Value readout", .value = 72, .show_value = true, .unit = "%", .z = d.save }) }),
        .d = ui.setting(.{ .label = "Tick marks", .description = ".ticks = 4 draws 5 marks", .control = ui.slider(.{ .name = "ticks", .label = "Tick marks", .min = 0, .max = 4, .value = 2, .ticks = 4, .z = d.save }) }),
        .e = ui.setting(.{ .label = "Range and step", .description = ".min .max .step", .control = ui.slider(.{ .name = "delay", .label = "Delay", .min = 0, .max = 500, .step = 50, .value = 200, .ticks = 10, .show_value = true, .unit = " ms", .z = d.save }) }),
    }) }).render(w);
}

fn states(w: *Writer) Writer.Error!void {
    try ui.card(.{ .body = zw.view("{a}{b}{c}{d}", .{
        .a = ui.setting(.{ .label = "At the minimum", .control = ui.slider(.{ .name = "at-min", .label = "At the minimum", .value = 0, .show_value = true, .z = d.save }) }),
        .b = ui.setting(.{ .label = "At the maximum", .control = ui.slider(.{ .name = "at-max", .label = "At the maximum", .value = 100, .show_value = true, .z = d.save }) }),
        .c = ui.setting(.{ .label = "Disabled", .description = ".disabled on the slider", .control = ui.slider(.{ .name = "off", .label = "Disabled", .value = 40, .disabled = true }) }),
        .d = ui.setting(.{ .label = "Brightness", .description = "Locked by your administrator.", .disabled = true, .control = ui.slider(.{ .name = "locked", .label = "Brightness", .value = 80, .min_label = "Dim", .max_label = "Bright" }) }),
    }) }).render(w);
}

// Live text size: the slider posts while you drag; the reply replaces the preview and the badge.
const Sample = zw.View(
    "<p class=\"demo-slider-sample\" id=\"demo-slider-sample\" style=\"--demo-size:{px}px\"{#if oob} z-oob{/if}>Ada Lovelace published her notes on the Analytical Engine in 1843.</p>",
    struct { px: i64, oob: bool },
);

fn sample(px: i64, oob: bool) Sample {
    return .{ .data = .{ .px = px, .oob = oob } };
}

fn sizeBadge(px: i64, oob: bool) ui.Badge {
    const name: []const u8 = if (px <= 11) "Small" else if (px <= 15) "Default" else if (px <= 19) "Large" else "Extra large";
    return ui.badge(.{ .text = name, .id = "demo-slider-size", .oob = oob, .tone = if (px >= 12 and px <= 15) .gray else .accent });
}

fn textSizeRoute(c: *zw.Ctx) !void {
    const px = num(c.form("size"), 10, 24, 13);
    try c.html("{a}{b}", .{ .a = sample(px, true), .b = sizeBadge(px, true) });
}

fn textSize(w: *Writer) Writer.Error!void {
    try ui.card(.{
        .title = "Text size",
        .subtitle = "Reading view",
        .accessory = sizeBadge(13, false),
        .body = zw.view("{s}{p}", .{
            .s = ui.slider(.{ .name = "size", .label = "Text size", .min = 10, .max = 24, .value = 13, .ticks = 14, .min_label = "Small", .max_label = "Large", .show_value = true, .unit = " pt", .z = .{ .post = "/demo/slider/text-size", .trigger = "input", .swap = .none } }),
            .p = sample(13, false),
        }),
    }).render(w);
}

// Export sheet: the form posts every control on each change; the reply updates the size badge.
fn estimate(buf: []u8, format: []const u8, quality: i64, scale: i64) []const u8 {
    var kb = @divTrunc(18000 * scale * scale, 10000);
    if (std.mem.eql(u8, format, "png")) {
        kb = @divTrunc(kb * 60, 100);
    } else if (std.mem.eql(u8, format, "heic")) {
        kb = @divTrunc(kb * quality, 800);
    } else {
        kb = @divTrunc(kb * quality, 400);
    }
    var w: Writer = .fixed(buf);
    if (kb >= 1000) {
        w.print("{d}.{d} MB", .{ @divTrunc(kb, 1000), @divTrunc(@rem(kb, 1000), 100) }) catch {};
    } else {
        w.print("{d} KB", .{kb}) catch {};
    }
    return w.buffered();
}

fn estimateBadge(buf: []u8, format: []const u8, quality: i64, scale: i64, oob: bool) ui.Badge {
    return ui.badge(.{ .text = estimate(buf, format, quality, scale), .id = "demo-slider-estimate", .oob = oob, .tone = .accent });
}

fn estimateRoute(c: *zw.Ctx) !void {
    const buf = try c.arena.alloc(u8, 32);
    try c.page(estimateBadge(buf, c.form("format") orelse "jpeg", num(c.form("quality"), 20, 100, 60), num(c.form("scale"), 25, 100, 100), true));
}

fn exportRoute(c: *zw.Ctx) !void {
    try c.page(ui.toast(.{ .text = "Photo exported", .kind = .success }));
}

fn exportPhoto(w: *Writer) Writer.Error!void {
    var buf: [32]u8 = undefined;
    try zw.view("<form{z}>{card}</form>", .{
        .z = ui.Z{ .post = "/demo/slider/estimate", .trigger = "change", .swap = .none, .keep = true },
        .card = ui.card(.{
            .title = "Export Photo",
            .subtitle = "IMG_0042",
            .body = zw.view("{a}{b}{c}{d}", .{
                .a = ui.setting(.{ .label = "Format", .control = ui.segmented(.{ .name = "format", .label = "Format", .options = &.{ .{ .value = "jpeg", .label = "JPEG", .selected = true }, .{ .value = "png", .label = "PNG" }, .{ .value = "heic", .label = "HEIC" } } }) }),
                .b = ui.setting(.{ .label = "Quality", .description = "PNG ignores quality.", .control = ui.slider(.{ .name = "quality", .label = "Quality", .min = 20, .max = 100, .step = 20, .value = 60, .ticks = 4, .min_label = "Low", .max_label = "High" }) }),
                .c = ui.setting(.{ .label = "Scale", .control = ui.slider(.{ .name = "scale", .label = "Scale", .min = 25, .max = 100, .step = 25, .value = 100, .ticks = 3, .show_value = true, .unit = "%" }) }),
                .d = ui.setting(.{ .label = "Estimated size", .control = estimateBadge(&buf, "jpeg", 60, 100, false) }),
            }),
            .footer = ui.button(.{ .label = "Export", .variant = .primary, .z = .{ .post = "/demo/slider/export", .swap = .none } }),
        }),
    }).render(w);
}
