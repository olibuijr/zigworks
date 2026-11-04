//! Live demos for docs/pages/components/sidebar.md (```demo sidebar``` fences).
const std = @import("std");
const Writer = std.Io.Writer;
const zw = @import("zigworks");
const ui = zw.ui;
const d = @import("demo.zig");

/// Fence name, block layout (stacked) or inline (wrapping row), render function.
pub const demos = [_]d.Demo{
    .{ "sidebar", true, hero },
    .{ "sidebar-sizes", true, sizes },
    .{ "sidebar-sections", true, sections },
    .{ "sidebar-filter", true, filter },
    .{ "sidebar-settings", true, settings },
};
/// Extra CSS for these demos (scope it under a demo-specific class).
pub const css =
    \\.demo-sidebar-window{display:flex;flex-wrap:wrap;align-items:stretch;gap:12px;
    \\>.zw-sidebar{flex:none}
    \\>.demo-sidebar-pane{flex:1 1 240px;min-width:0;min-height:280px;display:flex;flex-direction:column;justify-content:center;gap:12px;padding:20px;border-radius:var(--radius-panel);background:var(--content);box-shadow:inset 0 0 0 .5px var(--separator);
    \\:is(h3,p){margin:0}}}
    \\.zw-demo .demo-sidebar-window>.zw-card{flex:1 1 260px;min-width:0;align-self:flex-start}
    \\.demo-sidebar-actions{flex-wrap:wrap}
    \\.demo-sidebar-grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(min(100%,230px),1fr));gap:20px;align-items:start}
    \\.demo-sidebar-cell{display:flex;flex-direction:column;gap:8px;min-width:0;
    \\>p{margin:0;font:var(--callout)}
    \\>.zw-sidebar{width:100%}}
    \\.demo-sidebar-filter{max-width:260px;
    \\.zw-sidebar{width:100%}}
    \\
;
/// Server routes these demos need, e.g. `.{ "POST /demo/sidebar/x", handler }`.
pub const routes = .{
    .{ "POST /demo/sidebar/mail", mailRoute },
    .{ "GET /demo/sidebar/filter", filterRoute },
};

const svg = "<svg viewBox='0 0 16 16' fill='none' stroke='currentColor' stroke-width='1.4' stroke-linecap='round' stroke-linejoin='round'>";
const inbox_icon = svg ++ "<path d='M2 9.5l1.6-5.2a1 1 0 0 1 .95-.7h6.9a1 1 0 0 1 .95.7L14 9.5v2.9a1 1 0 0 1-1 1H3a1 1 0 0 1-1-1z'/><path d='M2 9.5h3.4l.6 1.5h4l.6-1.5H14'/></svg>";
const draft_icon = svg ++ "<path d='M4 1.7h5l3 3v9.6H4z'/><path d='M9 1.7v3h3'/></svg>";
const sent_icon = svg ++ "<path d='M14 2L7 9M14 2l-4.5 12L7 9 1.5 6.5z'/></svg>";
const trash_icon = svg ++ "<path d='M3 4.5h10M6.5 4.5V3h3v1.5M4.5 4.5l.6 8.5h5.8l.6-8.5'/></svg>";
const star_icon = svg ++ "<path d='M8 1.8l1.9 3.9 4.3.6-3.1 3 .7 4.3L8 11.6l-3.8 2 .7-4.3-3.1-3 4.3-.6z'/></svg>";
const folder_icon = svg ++ "<path d='M2 4.5a1 1 0 0 1 1-1h3l1.5 1.5H13a1 1 0 0 1 1 1V12a1 1 0 0 1-1 1H3a1 1 0 0 1-1-1z'/></svg>";
const desktop_icon = svg ++ "<rect x='2' y='3' width='12' height='8' rx='1.5'/><path d='M6 14h4M8 11v3'/></svg>";
const download_icon = svg ++ "<path d='M8 2v8m0 0L5 7m3 3 3-3M3 13h10'/></svg>";
const cloud_icon = svg ++ "<path d='M4.5 12.5a3 3 0 0 1-.4-6 4 4 0 0 1 7.6 1 2.5 2.5 0 0 1-.2 5z'/></svg>";
const wifi_icon = svg ++ "<path d='M1.8 6a9.5 9.5 0 0 1 12.4 0M4 8.7a6.3 6.3 0 0 1 8 0M6.2 11.3a3 3 0 0 1 3.6 0'/><circle cx='8' cy='13' r='.6'/></svg>";
const bell_icon = svg ++ "<path d='M4 11.5V7a4 4 0 0 1 8 0v4.5l1 1H3zM6.5 14h3'/></svg>";
const lock_icon = svg ++ "<rect x='3' y='7' width='10' height='6.5' rx='1.5'/><path d='M5 7V5a3 3 0 0 1 6 0v2'/></svg>";
const gear_icon = svg ++ "<circle cx='8' cy='8' r='2.2'/><path d='M8 1.5v2M8 12.5v2M1.5 8h2M12.5 8h2M3.4 3.4l1.4 1.4M11.2 11.2l1.4 1.4M3.4 12.6l1.4-1.4M11.2 4.8l1.4-1.4'/></svg>";

