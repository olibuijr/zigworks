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

## Props

| Prop | Type | Default | Notes |
|---|---|---|---|
| `name` | string | required | form field name |
| `label` | string | required | always present, for screen readers |
| `placeholder` | string | `""` | an example, not the label |
| `value` | string | `""` | |
| `type` | string | `"text"` | `email`, `password`, `number`, `url`… |
| `required` | bool | `false` | |
| `autofocus` | bool | `false` | |
| `z` | `ui.Z` | none | for example a live `input` trigger |
