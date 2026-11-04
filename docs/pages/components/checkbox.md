# Checkbox

A macOS checkbox with a visible label, for options in forms and settings. The mark springs in. For marking list items done, use the round [check](/components/check).

```demo
checkbox
```

## Usage

```zig
ui.checkbox(.{ .name = "spell", .label = "Check spelling while typing", .on = true })
```

With a description, mixed state and disabled option:

```zig
ui.checkbox(.{ .name = "all", .label = "Select all", .mixed = true, .description = "2 of 5 selected" })
ui.checkbox(.{ .name = "beta", .label = "Beta features", .disabled = true })
ui.checkbox(.{ .name = "terms", .label = "I agree to the terms", .invalid = true })
```

## Props

| Prop | Type | Default | Notes |
|---|---|---|---|
| `name` | string | required | |
| `label` | string | required | shown next to the box |
| `value` | string | `"on"` | sent when checked; nothing is sent when unchecked |
| `on` | bool | `false` | |
| `description` | string | none | secondary line under the label |
| `mixed` | bool | `false` | starts in the mixed state: a dash and `aria-checked="mixed"`. Overrides `on`; the first click checks it |
| `disabled` | bool | `false` | dimmed, not interactive, not submitted |
| `invalid` | bool | `false` | red box and `aria-invalid`, for a required box left unchecked |
| `z` | `ui.Z` | none | sent on `change` |

The whole label is the click target, at least 44px tall on touch screens. A mixed checkbox is a visual start state: when your page recomputes it (for example "Select all"), re-render it with the new `on` or `mixed`.
