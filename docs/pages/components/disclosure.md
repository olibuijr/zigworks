# Disclosure

A titled section that opens and closes, for details most people don't need, such as advanced settings or FAQ answers. It is a `<details>` element, so it works without JavaScript; the chevron turns and the height springs open.

Here it groups the sections of a Finder-style info panel. The first one starts open; the others show a `detail` on the trailing edge.

```demo
disclosure
```

## Usage

```zig
ui.disclosure(.{ .title = "Advanced", .body = advanced_settings })

// Open at first, with a value on the trailing edge:
ui.disclosure(.{ .title = "Sharing & Permissions", .open = true, .detail = "You can read and write", .body = sharing })
```

Inside a card, stack plain disclosures in a container. Hairlines between them are up to you; the demos use a `border-top` on every disclosure after the first.

## Styles and detail

`.plain` has no surface: use it inside a card or a page. `.card` gives each section its own content surface, spaced 8px apart, for stand-alone lists. Both take a `detail`.

```demo
disclosure-styles
```

```zig
ui.card(.{ .body = zw.view("{a}{b}", .{
    .a = ui.disclosure(.{ .title = "Wi-Fi", .detail = "Home", .body = wifi }),
    .b = ui.disclosure(.{ .title = "VPN", .detail = "Not connected", .body = vpn }),
}) })

ui.disclosure(.{ .title = "Storage", .style = .card, .detail = "41 of 64 GB", .body = storage })
```

## States

A disclosure is closed unless `open` is set. The title wraps, the `detail` is cut off with an ellipsis, and the body can hold anything, including an empty state or more disclosures.

```demo
disclosure-states
```

## Accordion

Give several disclosures the same `name` and opening one closes the others. Without a `name`, each one opens on its own.

```demo
disclosure-accordion
```

```zig
ui.disclosure(.{ .title = "Shipping", .name = "faq", .style = .card, .open = true, .body = shipping })
ui.disclosure(.{ .title = "Returns", .name = "faq", .style = .card, .detail = "30 days", .body = returns })
```

## Live filters

A disclosure has no `z` of its own, but its body can hold anything that does. Here the filter chips are a form that posts on every change. The handler reads which chips are checked and sends the whole inbox back, so the `detail` ("2 active"), the count and the empty state all follow. The server keeps nothing: the state is in the request.

```demo
disclosure-filters
```

```zig
// The form inside the disclosure body:
zw.view("<form class=\"zw-tags\"{z}>{a}{b}</form>", .{
    .z = ui.Z{ .post = "/inbox/filter", .trigger = "change", .target = "#inbox", .swap = .outer },
    .a = ui.tag(.{ .text = "Unread", .name = "unread", .value = "1", .selected = f.unread }),
    .b = ui.tag(.{ .text = "Flagged", .name = "flagged", .value = "1", .selected = f.flagged }),
})

// The handler renders the same view again, with the new state:
fn filterInbox(c: *zw.Ctx) !void {
    try c.page(Inbox{ .unread = c.form("unread") != null, .flagged = c.form("flagged") != null });
}
```

## In a form

A disclosure keeps secondary options out of the way. Controls inside it work as they do anywhere else; here they save through `POST /demo`. Disclosures nest, so an advanced section can hold its own.

```demo
disclosure-export
```

## Props

| Prop | Type | Default | Notes |
|---|---|---|---|
| `title` | string | required | always visible; wraps when long |
| `open` | bool | `false` | starts open |
| `body` | component or string | required | |
| `name` | string | `""` | disclosures with the same name are exclusive: opening one closes the others (an accordion) |
| `detail` | string | `""` | secondary text at the trailing edge of the title row, such as a count or a current value |
| `style` | `.plain` or `.card` | `.plain` | `.card` puts the section on its own content surface |

## Notes

- The whole title row is the target: it highlights on hover, shows a focus ring from the keyboard, and is 44px tall on touch screens. Space and Enter toggle it.
- `name` uses the native `<details name>` grouping, so it needs no script. In a browser that doesn't support it, each disclosure simply opens on its own.
- Consecutive `.card` disclosures are spaced 8px apart.
- `detail` stays on one line and is shortened with an ellipsis; the title wraps.
- There is no `id` or `z` prop. To update a disclosure from the server, put it in an element with an id and swap that element, as the filter demo does.
