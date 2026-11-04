# Setting

A settings row: a label on the leading side and any control on the trailing side, like System Settings. Rows in a card are separated by hairlines.

```demo
setting
```

The Sound pane above is one card with four rows. The volume slider and the alert picker are controls inside `setting` rows. The toggle is already a full row, so it sits in the card on its own. The last row is a navigation row.

## Usage

```zig
ui.card(.{ .title = "Sound", .body = zw.view("{a}{b}", .{
    .a = ui.setting(.{ .label = "Output volume", .icon = "🔊", .control = ui.slider(.{ .name = "volume", .label = "Output volume" }) }),
    .b = ui.toggle(.{ .name = "feedback", .label = "Play feedback when volume is changed" }),
}) })
```

With a description and an icon, a disabled row and a navigation row:

```zig
ui.setting(.{ .label = "Appearance", .description = "Applies to every window.", .control = ui.segmented(...) })
ui.setting(.{ .label = "Sync", .disabled = true, .control = ui.stepper(...) })
ui.setting(.{ .label = "Wi-Fi", .icon = "📶", .href = "/wifi", .control = "Home" })
```

## Rows

Only `label` is required. `description` adds a second line, `icon` adds a tile before the label, and `control` is a component or a plain string. A string is shown as secondary value text. With `href` the row becomes a link with a chevron.

```demo
setting-rows
```

## States

`disabled` dims the row and disables every control inside it. A disabled row with an `href` is not a link. A button can show `loading`, and a badge makes a good read-only control. Leave `control` out for a row that only informs. For an invalid value, put a field with `invalid` in the row.

```demo
setting-states
```

## Live rows

Controls in a row send requests like anywhere else. Here the toggle sends `POST /demo/setting/night`. The response replaces the Warmth row (now enabled or disabled) and the badge, and adds a toast, all out of band. The slider updates the badge as you drag. The button swaps its own row. The server keeps no state: everything the next request needs is in the request.

```demo
setting-live
```

```zig
ui.toggle(.{ .name = "night", .label = "Night Shift", .z = .{ .post = "/night", .swap = .none } })

// The handler answers with a replacement row. A switched-off checkbox sends nothing.
fn night(c: *zw.Ctx) !void {
    const on = c.form("night") != null;
    try c.page(zw.view("<div id=\"warmth\" z-oob>{row}</div>", .{
        .row = ui.setting(.{ .label = "Warmth", .disabled = !on, .control = ui.slider(...) }),
    }));
}
```

## In a form

A settings form is a card of rows with a Save button in the footer. The form posts with `.keep = true`, so the values stay after saving. The handler answers with a toast.

```demo
setting-mail
```

## Props

| Prop | Type | Default | Notes |
|---|---|---|---|
| `label` | string | required | text on the leading side |
| `control` | component or string | none | segmented control, slider, picker, stepper, button, field, badge… A string is shown as secondary value text |
| `description` | string | `""` | second line under the label, in secondary text |
| `icon` | string | `""` | a symbol or emoji in an accent tile before the label (decorative) |
| `disabled` | bool | `false` | dims the row and disables the controls inside (the row becomes a `<fieldset disabled>`) |
| `href` | string | `""` | a navigation row: an `<a>` with a chevron after the value text. Ignored while `disabled` |

## Notes

- A toggle is already a full row, so it doesn't need a setting around it.
- On a navigation row `control` should be a string. A button or field inside a link is not valid HTML.
- A disabled row keeps its text readable for screen readers; only the controls stop responding.
- A setting has no `id` or `z` of its own. To update one from a response, wrap it in an element with an `id` and swap that.
- On touch screens rows are at least 44px tall.
