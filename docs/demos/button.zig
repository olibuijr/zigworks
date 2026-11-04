//! Live demos for docs/pages/components/button.md (```demo button``` fences).
const std = @import("std");
const Writer = std.Io.Writer;
const zw = @import("zigworks");
const ui = zw.ui;
const d = @import("demo.zig");

/// Fence name, block layout (stacked) or inline (wrapping row), render function.
pub const demos = [_]d.Demo{
    .{ "button", true, hero },
    .{ "button-variants", true, variants },
    .{ "button-content", true, content },
    .{ "button-states", true, states },
    .{ "button-actions", true, actions },
    .{ "button-toolbar", true, toolbar },
};
/// Extra CSS for these demos (scope it under a demo-specific class).
pub const css =
    \\.demo-button-grid{display:grid;grid-template-columns:max-content 1fr;gap:14px 20px;align-items:center;
    \\  &>code{justify-self:start;color:var(--secondary)}}
    \\.demo-button-set{display:flex;flex-wrap:wrap;align-items:center;gap:8px}
    \\.demo-button-tools{flex-wrap:nowrap;gap:2px}
    \\.demo-button-count{display:inline-flex;align-items:center;gap:6px;margin-left:4px;font:var(--callout);color:var(--secondary)}
    \\.demo-button-msg{margin-top:14px;
    \\  & p{color:var(--secondary)}}
    \\@media (max-width:599px){.demo-button-grid{grid-template-columns:minmax(0,1fr);gap:6px}.demo-button-grid>code{margin-top:10px}}
    \\
;
/// Server routes these demos need, e.g. `.{ "POST /demo/button/x", handler }`.
pub const routes = .{
    .{ "POST /demo/button/save", saveProfile },
    .{ "POST /demo/button/sync", syncStep },
    .{ "POST /demo/button/cart", cartStep },
    .{ "POST /demo/button/toast", toolbarToast },
};

const svg = "<svg viewBox=\"0 0 18 18\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"1.6\" stroke-linecap=\"round\" stroke-linejoin=\"round\">";
const plus = svg ++ "<path d=\"M9 3.5v11M3.5 9h11\"/></svg>";
const chevron = svg ++ "<path d=\"M6.5 4l5 5-5 5\"/></svg>";
const download = svg ++ "<path d=\"M9 2.5v9M5.5 8L9 11.5 12.5 8M3 14.5h12\"/></svg>";
const refresh = svg ++ "<path d=\"M15 9a6 6 0 1 1-1.8-4.3M15 2.5v3.5h-3.5\"/></svg>";
const trash = svg ++ "<path d=\"M3 5h12M7 5V3h4v2M5 5l.7 10h6.6L13 5\"/></svg>";
const cart = svg ++ "<path d=\"M2 3h2l1.6 8h7.8l1.4-5.5H5M7 15.2h.01M13 15.2h.01\"/></svg>";
const compose = svg ++ "<path d=\"M3 15l.8-3.6 8.5-8.5a1.4 1.4 0 0 1 2 0l1.3 1.3a1.4 1.4 0 0 1 0 2l-8.5 8.5zM11 4.5l2.5 2.5\"/></svg>";
const reply = svg ++ "<path d=\"M7.5 4L3 8.5 7.5 13M3 8.5h7.5a4.5 4.5 0 0 1 4.5 4.5v1\"/></svg>";
const archive = svg ++ "<path d=\"M2.5 4h13v3h-13zM3.5 7v7.5h11V7M7.5 10.5h3\"/></svg>";
const more = svg ++ "<circle cx=\"3.5\" cy=\"9\" r=\"1.2\" fill=\"currentColor\" stroke=\"none\"/><circle cx=\"9\" cy=\"9\" r=\"1.2\" fill=\"currentColor\" stroke=\"none\"/><circle cx=\"14.5\" cy=\"9\" r=\"1.2\" fill=\"currentColor\" stroke=\"none\"/></svg>";

// Handlers. All state travels in the request; the server keeps nothing.

/// The profile form: answers with a toast (z.js appends it out of band; the form is not swapped).
fn saveProfile(c: *zw.Ctx) !void {
    const name = std.mem.trim(u8, c.form("name") orelse "", " ");
    if (name.len == 0) return c.page(ui.toast(.{ .text = "Enter a display name first", .kind = .@"error" }));
    if (name.len > 60) return c.page(ui.toast(.{ .text = "That name is too long", .kind = .warning }));
    try c.page(ui.toast(.{ .text = try std.fmt.allocPrint(c.arena, "Saved as {s}", .{name}), .kind = .success }));
}

