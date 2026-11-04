//! Live demos for docs/pages/components/tabs.md (```demo tabs``` fences).
const std = @import("std");
const Writer = std.Io.Writer;
const zw = @import("zigworks");
const ui = zw.ui;
const d = @import("demo.zig");

/// Fence name, block layout (stacked) or inline (wrapping row), render function.
pub const demos = [_]d.Demo{
    .{ "tabs", true, tabs },
    .{ "tabs-options", true, options },
    .{ "tabs-states", true, states },
    .{ "tabs-live", true, live },
    .{ "tabs-lazy", true, lazy },
    .{ "tabs-form", true, form },
};
/// Extra CSS for these demos (scope it under a demo-specific class).
pub const css =
    \\.demo-tabs-cases{display:flex;flex-direction:column;gap:22px;width:100%;min-width:0}
    \\.demo-tabs-case{display:flex;flex-direction:column;align-items:center;gap:8px;min-width:0;
    \\  & .zw-tab-panel{padding:4px 12px;text-align:center;color:var(--secondary);font:var(--callout)}}
    \\.demo-tabs-cap{color:var(--secondary);font:var(--callout);text-align:center}
    \\.demo-tabs-msg{flex:1;min-width:0;display:grid;
    \\  & small{overflow:hidden;text-overflow:ellipsis;white-space:nowrap;color:var(--secondary);font:var(--callout)}}
    \\
;
/// Server routes these demos need, e.g. `.{ "POST /demo/tabs/x", handler }`.
pub const routes = .{
    .{ "POST /demo/tabs/mail", mailDemo },
    .{ "GET /demo/tabs/lazy", lazyDemo },
    .{ "POST /demo/tabs/clear", clearDemo },
    .{ "POST /demo/tabs/save", saveDemo },
};

// Hero: a preferences window, like Safari's settings. Every control saves through POST /demo.
fn tabs(w: *Writer) Writer.Error!void {
    try ui.tabs(.{ .id = "demo-tabs", .label = "Preferences", .labels = &.{ "General", "Notifications", "Privacy" }, .panels = .{
        ui.card(.{ .body = zw.view("{a}{b}{c}", .{
            .a = ui.setting(.{ .label = "Appearance", .description = "Applies to every window.", .control = ui.segmented(.{ .name = "demo-tabs-look", .label = "Appearance", .z = d.save, .options = &.{
                .{ .value = "light", .label = "Light" },
                .{ .value = "dark", .label = "Dark" },
                .{ .value = "auto", .label = "Auto", .selected = true },
            } }) }),
            .b = ui.toggle(.{ .name = "demo-tabs-restore", .label = "Reopen windows at launch", .on = true, .z = d.save }),
            .c = ui.setting(.{ .label = "Keep downloads", .control = ui.stepper(.{ .name = "demo-tabs-keep", .label = "Days to keep downloads", .value = 7, .min = 1, .max = 30, .unit = "days", .z = d.save }) }),
        }) }),
        ui.card(.{ .body = zw.view("{a}{b}{c}", .{
            .a = ui.toggle(.{ .name = "demo-tabs-notify", .label = "Allow notifications", .on = true, .z = d.save }),
            .b = ui.toggle(.{ .name = "demo-tabs-sound", .label = "Play sounds", .description = "A short chime for new messages.", .z = d.save }),
            .c = ui.setting(.{ .label = "Show previews", .control = ui.segmented(.{ .name = "demo-tabs-preview", .label = "Show previews", .z = d.save, .options = &.{
                .{ .value = "always", .label = "Always" },
                .{ .value = "unlocked", .label = "Unlocked", .selected = true },
                .{ .value = "never", .label = "Never" },
            } }) }),
        }) }),
        ui.card(.{ .body = zw.view("{a}{b}{c}", .{
            .a = ui.toggle(.{ .name = "demo-tabs-ip", .label = "Hide IP address from trackers", .description = "Uses an anonymous relay.", .on = true, .z = d.save }),
            .b = ui.toggle(.{ .name = "demo-tabs-dnt", .label = "Ask websites not to track me", .z = d.save }),
            .c = ui.setting(.{ .label = "Browsing history", .control = ui.button(.{ .label = "Clear History…", .variant = .destructive, .z = .{ .post = "/demo/tabs/clear", .swap = .none, .confirm = "Clear all browsing history?" } }) }),
        }) }),
    } }).render(w);
}

