//! Live demos for docs/pages/components/setting.md (```demo setting``` fences).
const std = @import("std");
const Writer = std.Io.Writer;
const zw = @import("zigworks");
const ui = zw.ui;
const d = @import("demo.zig");

/// Fence name, block layout (stacked) or inline (wrapping row), render function.
pub const demos = [_]d.Demo{
    .{ "setting", true, setting },
    .{ "setting-rows", true, rows },
    .{ "setting-states", true, states },
    .{ "setting-live", true, live },
    .{ "setting-mail", true, mail },
};
/// Extra CSS for these demos (scope it under a demo-specific class).
pub const css =
    \\.demo-setting{display:flex;flex-direction:column;gap:12px;width:100%;
    \\  & .zw-field{flex:0 1 200px}}
    \\.demo-setting-slot{border-top:1px solid var(--separator);margin-top:6px;padding-top:6px}
    \\
;
/// Server routes these demos need, e.g. `.{ "POST /demo/setting/x", handler }`.
pub const routes = .{
    .{ "POST /demo/setting/night", night },
    .{ "POST /demo/setting/warmth", warmth },
    .{ "POST /demo/setting/update", update },
    .{ "POST /demo/setting/mail", mailSave },
};

// Hero: a System Settings "Sound" pane.
fn setting(w: *Writer) Writer.Error!void {
    try ui.card(.{ .title = "Sound", .body = zw.view("{a}{b}{c}{d}", .{
        .a = ui.setting(.{ .label = "Output volume", .icon = "🔊", .control = ui.slider(.{ .name = "demo-setting-volume", .label = "Output volume", .value = 70, .show_value = true, .unit = "%", .z = d.save }) }),
        .b = ui.setting(.{ .label = "Alert sound", .description = "Played when a message arrives.", .icon = "🔔", .control = ui.picker(.{ .id = "demo-setting-alert", .name = "demo-setting-alert", .label = "Alert sound", .z = d.save, .options = &.{
            .{ .value = "boop", .label = "Boop", .selected = true },
            .{ .value = "funk", .label = "Funk" },
            .{ .value = "glass", .label = "Glass" },
        } }) }),
        .c = ui.toggle(.{ .name = "demo-setting-feedback", .label = "Play feedback when volume is changed", .on = true, .z = d.save }),
        .d = ui.setting(.{ .label = "Output device", .icon = "🎧", .href = "#demo-setting-output", .control = "MacBook Pro Speakers" }),
    }) }).render(w);
}

// Each prop on its own: the card subtitle names the props the rows use.
fn rows(w: *Writer) Writer.Error!void {
    try zw.view("<div class=\"demo-setting\">{a}{b}{c}</div>", .{
        .a = ui.card(.{ .title = "Text", .subtitle = "label, description, control", .body = zw.view("{a}{b}{c}", .{
            .a = ui.setting(.{ .label = "Copies", .control = ui.stepper(.{ .name = "demo-setting-copies", .label = "Copies", .value = 1, .min = 1, .max = 99, .z = d.save }) }),
            .b = ui.setting(.{ .label = "Appearance", .description = "Applies to every window.", .control = ui.segmented(.{ .name = "demo-setting-look", .label = "Appearance", .size = .small, .z = d.save, .options = &.{
                .{ .value = "light", .label = "Light" },
                .{ .value = "dark", .label = "Dark" },
                .{ .value = "auto", .label = "Auto", .selected = true },
            } }) }),
            .c = ui.setting(.{ .label = "Language", .control = "English" }),
        }) }),
        .b = ui.card(.{ .title = "Icon", .subtitle = "icon, control", .body = zw.view("{a}{b}{c}", .{
            .a = ui.setting(.{ .label = "Notifications", .icon = "🔔", .control = ui.button(.{ .label = "Options…", .variant = .plain, .z = d.save }) }),
            .b = ui.setting(.{ .label = "Lock Screen", .icon = "🔒", .control = ui.picker(.{ .id = "demo-setting-lock", .name = "demo-setting-lock", .label = "Require password", .z = d.save, .options = &.{
                .{ .value = "1", .label = "After 1 minute" },
                .{ .value = "5", .label = "After 5 minutes", .selected = true },
                .{ .value = "15", .label = "After 15 minutes" },
            } }) }),
            .c = ui.setting(.{ .label = "Focus", .icon = "🌙", .control = "Off" }),
        }) }),
        .c = ui.card(.{ .title = "Navigation", .subtitle = "href, icon, description, string control", .body = zw.view("{a}{b}{c}", .{
            .a = ui.setting(.{ .label = "Wi-Fi", .icon = "📶", .href = "#demo-setting-rows", .control = "Home" }),
            .b = ui.setting(.{ .label = "Bluetooth", .icon = "🔵", .href = "#demo-setting-rows", .control = "On" }),
            .c = ui.setting(.{ .label = "VPN", .description = "Not configured.", .icon = "🌐", .href = "#demo-setting-rows" }),
        }) }),
    }).render(w);
}

