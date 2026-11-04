//! Live demos for docs/pages/components/disclosure.md (```demo disclosure``` fences).
const std = @import("std");
const Writer = std.Io.Writer;
const zw = @import("zigworks");
const ui = zw.ui;
const d = @import("demo.zig");

/// Fence name, block layout (stacked) or inline (wrapping row), render function.
pub const demos = [_]d.Demo{
    .{ "disclosure", true, disclosure },
    .{ "disclosure-styles", true, styles },
    .{ "disclosure-states", true, states },
    .{ "disclosure-accordion", true, accordion },
    .{ "disclosure-filters", true, filters },
    .{ "disclosure-oob", true, oobPane },
    .{ "disclosure-export", true, exportPane },
};
/// Extra CSS for these demos (scope it under a demo-specific class).
pub const css =
    \\.demo-disclosure-pair,.demo-disclosure-grid{display:grid;gap:16px;align-items:start;grid-template-columns:repeat(auto-fit,minmax(min(100%,260px),1fr))}
    \\.demo-disclosure-label{margin-bottom:8px;font:var(--callout);color:var(--secondary)}
    \\.demo-disclosure-inbox{display:flex;flex-direction:column;gap:12px}
    \\.demo-disclosure-msg{display:flex;flex-direction:column;gap:2px;
    \\&>small{font:var(--callout);color:var(--secondary);overflow-wrap:anywhere}
    \\&>.zw-tags{margin-top:4px}
    \\&.demo-disclosure-unread>.demo-disclosure-from{font-weight:600}}
    \\
;
/// Server routes these demos need, e.g. `.{ "POST /demo/disclosure/x", handler }`.
pub const routes = .{
    .{ "POST /demo/disclosure/filter", filterInbox },
    .{ "POST /demo/disclosure/link", setLink },
};

/// Hero: a Finder "Get Info" panel. Plain disclosures group the sections inside one card.
fn disclosure(w: *Writer) Writer.Error!void {
    try ui.card(.{
        .title = "Project Notes.txt",
        .subtitle = "Plain Text, 4 KB",
        .body = zw.view("<div class=\"demo-disclosure-pane\">{general}{more}{sharing}</div>", .{
            .general = ui.disclosure(.{ .title = "General", .open = true, .body = zw.view("{a}{b}{c}{d}", .{
                .a = ui.setting(.{ .label = "Kind", .control = "Plain Text Document" }),
                .b = ui.setting(.{ .label = "Size", .control = "4 KB (4,096 bytes)" }),
                .c = ui.setting(.{ .label = "Where", .control = "Documents" }),
                .d = ui.setting(.{ .label = "Modified", .control = "Today, 9:41" }),
            }) }),
            .more = ui.disclosure(.{ .title = "More Info", .detail = "Last opened today", .body = zw.view("{a}{b}", .{
                .a = ui.setting(.{ .label = "Created", .control = "March 3, 2026" }),
                .b = ui.setting(.{ .label = "Last opened", .control = "Today, 9:40" }),
            }) }),
            .sharing = ui.disclosure(.{ .title = "Sharing & Permissions", .detail = "You can read and write", .body = zw.view("{a}{b}{c}", .{
                .a = ui.setting(.{ .label = "Owner", .control = "You" }),
                .b = ui.toggle(.{ .name = "locked", .label = "Locked", .description = "Prevents changes to this file.", .z = d.save }),
                .c = ui.toggle(.{ .name = "stationery", .label = "Stationery pad", .z = d.save }),
            }) }),
        }),
    }).render(w);
}

