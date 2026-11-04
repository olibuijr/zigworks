# Field

A text field in the macOS style. The label is announced to screen readers but not drawn by default, so give the field a placeholder that tells people what to type, or set `show_label` to draw the label inside the box. Use it inside a form; z.js sends its value with the form.

```demo
field
```

## Types and affixes

`type`, `inputmode` and `autocomplete` pick the right keyboard and autofill on phones. `prefix` and `suffix` put a unit inside the box. `step`, `min` and `max` set the limits of a number field; `step = "0.1"` (or `"any"`) allows decimals. Each caption shows the props that make the field.

```demo
field-types
```

## States

`help` explains the field. `invalid` shows an error in its place and turns the box red. `disabled` dims the field and leaves it out of the form; `readonly` keeps it focusable and submitted. Without JavaScript, `required` and `pattern` still turn the box red once you leave it with a bad value. `show_label` draws the label before the input. Click a field to see the focus ring.

```demo
field-states
```

## Live fields

Put a `z` on the field to react as people type. z.js sends `name=value` after a short pause and swaps the reply into the element named by `target`. The field dims and shows a small spinner while the request runs. Keep the target outside the input, so the cursor stays where it is. The username field targets its own message, `#zw-<name>-msg` with `swap = .outer`, so the reply (a `<small>` with the same id, and `zw-help--error` when it is an error) changes the text and turns the box red.

```demo
field-live
```

## Server-side validation

Post the whole form and answer with the same form again, carrying `invalid` messages. Add `novalidate` to the form so the server's messages show instead of the browser's bubbles. On success, answer with something else and a toast.

```demo
field-validate
```

## With other components

A field next to a button adds tags to a list. A field inside a sheet takes focus when the sheet opens, with `autofocus` marking which one.

```demo
field-compose
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
    .name = "weight", .label = "Weight", .type = "number", .suffix = "kg", .step = "0.1", .min = "0", .max = "300",
    .help = "Your weight today.",
    .invalid = if (too_heavy) "Enter a value under 300." else "",
})
```

A field that checks its value while you type. The reply replaces its own message element (the field needs `help` or `invalid` so that element exists):

```zig
ui.field(.{
    .name = "handle", .label = "Username", .help = "3 to 20 characters.", .pattern = "[a-z0-9]{3,20}",
    .z = .{ .get = "/handle", .trigger = "input", .target = "#zw-handle-msg", .swap = .outer },
})
// the handler answers: <small id="zw-handle-msg" class="zw-help zw-help--error" role="alert">Already taken.</small>
```

## Notes

- The text under the field is linked to the input with `aria-describedby`. While `invalid` is set it replaces `help`, turns red, is announced as an alert and sets `aria-invalid`. Messages use the id `zw-<name>-msg`, so field names should be unique on a page.
- `prefix` and `suffix` are read as part of the accessible name (for example "Weight kg").
- Without JavaScript the browser still validates `required`, `pattern` and `maxlength` on submit, and a field turns red after the user leaves it with an invalid value.
- `type = "search"` shows a clear button once there is text (Safari and Chrome; Firefox has none).
- Number fields hide the browser's spin buttons. Use `ui.stepper` when you want buttons. Without `step` a number field accepts whole numbers only, so set `step = "0.1"` or `"any"` for decimals.
- While a live request runs, z.js adds `zw-busy` to the input; the field dims it and shows a spinner in the box (static with Reduce Motion).
- A reply that swaps the message element changes its text and colour, and a `zw-help--error` message turns the box red, but `aria-invalid` is only set by rendering the field with `invalid`; the `role="alert"` message is still announced. To also update `aria-invalid`, answer with the whole field and accept that it loses focus, or use a separate status element.
- With a `z` on the field itself (not on the form), z.js sends only that field, as `name=value`. `trigger = "input"` waits 250 ms after the last keystroke.
- `show_label` draws the label in the box before the input (and before any `prefix`); for a label on the left of a whole row, with a description, use `ui.setting`.
- Give each field a unique `name` on a page: the message id comes from it.
- On touch screens the field is 44px tall and its text is at least 16px, so iOS does not zoom in.

## Props

| Prop | Type | Default | Notes |
|---|---|---|---|
| `name` | string | required | form field name |
| `label` | string | required | always present, for screen readers |
| `show_label` | bool | `false` | draw the label inside the box before the input instead of hiding it |
| `placeholder` | string | `""` | an example, not the label |
| `value` | string | `""` | |
| `type` | string | `"text"` | `email`, `password`, `number`, `url`, `search`… |
| `required` | bool | `false` | |
| `autofocus` | bool | `false` | focus the field on load; use it in a sheet, not on a long page |
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
| `step` | string | `""` | number step: `"0.1"`, or `"any"` for decimals; empty uses the browser default |
| `min` | string | `""` | smallest value of a number or date field |
| `max` | string | `""` | largest value of a number or date field |
| `z` | `ui.Z` | none | on the input itself, for example a live `trigger = "input"` request (shows a spinner while it runs) |
