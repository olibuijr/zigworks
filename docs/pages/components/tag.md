# Tag

A small capsule for tokens, filters and categories. With `remove`, it shows a × button that sends the request and removes the tag. With `href` it is a link; with `name` it is a filter chip that toggles on click and keyboard (Space) and submits with its form, with no JavaScript.

```demo
tag
```

A note with tags. The × removes a tag and shows a toast; the form adds one. Each tag is a request: the server answers, z.js swaps.

## Variants and sizes

One row per prop. `tone` sets the tint, `size` the height, `icon` adds a glyph, `href` makes a link, `remove` adds the × button. Text that is wider than the space truncates with an ellipsis.

```demo
tag-variants
```

## States

A tag is `selected` (filled), a chip (`name`, filled while checked) or `disabled`. A disabled link tag is not a link any more, and a disabled tag ignores its × button too.

```demo
tag-states
```

## Filter chips

Chips are checkboxes, so they work inside a form. Put the request on the form with `z-trigger="change"` and it is sent with every selected chip. Here the server filters the files, swaps the rows and updates the count badge out of band. With no chip selected you see everything; with a combination that matches nothing you see the list's empty text.

```demo
tag-filter
```

## With other components

Small tags in list rows next to an avatar and a badge. The chips in the card are fire-and-forget: `z` sends `name=value` when a chip is checked.

```demo
tag-compose
```

## Usage

```zig
zw.view("<div class=\"zw-tags\">{a}{b}</div>", .{
    .a = ui.tag(.{ .text = "zig" }),
    .b = ui.tag(.{ .text = "web", .remove = .{ .delete = "/tags/web" } }),
})

// A link tag, with a tone and an icon:
ui.tag(.{ .text = "Docs", .href = "/docs", .tone = .orange, .icon = "📖" })

// Filter chips: inside a <form>, selected chips are sent as state=open&state=closed.
ui.tag(.{ .text = "Open", .name = "state", .value = "open", .selected = true })
ui.tag(.{ .text = "Closed", .name = "state", .value = "closed" })

// Save each chip as it changes (the chip's name=value is sent):
ui.tag(.{ .text = "Mentions", .name = "notify", .value = "mentions", .z = .{ .post = "/prefs", .swap = .none } })

// Or reload a list when any chip in a form changes: put the request on the form.
zw.view("<form class=\"zw-tags\" z-get=\"/files\" z-trigger=\"change\" z-target=\"#files\">{a}{b}</form>", .{
    .a = ui.tag(.{ .text = "Documents", .name = "kind", .value = "doc" }),
    .b = ui.tag(.{ .text = "Images", .name = "kind", .value = "image" }),
})

// The × button deletes the tag once the request succeeds. Answer 200 (a 204 changes nothing):
ui.tag(.{ .text = "Draft", .remove = .{ .delete = "/tags/draft" } })
```

## Props

| Prop | Type | Default | Notes |
|---|---|---|---|
| `text` | string | required | |
| `remove` | `?ui.Z` | `null` | request for the × button; the tag is removed when it succeeds with a 200 (not on chips) |
| `tone` | `.accent` `.gray` `.red` `.green` `.orange` | `.accent` | system color of the tint, or of the fill when selected |
| `size` | `.small` `.regular` `.large` | `.regular` | 20, 24 and 28px tall |
| `icon` | string | `""` | short glyph or emoji before the text; decorative |
| `href` | string | `""` | renders the label as a link; ignored (a plain span) when `disabled` |
| `name` | string | `""` | makes the tag a filter chip: a checkbox with this name |
| `value` | string | `""` | chip value sent when selected; the text when empty |
| `selected` | bool | `false` | filled style; for a chip, the initial checked state |
| `disabled` | bool | `false` | dims the tag and turns off the link, chip and × button |
| `z` | `ui.Z` | `.{}` | request fired when a chip is toggled; the chip's `name=value` is sent with it (only while checked) |

## Notes

- Wrap a group of tags in `<div class="zw-tags">` for spacing and wrapping.
- Long text truncates with an ellipsis at the width of its container; the × button stays visible.
- A tag dims (`zw-busy`) while its request is in flight.
- The remove request must answer 200 with a body (even a toast or an empty `<template>`): z.js does not swap on 204, so the tag would stay.
- To filter with several chips, put the request on the `<form>`; a chip's own `z` only sends that one chip.
- A selected link tag gets `aria-current="true"`; a chip is a real checkbox, so screen readers announce checked and unchecked.
- On touch screens the link, chip and × hit areas grow to 44px without changing the look.
- Increase Contrast swaps the tint for a solid outline.
