//! Live demos for docs/pages/components/kbd.md (```demo kbd``` fences).
const std = @import("std");
const Writer = std.Io.Writer;
const zw = @import("zigworks");
const ui = zw.ui;
const d = @import("demo.zig");

/// Fence name, block layout (stacked) or inline (wrapping row), render function.
pub const demos = [_]d.Demo{
    .{ "kbd", true, hero },
    .{ "kbd-variants", true, variants },
    .{ "kbd-keys", true, keys },
    .{ "kbd-platform", true, platform },
    .{ "kbd-find", true, find },
    .{ "kbd-commands", true, commands },
};
/// Extra CSS for these demos (scope it under a demo-specific class).
pub const css =
    \\.demo-kbd-word{display:block;font:var(--callout);color:var(--secondary)}
    \\.demo-kbd-head{min-height:32px;font:var(--callout);color:var(--secondary)}
    \\.demo-kbd-mac,.demo-kbd-pc{flex:none;display:flex}
    \\.demo-kbd-mac{width:64px}
    \\.demo-kbd-pc{width:88px}
    \\.demo-kbd-find{min-height:300px;
    \\& .zw-results{left:0;right:auto;width:100%}
    \\& .demo-kbd-hit{display:flex;align-items:center;gap:12px}
    \\& .demo-kbd-hint{margin-top:10px;font:var(--callout);color:var(--secondary)}}
    \\
;
/// Server routes these demos need, e.g. `.{ "POST /demo/kbd/x", handler }`.
pub const routes = .{
    .{ "GET /demo/kbd/platform", platformRows },
    .{ "GET /demo/kbd/find", findHits },
    .{ "POST /demo/kbd/run", run },
};

// A list row: a label and its shortcut. `Rows` renders a set of them; `pc` and `joiner` pass through to ui.kbd.
const row_src = "<li><span class=\"zw-grow\">{label}</span>{keys}</li>";

const Row = struct { label: []const u8, keys: []const u8, pc_keys: []const u8 = "" };

const Rows = struct {
    rows: []const Row,
    pc: bool = false,
    joiner: []const u8 = "",
    pub fn render(self: Rows, w: *Writer) Writer.Error!void {
        for (self.rows) |r| try zw.view(row_src, .{
            .label = r.label,
            .keys = ui.kbd(.{
                .keys = if (self.pc and r.pc_keys.len > 0) r.pc_keys else r.keys,
                .platform = if (self.pc) .pc else .mac,
                .joiner = self.joiner,
            }),
        }).render(w);
    }
};

// Modifiers in Apple's order: Control, Option, Shift, Command.
const notes = [_]Row{
    .{ .label = "New Note", .keys = "cmd n" },
    .{ .label = "New Folder", .keys = "shift cmd n" },
    .{ .label = "Find in Note", .keys = "cmd f" },
    .{ .label = "Bold", .keys = "cmd b" },
    .{ .label = "Lock Note", .keys = "opt cmd l" },
    .{ .label = "Move to Trash", .keys = "cmd backspace" },
};

fn hero(w: *Writer) Writer.Error!void {
    try ui.card(.{
        .flush = true,
        .title = "Keyboard Shortcuts",
        .subtitle = "Notes",
        .footer = "The same shortcuts appear in the menu bar.",
        .body = ui.list(.{ .id = "demo-kbd-notes", .separators = .full, .body = Rows{ .rows = &notes } }),
    }).render(w);
}

fn variants(w: *Writer) Writer.Error!void {
    try ui.card(.{ .body = zw.view("{a}{b}{c}{e}{f}{g}{h}", .{
        .a = ui.setting(.{ .label = "Small", .description = "size = .small", .control = ui.kbd(.{ .keys = "cmd c", .size = .small }) }),
        .b = ui.setting(.{ .label = "Regular", .description = "size = .regular (the default)", .control = ui.kbd(.{ .keys = "cmd c" }) }),
        .c = ui.setting(.{ .label = "Large", .description = "size = .large", .control = ui.kbd(.{ .keys = "cmd c", .size = .large }) }),
        .e = ui.setting(.{ .label = "Words", .description = "keys = \"ctrl opt cmd k\"", .control = ui.kbd(.{ .keys = "ctrl opt cmd k" }) }),
        .f = ui.setting(.{ .label = "Windows and Linux", .description = "platform = .pc", .control = ui.kbd(.{ .keys = "cmd shift k", .platform = .pc }) }),
        .g = ui.setting(.{ .label = "Sequence", .description = "joiner = \"then\"", .control = ui.kbd(.{ .keys = "g i", .joiner = "then" }) }),
        .h = ui.setting(.{ .label = "Menu style", .description = "plain = true", .control = ui.kbd(.{ .keys = "opt cmd esc", .plain = true }) }),
    }) }).render(w);
}

