//! Live demos for docs/pages/components/menu.md (```demo menu``` fences).
const std = @import("std");
const Writer = std.Io.Writer;
const Allocator = std.mem.Allocator;
const zw = @import("zigworks");
const ui = zw.ui;
const d = @import("demo.zig");

/// Fence name, block layout (stacked) or inline (wrapping row), render function.
pub const demos = [_]d.Demo{
    .{ "menu", true, hero },
    .{ "menu-variants", true, variants },
    .{ "menu-states", true, states },
    .{ "menu-view", true, viewDemo },
    .{ "menu-inbox", true, inboxDemo },
};
/// Extra CSS for these demos (scope it under a demo-specific class).
pub const css =
    \\.demo-menu-grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(150px,1fr));gap:20px 12px}
    \\.demo-menu-cell{display:flex;flex-direction:column;align-items:flex-start;gap:6px;min-width:0}
    \\.demo-menu-cell--end{align-items:flex-end;text-align:right}
    \\.demo-menu-ends{grid-column:1/-1;display:flex;justify-content:space-between;gap:12px}
    \\.demo-menu-cap{font:var(--footnote);color:var(--secondary)}
    \\.demo-menu-file{display:flex;flex-direction:column;gap:2px}
    \\.demo-menu-name{font:var(--body);overflow:hidden;text-overflow:ellipsis;white-space:nowrap}
    \\.demo-menu-meta{font:var(--footnote);color:var(--secondary);overflow:hidden;text-overflow:ellipsis;white-space:nowrap}
    \\.demo-menu-unread .demo-menu-name{font-weight:600}
    \\.demo-menu-title{display:flex;align-items:center;gap:8px;font:var(--title3);font-weight:600}
    \\.demo-menu-win{display:flex;flex-direction:column;min-height:176px;overflow:hidden;border-radius:var(--radius);background:var(--content);box-shadow:var(--shadow);font:var(--callout)}
    \\.demo-menu-toolbar{display:flex;justify-content:space-between;gap:8px;padding:8px 12px;background:var(--fill);border-bottom:1px solid var(--separator);
    \\& span{color:var(--secondary)}}
    \\.demo-menu-split{display:flex;flex:1}
    \\.demo-menu-side{display:flex;flex-direction:column;gap:4px;padding:10px 12px;background:var(--fill);border-right:1px solid var(--separator);color:var(--secondary)}
    \\.demo-menu-docs{flex:1;display:flex;flex-direction:column;gap:6px;margin:0;padding:10px 12px;list-style:none}
    \\.demo-menu-status{padding:6px 12px;background:var(--fill);border-top:1px solid var(--separator);font:var(--footnote);color:var(--secondary)}
    \\
;
/// Server routes these demos need, e.g. `.{ "POST /demo/menu/x", handler }`.
pub const routes = .{
    .{ "POST /demo/menu/file", fileAction },
    .{ "DELETE /demo/menu/trash", fileTrash },
    .{ "POST /demo/menu/restore", fileRestore },
    .{ "POST /demo/menu/view", viewAction },
    .{ "POST /demo/menu/mail", mailAction },
};

// Icons: 18px, drawn with currentColor.
const svg = "<svg viewBox=\"0 0 18 18\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"1.5\" stroke-linecap=\"round\" stroke-linejoin=\"round\">";
const open_icon = svg ++ "<path d=\"M10 3h5v5M15 3l-6 6M13 11v3a1 1 0 0 1-1 1H4a1 1 0 0 1-1-1V6a1 1 0 0 1 1-1h3\"/></svg>";
const copy_icon = svg ++ "<rect x=\"6\" y=\"6\" width=\"9\" height=\"9\" rx=\"2\"/><path d=\"M12 4.5V4a1 1 0 0 0-1-1H4a1 1 0 0 0-1 1v7a1 1 0 0 0 1 1h.5\"/></svg>";
const share_icon = svg ++ "<path d=\"M9 11V2.5M6 5l3-3 3 3M4.5 8H4a1 1 0 0 0-1 1v6a1 1 0 0 0 1 1h10a1 1 0 0 0 1-1V9a1 1 0 0 0-1-1h-.5\"/></svg>";
const trash_icon = svg ++ "<path d=\"M3 5h12M7 5V3h4v2M5 5l.7 10h6.6L13 5\"/></svg>";
const chevron_icon = svg ++ "<path d=\"M5 7l4 4 4-4\"/></svg>";
const more_icon = "<svg viewBox=\"0 0 18 18\" fill=\"currentColor\"><circle cx=\"4\" cy=\"9\" r=\"1.4\"/><circle cx=\"9\" cy=\"9\" r=\"1.4\"/><circle cx=\"14\" cy=\"9\" r=\"1.4\"/></svg>";

