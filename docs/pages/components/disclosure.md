# Disclosure

A titled section that opens and closes, for details most people don't need, such as advanced settings or FAQ answers. It is a `<details>` element, so it works without JavaScript; the chevron turns and the height springs open.

```demo
disclosure
```

## Usage

```zig
ui.disclosure(.{ .title = "Advanced", .body = advanced_settings })
```

## Props

| Prop | Type | Default | Notes |
|---|---|---|---|
| `title` | string | required | always visible |
| `open` | bool | `false` | |
| `body` | component | required | |
