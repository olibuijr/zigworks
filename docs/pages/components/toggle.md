# Toggle

A switch for settings that take effect immediately. It is a full settings row: label on the leading side, switch on the trailing side.

```demo
toggle
```

## Usage

```zig
ui.toggle(.{ .name = "wifi", .label = "Wi-Fi", .on = true, .z = .{ .post = "/settings", .swap = .none } })
```

## Props

| Prop | Type | Default | Notes |
|---|---|---|---|
| `name` | string | required | sends `name=on`; nothing when off |
| `label` | string | required | |
| `on` | bool | `false` | |
| `z` | `ui.Z` | none | sent on `change` |

Use a check for items in a list and a toggle for settings.
