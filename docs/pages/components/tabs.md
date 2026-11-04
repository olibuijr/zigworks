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

`ui.Tabs(Panels)` names the type. Use tabs for peer sections of the same window; use the sidebar for navigation between pages.
