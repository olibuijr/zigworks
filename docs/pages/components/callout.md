# Callout

A highlighted note, tip or warning. In Markdown, `> [!TIP]` renders the same component.

```demo
callout
```

## Usage

```zig
ui.callout(.{ .kind = .warning, .title = "Warning", .body = "This cannot be undone." })
```

## Props

| Prop | Type | Default | Notes |
|---|---|---|---|
| `kind` | enum | `.note` | `.note`, `.tip`, `.warning` |
| `title` | string | `""` | bold lead-in |
| `body` | component | required | a string or any component |
