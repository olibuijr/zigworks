# Tag

A small capsule for tokens, filters and categories. With `remove`, it shows a × button that sends the request and removes the tag.

```demo
tag
```

## Usage

```zig
zw.view("<div class=\"zw-tags\">{a}{b}</div>", .{
    .a = ui.tag(.{ .text = "zig" }),
    .b = ui.tag(.{ .text = "web", .remove = .{ .delete = "/tags/web" } }),
})
```

## Props

| Prop | Type | Default | Notes |
|---|---|---|---|
| `text` | string | required | |
| `remove` | `?ui.Z` | `null` | request for the × button; the tag is removed when it succeeds |

Wrap a group of tags in `<div class="zw-tags">` for spacing and wrapping.
