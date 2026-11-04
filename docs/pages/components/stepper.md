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

With a unit, and a wrapping hour that only the buttons change:

```zig
ui.stepper(.{ .name = "cache", .label = "Cache size", .value = 4, .min = 1, .max = 32, .unit = "GB" })
ui.stepper(.{ .name = "hour", .label = "Hour", .value = 23, .min = 0, .max = 23, .wrap = true, .editable = false })
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
| `unit` | string | none | text after the field, such as `"GB"` |
| `disabled` | bool | `false` | dimmed; field and buttons ignore input |
| `editable` | bool | `true` | `false` makes the field read-only: only the buttons change it, and they become Tab stops |
| `wrap` | bool | `false` | at `max` the + button goes to `min`, and the other way round; the buttons never disable (needs z.js) |

## Notes

- Without JavaScript the buttons do nothing, but an editable field still takes typed numbers and arrow keys. A read-only field then cannot change, so use `editable = false` only on pages that load z.js.
- With an editable field the buttons stay out of the Tab order, since the arrow keys already step the value.
- On touch screens the field and buttons are 44px tall.
