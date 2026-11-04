// Bar chart island for the docs: props = {"values":[...]}; the last bar is highlighted.
// Redraws on resize and skips drawing while hidden (a closed tab or sheet has no size).
export default function (el, p) {
  const c = document.createElement('canvas'), g = c.getContext('2d'), s = getComputedStyle(el);
  const accent = s.getPropertyValue('--accent').trim() || '#007aff', line = s.getPropertyValue('--separator').trim() || 'rgba(0,0,0,.1)';
  el.append(c);
  const draw = () => {
    const r = el.getBoundingClientRect(), k = devicePixelRatio, n = p.values.length, max = Math.max(...p.values), bw = r.width / n;
    if (r.width < 1 || r.height < 1) return;
    c.width = r.width * k; c.height = r.height * k; g.setTransform(k, 0, 0, k, 0, 0);
    g.strokeStyle = line; g.lineWidth = 1; g.beginPath(); g.moveTo(0, r.height - .5); g.lineTo(r.width, r.height - .5); g.stroke();
    p.values.forEach((v, i) => {
      const h = (r.height - 24) * v / max;
      g.fillStyle = accent; g.globalAlpha = i === n - 1 ? 1 : .45;
      g.beginPath(); g.roundRect(i * bw + bw * .18, r.height - h - 1, bw * .64, h, [5, 5, 0, 0]); g.fill();
    });
    g.globalAlpha = 1;
  };
  const ro = new ResizeObserver(draw);
  ro.observe(el);
  return () => { ro.disconnect(); c.remove(); };
}
