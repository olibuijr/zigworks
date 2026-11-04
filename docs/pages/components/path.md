# Path bar

Where a page sits, as links from the top level down, like the macOS path control. The last item is the current page.

```demo
path
```

## Usage

```zig
ui.path(.{ .items = &.{
    .{ .label = "Projects", .href = "/projects" },
    .{ .label = "zigworks", .href = "/projects/zigworks" },
    .{ .label = "Settings" },
} })
```

## Props

| Prop | Type | Default | Notes |
|---|---|---|---|
| `items` | `[]const ui.PathItem` | required | label and `href`; the last item's `href` is not used |
| `label` | string | `"Path"` | accessible name of the `nav` |
