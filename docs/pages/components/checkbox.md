# Checkbox

A macOS checkbox with a visible label, for options in forms and settings. The mark springs in. For marking list items done, use the round [check](/components/check).

```demo
checkbox
```

## Usage

```zig
ui.checkbox(.{ .name = "spell", .label = "Check spelling while typing", .on = true })
```

## Props

| Prop | Type | Default | Notes |
|---|---|---|---|
| `name` | string | required | |
| `label` | string | required | shown next to the box |
| `value` | string | `"on"` | sent when checked; nothing is sent when unchecked |
| `on` | bool | `false` | |
| `z` | `ui.Z` | none | sent on `change` |
