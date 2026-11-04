//! Live demos for docs/pages/components/badge.md (```demo badge``` fences).
const std = @import("std");
const Writer = std.Io.Writer;
const zw = @import("zigworks");
const ui = zw.ui;
const d = @import("demo.zig");

/// Fence name, block layout (stacked) or inline (wrapping row), render function.
pub const demos = [_]d.Demo{
    .{ "badge", true, badge },
    .{ "badge-variants", true, variants },
    .{ "badge-states", true, states },
    .{ "badge-live", true, live },
    .{ "badge-compose", true, compose },
};
/// Extra CSS for these demos (scope it under a demo-specific class).
pub const css =
    \\.demo-badge-key{flex:0 0 7rem;color:var(--secondary);overflow-wrap:anywhere}
    \\.demo-badge-sub{display:block;font:var(--callout);color:var(--secondary)}
    \\.demo-badge-dock{position:relative;display:inline-flex;flex:none;
    \\  .zw-badge{position:absolute;top:-5px;right:-7px}}
    \\
;
/// Server routes these demos need, e.g. `.{ "POST /demo/badge/x", handler }`.
pub const routes = .{
    .{ "POST /demo/badge/mail", mail },
};

// Hero: the mailbox list of a mail app.
fn badge(w: *Writer) Writer.Error!void {
    try ui.list(.{
        .id = "demo-badge-boxes",
        .header = "Mailboxes",
        .footer = "The red badge stops at 99+. The dot is named for screen readers.",
        .body = zw.view(
            "<li><span class=\"zw-grow\">Inbox</span>{a}</li>" ++
                "<li><span class=\"zw-grow\">VIP</span>{b}</li>" ++
                "<li><span class=\"zw-grow\">Drafts</span>{c}</li>" ++
                "<li><span class=\"zw-grow\">Flagged</span>{e}</li>" ++
                "<li><span class=\"zw-grow\">Sent</span></li>" ++
                "<li><span class=\"zw-grow\">iCloud</span>{f}</li>",
            .{
                .a = ui.badge(.{ .count = 128, .tone = .red, .solid = true }),
                .b = ui.badge(.{ .text = "New", .tone = .accent, .size = .small }),
                .c = ui.badge(.{ .count = 2 }),
                .e = ui.badge(.{ .count = 5, .tone = .orange }),
                .f = ui.badge(.{ .dot = true, .tone = .green, .text = "Online" }),
            },
        ),
    }).render(w);
}

/// One row of the variants list: the five tones, all with the same flags.
const ToneRow = struct {
    key: []const u8,
    solid: bool = false,
    small: bool = false,
    dot: bool = false,

    pub fn render(r: ToneRow, w: *Writer) Writer.Error!void {
        try w.print("<li><code class=\"demo-badge-key\">{s}</code><span class=\"zw-tags zw-grow\">", .{r.key});
        inline for (.{ .gray, .accent, .red, .green, .orange }) |tone| {
            try ui.badge(.{
                .text = @tagName(tone),
                .tone = tone,
                .solid = r.solid,
                .dot = r.dot,
                .size = if (r.small) .small else .regular,
            }).render(w);
        }
        try w.writeAll("</span></li>");
    }
};

fn variants(w: *Writer) Writer.Error!void {
    try ui.list(.{
        .id = "demo-badge-variants",
        .header = "Each tone, per prop",
        .footer = "Every row shows .gray, .accent, .red, .green and .orange.",
        .body = zw.view("{a}{b}{c}{d}{e}{f}", .{
            .a = ToneRow{ .key = "tone" },
            .b = ToneRow{ .key = "solid", .solid = true },
            .c = ToneRow{ .key = "size: small", .small = true },
            .d = ToneRow{ .key = "solid + small", .solid = true, .small = true },
            .e = ToneRow{ .key = "dot", .dot = true },
            .f = ToneRow{ .key = "dot + small", .dot = true, .small = true },
        }),
    }).render(w);
}

