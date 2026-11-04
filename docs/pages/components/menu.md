# Menu

A pull-down menu of actions, opened by a button. Items send z.js requests; the menu closes after each one.

```demo
menu
```

## Usage

```zig
zw.view("{b}{m}", .{
    .b = ui.button(.{ .label = "Actions", .opens = "actions" }),
    .m = ui.menu(.{ .id = "actions", .items = &.{
        .{ .label = "Duplicate", .z = .{ .post = "/dup" } },
        .{ .label = "Move to Trash", .destructive = true, .separated = true, .z = .{ .delete = "/item" } },
    } }),
})
```

A view menu with checkmarks, section headers, a shortcut hint and a link:

```zig
ui.menu(.{ .id = "view", .label = "View", .alignment = .end, .items = &.{
    .{ .label = "Show Sidebar", .checked = true, .shortcut = "⌘B", .header = "Layout", .z = .{ .post = "/sidebar" } },
    .{ .label = "Show Toolbar", .checked = false, .z = .{ .post = "/toolbar" } },
    .{ .label = "Archive", .disabled = true },
    .{ .label = "Documentation", .href = "/docs", .separated = true },
} })
```

## Props

| Prop | Type | Default | Notes |
|---|---|---|---|
| `id` | string | required | what `button(.{ .opens = id })` refers to |
| `items` | `[]const ui.MenuItem` | required | see below |
| `label` | string | `""` | accessible name of the menu, usually the button's label |
| `alignment` | enum | `.start` | `.start` or `.end`: which edge of the button the menu lines up with; use `.end` near the right edge of the window |

Each item:

| Field | Type | Default | Notes |
|---|---|---|---|
| `label` | string | required | end labels that open more UI with an ellipsis: "Share…" |
| `z` | `ui.Z` | none | z.js request; the menu closes after it fires |
| `destructive` | bool | `false` | red text, red highlight |
| `separated` | bool | `false` | a separator above the item |
| `icon` | string | `""` | inline SVG (trusted, `currentColor`); if any item has one, all labels line up |
| `shortcut` | string | `""` | hint such as `⌘D`, shown at the end; it does not bind the key |
| `checked` | `?bool` | `null` | `null` is a normal item; `false`/`true` make a checkable item (`menuitemcheckbox`) with a checkmark when true |
| `disabled` | bool | `false` | greyed out, not focusable |
| `header` | string | `""` | section header above the item |
| `href` | string | `""` | renders a link (`<a role="menuitem">`) instead of a button |

## Notes

- Destructive actions go last, below a separator.
- Show a shortcut only if it really works; keep the order modifier keys use on the Mac: ⌃ ⌥ ⇧ ⌘.
- Items are 44px tall on touch screens.
- A checkable item only shows state. Have its `z` request re-render the menu or the page so the checkmark follows.
