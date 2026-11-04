# Button

A macOS push button. Use one primary button per view for the default action.

```demo
button
```

## Usage

```zig
ui.button(.{ .label = "Save", .variant = .primary, .type = .submit })
ui.button(.{ .label = "Delete", .variant = .destructive, .z = .{
    .delete = "/todos/1", .target = "closest li", .swap = .delete, .confirm = "Delete this todo?",
} })
```

Sizes, icons, loading and links:

```zig
ui.button(.{ .label = "New Item", .icon = plus_svg, .size = .large })
ui.button(.{ .label = "Add", .icon = plus_svg, .icon_only = true, .variant = .primary })
ui.button(.{ .label = "Saving…", .variant = .primary, .loading = true })
ui.button(.{ .label = "Read the Docs", .href = "/docs", .variant = .plain, .icon = chevron_svg, .icon_end = true })
```

## Props

| Prop | Type | Default | Notes |
|---|---|---|---|
| `label` | string | required | use title case: "Save Changes" |
| `variant` | enum | `.secondary` | `.primary`, `.secondary`, `.plain`, `.destructive` |
| `type` | enum | `.button` | `.submit` inside forms |
| `aria` | string | `""` | accessible name when the label is not enough |
| `opens` | string | `""` | id of a menu or sheet to show |
| `disabled` | bool | `false` | |
| `z` | `ui.Z` | none | z.js request |
| `size` | enum | `.regular` | `.small`, `.regular`, `.large`; heights follow `--control-h` |
| `icon` | string | `""` | inline SVG markup drawn with `currentColor`; trusted, not escaped |
| `icon_end` | bool | `false` | put the icon after the label |
| `icon_only` | bool | `false` | square button showing only the icon; `label` stays as the hidden accessible name |
| `loading` | bool | `false` | spinner replaces the icon, button is disabled, `aria-busy="true"` |
| `href` | string | `""` | renders an `<a>` styled as a button; inert (`aria-disabled`) when `disabled` or `loading` |
| `full` | bool | `false` | stretch to the container width |
| `describedby` | string | `""` | id of an element that describes it, e.g. a tooltip's `id` |

## Notes

- Use `.icon_only` only for familiar symbols and keep the label meaningful ("Add", not "Plus"); it is read by screen readers.
- Give `.loading` buttons the same label as before, or its progressive form ("Saving…"), so the width barely changes.
- On touch screens every button is at least 44px tall. Reduce Motion stops the spinner turning; the ring stays visible.
- `opens` and `type` apply to the `<button>` form only; an `href` button is a plain link (`z` attributes still work on it).
