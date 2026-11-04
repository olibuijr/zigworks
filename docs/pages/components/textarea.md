# Text area

A multi-line text field for notes and messages. It grows with its content, from `rows` lines up to `max_rows` (twelve by default), then scrolls.

```demo
textarea
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

## Notes

- `maxlength` is enforced by the browser and adds an `n / max` counter under the field. The server renders the count of the initial `value`; the counter turns red at the limit. It carries `data-count` so a script can keep it live as the user types.
- The help or error text and the counter are linked with `aria-describedby`. While `invalid` is set it replaces `help`, turns red, is announced as an alert and sets `aria-invalid`. They use the ids `zw-<name>-msg` and `zw-<name>-count`, so names should be unique on a page.
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
