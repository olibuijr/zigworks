# Picker

A pop-up button that shows a menu of choices, like `NSPopUpButton`. It replaces `<select>` with a styled menu, built from radio buttons and the Popover API, so it works without JavaScript. Options can have icons, a description line, section headings and separators, and can be disabled.

Sort and filter a file list, like the toolbar of a Finder window. Both pickers sit in one form. When either changes, z.js sends both choices and the server answers with the new rows. Pick "Archives" to see the list's empty message.

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

Put `.z` on the picker to send its own choice as it changes. Without `.z` it is a plain form field.

```zig
ui.picker(.{ .id = "sort", .name = "sort", .label = "Sort by", .z = .{ .post = "/prefs", .swap = .none }, .options = ... })
```

To react to several pickers at once, put them in a form and give the form the request. z.js sends every field of the form, so the server sees all the choices:

```zig
zw.view("<form{z}>{sort}{kind}</form><ul id=\"files\"></ul>", .{
    .z = ui.Z{ .get = "/files", .trigger = "change", .target = "#files", .swap = .inner },
    .sort = ui.picker(.{ .id = "sort", .name = "sort", .label = "Sort by", .options = ... }),
    .kind = ui.picker(.{ .id = "kind", .name = "kind", .label = "Show", .options = ... }),
})
```

## Options

Every prop on its own. The label above each picker names the prop it shows. Open the menus to see the icons, descriptions, headings, separators and the disabled item.

```demo
picker-options
```

Placeholder, sections, descriptions and a disabled option in code:

```zig
ui.picker(.{ .id = "group", .name = "group", .label = "Group by", .placeholder = "Group by…", .options = &.{
    .{ .value = "none", .label = "None", .description = "A flat list" },
    .{ .value = "kind", .label = "Kind", .icon = doc_svg, .heading = "Attributes" },
    .{ .value = "tags", .label = "Tags", .separated = true, .disabled = true },
} })
```

The picker has one size, the height of a regular button. It is as wide as its label (at least 120px) up to the width of its container, or the whole container with `full`.

## States

A Settings pane with a picker in every row. Each choice is saved as it changes. The Calendar row has no selected option, so its button shows the placeholder, and its Hebrew option is disabled. The Time zone picker is disabled as a whole.

```demo
picker-states
```

## In a form

A picker submits like a `<select>`: `name=value` for the checked option. A picker with no selected option sends nothing, and so does a disabled one. This form shows what arrived in a toast. Press Add Reminder before choosing a list to see the server's error.

```demo
picker-form
```

## Updating the page

Two pickers in a checkout card. A change re-prices the order: the server returns the new total and, out of band, the plan badge in the card header. The choices travel in the request, the server keeps nothing.

```demo
picker-checkout
```

## Props

| Prop | Type | Default | Notes |
|---|---|---|---|
| `id` | string | required | unique per page |
| `name` | string | required | form field name |
| `label` | string | required | accessible name |
| `options` | `[]const ui.PickerOption` | required | see option fields below |
| `z` | `ui.Z` | none | request sent when the choice changes, with this picker's `name=value`. To send several fields, put the request on the form instead |
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
- There is no multiple choice and no error or loading state. For validation, answer with a toast or text next to the picker, as the form demo does.
