# Table

A simple data table with a header row. Cells are strings and escaped. Wide tables scroll inside their own frame.

```demo
table
```

## Usage

```zig
ui.table(.{
    .head = &.{ "Method", "Path" },
    .rows = &.{
        &.{ "GET", "/" },
        &.{ "POST", "/todos" },
    },
})
```

## Props

| Prop | Type | Default | Notes |
|---|---|---|---|
| `head` | `[]const []const u8` | required | column titles |
| `rows` | `[]const []const []const u8` | required | each row has one cell per column |
