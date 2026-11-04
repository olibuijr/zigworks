# Empty state

What a view shows when it has nothing in it yet: what would be here, and the next step.

```demo
empty
```

## Usage

```zig
ui.empty(.{
    .icon = "✓",
    .title = "No Reminders",
    .text = "Reminders you add show up here.",
    .action = ui.button(.{ .label = "New Reminder", .variant = .primary, .opens = "new" }),
    .secondary = ui.button(.{ .label = "Learn More", .variant = .plain }),
})
```

A compact one for a popover or a small card:

```zig
ui.empty(.{ .title = "No results", .size = .compact })
```

## Props

| Prop | Type | Default | Notes |
|---|---|---|---|
| `title` | string | required | names what is missing |
| `text` | string | `""` | one sentence on what to do |
| `icon` | string | `""` | a symbol or emoji above the title (decorative, hidden from screen readers) |
| `size` | `.regular`, `.compact`, `.large` | `.regular` | `.compact` fits a popover or card, `.large` fills a whole page |
| `action` | component | none | the main next step, usually a primary button |
| `secondary` | component | none | an alternative step, usually a plain button; sits beside `action` |

For a list that becomes empty after deletes, `ui.list`'s `empty` text is enough.
