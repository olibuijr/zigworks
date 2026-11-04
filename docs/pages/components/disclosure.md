# Disclosure

A titled section that opens and closes, for details most people don't need, such as advanced settings or FAQ answers. It is a `<details>` element, so it works without JavaScript; the chevron turns and the height springs open.

```demo
disclosure
```

## Usage

```zig
ui.disclosure(.{ .title = "Advanced", .body = advanced_settings })
```

## Props

| Prop | Type | Default | Notes |
|---|---|---|---|
| `title` | string | required | always visible |
| `open` | bool | `false` | |
| `body` | component | required | |
| `name` | string | `""` | disclosures with the same name are exclusive: opening one closes the others (an accordion) |
| `detail` | string | `""` | secondary text at the trailing edge of the title row, such as a count or a current value |
| `style` | `.plain` or `.card` | `.plain` | `.card` puts the section on its own content surface |

## Accordion

```zig
ui.disclosure(.{ .title = "Shipping", .name = "faq", .style = .card, .body = shipping })
ui.disclosure(.{ .title = "Returns", .name = "faq", .style = .card, .detail = "30 days", .body = returns })
```

## Notes

- The whole title row is the target: it highlights on hover, shows a focus ring from the keyboard, and is 44px tall on touch screens. Space and Enter toggle it.
- `name` uses the native `<details name>` grouping, so it needs no script. In a browser that doesn't support it, each disclosure simply opens on its own.
- Consecutive `.card` disclosures are spaced 8px apart.
- `detail` stays on one line and is shortened with an ellipsis; the title wraps.
