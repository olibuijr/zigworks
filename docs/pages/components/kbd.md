# Keyboard shortcut

Keycaps for a shortcut, in help text and menus. Keys are separated by spaces. Write the Mac symbols ⌘ ⌥ ⌃ ⇧ in Apple's order (Control, Option, Shift, Command), or plain words like `cmd shift k`; both render the same, and `platform = .pc` turns them into Ctrl, Alt and Shift for other systems.

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
```

## Props

| Prop | Type | Default | Notes |
|---|---|---|---|
| `keys` | string | required | space-separated symbols or words (see below) |
| `platform` | `.mac` `.pc` | `.mac` | `.pc` shows Ctrl, Alt, Shift, Enter, Esc... and joins keys with `+` |
| `size` | `.small` `.regular` `.large` | `.regular` | 16, 20 and 26px keycaps |
| `joiner` | string | `""` | text between keycaps, such as `+` or `then`; empty means none (`+` on `.pc`) |
| `plain` | bool | `false` | no keycaps, only the symbols in secondary text, like a menu item's shortcut |

## Key names

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

## Notes

- The whole shortcut has one accessible name ("Command Shift K"), because screen readers read symbols like ⌘ poorly; the keycaps inside are presentational.
- Only write the shortcut text. It does not register the shortcut; do that in your page's script.
