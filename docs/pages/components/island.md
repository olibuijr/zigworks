# Island

A slot for client-side JavaScript: canvas, WebGL, three.js, charts. z.js imports the module and calls its default export with the element and the parsed props. Until the module draws something the island shows a shimmering placeholder.

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

See [Islands and three.js](/islands) for import maps and a full 3D scene.
