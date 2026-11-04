//! Keyboard shortcut: keycaps for a shortcut, like menus show them. Keys are separated by spaces
//! and can be Mac symbols or words: `kbd(.{ .keys = "⌘ ⇧ K" })` and `kbd(.{ .keys = "cmd shift k" })`
//! are the same. `platform = .pc` shows Ctrl, Alt and Shift instead of the Mac symbols.
const std = @import("std");
const Writer = std.Io.Writer;
const writeEscaped = @import("../view.zig").writeEscaped;

pub const css =
    \\.zw-kbd{display:inline-flex;align-items:center;gap:3px;vertical-align:1px;white-space:nowrap;font:500 11px/1 var(--font);
    \\& kbd{display:inline-grid;place-items:center;min-width:20px;height:20px;padding:0 5px;border-radius:5px;font:inherit;color:var(--secondary);
    \\background:var(--content);box-shadow:0 0 0 .5px var(--separator),0 1px 0 var(--fill-strong)}}
    \\.zw-kbd__j{color:var(--tertiary)}
    \\.zw-kbd--small{font-size:10px;
    \\& kbd{min-width:16px;height:16px;padding:0 4px;border-radius:4px}}
    \\.zw-kbd--large{font-size:13px;
    \\& kbd{min-width:26px;height:26px;padding:0 7px;border-radius:7px}}
    \\.zw-kbd--plain{gap:1px;color:var(--secondary);vertical-align:baseline;
    \\& kbd{min-width:0;height:auto;padding:0;border-radius:0;color:inherit;background:none;box-shadow:none}
    \\& .zw-kbd__j{padding:0 2px}}
    \\@media (prefers-contrast:more){.zw-kbd kbd{color:var(--label);box-shadow:0 0 0 1px var(--secondary)}.zw-kbd--plain kbd{box-shadow:none}}
    \\
;

pub const Platform = enum { mac, pc };
pub const Size = enum { small, regular, large };

pub const Props = struct {
    /// Space-separated keys: symbols (⌘ ⌥ ⌃ ⇧ ↩ ⎋ ⇥ ⌫ ← ↑ → ↓) or words (cmd, option, shift, ctrl,
    /// enter, esc, tab, backspace, space, up, down, left, right...). Other words are shown as written with
    /// the first letter capitalized (`f5` becomes F5).
    keys: []const u8,
    /// `.pc` swaps Mac symbols for Ctrl, Alt, Shift and so on (⌘ becomes Ctrl), puts the modifiers first in
    /// the order Ctrl, Alt, Shift, and shows Ctrl once when both cmd and ctrl are given.
    platform: Platform = .mac,
    size: Size = .regular,
    /// Text between the keycaps, like "+" or "then" (a sequence). Empty: none, except "+" on `.pc`.
    joiner: []const u8 = "",
    /// Menu style: no keycaps, just the symbols in secondary text.
    plain: bool = false,
};

const Key = struct { aliases: []const []const u8, mac: []const u8, pc: []const u8, name: []const u8, rank: u8 = 3 };

