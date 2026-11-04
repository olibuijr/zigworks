//! Live demos for docs/pages/components/toggle.md (```demo toggle``` fences).
const std = @import("std");
const Writer = std.Io.Writer;
const zw = @import("zigworks");
const ui = zw.ui;
const d = @import("demo.zig");

/// Fence name, block layout (stacked) or inline (wrapping row), render function.
pub const demos = [_]d.Demo{
    .{ "toggle", true, toggle },
    .{ "toggle-variants", true, variants },
    .{ "toggle-states", true, states },
    .{ "toggle-focus", true, focus },
    .{ "toggle-wifi", true, wifi },
    .{ "toggle-form", true, form },
};
/// Extra CSS for these demos (scope it under a demo-specific class).
pub const css =
    \\.demo-toggle-nets{margin-top:10px}
    \\
;
/// Server routes these demos need, e.g. `.{ "POST /demo/toggle/x", handler }`.
pub const routes = .{
    .{ "POST /demo/toggle/focus", focusHandler },
    .{ "POST /demo/toggle/wifi", wifiHandler },
    .{ "POST /demo/toggle/prefs", prefsHandler },
};

// Hero: a System Settings style pane. Each switch saves as soon as it flips.
fn toggle(w: *Writer) Writer.Error!void {
    try ui.card(.{
        .title = "Mail Notifications",
        .subtitle = "Choose how Mail gets your attention.",
        .body = zw.view("{a}{b}{c}{d}", .{
            .a = ui.toggle(.{ .name = "allow", .label = "Allow Notifications", .description = "Show alerts from Mail", .on = true, .z = d.save }),
            .b = ui.toggle(.{ .name = "badge", .label = "Badge App Icon", .on = true, .z = d.save }),
            .c = ui.toggle(.{ .name = "sound", .label = "Play Sound", .z = d.save }),
            .d = ui.toggle(.{ .name = "preview", .label = "Show Previews", .description = "Only while your Mac is unlocked", .z = d.save }),
        }),
    }).render(w);
}

// Sizes and label sides, each labelled with the prop that makes it.
fn variants(w: *Writer) Writer.Error!void {
    try zw.view("{a}{b}", .{
        .a = ui.card(.{
            .title = "size",
            .body = zw.view("{a}{b}{c}", .{
                .a = ui.toggle(.{ .name = "regular", .label = "Regular", .description = "size = .regular (default), 46x26", .on = true, .z = d.save }),
                .b = ui.toggle(.{ .name = "small", .label = "Small", .description = "size = .small, 38x22", .on = true, .size = .small, .z = d.save }),
                .c = ui.toggle(.{ .name = "mini", .label = "Mini", .description = "size = .mini, 30x18", .on = true, .size = .mini, .z = d.save }),
            }),
        }),
        .b = ui.card(.{
            .title = "label_side",
            .body = zw.view("{a}{b}", .{
                .a = ui.toggle(.{ .name = "leading", .label = "Label leading", .description = "label_side = .leading (default)", .z = d.save }),
                .b = ui.toggle(.{ .name = "trailing", .label = "Label trailing", .description = "label_side = .trailing: the switch comes first", .label_side = .trailing, .z = d.save }),
            }),
        }),
    }).render(w);
}

// Off, on and disabled, with and without a description.
fn states(w: *Writer) Writer.Error!void {
    try ui.card(.{
        .body = zw.view("{a}{b}{c}{d}", .{
            .a = ui.toggle(.{ .name = "off", .label = "Off", .description = "on = false (default)", .z = d.save }),
            .b = ui.toggle(.{ .name = "on", .label = "On", .description = "on = true", .on = true, .z = d.save }),
            .c = ui.toggle(.{ .name = "locked-off", .label = "Disabled, off", .description = "Turned off by your administrator", .disabled = true }),
            .d = ui.toggle(.{ .name = "locked-on", .label = "Disabled, on", .description = "Required by your organization", .on = true, .disabled = true }),
        }),
    }).render(w);
}

