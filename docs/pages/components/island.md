# Island

A slot for client-side JavaScript: canvas, WebGL, three.js, charts. z.js imports the module and calls its default export with the element and the parsed props. Until the module draws something the island shows a shimmering placeholder.

This chart is an island inside a card. The segmented control asks the server for another range: the response swaps in a new island (the old one's cleanup runs) and updates the badge out of band.

```demo
island
```

## Usage

```zig
ui.island(.{ .src = "/orbit.js", .props = "{\"planets\":5}", .height = "220px", .label = "Animated orbit" })
ui.island(.{ .src = "/chart.js", .aspect = "16/9", .label = "Sales chart", .fallback = "Turn on JavaScript to see the chart." })
```

```js
// public/orbit.js
export default function mount(el, props) {
  const canvas = el.appendChild(document.createElement('canvas'));
  // ...draw props.planets planets...
  return () => canvas.remove(); // runs when the island is swapped out
}
```

## Height and aspect

Give an island a fixed `height`, or an `aspect` ratio so it scales with its width, which suits phones. When both are set, `aspect` wins.

```demo
island-sizes
```

## Loading

The placeholder fills the wait while the module loads. Set `loading` to `false` for modules that draw at once, or when you show your own spinner. These two modules take 2.5 seconds; Reload mounts fresh islands so you can watch it again.

```demo
island-loading
```

Without JavaScript the placeholder is hidden and `fallback` is shown instead, so a page that needs the island still says something useful.

## Props from the server

`props` is a JSON string, so the server can build it from the request. This form sends its values with `z-get`; the handler answers with an island whose `props`, `aspect` and `label` follow them. Nothing is kept on the server.

```demo
island-props
```

```zig
fn orbit(c: *zw.Ctx) !void {
    const n = std.math.clamp(std.fmt.parseInt(u8, c.query("n") orelse "5", 10) catch 5, 1, 8);
    try c.page(ui.island(.{
        .src = "/orbit.js",
        .props = try std.fmt.allocPrint(c.arena, "{{\"planets\":{d}}}", .{n}),
        .aspect = "21/9",
        .label = "Orbit preview",
    }));
}
```

## With other components

An island is a plain block, so it sits in a card, a tab panel or a sheet. A panel that is not showing has no size: a module should wait until it has one (a `ResizeObserver` does this) and draw again when it changes.

```demo
island-compose
```

## Props

| Prop | Type | Default | Notes |
|---|---|---|---|
| `src` | string | required | ES module URL |
| `props` | string | `"{}"` | JSON passed to the module |
| `height` | string | `"360px"` | CSS height reserved before it loads; ignored with `aspect` |
| `label` | string | `"Interactive content"` | accessible name (the island is a `role="group"`) |
| `aspect` | string | `""` | CSS aspect ratio such as `"16/9"`: the island scales with its width, which suits phones |
| `loading` | bool | `true` | show the placeholder until the module adds its own content |
| `fallback` | string | `""` | text shown when JavaScript is off |

## Notes

- The placeholder disappears as soon as the module adds any element to the island (a canvas, a div). A module that fails to load leaves it in place, and the error goes to the console.
- Pick `aspect` for charts and scenes that should keep their proportions, `height` for editors and panels.
- The module may return a cleanup function. z.js calls it when the island is swapped out of the page.
- Give every island a `label` that says what it shows; screen readers announce it as a group.

See [Islands and three.js](/islands) for import maps and a full 3D scene.
