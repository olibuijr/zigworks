# Segmented

A segmented control: two to eight mutually exclusive choices, all visible. It is made of radio buttons, so it works with the keyboard (arrow keys) and without JavaScript. The glass pill slides to the chosen segment.

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

Icons only, small, with a disabled option:

```zig
ui.segmented(.{ .name = "layout", .label = "Layout", .icons_only = true, .options = &.{
    .{ .value = "grid", .label = "Grid", .icon = grid_svg, .selected = true },
    .{ .value = "rows", .label = "Rows", .icon = rows_svg },
    .{ .value = "map", .label = "Map", .icon = map_svg, .disabled = true },
} })
```

## Props

| Prop | Type | Default | Notes |
|---|---|---|---|
| `name` | string | required | form field name |
| `label` | string | required | accessible group name |
| `options` | `[]const ui.SegmentedOption` | required | see option fields below |
| `z` | `ui.Z` | none | sent on `change` |
| `size` | `.small` / `.regular` / `.large` | `.regular` | control height; touch screens always get 44px |
| `full` | bool | `false` | fill the width of the container, segments stay equal |
| `icons_only` | bool | `false` | hide the text of options that have an icon; it stays for screen readers |
| `disabled` | bool | `false` | disable every segment |

Option fields:

| Field | Type | Default | Notes |
|---|---|---|---|
| `value` | string | required | submitted value |
| `label` | string | required | segment text |
| `selected` | bool | `false` | mark one option |
| `icon` | string | none | inline SVG markup shown before the label. Trusted markup only, never user input. Use `currentColor` so it follows the text |
| `disabled` | bool | `false` | dimmed and not selectable |

## Notes

- Long labels are cut with an ellipsis instead of overflowing, so the control fits a 390px phone.
- With `icons_only`, an option without an icon still shows its text.
- At most eight options. For more than five choices, or longer labels, use a picker.
