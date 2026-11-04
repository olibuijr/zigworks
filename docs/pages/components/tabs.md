# Tabs

A tab view: a segmented control above panels, showing one panel at a time, like the tabs in a macOS settings window. It switches with radio inputs and CSS, so it works without JavaScript; the glass pill slides between tabs and each panel springs in.

A preferences window. Each tab holds a card of settings, and every control saves through z.js.

```demo
tabs
```

## Usage

```zig
ui.tabs(.{
    .id = "prefs",
    .labels = &.{ "General", "Sharing" },
    .panels = .{ general, sharing },
})
```

`panels` is a tuple with one component (or string) per label. The panels can be different component types.

## Props

| Prop | Type | Default | Notes |
|---|---|---|---|
| `id` | string | required | unique per page; names the radio group |
| `labels` | `[]const []const u8` | required | one per panel, up to 8 |
| `panels` | tuple of components | required | shown in label order |
| `selected` | usize | `0` | the panel shown first |
| `label` | string | `""` | accessible name of the tab strip; the `id` when empty |
| `badges` | `[]const []const u8` | `&.{}` | badge text per tab, by position, such as a count; an empty string or a missing entry shows none |
| `disabled` | `[]const usize` | `&.{}` | indexes of tabs that can't be chosen; they are dimmed and skipped by the arrow keys |
| `full_width` | bool | `false` | stretch the strip across the container, tabs of equal width |

## Selected, badges, disabled and full width

Each strip is captioned with the props that shape it. `selected` picks the tab shown first, `badges` adds a count per tab, `disabled` dims tabs that can't be chosen, and `full_width` gives the tabs equal widths across the container. The last strip has `selected` pointing at a disabled tab: its panel still shows first.

```demo
tabs-options
```

```zig
ui.tabs(.{
    .id = "inbox",
    .label = "Mailbox",
    .labels = &.{ "Inbox", "Drafts", "Junk" },
    .badges = &.{ "12", "", "3" },
    .disabled = &.{2},
    .full_width = true,
    .selected = 1,
    .panels = .{ inbox, drafts, junk },
})
```

## Loading, empty and error panels

A panel is any component, so the usual states live inside it: a progress bar and skeleton while syncing, an empty state with an action, and a callout with an invalid field when something went wrong. A badge on the tab tells people there is something to look at before they open it.

```demo
tabs-states
```

## Updating from the server

The tab strip has no `z` prop, but the panels do whatever their content does. Here the Archive and Move to Inbox buttons post to the server, which answers with the whole mailbox again: the rows move to the other tab and both badges follow the counts. Archiving also sends a toast with Undo. The server keeps nothing; the set of archived messages travels in the URL of each button.

```demo
tabs-live
```

```zig
fn mailbox(c: *zw.Ctx) !void {
    // ?m=<archived bitmask>&t=<message to toggle>&s=<tab to show>
    try c.page(Mailbox{ .mask = mask, .sel = sel });
}

// A button inside a panel replaces the box that holds the tabs.
ui.button(.{ .label = "Archive", .variant = .plain, .z = .{
    .post = "/mail?m=0&t=2&s=0",
    .target = "#mail",
    .swap = .outer,
} })
```

Wrap the tabs in an element with an `id` to give z.js something to target; the tabs themselves have none.

## In a form

Tabs hold inputs like any other container. Every field in every panel belongs to the same form, so one Save button covers the whole window, whichever tab is showing. Here the tabs sit in a card whose footer holds the buttons. Saving with an empty name answers with an error toast. The tag buttons remove their tag.

```demo
tabs-form
```

```zig
zw.view("<form{z}>{card}</form>", .{
    .z = ui.Z{ .post = "/project", .swap = .none, .keep = true },
    .card = ui.card(.{ .title = "Project", .body = tabs, .footer = buttons }),
})
```

## Notes

- The arrow keys move between tabs, because each tab is a native radio input. Each panel is labelled with its tab.
- Every panel is in the page from the start, only one is visible. Content that must be fetched on demand needs its own request.
- The radio group is named after `id`, so inside a form the chosen tab is submitted as `id=Label`.
- Long labels are shortened with an ellipsis, and the strip tightens its padding below 480px. On touch screens the tabs are 44px tall.
- A disabled tab is never chosen, but if `selected` points at one, that panel still shows first.

`ui.Tabs(Panels)` names the type. Use tabs for peer sections of the same window; use the sidebar for navigation between pages.
