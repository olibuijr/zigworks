# Callout

A highlighted note, tip, warning, important or caution message, with an icon. In Markdown, `> [!TIP]` renders the same component.

```demo
callout
```

## Usage

```zig
ui.callout(.{ .kind = .warning, .title = "Warning", .body = "This cannot be undone." })
ui.callout(.{ .kind = .caution, .title = "Caution", .body = "Deleting a site removes its backups." })
ui.callout(.{ .kind = .tip, .body = "Press ⌘K to search.", .compact = true })
ui.callout(.{ .body = "Plain note, no icon.", .icon = false })
```

## Props

| Prop | Type | Default | Notes |
|---|---|---|---|
| `kind` | enum | `.note` | `.note` (blue), `.tip` (green), `.warning` (orange), `.important` (purple), `.caution` (red) |
| `title` | string | `""` | bold lead-in |
| `body` | component | required | a string or any component |
| `icon` | bool | `true` | show the kind's icon |
| `compact` | bool | `false` | tighter padding and no accent bar, for dense UI |

## Notes

- The callout is a `role="note"`. The kind is shown by color and icon; put it in `title` too when the distinction matters ("Caution: ...").
- Markdown fences support `[!NOTE]`, `[!TIP]` and `[!WARNING]` and always show the icon.
