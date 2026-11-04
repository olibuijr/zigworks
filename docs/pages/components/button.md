# Button

A macOS push button. Use one primary button per view for the default action.

```demo
button
```

## Usage

```zig
ui.button(.{ .label = "Save", .variant = .primary, .type = .submit })
ui.button(.{ .label = "Delete", .variant = .destructive, .z = .{
    .delete = "/todos/1", .target = "closest li", .swap = .delete, .confirm = "Delete this todo?",
} })
```

## Props

| Prop | Type | Default | Notes |
|---|---|---|---|
| `label` | string | required | use title case: "Save Changes" |
| `variant` | enum | `.secondary` | `.primary`, `.secondary`, `.plain`, `.destructive` |
| `type` | enum | `.button` | `.submit` inside forms |
| `aria` | string | `""` | accessible name when the label is not enough |
| `opens` | string | `""` | id of a menu or sheet to show |
| `disabled` | bool | `false` | |
| `z` | `ui.Z` | none | z.js request |
