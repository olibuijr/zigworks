# Sheet

A modal panel for a short task, opened by a button. It uses the Popover API: Esc and clicking outside close it, without JavaScript. After a form inside it submits, z.js closes it.

```demo
sheet
```

## Usage

```zig
zw.view("{open}{sheet}", .{
    .open = ui.button(.{ .label = "Rename…", .opens = "rename" }),
    .sheet = ui.sheet(.{
        .id = "rename",
        .title = "Rename Project",
        .description = "Names can be changed any time.",
        .size = .small,
        .close = true,
        .body = form,
    }),
})
```

Put the buttons in `<div class="zw-sheet-actions">` inside the form so they line up on the trailing edge, with the default action last. For buttons that are not part of a form, pass them as `footer`.

## Props

| Prop | Type | Default | Notes |
|---|---|---|---|
| `id` | string | required | what `button(.{ .opens = id })` refers to |
| `title` | string | required | heading and accessible name |
| `body` | component | required | usually a form |
| `size` | `.small` / `.medium` / `.large` | `.medium` | width of 360, 480 or 640 px; never wider than the screen minus 32 px |
| `description` | string | `""` | secondary text under the title; also the accessible description |
| `footer` | component | none | an action row after the body, aligned to the trailing edge. Use it for buttons outside a form |
| `close` | bool | `false` | a round close button in the corner (44 px on touch screens) |
| `close_label` | string | `"Close"` | accessible name of the close button, for other languages |
| `focus_first` | bool | `true` | z.js focuses the first field of the sheet when it opens; `false` leaves focus on the opening button |

## Notes

- The sheet is labelled by its title (`aria-labelledby`) and described by `description` (`aria-describedby`).
- A tall sheet scrolls inside itself instead of running off the screen.
- Several sheets can live on one page; give each its own `id`.
- Close a sheet from any button with `opens = id` (it toggles) or `popovertarget="id" popovertargetaction="hide"`.