const Key = struct { name: []const u8, word: []const u8 };

const key_list = [_]Key{
    .{ .name = "Command", .word = "cmd" },
    .{ .name = "Option", .word = "opt" },
    .{ .name = "Shift", .word = "shift" },
    .{ .name = "Control", .word = "ctrl" },
    .{ .name = "Return", .word = "enter" },
    .{ .name = "Escape", .word = "esc" },
    .{ .name = "Delete", .word = "backspace" },
    .{ .name = "Forward Delete", .word = "del" },
    .{ .name = "Space", .word = "space" },
    .{ .name = "Caps Lock", .word = "caps" },
    .{ .name = "Left Arrow", .word = "left" },
    .{ .name = "Page Up", .word = "pageup" },
    .{ .name = "Anything else", .word = "f5" },
};

const KeyRow = zw.View(
    "<li><span class=\"zw-grow\">{name}<span class=\"demo-kbd-word\">{word}</span></span>" ++
        "<span class=\"demo-kbd-mac\">{mac}</span><span class=\"demo-kbd-pc\">{pc}</span></li>",
    struct { name: []const u8, word: []const u8, mac: ui.Kbd, pc: ui.Kbd },
);

fn keyRow(k: Key) KeyRow {
    return .{ .data = .{
        .name = k.name,
        .word = k.word,
        .mac = ui.kbd(.{ .keys = k.word }),
        .pc = ui.kbd(.{ .keys = k.word, .platform = .pc }),
    } };
}

fn keys(w: *Writer) Writer.Error!void {
    try ui.list(.{
        .id = "demo-kbd-keys",
        .header = "Words in, keycaps out",
        .footer = "Left: the word you write. Then the Mac keycap and the PC keycap.",
        .separators = .full,
        .body = zw.view("<li class=\"demo-kbd-head\"><span class=\"zw-grow\">keys =</span><span class=\"demo-kbd-mac\">Mac</span><span class=\"demo-kbd-pc\">PC</span></li>{rows}", .{
            .rows = zw.each(&key_list, keyRow),
        }),
    }).render(w);
}

// Redo is Shift+Cmd+Z on a Mac and Ctrl+Y on Windows, so it carries its own PC keys. Other rows (Cmd+Z) map to Ctrl+Z.
const edit_menu = [_]Row{
    .{ .label = "Undo", .keys = "cmd z" },
    .{ .label = "Redo", .keys = "shift cmd z", .pc_keys = "cmd y" },
    .{ .label = "Cut", .keys = "cmd x" },
    .{ .label = "Copy", .keys = "cmd c" },
    .{ .label = "Paste", .keys = "cmd v" },
    .{ .label = "Select All", .keys = "cmd a" },
};

fn platform(w: *Writer) Writer.Error!void {
    try ui.card(.{
        .flush = true,
        .title = "Edit",
        .accessory = ui.segmented(.{
            .name = "p",
            .label = "Platform",
            .size = .small,
            .z = .{ .get = "/demo/kbd/platform", .target = "#demo-kbd-edit", .swap = .inner },
            .options = &.{ .{ .value = "mac", .label = "Mac", .selected = true }, .{ .value = "pc", .label = "Windows" } },
        }),
        .body = ui.list(.{ .id = "demo-kbd-edit", .separators = .full, .body = Rows{ .rows = &edit_menu } }),
    }).render(w);
}

/// GET /demo/kbd/platform?p=mac|pc: the Edit menu rows for one platform.
fn platformRows(c: *zw.Ctx) !void {
    const pc = std.mem.eql(u8, c.query("p") orelse "", "pc");
    try c.page(Rows{ .rows = &edit_menu, .pc = pc });
}

const Command = struct { id: []const u8, label: []const u8, group: []const u8, keys: []const u8, done: []const u8 };