// ---------------------------------------------------------------------------------------------
// Hero: a file list with a menu on every row. The row index travels in the URL; nothing is kept
// on the server.

const File = struct { name: []const u8, meta: []const u8 };
const files = [_]File{
    .{ .name = "Quarterly plan.pdf", .meta = "PDF · 2.4 MB" },
    .{ .name = "Budget 2027.xlsx", .meta = "Spreadsheet · 480 KB" },
    .{ .name = "Team photo.png", .meta = "Image · 3.1 MB" },
    .{ .name = "Release notes.md", .meta = "Markdown · 12 KB" },
};

const FileRow = zw.View(
    "<li id=\"demo-menu-file-{i}\"><div class=\"demo-menu-file zw-grow\"><span class=\"demo-menu-name\">{name}</span><span class=\"demo-menu-meta\">{meta}</span></div>{b}{m}</li>",
    struct { i: usize, name: []const u8, meta: []const u8, b: ui.Button, m: ui.Menu },
);

/// A menu item that tells the server what happened to file `i` and changes nothing on the page.
fn fileZ(a: Allocator, i: usize, verb: []const u8) Allocator.Error!ui.Z {
    return .{ .post = try std.fmt.allocPrint(a, "/demo/menu/file?i={d}&do={s}", .{ i, verb }), .swap = .none };
}

fn fileRow(a: Allocator, i: usize) Allocator.Error!FileRow {
    const f = files[i];
    const id = try std.fmt.allocPrint(a, "demo-menu-file-{d}-menu", .{i});
    const items = try a.dupe(ui.MenuItem, &.{
        .{ .label = "Open", .icon = open_icon, .shortcut = "⌘O", .z = try fileZ(a, i, "open") },
        .{ .label = "Duplicate", .icon = copy_icon, .shortcut = "⌘D", .z = try fileZ(a, i, "duplicate") },
        .{ .label = "Share…", .icon = share_icon, .z = try fileZ(a, i, "share") },
        .{
            .label = "Move to Trash",
            .icon = trash_icon,
            .shortcut = "⌘⌫",
            .destructive = true,
            .separated = true,
            // The row is the menu's ancestor, so "closest li" finds it; the 200 from the handler carries the toast.
            .z = .{ .delete = try std.fmt.allocPrint(a, "/demo/menu/trash?i={d}", .{i}), .target = "closest li", .swap = .delete },
        },
    });
    return .{ .data = .{
        .i = i,
        .name = f.name,
        .meta = f.meta,
        .b = ui.button(.{
            .label = try std.fmt.allocPrint(a, "More actions for {s}", .{f.name}),
            .variant = .plain,
            .icon = more_icon,
            .icon_only = true,
            .opens = id,
        }),
        .m = ui.menu(.{ .id = id, .label = "File actions", .alignment = .end, .items = items }),
    } };
}

const FileRows = struct {
    a: Allocator,
    pub fn render(self: FileRows, w: *Writer) Writer.Error!void {
        for (0..files.len) |i| try (fileRow(self.a, i) catch return error.WriteFailed).render(w);
    }
};

fn fileIndex(c: *zw.Ctx) ?usize {
    const i = std.fmt.parseInt(usize, c.query("i") orelse return null, 10) catch return null;
    return if (i < files.len) i else null;
}

