# Sidebar

Source-list navigation, like Finder and Mail. Pass it to `ui.layout` as `sidebar`. On wide screens it sits next to the content; on narrow screens it slides in from the title bar button, with no JavaScript.

```demo
sidebar
```

## Usage

```zig
ui.sidebar(.{
    .current = c.path,
    .size = .medium,
    .footer = "<span class=\"zw-secondary\">Signed in as ada</span>",
    .sections = &.{
        .{ .title = "Mail", .links = &.{
            .{ .label = "Inbox", .href = "/inbox", .badge = "12", .icon = inbox_svg },
            .{ .label = "Sent", .href = "/sent", .icon = sent_svg },
        } },
        .{ .title = "Folders", .collapsible = true, .open = false, .links = &.{
            .{ .label = "Receipts", .href = "/receipts" },
        } },
    },
})
```

## Props

| Prop | Type | Default | Notes |
|---|---|---|---|
| `sections` | `[]const ui.SidebarSection` | required | `.{ .title, .links, .collapsible, .open }` |
| `current` | string | required | the `href` to mark with `aria-current="page"` |
| `label` | string | `"Navigation"` | accessible name of the `nav` |
| `inline_` | bool | `false` | show it inside content (no popover, no id), like the demo above |
| `size` | `.small` / `.medium` / `.large` | `.medium` | row height and icon size, like the macOS Sidebar Icon Size setting (24, 28 and 32 px rows; 44 px on touch screens) |
| `footer` | raw HTML string | `""` | pinned to the bottom of the sidebar: an account row, a storage note. Trusted markup, not escaped |

A section is `ui.SidebarSection`:

| Field | Type | Default | Notes |
|---|---|---|---|
| `title` | string | required | the heading; empty gives an untitled group |
| `links` | `[]const ui.SidebarLink` | required | |
| `collapsible` | bool | `false` | the heading becomes a disclosure triangle that folds the links (it shows while the pointer is over the sidebar, and always on touch screens) |
| `open` | bool | `true` | the initial state of a collapsible section. A section that holds the current page is always open |

A link is `ui.SidebarLink`:

| Field | Type | Default | Notes |
|---|---|---|---|
| `label` | string | required | |
| `href` | string | required | |
| `icon` | inline SVG string | `""` | drawn in the accent color; use `currentColor` strokes and a square `viewBox`. Hidden from screen readers |
| `badge` | string | `""` | trailing text, usually a count. Read after the label by screen readers |

Build sections at comptime to share them between pages, as this site does.

## Notes

- Long labels are truncated with an ellipsis; the badge never wraps.
- Hover styles apply only on devices that can hover, so a tap never leaves a link looking stuck.
- Section headings use the secondary label color for contrast in light and dark mode.
- A collapsible section is a `<details>`, so it works without JavaScript and with the keyboard (Space or Enter on the heading).
