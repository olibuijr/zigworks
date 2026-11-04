# Tooltip

A short glass hint that appears when the pointer rests on something, after the macOS half-second delay, or when keyboard focus enters it. It replaces the browser's `title` attribute, which zigworks never uses.

```demo
tooltip
```

## Usage

```zig
ui.tooltip(.{ .text = "More actions", .body = ui.button(.{ .label = "•••", .aria = "More actions", .variant = .plain }) })
```

## Props

| Prop | Type | Default | Notes |
|---|---|---|---|
| `text` | string | required | a few words, no period |
| `side` | enum | `.above` | `.above` or `.below` (near the top of a page) |
| `body` | component | required | the thing being explained |

Tooltips explain; they must not hold the only copy of important information, since touch screens never show them.
