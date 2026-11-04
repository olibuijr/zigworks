# Checkbox

A macOS checkbox with a visible label, for options in forms and settings. The mark springs in. For marking list items done, use the round [check](/components/check).

```demo
checkbox
```

## Usage

```zig
ui.checkbox(.{ .name = "spell", .label = "Check spelling while typing", .on = true })
```

To save a change as soon as it is made, give the checkbox a request. It is sent on `change`, with `name=value` when the box is checked and an empty body when it is not:

```zig
ui.checkbox(.{ .name = "grammar", .label = "Check grammar with spelling", .z = .{ .post = "/prefs", .swap = .none } })
```

A checkbox has one size and one style. What changes is its state and the text around it.

## States

Each row shows the prop that produces the state. Click the mixed one: the first click checks it. Check the red one and the mark goes away.

```demo
checkbox-states
```

```zig
ui.checkbox(.{ .name = "all", .label = "Select all", .mixed = true, .description = "2 of 5 selected" })
ui.checkbox(.{ .name = "sync", .label = "Sync with iCloud", .description = "Turned off by your administrator.", .disabled = true })
ui.checkbox(.{ .name = "terms", .label = "I accept the terms of use", .invalid = true })
```

A disabled checkbox is dimmed and is not submitted. `invalid` only marks the box; your handler decides when to set it, as in the checkout form below.

## Name and value

Boxes that share a `name` make a multiple choice: the form sends one `name=value` pair for each checked box. A box without a `value` sends `on`. Toggle the boxes and read what the form would send:

```demo
checkbox-values
```

```zig
ui.checkbox(.{ .name = "notify", .value = "mail", .label = "Email", .on = true })
ui.checkbox(.{ .name = "notify", .value = "sms", .label = "Text message" })
ui.checkbox(.{ .name = "quiet", .label = "Not between 10 pm and 7 am" })
```

Put a `z` on the form, not on each box, to send them all together. Here the form posts on `change` and keeps its values:

```zig
fn echo(c: *zw.Ctx) !void {
    try c.html("{#if body}{body}{:else}nothing{/if}", .{ .body = c.body });
}
```

## Select all

A parent checkbox over a list. The server keeps nothing: every request carries the checked rows. The parent is checked when all rows are, and mixed when only some are. Its own request checks or clears every row, and each row's change re-renders the parent and the count badge.

```demo
checkbox-select-all
```

```zig
fn rowsChanged(c: *zw.Ctx) !void {
    const mask = selected(c.body); // rows in `m=0&m=3`
    const n = @popCount(mask);
    try c.html("{parent}{count}", .{
        .parent = parent(.{ .on = n == rows.len, .mixed = n > 0 and n < rows.len }), // oob div around ui.checkbox
        .count = ui.badge(.{ .id = "count", .count = n, .hide_zero = true, .oob = true }),
    });
}
```

A mixed checkbox is a visual start state: when the page recomputes it, re-render it with the new `on` or `mixed`. Here the response replaces the parent out of band.

## In a form

A required checkbox. Submit without it and the handler sends the form back with `invalid` set, plus an error toast:

```demo
checkbox-form
```

```zig
fn order(c: *zw.Ctx) !void {
    const terms = c.form("terms") != null; // unchecked boxes are not sent
    try c.html("{form}{toast}", .{
        .form = checkout(.{ .gift = c.form("gift") != null, .invalid = !terms }),
        .toast = ui.toast(.{ .text = "Accept the terms to place your order", .kind = .@"error" }),
    });
}
```

## Props

| Prop | Type | Default | Notes |
|---|---|---|---|
| `name` | string | required | the form field name; boxes can share one |
| `label` | string | required | shown next to the box |
| `value` | string | `"on"` | sent as `name=value` when checked; nothing is sent when unchecked |
| `on` | bool | `false` | starts checked |
| `description` | string | none | secondary line under the label |
| `mixed` | bool | `false` | starts in the mixed state: a dash and `aria-checked="mixed"`. Overrides `on`; the first click checks it |
| `disabled` | bool | `false` | dimmed, not interactive, not submitted |
| `invalid` | bool | `false` | red box and `aria-invalid`, for a required box left unchecked; the red goes away once the box is checked |
| `z` | `ui.Z` | none | sent on `change`; the box's `name=value` goes with it, or an empty body when unchecked |

The whole label is the click target, at least 44px tall on touch screens. The mark and dash use `--on-accent` on the accent color, so they follow the system accent in light and dark mode.
