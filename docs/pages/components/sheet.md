# Sheet

A modal panel for a short task, opened by a button. It uses the Popover API: Esc and clicking outside close it, without JavaScript. After a form inside it submits, z.js closes it.

```demo
sheet
```

## Usage

```zig
zw.view("{open}{sheet}", .{
    .open = ui.button(.{ .label = "Rename…", .opens = "rename" }),
    .sheet = ui.sheet(.{ .id = "rename", .title = "Rename Project", .body = form }),
})
```

Put the buttons in `<div class="zw-sheet-actions">` so they line up on the trailing edge, with the default action last.

## Props

| Prop | Type | Default | Notes |
|---|---|---|---|
| `id` | string | required | what `button(.{ .opens = id })` refers to |
| `title` | string | required | heading and accessible name |
| `body` | component | required | usually a form |
