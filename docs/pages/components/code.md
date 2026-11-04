# Code

A code block with a language label, a Copy button and server-side highlighting for Zig. Markdown fences render the same component. It can show a file name, line numbers and highlighted lines.

```demo
code
```

## Options

Each prop on its own: the label above a block names the prop it shows.

```demo
code-options
```

## States

Long lines, other languages, empty source and ignored settings.

```demo
code-states
```

## Try it

Change a control and the server renders the block again from the request. The badge shows what the settings did.

```demo
code-playground
```

## In context

Code blocks inside a card, tabs, a callout and a disclosure.

```demo
code-compose
```

## Usage

```zig
ui.code(.{ .src = @embedFile("example.zig") })
ui.code(.{ .lang = "sh", .src = "zig build run" })
ui.code(.{ .title = "src/main.zig", .numbers = true, .highlight = "2,4-5", .src = @embedFile("main.zig") })
ui.code(.{ .lang = "sh", .wrap = true, .src = "curl -fsSL https://example.com/a/very/long/install/script.sh | sh" })
ui.code(.{ .title = "src/ui/code.zig", .numbers = true, .start = 120, .highlight = "120,122-123", .src = excerpt })
ui.code(.{ .lang = "text", .copy = false, .src = "Read-only output." })
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
- Highlighted line numbers count from `start`. Parts that are not numbers or ranges are skipped, lines past the end of the source are skipped, and a range that runs past the end stops at the last line.
- Only `zig` is highlighted. Any other `lang` is shown as plain text under that label; an empty `lang` shows "text", or just the file name when there is a `title`.
- `wrap` turns off `numbers` and `highlight`, because bands and the gutter assume one row per line.
- Fences in Markdown pages (` ```zig `) render this component with its defaults.
