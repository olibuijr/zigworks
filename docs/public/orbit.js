// Island demo without dependencies: planets orbiting on a 2D canvas, in the page's accent color.
export default function mount(el, { planets = 5 }) {
  const canvas = document.createElement('canvas');
  el.append(canvas);
  const g = canvas.getContext('2d');
  const css = getComputedStyle(el);
  const accent = css.getPropertyValue('--accent').trim() || '#007aff';
  const line = css.getPropertyValue('--separator').trim() || 'rgba(0,0,0,.1)';
  const still = matchMedia('(prefers-reduced-motion: reduce)').matches;
  let w = 0, h = 0, raf = 0;

  const resize = () => {
    const r = el.getBoundingClientRect();
    w = r.width; h = r.height;
    canvas.width = w * devicePixelRatio; canvas.height = h * devicePixelRatio;
    g.setTransform(devicePixelRatio, 0, 0, devicePixelRatio, 0, 0);
  };
  const observer = new ResizeObserver(resize);
  observer.observe(el);
  resize();

  const draw = (t) => {
    if (w < 24 || h < 24) { raf = requestAnimationFrame(draw); return; } // hidden (closed tab or sheet): wait for a size
    g.clearRect(0, 0, w, h);
    const cx = w / 2, cy = h / 2, max = Math.min(w, h) / 2 - 12;
    g.fillStyle = accent;
    g.beginPath(); g.arc(cx, cy, 9, 0, Math.PI * 2); g.fill();
    for (let i = 1; i <= planets; i++) {
      const r = (max / planets) * i;
      g.strokeStyle = line; g.lineWidth = 1;
      g.beginPath(); g.arc(cx, cy, r, 0, Math.PI * 2); g.stroke();
      const a = (still ? 0 : t / 1000) * (1.6 / i) + i * 1.3;
      g.globalAlpha = 1 - i / (planets + 2);
      g.beginPath(); g.arc(cx + Math.cos(a) * r, cy + Math.sin(a) * r, 5 - i * 0.4, 0, Math.PI * 2); g.fill();
      g.globalAlpha = 1;
    }
    if (!still) raf = requestAnimationFrame(draw);
  };
  raf = requestAnimationFrame(draw);

  return () => { cancelAnimationFrame(raf); observer.disconnect(); canvas.remove(); };
}
