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

## Props

| Prop | Type | Default | Notes |
|---|---|---|---|
| `name` | string | required | |
| `label` | string | required | accessible group name |
| `options` | `[]const ui.RadioOption` | required | value, label, `selected` |
| `z` | `ui.Z` | none | sent on `change` |
