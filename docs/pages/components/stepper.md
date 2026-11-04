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

## Options

A stepper takes a `unit`, a `step` size, and can be read-only or wrapping. Each row below names the prop it shows.

```demo
stepper-props
```

```zig
ui.stepper(.{ .name = "cache", .label = "Cache size", .value = 4, .min = 1, .max = 32, .unit = "GB" })
ui.stepper(.{ .name = "opacity", .label = "Opacity", .value = 80, .min = 0, .max = 100, .step = 10, .unit = "%" })
ui.stepper(.{ .name = "hour", .label = "Hour", .value = 23, .min = 0, .max = 23, .wrap = true, .editable = false })
```

## States

At `min` the − button turns off, and at `max` the + button does. A wrapping stepper never turns its buttons off. `disabled` dims the stepper and ignores input; a disabled `ui.setting` row does the same to everything in it.

```demo
stepper-states
```

## Saving a total

Put the steppers in a form and put the `z` request on the form with `trigger = "change"`. Every step sends all the quantities, so the server can add them up. Here the reply swaps the summary and updates the badge out of band. Nothing is kept on the server.

```demo
stepper-cart
```

```zig
fn cart(c: *zw.Ctx) !void {
    const notebooks = std.fmt.parseInt(i64, c.form("notebook") orelse "", 10) catch 0;
    // ...add up the rows, then answer with the summary and a badge with .oob = true
}
```

## With a switch

Read-only steppers suit values that wrap, such as time. The form below holds two steppers and a toggle. The toggle sends `on` when it is switched on and nothing when off.

```demo
stepper-alarm
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
- Typed values are not clamped to `min` and `max` in the page. Check them on the server, as the cart does.
- On touch screens the field and buttons are 44px tall.
