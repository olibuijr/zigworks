# Picker

A pop-up button that shows a menu of choices, like `NSPopUpButton`. It replaces `<select>` with a styled menu, built from radio buttons and the Popover API, so it works without JavaScript.

```demo
picker
```

## Usage

```zig
ui.picker(.{ .id = "sort", .name = "sort", .label = "Sort by", .options = &.{
    .{ .value = "name", .label = "Name", .selected = true },
    .{ .value = "date", .label = "Date Modified" },
} })
```

## Props

| Prop | Type | Default | Notes |
|---|---|---|---|
| `id` | string | required | unique per page |
| `name` | string | required | form field name |
| `label` | string | required | accessible name |
| `options` | `[]const ui.PickerOption` | required | value, label, `selected` |
| `z` | `ui.Z` | none | sent on `change` |

The menu is anchored under the button and at least as wide as it. Choosing an item updates the label and closes the menu.