// Hero: a Mail window. The state (open mailbox, counts) lives in the buttons' URLs: each
// button posts the current state plus an action, and POST /demo/sidebar/mail answers with
// the whole window re-rendered (and a toast). Nothing is stored on the server.

const Box = enum { inbox, drafts };

const Mail = struct {
    box: Box,
    inbox: u32,
    drafts: u32,

    fn url(m: Mail, buf: []u8, act: []const u8) []const u8 {
        return std.fmt.bufPrint(buf, "/demo/sidebar/mail?a={s}&b={s}&i={d}&d={d}", .{ act, @tagName(m.box), m.inbox, m.drafts }) catch "/demo/sidebar/mail";
    }

    pub fn render(m: Mail, w: *Writer) Writer.Error!void {
        var inbox_buf: [12]u8 = undefined;
        var drafts_buf: [12]u8 = undefined;
        var text_buf: [32]u8 = undefined;
        var ua: [96]u8 = undefined;
        var ub: [96]u8 = undefined;
        var uc: [96]u8 = undefined;
        const inbox_badge: []const u8 = if (m.inbox == 0) "" else std.fmt.bufPrint(&inbox_buf, "{d}", .{m.inbox}) catch "";
        const drafts_badge: []const u8 = if (m.drafts == 0) "" else std.fmt.bufPrint(&drafts_buf, "{d}", .{m.drafts}) catch "";

        const text: []const u8 = switch (m.box) {
            .inbox => if (m.inbox == 0) "No unread mail." else std.fmt.bufPrint(&text_buf, "{d} unread", .{m.inbox}) catch "",
            .drafts => if (m.drafts == 0) "No drafts." else std.fmt.bufPrint(&text_buf, "{d} waiting to send", .{m.drafts}) catch "",
        };

        try ui.sidebar(.{
            .current = if (m.box == .inbox) "#inbox" else "#drafts",
            .label = "Mailboxes",
            .inline_ = true,
            .footer = "<span class=\"zw-secondary\">ada@example.com</span>",
            .sections = &.{
                .{ .title = "Mailboxes", .links = &.{
                    .{ .label = "Inbox", .href = "#inbox", .icon = inbox_icon, .badge = inbox_badge },
                    .{ .label = "Drafts", .href = "#drafts", .icon = draft_icon, .badge = drafts_badge },
                    .{ .label = "Sent", .href = "#sent", .icon = sent_icon },
                    .{ .label = "Trash", .href = "#trash", .icon = trash_icon },
                } },
                .{ .title = "Smart Mailboxes", .collapsible = true, .links = &.{.{ .label = "Flagged", .href = "#flagged", .icon = star_icon }} },
                .{ .title = "Archive", .collapsible = true, .open = false, .links = &.{ .{ .label = "2025", .href = "#y2025" }, .{ .label = "2024", .href = "#y2024" } } },
            },
        }).render(w);

        const pane = "<div class=\"demo-sidebar-pane\"><h3>{title}</h3><p class=\"zw-secondary\">{text}</p><div class=\"zw-row demo-sidebar-actions\">{a}{b}{c}</div></div>";
        if (m.box == .inbox) {
            try zw.view(pane, .{
                .title = "Inbox",
                .text = text,
                .a = ui.button(.{ .label = "Receive Message", .variant = .primary, .z = .{ .post = m.url(&ua, "receive"), .target = "#demo-sidebar-mail" } }),
                .b = ui.button(.{ .label = "Mark All Read", .disabled = m.inbox == 0, .z = .{ .post = m.url(&ub, "read"), .target = "#demo-sidebar-mail" } }),
                .c = ui.button(.{ .label = "Reply", .variant = .plain, .z = .{ .post = m.url(&uc, "reply"), .target = "#demo-sidebar-mail" } }),
            }).render(w);
        } else {
            try zw.view(pane, .{
                .title = "Drafts",
                .text = text,
                .a = ui.button(.{ .label = "Send All", .variant = .primary, .disabled = m.drafts == 0, .z = .{ .post = m.url(&ua, "send"), .target = "#demo-sidebar-mail" } }),
                .b = ui.button(.{ .label = "Back to Inbox", .z = .{ .post = m.url(&ub, "inbox"), .target = "#demo-sidebar-mail" } }),
                .c = "",
            }).render(w);
        }
    }
};

