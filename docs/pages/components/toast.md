# Toast

A short notification that drops in at the top of the window and leaves by itself after four seconds. Use it to confirm something that happened out of view, such as "Saved" or "Couldn't send". It can carry one action, like Undo, and can stay until dismissed.

```demo
toast
```

## Usage

Return a toast from a handler, alone or next to other HTML. It is an out-of-band append into the area every `ui.layout` has, so it shows whatever the request's target is:

```zig
fn save(c: *zw.Ctx) !void {
    try store.save(c.form("name") orelse "");
    try c.html("{row}{toast}", .{ .row = views.row(item), .toast = ui.toast(.{ .text = "Saved", .kind = .success }) });
}
```

With an action. The action fires like any `z` attributes; `.swap = .delete` aimed at the toast closes it afterwards:

```zig
ui.toast(.{
    .text = "Reminder deleted",
    .action = "Undo",
    .z = .{ .post = "/undo/42", .target = "closest .zw-toast", .swap = .delete },
    .sticky = true,
})
```

## Props

| Prop | Type | Default | Notes |
|---|---|---|---|
| `text` | string | required | one short sentence |
| `kind` | enum | `.info` | `.info`, `.success`, `.warning`, `.@"error"`: sets the icon and its color |
| `action` | string | `""` | label of a button inside the toast, such as "Undo" |
| `z` | `ui.Z` | `.{}` | what the action button does (same fields as a button's `.z`) |
| `sticky` | bool | `false` | no auto-dismiss; a close button is shown |

## Notes

- Toasts are announced to screen readers: errors immediately (`role="alert"`), everything else politely (`role="status"`). Don't use one for errors people must act on; show those next to the field or in a sheet.
- A normal toast leaves after four seconds. If it carries an action people may need time to find, make it `sticky`.
- A sticky toast is closed with its close button, which works without JavaScript.
- On touch screens the action and close buttons grow to 44px.