/// The two styles side by side, both with `detail`.
fn styles(w: *Writer) Writer.Error!void {
    try zw.view(
        \\<div class="demo-disclosure-pair">
        \\<div><p class="demo-disclosure-label"><code>.style = .plain</code> inside a card</p>{plain}</div>
        \\<div><p class="demo-disclosure-label"><code>.style = .card</code> on its own</p>{card}</div>
        \\</div>
    , .{
        .plain = ui.card(.{ .body = zw.view("<div class=\"demo-disclosure-pane\">{a}{b}{c}</div>", .{
            .a = ui.disclosure(.{ .title = "Wi-Fi", .detail = "Home", .open = true, .body = "Connected to Home. Signal is strong." }),
            .b = ui.disclosure(.{ .title = "Bluetooth", .detail = "On", .body = "2 devices connected." }),
            .c = ui.disclosure(.{ .title = "VPN", .detail = "Not connected", .body = "Add a configuration to connect." }),
        }) }),
        .card = zw.view("{a}{b}{c}", .{
            .a = ui.disclosure(.{ .title = "Storage", .style = .card, .detail = "41 of 64 GB", .open = true, .body = "Documents, photos and system files." }),
            .b = ui.disclosure(.{ .title = "Battery", .style = .card, .detail = "82%", .body = "Charging is optimized to reduce wear." }),
            .c = ui.disclosure(.{ .title = "Software Update", .style = .card, .detail = "Up to date", .body = "Last checked today." }),
        }),
    }).render(w);
}

/// Closed, open, long text, an empty body and nesting, each in its own card.
fn states(w: *Writer) Writer.Error!void {
    try zw.view("<div class=\"demo-disclosure-grid\">{a}{b}{c}{d}{e}</div>", .{
        .a = ui.card(.{ .title = "Closed", .subtitle = "open = false (default)", .body = ui.disclosure(.{ .title = "Keyboard Shortcuts", .body = "Press Space or Enter on the title to open it." }) }),
        .b = ui.card(.{ .title = "Open", .subtitle = "open = true", .body = ui.disclosure(.{ .title = "Keyboard Shortcuts", .open = true, .body = "Press Space or Enter on the title to close it." }) }),
        .c = ui.card(.{ .title = "Long text", .subtitle = "The title wraps, the detail is cut off", .body = ui.disclosure(.{
            .title = "Automatically adjust brightness and contrast for the ambient light around the display",
            .detail = "Adjusts to the room as the light changes during the day",
            .body = "The detail stays on one line.",
        }) }),
        .d = ui.card(.{ .title = "Empty body", .subtitle = "Say so inside the body", .body = ui.disclosure(.{ .title = "Recent Items", .open = true, .body = ui.empty(.{ .title = "No Recent Items", .text = "Files you open show up here.", .size = .compact }) }) }),
        .e = ui.card(.{ .title = "Nested", .subtitle = "Sections inside sections", .body = ui.disclosure(.{ .title = "Documents", .detail = "2 folders", .open = true, .body = zw.view("<div class=\"demo-disclosure-pane\">{a}{b}</div>", .{
            .a = ui.disclosure(.{ .title = "Reports", .detail = "12 files", .open = true, .body = "Q1 summary.pdf, Q2 summary.pdf, ..." }),
            .b = ui.disclosure(.{ .title = "Drafts", .detail = "3 files", .body = "Launch notes.txt, Old plan.txt, Ideas.txt" }),
        }) }) }),
    }).render(w);
}

/// A shared `name` makes an accordion; without one, each section opens on its own.
fn accordion(w: *Writer) Writer.Error!void {
    try zw.view(
        \\<div class="demo-disclosure-pair">
        \\<div><p class="demo-disclosure-label"><code>.name = "demo-disclosure-faq"</code>: one open at a time</p>{one}</div>
        \\<div><p class="demo-disclosure-label">No <code>name</code>: independent</p>{two}</div>
        \\</div>
    , .{
        .one = zw.view("{a}{b}{c}", .{
            .a = ui.disclosure(.{ .title = "Shipping", .name = "demo-disclosure-faq", .style = .card, .detail = "3-5 days", .open = true, .body = "Orders ship within one business day. Tracking arrives by email." }),
            .b = ui.disclosure(.{ .title = "Returns", .name = "demo-disclosure-faq", .style = .card, .detail = "30 days", .body = "Unused items can be returned for a full refund." }),
            .c = ui.disclosure(.{ .title = "Warranty", .name = "demo-disclosure-faq", .style = .card, .detail = "1 year", .body = "Covers defects in materials and workmanship." }),
        }),
        .two = zw.view("{a}{b}{c}", .{
            .a = ui.disclosure(.{ .title = "Shipping", .style = .card, .detail = "3-5 days", .open = true, .body = "Orders ship within one business day." }),
            .b = ui.disclosure(.{ .title = "Returns", .style = .card, .detail = "30 days", .open = true, .body = "Unused items can be returned for a full refund." }),
            .c = ui.disclosure(.{ .title = "Warranty", .style = .card, .detail = "1 year", .body = "Covers defects in materials and workmanship." }),
        }),
    }).render(w);
}

