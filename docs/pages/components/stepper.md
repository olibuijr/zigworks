# Stepper

A number field with − and + buttons, for small counts and sizes. The buttons disable at `min` and `max`. Each step fires `input` and `change`, so a `z` request saves the new value.

```demo
stepper
```

## Usage

```zig
ui.setting(.{ .label = "Copies", .control = ui.stepper(.{
    .name = "copies", .label = "Copies", .value = 1, .min = 1, .max = 99,
    .z = .{ .post = "/settings", .swap = .none },
}) })
```

## Props

| Prop | Type | Default | Notes |
|---|---|---|---|
| `name` | string | required | |
| `label` | string | required | accessible name; also names the buttons |
| `value` | i64 | `0` | |
| `min` | i64 | `0` | |
| `max` | i64 | `100` | |
| `step` | i64 | `1` | |
| `z` | `ui.Z` | none | sent on `change` |

Without JavaScript the buttons do nothing, but the field still takes typed numbers and arrow keys.
