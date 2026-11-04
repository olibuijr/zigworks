// glass.js: Liquid Glass for zigworks. Served after z.js; no dependencies.
//
// Refraction: each `.zw-glass` element gets an SVG displacement filter shaped like its own rounded
// rectangle (a signed-distance-field bezel), exposed as `--zw-lens: url(#...)` and used by
// `backdrop-filter`. Edges bend what is behind them, like a convex glass drop. Only Chromium can use
// SVG filters in backdrop-filter; other browsers keep the blur + rim material. Filters are cached
// per size (rounded to 2px), so a page with many equal buttons builds one map; the cache keeps the
// most recently used sizes so elements that track the viewport don't pile up maps on resize.
//
// Light: the specular highlight follows the pointer (`--mx`, `--my`).
// Inertia: pressed `.zw-press` controls stretch toward the pointer (`--dx`, `--dy`, `--sx`, `--sy`)
// and spring back on release (the spring curves live in CSS).
(() => {
  const ns = 'http://www.w3.org/2000/svg';
  const reduceMotion = matchMedia('(prefers-reduced-motion: reduce)');
  const reduceGlass = matchMedia('(prefers-reduced-transparency: reduce)');
  const refract = !!navigator.userAgentData?.brands?.some((b) => b.brand === 'Chromium');
  const maxArea = 600_000; // larger surfaces keep plain blur; the map would cost more than it shows
  const maxLenses = 64;

  let defs = null;
  const made = new Set();

  // Displacement map for a w×h rounded rectangle with radius r. R/G encode the x/y shift
  // (128 = none). Inside the bezel band, pixels sample toward the centre, strongest at the rim.
  // `mag` > 0 also magnifies the middle (knobs read the track through a drop); `rimK` sets how far
  // the rim bends (knobs keep it low so the edge doesn't echo the track back in).
  function lens(w, h, r, id = `zw-lens-${w}-${h}-${r}`, mag = 0, rimK = 0.7) {
    if (made.delete(id)) { made.add(id); return id; } // re-add: most recently used goes last
    if (!defs) {
      const svg = document.createElementNS(ns, 'svg');
      svg.setAttribute('aria-hidden', 'true');
      svg.style.cssText = 'position:absolute;width:0;height:0;overflow:hidden';
      defs = document.createElementNS(ns, 'defs');
      svg.append(defs);
      document.body.append(svg);
    }
    const c = document.createElement('canvas');
    c.width = w;
    c.height = h;
    const ctx = c.getContext('2d');
    const img = ctx.createImageData(w, h);
    const hw = w / 2, hh = h / 2;
    r = Math.min(r, hw, hh);
    const bezel = Math.max(3, Math.min(24, Math.min(w, h) * 0.32));
    const rim = bezel * rimK; // largest inward shift at the rim, px
    const scale = 2 * (rim + Math.max(hw, hh) * mag); // covers the largest shift either way
    for (let j = 0; j < h; j++) {
      for (let i = 0; i < w; i++) {
        const px = i + 0.5 - hw, py = j + 0.5 - hh;
        const qx = Math.abs(px) - (hw - r), qy = Math.abs(py) - (hh - r);
        const ox = Math.max(qx, 0), oy = Math.max(qy, 0);
        const out = Math.hypot(ox, oy);
        const d = out + Math.min(Math.max(qx, qy), 0) - r; // signed distance, negative inside
        let nx, ny;
        if (qx > 0 && qy > 0) { nx = ox / out; ny = oy / out; } else if (qx > qy) { nx = 1; ny = 0; } else { nx = 0; ny = 1; }
        if (px < 0) nx = -nx;
        if (py < 0) ny = -ny;
        const t = Math.min(1, Math.max(0, 1 + d / bezel)); // 0 inside the band, 1 at the rim
        const m = t * t * t * (t * (6 * t - 15) + 10); // smootherstep: flat centre, steep rim
        const sx = -nx * m * rim - px * mag, sy = -ny * m * rim - py * mag;
        const k = (j * w + i) * 4;
        img.data[k] = 128 + (sx / scale) * 255;
        img.data[k + 1] = 128 + (sy / scale) * 255;
        img.data[k + 2] = 128;
        img.data[k + 3] = 255;
      }
    }
    ctx.putImageData(img, 0, 0);
    const f = document.createElementNS(ns, 'filter');
    const set = (el, a) => { for (const k in a) el.setAttribute(k, a[k]); };
    set(f, { id, x: 0, y: 0, width: w, height: h, filterUnits: 'userSpaceOnUse', primitiveUnits: 'userSpaceOnUse', 'color-interpolation-filters': 'sRGB' });
    const map = document.createElementNS(ns, 'feImage');
    set(map, { href: c.toDataURL(), x: 0, y: 0, width: w, height: h, result: 'map', preserveAspectRatio: 'none' });
    const disp = document.createElementNS(ns, 'feDisplacementMap');
    set(disp, { in: 'SourceGraphic', in2: 'map', scale: scale.toFixed(1), xChannelSelector: 'R', yChannelSelector: 'G' });
    f.append(map, disp);
    defs.append(f);
    made.add(id);
    if (made.size > maxLenses) { // drop the least recently used per-size lens (not the knob ones)
      const old = [...made].find((k) => /^zw-lens-\d/.test(k));
      made.delete(old);
      document.getElementById(old)?.remove();
    }
    return id;
  }

  function fit(el) {
    const w = Math.round(el.offsetWidth / 2) * 2, h = Math.round(el.offsetHeight / 2) * 2; // 2px steps
    // Scroll containers keep plain blur: content moving under a fixed lens looks broken.
    const cs = getComputedStyle(el);
    if (!w || !h || w * h > maxArea || /auto|scroll/.test(cs.overflowY)) return el.style.removeProperty('--zw-lens');
    const r = Math.round(parseFloat(cs.borderTopLeftRadius) || 0);
    el.style.setProperty('--zw-lens', `url(#${lens(w, h, r)})`);
  }

  const sizes = refract ? new ResizeObserver((entries) => entries.forEach((e) => fit(e.target))) : null;
  const scan = (root) => {
    if (!sizes || root.nodeType !== 1) return;
    if (root.matches('.zw-glass')) sizes.observe(root);
    root.querySelectorAll('.zw-glass').forEach((el) => sizes.observe(el));
  };

  function start() {
    if (refract && !reduceGlass.matches) {
      document.documentElement.classList.add('zw-refract');
      // Knobs grow into lenses while pressed, at the pressed sizes set in CSS. They grow by
      // width/height, not `scale`: Chromium drops SVG backdrop filters on scaled elements.
      lens(38, 30, 15, 'zw-lens-knob', 0.2, 0.25);
      lens(40, 26, 13, 'zw-lens-thumb', 0.22, 0.25);
      scan(document.body);
      new MutationObserver((ms) => ms.forEach((m) => m.addedNodes.forEach(scan))).observe(document.body, { childList: true, subtree: true });
    }
  }

  // Specular light that follows the pointer across glass.
  let lit = null, frame = 0, last = null;
  document.addEventListener('pointermove', (e) => {
    last = e;
    if (frame) return;
    frame = requestAnimationFrame(() => {
      frame = 0;
      const el = last.target.closest?.('.zw-glass');
      if (lit && lit !== el) lit.style.removeProperty('--zw-glow');
      lit = el;
      if (!el) return;
      const b = el.getBoundingClientRect();
      el.style.setProperty('--mx', `${last.clientX - b.left}px`);
      el.style.setProperty('--my', `${last.clientY - b.top}px`);
      el.style.setProperty('--zw-glow', '1');
    });
  }, { passive: true });

  // Inertia: a pressed control follows the pointer a little and stretches, then springs back.
  let pressed = null, x0 = 0, y0 = 0;
  const clamp = (v, m) => Math.max(-m, Math.min(m, v));
  const release = () => {
    if (!pressed) return;
    pressed.removeAttribute('data-press');
    for (const p of ['--dx', '--dy', '--sx', '--sy']) pressed.style.removeProperty(p);
    pressed = null;
  };
  document.addEventListener('pointerdown', (e) => {
    const el = e.button === 0 && e.target.closest?.('.zw-press');
    if (!el || el.disabled) return;
    pressed = el;
    x0 = e.clientX;
    y0 = e.clientY;
    el.setAttribute('data-press', '');
  });
  document.addEventListener('pointermove', (e) => {
    if (!pressed || reduceMotion.matches) return;
    const dx = clamp((e.clientX - x0) / 4, 6), dy = clamp((e.clientY - y0) / 4, 4);
    pressed.style.setProperty('--dx', `${dx.toFixed(2)}px`);
    pressed.style.setProperty('--dy', `${dy.toFixed(2)}px`);
    pressed.style.setProperty('--sx', (Math.abs(dx) / 60 - Math.abs(dy) / 120).toFixed(3));
    pressed.style.setProperty('--sy', (Math.abs(dy) / 60 - Math.abs(dx) / 120).toFixed(3));
  }, { passive: true });
  for (const t of ['pointerup', 'pointercancel', 'blur']) addEventListener(t, release);

  if (document.body) start(); else document.addEventListener('DOMContentLoaded', start);
})();