const command_list = [_]Command{
    .{ .id = "new-note", .label = "New Note", .group = "File", .keys = "cmd n", .done = "Note created" },
    .{ .id = "new-folder", .label = "New Folder", .group = "File", .keys = "shift cmd n", .done = "Folder created" },
    .{ .id = "find", .label = "Find in Note", .group = "Edit", .keys = "cmd f", .done = "Searching this note" },
    .{ .id = "lock", .label = "Lock Note", .group = "File", .keys = "opt cmd l", .done = "Note locked" },
    .{ .id = "sidebar", .label = "Hide Sidebar", .group = "View", .keys = "ctrl cmd s", .done = "Sidebar hidden" },
    .{ .id = "trash", .label = "Move to Trash", .group = "File", .keys = "cmd backspace", .done = "Moved to Trash" },
};

fn find(w: *Writer) Writer.Error!void {
    try zw.view("<div class=\"demo-kbd-find\" id=\"demo-kbd-find\">{search}<p class=\"demo-kbd-hint\">Press ⌘K (Ctrl+K) to focus the field, then try “note”, “trash” or “view”.</p></div>", .{
        .search = ui.search(.{
            .action = "/demo/kbd/find",
            .id = "demo-kbd-hits",
            .label = "Search commands",
            .placeholder = "Search commands",
            .shortcut = "k",
        }),
    }).render(w);
}

const Hits = struct {
    q: []const u8,
    pub fn render(self: Hits, w: *Writer) Writer.Error!void {
        var n: usize = 0;
        for (command_list) |cmd| {
            if (self.q.len > 0 and std.ascii.findIgnoreCase(cmd.label, self.q) == null and std.ascii.findIgnoreCase(cmd.group, self.q) == null) continue;
            n += 1;
            try zw.view("<a class=\"demo-kbd-hit\" href=\"#demo-kbd-find\"><span class=\"zw-grow\">{label}<small>{group}</small></span>{keys}</a>", .{
                .label = cmd.label,
                .group = cmd.group,
                .keys = ui.kbd(.{ .keys = cmd.keys, .size = .small }),
            }).render(w);
        }
        if (n == 0) try zw.view("<p>No commands match “{q}”.</p>", .{ .q = self.q }).render(w);
    }
};

/// GET /demo/kbd/find?q=...: the commands whose name or menu contains the query.
fn findHits(c: *zw.Ctx) !void {
    try c.page(Hits{ .q = std.mem.trim(u8, c.query("q") orelse "", " ") });
}

const CommandRows = struct {
    pub fn render(_: CommandRows, w: *Writer) Writer.Error!void {
        inline for (command_list) |cmd| try zw.view("<li><span class=\"zw-grow\">{label}</span>{keys}{run}</li>", .{
            .label = cmd.label,
            .keys = ui.kbd(.{ .keys = cmd.keys }),
            .run = ui.button(.{
                .label = "Run",
                .aria = "Run " ++ cmd.label,
                .size = .small,
                .variant = .plain,
                .z = .{ .post = "/demo/kbd/run?c=" ++ cmd.id, .swap = .none },
            }),
        }).render(w);
    }
};

const sequences = [_]Row{
    .{ .label = "Go to Inbox", .keys = "g i" },
    .{ .label = "Go to Drafts", .keys = "g d" },
    .{ .label = "Compose", .keys = "c" },
    .{ .label = "Search", .keys = "/" },
};

fn commands(w: *Writer) Writer.Error!void {
    try ui.card(.{
        .flush = true,
        .title = "Commands",
        .subtitle = "Notes",
        .accessory = zw.view("{open}{sheet}", .{
            .open = ui.button(.{ .label = "Sequences…", .variant = .plain, .opens = "demo-kbd-sheet" }),
            .sheet = ui.sheet(.{
                .id = "demo-kbd-sheet",
                .title = "Mail Sequences",
                .description = "Press the keys one after the other.",
                .size = .small,
                .close = true,
                .body = ui.list(.{ .id = "demo-kbd-seq", .separators = .full, .body = Rows{ .rows = &sequences, .joiner = "then" } }),
            }),
        }),
        .footer = "Run shows a toast. The shortcuts are drawn here; your page's script registers them.",
        .body = ui.list(.{ .id = "demo-kbd-commands", .separators = .full, .body = CommandRows{} }),
    }).render(w);
}

/// POST /demo/kbd/run?c=<command id>: a toast that says what the command did.
fn run(c: *zw.Ctx) !void {
    const id = c.query("c") orelse "";
    for (command_list) |cmd| {
        if (std.mem.eql(u8, cmd.id, id)) return c.page(ui.toast(.{ .text = cmd.done, .kind = .success }));
    }
    try c.send(.not_found, "text/plain", "Unknown command");
}
