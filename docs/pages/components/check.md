# Check

A round checkbox for marking items done, as in Reminders. Give it a `z` request to save the change.

```demo
check
```

## Usage

```zig
ui.check(.{
    .on = todo.done,
    .label = todo.title,
    .z = .{ .post = path, .target = "closest li", .swap = .outer },
})
```

A flagged item with a larger orange check:

```zig
ui.check(.{ .on = todo.flagged, .label = todo.title, .tint = .orange, .size = .large, .z = .{ .post = path } })
```

## Props

| Prop | Type | Default | Notes |
|---|---|---|---|
| `on` | bool | required | checked |
| `label` | string | required | accessible name; the row shows its own text |
| `size` | `.small` `.regular` `.large` | `.regular` | 18, 22 or 28px; the touch target stays 44px on touch screens |
| `tint` | `.accent` `.red` `.orange` `.green` | `.accent` | fill colour when checked, for list colours and flags |
| `disabled` | bool | `false` | dimmed and not interactive |
| `z` | `ui.Z` | none | sent on `click` |

It is a `role="checkbox"` button, so it is not part of a form: the state lives in `aria-checked` and the server flips it. For a form field, use [checkbox](/components/checkbox). Reduce Motion turns off the pop and tick animations.
