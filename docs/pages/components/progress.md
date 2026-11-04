# Progress

A progress bar when you know how far along a task is, and a spinner when you don't.

```demo
progress
```

## Usage

```zig
ui.progress(.{ .value = 42, .label = "Download" })   // 42%
ui.progress(.{ .value = null, .label = "Indexing" }) // spinner
```

## Props

| Prop | Type | Default | Notes |
|---|---|---|---|
| `value` | `?u8` | required | 0 to 100, or null for indeterminate |
| `label` | string | required | accessible name |

Swap in a new bar with z.js to update it, for example with `z-trigger="load"` polling.
