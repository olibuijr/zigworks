# Setting

A settings row: a label on the leading side and any control on the trailing side, like System Settings. Rows in a card are separated by hairlines.

```demo
setting
```

## Usage

```zig
ui.card(.{ .body = zw.view("{a}{b}", .{
    .a = ui.setting(.{ .label = "Volume", .control = ui.slider(.{ .name = "volume", .label = "Volume" }) }),
    .b = ui.toggle(.{ .name = "sounds", .label = "Play sounds" }),
}) })
```

With a description and an icon, a disabled row and a navigation row:

```zig
ui.setting(.{ .label = "Appearance", .description = "Applies to every window.", .control = ui.segmented(...) })
ui.setting(.{ .label = "Sync", .disabled = true, .control = ui.stepper(...) })
ui.setting(.{ .label = "Wi-Fi", .icon = "📶", .href = "/wifi", .control = "Home" })
```

## Props

| Prop | Type | Default | Notes |
|---|---|---|---|
| `label` | string | required | text on the leading side |
| `control` | component or string | none | segmented control, slider, picker, button… A string is shown as secondary value text |
| `description` | string | `""` | second line under the label, in secondary text |
| `icon` | string | `""` | a symbol or emoji in an accent tile before the label (decorative) |
| `disabled` | bool | `false` | dims the row and disables the controls inside (the row becomes a `<fieldset disabled>`) |
| `href` | string | `""` | a navigation row: an `<a>` with a chevron after the value text |

## Notes

- A toggle is already a full row, so it doesn't need a setting around it.
- On a navigation row `control` should be a string. A button or field inside a link is not valid HTML.
- A disabled row keeps its text readable for screen readers; only the controls stop responding.
- On touch screens rows are at least 44px tall.
