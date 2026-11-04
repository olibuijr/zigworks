# Progress

A progress bar when you know how far along a task is, a ring for compact spots, and a spinner when you don't.

Here it is in a Settings app: a bar for the download, a ring for disk use, a spinner for work of unknown length.

```demo
progress
```

## Variants and sizes

Every prop has a row. `size` sets the bar thickness and the ring and spinner diameter. `tone` colors the fill. `text` and `show_value` add the caption above a bar, beside a ring or spinner; on a ring, `show_value` writes the percentage in the middle (small rings have no room for it). With `value = null` you get a spinner, which is gray unless you give it a tone.

```demo
progress-variants
```

## States

A progress bar is read-only, so it has no disabled state. These are the states it does have: not started, complete, nearly full, failed, unknown length, and a value over 100 (clamped).

```demo
progress-states
```

## Updating from the server

Drag the slider. It sends the new value with `z-get`, and the response replaces the bar and ring and, out of band, the badge in the card header. The server picks the tone (orange from 75, red from 90) so the markup always matches the number.

```demo
progress-live
```

`ui.progress` has no `id`, so wrap it in an element you can target and swap its contents:

```zig
fn storage(c: *zw.Ctx) !void {
    const v = @min(std.fmt.parseInt(u8, c.query("v") orelse "", 10) catch 50, 100);
    try c.page(ui.progress(.{
        .value = v,
        .label = "Used space",
        .text = "Macintosh HD",
        .show_value = true,
        .tone = if (v >= 90) .@"error" else if (v >= 75) .warning else .accent,
    }));
}
```

## An upload queue

Add a file and it joins the list at 0%. Each click on Advance posts the file name and its progress; the server answers with the row at the next value, and a toast when the file reaches 100%. The page holds all the state, so nothing is stored on the server.

```demo
progress-queue
```

## With other components

A copy card, a mail account list where a badge, a spinner and a ring each say where an account is, and a button with its own `loading` spinner next to a disabled primary action.

```demo
progress-composition
```

## Usage

```zig
ui.progress(.{ .value = 42, .label = "Download" })                 // bar, 42%
ui.progress(.{ .value = null, .label = "Indexing" })              // spinner
ui.progress(.{ .value = 72, .label = "Upload", .text = "Uploading photos", .show_value = true })
ui.progress(.{ .value = 100, .label = "Backup", .tone = .success, .size = .large })
ui.progress(.{ .value = 64, .label = "Storage", .ring = true, .show_value = true })
ui.progress(.{ .value = null, .label = "Syncing", .text = "Syncing…", .size = .small })
ui.progress(.{ .value = 30, .label = "Upload failed", .text = "Upload failed", .tone = .@"error" })
```

## Props

| Prop | Type | Default | Notes |
|---|---|---|---|
| `value` | `?u8` | required | 0 to 100 (higher values are clamped), or null for an indeterminate spinner |
| `label` | string | required | accessible name |
| `size` | enum | `.regular` | `.small`, `.regular`, `.large`: bar thickness, ring and spinner diameter |
| `tone` | enum | `.accent` | `.accent`, `.success`, `.warning`, `.@"error"`: fill color; a spinner is gray unless the tone is not `.accent` |
| `text` | string | `""` | visible caption: above a bar, beside a ring or spinner |
| `show_value` | bool | `false` | percentage: right-aligned above a bar, inside a ring (hidden on `.small` rings) |
| `ring` | bool | `false` | draw a determinate value as a circular ring instead of a bar |

## Notes

- Bars and rings are `role="progressbar"` with `aria-valuenow`; spinners are `role="status"`. Always give a `label`, even when `text` is visible.
- Use `.tone` to say what the number means (green for done, orange for nearly full, red for failed), never as the only signal: pair it with `text`.
- With Reduce Motion the spinner stops and the bar and ring jump to their new value.
- A bar has no `id` or `oob` prop. To update one, put it in a wrapper with an id and swap the wrapper's contents with z.js, as the slider demo does.
- A swap replaces the element, so the new bar appears at its value without animating the width.
- Progress has no indeterminate bar: `value = null` always draws a spinner.
