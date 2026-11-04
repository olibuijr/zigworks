//! Live demos for docs/pages/components/check.md (```demo check``` fences).
const std = @import("std");
const Writer = std.Io.Writer;
const zw = @import("zigworks");
const ui = zw.ui;
const d = @import("demo.zig");

/// Fence name, block layout (stacked) or inline (wrapping row), render function.
pub const demos = [_]d.Demo{
    .{ "check", true, check },
    .{ "check-sizes", true, sizes },
    .{ "check-states", true, states },
    .{ "check-progress", true, progress },
    .{ "check-add", true, add },
};
/// Extra CSS for these demos (scope it under a demo-specific class).
pub const css =
    \\.demo-check-grid{display:grid;grid-template-columns:auto repeat(5,minmax(0,1fr));gap:14px 4px;align-items:center;justify-items:center}
    \\.demo-check-grid>small{color:var(--secondary);font-size:12px}
    \\.demo-check-size{justify-self:start;display:grid;margin-right:8px}
    \\.demo-check-size small{color:var(--secondary);font-size:12px}
    \\.demo-check-text{display:grid;justify-items:start}
    \\.demo-check-text small{font:var(--callout);color:var(--secondary)}
    \\.demo-check-meter{margin-bottom:8px}
    \\.demo-check-add{display:grid;gap:12px;margin-bottom:12px}
    \\
;
/// Server routes these demos need, e.g. `.{ "POST /demo/check/x", handler }`.
/// No server state: every request carries what the response needs.
pub const routes = .{
    .{ "POST /demo/check/flip", flipRoute },
    .{ "POST /demo/check/reminders", remindersRoute },
    .{ "POST /demo/check/launch", launchRoute },
    .{ "POST /demo/check/row", rowRoute },
    .{ "POST /demo/check/add", addRoute },
};

// The component does not export its enums, so take them from its props.
const Size = @TypeOf(ui.check(.{ .on = false, .label = "" }).data.size);
const Tint = @TypeOf(ui.check(.{ .on = false, .label = "" }).data.tint);

/// A check that flips itself: the URL carries the current state and the look.
const Flip = struct {
    on: bool,
    /// Shown as a dash; the next click checks it.
    mixed: bool = false,
    label: []const u8,
    size: Size = .regular,
    tint: Tint = .accent,

    pub fn render(self: Flip, w: *Writer) Writer.Error!void {
        var buf: [256]u8 = undefined;
        const url = std.fmt.bufPrint(&buf, "/demo/check/flip?d={d}&m={d}&s={t}&c={t}&l={f}", .{
            @intFromBool(self.on), @intFromBool(self.mixed), self.size, self.tint, std.fmt.alt(std.Uri.Component{ .raw = self.label }, .formatEscaped),
        }) catch "/demo/check/flip";
        try ui.check(.{ .on = self.on, .mixed = self.mixed, .label = self.label, .size = self.size, .tint = self.tint, .z = .{ .post = url, .swap = .outer } }).render(w);
    }
};

fn flipRoute(c: *zw.Ctx) !void {
    const was_on = std.mem.eql(u8, c.query("d") orelse "0", "1");
    const was_mixed = std.mem.eql(u8, c.query("m") orelse "0", "1");
    try c.page(Flip{
        .on = was_mixed or !was_on,
        .label = c.query("l") orelse "Check",
        .size = std.meta.stringToEnum(Size, c.query("s") orelse "") orelse .regular,
        .tint = std.meta.stringToEnum(Tint, c.query("c") orelse "") orelse .accent,
    });
}

const Item = struct { title: []const u8, note: []const u8 = "", tint: Tint = .accent };

/// List rows that are done or not according to the bits of `mask`. Each check posts the mask with
/// its own bit flipped to `route` and swaps the list `list_id` (a selector), so the page is the only state.
const MaskRows = struct {
    route: []const u8,
    list_id: []const u8,
    items: []const Item,
    mask: u8,

    pub fn render(self: MaskRows, w: *Writer) Writer.Error!void {
        for (self.items, 0..) |item, i| {
            const bit = @as(u8, 1) << @intCast(i);
            var buf: [64]u8 = undefined;
            const url = std.fmt.bufPrint(&buf, "{s}?s={d}", .{ self.route, self.mask ^ bit }) catch self.route;
            const done = self.mask & bit != 0;
            try zw.view("<li>{c}<span class=\"zw-grow demo-check-text\"><span{#if done} class=\"is-done\"{/if}>{title}</span>{#if note}<small>{note}</small>{/if}</span></li>", .{
                .c = ui.check(.{ .on = done, .label = item.title, .tint = item.tint, .z = .{ .post = url, .target = self.list_id, .swap = .outer } }),
                .done = done,
                .title = item.title,
                .note = item.note,
            }).render(w);
        }
    }
};