fn states(w: *Writer) Writer.Error!void {
    try ui.list(.{
        .id = "demo-badge-counts",
        .header = "Counts",
        .footer = "A badge has no disabled or loading state: hide it, or leave it out.",
        .body = zw.view(
            "<li><code class=\"demo-badge-key\">count = 7</code>{a}</li>" ++
                "<li><code class=\"demo-badge-key\">count = 128</code>{b}</li>" ++
                "<li><code class=\"demo-badge-key\">count = 25, max = 9</code>{c}</li>" ++
                "<li><code class=\"demo-badge-key\">count = 0</code>{e}</li>" ++
                "<li><code class=\"demo-badge-key\">count = 0, hide_zero</code>{f}<span class=\"zw-secondary\">Hidden, but still in the page</span></li>",
            .{
                .a = ui.badge(.{ .count = 7 }),
                .b = ui.badge(.{ .count = 128, .tone = .red, .solid = true }),
                .c = ui.badge(.{ .count = 25, .max = 9, .tone = .accent }),
                .e = ui.badge(.{ .count = 0 }),
                .f = ui.badge(.{ .count = 0, .hide_zero = true }),
            },
        ),
    }).render(w);
    try ui.list(.{
        .id = "demo-badge-status",
        .header = "Status",
        .footer = "A dot with text is named for screen readers; without text it is decorative.",
        .body = zw.view(
            "<li>{a}<span class=\"zw-grow\">Build</span><span class=\"zw-secondary\">Passing</span></li>" ++
                "<li>{b}<span class=\"zw-grow\">Tests</span><span class=\"zw-secondary\">2 failing</span></li>" ++
                "<li>{c}<span class=\"zw-grow\">Deploy</span><span class=\"zw-secondary\">Waiting for approval</span></li>" ++
                "<li>{e}<span class=\"zw-grow\">Docs</span><span class=\"zw-secondary\">Draft</span></li>",
            .{
                .a = ui.badge(.{ .dot = true, .tone = .green, .text = "Build passing" }),
                .b = ui.badge(.{ .dot = true, .tone = .red, .text = "Tests failing" }),
                .c = ui.badge(.{ .dot = true, .tone = .orange, .text = "Deploy waiting" }),
                .e = ui.badge(.{ .dot = true, .size = .small }),
            },
        ),
    }).render(w);
}

// Live: checking messages updates two badges out of band. The count is derived from the
// request (the checked boxes), so the server keeps no state.
const Message = struct { id: []const u8, from: []const u8, subject: []const u8, read: bool };
const inbox = [_]Message{
    .{ .id = "1", .from = "Ada Lovelace", .subject = "Notes on the Analytical Engine", .read = false },
    .{ .id = "2", .from = "Grace Hopper", .subject = "Compiler status update", .read = false },
    .{ .id = "3", .from = "Alan Turing", .subject = "Re: Halting problem", .read = false },
    .{ .id = "4", .from = "Margaret Hamilton", .subject = "Guidance review", .read = true },
};

/// The rows: a checked box means the message is read.
const MailRows = struct {
    all_read: bool,

    pub fn render(self: MailRows, w: *Writer) Writer.Error!void {
        inline for (inbox) |m| {
            try zw.view("<li>{c}</li>", .{
                .c = ui.checkbox(.{ .name = "read", .value = m.id, .label = m.from, .description = m.subject, .on = self.all_read or m.read }),
            }).render(w);
        }
    }
};

const MailList = struct {
    all_read: bool,

    pub fn render(self: MailList, w: *Writer) Writer.Error!void {
        try ui.list(.{ .id = "demo-badge-mail", .inset = false, .body = MailRows{ .all_read = self.all_read } }).render(w);
    }
};

fn unreadBadge(n: u32, oob: bool) ui.Badge {
    return ui.badge(.{ .id = "demo-badge-unread", .count = n, .tone = .red, .solid = true, .hide_zero = true, .oob = oob });
}

