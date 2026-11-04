# Tabs

A tab view: a segmented control above panels, showing one panel at a time, like the tabs in a macOS settings window. It switches with radio inputs and CSS, so it works without JavaScript; the glass pill slides between tabs and each panel springs in.

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

## Badges, disabled tabs and full width

```zig
ui.tabs(.{
    .id = "inbox",
    .label = "Mailbox",
    .labels = &.{ "Inbox", "Drafts", "Archive" },
    .badges = &.{ "12", "" },
    .disabled = &.{2},
    .full_width = true,
    .panels = .{ inbox, drafts, archive },
})
```

## Notes

- The arrow keys move between tabs, because each tab is a native radio input. Each panel is labelled with its tab.
- Long labels are shortened with an ellipsis, and the strip tightens its padding below 480px. On touch screens the tabs are 44px tall.
- A disabled tab is never chosen, but if `selected` points at one, that panel still shows first.

`ui.Tabs(Panels)` names the type. Use tabs for peer sections of the same window; use the sidebar for navigation between pages.
