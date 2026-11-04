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

## Props

| Prop | Type | Default | Notes |
|---|---|---|---|
| `on` | bool | required | checked |
| `label` | string | required | accessible name; the row shows its own text |
| `z` | `ui.Z` | none | sent on `change` |
