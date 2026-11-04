# Skeleton

Placeholder lines with a soft shimmer while content loads. Pair it with `z-trigger="load"` so the real content replaces it as soon as it arrives.

```demo
skeleton
```

## Usage

```zig
// The page renders the skeleton; z.js loads the real content right away.
zw.view("<div z-get=\"/feed\" z-trigger=\"load\" z-swap=\"outer\">{s}</div>", .{ .s = ui.skeleton(.{ .lines = 4 }) })
```

## Props

| Prop | Type | Default | Notes |
|---|---|---|---|
| `lines` | u8 | `3` | the last line is shorter |
| `label` | string | `"Loading"` | announced to screen readers |

With Reduce Motion, the shimmer stops and the lines stay still.