fn hero(w: *Writer) Writer.Error!void {
    try w.writeAll("<div class=\"demo-sidebar-window\" id=\"demo-sidebar-mail\">");
    try (Mail{ .box = .inbox, .inbox = 3, .drafts = 0 }).render(w);
    try w.writeAll("</div>");
}

fn count(c: *zw.Ctx, name: []const u8) u32 {
    return @min(std.fmt.parseInt(u32, c.query(name) orelse "0", 10) catch 0, 98);
}

fn mailRoute(c: *zw.Ctx) !void {
    const act = c.query("a") orelse "";
    var m: Mail = .{
        .box = if (std.mem.eql(u8, c.query("b") orelse "", "drafts")) .drafts else .inbox,
        .inbox = count(c, "i"),
        .drafts = count(c, "d"),
    };
    var msg: []const u8 = "";
    if (std.mem.eql(u8, act, "receive")) {
        m.inbox += 1;
        msg = "New message received";
    } else if (std.mem.eql(u8, act, "read")) {
        m.inbox = 0;
        msg = "Inbox marked as read";
    } else if (std.mem.eql(u8, act, "reply")) {
        m.drafts += 1;
        m.box = .drafts;
        msg = "Draft saved";
    } else if (std.mem.eql(u8, act, "send")) {
        m.drafts = 0;
        m.box = .inbox;
        msg = "Drafts sent";
    } else if (std.mem.eql(u8, act, "inbox")) {
        m.box = .inbox;
    }
    if (msg.len == 0) return c.page(m);
    try c.page(zw.view("{m}{t}", .{ .m = m, .t = ui.toast(.{ .text = msg, .kind = .success }) }));
}

// Sizes: the same sections at each macOS Sidebar Icon Size.

const places: []const ui.SidebarSection = &.{
    .{ .title = "Favorites", .links = &.{
        .{ .label = "Documents", .href = "#documents", .icon = folder_icon, .badge = "24" },
        .{ .label = "Downloads", .href = "#downloads", .icon = download_icon },
        .{ .label = "Desktop", .href = "#desktop", .icon = desktop_icon },
    } },
};

