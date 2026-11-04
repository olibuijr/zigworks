# Tag

A small capsule for tokens, filters and categories. With `remove`, it shows a × button that sends the request and removes the tag. With `href` it is a link; with `name` it is a filter chip that toggles on click and keyboard (Space) and submits with its form, with no JavaScript.

```demo
tag
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

// Reload a list whenever a chip changes:
ui.tag(.{ .text = "Mine", .name = "mine", .z = .{ .get = "/todos", .target = "#list" } })
```

## Props

| Prop | Type | Default | Notes |
|---|---|---|---|
| `text` | string | required | |
| `remove` | `?ui.Z` | `null` | request for the × button; the tag is removed when it succeeds (not on chips) |
| `tone` | `.accent` `.gray` `.red` `.green` `.orange` | `.accent` | system color of the tint, or of the fill when selected |
| `size` | `.small` `.regular` `.large` | `.regular` | 20, 24 and 28px tall |
| `icon` | string | `""` | short glyph or emoji before the text; decorative |
| `href` | string | `""` | renders the label as a link |
| `name` | string | `""` | makes the tag a filter chip: a checkbox with this name |
| `value` | string | `""` | chip value sent when selected; the text when empty |
| `selected` | bool | `false` | filled style; for a chip, the initial checked state |
| `disabled` | bool | `false` | dims the tag and turns off the link, chip and × button |
| `z` | `ui.Z` | `.{}` | request fired when a chip is toggled; the chip's `name=value` is sent with it |

## Notes

- Wrap a group of tags in `<div class="zw-tags">` for spacing and wrapping.
- A selected link tag gets `aria-current="true"`; a chip is a real checkbox, so screen readers announce checked and unchecked.
- On touch screens the link, chip and × hit areas grow to 44px without changing the look.
- Increase Contrast swaps the tint for a solid outline.