// Flipping the switch updates a badge elsewhere on the page and shows a toast.
fn focus(w: *Writer) Writer.Error!void {
    try ui.card(.{
        .title = "Focus",
        .subtitle = "The status also appears in the menu bar.",
        .accessory = ui.badge(.{ .id = "demo-toggle-focus", .text = "Off" }),
        .body = zw.view("{a}{b}", .{
            .a = ui.toggle(.{ .name = "focus", .label = "Do Not Disturb", .description = "Silence calls and alerts", .z = .{ .post = "/demo/toggle/focus", .swap = .none } }),
            .b = ui.toggle(.{ .name = "share", .label = "Share Across Devices", .on = true, .z = d.save }),
        }),
    }).render(w);
}

fn focusHandler(c: *zw.Ctx) !void {
    // An unchecked switch sends nothing, so a missing field means off.
    const on = c.form("focus") != null;
    try c.html("{badge}{toast}", .{
        .badge = ui.badge(.{ .id = "demo-toggle-focus", .oob = true, .text = if (on) "On" else "Off", .tone = if (on) .accent else .gray }),
        .toast = ui.toast(.{ .text = if (on) "Do Not Disturb is on" else "Do Not Disturb is off" }),
    });
}

// A switch that decides what the rest of the pane shows.
fn wifi(w: *Writer) Writer.Error!void {
    try ui.card(.{
        .title = "Network",
        .body = zw.view("{a}<div id=\"demo-toggle-nets\" class=\"demo-toggle-nets\">{b}</div>", .{
            .a = ui.toggle(.{ .name = "wifi", .label = "Wi-Fi", .description = "Join known networks automatically", .on = true, .z = .{ .post = "/demo/toggle/wifi", .target = "#demo-toggle-nets", .swap = .inner } }),
            .b = Networks{ .on = true },
        }),
    }).render(w);
}

/// The network list, or an empty state while Wi-Fi is off. Any value with `render` is a component.
const Networks = struct {
    on: bool,

    pub fn render(self: Networks, w: *Writer) Writer.Error!void {
        if (!self.on) return ui.empty(.{ .icon = "\u{1F4F6}", .title = "Wi-Fi is Off", .text = "Turn on Wi-Fi to see nearby networks.", .size = .compact }).render(w);
        try ui.list(.{
            .id = "demo-toggle-list",
            .inset = false,
            .body = zw.view("<li><span class=\"zw-grow\">Home</span>{a}</li><li><span class=\"zw-grow\">Guest</span></li><li><span class=\"zw-grow\">Studio 5G</span></li>", .{
                .a = ui.badge(.{ .text = "Connected", .tone = .green }),
            }),
        }).render(w);
    }
};

fn wifiHandler(c: *zw.Ctx) !void {
    try c.page(Networks{ .on = c.form("wifi") != null });
}

// A form: the switches carry no request of their own, Save sends them all.
fn form(w: *Writer) Writer.Error!void {
    try zw.view("<form class=\"zw-stack\" z-post=\"/demo/toggle/prefs\" z-swap=\"none\" z-keep>{card}</form>", .{
        .card = ui.card(.{
            .title = "Privacy",
            .subtitle = "Share nothing unless you choose to.",
            .body = zw.view("{a}{b}{c}", .{
                .a = ui.toggle(.{ .name = "analytics", .label = "Share Analytics", .description = "Usage data, never your content", .on = true }),
                .b = ui.toggle(.{ .name = "crashes", .label = "Share Crash Reports" }),
                .c = ui.toggle(.{ .name = "ads", .label = "Personalised Ads", .description = "Not available in your region", .disabled = true }),
            }),
            .footer = ui.button(.{ .label = "Save", .variant = .primary, .type = .submit }),
        }),
    }).render(w);
}

fn prefsHandler(c: *zw.Ctx) !void {
    var on: usize = 0;
    inline for (.{ "analytics", "crashes", "ads" }) |name| {
        if (c.form(name) != null) on += 1;
    }
    const text = try std.fmt.allocPrint(c.arena, "Saved. {d} of 3 options are on.", .{on});
    try c.page(ui.toast(.{ .text = text, .kind = .success }));
}
