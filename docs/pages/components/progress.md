# Progress

A progress bar when you know how far along a task is, a ring for compact spots, and a spinner or an indeterminate bar when you don't.

Here it is in a Settings app: a bar for the download, a ring for disk use, a spinner for work of unknown length.

```demo
progress
```

## Variants and sizes

Every prop has a row. `size` sets the bar thickness and the ring and spinner diameter. `tone` colors the fill. `text` and `show_value` add the caption above a bar, beside a ring or spinner; on a ring, `show_value` writes the percentage in the middle, or after the caption on a small ring, which has no room for it. With `value = null` you get a spinner, or an indeterminate bar with `bar = true`. Both take the same tones: `.accent` is blue, `.neutral` is the gray of the system spinner.

```demo
progress-variants
```

## States

A progress bar is read-only, so it has no disabled state. These are the states it does have: not started, complete, nearly full, failed, unknown length, and a value over 100 (clamped).

```demo
progress-states
```

## Updating from the server

Drag the slider. It sends the new value with `z-get`, and the response replaces the ring, the bar and the badge in the card header, all out of band. The server picks the tone (orange from 75, red from 90) so the markup always matches the number.

```demo
progress-live
```

Give the progress an `id` and set `oob`, and a z.js response replaces the element with that id wherever it is on the page. The request's target only has to exist, so use `.swap = .none`:

```zig
fn storage(c: *zw.Ctx) !void {
    const v = @min(std.fmt.parseInt(u8, c.query("v") orelse "", 10) catch 50, 100);
    try c.page(ui.progress(.{
        .id = "storage",
        .oob = true,
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
ui.progress(.{ .value = null, .label = "Preparing", .bar = true }) // indeterminate bar
ui.progress(.{ .value = 72, .label = "Upload", .text = "Uploading photos", .show_value = true })
ui.progress(.{ .value = 100, .label = "Backup", .tone = .success, .size = .large })
ui.progress(.{ .value = 64, .label = "Storage", .ring = true, .show_value = true })
ui.progress(.{ .value = null, .label = "Syncing", .text = "Syncing…", .size = .small })
ui.progress(.{ .value = 30, .label = "Upload failed", .text = "Upload failed", .tone = .@"error" })
ui.progress(.{ .id = "dl", .oob = true, .value = 50, .label = "Download" })  // replaces #dl in a response
```

## Props

| Prop | Type | Default | Notes |
|---|---|---|---|
| `value` | `?u8` | required | 0 to 100 (higher values are clamped), or null for an indeterminate spinner (or bar, see `bar`) |
| `label` | string | required | accessible name |
| `size` | enum | `.regular` | `.small`, `.regular`, `.large`: bar thickness, ring and spinner diameter |
| `tone` | enum | `.accent` | `.accent` (blue), `.neutral` (gray), `.success`, `.warning`, `.@"error"`: fill color of bars, rings and spinners |
| `text` | string | `""` | visible caption: above a bar, beside a ring or spinner |
| `show_value` | bool | `false` | percentage: right-aligned above a bar, inside a ring; after the caption on `.small` rings. Ignored when `value` is null |
| `ring` | bool | `false` | draw a determinate value as a circular ring instead of a bar |
| `bar` | bool | `false` | with `value = null`: draw an indeterminate bar instead of a spinner; `text` shows above it |
| `id` | string | `""` | element id, on the outermost element (the caption wrapper when there is one) |
| `oob` | bool | `false` | in a z.js response, replace the element with the same `id`; needs `id` |

## Notes

- Bars and rings are `role="progressbar"` with `aria-valuenow`; spinners are `role="status"`. Always give a `label`, even when `text` is visible.
- Use `.tone` to say what the number means (green for done, orange for nearly full, red for failed), never as the only signal: pair it with `text`.
- With Reduce Motion the spinner stops and the bar and ring jump to their new value.
- To update a progress from the server, give it an `id` and `oob`, as the slider demo does. The `id` goes on the outermost element, so the caption is replaced with the bar.
- A swap replaces the element, so the new bar appears at its value without animating the width. To animate, change the value on the same element yourself (set `--v` on a bar, `--n` on a ring).
- An indeterminate bar (`value = null`, `bar = true`) is `role="progressbar"` without `aria-valuenow`. `show_value` is ignored when there is no value; use `text`. With Reduce Motion it stays still as a faint full bar.
- A ring shows its caption after the ring; there is no option to put it above or below. Put the ring in your own column layout for that. The percentage is inside the ring, so repeat it in `text` if the caption should carry the value too.
- To poll, give an element `z-trigger="every 2s"` (or `every 500ms`) with a `z-get`: z.js sends it on that interval while the page is visible and stops when the element is swapped out. Let the server answer without the trigger once the task is done.
