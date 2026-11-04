# Island

A slot for client-side JavaScript: canvas, WebGL, three.js, charts. z.js imports the module and calls its default export with the element and the parsed props.

```demo
island
```

## Usage

```zig
ui.island(.{ .src = "/orbit.js", .props = "{\"planets\":5}", .height = "220px", .label = "Animated orbit" })
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
| `height` | string | `"360px"` | CSS height reserved before it loads |
| `label` | string | `"Interactive content"` | accessible description |

See [Islands and three.js](/islands) for import maps and a full 3D scene.
