# Button

A macOS push button. Use one primary button per view for the default action.

The pane below is a typical Settings page. "Save Changes" is the primary button and submits the form, "Delete Account…" is destructive and asks first, and "Choose Photo…" is a link styled as a button. Clear the name and save to see the error toast.

```demo
button
```

## Variants and sizes

The `variant` prop sets the role. Primary is the default action and is filled with the accent color. Secondary is the standard bezel. Plain has no border and suits quiet actions next to a primary button. Destructive is red and marks an action that deletes something. The `size` prop follows AppKit control sizes; the heights come from `--control-h`.

```demo
button-variants
```

## Icons, links and width

`icon` draws an SVG before the label, and `icon_end` moves it after (chevrons, external links). `icon_only` shows just the icon in a square; the label stays as the hidden accessible name. When the label itself is a symbol such as "+", set `aria` to the real name. `href` renders a link that looks like a button, and `full` stretches a button to the width of its container.

```demo
button-content
```

## States

A disabled button is dimmed and ignores the pointer and keyboard. A loading button shows a spinner, is disabled and sets `aria-busy`, so keep its label (or its progressive form, "Saving…"). Link buttons go inert in both states. Buttons have no invalid state: show errors on the field, or with a toast.

The last row is live. "Check for Updates" asks the server for a loading version of itself, and Stop asks for the idle one back.

```demo
button-states
```

## Actions

Give a button a `z` request and it talks to the server. The cart posts the next count in its own URL and the server answers with the whole row, so the badge and both buttons stay in step and nothing is kept on the server; Clear is disabled while the cart is empty. The delete buttons ask for confirmation first, then remove their row.

```demo
button-actions
```

## In a toolbar

Icon-only buttons need a tooltip and `describedby`. Here Reply, Archive and Move to Trash fire a request and answer with a toast, and More opens a menu with `opens`; the button keeps its pressed look while the menu is open.

```demo
button-toolbar
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

A button that opens a menu, and an icon-only button with a tooltip:

```zig
ui.button(.{ .label = "More", .icon = more_svg, .icon_only = true, .variant = .plain, .opens = "more-menu" })
ui.tooltip(.{ .id = "tip-reply", .text = "Reply", .body = ui.button(.{
    .label = "Reply", .icon = reply_svg, .icon_only = true, .variant = .plain, .describedby = "tip-reply",
}) })
```

To show the loading state while a request runs, have the handler send the button back with `.loading = true`, and send the idle one back when the work is done:

```zig
ui.button(.{ .label = "Check for Updates", .z = .{ .post = "/check", .swap = .outer } })
```

## Props

| Prop | Type | Default | Notes |
|---|---|---|---|
| `label` | string | required | use title case: "Save Changes"; the accessible name when `icon_only` |
| `variant` | enum | `.secondary` | `.primary`, `.secondary`, `.plain`, `.destructive`; primary and secondary are glass |
| `type` | enum | `.button` | `.submit` inside forms |
| `aria` | string | `""` | accessible name when the label is a symbol ("+") |
| `opens` | string | `""` | id of a popover (menu or sheet) to toggle; no JS needed |
| `disabled` | bool | `false` | dimmed and inert |
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
- While a `z` request is in flight the button is dimmed and ignores clicks, so a double click sends once.
- On touch screens every button is at least 44px tall. Reduce Motion stops the spinner turning; the ring stays visible.
- `opens` and `type` apply to the `<button>` form only; an `href` button is a plain link (`z` attributes still work on it).
