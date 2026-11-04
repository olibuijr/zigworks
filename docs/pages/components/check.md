# Check

A round checkbox for marking items done, as in Reminders. Give it a `z` request to save the change. The server answers with the new state and the check pops.

In this list, each check posts to the server. The reply swaps the list and updates the badge in the header out of band.

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

The check does not flip itself. The request decides: answer with the same check and `.on` changed, and z.js swaps it in. The state lives in `aria-checked`, so a page with no server state can put it in the URL, as these demos do.

## Variants and sizes

`size` scales the check (18, 22 or 28px). `tint` sets the fill when checked: the accent, or a system colour for list colours and flags. Rows are sizes, columns are tints. Click any of them.

```demo
check-sizes
```

A flagged item with a larger orange check:

```zig
ui.check(.{ .on = todo.flagged, .label = todo.title, .tint = .orange, .size = .large, .z = .{ .post = path } })
```

## States

A check is unchecked or checked. `disabled` dims it and makes it inert. Without a `z` request, a check does nothing when clicked. While a request is in flight, z.js dims it. Tab to focus a check and press Space.

```demo
check-states
```

## Progress and toasts

A response can carry more than the swapped content. Here every tick returns the list, a new progress bar (out of band) and, once the last step is done, a toast.

```demo
check-progress
```

```zig
c.html("{list}{meter}{#if all}{toast}{/if}", .{
    .list = checklist(mask),
    .meter = meter(mask), // <div id="meter" z-oob>…</div>
    .all = mask == full,
    .toast = ui.toast(.{ .text = "Everything is ready to ship", .kind = .success }),
})
```

## In a list

A check is the leading control of a list row. Here a [field](/components/field), a [segmented](/components/segmented) colour picker and a [button](/components/button) add rows with their own `tint`. Each row has a delete [button](/components/button) that appears on hover.

```demo
check-add
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
