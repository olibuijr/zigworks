# Radio group

A list of choices where exactly one is selected. Use it when the labels are long or there are more than a few; for two to five short choices in a row, use a [segmented control](/components/segmented).

Pick an option and the badge in the header follows. The change posts to a small route that answers with the new badge.

```demo
radio
```

## Usage

```zig
ui.radio(.{ .name = "open", .label = "New windows open with", .options = &.{
    .{ .value = "recent", .label = "Recents", .selected = true },
    .{ .value = "home", .label = "Home folder" },
} })
```

Add `.z` to send the choice as soon as it changes. The request body is `name=value`:

```zig
ui.radio(.{
    .name = "open",
    .label = "New windows open with",
    .z = .{ .post = "/settings/open", .swap = .none },
    .options = &.{ ... },
})
```

## Layout and descriptions

`layout` is `.vertical` (the default) or `.horizontal`. A horizontal group wraps onto new lines on narrow screens. `description` adds a secondary line under an option's label.

```demo
radio-layout
```

```zig
ui.radio(.{ .name = "plan", .label = "Plan", .layout = .horizontal, .options = &.{
    .{ .value = "free", .label = "Free", .description = "1 project", .selected = true },
    .{ .value = "team", .label = "Team", .description = "Unlimited" },
    .{ .value = "ent", .label = "Enterprise", .disabled = true },
} })
```

## States

Set `disabled` on one option to dim it, or on the group to dim every option. A group with no `selected` option starts empty. Long labels wrap and stay aligned with the button.

The last group is disabled until the switch is on. The switch posts to a route that sends the group back with `disabled` changed.

```demo
radio-states
```

## Updating the page

A change can update other parts of the page. This order summary sits outside the radio group: the route answers with the new summary marked `z-oob`, and z.js swaps it in by id. The server keeps nothing; the choice travels in the request.

```demo
radio-checkout
```

```zig
fn shipPick(c: *zw.Ctx) !void {
    const value = c.form("ship") orelse "";
    // look the price up, then answer with the summary (id + z-oob)
    try c.page(summary(value))
}
```

## In a form

Radio groups work as ordinary form fields. Here a field, two groups and a button share one form. No format is preselected, so exporting without choosing one gets an error toast from the server.

```demo
radio-export
```

## Props

| Prop | Type | Default | Notes |
|---|---|---|---|
| `name` | string | required | form field name, shared by every option |
| `label` | string | required | accessible group name |
| `options` | `[]const ui.RadioOption` | required | `value`, `label`, `selected` (default `false`), `description` (secondary line, default none) and `disabled` (default `false`) |
| `layout` | `.vertical` `.horizontal` | `.vertical` | `.horizontal` wraps onto new lines on narrow screens |
| `disabled` | bool | `false` | disables the whole group |
| `z` | `ui.Z` | none | set on every option's input; fires on `change` |

Arrow keys move between options and each row is at least 44px tall on touch screens. Give each group on a page its own `name`: options that share a name belong to the same group.
