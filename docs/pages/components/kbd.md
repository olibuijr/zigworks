# Keyboard shortcut

Keycaps for a shortcut, in help text and menus. Keys are separated by spaces. Write the Mac symbols ⌘ ⌥ ⌃ ⇧ in Apple's order (Control, Option, Shift, Command), or plain words like `cmd shift k`; both render the same, and `platform = .pc` turns them into Ctrl, Alt and Shift for other systems.

A shortcuts pane lists each command with its keys on the trailing side, the way System Settings does:

```demo
kbd
```

## Usage

```zig
ui.kbd(.{ .keys = "⌘ ⇧ N" })

// Words work too (any case); lowercase letters are capitalized:
ui.kbd(.{ .keys = "cmd shift n" })

// For Windows and Linux: Ctrl+Shift+N
ui.kbd(.{ .keys = "cmd shift n", .platform = .pc })

// A sequence instead of a chord, in menu style:
ui.kbd(.{ .keys = "g i", .joiner = "then", .plain = true })

// As the trailing control of a list row:
zw.view("<li><span class=\"zw-grow\">{label}</span>{keys}</li>", .{
    .label = "New Note",
    .keys = ui.kbd(.{ .keys = "cmd n" }),
})
```

## Variants and sizes

Each row names the props it uses. `size` changes the keycap height, `plain` drops the keycaps for menu-style text, and `joiner` puts text between the keys, which turns a chord into a sequence.

```demo
kbd-variants
```

## Key names

Anything on the left of the table below can be written as a word. The demo shows what each word becomes on a Mac and on a PC. Unknown words are shown as written, so write them the way they should look (`F5`, not `f5`).

```demo
kbd-keys
```

| Key | Words | Mac | PC |
|---|---|---|---|
| Command | `cmd` `command` `meta` `super` | ⌘ | Ctrl |
| Option | `opt` `option` `alt` | ⌥ | Alt |
| Shift, Control | `shift`, `ctrl` `control` | ⇧ ⌃ | Shift, Ctrl |
| Return | `enter` `return` | ↩ | Enter |
| Escape, Tab | `esc` `escape`, `tab` | ⎋ ⇥ | Esc, Tab |
| Delete | `backspace` `delete` | ⌫ | Backspace |
| Forward delete | `del` | ⌦ | Del |
| Space, Caps Lock | `space`, `caps` | Space ⇪ | Space, Caps Lock |
| Arrows | `up` `down` `left` `right` | ↑ ↓ ← → | ↑ ↓ ← → |
| Page, Home, End | `pageup` `pagedown` `home` `end` | ⇞ ⇟ ↖ ↘ | PgUp PgDn Home End |

Anything else is shown as written.

## Mac and Windows

`platform` only swaps the keycaps; it does not know that Redo is Ctrl+Y on Windows. When the shortcut differs, pass different `keys`. Here a segmented control asks the server for the same menu on the other platform, and the response replaces the rows:

```demo
kbd-platform
```

```zig
fn platformRows(c: *zw.Ctx) !void {
    const pc = std.mem.eql(u8, c.query("p") orelse "", "pc");
    try c.page(Rows{ .rows = &edit_menu, .pc = pc }); // each row: ui.kbd(.{ .keys = ..., .platform = if (pc) .pc else .mac })
}
```

## In a command search

A search field with `shortcut = "k"` shows a ⌘K hint and focuses on ⌘K or Ctrl+K. Its results are links, so each command can carry its shortcut as a small `kbd`:

```demo
kbd-find
```

## In a command list

A list of commands, each with its shortcut and a Run button. Running one posts to the server, which answers with a toast. The "Sequences…" sheet lists multi-key sequences with `joiner = "then"`:

```demo
kbd-commands
```

## Props

| Prop | Type | Default | Notes |
|---|---|---|---|
| `keys` | string | required | space-separated symbols or words (see above) |
| `platform` | `.mac` `.pc` | `.mac` | `.pc` shows Ctrl, Alt, Shift, Enter, Esc... and joins keys with `+` |
| `size` | `.small` `.regular` `.large` | `.regular` | 16, 20 and 26px keycaps |
| `joiner` | string | `""` | text between keycaps, such as `+` or `then`; empty means none (`+` on `.pc`) |
| `plain` | bool | `false` | no keycaps, only the symbols in secondary text, like a menu item's shortcut |

## Notes

- The whole shortcut has one accessible name ("Command Shift K"), because screen readers read symbols like ⌘ poorly; the keycaps inside are presentational.
- Only write the shortcut text. It does not register the shortcut; do that in your page's script.
- On `.pc`, both `cmd` and `ctrl` become Ctrl, and the keys keep the order you wrote them in.
- Menu items, tooltips and the search field have their own `shortcut` hint, which is plain text. Use `ui.kbd` where you lay out the markup yourself, such as list rows, cards and sheets.
