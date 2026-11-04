# Radio group

A vertical list of choices where exactly one is selected. Use it when the labels are long or there are more than a few; for two to five short choices in a row, use a [segmented control](/components/segmented).

```demo
radio
```

## Usage

```zig
ui.radio(.{ .name = "open", .label = "New windows open with", .options = &.{
    .{ .value = "recent", .label = "Recents", .selected = true },
    .{ .value = "home", .label = "Home folder" },
} })
```

Horizontal, with descriptions and a disabled option:

```zig
ui.radio(.{ .name = "plan", .label = "Plan", .layout = .horizontal, .options = &.{
    .{ .value = "free", .label = "Free", .description = "1 project", .selected = true },
    .{ .value = "team", .label = "Team", .description = "Unlimited" },
    .{ .value = "ent", .label = "Enterprise", .disabled = true },
} })
```

## Props

| Prop | Type | Default | Notes |
|---|---|---|---|
| `name` | string | required | |
| `label` | string | required | accessible group name |
| `options` | `[]const ui.RadioOption` | required | `value`, `label`, `selected`, plus `description` (secondary line, default none) and `disabled` (default `false`) |
| `layout` | `.vertical` `.horizontal` | `.vertical` | `.horizontal` wraps onto new lines on narrow screens |
| `disabled` | bool | `false` | disables the whole group |
| `z` | `ui.Z` | none | sent on `change` |

Arrow keys move between options and each row is at least 44px tall on touch screens.
