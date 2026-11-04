# Slider

A continuous value in a range. The track fills up to the thumb in the accent color; pressing the thumb turns it into a clear glass lens. Optional tick marks, end labels and a live value readout.

A Sound pane. Each slider saves when you let go of the thumb.

```demo
slider
```

## Usage

```zig
ui.setting(.{ .label = "Volume", .control = ui.slider(.{
    .name = "volume", .label = "Volume", .value = 70, .z = .{ .post = "/settings", .swap = .none },
}) })
```

`label` is the accessible name. Put the visible label in a `ui.setting` row, as above, or next to the slider yourself.

## Extras

Each row below turns on one thing: end labels, a readout, tick marks, or a custom range and step.

```demo
slider-extras
```

```zig
ui.slider(.{ .name = "ends", .label = "End labels", .min_label = "Quiet", .max_label = "Loud" })

ui.slider(.{ .name = "readout", .label = "Value readout", .value = 72, .show_value = true, .unit = "%" })

ui.slider(.{ .name = "quality", .label = "Quality", .min = 0, .max = 4, .value = 2, .ticks = 4 })

ui.slider(.{ .name = "delay", .label = "Delay", .min = 0, .max = 500, .step = 50, .value = 200, .ticks = 10, .show_value = true, .unit = " ms" })
```

## States

A slider can sit at either end of its range, be disabled, or be disabled by its settings row.

```demo
slider-states
```

```zig
ui.slider(.{ .name = "off", .label = "Disabled", .value = 40, .disabled = true })

ui.setting(.{ .label = "Brightness", .disabled = true, .control = ui.slider(.{ .name = "locked", .label = "Brightness", .value = 80 }) })
```

## Live updates

By default `z` fires on `change`, when the thumb is released. Use `.trigger = "input"` to send while dragging (z.js waits for a short pause). The handler answers with elements that carry `z-oob` and an `id`, and z.js swaps them in anywhere on the page. Here the preview text and the badge both update.

```demo
slider-text-size
```

```zig
ui.slider(.{
    .name = "size", .label = "Text size", .min = 10, .max = 24, .value = 13,
    .show_value = true, .unit = " pt",
    .z = .{ .post = "/demo/slider/text-size", .trigger = "input", .swap = .none },
})
```

```zig
fn textSize(c: *zw.Ctx) !void {
    const px = std.fmt.parseInt(i64, c.form("size") orelse "13", 10) catch 13;
    try c.html("{preview}{badge}", .{ .preview = sample(px, true), .badge = sizeBadge(px, true) });
}
```

## In a form

Sliders work in forms like any input. Put the `z` on the form with `.trigger = "change"` and every control is sent whenever one of them changes. This export sheet combines a segmented control, two sliders and a badge that shows the estimated size.

```demo
slider-export
```

```zig
ui.card(.{
    .title = "Export Photo",
    .body = zw.view("{format}{quality}{estimate}", .{
        .format = ui.setting(.{ .label = "Format", .control = ui.segmented(.{ .name = "format", .label = "Format", .options = &formats }) }),
        .quality = ui.setting(.{ .label = "Quality", .control = ui.slider(.{ .name = "quality", .label = "Quality", .min = 20, .max = 100, .step = 20, .value = 60, .ticks = 4 }) }),
        .estimate = ui.setting(.{ .label = "Estimated size", .control = ui.badge(.{ .text = "2.7 MB", .id = "estimate" }) }),
    }),
})
```

Wrap the card in `<form{z}>` with `ui.Z{ .post = "/estimate", .trigger = "change", .swap = .none, .keep = true }`. `keep` stops z.js from resetting the form after a successful send.

## Props

| Prop | Type | Default | Notes |
|---|---|---|---|
| `name` | string | required | form field name |
| `label` | string | required | accessible name |
| `min` | i64 | `0` | |
| `max` | i64 | `100` | |
| `step` | i64 | `1` | |
| `value` | i64 | `50` | |
| `z` | `ui.Z` | none | sent on `change`, when the thumb is released; add `.trigger = "input"` to send while dragging |
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
- The readout is as wide as the longest value plus the unit, so the track does not shift while you drag.
- The readout updates while dragging only with the client script (z.js); without it, it shows the starting value.
- A slider has one size, like the macOS control, and no loading, error or mixed state. Use `disabled` to lock it.
- Dragging fires native `input` events that bubble to a form. A `z` with `.trigger = "input"` on a form is debounced by z.js (a short pause), so it does not send on every tick.
- A form that posts is reset by z.js after a successful reply. Set `.keep = true` on its `z` or the slider snaps back to its starting value.
- Replacing a slider from the server (an `oob` swap) re-creates the element, which drops focus and any drag in progress. Swap its surrounding row when a slider must change live, and not while the user holds it.
- Inside a `ui.setting` row the slider is at most 240px wide and wraps under the label on narrow screens.
