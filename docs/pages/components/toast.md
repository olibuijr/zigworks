# Toast

A short notification that drops in at the top of the window and leaves by itself after four seconds. Use it to confirm something that happened out of view, such as "Saved" or "Couldn't send".

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

## Props

| Prop | Type | Default | Notes |
|---|---|---|---|
| `text` | string | required | one short sentence |
| `kind` | enum | `.info` | `.info`, `.success`, `.@"error"` (sets the dot color) |

Toasts are announced to screen readers. Don't use one for errors people must act on; show those next to the field or in a sheet.
