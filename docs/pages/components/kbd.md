# Keyboard shortcut

Keycaps for a shortcut, in help text and menus. Keys are separated by spaces; use the Mac symbols ⌘ ⌥ ⌃ ⇧ in Apple's order (Control, Option, Shift, Command).

```demo
kbd
```

## Usage

```zig
ui.kbd(.{ .keys = "⌘ ⇧ N" })
```

## Props

| Prop | Type | Default | Notes |
|---|---|---|---|
| `keys` | string | required | space-separated keys |
