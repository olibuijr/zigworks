# Layout

The root of every page: the document shell, a glass title bar and the content column. It loads `zw.css` and `z.js`, so pages need nothing else.

```demo
layout
```

## Usage

```zig
try c.page(ui.layout(.{
    .title = "Todos",
    .toolbar = ui.badge(.{ .text = "3 left", .id = "remaining" }),
    .body = ui.card(.{ .body = list }),
}));
```

## Props

| Prop | Type | Default | Notes |
|---|---|---|---|
| `title` | string | required | the tab title, and the title bar text without `brand` |
| `brand` | string | `""` | title bar text that links to `/` |
| `head` | raw HTML | `""` | import maps, meta tags, a real favicon |
| `toolbar` | component | none | trailing title bar content |
| `sidebar` | `ui.sidebar` | none | turns the page into a two-column app |
| `body` | component | required | the page content |

An unknown prop is a compile error. With a sidebar, the title bar gains a button that shows the sidebar on narrow screens.