fn states(w: *Writer) Writer.Error!void {
    try zw.view("<div class=\"demo-setting\">{a}{b}{c}{d}</div>", .{
        .a = ui.card(.{ .title = "Disabled", .subtitle = "disabled", .body = zw.view("{a}{b}", .{
            .a = ui.setting(.{ .label = "Sync interval", .description = "Turned off by your administrator.", .disabled = true, .control = ui.stepper(.{ .name = "demo-setting-sync", .label = "Sync interval in minutes", .value = 15, .min = 5, .max = 60, .unit = "min" }) }),
            .b = ui.setting(.{ .label = "AirDrop", .description = "A disabled row is never a link.", .icon = "📡", .href = "#demo-setting-states", .disabled = true, .control = "Off" }),
        }) }),
        .b = ui.card(.{ .title = "Loading and status", .subtitle = "a loading button, badges as controls", .body = zw.view("{a}{b}{c}{d}", .{
            .a = ui.setting(.{ .label = "Software Update", .description = "Looking for new versions…", .icon = "🔄", .control = ui.button(.{ .label = "Checking", .loading = true }) }),
            .b = ui.setting(.{ .label = "Backup", .description = "Last backup: today, 09:41.", .icon = "💾", .control = ui.badge(.{ .text = "Up to date", .tone = .green }) }),
            .c = ui.setting(.{ .label = "Storage", .icon = "🗄️", .control = ui.badge(.{ .text = "Almost full", .tone = .orange }) }),
            .d = ui.setting(.{ .label = "Notifications", .icon = "🔔", .control = ui.badge(.{ .count = 3, .tone = .red, .solid = true }) }),
        }) }),
        .c = ui.card(.{ .title = "Invalid value", .subtitle = "a field with an error as the control", .body = ui.setting(.{
            .label = "Server port",
            .description = "Between 1 and 65535.",
            .control = ui.field(.{ .name = "demo-setting-port", .label = "Server port", .type = "number", .value = "70000", .inputmode = "numeric", .invalid = "That port is out of range." }),
        }) }),
        .d = ui.card(.{ .title = "No control", .subtitle = "control left out", .body = ui.setting(.{ .label = "External disks", .description = "None connected. Plug in a drive to manage it here.", .icon = "💽" }) }),
    }).render(w);
}

// Live: the toggle swaps the Warmth row and the status badge out of band, the slider updates the
// badge, the button replaces its own row. All state travels in the request.

/// The Warmth row. It is dimmed and disabled until Night Shift is on.
const WarmthRow = struct {
    on: bool,
    pub fn render(s: WarmthRow, w: *Writer) Writer.Error!void {
        try zw.view("<div id=\"demo-setting-warmth\" class=\"demo-setting-slot\" z-oob>{row}</div>", .{
            .row = ui.setting(.{ .label = "Warmth", .description = "Shifts the display toward amber.", .disabled = !s.on, .control = ui.slider(.{
                .name = "demo-setting-warmth",
                .label = "Warmth",
                .value = 50,
                .show_value = true,
                .unit = "%",
                .z = .{ .post = "/demo/setting/warmth", .swap = .none, .trigger = "input" },
            }) }),
        }).render(w);
    }
};

/// The Software Update row; `checks` is how many times the button has been pressed.
const UpdateRow = struct {
    checks: u8,
    pub fn render(s: UpdateRow, w: *Writer) Writer.Error!void {
        var url: [48]u8 = undefined;
        var desc: [48]u8 = undefined;
        try ui.setting(.{
            .label = "Software Update",
            .description = if (s.checks == 0) "Not checked yet." else std.fmt.bufPrint(&desc, "Up to date. Checked {d} time(s).", .{s.checks}) catch "Up to date.",
            .icon = "🔄",
            .control = ui.button(.{ .label = "Check Now", .z = .{
                .post = std.fmt.bufPrint(&url, "/demo/setting/update?n={d}", .{s.checks}) catch "/demo/setting/update",
                .target = "#demo-setting-update",
                .swap = .inner,
            } }),
        }).render(w);
    }
};