/// One captioned strip: the caption shows the props that make it look the way it does.
fn case(cap: []const u8, t: anytype) zw.View("<div class=\"demo-tabs-case\"><p class=\"demo-tabs-cap\"><code>{cap}</code></p>{t}</div>", struct { cap: []const u8, t: @TypeOf(t) }) {
    return .{ .data = .{ .cap = cap, .t = t } };
}

// Props side by side: selected, badges, disabled, full_width.
fn options(w: *Writer) Writer.Error!void {
    try zw.view("<div class=\"demo-tabs-cases\">{a}{b}{c}{d}{e}</div>", .{
        .a = case(".selected = 1", ui.tabs(.{ .id = "demo-tabs-opt-selected", .label = "Calendar range", .labels = &.{ "Day", "Week", "Month", "Year" }, .selected = 1, .panels = .{
            "Showing today.", "Showing this week.", "Showing this month.", "Showing this year.",
        } })),
        .b = case(".badges = &.{ \"12\", \"\", \"3\" }", ui.tabs(.{ .id = "demo-tabs-opt-badges", .label = "Mailbox", .labels = &.{ "Inbox", "Drafts", "Junk" }, .badges = &.{ "12", "", "3" }, .panels = .{
            "12 unread messages.", "No drafts.", "3 messages to review.",
        } })),
        .c = case(".disabled = &.{ 2 }", ui.tabs(.{ .id = "demo-tabs-opt-disabled", .label = "Storage", .labels = &.{ "This Mac", "Network", "iCloud" }, .disabled = &.{2}, .panels = .{
            "Disks attached to this computer.", "Servers on your local network.", "Sign in to use iCloud.",
        } })),
        .d = case(".full_width = true", ui.tabs(.{ .id = "demo-tabs-opt-full", .label = "Weekday", .full_width = true, .selected = 2, .labels = &.{ "Mon", "Tue", "Wed", "Thu", "Fri" }, .panels = .{
            "Monday", "Tuesday", "Wednesday", "Thursday", "Friday",
        } })),
        .e = case(".selected = 1, .disabled = &.{ 1 }", ui.tabs(.{ .id = "demo-tabs-opt-locked", .label = "Document", .labels = &.{ "Overview", "Locked" }, .selected = 1, .disabled = &.{1}, .panels = .{
            "Overview of the document.", "This panel shows first, although its tab is disabled.",
        } })),
    }).render(w);
}

// States inside panels: loading, empty and error. The Issues tab carries a badge.
fn states(w: *Writer) Writer.Error!void {
    try ui.tabs(.{ .id = "demo-tabs-states", .label = "Backup", .full_width = true, .labels = &.{ "Syncing", "Shared", "Issues" }, .badges = &.{ "", "", "1" }, .panels = .{
        ui.card(.{ .body = zw.view("<div class=\"zw-stack\">{a}{b}</div>", .{
            .a = ui.progress(.{ .value = 62, .label = "Upload", .text = "Uploading 12 of 19 photos", .show_value = true }),
            .b = ui.skeleton(.{ .lines = 3, .label = "Loading recent activity" }),
        }) }),
        ui.card(.{ .body = ui.empty(.{
            .icon = "👥",
            .title = "Nothing Shared",
            .text = "Invite people and their changes show up here.",
            .action = ui.button(.{ .label = "Invite…", .variant = .primary, .z = d.save }),
        }) }),
        ui.card(.{ .body = zw.view("<div class=\"zw-stack\">{a}{b}{c}</div>", .{
            .a = ui.callout(.{ .kind = .caution, .title = "Backup failed", .body = "The disk “Backup” isn't connected." }),
            .b = ui.field(.{ .name = "demo-tabs-dest", .label = "Destination", .value = "/Volumes/Backup", .invalid = "Choose a disk that is connected." }),
            .c = ui.button(.{ .label = "Retrying", .variant = .primary, .loading = true }),
        }) }),
    } }).render(w);
}

// Interactive: a mailbox. Archive and Move to Inbox post to the server, which answers with the
// whole box again (tabs, rows and badges). The archived set travels in the URL as a bitmask `m`.
const msgs = [_]struct { from: []const u8, subject: []const u8 }{
    .{ .from = "Ada Lovelace", .subject = "Notes on the Analytical Engine" },
    .{ .from = "Grace Hopper", .subject = "Compiler status update" },
    .{ .from = "Alan Turing", .subject = "Draft: the halting problem" },
    .{ .from = "Katherine Johnson", .subject = "Trajectory review" },
};

