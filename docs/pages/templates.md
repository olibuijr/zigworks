# Templates

Templates are strings compiled by `comptime`. Unknown variables, unclosed blocks and values that cannot be printed are build errors, and everything printed is HTML-escaped unless you ask otherwise.

```zig
try c.html(
    \\<h1>{title}</h1>
    \\{#if todos}<ul>{#each todos as t, i}<li>{i}. {t.title}</li>{/each}</ul>
    \\{:else}<p>Nothing yet.</p>{/if}
, .{ .title = "Todos", .todos = todos });
```

## Syntax

| Tag | Meaning |
|---|---|
| `{expr}` | print, escaped |
| `{@html expr}` | print without escaping |
| `{#if expr}…{:else}…{/if}` | condition; `!expr` negates |
| `{#each list as item, i}…{/each}` | loop, index optional |
| `{{` | a literal `{` |

`expr` is a path into the data: `title`, `todo.done`, `todos.len`. Inside `#each`, outer variables stay visible.

## What can be printed

Strings, integers, floats, booleans, enums (their name) and optionals (nothing when null). Anything with a `render(self, *Writer)` method is written as-is: that is how components nest.

## What counts as true

`true`, a non-null optional, a non-empty slice or string, and a non-zero number.

## Components

`zw.view(src, data)` turns a template into a value you can pass around, and `zw.View(src, Data)` names its type for return types:

```zig
pub const Row = zw.View("<li>{t.title}</li>", struct { t: Todo });

pub fn row(t: Todo) Row {
    return .{ .data = .{ .t = t } };
}

// Render one per item:
const rows = zw.each(todos, row);
```

## Props with defaults

`zw.props(T, .{...})` fills a props struct from an anonymous one, using defaults for missing fields. A missing required field or a misspelled one is a compile error naming the prop.

```zig
const Props = struct { label: []const u8, size: u8 = 13 };
const p = zw.props(Props, .{ .label = "Hi" }); // size = 13
```
