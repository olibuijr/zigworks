# Picker

A pop-up button that shows a menu of choices, like `NSPopUpButton`. It replaces `<select>` with a styled menu, built from radio buttons and the Popover API, so it works without JavaScript. Options can have icons, a description line, section headings and separators, and can be disabled.

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

Placeholder, sections, descriptions and a disabled option:

```zig
ui.picker(.{ .id = "group", .name = "group", .label = "Group by", .placeholder = "Group by…", .options = &.{
    .{ .value = "none", .label = "None", .description = "A flat list" },
    .{ .value = "kind", .label = "Kind", .icon = doc_svg, .heading = "Attributes" },
    .{ .value = "tags", .label = "Tags", .separated = true, .disabled = true },
} })
```

## Props

| Prop | Type | Default | Notes |
|---|---|---|---|
| `id` | string | required | unique per page |
| `name` | string | required | form field name |
| `label` | string | required | accessible name |
| `options` | `[]const ui.PickerOption` | required | see option fields below |
| `z` | `ui.Z` | none | sent on `change` |
| `placeholder` | string | none | dimmed text shown while no option is `selected`; without it the button shows the first label |
| `disabled` | bool | `false` | dimmed, cannot open, submits nothing (like a disabled `<select>`) |
| `full` | bool | `false` | stretch the button to the width of its container |

Option fields:

| Field | Type | Default | Notes |
|---|---|---|---|
| `value` | string | required | submitted value |
| `label` | string | required | menu text and button text |
| `selected` | bool | `false` | mark one option |
| `icon` | string | none | inline SVG markup before the label, in the menu only. Trusted markup, never user input. Use `currentColor` |
| `description` | string | none | a smaller second line under the label |
| `disabled` | bool | `false` | dimmed and not selectable |
| `separated` | bool | `false` | hairline above this option |
| `heading` | string | none | section heading above this option |

## Notes

- The menu is anchored under the button and at least as wide as it. It scrolls when taller than 60% of the screen, and its items are 44px tall on touch screens.
- Choosing an item updates the label and closes the menu. The button shows only the label, so icons and descriptions stay in the menu.
- Screen readers hear "Sort by: Name" on the button; the menu is a radio group with the same name.
- Mark one option `selected` unless you pass a `placeholder`, so what the button shows is what the form submits.
