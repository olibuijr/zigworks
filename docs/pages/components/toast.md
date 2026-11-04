# Toast

A short notification that drops in at the top of the window and leaves by itself after four seconds. Use it to confirm something that happened out of view, such as "Saved" or "Couldn't send". It can carry one action, like Undo, and can stay until dismissed.

Move a file to the Trash. The toast appears at the top of the window, and Undo puts the row back.

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

With an action. The action fires like any `z` attributes. z.js closes the toast when its action is pressed, so `z` only has to say what the action does and needs no `.swap = .delete`. This one puts a deleted row back:

```zig
ui.toast(.{
    .text = "Moved “Invoice.pdf” to the Trash",
    .action = "Undo",
    .z = .{ .post = "/restore/42", .target = "#files", .swap = .beforeend },
})
```

## Kinds

`kind` picks the icon and its color. Errors are announced to screen readers at once, the other kinds politely. These are shown in place with `static: true`, so all four fit on the page:

```demo
toast-kinds
```

```zig
ui.toast(.{ .text = "Message sent", .kind = .success, .static = true })
```

## Action, sticky and long text

An `action` adds one button. `sticky` keeps the toast on screen until it is dismissed, and shows a close button. Long text wraps. Several toasts at once stack below each other.

```demo
toast-options
```

A sticky toast is for something people may need time to read or act on. Retry here asks the server for the next toast:

```zig
ui.toast(.{
    .text = "Upload failed",
    .kind = .@"error",
    .action = "Retry",
    .z = .{ .post = "/upload/retry", .swap = .none },
})
```

## With a form and a list

A form posts an address. A good one answers with the new row and a success toast, a bad one with an error toast only, so the list stays as it is. Try an empty field or "ada" without an at sign.

```demo
toast-invite
```

```zig
fn invite(c: *zw.Ctx) !void {
    const email = std.mem.trim(u8, c.form("email") orelse "", " ");
    if (!valid(email)) return c.page(ui.toast(.{ .text = "Enter a valid email address", .kind = .@"error" }));
    try c.html("{row}{toast}", .{ .row = inviteRow(email), .toast = ui.toast(.{ .text = "Invitation sent", .kind = .success }) });
}
```

An error here is a normal response with an error toast, not an error status: z.js only logs a failed request (non-2xx) to the console and shows nothing. A form with `z-post` also resets after any successful response, so the mistyped address is cleared here too; `z-keep` on the form keeps its values, but then a sent address stays too.

## Props

| Prop | Type | Default | Notes |
|---|---|---|---|
| `text` | string | required | one short sentence |
| `kind` | enum | `.info` | `.info`, `.success`, `.warning`, `.@"error"`: sets the icon and its color |
| `action` | string | `""` | label of a button inside the toast, such as "Undo" |
| `z` | `ui.Z` | `.{}` | what the action button does (same fields as a button's `.z`) |
| `sticky` | bool | `false` | no auto-dismiss; a close button is shown |
| `static` | bool | `false` | render the toast in place in the page instead of appending it to the toast area; for docs and previews |

## Notes

- Toasts are announced to screen readers: errors immediately (`role="alert"`), everything else politely (`role="status"`). Don't use one for errors people must act on; show those next to the field or in a sheet.
- Toasts slide up and out when they leave (on their own, when dismissed, or after their action), and the ones below move up to fill the space.
- A normal toast leaves after four seconds. If it carries an action people may need time to find, make it `sticky`.
- A sticky toast is closed with its close button, which works without JavaScript.
- On touch screens the action and close buttons grow to 44px.
- A toast is added to the `#zw-toasts` area of the layout, so the response must reach z.js. Keep the request's `swap` as it is, or use `.swap = .none` when nothing else changes.
- `static` renders only the toast, without the `#zw-toasts` append and without the entrance animation. It never leaves by itself, so use it for previews, not for notifications.
- A failed request (non-2xx) shows no toast on its own. To tell people a save failed, answer with status 200 and an error toast.
