# Layout

The root of every page: the document shell, a glass title bar and the content column. It loads `zw.css` and `z.js`, so pages need nothing else.

A layout is a whole document, so each demo below is a real page in a frame. Here is a Notes app: a sidebar, a toolbar and a list that scrolls under the title bar.

```demo
layout
```

## Usage

```zig
try c.page(ui.layout(.{
    .title = "Todos",
    .toolbar = ui.badge(.{ .text = "3 left", .id = "remaining" }),
    .body = ui.card(.{ .body = list }),
    .footer = "Made with zigworks",
    .title_align = .center,
}));
```

A sidebar turns the page into an app:

```zig
try c.page(ui.layout(.{
    .title = "Notes",
    .sidebar = ui.sidebar(.{ .current = "/all", .sections = &.{
        .{ .title = "iCloud", .links = &.{.{ .label = "All Notes", .href = "/all" }} },
    } }),
    .body = notes,
}));
```

## Title bar

`.title_align` places the title, `.brand` turns it into a link to `/`, and `.toolbar` fills the trailing edge. With a sidebar, the title bar gains a button that opens it on narrow screens. `.head` adds raw HTML to `<head>`; here it makes the brand link leave the frame.

```demo
layout-titles
```

## Footer, language and skip link

`.footer` sits under the page below a hairline. `.lang` sets the document language, `.skip_label` translates the skip link, and `.skip_link = false` removes it.

```demo
layout-chrome
```

## Updating the page from a response

The title bar is part of the page, so z.js can update it. Give a toolbar badge an `id`, and answer a request with the same badge and `.oob = true`. Toasts work the same way.

```demo
layout-live
```

```zig
// POST /reminders: append the row, replace the badge, show a toast.
try c.page(zw.view("{row}{badge}{toast}", .{
    .row = row,
    .badge = ui.badge(.{ .count = n, .id = "remaining", .oob = true }),
    .toast = ui.toast(.{ .text = "Reminder added", .kind = .success }),
}));
```

## In a real app

A settings window: a centered title, a sidebar, cards, setting rows and a footer.

```demo
layout-settings
```

## Props

| Prop | Type | Default | Notes |
|---|---|---|---|
| `title` | string | required | the tab title, and the title bar text without `brand` |
| `brand` | string | `""` | title bar text that links to `/` |
| `head` | raw HTML | `""` | import maps, meta tags, a real favicon |
| `lang` | string | `"en"` | the `lang` of the `<html>` element; set it for screen readers and hyphenation |
| `toolbar` | component | none | trailing title bar content |
| `title_align` | `.leading` / `.center` | `.leading` | `.center` centers the title between the sidebar button and the toolbar, like a macOS window title |
| `sidebar` | `ui.sidebar` | none | turns the page into a two-column app |
| `skip_link` | bool | `true` | a "Skip to content" glass pill that appears on the first Tab and jumps to the content |
| `skip_label` | string | `"Skip to content"` | text of the skip link, for other languages |
| `footer` | component or string | none | content under the page, below a hairline; with a sidebar it sits under the content column |
| `body` | component | required | the page content |

An unknown prop is a compile error. With a sidebar, the title bar gains a button that shows the sidebar on narrow screens.

## Notes

- The content column is `<main id="zw-main">`; the skip link targets it, so keep the id unused elsewhere. Pass `.skip_link = false` only if your own markup already offers one.
- The title bar respects the notch and home indicator on phones (`viewport-fit=cover` with safe-area insets).
- The sidebar button is 44 px on touch screens.
- `.footer` is a good place for a copyright line, a version or links to legal pages. Use `zw-secondary` text for quiet content; the footer already uses the callout size and secondary color.
