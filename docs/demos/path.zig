//! Live demos for docs/pages/components/path.md (```demo path``` fences).
const std = @import("std");
const Writer = std.Io.Writer;
const zw = @import("zigworks");
const ui = zw.ui;
const d = @import("demo.zig");

/// Fence name, block layout (stacked) or inline (wrapping row), render function.
pub const demos = [_]d.Demo{
    .{ "path", true, browser },
    .{ "path-variants", true, variants },
    .{ "path-states", true, states },
    .{ "path-folding", true, folding },
    .{ "path-compose", true, compose },
};
/// Extra CSS for these demos (scope it under a demo-specific class).
pub const css =
    \\.demo-path-bar{display:flex;align-items:center;gap:6px;padding:4px 10px 4px 4px;border-radius:10px;background:var(--fill)}
    \\.demo-path-cap{margin:0 0 4px 6px;font:var(--footnote);font-family:var(--mono);color:var(--secondary)}
    \\.demo-path-from,.demo-path-subj{display:block;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}
    \\.demo-path-subj{font:var(--callout);color:var(--secondary)}
    \\.demo-path-unread .demo-path-from{font-weight:600}
    \\.demo-path-unread::after{content:"";flex:none;width:8px;height:8px;border-radius:50%;background:var(--accent)}
    \\
;
/// Server routes these demos need, e.g. `.{ "POST /demo/path/x", handler }`.
pub const routes = .{
    .{ "GET /demo/path/browse", browse },
    .{ "GET /demo/path/mailbox", mailbox },
};

// A caption above a path bar, so readers can map each one to the props that made it.
const Row = zw.View("<div><p class=\"demo-path-cap\">{cap}</p>{bar}</div>", struct { cap: []const u8, bar: ui.Path });

fn row(cap: []const u8, bar: ui.Path) Row {
    return .{ .data = .{ .cap = cap, .bar = bar } };
}

// ---- Hero: a Finder-style folder browser ----------------------------------------------------

const browser_id = "demo-path-browser";

/// The sample folder tree: the names a folder at each depth contains.
const tree = [_][]const []const u8{
    &.{ "Documents", "Pictures", "Music" },
    &.{ "Projects", "Archive", "Drafts" },
    &.{ "Reports", "Invoices", "Sketches" },
    &.{ "2025", "2026" },
};

/// Keeps `p` only when every segment is a folder of the sample tree, so it is safe to echo into markup.
fn clean(p: []const u8) []const u8 {
    if (p.len == 0) return p;
    var depth: usize = 0;
    var it = std.mem.splitScalar(u8, p, '/');
    while (it.next()) |seg| : (depth += 1) {
        if (depth >= tree.len) return "";
        const known = for (tree[depth]) |name| {
            if (std.mem.eql(u8, seg, name)) break true;
        } else false;
        if (!known) return "";
    }
    return p;
}

/// The subfolders of the folder at `p`, as navigation rows that open them in place.
const Folders = struct {
    p: []const u8,

    pub fn render(self: Folders, w: *Writer) Writer.Error!void {
        const depth = if (self.p.len == 0) 0 else 1 + std.mem.countScalar(u8, self.p, '/');
        if (depth >= tree.len) return; // the list is empty: its "empty" text shows
        const sep = if (self.p.len == 0) "" else "/";
        for (tree[depth]) |name| try w.print(
            "<li><a href=\"#{s}\" z-get=\"/demo/path/browse?p={s}{s}{s}\" z-target=\"#{s}\" z-swap=\"inner\"><span aria-hidden=\"true\">📁</span><span class=\"zw-grow\">{s}</span></a></li>",
            .{ browser_id, self.p, sep, name, browser_id, name },
        );
    }
};

/// A path item that opens the folder `dir` in place, with a plain link to the browser as the fallback.
fn crumb(buf: *[96]u8, label: []const u8, dir: []const u8, icon: []const u8) ui.PathItem {
    const url = std.fmt.bufPrint(buf, "/demo/path/browse?p={s}", .{dir}) catch unreachable;
    return .{ .label = label, .href = "#" ++ browser_id, .icon = icon, .z = .{ .get = url, .target = "#" ++ browser_id, .swap = .inner } };
}

