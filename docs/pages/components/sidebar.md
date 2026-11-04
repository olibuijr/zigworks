# Sidebar

Source-list navigation, like Finder and Mail. Pass it to `ui.layout` as `sidebar`. On wide screens it sits next to the content; on narrow screens it slides in from the title bar button, with no JavaScript.

A Mail window. Sections have headings, links have icons and counts, two sections fold, and the footer is pinned to the bottom. The buttons on the right post to the server, which sends back the whole window: the badges and the selected mailbox follow.

```demo
sidebar
```

In the demos the links only change the URL hash. In an app they are real pages, and `current` marks the one you are on.

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

## Sizes

`size` is the macOS Sidebar Icon Size setting. It changes the row height and the icon size together, and rows are 44 px on touch screens whatever you pick.

```demo
sidebar-sizes
```

## Sections and badges

A section with an empty `title` has no heading. A `badge` stays visible when a long label is cut off with an ellipsis. A collapsible section starts as `open` says, but the section that holds the `current` page always opens.

```demo
sidebar-sections
```

## Filtering

The sidebar is plain markup, so a handler can return a smaller one. Here a field sends `GET /demo/sidebar/filter` on every keystroke and swaps the answer into the sidebar's container. Matching sections fold open, and when nothing matches the handler returns an empty state instead.

```demo
sidebar-filter
```

```zig
fn filter(c: *zw.Ctx) !void {
    const q = c.query("q") orelse "";
    // keep the links whose label contains q, then:
    try c.page(ui.sidebar(.{ .current = "#documents", .inline_ = true, .sections = kept }));
}
```

## In a settings window

A sidebar next to a card of settings, as in System Settings. The footer holds an account row and a storage meter; render them to a string first, since `footer` takes markup.

```demo
sidebar-settings
```

## Props

| Prop | Type | Default | Notes |
|---|---|---|---|
| `sections` | `[]const ui.SidebarSection` | required | `.{ .title, .links, .collapsible, .open }` |
| `current` | string | required | the `href` to mark with `aria-current="page"` |
| `label` | string | `"Navigation"` | accessible name of the `nav` |
| `inline_` | bool | `false` | show it inside content (no popover, no id), like every demo on this page |
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

Build sections at comptime to share them between pages, as this site does. Build them from the request to change them per user, as the filter demo does. Links are plain `<a>` elements: they take no `z` props, so a link always loads its `href`.

## Notes

- Long labels are truncated with an ellipsis; the badge never wraps.
- Hover styles apply only on devices that can hover, so a tap never leaves a link looking stuck.
- Section headings use the secondary label color for contrast in light and dark mode.
- A collapsible section is a `<details>`, so it works without JavaScript and with the keyboard (Space or Enter on the heading).
