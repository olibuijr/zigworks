# Empty state

What a view shows when it has nothing in it yet: what would be here, and the next step.

```demo
empty
```

## Usage

```zig
ui.empty(.{
    .title = "No Reminders",
    .text = "Reminders you add show up here.",
    .action = ui.button(.{ .label = "New Reminder", .variant = .primary, .opens = "new" }),
})
```

## Props

| Prop | Type | Default | Notes |
|---|---|---|---|
| `title` | string | required | names what is missing |
| `text` | string | `""` | one sentence on what to do |
| `action` | component | none | usually a button |

For a list that becomes empty after deletes, `ui.list`'s `empty` text is enough.