/// The path bar with an Up button, and the folder's contents under it.
const Browse = struct {
    p: []const u8,

    pub fn render(self: Browse, w: *Writer) Writer.Error!void {
        const p = self.p;
        // Every ancestor is a link that opens its folder in place; the last one is the current folder.
        var items: [tree.len + 1]ui.PathItem = undefined;
        var urls: [tree.len + 1][96]u8 = undefined;
        items[0] = crumb(&urls[0], "Home", "", "⌂");
        var n: usize = 1;
        if (p.len > 0) {
            var it = std.mem.splitScalar(u8, p, '/');
            while (it.next()) |seg| : (n += 1) {
                const end = @intFromPtr(seg.ptr) - @intFromPtr(p.ptr) + seg.len; // the path up to and including seg
                items[n] = crumb(&urls[n], seg, p[0..end], "");
            }
        }

        const parent = if (std.mem.cutScalarLast(u8, p, '/')) |c| c[0] else "";
        var buf: [96]u8 = undefined;
        const up_url = std.fmt.bufPrint(&buf, "/demo/path/browse?p={s}", .{parent}) catch unreachable;
        const up_icon = "<svg viewBox=\"0 0 18 18\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"1.7\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><path d=\"M11.5 4l-5 5 5 5\"/></svg>";

        try w.writeAll("<div class=\"demo-path-bar\">");
        try ui.button(.{
            .label = "Up one folder",
            .icon = up_icon,
            .icon_only = true,
            .variant = .plain,
            .size = .small,
            .disabled = p.len == 0,
            .z = .{ .get = up_url, .target = "#" ++ browser_id, .swap = .inner },
        }).render(w);
        try w.writeAll("<div class=\"zw-grow\">");
        try ui.path(.{ .items = items[0..n], .label = "Folder path", .max = 4 }).render(w);
        try w.writeAll("</div></div>");
        try ui.list(.{ .id = "demo-path-folders", .nav = true, .empty = "This folder is empty", .body = Folders{ .p = p } }).render(w);
    }
};

fn browse(c: *zw.Ctx) !void {
    try c.page(Browse{ .p = clean(c.query("p") orelse "") });
}

fn browser(w: *Writer) Writer.Error!void {
    try zw.view("<div class=\"zw-stack\" id=\"" ++ browser_id ++ "\">{b}</div>", .{ .b = Browse{ .p = "Documents/Projects" } }).render(w);
}

// ---- Variants -------------------------------------------------------------------------------

fn variants(w: *Writer) Writer.Error!void {
    const trail: []const ui.PathItem = &.{
        .{ .label = "Settings", .href = "/" },
        .{ .label = "Privacy & Security", .href = "/" },
        .{ .label = "Location Services" },
    };
    const icons: []const ui.PathItem = &.{
        .{ .label = "Home", .href = "/", .icon = "⌂" },
        .{ .label = "Photos", .href = "/", .icon = "🖼" },
        .{ .label = "Holiday", .icon = "🏝" },
    };
    try zw.view("<div class=\"zw-stack\">{a}{b}{c}{d}</div>", .{
        .a = row("separator = .chevron (default)", ui.path(.{ .items = trail })),
        .b = row("separator = .slash", ui.path(.{ .items = trail, .separator = .slash })),
        .c = row("icon on items", ui.path(.{ .items = icons })),
        .d = row("slash + icons", ui.path(.{ .items = icons, .separator = .slash })),
    }).render(w);
}

// ---- States ---------------------------------------------------------------------------------

fn states(w: *Writer) Writer.Error!void {
    try zw.view("<div class=\"zw-stack\">{a}{b}{c}{d}</div>", .{
        .a = row("one item: the top level, already current", ui.path(.{ .items = &.{
            .{ .label = "Home", .icon = "⌂" },
        } })),
        .b = row("href empty: a plain-text segment", ui.path(.{ .items = &.{
            .{ .label = "Settings", .href = "/" },
            .{ .label = "Accounts" },
            .{ .label = "Mail" },
        } })),
        .c = row("long labels shorten with an ellipsis", ui.path(.{ .items = &.{
            .{ .label = "Home", .href = "/" },
            .{ .label = "Quarterly planning documents for the whole engineering organisation", .href = "/" },
            .{ .label = "Draft of the annual roadmap with comments from every team lead" },
        } })),
        .d = row("label = \"Breadcrumb\" (the nav's accessible name)", ui.path(.{ .label = "Breadcrumb", .items = &.{
            .{ .label = "Store", .href = "/" },
            .{ .label = "Keyboards" },
        } })),
    }).render(w);
}

// ---- Folding long paths ---------------------------------------------------------------------