/// Mask from `?s=`, limited to the first `n` rows.
fn maskOf(c: *zw.Ctx, n: u3) u8 {
    const v = std.fmt.parseInt(u8, c.query("s") orelse "0", 10) catch 0;
    return v & ((@as(u8, 1) << n) - 1);
}

fn remaining(total: u32, mask: u8) u32 {
    return total - @popCount(mask);
}

// 1. Hero: Reminders. Toggling a row answers with the whole list and an out-of-band badge.
const reminders = [_]Item{
    .{ .title = "Call the dentist", .note = "Today, 9:30" },
    .{ .title = "Send the invoice", .note = "Flagged", .tint = .orange },
    .{ .title = "Renew passport", .note = "Overdue", .tint = .red },
    .{ .title = "Book flights to Lisbon", .note = "Travel" },
};

fn remindersList(mask: u8) ui.List(MaskRows) {
    return ui.list(.{ .id = "demo-check-list", .body = MaskRows{ .route = "/demo/check/reminders", .list_id = "#demo-check-list", .items = &reminders, .mask = mask } });
}

fn leftBadge(mask: u8, oob: bool) ui.Badge {
    return ui.badge(.{ .count = remaining(reminders.len, mask), .id = "demo-check-left", .oob = oob, .tone = .accent, .solid = true, .hide_zero = true });
}

fn check(w: *Writer) Writer.Error!void {
    const mask: u8 = 0b0001;
    try ui.card(.{
        .title = "Reminders",
        .subtitle = "Personal",
        .flush = true,
        .accessory = leftBadge(mask, false),
        .body = remindersList(mask),
    }).render(w);
}

fn remindersRoute(c: *zw.Ctx) !void {
    const mask = maskOf(c, reminders.len);
    try c.page(zw.view("{l}{b}", .{ .l = remindersList(mask), .b = leftBadge(mask, true) }));
}

// 2. Variants and sizes. Every cell is a real check: click it.
fn sizes(w: *Writer) Writer.Error!void {
    try w.writeAll("<div class=\"demo-check-grid\"><span></span><small>off</small><small>accent</small><small>red</small><small>orange</small><small>green</small>");
    inline for (.{ .{ "small", "18px", .small }, .{ "regular", "22px", .regular }, .{ "large", "28px", .large } }) |s| {
        try w.writeAll("<span class=\"demo-check-size\">" ++ s[0] ++ "<small>" ++ s[1] ++ "</small></span>");
        try (Flip{ .on = false, .label = s[0] ++ " off", .size = s[2] }).render(w);
        inline for (.{ .{ "accent", .accent }, .{ "red", .red }, .{ "orange", .orange }, .{ "green", .green } }) |t| {
            try (Flip{ .on = true, .label = s[0] ++ " " ++ t[0], .size = s[2], .tint = t[1] }).render(w);
        }
    }
    try w.writeAll("</div>");
}

// 3. States.
fn states(w: *Writer) Writer.Error!void {
    try ui.list(.{ .id = "demo-check-states", .body = zw.view(
        \\<li>{a}<span class="zw-grow demo-check-text">Unchecked<small>Click it, or focus it and press Space</small></span></li>
        \\<li>{b}<span class="zw-grow demo-check-text">Checked<small>aria-checked is true</small></span></li>
        \\<li>{m}<span class="zw-grow demo-check-text">Mixed<small>aria-checked is mixed; the next click checks it</small></span></li>
        \\<li>{c}<span class="zw-grow demo-check-text">Disabled<small>Waiting on a teammate</small></span></li>
        \\<li>{e}<span class="zw-grow demo-check-text">Disabled and checked<small>Completed by the list owner</small></span></li>
    , .{
        .a = Flip{ .on = false, .label = "Unchecked" },
        .b = Flip{ .on = true, .label = "Checked" },
        .m = Flip{ .on = false, .mixed = true, .label = "Mixed" },
        .c = ui.check(.{ .on = false, .label = "Disabled", .disabled = true }),
        .e = ui.check(.{ .on = true, .label = "Disabled and checked", .disabled = true }),
    }) }).render(w);
}

// 4. A checklist with a progress bar and a toast, both sent next to the list.
const launch = [_]Item{
    .{ .title = "Run the test suite", .tint = .green },
    .{ .title = "Update the changelog", .tint = .green },
    .{ .title = "Tag the release", .tint = .green },
    .{ .title = "Deploy to staging", .tint = .green },
    .{ .title = "Announce it", .tint = .green },
};

const Meter = struct {
    mask: u8,
    oob: bool,

    pub fn render(self: Meter, w: *Writer) Writer.Error!void {
        const total: u32 = launch.len;
        const done = total - remaining(total, self.mask);
        var buf: [32]u8 = undefined;
        const text = std.fmt.bufPrint(&buf, "{d} of {d} done", .{ done, total }) catch "";
        try w.writeAll(if (self.oob) "<div class=\"demo-check-meter\" id=\"demo-check-meter\" z-oob>" else "<div class=\"demo-check-meter\" id=\"demo-check-meter\">");
        try ui.progress(.{ .value = @as(u8, @intCast(done * 100 / total)), .label = "Release progress", .text = text, .show_value = true, .tone = .success }).render(w);
        try w.writeAll("</div>");
    }
};

