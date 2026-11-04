# Empty state

What a view shows when it has nothing in it yet: what would be here, and the next step.

A Reminders list that starts empty. The primary button adds a reminder, and the badge counts them. "Clear All" brings the empty state back.

```demo
empty
```

## Usage

```zig
ui.empty(.{
    .icon = "✓",
    .title = "No Reminders",
    .text = "Reminders you add show up here.",
    .action = ui.button(.{ .label = "New Reminder", .variant = .primary, .z = .{ .post = "/reminders", .target = "#reminders" } }),
    .secondary = ui.button(.{ .label = "Import…", .variant = .plain }),
})
```

The buttons are ordinary buttons, so they take `.z` requests, `.opens` and `.href` like any other. Swap the empty state out when the request succeeds, and the list takes its place.

## Sizes

`size` fits the empty state to the space it fills: a popover or small card, a section of a window, or a whole page.

```demo
empty-sizes
```

```zig
ui.empty(.{ .title = "No Recent Searches", .size = .compact })
ui.empty(.{ .title = "No Photos or Videos", .text = "Import some to get started.", .size = .large })
```

## Parts

Only `title` is required. Add `text` to say what to do, `icon` for a symbol, and `action` and `secondary` for the next step. A button can show a spinner with `loading`, or be dimmed with `disabled`.

```demo
empty-parts
```

## Switching places

One pane can show a list in one place and an empty state in another. Shared has a next step; Trash is empty on purpose and has none. The server answers each request with the right view.

```demo
empty-places
```

```zig
fn place(c: *zw.Ctx) !void {
    const name = c.query("place") orelse "recents";
    if (std.mem.eql(u8, name, "trash")) return c.page(ui.empty(.{ .icon = "🗑", .title = "Trash is Empty" }));
    // ...
}
```

## No search results

When a filter matches nothing, answer with a compact empty state instead of the list. Type something that is not a file name, such as "xyz".

```demo
empty-search
```

```zig
const title = try std.fmt.allocPrint(c.arena, "No Results for “{s}”", .{q});
try c.page(ui.empty(.{ .title = title, .text = "Check the spelling or try a new search.", .size = .compact }));
```

## Replacing out of band

Give the empty state an `id` and `oob` to swap it in from any response, for example when a delete in another part of the page leaves nothing. It has `role="status"`, so a screen reader announces it when it appears.

```zig
try c.page(ui.empty(.{ .id = "no-results", .oob = true, .title = "No Reminders" }));
```

## Props

| Prop | Type | Default | Notes |
|---|---|---|---|
| `title` | string | required | names what is missing |
| `id` | string | `""` | the element id, so a response can target or replace it |
| `oob` | bool | `false` | replace the element with the same `id` out of band |
| `text` | string | `""` | one sentence on what to do |
| `icon` | string | `""` | a symbol or emoji above the title (decorative, hidden from screen readers) |
| `size` | `.regular`, `.compact`, `.large` | `.regular` | `.compact` fits a popover or card, `.large` fills a whole page |
| `action` | component | none | the main next step, usually a primary button |
| `secondary` | component | none | an alternative step, usually a plain button; sits beside `action` |

## Notes

- The root has `role="status"`, so an empty state swapped in after a request (a search with no results) is announced politely.
- `ui.list`'s own `empty` text is plain text. When a list needs an icon or a button once it is empty, answer the request with `ui.empty` in place of the list, or send one with `id` and `oob`.
- Inside a search popover (`.zw-results`) the text keeps its own padding and callout font, so an empty state can be returned there.