fn fileAction(c: *zw.Ctx) !void {
    const i = fileIndex(c) orelse return c.send(.bad_request, "text/plain", "bad file");
    const verb = c.query("do") orelse "";
    const name = files[i].name;
    if (std.mem.eql(u8, verb, "duplicate")) {
        return c.page(ui.toast(.{ .text = try std.fmt.allocPrint(c.arena, "Duplicated “{s}”", .{name}), .kind = .success }));
    }
    if (std.mem.eql(u8, verb, "share")) {
        return c.page(ui.toast(.{ .text = try std.fmt.allocPrint(c.arena, "Link to “{s}” copied", .{name}), .kind = .success }));
    }
    try c.page(ui.toast(.{ .text = try std.fmt.allocPrint(c.arena, "Opening “{s}”", .{name}) }));
}

fn fileTrash(c: *zw.Ctx) !void {
    const i = fileIndex(c) orelse return c.send(.bad_request, "text/plain", "bad file");
    // The toast is out-of-band; z.js then removes the row (swap = delete). Undo closes the toast
    // and puts the row back through the list's own id (see fileRestore).
    try c.page(ui.toast(.{
        .text = try std.fmt.allocPrint(c.arena, "Moved “{s}” to the Trash", .{files[i].name}),
        .action = "Undo",
        .z = .{ .post = try std.fmt.allocPrint(c.arena, "/demo/menu/restore?i={d}", .{i}), .target = "closest .zw-toast", .swap = .delete },
        .sticky = true,
    }));
}

fn fileRestore(c: *zw.Ctx) !void {
    const i = fileIndex(c) orelse return c.send(.bad_request, "text/plain", "bad file");
    try c.html("<ul id=\"demo-menu-files\" z-oob=\"beforeend\">{row}</ul>", .{ .row = try fileRow(c.arena, i) });
}

fn hero(w: *Writer) Writer.Error!void {
    var buf: [16384]u8 = undefined;
    var fba: std.heap.FixedBufferAllocator = .init(&buf);
    try ui.list(.{
        .id = "demo-menu-files",
        .header = "Recents",
        .footer = "Use the ⋯ button on a row. Move a file to the Trash, then undo it.",
        .empty = "Every file is in the Trash.",
        .body = FileRows{ .a = fba.allocator() },
    }).render(w);
}

// ---------------------------------------------------------------------------------------------
// Variants: one menu per feature, labelled with the props it shows.