fn dockBadge(n: u32, oob: bool) ui.Badge {
    return ui.badge(.{ .id = "demo-badge-dock", .count = n, .tone = .red, .solid = true, .size = .small, .hide_zero = true, .oob = oob });
}

fn live(w: *Writer) Writer.Error!void {
    var unread: u32 = 0;
    for (inbox) |m| unread += @intFromBool(!m.read);
    try ui.card(.{
        .title = "Inbox",
        .subtitle = "Check a message to mark it read.",
        .accessory = unreadBadge(unread, false),
        .body = zw.view("<form{z}>{list}</form>", .{
            .z = ui.Z{ .post = "/demo/badge/mail", .trigger = "change", .swap = .none, .keep = true },
            .list = MailList{ .all_read = false },
        }),
        .footer = zw.view("<span class=\"demo-badge-dock\">{app}{dock}</span><span class=\"zw-grow zw-secondary\">Dock icon</span>{all}", .{
            .app = ui.avatar(.{ .name = "Mail", .size = 40, .shape = .rounded, .hue = 210 }),
            .dock = dockBadge(unread, false),
            .all = ui.button(.{ .label = "Mark All as Read", .variant = .plain, .z = .{ .post = "/demo/badge/mail?all=1", .target = "#demo-badge-mail", .swap = .outer } }),
        }),
    }).render(w);
}

/// Answers a change in the inbox form (the checked messages come in the body) or "Mark All as
/// Read" (`?all=1`, which also redraws the list). Both badges are replaced out of band.
fn mail(c: *zw.Ctx) !void {
    const all = c.query("all") != null;
    var read: u32 = 0;
    var fields = std.mem.splitScalar(u8, c.body, '&');
    while (fields.next()) |field| read += @intFromBool(std.mem.startsWith(u8, field, "read="));
    const unread: u32 = if (all) 0 else inbox.len - @min(read, inbox.len);
    try c.html("{#if all}{list}{/if}{head}{dock}{#if zero}{toast}{/if}", .{
        .all = all,
        .list = MailList{ .all_read = true },
        .head = unreadBadge(unread, true),
        .dock = dockBadge(unread, true),
        .zero = unread == 0,
        .toast = ui.toast(.{ .text = "Inbox zero", .kind = .success }),
    });
}

fn compose(w: *Writer) Writer.Error!void {
    try ui.card(.{
        .title = "Team",
        .subtitle = "Analytical Engine",
        .accessory = ui.badge(.{ .text = "2 online", .tone = .green }),
        .body = ui.list(.{
            .id = "demo-badge-team",
            .inset = false,
            .body = zw.view(
                "<li>{a1}<span class=\"zw-grow\">Ada Lovelace<span class=\"demo-badge-sub\">Maintainer</span></span>{b1}</li>" ++
                    "<li>{a2}<span class=\"zw-grow\">Grace Hopper<span class=\"demo-badge-sub\">Reviewer</span></span>{b2}<span class=\"zw-secondary\">to review</span></li>" ++
                    "<li>{a3}<span class=\"zw-grow\">Alan Turing<span class=\"demo-badge-sub\">Contributor</span></span>{b3}</li>",
                .{
                    .a1 = ui.avatar(.{ .name = "Ada Lovelace", .size = 36, .status = .online }),
                    .b1 = ui.badge(.{ .text = "Owner", .tone = .accent, .size = .small }),
                    .a2 = ui.avatar(.{ .name = "Grace Hopper", .size = 36, .status = .online }),
                    .b2 = ui.badge(.{ .count = 3, .tone = .red, .solid = true }),
                    .a3 = ui.avatar(.{ .name = "Alan Turing", .size = 36, .status = .away }),
                    .b3 = ui.badge(.{ .text = "Guest", .size = .small }),
                },
            ),
        }),
        .footer = ui.button(.{ .label = "Invite…", .variant = .primary, .z = d.save }),
    }).render(w);
}
