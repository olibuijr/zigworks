# Code

A code block with a language label, a Copy button and server-side highlighting for Zig. Markdown fences render the same component.

```demo
code
```

## Usage

```zig
ui.code(.{ .src = @embedFile("example.zig") })
ui.code(.{ .lang = "sh", .src = "zig build run" })
```

## Props

| Prop | Type | Default | Notes |
|---|---|---|---|
| `lang` | string | `"zig"` | shown as the label; only `zig` is highlighted |
| `src` | string | required | escaped for you |

The Copy button is handled by z.js and confirms with "Copied". Code blocks scroll sideways instead of wrapping.