fn variants(w: *Writer) Writer.Error!void {
    try zw.view(
        \\<div class="demo-menu-grid">
        \\<div class="demo-menu-cell"><span class="demo-menu-cap">Labels only</span>{b1}{m1}</div>
        \\<div class="demo-menu-cell"><span class="demo-menu-cap"><code>icon</code> <code>shortcut</code></span>{b2}{m2}</div>
        \\<div class="demo-menu-cell"><span class="demo-menu-cap"><code>checked</code></span>{b3}{m3}</div>
        \\<div class="demo-menu-cell"><span class="demo-menu-cap"><code>header</code> <code>separated</code></span>{b4}{m4}</div>
        \\<div class="demo-menu-cell"><span class="demo-menu-cap"><code>href</code> <code>disabled</code></span>{b5}{m5}</div>
        \\<div class="demo-menu-cell"><span class="demo-menu-cap"><code>destructive</code></span>{b6}{m6}</div>
        \\<div class="demo-menu-ends">
        \\<div class="demo-menu-cell"><span class="demo-menu-cap"><code>alignment = .start</code></span>{b7}{m7}</div>
        \\<div class="demo-menu-cell demo-menu-cell--end"><span class="demo-menu-cap"><code>alignment = .end</code></span>{b8}{m8}</div>
        \\</div>
        \\</div>
    , .{
        .b1 = ui.button(.{ .label = "New", .opens = "demo-menu-v-plain" }),
        .m1 = ui.menu(.{ .id = "demo-menu-v-plain", .label = "New", .items = &.{
            .{ .label = "Folder", .z = d.save },
            .{ .label = "Document", .z = d.save },
            .{ .label = "Import…", .z = d.save },
        } }),
        .b2 = ui.button(.{ .label = "File", .opens = "demo-menu-v-icons" }),
        .m2 = ui.menu(.{ .id = "demo-menu-v-icons", .label = "File", .items = &.{
            .{ .label = "Open", .icon = open_icon, .shortcut = "⌘O", .z = d.save },
            .{ .label = "Duplicate", .icon = copy_icon, .shortcut = "⌘D", .z = d.save },
            .{ .label = "Share…", .icon = share_icon, .z = d.save },
        } }),
        .b3 = ui.button(.{ .label = "View", .opens = "demo-menu-v-checks" }),
        .m3 = ui.menu(.{ .id = "demo-menu-v-checks", .label = "View", .items = &.{
            .{ .label = "Sidebar", .checked = true, .shortcut = "⌘B", .z = d.save },
            .{ .label = "Toolbar", .checked = true, .z = d.save },
            .{ .label = "Status Bar", .checked = false, .z = d.save },
        } }),
        .b4 = ui.button(.{ .label = "Sort", .opens = "demo-menu-v-sections" }),
        .m4 = ui.menu(.{ .id = "demo-menu-v-sections", .label = "Sort", .items = &.{
            .{ .label = "Name", .checked = true, .header = "Sort by", .z = d.save },
            .{ .label = "Date Modified", .checked = false, .z = d.save },
            .{ .label = "Size", .checked = false, .z = d.save },
            .{ .label = "Ascending", .checked = true, .separated = true, .header = "Order", .z = d.save },
            .{ .label = "Descending", .checked = false, .z = d.save },
        } }),
        .b5 = ui.button(.{ .label = "Help", .opens = "demo-menu-v-links" }),
        .m5 = ui.menu(.{ .id = "demo-menu-v-links", .label = "Help", .items = &.{
            .{ .label = "Documentation", .href = "/components/layout" },
            .{ .label = "Keyboard Shortcuts", .href = "/components/kbd" },
            .{ .label = "Release Notes", .href = "/", .disabled = true },
        } }),
        .b6 = ui.button(.{ .label = "Item", .opens = "demo-menu-v-danger" }),
        .m6 = ui.menu(.{ .id = "demo-menu-v-danger", .label = "Item", .items = &.{
            .{ .label = "Rename…", .z = d.save },
            .{ .label = "Duplicate", .z = d.save },
            .{ .label = "Delete…", .destructive = true, .separated = true, .z = d.save },
        } }),
        .b7 = ui.button(.{ .label = "Left", .opens = "demo-menu-v-start" }),
        .m7 = ui.menu(.{ .id = "demo-menu-v-start", .label = "Left", .alignment = .start, .items = &.{
            .{ .label = "Opens to the right", .z = d.save },
            .{ .label = "Of the button", .z = d.save },
        } }),
        .b8 = ui.button(.{ .label = "Right", .opens = "demo-menu-v-end" }),
        .m8 = ui.menu(.{ .id = "demo-menu-v-end", .label = "Right", .alignment = .end, .items = &.{
            .{ .label = "Opens to the left", .z = d.save },
            .{ .label = "Of the button", .z = d.save },
        } }),
    }).render(w);
}

// ---------------------------------------------------------------------------------------------
// States: what a menu looks like when items or the whole thing can't be used.

