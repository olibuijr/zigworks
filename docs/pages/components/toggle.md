# Toggle

A switch for settings that take effect immediately. It is a full settings row: label on the leading side, switch on the trailing side. Under the hood it is a real checkbox, so it works in forms, with the keyboard and with screen readers.

```demo
toggle
```

## Usage

Give it a `name` and a `label`. With `z`, z.js sends the request whenever the switch changes, with `name=on` when it is switched on and nothing when it is off.

```zig
ui.toggle(.{ .name = "wifi", .label = "Wi-Fi", .on = true, .z = .{ .post = "/settings", .swap = .none } })
```

Toggles stack with hairline separators, so put several in a card to get a settings pane:

```zig
ui.card(.{ .title = "Mail Notifications", .body = zw.view("{a}{b}", .{
    .a = ui.toggle(.{ .name = "allow", .label = "Allow Notifications", .on = true, .z = d.save }),
    .b = ui.toggle(.{ .name = "sound", .label = "Play Sound", .z = d.save }),
}) })
```

## Sizes and label side

`size` picks the switch: regular, small or mini. `label_side` puts the switch before the label, like a checkbox. Each row below names the prop that sets it.

```demo
toggle-variants
```

```zig
ui.toggle(.{ .name = "bt", .label = "Bluetooth", .description = "Discoverable as Studio", .size = .small, .label_side = .trailing })
```

## States

A toggle is off or on. `disabled` dims it and stops it from being used or submitted, which suits settings an administrator controls. While a request is in flight z.js dims the row, so a slow save looks busy.

```demo
toggle-states
```

## Updating the page

A toggle can do more than save. The request below answers with a badge that replaces the one in the card header (`oob`) and a toast. An unchecked switch sends nothing, so the handler reads a missing field as off.

```demo
toggle-focus
```

```zig
fn focus(c: *zw.Ctx) !void {
    const on = c.form("focus") != null;
    try c.html("{badge}{toast}", .{
        .badge = ui.badge(.{ .id = "focus-badge", .oob = true, .text = if (on) "On" else "Off" }),
        .toast = ui.toast(.{ .text = if (on) "Do Not Disturb is on" else "Do Not Disturb is off" }),
    });
}
```

## With a list

Aim the request at a container with `target` and swap its content. Here the switch decides whether the card shows the network list or an empty state.

```demo
toggle-wifi
```

```zig
ui.toggle(.{ .name = "wifi", .label = "Wi-Fi", .on = true, .z = .{ .post = "/wifi", .target = "#networks", .swap = .inner } })
```

## In a form

Toggles without `z` are plain form fields. Put them in a form and a Save button sends them together. Disabled switches are not submitted.

```demo
toggle-form
```

```zig
fn prefs(c: *zw.Ctx) !void {
    const analytics = c.form("analytics") != null;
    // ...
}
```

## Props

| Prop | Type | Default | Notes |
|---|---|---|---|
| `name` | string | required | sends `name=on`; nothing when off |
| `label` | string | required | |
| `on` | bool | `false` | initial state |
| `description` | string | none | secondary line under the label |
| `size` | `.mini` `.small` `.regular` | `.regular` | switch is 30x18, 38x22 or 46x26 |
| `label_side` | `.leading` `.trailing` | `.leading` | `.trailing` puts the switch first, like a checkbox |
| `disabled` | bool | `false` | dimmed, not interactive, not submitted |
| `z` | `ui.Z` | none | sent on `change` |

Rows get at least 44px of height on touch screens. Use a check for items in a list and a toggle for settings.
