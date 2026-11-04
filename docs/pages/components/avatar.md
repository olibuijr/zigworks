# Avatar

A person's picture, or their initials on a color chosen from their name. The same name always gets the same color, on every page.

```demo
avatar
```

## Usage

```zig
ui.avatar(.{ .name = "Ada Lovelace" })
ui.avatar(.{ .name = "Grace Hopper", .src = "/img/grace.jpg", .size = 44 })
```

## Props

| Prop | Type | Default | Notes |
|---|---|---|---|
| `name` | string | required | initials, color and accessible label |
| `src` | string | `""` | image URL; initials when empty |
| `size` | u16 | `32` | diameter in px |
