// z.js: htmx-style attributes and islands for zigworks. No dependencies.
// z-get|z-post|z-put|z-patch|z-delete="/url"   z-target="#sel" | "closest li"   z-swap="inner|outer|beforeend|afterbegin|delete|none"
// z-trigger="click|submit|change|input|load|every 2s"   z-confirm="Sure?"   z-keep (form keeps its values)
// z-keep-open (a popover stays open after the request)   z-island="/mod.js" data-props='{}'
// Response elements with z-oob and an id replace the element with that id, wherever it is;
// z-oob="beforeend" appends their children to it instead (toasts use this). Error responses
// still apply their z-oob parts, so a handler can answer 4xx with an error toast.
// Response headers: z-redirect: /url, z-keep (don't reset the form), z-keep-open (keep the popover).
// Also wires ui components that need a touch of JS: picker label, slider fill, closing popovers.
(() => {
  document.documentElement.classList.add('zw-js'); // CSS: JS-drawn parts may replace native ones
  const verbs = ['get', 'post', 'put', 'patch', 'delete'];
  const sel = verbs.map((v) => `[z-${v}]`).join();
  const attr = (el, n) => el.getAttribute('z-' + n);
  const reduced = () => matchMedia('(prefers-reduced-motion: reduce)').matches;

  const ask = (msg) => new Promise((done) => {
    const d = document.createElement('dialog');
    d.className = 'zw-dialog zw-glass';
    d.innerHTML = '<p></p><div class="zw-row"><button class="zw-btn zw-btn--secondary zw-glass zw-press" value="">Cancel</button><button class="zw-btn zw-btn--primary zw-glass zw-press" value="1">OK</button></div>';
    d.querySelector('p').textContent = msg;
    d.onclick = (e) => { if (e.target.tagName === 'BUTTON') { done(!!e.target.value); d.close(); } };
    d.onclose = () => { done(false); setTimeout(() => d.remove(), reduced() ? 0 : 260); };
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
    const pop = el.closest('[popover]'), results = el.closest('.zw-results');
    el.classList.add('zw-busy');
    try {
      const res = await fetch(url, { method: verb.toUpperCase(), body, headers: { 'z-request': '1' } });
      const to = res.headers.get('z-redirect'), has = (h) => res.headers.has(h) || el.hasAttribute(h);
      if (to) return location.assign(to);
      if (!res.ok) { swap(el, 'none', await res.text()); throw new Error(`${res.status} ${verb.toUpperCase()} ${url}`); }
      if (res.status !== 204) { if (target) swap(target, attr(el, 'swap') || 'inner', await res.text()); else console.error('z.js: no target', tsel); }
      if (form && verb !== 'get' && !has('z-keep')) el.reset();
      if (pop?.isConnected && pop.matches(':popover-open') && !has('z-keep-open')) pop.hidePopover();
      if (results?.isConnected && !el.matches('input') && !results.contains(target)) results.replaceChildren(); // a picked result closes the panel
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
      if (!old) { o.remove(); continue; }
      if (o.getAttribute('z-oob') === 'beforeend') {
        const kids = [...o.children];
        old.append(...kids);
        o.remove();
        kids.forEach((k) => { mount(k); if (k.matches('.zw-toast')) setTimeout(() => leave(k), 4000); });
      } else { unmount(old); old.replaceWith(o); mount(o); }
    }
    if (mode === 'none') return;
    if (mode === 'delete') { unmount(t); return leave(t); }
    const nodes = [...tpl.content.children];
    const added = mode === 'beforeend' || mode === 'afterbegin';
    if (mode === 'outer') { unmount(t); t.replaceWith(tpl.content); }
    else if (mode === 'inner') { [...t.children].forEach(unmount); t.replaceChildren(tpl.content); }
    else if (mode === 'beforeend') t.append(tpl.content);
    else if (mode === 'afterbegin') t.prepend(tpl.content);
    else return console.error('z.js: unknown z-swap', mode);
    // Only new content animates, so motion shows what changed. Replaced content gets a brief
    // `zw-swapped` hook (the check uses it to pop) that clears itself.
    for (const n of nodes) {
      n.classList.add(added ? 'zw-enter' : 'zw-swapped');
      if (!added) setTimeout(() => n.classList.remove('zw-swapped'), 1000);
      mount(n);
    }
  }

  // Removed elements fade and collapse along their flow axis (inline ones shrink sideways), eating
  // the parent's gap too so neighbours glide into place. Instant with Reduce Motion.
  function leave(el) {
    if (el.classList.contains('zw-leave')) return;
    if (reduced()) return el.remove();
    let p = el.parentElement;
    if (getComputedStyle(p).display === 'contents') p = p.parentElement;
    const ps = getComputedStyle(p), d = ps.display, row = d.includes('flex') ? !ps.flexDirection.startsWith('column') : !d.includes('grid') && getComputedStyle(el).display.startsWith('inline');
    const [dim, min, pad, edge, gap] = row ? ['width', 'minWidth', 'paddingInline', 'marginInlineEnd', ps.columnGap] : ['height', 'minHeight', 'paddingBlock', 'marginBlockEnd', ps.rowGap];
    el.style[dim] = el[row ? 'offsetWidth' : 'offsetHeight'] + 'px';
    el.style[min] = '0';
    el.classList.add('zw-leave');
    requestAnimationFrame(() => requestAnimationFrame(() => Object.assign(el.style, { [dim]: '0px', [pad]: '0px', [edge]: -(parseFloat(gap) || 0) + 'px' })));
    setTimeout(() => el.remove(), 420);
  }

  // Islands: `export default function (el, props) { ...; return cleanup? }`
  // An island that fails to load gets data-error (the component shows its `failed` text).
  // z-trigger="every 2s" (or 500ms) polls while the page is visible, until the element leaves.
  const live = '[z-island],[z-trigger=load],[z-trigger^="every "]';
  function mount(root) {
    const found = root.querySelectorAll(live);
    for (const el of root.matches(live) ? [root, ...found] : found) {
      if (el._zw) continue;
      el._zw = true;
      if (el.hasAttribute('z-island')) {
        import(new URL(attr(el, 'island'), location.href).href)
          .then((m) => m.default(el, JSON.parse(el.dataset.props || '{}')))
          .then((stop) => { el._zwStop = stop; if (!el.isConnected && typeof stop === 'function') stop(); })
          .catch((e) => { el.setAttribute('data-error', ''); console.error('z.js island', e); });
      }
      const every = /^every (\d+)(ms|s)$/.exec(attr(el, 'trigger') || '');
      if (every) el._zwPoll = setInterval(() => document.hidden || fire(el), every[1] * (every[2] === 's' ? 1000 : 1));
      if (attr(el, 'trigger') === 'load') fire(el);
    }
    root.querySelectorAll('.zw-slider input').forEach(fill);
    root.querySelectorAll('.zw-stepper input').forEach(clampStep);
  }

  function unmount(root) {
    for (const el of [root, ...root.querySelectorAll('[z-island],[z-trigger^="every "]')]) {
      if (typeof el._zwStop === 'function') el._zwStop();
      clearInterval(el._zwPoll);
    }
  }

  // Component wiring: ui components that need a touch of JS (each still works without it).
  // Slider fill and knob position (the knob is drawn over the track so glass can refract it).
  const fill = (i) => {
    const f = (i.value - i.min) / (i.max - i.min);
    i.style.setProperty('--zw-fill', f * 100 + '%');
    i.parentElement.style.setProperty('--zw-f', f);
  };
  // Stepper buttons disable at the bounds, unless the field wraps.
  const clampStep = (i) => {
    const b = i.parentElement.querySelectorAll('[data-step]');
    if (i.disabled || i.hasAttribute('data-wrap')) return;
    if (b.length === 2) { b[0].disabled = i.min !== '' && +i.value <= +i.min; b[1].disabled = i.max !== '' && +i.value >= +i.max; }
  };
  const count = (t, c) => { const n = [...t.value].length, max = +c.dataset.count; c.textContent = `${n} / ${max}`; c.classList.toggle('zw-count--full', n >= max); };
  const pickLabel = (p) => { const c = p.querySelector(':checked'), v = p.querySelector('.zw-picker-value'); if (c) { v.textContent = c.closest('label').querySelector('.zw-pick-text').textContent; v.classList.remove('is-placeholder'); } };
  // Slider value label, textarea character counter.
  document.addEventListener('input', (e) => {
    const t = e.target, s = t.closest('.zw-slider'), c = t.closest('.zw-textarea')?.querySelector('[data-count]');
    if (s) { fill(t); const o = s.querySelector('.zw-slider-value'); if (o) o.textContent = t.value + o.dataset.unit; }
    if (c) count(t, c);
  });
  // A form reset puts counters, picker labels and slider fills back (values restore after the event).
  document.addEventListener('reset', (e) => setTimeout(() => {
    const f = e.target;
    f.querySelectorAll?.('.zw-textarea [data-count]').forEach((c) => count(c.closest('.zw-textarea').querySelector('textarea'), c));
    f.querySelectorAll?.('.zw-picker').forEach(pickLabel);
    f.querySelectorAll?.('.zw-slider input').forEach((i) => { fill(i); const o = i.closest('.zw-slider').querySelector('.zw-slider-value'); if (o) o.textContent = i.value + o.dataset.unit; });
    f.querySelectorAll?.('.zw-stepper input').forEach(clampStep);
  }));
  // A mixed checkbox becomes a plain one after the first click; steppers clamp typed values
  // (before any z request on the same change) and re-check their bounds; a picker shows the
  // chosen option as its label and closes.
  document.addEventListener('change', (e) => {
    const t = e.target, picker = t.closest?.('.zw-picker');
    if (t.hasAttribute?.('data-mixed')) { t.removeAttribute('data-mixed'); t.removeAttribute('aria-checked'); }
    if (t.closest?.('.zw-stepper') && t.matches('input')) {
      if (t.value !== '' && !t.readOnly) { const v = Math.min(t.max === '' ? Infinity : +t.max, Math.max(t.min === '' ? -Infinity : +t.min, +t.value)); if (v !== +t.value) t.value = v; }
      clampStep(t);
    }
    if (t.matches?.('.zw-toast-x')) leave(t.closest('.zw-toast'));
    if (picker) { pickLabel(picker); picker.querySelector('[popover]').hidePopover(); }
  });
  // Sheets focus their first field when they open.
  document.addEventListener('toggle', (e) => {
    const s = e.target;
    if (e.newState === 'open' && s.matches?.('[data-focus-first]')) (s.querySelector('[autofocus],input:not([type=hidden]):not([disabled]),textarea:not([disabled])') || s).focus();
  }, true);
  // Menus: arrow keys, Home and End move between enabled items. ⌘K / Ctrl+K style shortcuts focus
  // the first visible search field with that data-shortcut. In a search field, ↓ moves into its
  // results and ↑/↓ move between them (↑ from the first goes back to the field). Esc blurs a
  // search field or tip (results hide then) and hides a tip shown by hover.
  document.addEventListener('keydown', (e) => {
    const t = e.target, m = t.closest?.('.zw-menu');
    if (m && ['ArrowDown', 'ArrowUp', 'Home', 'End'].includes(e.key)) {
      const items = [...m.querySelectorAll('[role^=menuitem]:not([disabled]):not([aria-disabled=true])')];
      const i = items.indexOf(document.activeElement);
      items.at({ ArrowDown: i + 1, ArrowUp: i - 1, Home: 0, End: items.length - 1 }[e.key] % items.length)?.focus();
      e.preventDefault();
    }
    const f = (e.metaKey || e.ctrlKey) && !e.altKey && [...document.querySelectorAll(`.zw-search [data-shortcut="${CSS.escape(e.key.toLowerCase())}"]`)].find((i) => !i.disabled && i.offsetParent);
    if (f) { e.preventDefault(); f.focus(); f.select(); }
    const box = t.closest?.('.zw-search');
    if (box && (e.key === 'ArrowDown' || e.key === 'ArrowUp')) {
      const links = [...box.querySelectorAll('.zw-results a')], i = links.indexOf(t);
      const next = t.matches('input') ? (e.key === 'ArrowDown' ? links[0] : null) : e.key === 'ArrowDown' ? links[i + 1] : links[i - 1] || box.querySelector('input');
      if (next) { e.preventDefault(); next.focus(); }
    }
    if (e.key === 'Escape') {
      if (t.closest?.('.zw-search,.zw-tip')) t.blur();
      const tip = document.querySelector('.zw-tip:hover');
      if (tip) { tip.classList.add('zw-tip--off'); tip.addEventListener('pointerleave', () => tip.classList.remove('zw-tip--off'), { once: true }); }
    }
  });
  // Stepper buttons step the number field and fire input + change like typing would.
  // Copy buttons copy their figure's code.
  document.addEventListener('click', async (e) => {
    const b = e.target.closest('[data-step]'), i = b?.closest('.zw-stepper')?.querySelector('input');
    if (i && !i.disabled) {
      const up = b.dataset.step === '1';
      if (i.hasAttribute('data-wrap') && (up ? +i.value >= +i.max : +i.value <= +i.min)) i.value = up ? i.min : i.max;
      else if (up) i.stepUp(); else i.stepDown();
      i.dispatchEvent(new Event('input', { bubbles: true }));
      i.dispatchEvent(new Event('change', { bubbles: true }));
      clampStep(i);
    }
    const a = e.target.closest('.zw-toast-action');
    if (a) setTimeout(() => leave(a.closest('.zw-toast')));
    const c = e.target.closest('[data-copy]');
    if (!c) return;
    const say = (text, ok) => { c.textContent = text; c.classList.toggle('zw-copied', ok); c.classList.remove('zw-flip'); void c.offsetWidth; c.classList.add('zw-flip'); };
    try { await navigator.clipboard.writeText(c.closest('figure').querySelector('code').textContent); say('Copied', true); }
    catch { say('Copy failed', false); }
    clearTimeout(c.zwT); c.zwT = setTimeout(() => say('Copy', false), 1500);
  });

  for (const type of ['click', 'submit', 'change', 'input']) {
    document.addEventListener(type, (e) => {
      const el = e.target.closest?.(sel);
      if (!el) return;
      const field = el.matches('input,select,textarea');
      // A z form always sends on submit (Enter in a field), even when its trigger is change or input.
      const submit = type === 'submit' && el.tagName === 'FORM';
      if (!submit && (attr(el, 'trigger') || (el.tagName === 'FORM' ? 'submit' : field ? 'change' : 'click')) !== type) return;
      if (type !== 'input' && type !== 'change') e.preventDefault();
      if (type === 'input') { clearTimeout(el._zwT); el._zwT = setTimeout(() => fire(el), 250); } else fire(el);
    });
  }

  mount(document.body);
})();
