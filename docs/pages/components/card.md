# Card

An opaque content surface with an optional heading. Group related content in cards; never put glass on them.

```demo
card
```

## Usage

```zig
ui.card(.{
    .title = "Storage",
    .body = zw.view("<p>{used} used</p>", .{ .used = "41 GB" }),
})
```

## Props

| Prop | Type | Default | Notes |
|---|---|---|---|
| `title` | string | `""` | heading at the top |
| `body` | component | required | any component or string |
| `z` | `ui.Z` | none | z.js attributes for the section |

`ui.Card(Body)` names the type when a function returns a card.
