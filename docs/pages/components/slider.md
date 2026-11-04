# Slider

A continuous value in a range. The track fills up to the thumb in the accent color; pressing the thumb turns it into a clear glass lens. Optional tick marks, end labels and a live value readout.

```demo
slider
```

## Usage

```zig
ui.setting(.{ .label = "Volume", .control = ui.slider(.{
    .name = "volume", .label = "Volume", .value = 70, .z = .{ .post = "/settings", .swap = .none },
}) })
```

Discrete steps with tick marks, end labels and a readout:

```zig
ui.slider(.{
    .name = "quality", .label = "Quality", .min = 0, .max = 4, .value = 2,
    .ticks = 4, .min_label = "Low", .max_label = "High",
})

ui.slider(.{ .name = "size", .label = "Text size", .min = 10, .max = 20, .value = 13, .show_value = true, .unit = " pt" })
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
| `disabled` | bool | `false` | dimmed, ignores pointer and keyboard |
| `ticks` | u8 | `0` | number of intervals along the track: `4` draws 5 marks. Pick a count that divides the range by `step` so the thumb lands on a mark |
| `min_label` | string | none | text before the track, such as "Quiet" |
| `max_label` | string | none | text after the track, such as "Loud" |
| `show_value` | bool | `false` | value readout on the right, kept in sync while dragging |
| `unit` | string | none | appended to the readout, such as `"%"` or `" pt"` |

## Notes

- The starting fill is written by the server, so the track is right on first paint and without JavaScript.
- Tick marks, end labels and the readout are decorative: screen readers get the slider's name and value, not the extras.
- On touch screens the slider is 44px tall, so the thumb is easy to grab.
- The readout updates while dragging only with the client script (z.js); without it, it shows the starting value.
