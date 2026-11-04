# Segmented

A segmented control: two to five mutually exclusive choices, all visible. It is made of radio buttons, so it works with the keyboard and without JavaScript.

```demo
segmented
```

## Usage

```zig
ui.segmented(.{ .name = "view", .label = "View", .options = &.{
    .{ .value = "icons", .label = "Icons", .selected = true },
    .{ .value = "list", .label = "List" },
} })
```

## Props

| Prop | Type | Default | Notes |
|---|---|---|---|
| `name` | string | required | form field name |
| `label` | string | required | accessible group name |
| `options` | `[]const ui.SegmentedOption` | required | value, label, `selected` |
| `z` | `ui.Z` | none | sent on `change` |

For more than five choices, use a picker.
