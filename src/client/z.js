// z.js: htmx-style attributes and islands for zigworks. No dependencies.
// z-get|z-post|z-put|z-patch|z-delete="/url"   z-target="#sel" | "closest li"   z-swap="inner|outer|beforeend|afterbegin|delete|none"
// z-trigger="click|submit|change|input|load"   z-confirm="Sure?"   z-island="/mod.js" data-props='{}'
// Response elements with z-oob and an id replace the element with that id, wherever it is.
// Also wires ui components that need a touch of JS: picker label, slider fill, closing popovers.
(() => {
  const verbs = ['get', 'post', 'put', 'patch', 'delete'];
  const sel = verbs.map((v) => `[z-${v}]`).join();
  const attr = (el, n) => el.getAttribute('z-' + n);

  const ask = (msg) => new Promise((done) => {
    const d = document.createElement('dialog');
    d.className = 'zw-dialog';
    d.innerHTML = '<p></p><div class="zw-row"><button class="zw-btn zw-btn--secondary" value="">Cancel</button><button class="zw-btn zw-btn--primary" value="1">OK</button></div>';
    d.querySelector('p').textContent = msg;
    d.onclick = (e) => { if (e.target.tagName === 'BUTTON') { done(!!e.target.value); d.close(); } };
    d.onclose = () => { done(false); d.remove(); };
    document.body.append(d);
    d.showModal();
  });

  async function fire(el) {
    const msg = attr(el, 'confirm');
    if (msg && !(await ask(msg))) return;
    const verb = verbs.find((v) => el.hasAttribute('z-' + v));
    const form = el.tagName === 'FORM';
    const off = el.type === 'checkbox' && !el.checked;
    const data = new URLSearchParams(form ? new FormData(el) : el.name && !off ? [[el.name, el.value]] : []);
    let url = attr(el, verb), body = null;
    if (verb === 'get') { const q = data.toString(); if (q) url += (url.includes('?') ? '&' : '?') + q; } else body = data;
    const tsel = attr(el, 'target');
    const target = !tsel ? el : tsel.startsWith('closest ') ? el.closest(tsel.slice(8)) : document.querySelector(tsel);
    el.classList.add('zw-busy');
    try {
      const res = await fetch(url, { method: verb.toUpperCase(), body, headers: { 'z-request': '1' } });
      const to = res.headers.get('z-redirect');
      if (to) return location.assign(to);
      if (!res.ok) throw new Error(`${res.status} ${verb.toUpperCase()} ${url}`);
      if (res.status !== 204 && target) swap(target, attr(el, 'swap') || 'inner', await res.text());
      if (form && verb !== 'get') el.reset();
      el.closest('[popover]')?.hidePopover();
    } catch (e) {
      console.error('z.js', e);
    } finally {
      el.classList.remove('zw-busy');
    }
  }

  function swap(t, mode, html) {
    const tpl = document.createElement('template');
    tpl.innerHTML = html;
    for (const o of tpl.content.querySelectorAll('[z-oob][id]')) {
      const old = document.getElementById(o.id);
      if (old) { unmount(old); old.replaceWith(o); mount(o); } else o.remove();
    }
    if (mode === 'none') return;
    if (mode === 'delete') { unmount(t); return t.remove(); }
    const nodes = [...tpl.content.children];
    const added = mode === 'beforeend' || mode === 'afterbegin';
    if (mode === 'outer') { unmount(t); t.replaceWith(tpl.content); }
    else if (mode === 'inner') { [...t.children].forEach(unmount); t.replaceChildren(tpl.content); }
    else if (mode === 'beforeend') t.append(tpl.content);
    else if (mode === 'afterbegin') t.prepend(tpl.content);
    else return console.error('z.js: unknown z-swap', mode);
    // Only new content animates, so motion shows what changed.
    for (const n of nodes) { if (added) n.classList.add('zw-enter'); mount(n); }
  }

  // Islands: `export default function (el, props) { ...; return cleanup? }`
  function mount(root) {
    const found = root.querySelectorAll('[z-island],[z-trigger=load]');
    for (const el of root.matches('[z-island],[z-trigger=load]') ? [root, ...found] : found) {
      if (el._zw) continue;
      el._zw = true;
      if (el.hasAttribute('z-island')) {
        import(new URL(attr(el, 'island'), location.href).href)
          .then((m) => { el._zwStop = m.default(el, JSON.parse(el.dataset.props || '{}')); })
          .catch((e) => console.error('z.js island', e));
      }
      if (attr(el, 'trigger') === 'load') fire(el);
    }
    root.querySelectorAll('.zw-slider input').forEach(fill);
  }

  const fill = (i) => i.style.setProperty('--zw-fill', ((i.value - i.min) / (i.max - i.min)) * 100 + '%');

  function unmount(root) {
    for (const el of [root, ...root.querySelectorAll('[z-island]')]) {
      if (typeof el._zwStop === 'function') el._zwStop();
    }
  }

  document.addEventListener('input', (e) => { if (e.target.closest('.zw-slider')) fill(e.target); });
  // Esc in a search field dismisses its results (they hide once the field loses focus).
  document.addEventListener('keydown', (e) => { if (e.key === 'Escape' && e.target.closest('.zw-search')) e.target.blur(); });
  document.addEventListener('click', async (e) => {
    const b = e.target.closest('[data-copy]');
    if (!b) return;
    try { await navigator.clipboard.writeText(b.closest('figure').querySelector('code').textContent); b.textContent = 'Copied'; }
    catch { b.textContent = 'Copy failed'; }
    setTimeout(() => (b.textContent = 'Copy'), 1500);
  });
  document.addEventListener('change', (e) => {
    const picker = e.target.closest('.zw-picker');
    if (!picker) return;
    picker.querySelector('.zw-picker-value').textContent = e.target.parentElement.textContent;
    picker.querySelector('[popover]').hidePopover();
  });

  for (const type of ['click', 'submit', 'change', 'input']) {
    document.addEventListener(type, (e) => {
      const el = e.target.closest?.(sel);
      if (!el) return;
      const field = el.matches('input,select,textarea');
      if ((attr(el, 'trigger') || (el.tagName === 'FORM' ? 'submit' : field ? 'change' : 'click')) !== type) return;
      if (type !== 'input' && type !== 'change') e.preventDefault();
      if (type === 'input') { clearTimeout(el._zwT); el._zwT = setTimeout(() => fire(el), 250); } else fire(el);
    });
  }

  mount(document.body);
})();