fn folding(w: *Writer) Writer.Error!void {
    const deep: []const ui.PathItem = &.{
        .{ .label = "Home", .href = "/", .icon = "⌂" },
        .{ .label = "Documents", .href = "/" },
        .{ .label = "Projects", .href = "/" },
        .{ .label = "zigworks", .href = "/" },
        .{ .label = "docs", .href = "/" },
        .{ .label = "Reports", .href = "/" },
        .{ .label = "Summary" },
    };
    try zw.view("<div class=\"zw-stack\">{a}{b}{c}{d}</div>", .{
        .a = row("max = 0 (default): show everything", ui.path(.{ .items = deep })),
        .b = row("max = 5: first item + last 4", ui.path(.{ .items = deep, .max = 5 })),
        .c = row("max = 3: first item + last 2", ui.path(.{ .items = deep, .max = 3 })),
        .d = row("max = 2, slash: first and current only", ui.path(.{ .items = deep, .max = 2, .separator = .slash })),
    }).render(w);
}

// ---- Composition: a Mail mailbox switcher ---------------------------------------------------

const Message = struct { from: []const u8, subject: []const u8, unread: bool = false };
const Mailbox = struct { value: []const u8, name: []const u8, messages: []const Message };

const mailboxes = [_]Mailbox{
    .{ .value = "inbox", .name = "Inbox", .messages = &.{
        .{ .from = "Ada Lovelace", .subject = "Notes on the Analytical Engine", .unread = true },
        .{ .from = "Grace Hopper", .subject = "Compiler review for Friday", .unread = true },
        .{ .from = "Alan Turing", .subject = "Lunch on Thursday?" },
    } },
    .{ .value = "sent", .name = "Sent", .messages = &.{
        .{ .from = "To: Grace Hopper", .subject = "Re: Compiler review for Friday" },
        .{ .from = "To: Ada Lovelace", .subject = "Thanks for the notes" },
    } },
    .{ .value = "drafts", .name = "Drafts", .messages = &.{
        .{ .from = "To: Alan Turing", .subject = "Lunch on Thursday works" },
    } },
};

fn unreadIn(box: Mailbox) u32 {
    var n: u32 = 0;
    for (box.messages) |m| n += @intFromBool(m.unread);
    return n;
}

fn unreadBadge(box: Mailbox, oob: bool) ui.Badge {
    return ui.badge(.{ .id = "demo-path-unread", .oob = oob, .count = unreadIn(box), .tone = .red, .solid = true, .hide_zero = true });
}

/// The path bar and the message list of one mailbox, plus the unread badge as an out-of-band update.
const Mail = struct {
    box: Mailbox,
    oob: bool,

    pub fn render(self: Mail, w: *Writer) Writer.Error!void {
        const items = [_]ui.PathItem{
            .{ .label = "Mail", .href = "#demo-path-mail", .icon = "✉" },
            .{ .label = "Personal" },
            .{ .label = self.box.name },
        };
        try ui.path(.{ .items = &items, .separator = .slash, .label = "Mailbox path" }).render(w);
        try ui.list(.{
            .id = "demo-path-messages",
            .inset = false,
            .empty = "No messages",
            .body = zw.view("{#each rows as m}<li{#if m.unread} class=\"demo-path-unread\"{/if}><span class=\"zw-grow\"><span class=\"demo-path-from\">{m.from}</span><span class=\"demo-path-subj\">{m.subject}</span></span></li>{/each}", .{ .rows = self.box.messages }),
        }).render(w);
        if (self.oob) try unreadBadge(self.box, true).render(w);
    }
};

fn mailbox(c: *zw.Ctx) !void {
    const want = c.query("box") orelse "";
    for (mailboxes) |box| {
        if (std.mem.eql(u8, box.value, want)) return c.page(Mail{ .box = box, .oob = true });
    }
    try c.page(Mail{ .box = mailboxes[0], .oob = true });
}

fn compose(w: *Writer) Writer.Error!void {
    const first = mailboxes[0];
    try ui.card(.{
        .title = "Mail",
        .accessory = unreadBadge(first, false),
        .body = zw.view("<div class=\"zw-stack\">{seg}<div class=\"zw-stack\" id=\"demo-path-mail\">{view}</div></div>", .{
            .seg = ui.segmented(.{
                .name = "box",
                .label = "Mailbox",
                .z = .{ .get = "/demo/path/mailbox", .target = "#demo-path-mail", .swap = .inner },
                .options = &.{
                    .{ .value = "inbox", .label = "Inbox", .selected = true },
                    .{ .value = "sent", .label = "Sent" },
                    .{ .value = "drafts", .label = "Drafts" },
                },
            }),
            .view = Mail{ .box = first, .oob = false },
        }),
    }).render(w);
}
