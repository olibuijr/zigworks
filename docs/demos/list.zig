//! Live demos for docs/pages/components/list.md (```demo list``` fences).
const std = @import("std");
const Writer = std.Io.Writer;
const zw = @import("zigworks");
const ui = zw.ui;
const d = @import("demo.zig");

/// Fence name, block layout (stacked) or inline (wrapping row), render function.
pub const demos = [_]d.Demo{
    .{ "list", true, hero },
    .{ "list-variants", true, variants },
    .{ "list-states", true, states },
    .{ "list-select", true, select },
    .{ "list-add", true, add },
    .{ "list-share", true, share },
};
/// Extra CSS for these demos (scope it under a demo-specific class).
pub const css =
    \\.demo-list-grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(min(100%,250px),1fr));gap:20px 16px;align-items:start;width:100%}
    \\.demo-list-grid>*{min-width:0}
    \\.demo-list-text{display:flex;flex-direction:column;gap:1px;min-width:0;flex:1;}
    \\.demo-list-text>*{overflow:hidden;text-overflow:ellipsis;white-space:nowrap}
    \\.demo-list-title{font-weight:500}
    \\.demo-list-unread{font-weight:700}
    \\.demo-list-sub{font:var(--callout);color:var(--secondary)}
    \\.zw-list>li[aria-selected=true] .demo-list-sub{color:inherit;opacity:.8}
    \\.demo-list-grid .zw-list--nav>li[aria-selected=true]>a::after{border-color:currentColor}
    \\.demo-list-grid .zw-list>li>.zw-skeleton{flex:1}
    \\.demo-list-note{display:flex;flex-direction:column;gap:6px}
    \\.demo-list-note>*{margin:0}
    \\.demo-list-note>h3{font:var(--headline)}
    \\.demo-list-share .zw-toggle{flex:1}
    \\
;
/// Server routes these demos need, e.g. `.{ "POST /demo/list/x", handler }`.
pub const routes = .{
    .{ "GET /demo/list/note", noteGet },
    .{ "POST /demo/list/add", bagAdd },
    .{ "DELETE /demo/list/item", bagRemove },
};

// Hero: a Mail-style inbox.

const Mail = struct { from: []const u8, subject: []const u8, time: []const u8, unread: bool = false };

const inbox = [_]Mail{
    .{ .from = "Ada Lovelace", .subject = "Notes on the Analytical Engine", .time = "9:41", .unread = true },
    .{ .from = "Grace Hopper", .subject = "Compiler status for Friday", .time = "8:15", .unread = true },
    .{ .from = "Alan Turing", .subject = "Re: A question about halting", .time = "Yesterday" },
    .{ .from = "Katherine Johnson", .subject = "Trajectory check", .time = "Tuesday" },
    .{ .from = "Margaret Hamilton", .subject = "Flight software review", .time = "Monday" },
};

const MailRow = zw.View(
    \\<li>{av}<div class="demo-list-text"><span class="demo-list-title{#if m.unread} demo-list-unread{/if}">{m.from}</span><span class="demo-list-sub">{m.subject}</span></div><span class="demo-list-sub">{m.time}</span>{dot}{del}</li>
, struct { m: Mail, av: ui.Avatar, dot: ?ui.Badge, del: ui.Button });

fn mailRow(m: Mail) MailRow {
    return .{ .data = .{
        .m = m,
        .av = ui.avatar(.{ .name = m.from }),
        .dot = if (m.unread) ui.badge(.{ .dot = true, .text = "Unread", .tone = .accent }) else null,
        // An empty 200 lets z.js remove the row (see DELETE /demo/todo in main.zig).
        .del = ui.button(.{ .label = "Delete", .variant = .destructive, .size = .small, .z = .{ .delete = "/demo/todo", .target = "closest li", .swap = .delete } }),
    } };
}