/// The badge in the card header; `oob` lets any response replace it.
fn status(text: []const u8, on: bool) ui.Badge {
    return ui.badge(.{ .id = "demo-setting-status", .oob = true, .text = text, .tone = if (on) .accent else .gray });
}

fn live(w: *Writer) Writer.Error!void {
    try ui.card(.{
        .title = "Display",
        .accessory = status("Off", false),
        .body = zw.view("{night}{warmth}<div id=\"demo-setting-update\" class=\"demo-setting-slot\">{update}</div>", .{
            .night = ui.toggle(.{ .name = "demo-setting-night", .label = "Night Shift", .description = "Warms the display after sunset.", .z = .{ .post = "/demo/setting/night", .swap = .none } }),
            .warmth = WarmthRow{ .on = false },
            .update = UpdateRow{ .checks = 0 },
        }),
    }).render(w);
}

fn night(c: *zw.Ctx) !void {
    // A switched-off checkbox sends nothing.
    const on = c.form("demo-setting-night") != null;
    try c.page(zw.view("{warmth}{status}{toast}", .{
        .warmth = WarmthRow{ .on = on },
        .status = status(if (on) "Sunset to sunrise" else "Off", on),
        .toast = ui.toast(.{ .text = if (on) "Night Shift is on until sunrise." else "Night Shift is off." }),
    }));
}

fn warmth(c: *zw.Ctx) !void {
    const pct = std.fmt.parseInt(u8, c.form("demo-setting-warmth") orelse "50", 10) catch 50;
    try c.page(status(try c.arena.print("Warmth {d}%", .{pct}), true));
}

fn update(c: *zw.Ctx) !void {
    const n = std.fmt.parseInt(u8, c.query("n") orelse "0", 10) catch 0;
    try c.page(UpdateRow{ .checks = n +| 1 });
}

// Composition: setting rows, a toggle, a field and a picker in one form card.
fn mail(w: *Writer) Writer.Error!void {
    try zw.view("<div class=\"demo-setting\"><form{z}>{card}</form>{note}</div>", .{
        .z = ui.Z{ .post = "/demo/setting/mail", .swap = .none, .keep = true },
        .card = ui.card(.{
            .title = "Mail account",
            .subtitle = "ada@example.com",
            .accessory = ui.badge(.{ .text = "Connected", .tone = .green }),
            .footer = ui.button(.{ .label = "Save", .variant = .primary, .type = .submit }),
            .body = zw.view("{a}{b}{c}{d}", .{
                .a = ui.setting(.{ .label = "Account name", .icon = "✉️", .control = ui.field(.{ .name = "demo-setting-account", .label = "Account name", .value = "Work", .placeholder = "Name" }) }),
                .b = ui.setting(.{ .label = "Check for new mail", .description = "More often uses more battery.", .control = ui.picker(.{ .id = "demo-setting-interval", .name = "demo-setting-interval", .label = "Check interval", .options = &.{
                    .{ .value = "5", .label = "Every 5 minutes" },
                    .{ .value = "15", .label = "Every 15 minutes", .selected = true },
                    .{ .value = "60", .label = "Every hour" },
                } }) }),
                .c = ui.toggle(.{ .name = "demo-setting-notify", .label = "Notify for new mail", .on = true }),
                .d = ui.setting(.{ .label = "Signature", .href = "#demo-setting-mail", .control = "Sent from my Mac" }),
            }),
        }),
        .note = ui.callout(.{ .compact = true, .body = "Changes apply to this account only." }),
    }).render(w);
}

fn mailSave(c: *zw.Ctx) !void {
    const name = std.mem.trim(u8, c.form("demo-setting-account") orelse "", " ");
    if (name.len == 0) return c.page(ui.toast(.{ .text = "Give the account a name.", .kind = .@"error" }));
    const every = c.form("demo-setting-interval") orelse "15";
    const notify = if (c.form("demo-setting-notify") != null) "on" else "off";
    try c.page(ui.toast(.{
        .text = try c.arena.print("Saved “{s}”: every {s} min, notifications {s}.", .{ name, every, notify }),
        .kind = .success,
    }));
}
