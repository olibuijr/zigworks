# Tooltip

A short glass hint that appears when the pointer rests on something, after the macOS half-second delay, or when keyboard focus enters it. It replaces the browser's `title` attribute, which zigworks never uses.

Here it labels the icon-only buttons of a Notes-style toolbar. Rest the pointer on one, or press Tab:

```demo
tooltip
```

## Usage

```zig
ui.tooltip(.{ .text = "More actions", .body = ui.button(.{ .label = "•••", .aria = "More actions", .variant = .plain }) })
```

With a shortcut, a detail line and a description link for screen readers:

```zig
ui.tooltip(.{
    .id = "save-tip", .text = "Save", .shortcut = "⌘S", .detail = "Writes the document to disk.", .side = .below,
    .body = ui.button(.{ .label = "Save", .variant = .primary, .describedby = "save-tip" }),
})
```

## Sides

`side` picks where the tip opens. `.above` is the default. Use `.below` near the top of a page, such as in a toolbar, and `.left` or `.right` when the trigger is at the edge of the window and there is room beside it.

```demo
tooltip-sides
```

## Text, shortcut, detail and delay

`text` is a few words, with no period. `shortcut` adds a key hint after it and `detail` a second line in secondary color. Pass `id` and the trigger's `describedby` when the tip holds more than the trigger's own name, so screen readers read it.

`delay` is how long the pointer or focus must rest before the tip shows. The default is 500 ms, as on macOS; use `0` for controls people scan quickly.

```demo
tooltip-content
```

## Disabled and busy controls

A tip is the right place to say why something is unavailable. It belongs to the wrapper, not the button, so it still shows over a disabled or loading control. Say what to do, not just that it is off.

```demo
tooltip-states
```

## Tips that follow state

The tip is plain markup, so the server can change it with the control. Here the star posts its state in the URL and the response replaces the whole tooltip (`target = "closest .zw-tip"`, `swap = .outer`), so "Add to Favorites" becomes "Remove from Favorites". The count is an out-of-band badge from the same response. Copy Link answers with a toast.

```demo
tooltip-live
```

```zig
fn star(on: bool, url: []const u8) ui.Tooltip(ui.Button) {
    return ui.tooltip(.{
        .id = "star-tip",
        .text = if (on) "Remove from Favorites" else "Add to Favorites",
        .body = ui.button(.{
            .label = "Favorite", .variant = .plain, .icon = star_icon, .icon_only = true, .describedby = "star-tip",
            .z = .{ .post = url, .target = "closest .zw-tip", .swap = .outer },
        }),
    });
}
```

## In context

Tooltips go on the quiet controls of a card header and on avatars, where the tip carries a name and a role. A button that opens a menu can have a tip too. Avatars are not focusable, so wrap each in an element with `tabindex="0"` to let keyboard users reach the tip.

```demo
tooltip-compose
```

## Props

| Prop | Type | Default | Notes |
|---|---|---|---|
| `text` | string | required | a few words, no period |
| `side` | enum | `.above` | `.above`, `.below` (near the top of a page), `.left` or `.right` (near the window edges) |
| `body` | component | required | the thing being explained |
| `delay` | `u16` | `500` | milliseconds the pointer or focus rests before the tip shows; `0` shows it at once |
| `detail` | string | `""` | second line in secondary color, for a short explanation |
| `shortcut` | string | `""` | key hint after the text, such as `⌘S`; display only |
| `id` | string | `""` | id of the tip; pass the same string as the trigger's `describedby` (`ui.button`) so screen readers read it |

Tooltips explain; they must not hold the only copy of important information, since touch screens never show them.

## Notes

- Keyboard focus (Tab) shows the tip; a mouse click does not, so it never sticks after pressing a button.
- Hover tips only appear on devices with a real pointer; touch screens never show them.
- `.left` and `.right` tips are at most half the viewport wide, but do not place them against the window edge.
- A tip is positioned inside its trigger's wrapper, so a parent with `overflow: hidden` clips it. Keep tooltips out of lists and flush cards, or put them on controls in the card header.
- Tips are not interactive: the pointer passes through them, so people cannot move onto a tip to select its text.
