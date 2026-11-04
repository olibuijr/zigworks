# Segmented

A segmented control: two to eight mutually exclusive choices, all visible. It is made of radio buttons, so it works with the keyboard (arrow keys) and without JavaScript. The glass pill slides to the chosen segment.

```demo
segmented
```

A Finder-style toolbar. Both controls sit in one form: picking a segment sends the form, and the server draws the file area again in that view and order.

## Sizes and styles

Three sizes, a full-width control, and icons with or without text. Each row names the prop it shows.

```demo
segmented-variants
```

## States

One segment is usually selected. Leave all of them unselected when there is no value yet. Disable a single option, or the whole control. Add `help` text under the control, or an `invalid` message that turns it red. Long labels are cut with an ellipsis.

```demo
segmented-states
```

## Reacting to a choice

Give the control a `z` request and it fires on `change`, with the field name and the chosen value. Here the response swaps the price and, out of band, updates the badge and shows a toast.

```demo
segmented-billing
```

## Filtering a list

A segmented control is a good filter above a list. The response replaces the list and the count badge; the empty state comes from the list's `empty` text.

```demo
segmented-mail
```

## Usage

```zig
ui.segmented(.{ .name = "view", .label = "View", .options = &.{
    .{ .value = "icons", .label = "Icons", .selected = true },
    .{ .value = "list", .label = "List" },
} })
```

Run a request when the choice changes. The value arrives as `?view=list`:

```zig
ui.segmented(.{
    .name = "view",
    .label = "View",
    .full = true,
    .z = .{ .get = "/files", .target = "#files", .swap = .inner },
    .options = &.{
        .{ .value = "icons", .label = "Icons", .selected = true },
        .{ .value = "list", .label = "List" },
    },
})
```

Show a validation error under the control. It outlines the control in red, sets `aria-invalid` and is announced to screen readers:

```zig
ui.segmented(.{ .name = "delivery", .label = "Delivery", .invalid = "Choose a delivery method.", .options = &.{
    .{ .value = "post", .label = "Post" },
    .{ .value = "pickup", .label = "Pickup" },
} })
```

Icons only, small, with a disabled option:

```zig
ui.segmented(.{ .name = "layout", .label = "Layout", .size = .small, .icons_only = true, .options = &.{
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
| `z` | `ui.Z` | none | request sent on `change` (the attributes go on every radio, so each segment fires it), with `name=value` |
| `size` | `.small` / `.regular` / `.large` | `.regular` | control height; touch screens always get 44px |
| `full` | bool | `false` | fill the width of the container, segments stay equal |
| `icons_only` | bool | `false` | hide the text of options that have an icon; it stays for screen readers |
| `disabled` | bool | `false` | disable every segment |
| `help` | string | none | help text under the control |
| `invalid` | string | none | error text under the control (red, replaces `help`); also sets `aria-invalid` and outlines the control |

Option fields:

| Field | Type | Default | Notes |
|---|---|---|---|
| `value` | string | required | submitted value |
| `label` | string | required | segment text |
| `selected` | bool | `false` | mark one option |
| `icon` | string | none | inline SVG markup shown before the label. Trusted markup only, never user input. Use `currentColor` so it follows the text |
| `disabled` | bool | `false` | dimmed and not selectable |

## Notes

- Long labels are cut with an ellipsis instead of overflowing, so the control fits a 390px phone. Screen readers still read the full label, but sighted users cannot, so keep labels short or use a picker.
- While a `z` request is in flight the control dims and ignores clicks (z.js marks the sending radio busy). There is no separate loading prop.
- To send several controls together, put them in a `<form>` with the `z` attributes on the form and `trigger = "change"`, like the first demo.
- Names must be unique on a page: radios with the same `name` form one group.
- With no `selected` option the glass pill is hidden and nothing is submitted until the user picks one.
- With `icons_only`, an option without an icon still shows its text.
- Two to eight options. Any other number panics in every build mode, because the pill could not be placed. For more than five choices, or longer labels, use a picker.