fn states(w: *Writer) Writer.Error!void {
    try zw.view(
        \\<div class="demo-menu-grid">
        \\<div class="demo-menu-cell"><span class="demo-menu-cap">Disabled items</span>{b1}{m1}</div>
        \\<div class="demo-menu-cell"><span class="demo-menu-cap">Disabled link</span>{b2}{m2}</div>
        \\<div class="demo-menu-cell"><span class="demo-menu-cap">Disabled button</span>{b3}{m3}</div>
        \\<div class="demo-menu-cell"><span class="demo-menu-cap">Marks and plain items</span>{b4}{m4}</div>
        \\<div class="demo-menu-cell"><span class="demo-menu-cap">Long labels</span>{b5}{m5}</div>
        \\</div>
    , .{
        .b1 = ui.button(.{ .label = "Edit", .opens = "demo-menu-s-edit" }),
        .m1 = ui.menu(.{ .id = "demo-menu-s-edit", .label = "Edit", .items = &.{
            .{ .label = "Undo", .shortcut = "⌘Z", .disabled = true },
            .{ .label = "Redo", .shortcut = "⇧⌘Z", .disabled = true },
            .{ .label = "Cut", .shortcut = "⌘X", .disabled = true, .separated = true },
            .{ .label = "Copy", .shortcut = "⌘C", .disabled = true },
            .{ .label = "Paste", .shortcut = "⌘V", .z = d.save },
            .{ .label = "Select All", .shortcut = "⌘A", .z = d.save },
        } }),
        .b2 = ui.button(.{ .label = "Account", .opens = "demo-menu-s-account" }),
        .m2 = ui.menu(.{ .id = "demo-menu-s-account", .label = "Account", .items = &.{
            .{ .label = "Profile", .href = "/components/avatar" },
            .{ .label = "Billing", .href = "/", .disabled = true },
            .{ .label = "Sign Out", .destructive = true, .separated = true, .z = d.save },
        } }),
        // Nothing to export, so the button is disabled; the menu behind it can never open.
        .b3 = ui.button(.{ .label = "Export", .opens = "demo-menu-s-export", .disabled = true }),
        .m3 = ui.menu(.{ .id = "demo-menu-s-export", .label = "Export", .items = &.{
            .{ .label = "PDF", .z = d.save },
            .{ .label = "PNG", .z = d.save },
        } }),
        .b4 = ui.button(.{ .label = "Window", .opens = "demo-menu-s-window" }),
        .m4 = ui.menu(.{ .id = "demo-menu-s-window", .label = "Window", .items = &.{
            .{ .label = "Minimize", .shortcut = "⌘M", .z = d.save },
            .{ .label = "Zoom", .z = d.save },
            .{ .label = "Inbox", .checked = true, .separated = true, .header = "Open windows", .z = d.save },
            .{ .label = "Drafts", .checked = false, .z = d.save },
            .{ .label = "Sent", .checked = false, .z = d.save },
        } }),
        .b5 = ui.button(.{ .label = "Share", .opens = "demo-menu-s-long" }),
        .m5 = ui.menu(.{ .id = "demo-menu-s-long", .label = "Share", .items = &.{
            .{ .label = "Copy a public link to the whole shared project folder", .icon = share_icon, .z = d.save },
            .{ .label = "Send a copy by email", .icon = copy_icon, .shortcut = "⇧⌘E", .z = d.save },
        } }),
    }).render(w);
}

// ---------------------------------------------------------------------------------------------
// Interactive: a View menu with checkmarks. Each item posts the state it would produce; the server
// answers with the new menu (so the marks follow) and the preview window (out-of-band).

const Sort = enum { name, date, size };
const ViewState = struct { sidebar: bool = true, toolbar: bool = true, status: bool = false, sort: Sort = .name };

const sorted = [3][3][]const u8{
    .{ "Annual report.pdf · 480 KB", "Budget.xlsx · 2.4 MB", "Cover letter.docx · 36 KB" },
    .{ "Cover letter.docx · Mar 9", "Budget.xlsx · Mar 2", "Annual report.pdf · Feb 20" },
    .{ "Budget.xlsx · 2.4 MB", "Annual report.pdf · 480 KB", "Cover letter.docx · 36 KB" },
};