const table = [_]Key{
    .{ .aliases = &.{ "⌘", "cmd", "command", "meta", "super" }, .mac = "⌘", .pc = "Ctrl", .name = "Command", .rank = 0 },
    .{ .aliases = &.{ "⌥", "opt", "option", "alt" }, .mac = "⌥", .pc = "Alt", .name = "Option", .rank = 1 },
    .{ .aliases = &.{ "⇧", "shift" }, .mac = "⇧", .pc = "Shift", .name = "Shift", .rank = 2 },
    .{ .aliases = &.{ "⌃", "ctrl", "control" }, .mac = "⌃", .pc = "Ctrl", .name = "Control", .rank = 0 },
    .{ .aliases = &.{ "↩", "⏎", "return", "enter" }, .mac = "↩", .pc = "Enter", .name = "Return" },
    .{ .aliases = &.{ "⎋", "esc", "escape" }, .mac = "⎋", .pc = "Esc", .name = "Escape" },
    .{ .aliases = &.{ "⇥", "tab" }, .mac = "⇥", .pc = "Tab", .name = "Tab" },
    .{ .aliases = &.{ "⌫", "backspace", "delete" }, .mac = "⌫", .pc = "Backspace", .name = "Delete" },
    .{ .aliases = &.{ "⌦", "del", "fwd-delete" }, .mac = "⌦", .pc = "Del", .name = "Forward Delete" },
    .{ .aliases = &.{ "␣", "space" }, .mac = "Space", .pc = "Space", .name = "Space" },
    .{ .aliases = &.{ "⇪", "caps", "capslock" }, .mac = "⇪", .pc = "Caps Lock", .name = "Caps Lock" },
    .{ .aliases = &.{ "←", "left" }, .mac = "←", .pc = "←", .name = "Left Arrow" },
    .{ .aliases = &.{ "→", "right" }, .mac = "→", .pc = "→", .name = "Right Arrow" },
    .{ .aliases = &.{ "↑", "up" }, .mac = "↑", .pc = "↑", .name = "Up Arrow" },
    .{ .aliases = &.{ "↓", "down" }, .mac = "↓", .pc = "↓", .name = "Down Arrow" },
    .{ .aliases = &.{ "⇞", "pageup", "pgup" }, .mac = "⇞", .pc = "PgUp", .name = "Page Up" },
    .{ .aliases = &.{ "⇟", "pagedown", "pgdn" }, .mac = "⇟", .pc = "PgDn", .name = "Page Down" },
    .{ .aliases = &.{ "↖", "home" }, .mac = "↖", .pc = "Home", .name = "Home" },
    .{ .aliases = &.{ "↘", "end" }, .mac = "↘", .pc = "End", .name = "End" },
};

fn lookup(tok: []const u8) ?*const Key {
    for (&table) |*k| {
        for (k.aliases) |a| if (std.ascii.eqlIgnoreCase(a, tok)) return k;
    }
    return null;
}

/// Writes one key: its keycap text, or (`spoken`) its name for screen readers.
fn writeKey(w: *Writer, tok: []const u8, platform: Platform, spoken: bool) Writer.Error!void {
    if (lookup(tok)) |k| {
        const text = if (platform == .pc) k.pc else if (spoken) k.name else k.mac;
        return writeEscaped(w, text);
    }
    // Unknown words: first letter capitalized ("f5" is F5, "a" is A).
    const first = [1]u8{std.ascii.toUpper(tok[0])};
    try writeEscaped(w, &first);
    try writeEscaped(w, tok[1..]);
}

const max_keys = 16;

/// The keys in display order (at most `max_keys`). On a Mac: as written. On a PC: Ctrl, Alt and Shift
/// first (Ctrl once, even for "cmd ctrl"), then the other keys as written.
fn ordered(keys: []const u8, pc: bool, buf: *[max_keys][]const u8) [][]const u8 {
    var n: usize = 0;
    for (0..(if (pc) 4 else 1)) |pass| {
        var it = std.mem.tokenizeScalar(u8, keys, ' ');
        while (it.next()) |k| {
            if (n == buf.len) return buf[0..n];
            const rank: usize = if (!pc) 0 else if (lookup(k)) |e| e.rank else 3;
            if (rank != pass) continue;
            buf[n] = k;
            n += 1;
            if (pass < 3 and pc) break; // Ctrl, Alt and Shift once each
        }
    }
    return buf[0..n];
}

