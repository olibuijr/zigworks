// Island for the docs that takes 2.5 s to draw, to show the loading placeholder. props = {"text":"..."}.
export default function (el, p) {
  const t = setTimeout(() => {
    const d = document.createElement('div');
    d.className = 'demo-island-ready';
    d.textContent = p.text;
    el.append(d);
  }, 2500);
  return () => clearTimeout(t);
}