const Preview = zw.View(
    \\<div class="demo-menu-win" id="demo-menu-preview" z-oob>
    \\{#if toolbar}<div class="demo-menu-toolbar"><strong>Documents</strong><span>Sorted by {sort}</span></div>{/if}
    \\<div class="demo-menu-split">
    \\{#if sidebar}<nav class="demo-menu-side" aria-label="Places"><span>Recents</span><span>Documents</span><span>Downloads</span></nav>{/if}
    \\<ul class="demo-menu-docs">{#each rows as r}<li>{r}</li>{/each}</ul>
    \\</div>
    \\{#if status}<div class="demo-menu-status">3 items</div>{/if}
    \\</div>
, struct { toolbar: bool, sidebar: bool, status: bool, sort: Sort, rows: []const []const u8 });

fn preview(st: ViewState) Preview {
    return .{ .data = .{
        .toolbar = st.toolbar,
        .sidebar = st.sidebar,
        .status = st.status,
        .sort = st.sort,
        .rows = &sorted[@backingInt(st.sort)],
    } };
}

fn viewZ(a: Allocator, st: ViewState) Allocator.Error!ui.Z {
    const url = try std.fmt.allocPrint(a, "/demo/menu/view?s={d}&t={d}&b={d}&o={s}", .{ @intFromBool(st.sidebar), @intFromBool(st.toolbar), @intFromBool(st.status), @tagName(st.sort) });
    return .{ .post = url, .target = "#demo-menu-view-menu", .swap = .outer };
}

fn viewMenu(a: Allocator, st: ViewState) Allocator.Error!ui.Menu {
    var sidebar = st;
    sidebar.sidebar = !st.sidebar;
    var toolbar = st;
    toolbar.toolbar = !st.toolbar;
    var status = st;
    status.status = !st.status;
    var by_name = st;
    by_name.sort = .name;
    var by_date = st;
    by_date.sort = .date;
    var by_size = st;
    by_size.sort = .size;
    const items = try a.dupe(ui.MenuItem, &.{
        .{ .label = "Sidebar", .checked = st.sidebar, .header = "Show", .z = try viewZ(a, sidebar) },
        .{ .label = "Toolbar", .checked = st.toolbar, .z = try viewZ(a, toolbar) },
        .{ .label = "Status Bar", .checked = st.status, .z = try viewZ(a, status) },
        .{ .label = "Name", .checked = st.sort == .name, .separated = true, .header = "Sort by", .z = try viewZ(a, by_name) },
        .{ .label = "Date Modified", .checked = st.sort == .date, .z = try viewZ(a, by_date) },
        .{ .label = "Size", .checked = st.sort == .size, .z = try viewZ(a, by_size) },
    });
    return ui.menu(.{ .id = "demo-menu-view-menu", .label = "View", .items = items });
}

fn flag(c: *zw.Ctx, name: []const u8) bool {
    return std.mem.eql(u8, c.query(name) orelse "", "1");
}

fn viewAction(c: *zw.Ctx) !void {
    const st: ViewState = .{
        .sidebar = flag(c, "s"),
        .toolbar = flag(c, "t"),
        .status = flag(c, "b"),
        .sort = std.meta.stringToEnum(Sort, c.query("o") orelse "") orelse .name,
    };
    try c.html("{menu}{preview}", .{ .menu = try viewMenu(c.arena, st), .preview = preview(st) });
}

fn viewDemo(w: *Writer) Writer.Error!void {
    var buf: [4096]u8 = undefined;
    var fba: std.heap.FixedBufferAllocator = .init(&buf);
    const st: ViewState = .{};
    try zw.view("<div>{b}{m}</div>{p}", .{
        .b = ui.button(.{ .label = "View", .opens = "demo-menu-view-menu" }),
        .m = viewMenu(fba.allocator(), st) catch return error.WriteFailed,
        .p = preview(st),
    }).render(w);
}

// ---------------------------------------------------------------------------------------------
// Composition: an inbox. The menu filters and marks; the badge, the list and the menu itself all
// answer in one response. The state is a bitmask of unread messages plus a filter, kept in the URL.

const Filter = enum { all, unread };
const Inbox = struct { unread: u8 = 0b0111, filter: Filter = .all };

const Mail = struct { from: []const u8, subject: []const u8 };
const mails = [_]Mail{
    .{ .from = "Ada Lovelace", .subject = "Notes on the Analytical Engine" },
    .{ .from = "Grace Hopper", .subject = "Re: compiler draft" },
    .{ .from = "Alan Turing", .subject = "Machine intelligence reading list" },
    .{ .from = "Katherine Johnson", .subject = "Trajectory check, final numbers" },
};

const Mailbox = struct {
    st: Inbox,
    pub fn render(self: Mailbox, w: *Writer) Writer.Error!void {
        for (mails, 0..) |m, i| {
            const unread = (self.st.unread & (@as(u8, 1) << @intCast(i))) != 0;
            if (self.st.filter == .unread and !unread) continue;
            try zw.view(
                "<li{#if unread} class=\"demo-menu-unread\"{/if}>{av}<div class=\"demo-menu-file zw-grow\"><span class=\"demo-menu-name\">{from}</span><span class=\"demo-menu-meta\">{subject}</span></div>{#if unread}{dot}{/if}</li>",
                .{
                    .unread = unread,
                    .av = ui.avatar(.{ .name = m.from }),
                    .from = m.from,
                    .subject = m.subject,
                    .dot = ui.badge(.{ .dot = true, .tone = .accent, .text = "Unread" }),
                },
            ).render(w);
        }
    }
};

const MailBody = zw.View("<div id=\"demo-menu-mailbox\"{#if oob} z-oob{/if}>{list}</div>", struct { oob: bool, list: ui.List(Mailbox) });

fn mailBody(st: Inbox, oob: bool) MailBody {
    return .{ .data = .{
        .oob = oob,
        .list = ui.list(.{ .id = "demo-menu-mail", .empty = "No unread messages", .body = Mailbox{ .st = st } }),
    } };
}

fn mailBadge(st: Inbox, oob: bool) ui.Badge {
    return ui.badge(.{ .id = "demo-menu-count", .count = @popCount(st.unread), .hide_zero = true, .tone = .accent, .solid = true, .oob = oob });
}

fn mailZ(a: Allocator, st: Inbox, act: []const u8) Allocator.Error!ui.Z {
    const url = try std.fmt.allocPrint(a, "/demo/menu/mail?u={d}&f={s}&a={s}", .{ st.unread, @tagName(st.filter), act });
    return .{ .post = url, .target = "#demo-menu-mail-menu", .swap = .outer };
}

fn mailMenu(a: Allocator, st: Inbox) Allocator.Error!ui.Menu {
    const items = try a.dupe(ui.MenuItem, &.{
        .{ .label = "All Messages", .checked = st.filter == .all, .header = "Show", .z = try mailZ(a, st, "show-all") },
        .{ .label = "Unread Only", .checked = st.filter == .unread, .z = try mailZ(a, st, "show-unread") },
        .{ .label = "Mark All as Read", .separated = true, .disabled = st.unread == 0, .z = try mailZ(a, st, "mark-read") },
        .{ .label = "Mark All as Unread", .disabled = st.unread == 0b1111, .z = try mailZ(a, st, "mark-unread") },
    });
    return ui.menu(.{ .id = "demo-menu-mail-menu", .label = "Mailbox", .alignment = .end, .items = items });
}

fn mailAction(c: *zw.Ctx) !void {
    var st: Inbox = .{
        .unread = (std.fmt.parseInt(u8, c.query("u") orelse "", 10) catch 0b0111) & 0b1111,
        .filter = std.meta.stringToEnum(Filter, c.query("f") orelse "") orelse .all,
    };
    const act = c.query("a") orelse "";
    if (std.mem.eql(u8, act, "show-all")) st.filter = .all;
    if (std.mem.eql(u8, act, "show-unread")) st.filter = .unread;
    if (std.mem.eql(u8, act, "mark-read")) st.unread = 0;
    if (std.mem.eql(u8, act, "mark-unread")) st.unread = 0b1111;
    try c.html("{menu}{badge}{body}", .{ .menu = try mailMenu(c.arena, st), .badge = mailBadge(st, true), .body = mailBody(st, true) });
}

fn inboxDemo(w: *Writer) Writer.Error!void {
    var buf: [4096]u8 = undefined;
    var fba: std.heap.FixedBufferAllocator = .init(&buf);
    const st: Inbox = .{};
    try zw.view(
        \\<div class="zw-stack">
        \\<div class="zw-row"><span class="demo-menu-title zw-grow">Inbox {badge}</span>{b}{m}</div>
        \\{body}
        \\</div>
    , .{
        .badge = mailBadge(st, false),
        .b = ui.button(.{ .label = "Mailbox", .variant = .plain, .icon = chevron_icon, .icon_end = true, .opens = "demo-menu-mail-menu" }),
        .m = mailMenu(fba.allocator(), st) catch return error.WriteFailed,
        .body = mailBody(st, false),
    }).render(w);
}
