# Sidebar

Source-list navigation, like Finder and Mail. Pass it to `ui.layout` as `sidebar`. On wide screens it sits next to the content; on narrow screens it slides in from the title bar button, with no JavaScript.

```demo
sidebar
```

## Usage

```zig
ui.sidebar(.{
    .current = c.path,
    .sections = &.{
        .{ .title = "Mail", .links = &.{
            .{ .label = "Inbox", .href = "/inbox" },
            .{ .label = "Sent", .href = "/sent" },
        } },
    },
})
```

## Props

| Prop | Type | Default | Notes |
|---|---|---|---|
| `sections` | `[]const ui.SidebarSection` | required | `.{ .title, .links }` |
| `current` | string | required | the `href` to mark with `aria-current="page"` |
| `label` | string | `"Navigation"` | accessible name of the `nav` |
| `inline_` | bool | `false` | show it inside content (no popover, no id), like the demo above |

Each link is a `ui.SidebarLink`: `.{ .label, .href }`. Build sections at comptime to share them between pages, as this site does.
