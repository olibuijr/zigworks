# Slider

A continuous value in a range. The track fills up to the thumb in the accent color.

```demo
slider
```

## Usage

```zig
ui.setting(.{ .label = "Volume", .control = ui.slider(.{
    .name = "volume", .label = "Volume", .value = 70, .z = .{ .post = "/settings", .swap = .none },
}) })
```

## Props

| Prop | Type | Default | Notes |
|---|---|---|---|
| `name` | string | required | |
| `label` | string | required | accessible name |
| `min` | i64 | `0` | |
| `max` | i64 | `100` | |
| `step` | i64 | `1` | |
| `value` | i64 | `50` | |
| `z` | `ui.Z` | none | sent on `change`, when the thumb is released |
