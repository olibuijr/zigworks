# Text area

A multi-line text field for notes and messages. It grows with its content, from `rows` lines up to twelve, then scrolls.

```demo
textarea
```

## Usage

```zig
ui.textarea(.{ .name = "notes", .label = "Notes", .placeholder = "Add notes", .rows = 4 })
```

## Props

| Prop | Type | Default | Notes |
|---|---|---|---|
| `name` | string | required | form field name |
| `label` | string | required | accessible name |
| `placeholder` | string | `""` | |
| `value` | string | `""` | escaped for you |
| `rows` | u8 | `3` | starting height in lines |
| `required` | bool | `false` | |
| `z` | `ui.Z` | none | for example save on `change` |
