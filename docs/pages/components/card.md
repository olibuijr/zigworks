# Card

An opaque content surface with an optional header and footer. Group related content in cards; never put glass on them.

```demo
card
```

## Usage

```zig
ui.card(.{
    .title = "Storage",
    .subtitle = "Macintosh HD",
    .accessory = ui.button(.{ .label = "Manage…", .variant = .plain }),
    .footer = "Updated just now",
    .body = zw.view("<p>{used} used</p>", .{ .used = "41 GB" }),
})
```

A footer can also hold actions, right-aligned:

```zig
ui.card(.{
    .title = "Rename list",
    .body = ui.field(.{ .name = "title", .label = "Title" }),
    .footer = zw.view("{a}{b}", .{ .a = ui.button(.{ .label = "Cancel" }), .b = ui.button(.{ .label = "Save", .variant = .primary }) }),
})
```

A link card is one big target:

```zig
ui.card(.{ .href = "/projects/zigworks", .title = "zigworks", .subtitle = "Updated today", .body = "A small web framework in Zig." })
```

## Props

| Prop | Type | Default | Notes |
|---|---|---|---|
| `title` | string | `""` | heading at the top |
| `subtitle` | string | `""` | secondary line under the title |
| `accessory` | component or string | none | trailing side of the header: a button, a badge, a menu |
| `footer` | component or string | none | text becomes a caption; a component (usually buttons) is right-aligned |
| `variant` | `ui.Card` variant | `.elevated` | `.elevated` (shadow), `.inset` (grouped fill, no shadow), `.plain` (no surface) |
| `flush` | bool | `false` | no padding, content clipped to the corners: for lists, tables and images that run edge to edge |
| `href` | string | `""` | renders an `<a>` so the whole card is a link, with hover and press feedback |
| `id` | string | `""` | sets the element id; with a title it also names the section for screen readers |
| `body` | component | required | any component or string |
| `z` | `ui.Z` | none | z.js attributes for the section |

`ui.Card(Body)` names the type when a function returns a card whose accessory and footer are text or absent.

## Notes

- A link card must not contain buttons, fields or other links, and takes no `footer` actions; put those in a regular card.
- Use `.inset` for a card inside another card, and `.plain` to keep the heading and footer layout without a surface.
- A `flush` card with a `ui.list` inside drops the list's own background, so the card provides it.
- Titles are `<h2>`. Keep the order of headings on the page sensible.
