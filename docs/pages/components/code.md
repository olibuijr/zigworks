# Code

A code block with a language label, a Copy button and server-side highlighting for Zig. Markdown fences render the same component. It can show a file name, line numbers and highlighted lines.

```demo
code
```

## Usage

```zig
ui.code(.{ .src = @embedFile("example.zig") })
ui.code(.{ .lang = "sh", .src = "zig build run" })
ui.code(.{ .title = "src/main.zig", .numbers = true, .highlight = "2,4-5", .src = @embedFile("main.zig") })
ui.code(.{ .lang = "sh", .wrap = true, .src = "curl -fsSL https://example.com/a/very/long/install/script.sh | sh" })
```

## Props

| Prop | Type | Default | Notes |
|---|---|---|---|
| `lang` | string | `"zig"` | shown as the label; only `zig` is highlighted |
| `src` | string | required | escaped for you |
| `title` | string | `""` | file name for the caption; the language moves beside it |
| `numbers` | bool | `false` | line numbers in a gutter (not copied) |
| `start` | u32 | `1` | number of the first line, for excerpts |
| `highlight` | string | `""` | lines to emphasize, by number: `"3"` or `"2,5-7"` |
| `wrap` | bool | `false` | wrap long lines instead of scrolling; turns off `numbers` and `highlight` |
| `copy` | bool | `true` | show the Copy button |

## Notes

- The Copy button is handled by z.js and confirms with "Copied". It copies the code only, never the line numbers.
- Without `wrap`, code blocks scroll sideways and can be scrolled with the keyboard once focused.
- Highlighted line numbers count from `start`.
