# Menu

A pull-down menu of actions, opened by a button. Items send z.js requests; the menu closes after each one.

Every row below has its own menu. Open one, duplicate or share a file, or move it to the Trash and undo from the toast.

```demo
menu
```

## Usage

A menu is two parts: a button with `opens` set to the menu's `id`, and the menu itself. The browser's Popover API shows it next to the button, so there is no JavaScript to write, and light dismiss and Esc work.

```zig
zw.view("{b}{m}", .{
    .b = ui.button(.{ .label = "Actions", .opens = "actions" }),
    .m = ui.menu(.{ .id = "actions", .items = &.{
        .{ .label = "Duplicate", .z = .{ .post = "/dup" } },
        .{ .label = "Move to Trash", .destructive = true, .separated = true, .z = .{ .delete = "/item" } },
    } }),
})
```

## Features

Each menu below turns on one or two item fields. The caption names them.

```demo
menu-variants
```

`alignment` picks the button edge the menu lines up with. Use `.end` for a button near the right edge of the window, such as a row's actions button or a toolbar. The menu also flips to the other side by itself when it would leave the screen.

## States

Disabled items stay visible but are skipped by the pointer and the keyboard. A disabled link is dimmed and marked `aria-disabled`. When there is nothing to choose from, disable the button instead of the menu. If any item has a checkmark, the other items are indented to line up with the labels. Long labels are cut with an ellipsis.

```demo
menu-states
```

## Checkmarks that follow

A checkable item only shows state. To make it change, point each item's `z` at a handler that returns the new menu, and use `.target` with `.swap = .outer` so the menu replaces itself. Anything else in the same response with `z-oob` and an `id` is swapped in too. Here each item carries the state it would produce, so the server keeps nothing.

```demo
menu-view
```

```zig
// Item: flip one flag and post the whole state.
.{ .label = "Sidebar", .checked = st.sidebar, .header = "Show", .z = .{
    .post = "/view?s=0&t=1&b=0&o=name",
    .target = "#view-menu",
    .swap = .outer,
} },

// Handler: answer with the new menu and the preview.
fn view(c: *zw.Ctx) !void {
    const st = parse(c);
    try c.html("{menu}{preview}", .{ .menu = viewMenu(c.arena, st), .preview = preview(st) });
}
```

## In an inbox

A menu rarely works alone. This inbox combines it with a list, avatars and a count badge. One request changes the filter, the unread count and the marks on the menu, and it disables "Mark All as Read" once nothing is unread. The menu is on the right edge of the card, so it uses `alignment = .end`.

```demo
menu-inbox
```

```zig
fn mail(c: *zw.Ctx) !void {
    const st = apply(c); // unread bits and filter come from the query
    try c.html("{menu}{badge}{body}", .{
        .menu = try mailMenu(c.arena, st),   // swapped by the item's own z
        .badge = mailBadge(st, true),        // ui.badge(.{ .id = "count", .oob = true, ... })
        .body = mailBody(st, true),          // <div id="mailbox" z-oob>…</div>
    });
}
```

## Props

| Prop | Type | Default | Notes |
|---|---|---|---|
| `id` | string | required | what `button(.{ .opens = id })` refers to; also names the anchor, so it must be a valid CSS identifier |
| `items` | `[]const ui.MenuItem` | required | see below |
| `label` | string | `""` | accessible name of the menu, usually the button's label |
| `alignment` | enum | `.start` | `.start` or `.end`: which edge of the button the menu lines up with; use `.end` near the right edge of the window |

Each item:

| Field | Type | Default | Notes |
|---|---|---|---|
| `label` | string | required | end labels that open more UI with an ellipsis: "Share…" |
| `z` | `ui.Z` | none | z.js request; the menu closes after it fires. Without a `target` or `swap` the response is ignored (`.swap = .none` is filled in), so the item's label is never overwritten; set `target` and `swap` to use the response |
| `destructive` | bool | `false` | red text, red highlight |
| `separated` | bool | `false` | a separator above the item |
| `icon` | string | `""` | inline SVG (trusted, `currentColor`); if any item has one, all labels line up |
| `shortcut` | string | `""` | hint such as `⌘D`, shown at the end; it does not bind the key |
| `checked` | `?bool` | `null` | `null` is a normal item; `false`/`true` make a checkable item (`menuitemcheckbox`) with a checkmark when true |
| `radio` | bool | `false` | with `checked`: an exclusive choice (`menuitemradio`), such as a sort order, so screen readers announce it as one of a set |
| `disabled` | bool | `false` | greyed out, not focusable |
| `header` | string | `""` | section header above the item, below the separator if there is one |
| `href` | string | `""` | renders a link (`<a role="menuitem">`) instead of a button |

## Notes

- Destructive actions go last, below a separator.
- Show a shortcut only if it really works; keep the order modifier keys use on the Mac: ⌃ ⌥ ⇧ ⌘. `shortcut` is display only and the component cannot bind the key; handle it in your own key listener, or leave the hint out.
- Items are 44px tall on touch screens.
- Arrow keys, Home and End move between items; disabled items are skipped.
- A checkable item only shows state. Have its `z` request re-render the menu or the page so the checkmark follows. Exclusive choices, like a sort order, are checkable items with `radio = true` where the handler moves the mark. The browser does not flip `aria-checked` on click; the server round trip is what changes it.
- A menu inside a row of a list needs its own `id` per row. Carry the row's key in the item's URL.
