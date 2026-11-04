# Badge

A small count or status. With `oob`, a z.js response can update a badge anywhere on the page.

```demo
badge
```

## Usage

```zig
// In the page:
ui.badge(.{ .text = "3 left", .id = "remaining" })

// In a response, next to the swapped content:
ui.badge(.{ .text = "2 left", .id = "remaining", .oob = true })
```

## Props

| Prop | Type | Default | Notes |
|---|---|---|---|
| `text` | string | required | |
| `id` | string | `""` | needed for `oob` |
| `oob` | bool | `false` | replace the element with the same `id` |