/// Start or stop the fake update check (`?run=1` or `?run=0`); answers with the whole row.
fn syncStep(c: *zw.Ctx) !void {
    try c.page(SyncRow{ .running = std.mem.eql(u8, c.query("run") orelse "0", "1") });
}

/// Set the cart count (`?n=`); answers with the whole row, so both buttons and the badge stay in step.
fn cartStep(c: *zw.Ctx) !void {
    const n = std.fmt.parseInt(u32, c.query("n") orelse "0", 10) catch 0;
    try c.page(CartRow{ .n = @min(n, 99) });
}

/// The toast a toolbar button asks for (`?k=reply|archive|trash`).
fn toolbarToast(c: *zw.Ctx) !void {
    const k = c.query("k") orelse "";
    if (std.mem.eql(u8, k, "reply")) return c.page(ui.toast(.{ .text = "Draft saved to Drafts" }));
    // The action closes the toast through the empty 200 that DELETE /demo/todo answers.
    if (std.mem.eql(u8, k, "trash")) return c.page(ui.toast(.{
        .text = "Message moved to Trash",
        .action = "Undo",
        .z = .{ .delete = "/demo/todo", .target = "closest .zw-toast", .swap = .delete },
        .sticky = true,
    }));
    try c.page(ui.toast(.{ .text = "Message archived", .kind = .success }));
}

/// "Check for Updates" turns into a busy button next to a Stop button, and back.
const SyncRow = struct {
    running: bool,

    pub fn render(self: SyncRow, w: *Writer) Writer.Error!void {
        try zw.view("<div class=\"demo-button-set\" id=\"demo-button-sync\">{#if running}{busy}{stop}{:else}{go}{/if}</div>", .{
            .running = self.running,
            .busy = ui.button(.{ .label = "Checking…", .variant = .primary, .loading = true }),
            .stop = ui.button(.{ .label = "Stop", .variant = .plain, .z = .{ .post = "/demo/button/sync?run=0", .target = "#demo-button-sync", .swap = .outer } }),
            .go = ui.button(.{ .label = "Check for Updates", .icon = refresh, .z = .{ .post = "/demo/button/sync?run=1", .target = "#demo-button-sync", .swap = .outer } }),
        }).render(w);
    }
};

/// The count lives in the URL of the next click: Add posts `n + 1`, Clear posts `0`.
const CartRow = struct {
    n: u32,

    pub fn render(self: CartRow, w: *Writer) Writer.Error!void {
        var buf: [48]u8 = undefined;
        var url: Writer = .fixed(&buf);
        try url.print("/demo/button/cart?n={d}", .{self.n + 1});
        try zw.view("<div class=\"demo-button-set\" id=\"demo-button-cart\">{add}{clear}<span class=\"demo-button-count\">In cart {count}</span></div>", .{
            .add = ui.button(.{ .label = "Add to Cart", .variant = .primary, .icon = cart, .disabled = self.n >= 99, .z = .{ .post = url.buffered(), .target = "#demo-button-cart", .swap = .outer } }),
            .clear = ui.button(.{ .label = "Clear", .variant = .plain, .disabled = self.n == 0, .z = .{ .post = "/demo/button/cart?n=0", .target = "#demo-button-cart", .swap = .outer } }),
            .count = ui.badge(.{ .count = self.n, .tone = .accent, .solid = true }),
        }).render(w);
    }
};

const FileRow = zw.View("<li><span class=\"zw-grow\">{name}</span>{del}</li>", struct { name: []const u8, del: ui.Button });

fn fileRow(name: []const u8) FileRow {
    return .{ .data = .{ .name = name, .del = ui.button(.{
        .label = "Delete",
        .variant = .destructive,
        .z = .{ .delete = "/demo/todo", .target = "closest li", .swap = .delete, .confirm = "Delete this file?" },
    }) } };
}

// Demos.