const Msg = struct { from: []const u8, subject: []const u8, unread: bool, flagged: bool, files: bool };

const messages = [_]Msg{
    .{ .from = "Ada Lovelace", .subject = "Notes on the Analytical Engine", .unread = true, .flagged = false, .files = true },
    .{ .from = "Grace Hopper", .subject = "Compiler release checklist", .unread = false, .flagged = true, .files = false },
    .{ .from = "Alan Turing", .subject = "Re: Lunch on Friday?", .unread = true, .flagged = true, .files = false },
    .{ .from = "Katherine Johnson", .subject = "Orbit figures attached", .unread = false, .flagged = false, .files = true },
    .{ .from = "Margaret Hamilton", .subject = "Flight software review", .unread = true, .flagged = false, .files = true },
    .{ .from = "Edsger Dijkstra", .subject = "Draft: on the cruelty of teaching", .unread = false, .flagged = false, .files = false },
};

const Row = struct {
    m: Msg,

    pub fn render(row: Row, w: *Writer) Writer.Error!void {
        try zw.view(
            "<li>{av}<div class=\"zw-grow demo-disclosure-msg{#if m.unread} demo-disclosure-unread{/if}\"><span class=\"demo-disclosure-from\">{m.from}</span><small>{m.subject}</small>" ++
                "{#if tags}<div class=\"zw-tags\">{#if m.flagged}{flag}{/if}{#if m.files}{files}{/if}</div>{/if}</div>{#if m.unread}{dot}{/if}</li>",
            .{
                .m = row.m,
                .tags = row.m.flagged or row.m.files,
                .av = ui.avatar(.{ .name = row.m.from, .size = 32 }),
                .flag = ui.tag(.{ .text = "Flagged", .tone = .orange, .size = .small }),
                .files = ui.tag(.{ .text = "Attachment", .tone = .gray, .size = .small }),
                .dot = ui.badge(.{ .dot = true, .tone = .accent, .text = "Unread" }),
            },
        ).render(w);
    }
};

fn rowOf(m: Msg) Row {
    return .{ .m = m };
}

/// The inbox with its filters. The page and the filter handler both render this, so the
/// filter state lives only in the request (the chips that are checked).
const Inbox = struct {
    unread: bool = false,
    flagged: bool = false,
    files: bool = false,

    pub fn render(f: Inbox, w: *Writer) Writer.Error!void {
        var shown: [messages.len]Msg = undefined;
        var n: u32 = 0;
        for (messages) |m| {
            if ((f.unread and !m.unread) or (f.flagged and !m.flagged) or (f.files and !m.files)) continue;
            shown[n] = m;
            n += 1;
        }
        const active = @as(usize, @intFromBool(f.unread)) + @intFromBool(f.flagged) + @intFromBool(f.files);
        const details = [_][]const u8{ "None", "1 active", "2 active", "3 active" };
        try zw.view("<div class=\"demo-disclosure-inbox\" id=\"demo-disclosure-inbox\"><div class=\"zw-row\"><strong class=\"zw-grow\">Inbox</strong>{count}</div>{filters}{msgs}</div>", .{
            .count = ui.badge(.{ .count = n, .tone = .gray }),
            .filters = ui.disclosure(.{
                .title = "Filters",
                .style = .card,
                .open = true,
                .detail = details[active],
                .body = zw.view("<form class=\"zw-tags\"{z}>{a}{b}{c}</form>", .{
                    .z = ui.Z{ .post = "/demo/disclosure/filter", .trigger = "change", .target = "#demo-disclosure-inbox", .swap = .outer },
                    .a = ui.tag(.{ .text = "Unread", .name = "unread", .value = "1", .selected = f.unread }),
                    .b = ui.tag(.{ .text = "Flagged", .name = "flagged", .value = "1", .tone = .orange, .selected = f.flagged }),
                    .c = ui.tag(.{ .text = "Attachments", .name = "files", .value = "1", .tone = .gray, .selected = f.files }),
                }),
            }),
            .msgs = ui.list(.{ .id = "demo-disclosure-msgs", .empty = "No messages match these filters.", .body = zw.each(shown[0..n], rowOf) }),
        }).render(w);
    }
};