pub const Kbd = struct {
    p: Props,
    pub fn render(self: Kbd, w: *Writer) Writer.Error!void {
        const p = self.p;
        const joiner = if (p.joiner.len == 0 and p.platform == .pc) "+" else p.joiner;
        try w.writeAll("<span class=\"zw-kbd");
        if (p.size != .regular) try w.print(" zw-kbd--{s}", .{@tagName(p.size)});
        if (p.plain) try w.writeAll(" zw-kbd--plain");
        // One accessible name for the whole chord ("Command Shift K", "G then I"); the keycaps inside are presentational.
        try w.writeAll("\" role=\"img\" aria-label=\"");
        var buf: [max_keys][]const u8 = undefined;
        const keys = ordered(p.keys, p.platform == .pc, &buf);
        for (keys, 0..) |k, n| {
            if (n > 0) {
                try w.writeByte(' ');
                if (p.joiner.len > 0) {
                    try writeEscaped(w, p.joiner);
                    try w.writeByte(' ');
                }
            }
            try writeKey(w, k, p.platform, true);
        }
        try w.writeAll("\">");
        for (keys, 0..) |k, n| {
            if (n > 0 and joiner.len > 0) {
                try w.writeAll("<span class=\"zw-kbd__j\">");
                try writeEscaped(w, joiner);
                try w.writeAll("</span>");
            }
            try w.writeAll("<kbd>");
            try writeKey(w, k, p.platform, false);
            try w.writeAll("</kbd>");
        }
        try w.writeAll("</span>");
    }
};

/// `kbd(.{ .keys = "⌘ ⇧ K" })`, `kbd(.{ .keys = "cmd shift k", .platform = .pc })`.
pub fn kbd(p: Props) Kbd {
    return .{ .p = p };
}

fn expectHtml(expected: []const u8, p: Props) !void {
    var buf: [512]u8 = undefined;
    var w: Writer = .fixed(&buf);
    try kbd(p).render(&w);
    try std.testing.expectEqualStrings(expected, w.buffered());
}

test kbd {
    try expectHtml("<span class=\"zw-kbd\" role=\"img\" aria-label=\"Command Shift K\"><kbd>⌘</kbd><kbd>⇧</kbd><kbd>K</kbd></span>", .{ .keys = "⌘ ⇧ k" });
    try expectHtml("<span class=\"zw-kbd\" role=\"img\" aria-label=\"Command Shift K\"><kbd>⌘</kbd><kbd>⇧</kbd><kbd>K</kbd></span>", .{ .keys = "cmd Shift K" });
    try expectHtml(
        "<span class=\"zw-kbd zw-kbd--small\" role=\"img\" aria-label=\"Ctrl Alt Del\"><kbd>Ctrl</kbd><span class=\"zw-kbd__j\">+</span><kbd>Alt</kbd><span class=\"zw-kbd__j\">+</span><kbd>Del</kbd></span>",
        .{ .keys = "⌘ ⌥ del", .platform = .pc, .size = .small },
    );
    try expectHtml(
        "<span class=\"zw-kbd zw-kbd--plain\" role=\"img\" aria-label=\"G then I\"><kbd>G</kbd><span class=\"zw-kbd__j\">then</span><kbd>I</kbd></span>",
        .{ .keys = "g i", .joiner = "then", .plain = true },
    );
    try expectHtml("<span class=\"zw-kbd\" role=\"img\" aria-label=\"A&lt;b\"><kbd>A&lt;b</kbd></span>", .{ .keys = "a<b" });
    // F-keys and other words get a capital first letter.
    try expectHtml("<span class=\"zw-kbd\" role=\"img\" aria-label=\"Command F5\"><kbd>⌘</kbd><kbd>F5</kbd></span>", .{ .keys = "cmd f5" });
    // PC: modifiers first as Ctrl, Alt, Shift; "cmd ctrl" shows Ctrl once.
    try expectHtml(
        "<span class=\"zw-kbd\" role=\"img\" aria-label=\"Ctrl Shift Z\"><kbd>Ctrl</kbd><span class=\"zw-kbd__j\">+</span><kbd>Shift</kbd><span class=\"zw-kbd__j\">+</span><kbd>Z</kbd></span>",
        .{ .keys = "shift cmd z", .platform = .pc },
    );
    try expectHtml(
        "<span class=\"zw-kbd\" role=\"img\" aria-label=\"Ctrl Alt K\"><kbd>Ctrl</kbd><span class=\"zw-kbd__j\">+</span><kbd>Alt</kbd><span class=\"zw-kbd__j\">+</span><kbd>K</kbd></span>",
        .{ .keys = "ctrl opt cmd k", .platform = .pc },
    );
}
