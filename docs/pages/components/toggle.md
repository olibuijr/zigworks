# Toggle

A switch for settings that take effect immediately. It is a full settings row: label on the leading side, switch on the trailing side.

```demo
toggle
```

## Usage

```zig
ui.toggle(.{ .name = "wifi", .label = "Wi-Fi", .on = true, .z = .{ .post = "/settings", .swap = .none } })
```

Smaller, with a description and the switch before the label:

```zig
ui.toggle(.{ .name = "bt", .label = "Bluetooth", .description = "Discoverable as Studio", .size = .small, .label_side = .trailing })
```

## Props

| Prop | Type | Default | Notes |
|---|---|---|---|
| `name` | string | required | sends `name=on`; nothing when off |
| `label` | string | required | |
| `on` | bool | `false` | |
| `description` | string | none | secondary line under the label |
| `size` | `.mini` `.small` `.regular` | `.regular` | switch is 30x18, 38x22 or 46x26 |
| `label_side` | `.leading` `.trailing` | `.leading` | `.trailing` puts the switch first, like a checkbox |
| `disabled` | bool | `false` | dimmed, not interactive, not submitted |
| `z` | `ui.Z` | none | sent on `change` |

Rows get at least 44px of height on touch screens. Use a check for items in a list and a toggle for settings.
