# Sheet

A modal panel for a short task, opened by a button. It uses the Popover API: Esc and clicking outside close it, without JavaScript. After a form inside it submits, z.js closes it.

This one is a Finder-style folder list. "New Folder…" opens a sheet with a form. The server answers with a new row and a toast, and z.js adds both to the page.

```demo
sheet
```

## Usage

```zig
zw.view("{open}{sheet}", .{
    .open = ui.button(.{ .label = "New Folder…", .opens = "new-folder" }),
    .sheet = ui.sheet(.{
        .id = "new-folder",
        .title = "New Folder",
        .description = "Name it now; you can rename it later.",
        .size = .small,
        .close = true,
        .body = form,
    }),
})
```

Put the buttons in `<div class="zw-sheet-actions">` inside the form so they line up on the trailing edge, with the default action last. For buttons that are not part of a form, pass them as `footer`; for two or more, join them with a view such as `zw.view("{cancel}{ok}", .{ ... })`.

## Sizes

`size` sets the width. Use `.small` for a question, `.medium` (the default) for a short form and `.large` for lists or previews. On a phone every size shrinks to the screen width minus 32 px.

```demo
sheet-sizes
```

## Close button, focus and accessibility

`close` adds a round close button in the corner; `close_label` is its accessible name, so set it for other languages. When the sheet opens, z.js moves focus to the first field. Set `focus_first = false` to leave focus on the button that opened it, which suits sheets without a form. The last sheet shows a body in an error state: the field's `invalid` text and a disabled action.

```demo
sheet-options
```

## Footer actions

When the actions are not part of a form, pass them as `footer`. A button with a `z` request still closes the sheet once the request succeeds, so a confirmation needs no extra code. Here the footer's Delete button sends `DELETE /demo/sheet/project`. The response carries a toast with an Undo action that puts the row back.

```demo
sheet-delete
```

## Composition

A sheet usually sits inside a larger screen. This team card combines a card, a badge, a list, avatars, a segmented control, a toggle and a toast. The form's response holds the new row, and out-of-band elements that update the badge and a hidden field with the new head count. The email field uses the browser's own validation, so a bad address never reaches the server.

```demo
sheet-invite
```

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
- z.js closes the sheet after any successful request from inside it, including a footer button's `z`. A failed request leaves it open. To show validation errors, use the browser's own validation (`required`, `type`, `pattern`) so an invalid form is never sent. To show a server-side error inside the sheet, answer with the `z-keep-open` header (`try c.setHeader("z-keep-open", "1")`) and swap the message in; add `z-keep` too so the form keeps what was typed. A `z-keep-open` attribute on the element keeps the sheet open after every request it sends.
- A sheet has no busy state of its own. While a request from a form or button inside it runs, z.js dims that element (`zw-busy`) and ignores clicks on it; use `loading` on the submit button for a spinner.
- The sheet positions itself with `margin`, which a parent's own sibling-spacing rule cannot override.
