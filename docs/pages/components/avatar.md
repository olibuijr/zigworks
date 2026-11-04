# Avatar

A person's picture, or their initials on a color chosen from their name. The same name always gets the same color, on every page. A picture that fails to load falls back to the initials.

```demo
avatar
```

Each row starts with an avatar. The dot is the presence status, the rounded one is a group, and Alan Turing has a photo.

## Usage

```zig
ui.avatar(.{ .name = "Ada Lovelace" })
ui.avatar(.{ .name = "Grace Hopper", .src = "/img/grace.jpg", .size = 44, .status = .online })

// An organization: rounded square, fixed color.
ui.avatar(.{ .name = "Zig Software Foundation", .shape = .rounded, .hue = 35 })

// A stack with an overflow chip:
zw.view("<div class=\"zw-avatars\">{a}{b}{c}</div>", .{
    .a = ui.avatar(.{ .name = "Ada Lovelace" }),
    .b = ui.avatar(.{ .name = "Grace Hopper" }),
    .c = ui.avatar(.{ .more = 5 }),
})

// No name yet: a gray silhouette. `neutral` makes a named one gray too.
ui.avatar(.{ .size = 44 })
ui.avatar(.{ .name = "Linus Torvalds", .neutral = true })
```

## Variants and sizes

Size, shape and color, each labelled with the prop that sets it. Without `hue`, the color comes from the name, so Grace Hopper is the same color everywhere.

```demo
avatar-variants
```

## States

Presence (also on a small avatar), a photo that loads and one that fails (the initials stay), a skeleton while the photo loads, how initials are picked, and stacks with an overflow chip, including avatars inside tooltips.

```demo
avatar-states
```

## Try it

Change your status: the server sends back the avatar with the new dot, and a toast. Then type a name to see how it is turned into initials and a color.

```demo
avatar-live
```

## In an app

A share list. Invite a name and the server answers with a new row; Remove deletes a row.

```demo
avatar-compose
```

## Props

| Prop | Type | Default | Notes |
|---|---|---|---|
| `name` | string | `""` | initials, color and accessible label; empty draws a gray silhouette labelled "Anonymous" |
| `src` | string | `""` | image URL; initials when empty, while loading, and if it fails |
| `size` | u16 | `32` | diameter in px |
| `shape` | `.circle` `.rounded` | `.circle` | `.rounded` is a square with soft corners |
| `status` | `.none` `.online` `.away` `.busy` `.offline` | `.none` | presence dot on the bottom corner; added to the accessible label ("Ada, online") |
| `hue` | `?u16` | `null` | color hue 0-359 instead of the one derived from `name` |
| `neutral` | bool | `false` | gray instead of the name-derived color; the initials stay |
| `more` | u16 | `0` | above 0, draws a "+N" overflow chip (label "N more"); `name`, `src`, `status` and `neutral` are ignored |

## Notes

- `<div class="zw-avatars">` overlaps its avatars and gives each a ring in the content color, so stacks read on any surface. Put the `more` chip last.
- Images load lazily. They are decorative: the name is the accessible label.
- `name` can be left out with `more`. Without a name (and without `more`) the avatar is a gray silhouette, so an unnamed user never shows as a blank colored circle.
- Initials are the first character of the first two words. A character keeps its combining marks, emoji skin tone, joined emoji parts and flag.
- The status dot is at least 6px wide, so it stays small on a 24px avatar.
- In a stack, an avatar can sit inside a wrapper such as `ui.tooltip`: every avatar after the first overlaps the one before. The wrapper should be only as wide as the avatar.
- The status dot also differs in shape (offline is an outline), so it is not color-only.