fn sizes(w: *Writer) Writer.Error!void {
    try zw.view(
        \\<div class="demo-sidebar-grid">
        \\<div class="demo-sidebar-cell"><p class="zw-secondary"><code>.size = .small</code> 24 px rows</p>{a}</div>
        \\<div class="demo-sidebar-cell"><p class="zw-secondary"><code>.size = .medium</code> 28 px rows, the default</p>{b}</div>
        \\<div class="demo-sidebar-cell"><p class="zw-secondary"><code>.size = .large</code> 32 px rows</p>{c}</div>
        \\</div>
    , .{
        .a = ui.sidebar(.{ .current = "#documents", .inline_ = true, .size = .small, .label = "Small", .sections = places }),
        .b = ui.sidebar(.{ .current = "#documents", .inline_ = true, .size = .medium, .label = "Medium", .sections = places }),
        .c = ui.sidebar(.{ .current = "#documents", .inline_ = true, .size = .large, .label = "Large", .sections = places }),
    }).render(w);
}

// Sections: headings, badges, truncation and folding.

fn sections(w: *Writer) Writer.Error!void {
    try zw.view(
        \\<div class="demo-sidebar-grid">
        \\<div class="demo-sidebar-cell"><p class="zw-secondary">Untitled group, titled group, badges and a long label</p>{a}</div>
        \\<div class="demo-sidebar-cell"><p class="zw-secondary"><code>.collapsible</code> and <code>.open</code></p>{b}</div>
        \\</div>
    , .{
        .a = ui.sidebar(.{ .current = "#inbox", .inline_ = true, .label = "Badges", .sections = &.{
            .{ .title = "", .links = &.{
                .{ .label = "Inbox", .href = "#inbox", .icon = inbox_icon, .badge = "12" },
                .{ .label = "Drafts", .href = "#drafts", .icon = draft_icon },
            } },
            .{ .title = "Projects", .links = &.{
                .{ .label = "Website redesign", .href = "#web", .badge = "4" },
                .{ .label = "A project name far too long to fit in the row", .href = "#long", .badge = "128" },
            } },
        } }),
        .b = ui.sidebar(.{ .current = "#spec", .inline_ = true, .label = "Folding", .sections = &.{
            .{ .title = "Always shown", .links = &.{.{ .label = "Overview", .href = "#overview" }} },
            .{ .title = "Starts open", .collapsible = true, .links = &.{.{ .label = "Roadmap", .href = "#roadmap" }} },
            .{ .title = "Starts closed", .collapsible = true, .open = false, .links = &.{.{ .label = "Ideas", .href = "#ideas" }} },
            .{ .title = "Closed, holds the page", .collapsible = true, .open = false, .links = &.{.{ .label = "Spec", .href = "#spec" }} },
        } }),
    }).render(w);
}

// Filter: the field asks GET /demo/sidebar/filter on every keystroke, which answers with the
// sidebar holding only the matching links (sections fold open), or an empty state.

const finder: []const ui.SidebarSection = &.{
    .{ .title = "Favorites", .links = &.{
        .{ .label = "Applications", .href = "#applications", .icon = folder_icon },
        .{ .label = "Desktop", .href = "#desktop", .icon = desktop_icon },
        .{ .label = "Documents", .href = "#documents", .icon = folder_icon },
        .{ .label = "Downloads", .href = "#downloads", .icon = download_icon },
    } },
    .{ .title = "iCloud", .collapsible = true, .links = &.{
        .{ .label = "iCloud Drive", .href = "#drive", .icon = cloud_icon },
        .{ .label = "Shared", .href = "#shared", .icon = folder_icon },
    } },
    .{ .title = "Locations", .collapsible = true, .open = false, .links = &.{
        .{ .label = "Macintosh HD", .href = "#hd", .icon = desktop_icon },
        .{ .label = "Network", .href = "#network", .icon = cloud_icon },
    } },
};