const Item = struct { from: []const u8, subject: []const u8, url: []const u8, archived: bool };

const MsgRow = zw.View("<li>{av}<span class=\"demo-tabs-msg\"><strong>{from}</strong><small>{subject}</small></span>{b}</li>", struct { av: ui.Avatar, from: []const u8, subject: []const u8, b: ui.Button });

fn row(r: Item) MsgRow {
    return .{ .data = .{
        .av = ui.avatar(.{ .name = r.from }),
        .from = r.from,
        .subject = r.subject,
        .b = ui.button(.{ .label = if (r.archived) "Move to Inbox" else "Archive", .variant = .plain, .size = .small, .z = .{ .post = r.url, .target = "#demo-tabs-mail", .swap = .outer } }),
    } };
}

const Mailbox = struct {
    /// Bit i set: message i is archived.
    mask: u8,
    /// Tab shown after the update.
    sel: usize,

    pub fn render(m: Mailbox, w: *Writer) Writer.Error!void {
        var urls: [msgs.len][48]u8 = undefined;
        var inbox: [msgs.len]Item = undefined;
        var archived: [msgs.len]Item = undefined;
        var ni: usize = 0;
        var na: usize = 0;
        for (msgs, 0..) |msg, i| {
            const gone = (m.mask & (@as(u8, 1) << @intCast(i))) != 0;
            // Archive stays on the Inbox tab and offers Undo; Move to Inbox stays on Archived.
            const url = std.fmt.bufPrint(&urls[i], "/demo/tabs/mail?m={d}&t={d}&s={d}&n={d}", .{ m.mask, i, @intFromBool(gone), @intFromBool(!gone) }) catch unreachable;
            const item: Item = .{ .from = msg.from, .subject = msg.subject, .url = url, .archived = gone };
            if (gone) {
                archived[na] = item;
                na += 1;
            } else {
                inbox[ni] = item;
                ni += 1;
            }
        }
        var nb0: [4]u8 = undefined;
        var nb1: [4]u8 = undefined;
        const c0 = std.fmt.bufPrint(&nb0, "{d}", .{ni}) catch unreachable;
        const c1 = std.fmt.bufPrint(&nb1, "{d}", .{na}) catch unreachable;
        const badges = [2][]const u8{ if (ni > 0) c0 else "", if (na > 0) c1 else "" };
        try w.writeAll("<div id=\"demo-tabs-mail\">");
        try ui.tabs(.{ .id = "demo-tabs-mailbox", .label = "Mailbox", .labels = &.{ "Inbox", "Archived" }, .badges = &badges, .selected = m.sel, .panels = .{
            ui.list(.{ .id = "demo-tabs-inbox", .empty = "Inbox zero. Nothing to read.", .body = zw.each(inbox[0..ni], row) }),
            ui.list(.{ .id = "demo-tabs-archived", .empty = "Nothing archived.", .body = zw.each(archived[0..na], row) }),
        } }).render(w);
        try w.writeAll("</div>");
    }
};

fn live(w: *Writer) Writer.Error!void {
    try (Mailbox{ .mask = 0, .sel = 0 }).render(w);
}

fn mailDemo(c: *zw.Ctx) !void {
    var mask = (std.fmt.parseInt(u8, c.query("m") orelse "0", 10) catch 0) & 0x0f;
    const t = std.fmt.parseInt(u8, c.query("t") orelse "", 10) catch msgs.len;
    if (t < msgs.len) mask ^= @as(u8, 1) << @intCast(t);
    const box: Mailbox = .{ .mask = mask, .sel = if (std.mem.eql(u8, c.query("s") orelse "0", "1")) 1 else 0 };
    if (t >= msgs.len or !std.mem.eql(u8, c.query("n") orelse "", "1")) return c.page(box);
    // Archiving also answers with a toast whose Undo posts the opposite change.
    var buf: [48]u8 = undefined;
    const undo = std.fmt.bufPrint(&buf, "/demo/tabs/mail?m={d}&t={d}&s=0", .{ mask, t }) catch unreachable;
    try c.page(zw.view("{box}{toast}", .{
        .box = box,
        .toast = ui.toast(.{ .text = "Message archived", .action = "Undo", .z = .{ .post = undo, .target = "#demo-tabs-mail", .swap = .outer } }),
    }));
}

