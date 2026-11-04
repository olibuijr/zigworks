# Text area

A multi-line text field for notes and messages. It grows with its content, from `rows` lines up to `max_rows` (twelve by default), then scrolls.

A feedback form. The server checks the text and answers with a fresh form and a toast; try sending it empty first.

```demo
textarea
```

## Sizes and resizing

By default the field grows. Set `grow = false` for a fixed height, and add `resize = .vertical` to give it a drag handle. `rows = 1` makes a compact box that still grows.

```demo
textarea-sizes
```

## States

`help` adds a hint, `maxlength` adds a live counter, and `invalid` shows a red message and sets `aria-invalid`. `disabled` dims the field; `readonly` keeps it focusable but not editable.

```demo
textarea-states
```

## Autosave

Put a `z` request on the field to save as people type. Here it fires on `input`, which z.js sends after a short pause, and the server answers with an out-of-band badge.

```demo
textarea-autosave
```

## In a comment thread

With a list and avatars, a text area makes a comment box. Each post adds a row and swaps in a fresh form, so the counter starts again at zero.

```demo
textarea-comments
```

## Usage

```zig
ui.textarea(.{ .name = "notes", .label = "Notes", .placeholder = "Add notes", .rows = 4 })
```

With a limit, help text and a drag handle instead of auto-grow:

```zig
ui.textarea(.{
    .name = "bio", .label = "Bio", .maxlength = 140, .help = "Shown on your profile.",
    .rows = 4, .grow = false, .resize = .vertical,
})
```

Save while typing:

```zig
ui.textarea(.{
    .name = "notes", .label = "Notes",
    .z = .{ .post = "/notes", .trigger = "input", .swap = .none },
})
```

Show a server-side error by rendering the field again with `invalid`:

```zig
ui.textarea(.{ .name = "reason", .label = "Reason", .value = text, .invalid = "Add a reason before you send." })
```

## Notes

- `maxlength` is enforced by the browser and adds an `n / max` counter under the field. The server renders the count of the initial `value`; the counter turns red at the limit. It carries `data-count` so a script can keep it live as the user types.
- The help or error text and the counter are linked with `aria-describedby`. While `invalid` is set it replaces `help`, turns red, is announced as an alert and sets `aria-invalid`. They use the ids `zw-<name>-msg` and `zw-<name>-count`, so names should be unique on a page.
- Resetting a form clears the text but not the counter, because the script only updates it on `input`. After a successful post, swap in a fresh field (the comment demo does).
- Auto-grow uses CSS `field-sizing: content`. Browsers without it show a fixed `rows` height that scrolls.
- On touch screens the text is at least 16px so iOS does not zoom in.

## Props

| Prop | Type | Default | Notes |
|---|---|---|---|
| `name` | string | required | form field name |
| `label` | string | required | accessible name |
| `placeholder` | string | `""` | |
| `value` | string | `""` | escaped for you |
| `rows` | u8 | `3` | starting height in lines |
| `max_rows` | u8 | `12` | height at which a growing field stops and scrolls |
| `grow` | bool | `true` | grow with the content; `false` keeps a fixed height of `rows` lines |
| `resize` | enum: `none`, `vertical` | `.none` | drag handle for the height; best with `grow = false` |
| `required` | bool | `false` | |
| `disabled` | bool | `false` | dimmed, not focusable, not submitted |
| `readonly` | bool | `false` | focusable and submitted, but not editable |
| `maxlength` | u16 | `0` | maximum characters and a counter; `0` means no limit |
| `help` | string | `""` | help text under the field |
| `invalid` | string | `""` | error message under the field (red); replaces `help` and sets `aria-invalid` |
| `z` | `ui.Z` | none | for example save on `change` |