fn hero(w: *Writer) Writer.Error!void {
    try ui.list(.{
        .id = "demo-list-inbox",
        .header = "Inbox",
        .footer = "Delete every message to see the empty state.",
        .empty = "Inbox Zero. Nothing to read.",
        .reveal = true,
        .body = zw.each(&inbox, mailRow),
    }).render(w);
}

// Variants: separators, nav and the flat surface.

const PersonRow = zw.View("<li>{av}<span class=\"zw-grow\">{name}</span></li>", struct { av: ui.Avatar, name: []const u8 });

fn person(name: []const u8) PersonRow {
    return .{ .data = .{ .av = ui.avatar(.{ .name = name, .size = 28 }), .name = name } };
}

const people = [_][]const u8{ "Ada Lovelace", "Grace Hopper", "Alan Turing" };

fn variants(w: *Writer) Writer.Error!void {
    try zw.view("<div class=\"demo-list-grid\">{a}{b}{c}{e}{f}</div>", .{
        .a = ui.list(.{
            .id = "demo-list-sep-inset",
            .header = "separators: .inset",
            .footer = "Lines start after the avatar.",
            .body = zw.each(&people, person),
        }),
        .b = ui.list(.{
            .id = "demo-list-sep-full",
            .header = "separators: .full",
            .separators = .full,
            .body = zw.view(
                \\<li><span class="zw-grow">Quarterly report.pdf</span><span class="demo-list-sub">2.4 MB</span></li><li><span class="zw-grow">Budget.numbers</span><span class="demo-list-sub">380 KB</span></li><li><span class="zw-grow">Team photo.heic</span><span class="demo-list-sub">5.1 MB</span></li>
            , .{}),
        }),
        .c = ui.list(.{
            .id = "demo-list-sep-none",
            .header = "separators: .none",
            .body = zw.view("<li><span class=\"zw-grow\">New Note</span>{a}</li><li><span class=\"zw-grow\">Find</span>{b}</li><li><span class=\"zw-grow\">Pin Note</span>{c}</li>", .{
                .a = ui.kbd(.{ .keys = "⌘ N" }),
                .b = ui.kbd(.{ .keys = "⌘ F" }),
                .c = ui.kbd(.{ .keys = "⌘ ⇧ P" }),
            }),
        }),
        .e = ui.card(.{
            .title = "Storage",
            .subtitle = "inset: false, flat inside a card",
            .body = ui.list(.{
                .id = "demo-list-flat",
                .inset = false,
                .separators = .full,
                .body = zw.view(
                    \\<li><span class="zw-grow">Apps</span><span class="demo-list-sub">42 GB</span></li><li><span class="zw-grow">Documents</span><span class="demo-list-sub">18 GB</span></li><li><span class="zw-grow">System</span><span class="demo-list-sub">26 GB</span></li>
                , .{}),
            }),
        }),
        .f = ui.list(.{
            .id = "demo-list-nav",
            .header = "nav: true",
            .footer = "Each row is a link with a chevron.",
            .nav = true,
            .body = zw.view(
                \\<li><a href="#demo-list-nav"><span class="zw-grow">Wi-Fi</span><span class="demo-list-sub">Home</span></a></li><li><a href="#demo-list-nav"><span class="zw-grow">Bluetooth</span><span class="demo-list-sub">On</span></a></li><li><a href="#demo-list-nav"><span class="zw-grow">VPN</span><span class="demo-list-sub">Not connected</span></a></li>
            , .{}),
        }),
    }).render(w);
}

// States: selected, disabled, empty, loading.