fn launchList(mask: u8) ui.List(MaskRows) {
    return ui.list(.{ .id = "demo-check-launch", .inset = false, .body = MaskRows{ .route = "/demo/check/launch", .list_id = "#demo-check-launch", .items = &launch, .mask = mask } });
}

fn progress(w: *Writer) Writer.Error!void {
    const mask: u8 = 0b00011;
    try ui.card(.{
        .title = "Release 0.2",
        .subtitle = "Check every step to ship",
        .body = zw.view("{m}{l}", .{ .m = Meter{ .mask = mask, .oob = false }, .l = launchList(mask) }),
    }).render(w);
}

fn launchRoute(c: *zw.Ctx) !void {
    const mask = maskOf(c, launch.len);
    try c.page(zw.view("{l}{m}{#if full}{t}{/if}", .{
        .l = launchList(mask),
        .m = Meter{ .mask = mask, .oob = true },
        .full = remaining(launch.len, mask) == 0,
        .t = ui.toast(.{ .text = "Everything is ready to ship", .kind = .success }),
    }));
}

// 5. Composition: field + colour picker + button add rows; each row is check, title, delete.
const Row = struct {
    done: bool,
    title: []const u8,
    tint: Tint,

    pub fn render(self: Row, w: *Writer) Writer.Error!void {
        var buf: [512]u8 = undefined;
        const url = std.fmt.bufPrint(&buf, "/demo/check/row?d={d}&c={t}&t={f}", .{
            @intFromBool(self.done), self.tint, std.fmt.alt(std.Uri.Component{ .raw = self.title }, .formatEscaped),
        }) catch "/demo/check/row";
        try zw.view("<li>{c}<span class=\"zw-grow{#if done} is-done{/if}\">{title}</span>{del}</li>", .{
            .c = ui.check(.{ .on = self.done, .label = self.title, .tint = self.tint, .z = .{ .post = url, .target = "closest li", .swap = .outer } }),
            .done = self.done,
            .title = self.title,
            // An empty 200 from DELETE /demo/todo lets z.js remove the row.
            .del = ui.button(.{ .label = "Delete", .variant = .destructive, .size = .small, .z = .{ .delete = "/demo/todo", .target = "closest li", .swap = .delete } }),
        }).render(w);
    }
};

fn rowRoute(c: *zw.Ctx) !void {
    const was_done = std.mem.eql(u8, c.query("d") orelse "0", "1");
    try c.page(Row{
        .done = !was_done,
        .title = c.query("t") orelse return c.send(.bad_request, "text/plain", "missing t"),
        .tint = std.meta.stringToEnum(Tint, c.query("c") orelse "") orelse .accent,
    });
}

fn addRoute(c: *zw.Ctx) !void {
    const title = std.mem.trim(u8, c.form("title") orelse "", " ");
    if (title.len == 0 or title.len > 120) return c.send(.no_content, "text/plain", "");
    try c.page(Row{
        .done = false,
        .title = title,
        .tint = std.meta.stringToEnum(Tint, c.form("tint") orelse "") orelse .accent,
    });
}

fn add(w: *Writer) Writer.Error!void {
    try ui.card(.{
        .title = "Groceries",
        .subtitle = "Pick a colour for the new item",
        .body = zw.view("<form class=\"demo-check-add\"{z}><div class=\"zw-row\"><div class=\"zw-grow\">{f}</div>{b}</div>{s}</form>{l}", .{
            .z = ui.Z{ .post = "/demo/check/add", .target = "#demo-check-groceries", .swap = .beforeend },
            .f = ui.field(.{ .name = "title", .label = "New item", .placeholder = "Add an item", .required = true, .maxlength = 40 }),
            .b = ui.button(.{ .label = "Add", .variant = .primary, .type = .submit }),
            .s = ui.segmented(.{ .name = "tint", .label = "Colour", .full = true, .options = &.{
                .{ .value = "accent", .label = "Blue", .selected = true },
                .{ .value = "green", .label = "Green" },
                .{ .value = "orange", .label = "Orange" },
                .{ .value = "red", .label = "Red" },
            } }),
            .l = ui.list(.{ .id = "demo-check-groceries", .inset = false, .reveal = true, .empty = "Nothing to buy.", .body = zw.view("{a}{b}{c}", .{
                .a = Row{ .done = true, .title = "Sourdough", .tint = .accent },
                .b = Row{ .done = false, .title = "Oat milk", .tint = .green },
                .c = Row{ .done = false, .title = "Chilli flakes", .tint = .red },
            }) }),
        }),
    }).render(w);
}