// On-demand panels: choosing a tab sends a GET (`demo-tabs-lazy=Label`) and the server answers with
// the tabs again, that panel filled in. Until then the other panels only say "Loading…".
const lazy_labels = [_][]const u8{ "Overview", "Activity", "Files" };
const lazy_text = [_][]const u8{ "A summary of the project.", "12 changes this week, fetched when you opened this tab.", "48 files, fetched when you opened this tab." };

const Lazy = struct {
    sel: usize,

    fn panel(l: Lazy, i: usize) []const u8 {
        return if (l.sel == i) lazy_text[i] else "Loading…";
    }

    pub fn render(l: Lazy, w: *Writer) Writer.Error!void {
        try ui.tabs(.{
            .id = "demo-tabs-lazy",
            .label = "Project",
            .labels = &lazy_labels,
            .selected = l.sel,
            .z = .{ .get = "/demo/tabs/lazy", .target = "closest .zw-tabs", .swap = .outer },
            .panels = .{ l.panel(0), l.panel(1), l.panel(2) },
        }).render(w);
    }
};

fn lazy(w: *Writer) Writer.Error!void {
    try w.writeAll("<div class=\"demo-tabs-case\">");
    try (Lazy{ .sel = 0 }).render(w);
    try w.writeAll("</div>");
}

fn lazyDemo(c: *zw.Ctx) !void {
    const chosen = c.query("demo-tabs-lazy") orelse "";
    const sel = for (lazy_labels, 0..) |l, i| {
        if (std.mem.eql(u8, l, chosen)) break i;
    } else 0;
    try c.page(Lazy{ .sel = sel });
}

fn clearDemo(c: *zw.Ctx) !void {
    try c.page(ui.toast(.{ .text = "History cleared", .kind = .success }));
}

// Composition: tabs inside a card inside a form. The footer buttons save whichever tab is showing,
// because every field of every panel is part of the form.
fn form(w: *Writer) Writer.Error!void {
    try zw.view("<form{z}>{card}</form>", .{
        .z = ui.Z{ .post = "/demo/tabs/save", .swap = .none, .keep = true },
        .card = ui.card(.{
            .title = "Project",
            .subtitle = "Nebula",
            .body = ui.tabs(.{ .id = "demo-tabs-project", .label = "Project sections", .submit = false, .labels = &.{ "Details", "Tags", "Activity" }, .badges = &.{ "", "3" }, .panels = .{
                zw.view("<div class=\"zw-stack\">{a}{b}{c}</div>", .{
                    .a = ui.field(.{ .name = "demo-tabs-name", .label = "Project name", .placeholder = "Project name", .value = "Nebula" }),
                    .b = ui.field(.{ .name = "demo-tabs-owner", .label = "Owner email", .type = "email", .autocomplete = "email", .value = "ada@example.com", .help = "Used for build notifications." }),
                    .c = ui.toggle(.{ .name = "demo-tabs-public", .label = "Visible to everyone", .on = true }),
                }),
                zw.view("<div class=\"zw-tags\">{a}{b}{c}</div>", .{
                    .a = ui.tag(.{ .text = "design", .remove = .{ .delete = "/demo/todo" } }),
                    .b = ui.tag(.{ .text = "q4", .tone = .gray, .remove = .{ .delete = "/demo/todo" } }),
                    .c = ui.tag(.{ .text = "internal", .tone = .orange, .remove = .{ .delete = "/demo/todo" } }),
                }),
                ui.table(.{ .compact = true, .head = &.{ "When", "Change" }, .rows = &.{
                    &.{ "Today", "Renamed to Nebula" },
                    &.{ "Yesterday", "Added 3 tags" },
                    &.{ "Mon", "Created project" },
                } }),
            } }),
            .footer = zw.view("{a}{b}", .{
                .a = ui.button(.{ .label = "Cancel", .variant = .plain }),
                .b = ui.button(.{ .label = "Save", .variant = .primary, .type = .submit }),
            }),
        }),
    }).render(w);
}

fn saveDemo(c: *zw.Ctx) !void {
    const name = std.mem.trim(u8, c.form("demo-tabs-name") orelse "", " ");
    if (name.len == 0) return c.page(ui.toast(.{ .text = "Give the project a name on the Details tab.", .kind = .@"error" }));
    try c.page(ui.toast(.{ .text = "Project saved", .kind = .success }));
}
