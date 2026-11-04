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
    .body = ui.progress(.{ .value = 64, .label = "Storage used", .text = "41.2 GB of 64 GB used", .show_value = true }),
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

## Variants

`variant` picks the surface. Use `.inset` for a card inside another card, and `.plain` to keep the heading and footer layout without a surface.

```demo
card-variants
```

```zig
ui.card(.{ .variant = .inset, .title = "Last backup", .body = "Today at 9:41 AM" })
```

`ui.card` takes its props loosely, so a literal like `.inset` works but `if (x) .inset else .elevated` does not compile. To choose the variant at run time, give it a type with `ui.CardVariant`:

```zig
const v: ui.CardVariant = if (nested) .inset else .elevated;
ui.card(.{ .variant = v, .title = "Last backup", .body = "Today at 9:41 AM" })
```

## States

A card has no states of its own; it shows the state of what is inside. Put a skeleton in the body while content loads, an empty state when there is none, a callout or a field error when something went wrong, and disabled controls with the reason in the footer.

```demo
card-states
```

A card can also load itself. Give it a `z` that fires on `load` and answer with the finished card:

```zig
ui.card(.{
    .id = "activity",
    .title = "Recent Activity",
    .z = ui.Z{ .get = "/activity", .trigger = "load", .swap = .outer },
    .body = ui.skeleton(.{ .shape = .media, .lines = 2 }),
})
```

## Link cards

With `href` the whole card is one big target, with hover and press feedback. Use it to open a detail page.

```demo
card-links
```

```zig
ui.card(.{ .href = "/projects/zigworks", .title = "zigworks", .subtitle = "Updated today", .body = "A small web framework in Zig." })
```

## Choosing between cards

A card does not select itself. Put a button in each footer, send a request, and let the server answer with the cards again. The response also carries a toast.

```demo
card-plans
```

```zig
ui.button(.{
    .label = if (on) "Selected" else "Choose",
    .variant = if (on) .primary else .secondary,
    .disabled = on,
    .z = .{ .get = "/plan?p=pro", .target = "#plans", .swap = .inner },
})
```

## Flush cards in a list

`flush` removes the padding and clips the content to the corners, so a list runs edge to edge. The header and footer keep their own padding. Here the footer holds a form that adds rows, each row deletes with an Undo toast, and the empty list shows its `empty` text.

```demo
card-reminders
```

```zig
ui.card(.{
    .title = "Reminders",
    .subtitle = "Today",
    .flush = true,
    .body = ui.list(.{ .id = "reminders", .empty = "All done.", .body = zw.each(items, row) }),
    .footer = zw.view("<form class=\"zw-row zw-grow\"{z}>{f}{b}</form>", .{
        .z = ui.Z{ .post = "/add", .target = "#reminders", .swap = .beforeend },
        .f = ui.field(.{ .name = "title", .label = "New reminder", .required = true }),
        .b = ui.button(.{ .label = "Add", .variant = .primary, .type = .submit }),
    }),
})
```

## Props

| Prop | Type | Default | Notes |
|---|---|---|---|
| `title` | string | `""` | heading at the top |
| `subtitle` | string | `""` | secondary line under the title |
| `accessory` | component or string | none | trailing side of the header: a button, a badge, a spinner |
| `footer` | component or string | none | text becomes a caption; a component (usually buttons) is right-aligned |
| `variant` | `ui.CardVariant` | `.elevated` | `.elevated` (shadow), `.inset` (grouped fill, no shadow), `.plain` (no surface) |
| `flush` | bool | `false` | no padding, content clipped to the corners: for lists, tables and images that run edge to edge |
| `href` | string | `""` | renders an `<a>` so the whole card is a link, with hover and press feedback |
| `id` | string | `""` | sets the element id; with a title it also names the section for screen readers |
| `body` | component or string | required | any component or string |
| `z` | `ui.Z` | none | z.js attributes for the section or link |

`ui.Card(Body)` names the type when a function returns a card whose accessory and footer are text or absent.

## Notes

- A link card must not contain buttons, fields or other links, and takes no `footer` actions; put those in a regular card.
- A `flush` card with a `ui.list` inside drops the list's own shadow and corners, so the card provides them. The list keeps its background, which matches the card's.
- A card with `z` and no `href` is a plain `<section>`: a click fires the request, but the card cannot be focused or used from the keyboard. Put a real `ui.button` inside for anything a keyboard user must reach, as the plans above do. `z` on a card suits `.trigger = "load"`.
- Pass `z` as `ui.Z{ ... }` to `ui.card`, which takes its props loosely; the buttons and fields inside take a plain `.z = .{ ... }`.
- Titles are `<h2>`. Keep the order of headings on the page sensible.