fn states(w: *Writer) Writer.Error!void {
    try zw.view("<div class=\"demo-list-grid\">{a}{b}{c}{e}</div>", .{
        .a = ui.list(.{
            .id = "demo-list-selected",
            .header = "Selected row",
            .footer = "<li aria-selected=\"true\">",
            .body = zw.view(
                \\<li><span class="zw-grow">Inbox</span><span class="demo-list-sub">12</span></li><li aria-selected="true"><span class="zw-grow">Drafts</span><span class="demo-list-sub">2</span></li><li><span class="zw-grow">Sent</span></li>
            , .{}),
        }),
        .b = ui.list(.{
            .id = "demo-list-disabled",
            .header = "Disabled row",
            .footer = "<li aria-disabled=\"true\">",
            .body = zw.view(
                \\<li><span class="zw-grow">Export as PDF</span></li><li><span class="zw-grow">Export as Markdown</span></li><li aria-disabled="true"><div class="demo-list-text"><span>Export as Word</span><span class="demo-list-sub">Needs a connection</span></div></li>
            , .{}),
        }),
        .c = ui.list(.{
            .id = "demo-list-empty",
            .header = "Empty",
            .footer = "empty: \"No downloads\"",
            .empty = "No downloads",
            .body = "",
        }),
        .e = ui.list(.{
            .id = "demo-list-loading",
            .header = "Loading",
            .footer = "A skeleton in each row.",
            .body = zw.view("<li>{a}</li><li>{b}</li>", .{
                .a = ui.skeleton(.{ .shape = .media, .lines = 2, .size = 32, .label = "Loading messages" }),
                .b = ui.skeleton(.{ .shape = .media, .lines = 2, .size = 32, .label = "Loading more messages" }),
            }),
        }),
    }).render(w);
}

// Selecting: a nav list whose rows load a note into the pane next to it. Every row link is
// a z-get; the answer is the new rows (selection moves) plus the pane as an out-of-band swap.

const Note = struct { title: []const u8, when: []const u8, body: []const u8, z: ui.Z };

fn pick(comptime n: u8) ui.Z {
    return .{ .get = std.fmt.comptimePrint("/demo/list/note?n={d}", .{n}), .target = "#demo-list-notes", .swap = .inner };
}

const notes = [_]Note{
    .{ .title = "Packing list", .when = "Today", .body = "Passport, charger, sunscreen, and the paperback you keep not finishing.", .z = pick(0) },
    .{ .title = "Release plan", .when = "Yesterday", .body = "Freeze on Thursday, tag on Friday morning, announce after lunch.", .z = pick(1) },
    .{ .title = "Book ideas", .when = "Monday", .body = "A field guide to the bugs that only happen on Fridays.", .z = pick(2) },
};

const NoteRow = struct { note: Note, selected: bool };

