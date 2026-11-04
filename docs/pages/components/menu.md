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

## Props

| Prop | Type | Default | Notes |
|---|---|---|---|
| `id` | string | required | what `button(.{ .opens = id })` refers to |
| `items` | `[]const ui.MenuItem` | required | see below |

Each item: `label`, `z`, `destructive` (red text) and `separated` (a separator above it). End labels that open more UI with an ellipsis: "Share…".
