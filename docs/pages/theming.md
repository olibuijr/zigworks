# Theming

All styling comes from design tokens: Zig struct fields that become CSS custom properties in `/_zw/zw.css`. The defaults follow the macOS Human Interface Guidelines: system fonts, the macOS text styles and the semantic colors of AppKit.

```zig
const purple = blk: {
    var p = zw.css.light;
    p.accent = "#8944ab";
    break :blk p;
};

const app = .{
    .routes = .{...},
    .tokens = .{ .radius = "12px", .light = purple },
};
```

## Token names

Field names become variables with dashes: `radius_control` becomes `--radius-control`. Use them in your own CSS through `app.css`, which is appended to the stylesheet:

```zig
const app = .{
    .routes = .{...},
    .css = ".note{color:var(--secondary);font:var(--callout)}",
};
```

## Type

| Token | Value |
|---|---|
| `--large-title` | 26/32 |
| `--title1` | 22/26 |
| `--title2` | 17/22 |
| `--title3` | 15/20 |
| `--headline` | 13/16 bold |
| `--body` | 13/16 |
| `--callout` | 12/15 |
| `--footnote` | 10/13 |

Use them as font shorthands: `font: var(--headline)`.

## Color

Palettes use AppKit's semantic names: `window`, `content`, `control`, `label`, `secondary`, `tertiary`, `separator`, `fill`, `accent`, `red`, `green`, `orange` and the code colors. Light and dark palettes switch with the system appearance.

## Accessibility

Reduce Transparency makes glass opaque, Increase Contrast strengthens separators, and Reduce Motion turns animation off. Focus rings are always visible for keyboard users.

## Glass and motion

Glass and spring tokens (`glass`, `glass_thick`, `glass_clear`, `glass_rim`, `glass_sheen`, `glass_filter`, `spring`, `spring_bouncy`, `dur`…) work like the rest. See [Liquid Glass](/glass) for how the material and its motion work.