const NoteRows = zw.View(
    \\{#each rows as r}<li{#if r.selected} aria-selected="true"{/if}><a href="#demo-list-notes"{r.note.z}><div class="demo-list-text"><span class="demo-list-title">{r.note.title}</span><span class="demo-list-sub">{r.note.body}</span></div><span class="demo-list-sub">{r.note.when}</span></a></li>{/each}
, struct { rows: [notes.len]NoteRow });

fn noteRows(sel: usize) NoteRows {
    var rows: [notes.len]NoteRow = undefined;
    for (&rows, notes, 0..) |*r, n, i| r.* = .{ .note = n, .selected = i == sel };
    return .{ .data = .{ .rows = rows } };
}

const NotePane = zw.View(
    \\<div id="demo-list-note" class="zw-card demo-list-note" z-oob aria-live="polite"><h3>{n.title}</h3><p class="demo-list-sub">{n.when}</p><p>{n.body}</p></div>
, struct { n: Note });

fn notePane(sel: usize) NotePane {
    return .{ .data = .{ .n = notes[sel] } };
}

fn select(w: *Writer) Writer.Error!void {
    try zw.view("<div class=\"demo-list-grid\">{l}{p}</div>", .{
        .l = ui.list(.{ .id = "demo-list-notes", .header = "Notes", .nav = true, .body = noteRows(0) }),
        .p = notePane(0),
    }).render(w);
}

fn noteGet(c: *zw.Ctx) !void {
    const n = std.fmt.parseInt(usize, c.query("n") orelse "0", 10) catch 0;
    const sel = @min(n, notes.len - 1);
    try c.page(zw.view("{rows}{pane}", .{ .rows = noteRows(sel), .pane = notePane(sel) }));
}

// Adding and removing rows, with a toast. The page holds the list; the server only renders a row.

const BagRow = zw.View(
    \\<li><span class="zw-grow">{t}</span>{del}</li>
, struct { t: []const u8, del: ui.Button });

fn bagRow(title: []const u8) BagRow {
    return .{ .data = .{
        .t = title,
        .del = ui.button(.{ .label = "Delete", .variant = .destructive, .size = .small, .z = .{ .delete = "/demo/list/item", .target = "closest li", .swap = .delete } }),
    } };
}

fn add(w: *Writer) Writer.Error!void {
    try zw.view("<form class=\"zw-row\"{z}><div class=\"zw-grow\">{f}</div>{b}</form>{l}", .{
        .z = ui.Z{ .post = "/demo/list/add", .target = "#demo-list-bag", .swap = .beforeend },
        .f = ui.field(.{ .name = "item", .label = "New item", .placeholder = "Add an item", .required = true }),
        .b = ui.button(.{ .label = "Add", .variant = .primary, .type = .submit }),
        .l = ui.list(.{
            .id = "demo-list-bag",
            .header = "Packing list",
            .footer = "New rows are appended with swap = .beforeend.",
            .empty = "Nothing to pack. Add an item above.",
            .separators = .full,
            .reveal = true,
            .body = zw.view("{a}{b}", .{ .a = bagRow("Passport"), .b = bagRow("Charger") }),
        }),
    }).render(w);
}

fn bagAdd(c: *zw.Ctx) !void {
    const item = std.mem.trim(u8, c.form("item") orelse "", " ");
    if (item.len == 0 or item.len > 60) return c.send(.no_content, "text/plain", "");
    try c.page(zw.view("{row}{toast}", .{
        .row = bagRow(item),
        .toast = ui.toast(.{ .text = "Added to the packing list", .kind = .success }),
    }));
}

fn bagRemove(c: *zw.Ctx) !void {
    // The toast is out of band; the rest of the answer is empty, so z.js removes the row.
    try c.page(ui.toast(.{ .text = "Removed from the packing list" }));
}

// Composition: a flush card holding a list of people, with avatars, tags and a switch.

const ShareRow = zw.View(
    \\<li>{av}<div class="demo-list-text"><span class="demo-list-title">{name}</span><span class="demo-list-sub">{email}</span></div>{role}</li>
, struct { av: ui.Avatar, name: []const u8, email: []const u8, role: ui.Tag });

fn shareRow(av: ui.Avatar, name: []const u8, email: []const u8, role: ui.Tag) ShareRow {
    return .{ .data = .{ .av = av, .name = name, .email = email, .role = role } };
}

fn share(w: *Writer) Writer.Error!void {
    try zw.view("<div class=\"demo-list-share\">{c}</div>", .{
        .c = ui.card(.{
            .flush = true,
            .title = "Share “Roadmap”",
            .subtitle = "3 people have access",
            .accessory = ui.button(.{ .label = "Invite", .size = .small, .z = d.save }),
            .footer = ui.button(.{ .label = "Done", .variant = .primary, .z = d.save }),
            .body = ui.list(.{
                .id = "demo-list-people",
                .body = zw.view("{a}{b}{c}<li>{t}</li>", .{
                    .a = shareRow(ui.avatar(.{ .name = "Ada Lovelace", .status = .online }), "Ada Lovelace", "ada@example.com", ui.tag(.{ .text = "Owner", .tone = .gray, .size = .small })),
                    .b = shareRow(ui.avatar(.{ .name = "Grace Hopper", .status = .away }), "Grace Hopper", "grace@example.com", ui.tag(.{ .text = "Editor", .size = .small })),
                    .c = shareRow(ui.avatar(.{ .name = "Alan Turing" }), "Alan Turing", "alan@example.com", ui.tag(.{ .text = "Viewer", .tone = .gray, .size = .small })),
                    .t = ui.toggle(.{ .name = "link", .label = "Anyone with the link", .description = "Can view, not edit", .z = d.save }),
                }),
            }),
        }),
    }).render(w);
}