/// Interactive: the filter chips post their form; the response redraws the whole inbox,
/// including the disclosure's `detail` and the empty state.
fn filters(w: *Writer) Writer.Error!void {
    try (Inbox{}).render(w);
}

fn filterInbox(c: *zw.Ctx) !void {
    try c.page(Inbox{
        .unread = c.form("unread") != null,
        .flagged = c.form("flagged") != null,
        .files = c.form("files") != null,
    });
}

fn connection(on: bool, oob: bool) ui.Disclosure([]const u8) {
    const body: []const u8 = if (on) "Connected to Home. Signal is strong." else "Choose a network to connect.";
    return ui.disclosure(.{
        .id = "demo-disclosure-link",
        .oob = oob,
        .style = .card,
        .open = true,
        .title = "Connection",
        .detail = if (on) "Connected" else "Not connected",
        .body = body,
    });
}

/// The buttons sit outside the disclosure. Their response replaces it by `id` (out of band),
/// so the button that was pressed keeps keyboard focus.
fn oobPane(w: *Writer) Writer.Error!void {
    try zw.view("<div class=\"zw-stack\">{link}<div class=\"zw-row\">{on}{off}</div></div>", .{
        .link = connection(false, false),
        .on = ui.button(.{ .label = "Connect", .variant = .primary, .z = .{ .post = "/demo/disclosure/link?on=1", .swap = .none } }),
        .off = ui.button(.{ .label = "Disconnect", .z = .{ .post = "/demo/disclosure/link", .swap = .none } }),
    }).render(w);
}

fn setLink(c: *zw.Ctx) !void {
    try c.html("{link}", .{ .link = connection(c.query("on") != null, true) });
}

/// Composition: an export panel with settings controls and a nested disclosure.
fn exportPane(w: *Writer) Writer.Error!void {
    try ui.card(.{
        .title = "Export Photos",
        .subtitle = "12 photos selected",
        .body = zw.view("<div class=\"demo-disclosure-pane\">{format}{advanced}</div>", .{
            .format = ui.setting(.{ .label = "Format", .control = ui.segmented(.{ .name = "format", .label = "Format", .z = d.save, .options = &.{
                .{ .value = "jpeg", .label = "JPEG", .selected = true },
                .{ .value = "png", .label = "PNG" },
                .{ .value = "heic", .label = "HEIC" },
            } }) }),
            .advanced = ui.disclosure(.{ .title = "Advanced", .detail = "Defaults", .body = zw.view("<div class=\"demo-disclosure-pane\">{quality}{location}{profile}</div>", .{
                .quality = ui.setting(.{ .label = "Quality", .control = ui.stepper(.{ .name = "quality", .label = "Quality", .value = 80, .min = 10, .max = 100, .step = 10, .unit = "%", .z = d.save }) }),
                .location = ui.toggle(.{ .name = "location", .label = "Include location", .description = "Turn off to remove GPS data.", .z = d.save }),
                .profile = ui.disclosure(.{ .title = "Color profile", .detail = "sRGB", .body = zw.view("<div class=\"zw-stack\">{seg}{note}</div>", .{
                    .seg = ui.setting(.{ .label = "Profile", .control = ui.segmented(.{ .name = "profile", .label = "Color profile", .size = .small, .z = d.save, .options = &.{
                        .{ .value = "srgb", .label = "sRGB", .selected = true },
                        .{ .value = "p3", .label = "Display P3" },
                    } }) }),
                    .note = ui.callout(.{ .kind = .tip, .compact = true, .body = "sRGB looks right everywhere. Choose Display P3 only for wide-gamut screens." }),
                }) }),
            }) }),
        }),
        .footer = zw.view("{a}{b}", .{
            .a = ui.button(.{ .label = "Cancel" }),
            .b = ui.button(.{ .label = "Export", .variant = .primary, .z = d.save }),
        }),
    }).render(w);
}
