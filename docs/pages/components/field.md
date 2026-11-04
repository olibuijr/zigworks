# Field

A text field with a visible label. Use it inside a form; z.js sends its value with the form.

```demo
field
```

## Usage

```zig
zw.view("<form{z}>{f}{b}</form>", .{
    .z = ui.Z{ .post = "/todos", .target = "#todos", .swap = .beforeend },
    .f = ui.field(.{ .name = "title", .label = "New todo", .required = true }),
    .b = ui.button(.{ .label = "Add", .variant = .primary, .type = .submit }),
})
```

Help text, a unit and an error message:

```zig
ui.field(.{
    .name = "weight", .label = "Weight", .type = "number", .suffix = "kg", .inputmode = "decimal",
    .help = "Your weight today.",
    .invalid = if (too_heavy) "Enter a value under 300." else "",
})
```

## Notes

- The text under the field is linked to the input with `aria-describedby`. While `invalid` is set it replaces `help`, turns red, is announced as an alert and sets `aria-invalid`. Messages use the id `zw-<name>-msg`, so field names should be unique on a page.
- `prefix` and `suffix` are read as part of the accessible name (for example "Weight kg").
- Without JavaScript the browser still validates `required`, `pattern` and `maxlength` on submit, and a field turns red after the user leaves it with an invalid value.
- `type = "search"` shows a clear button once there is text (Safari and Chrome; Firefox has none).
- Number fields hide the browser's spin buttons. Use `ui.stepper` when you want buttons.
- On touch screens the field is 44px tall and its text is at least 16px, so iOS does not zoom in.

## Props

| Prop | Type | Default | Notes |
|---|---|---|---|
| `name` | string | required | form field name |
| `label` | string | required | always present, for screen readers |
| `placeholder` | string | `""` | an example, not the label |
| `value` | string | `""` | |
| `type` | string | `"text"` | `email`, `password`, `number`, `url`, `search`… |
| `required` | bool | `false` | |
| `autofocus` | bool | `false` | |
| `disabled` | bool | `false` | dimmed, not focusable, not submitted |
| `readonly` | bool | `false` | focusable and submitted, but not editable |
| `help` | string | `""` | help text under the field |
| `invalid` | string | `""` | error message under the field (red); replaces `help` and sets `aria-invalid` |
| `prefix` | string | `""` | text inside the box before the input, such as `$` |
| `suffix` | string | `""` | text inside the box after the input, such as `kg` |
| `autocomplete` | string | `"off"` | an autocomplete token: `email`, `current-password`, `one-time-code`… |
| `inputmode` | string | `""` | virtual keyboard: `numeric`, `decimal`, `tel`, `email`, `url`, `search` |
| `pattern` | string | `""` | regular expression checked on submit |
| `maxlength` | u16 | `0` | maximum characters; `0` means no limit |
| `z` | `ui.Z` | none | for example a live `input` trigger |
