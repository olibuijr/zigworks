# Islands and three.js

Most of a zigworks page is server-rendered HTML. When a part needs real JavaScript, such as a 3D scene, a chart or an editor, make it an island: z.js imports an ES module and hands it an element.

```demo
island
```

## Write the module

Put it in `public/`, which is served at `/`. Export a default function that takes the element and its props, and return a cleanup function:

```js
export default function mount(el, props) {
  const canvas = document.createElement('canvas');
  el.append(canvas);
  // draw...
  return () => canvas.remove();
}
```

## Mount it

```zig
ui.island(.{
    .src = "/scene.js",
    .props = "{\"speed\":1}",
    .height = "420px",
    .label = "Rotating 3D model",
});
```

Islands mount on page load and whenever z.js swaps in HTML that contains one. When an island is swapped out, its cleanup runs.

## three.js

Map the bare `three` import with an import map in the layout's `head`:

```zig
const importmap =
    \\<script type="importmap">{"imports":{"three":"https://cdn.jsdelivr.net/npm/three@0.170.0/build/three.module.js"}}</script>
;

try c.page(ui.layout(.{ .title = "Scene", .head = importmap, .body = ui.island(.{ .src = "/scene.js" }) }));
```

Then `import * as THREE from 'three'` works in `public/scene.js`. See `examples/scene` for a complete scene with resizing, Reduce Motion and cleanup. To run offline, copy three into `public/` and point the import map there.

## Static files

`public/` files are served with the right type for JS modules, wasm, glTF (`.glb`, `.gltf`), `.hdr`, `.ktx2`, images, fonts, audio and video. Hidden files and `..` paths are refused.