/// A Settings pane: secondary link button, destructive button with a confirmation, primary submit.
fn hero(w: *Writer) Writer.Error!void {
    try zw.view("<form{z}>{card}</form>", .{
        .z = ui.Z{ .post = "/demo/button/save", .swap = .none, .keep = true },
        .card = ui.card(.{
            .title = "Profile",
            .subtitle = "Shown in Mail and Messages",
            .body = zw.view("<div class=\"zw-stack\">{name}<div>{photo}</div></div>", .{
                .name = ui.field(.{ .name = "name", .label = "Display name", .value = "Ada Lovelace", .help = "Clear the field and save to see an error." }),
                .photo = ui.button(.{ .label = "Choose Photo…", .href = "/components/avatar", .size = .small }),
            }),
            .footer = zw.view("{del}<span class=\"zw-grow\"></span>{save}", .{
                .del = ui.button(.{
                    .label = "Delete Account…",
                    .variant = .destructive,
                    .z = .{ .post = "/demo", .swap = .none, .confirm = "Delete your account? This can't be undone." },
                }),
                .save = ui.button(.{ .label = "Save Changes", .variant = .primary, .type = .submit }),
            }),
        }),
    }).render(w);
}

fn variants(w: *Writer) Writer.Error!void {
    try zw.view(
        \\<div class="demo-button-grid">
        \\<code>variant</code><div class="demo-button-set">{v1}{v2}{v3}{v4}</div>
        \\<code>size</code><div class="demo-button-set">{s1}{s2}{s3}</div>
        \\<code>variant + size</code><div class="demo-button-set">{p1}{p2}{p3}</div>
        \\</div>
    , .{
        .v1 = ui.button(.{ .label = "Primary", .variant = .primary }),
        .v2 = ui.button(.{ .label = "Secondary" }),
        .v3 = ui.button(.{ .label = "Plain", .variant = .plain }),
        .v4 = ui.button(.{ .label = "Destructive", .variant = .destructive }),
        .s1 = ui.button(.{ .label = "Small", .size = .small }),
        .s2 = ui.button(.{ .label = "Regular", .size = .regular }),
        .s3 = ui.button(.{ .label = "Large", .size = .large }),
        .p1 = ui.button(.{ .label = "Revert", .variant = .plain, .size = .small }),
        .p2 = ui.button(.{ .label = "Export", .size = .small }),
        .p3 = ui.button(.{ .label = "Get Started", .variant = .primary, .size = .large }),
    }).render(w);
}

fn content(w: *Writer) Writer.Error!void {
    try zw.view(
        \\<div class="demo-button-grid">
        \\<code>icon</code><div class="demo-button-set">{i1}{i2}</div>
        \\<code>icon_end</code><div class="demo-button-set">{e1}{e2}</div>
        \\<code>icon_only</code><div class="demo-button-set">{o1}{o2}{o3}</div>
        \\<code>aria</code><div class="demo-button-set">{a1}{a2}</div>
        \\<code>href</code><div class="demo-button-set">{h1}{h2}</div>
        \\<code>full</code><div>{f1}</div>
        \\</div>
    , .{
        .i1 = ui.button(.{ .label = "New Item", .icon = plus }),
        .i2 = ui.button(.{ .label = "Download", .icon = download, .variant = .primary }),
        .e1 = ui.button(.{ .label = "Next", .icon = chevron, .icon_end = true, .variant = .primary }),
        .e2 = ui.button(.{ .label = "Show Details", .icon = chevron, .icon_end = true, .variant = .plain }),
        .o1 = ui.button(.{ .label = "Add", .icon = plus, .icon_only = true, .variant = .primary }),
        .o2 = ui.button(.{ .label = "Refresh", .icon = refresh, .icon_only = true }),
        .o3 = ui.button(.{ .label = "Delete", .icon = trash, .icon_only = true, .variant = .destructive, .size = .small }),
        .a1 = ui.button(.{ .label = "−", .aria = "Zoom out" }),
        .a2 = ui.button(.{ .label = "+", .aria = "Zoom in" }),
        .h1 = ui.button(.{ .label = "Read the Docs", .href = "/components/layout", .variant = .plain, .icon = chevron, .icon_end = true }),
        .h2 = ui.button(.{ .label = "Archived Page", .href = "/components/layout", .disabled = true }),
        .f1 = ui.button(.{ .label = "Continue", .variant = .primary, .full = true }),
    }).render(w);
}

