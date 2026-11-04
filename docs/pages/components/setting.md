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

## Props

| Prop | Type | Default | Notes |
|---|---|---|---|
| `label` | string | required | text on the leading side |
| `control` | component | required | segmented control, slider, picker, button… |

A toggle is already a full row, so it doesn't need a setting around it.