fn finderNav(secs: []const ui.SidebarSection) ui.Sidebar {
    return ui.sidebar(.{ .current = "#documents", .inline_ = true, .label = "Finder", .footer = "214 GB available", .sections = secs });
}

fn filter(w: *Writer) Writer.Error!void {
    try zw.view("<div class=\"zw-stack demo-sidebar-filter\">{f}<div id=\"demo-sidebar-filter-list\">{s}</div></div>", .{
        .f = ui.field(.{ .name = "demo-sidebar-q", .label = "Filter sidebar", .placeholder = "Filter", .type = "search", .z = .{
            .get = "/demo/sidebar/filter",
            .trigger = "input",
            .target = "#demo-sidebar-filter-list",
        } }),
        .s = finderNav(finder),
    }).render(w);
}

fn filterRoute(c: *zw.Ctx) !void {
    const q = std.mem.trim(u8, c.query("demo-sidebar-q") orelse "", " ");
    var kept: std.ArrayList(ui.SidebarSection) = .empty;
    for (finder) |sec| {
        var links: std.ArrayList(ui.SidebarLink) = .empty;
        for (sec.links) |l| {
            if (q.len == 0 or std.ascii.findIgnoreCase(l.label, q) != null) try links.append(c.arena, l);
        }
        if (links.items.len == 0) continue;
        var hit = sec;
        hit.links = links.items;
        hit.open = hit.open or q.len > 0;
        try kept.append(c.arena, hit);
    }
    if (kept.items.len == 0) return c.page(ui.empty(.{ .title = "No Matches", .text = "Nothing in the sidebar matches that.", .size = .compact }));
    try c.page(finderNav(kept.items));
}

// Composition: a System Settings window. The sidebar's footer holds an account row (avatar)
// and a storage meter; the pane is a card of settings.

fn settings(w: *Writer) Writer.Error!void {
    var buf: [3072]u8 = undefined;
    var fw: Writer = .fixed(&buf);
    try fw.writeAll("<div class=\"zw-stack\"><div class=\"zw-row\">");
    try ui.avatar(.{ .name = "Ada Lovelace", .size = 28, .status = .online }).render(&fw);
    try fw.writeAll("<span class=\"zw-grow\">Ada Lovelace</span></div>");
    try ui.progress(.{ .value = 62, .label = "Storage used", .text = "124 of 200 GB", .size = .small }).render(&fw);
    try fw.writeAll("</div>");

    try w.writeAll("<div class=\"demo-sidebar-window\">");
    try ui.sidebar(.{
        .current = "#general",
        .inline_ = true,
        .size = .large,
        .label = "Settings",
        .footer = fw.buffered(),
        .sections = &.{
            .{ .title = "", .links = &.{
                .{ .label = "Wi-Fi", .href = "#wifi", .icon = wifi_icon },
                .{ .label = "Notifications", .href = "#notifications", .icon = bell_icon, .badge = "2" },
            } },
            .{ .title = "System", .links = &.{
                .{ .label = "General", .href = "#general", .icon = gear_icon },
                .{ .label = "Privacy", .href = "#privacy", .icon = lock_icon },
            } },
        },
    }).render(w);
    try ui.card(.{ .title = "General", .body = zw.view("{a}{b}{c}", .{
        .a = ui.setting(.{ .label = "Appearance", .control = ui.segmented(.{ .name = "demo-sidebar-look", .label = "Appearance", .z = d.save, .options = &.{ .{ .value = "light", .label = "Light" }, .{ .value = "dark", .label = "Dark" }, .{ .value = "auto", .label = "Auto", .selected = true } } }) }),
        .b = ui.toggle(.{ .name = "demo-sidebar-sounds", .label = "Play sounds", .on = true, .z = d.save }),
        .c = ui.toggle(.{ .name = "demo-sidebar-bars", .label = "Show scroll bars", .z = d.save }),
    }) }).render(w);
    try w.writeAll("</div>");
}
