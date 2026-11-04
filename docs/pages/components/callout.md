# Callout

A highlighted note, tip, warning, important or caution message, with an icon. Use it for text that explains the content around it: why a setting matters, what a risky action will do, or how an input was understood. In Markdown, `> [!TIP]` renders the same component.

Here a Settings pane explains why its switches matter:

```demo
callout
```

## Kinds

The `kind` sets the accent color and the icon. Each cell shows the props it uses.

```demo
callout-kinds
```

## Title, icon and compact

A `title` is a bold lead-in; leave it out when the body is enough. `icon = false` hides the icon, and `compact` makes a tighter callout without the accent bar, for notes inside dense UI. The `body` can be a string or any component, such as a keyboard shortcut.

```demo
callout-options
```

## Try the props

Change the form and the callout below it is rendered again by the server from your values. Nothing is stored.

```demo
callout-playground
```

## Feedback under a field

A callout works well as live feedback. The field posts its value as you type, and the handler answers with a callout whose kind depends on the name. Try a name with a slash, a leading dot or no extension, then press Return.

```demo
callout-rename
```

## Callout in a flow

The callout changes with the step and sits next to a progress bar and buttons. The step is in the request URL, so the server keeps nothing.

```demo
callout-update
```

## Usage

```zig
ui.callout(.{ .kind = .warning, .title = "Warning", .body = "This cannot be undone." })
ui.callout(.{ .kind = .caution, .title = "Caution", .body = "Deleting a site removes its backups." })
ui.callout(.{ .kind = .tip, .body = "Press ⌘K to search.", .compact = true })
ui.callout(.{ .title = "Plain note.", .body = "No icon.", .icon = false })
```

The body can be a component. A handler can return a callout to replace a status area:

```zig
fn check(c: *zw.Ctx) !void {
    const name = c.form("name") orelse "";
    try c.page(ui.callout(.{
        .kind = if (name.len == 0) .note else .tip,
        .title = "Name",
        .body = zw.view("Press {k} to rename.", .{ .k = ui.kbd(.{ .keys = "↩" }) }),
    }));
}
```

## Props

| Prop | Type | Default | Notes |
|---|---|---|---|
| `kind` | enum | `.note` | `.note` (blue), `.tip` (green), `.warning` (orange), `.important` (violet, a blend of the accent and red), `.caution` (red) |
| `title` | string | `""` | bold lead-in, followed by the body on the same line |
| `body` | component | required | a string or any component |
| `icon` | bool | `true` | show the kind's icon |
| `compact` | bool | `false` | tighter padding and no accent bar, for dense UI |

## Notes

- The callout is a `role="note"`. The kind is shown by color and icon; put it in `title` too when the distinction matters ("Caution: ...").
- When a handler swaps a callout into a status area, give the area `aria-live="polite"` so screen readers announce the new message.
- Keep a callout to a sentence or two. Long text belongs in the page.
- A callout has no dismiss button and no live-region role of its own. To announce a swapped-in message, wrap it in an `aria-live="polite"` area as the demos do; for a dismissable message use a toast.
- Handlers can name the kind through the callout's props type, for example `@FieldType(@TypeOf(ui.callout(.{ .body = "" }).data), "kind")`.
- Markdown fences support `[!NOTE]`, `[!TIP]`, `[!WARNING]`, `[!IMPORTANT]` and `[!CAUTION]` and always show the icon.