fn states(w: *Writer) Writer.Error!void {
    try zw.view(
        \\<div class="demo-button-grid">
        \\<code>disabled</code><div class="demo-button-set">{d1}{d2}{d3}{d4}</div>
        \\<code>loading</code><div class="demo-button-set">{l1}{l2}{l3}</div>
        \\<code>link, loading</code><div class="demo-button-set">{k1}</div>
        \\<code>live</code>{sync}
        \\</div>
    , .{
        .d1 = ui.button(.{ .label = "Save", .variant = .primary, .disabled = true }),
        .d2 = ui.button(.{ .label = "Cancel", .disabled = true }),
        .d3 = ui.button(.{ .label = "Learn More", .variant = .plain, .disabled = true }),
        .d4 = ui.button(.{ .label = "Delete", .variant = .destructive, .disabled = true }),
        .l1 = ui.button(.{ .label = "Saving…", .variant = .primary, .loading = true }),
        .l2 = ui.button(.{ .label = "Exporting…", .loading = true, .icon = download }),
        .l3 = ui.button(.{ .label = "Syncing…", .variant = .plain, .loading = true }),
        .k1 = ui.button(.{ .label = "Opening…", .href = "/components/layout", .loading = true }),
        .sync = SyncRow{ .running = false },
    }).render(w);
}

fn actions(w: *Writer) Writer.Error!void {
    const files = [_][]const u8{ "Quarterly Report.pdf", "Budget.numbers", "Meeting Notes.txt" };
    try zw.view(
        \\<div class="demo-button-grid">
        \\<code>z.post</code>{cart}
        \\<code>z.delete + confirm</code>{files}
        \\</div>
    , .{
        .cart = CartRow{ .n = 0 },
        .files = ui.list(.{ .id = "demo-button-files", .empty = "No files left.", .body = zw.each(&files, fileRow) }),
    }).render(w);
}

fn toolbar(w: *Writer) Writer.Error!void {
    try ui.card(.{
        .title = "Inbox",
        .subtitle = "3 unread",
        .body = zw.view(
            \\<div class="demo-button-set demo-button-tools">{new}<span class="zw-grow"></span>{reply}{archive}{trash}{more}{menu}</div>
            \\<div class="demo-button-msg"><strong>Ada Lovelace</strong><p>Notes on the Analytical Engine</p></div>
        , .{
            .new = ui.button(.{ .label = "Compose", .icon = compose, .variant = .primary, .z = d.save }),
            .reply = ui.tooltip(.{
                .id = "demo-button-tip-reply",
                .text = "Reply",
                .shortcut = "⌘R",
                .side = .below,
                .body = ui.button(.{
                    .label = "Reply",
                    .icon = reply,
                    .icon_only = true,
                    .variant = .plain,
                    .describedby = "demo-button-tip-reply",
                    .z = .{ .post = "/demo/button/toast?k=reply", .swap = .none },
                }),
            }),
            .archive = ui.tooltip(.{
                .id = "demo-button-tip-archive",
                .text = "Archive",
                .shortcut = "⌃⌘A",
                .side = .below,
                .body = ui.button(.{
                    .label = "Archive",
                    .icon = archive,
                    .icon_only = true,
                    .variant = .plain,
                    .describedby = "demo-button-tip-archive",
                    .z = .{ .post = "/demo/button/toast?k=archive", .swap = .none },
                }),
            }),
            .trash = ui.tooltip(.{
                .id = "demo-button-tip-trash",
                .text = "Move to Trash",
                .shortcut = "⌘⌫",
                .side = .below,
                .body = ui.button(.{
                    .label = "Move to Trash",
                    .icon = trash,
                    .icon_only = true,
                    .variant = .destructive,
                    .describedby = "demo-button-tip-trash",
                    .z = .{ .post = "/demo/button/toast?k=trash", .swap = .none },
                }),
            }),
            .more = ui.button(.{ .label = "More", .icon = more, .icon_only = true, .variant = .plain, .opens = "demo-button-more" }),
            .menu = ui.menu(.{ .id = "demo-button-more", .label = "More", .alignment = .end, .items = &.{
                .{ .label = "Mark as Unread", .shortcut = "⇧⌘U", .z = d.save },
                .{ .label = "Mute Thread", .z = d.save },
                .{ .label = "Move to Junk", .destructive = true, .separated = true, .z = d.save },
            } }),
        }),
    }).render(w);
}
