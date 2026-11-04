# Progress

A progress bar when you know how far along a task is, a ring for compact spots, and a spinner when you don't.

```demo
progress
```

## Usage

```zig
ui.progress(.{ .value = 42, .label = "Download" })                 // bar, 42%
ui.progress(.{ .value = null, .label = "Indexing" })              // spinner
ui.progress(.{ .value = 72, .label = "Upload", .text = "Uploading photos", .show_value = true })
ui.progress(.{ .value = 100, .label = "Backup", .tone = .success, .size = .large })
ui.progress(.{ .value = 64, .label = "Storage", .ring = true, .show_value = true })
ui.progress(.{ .value = null, .label = "Syncing", .text = "Syncing…", .size = .small })
```

## Props

| Prop | Type | Default | Notes |
|---|---|---|---|
| `value` | `?u8` | required | 0 to 100 (higher values are clamped), or null for indeterminate |
| `label` | string | required | accessible name |
| `size` | enum | `.regular` | `.small`, `.regular`, `.large`: bar thickness, ring and spinner diameter |
| `tone` | enum | `.accent` | `.accent`, `.success`, `.warning`, `.@"error"`: fill color; a spinner is gray unless the tone is not `.accent` |
| `text` | string | `""` | visible caption: above a bar, beside a ring or spinner |
| `show_value` | bool | `false` | percentage: right-aligned above a bar, inside a ring (hidden on `.small` rings) |
| `ring` | bool | `false` | draw a determinate value as a circular ring instead of a bar |

## Notes

- Bars and rings are `role="progressbar"` with `aria-valuenow`; spinners are `role="status"`. Always give a `label`, even when `text` is visible.
- Use `.tone` to say what the number means (green for done, orange for nearly full, red for failed), never as the only signal: pair it with `text`.
- With Reduce Motion the spinner stops and the bar and ring jump to their new value.
- Swap in a new bar with z.js to update it, for example with `z-trigger="load"` polling.
