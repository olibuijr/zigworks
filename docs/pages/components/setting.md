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

Only `label` is required. `description` adds a second line, `icon` adds a tile before the label (`tint` colours it: `.red`, `.green`, `.orange`, `.gray`, default accent), and `control` is a component or a plain string. A string is shown as secondary value text. With `href` the row becomes a link with a chevron.

```demo
setting-rows
```

## States

`disabled` dims the row and disables every control inside it. A disabled row with an `href` keeps its chevron but is not a link. A button can show `loading`, and a badge makes a good read-only control. Leave `control` out for a row that only informs. For an invalid value, put a field with `invalid` in the row.

```demo
setting-states
```

## Live rows

Controls in a row send requests like anywhere else. Here the toggle sends `POST /demo/setting/night`. The response replaces the Warmth row (now enabled or disabled; the row has an `id` and `oob`) and the badge, and adds a toast, all out of band. The slider updates the badge as you drag. The button swaps its own row (`id` plus `.swap = .outer`). The server keeps no state: everything the next request needs is in the request.

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
| `id` | string | `""` | element id, so a request can target the row or a response can replace it |
| `oob` | bool | `false` | out-of-band: a response containing the row replaces the element with the same `id` |
| `description` | string | `""` | second line under the label, in secondary text |
| `icon` | string | `""` | a symbol or emoji in an accent tile before the label (decorative) |
| `tint` | `.accent`, `.red`, `.green`, `.orange`, `.gray` | `.accent` | colour of the icon tile |
| `disabled` | bool | `false` | dims the row and disables the controls inside (the row becomes a `<fieldset disabled>`) |
| `href` | string | `""` | a navigation row: an `<a>` with a chevron after the value text. While `disabled` the chevron stays but the row is not a link |

## Notes

- A toggle is already a full row, so it doesn't need a setting around it.
- On a navigation row `control` should be a string. A button or field inside a link is not valid HTML.
- A disabled row keeps its text readable for screen readers; only the controls stop responding.
- A setting has an `id` and `oob` but no `z`: the row itself does not send requests, its controls do. To replace a row from a response, give it an `id` and answer with the row (`oob`, or `.swap = .outer` on the request). Replace the row directly, not through a wrapper, so the hairline between neighbouring rows stays.
- Replacing a row replaces its controls, so a control that has focus loses it. Update only the rows that depend on it, never the control that was just used: its `z` can use `.swap = .none` and the response carries the other rows out of band.
- On touch screens rows are at least 44px tall.
