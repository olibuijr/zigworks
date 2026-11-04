// Browser end-to-end tests + screenshots. No dependencies: Chromium over the DevTools protocol.
// Run: `zig build e2e` (builds first). Screenshots land in zig-out/e2e/<name>-<light|dark>.png.
// Env: CHROMIUM (browser path, default "chromium"), CHROMIUM_FLAGS (extra flags, e.g. --no-sandbox in CI), ZW_BIN (default zig-out/bin), ZW_SHOTS (default zig-out/e2e).
import { spawn } from 'node:child_process';
import { mkdirSync, writeFileSync } from 'node:fs';
import { join, resolve } from 'node:path';

const root = resolve(import.meta.dirname, '..');
const bin = process.env.ZW_BIN ?? join(root, 'zig-out/bin');
const shots = process.env.ZW_SHOTS ?? join(root, 'zig-out/e2e');
mkdirSync(shots, { recursive: true });

const children = [];
const cleanup = () => children.forEach((c) => c.kill());
process.on('exit', cleanup);
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

async function waitHttp(url, ms = 30000) { // CI machines can take a while to start Chrome
  for (const end = Date.now() + ms; Date.now() < end; await sleep(100)) {
    try { await fetch(url); return; } catch {}
  }
  throw new Error(`timeout waiting for ${url}`);
}

// Apps run on loopback during tests (the framework default is every interface).
function app(name, port, dir = join('examples', name)) {
  const p = spawn(join(bin, name), [], { cwd: join(root, dir), env: { ...process.env, HOST: '127.0.0.1', PORT: String(port) }, stdio: ['ignore', 'ignore', 'pipe'] });
  p.stderr.on('data', (d) => { if (/error/i.test(d)) process.stderr.write(`[${name}] ${d}`); });
  children.push(p);
  return `http://127.0.0.1:${port}`;
}

const cdpPort = 9333;
const browser = spawn(process.env.CHROMIUM ?? 'chromium', [
  '--headless=new', `--remote-debugging-port=${cdpPort}`, '--no-first-run', '--no-default-browser-check',
  '--use-gl=angle', '--use-angle=swiftshader', '--enable-unsafe-swiftshader', '--hide-scrollbars',
  // Behave like a desktop with a mouse (headless reports no hover), so hover-only styles are testable.
  '--blink-settings=primaryHoverType=2,availableHoverTypes=2,primaryPointerType=4,availablePointerTypes=4',
  ...(process.env.CHROMIUM_FLAGS ?? '').split(' ').filter(Boolean), 'about:blank',
], { stdio: 'ignore' });
children.push(browser);

// One tab = one CDP session.
async function open(url, { dark = false, width = 900, height = 900 } = {}) {
  const t = await (await fetch(`http://127.0.0.1:${cdpPort}/json/new?about:blank`, { method: 'PUT' })).json();
  const ws = new WebSocket(t.webSocketDebuggerUrl);
  await new Promise((r) => (ws.onopen = r));
  let id = 0;
  const pending = new Map();
  const errors = [];
  const waiters = [];
  ws.onmessage = (m) => {
    const d = JSON.parse(m.data);
    if (d.id) { pending.get(d.id)?.(d); pending.delete(d.id); }
    if (d.method === 'Runtime.exceptionThrown') errors.push(d.params.exceptionDetails.exception?.description ?? d.params.exceptionDetails.text);
    if (d.method === 'Runtime.consoleAPICalled' && d.params.type === 'error') errors.push(d.params.args.map((a) => a.value ?? a.description).join(' '));
    if (d.method === 'Log.entryAdded' && d.params.entry.level === 'error') errors.push(`${d.params.entry.text} ${d.params.entry.url ?? ''}`);
    for (const w of waiters) if (w.method === d.method) w.resolve(d.params);
  };
  const send = (method, params = {}) => new Promise((res, rej) => {
    const i = ++id;
    pending.set(i, (d) => (d.error ? rej(new Error(`${method}: ${d.error.message}`)) : res(d.result)));
    ws.send(JSON.stringify({ id: i, method, params }));
  });
  const event = (method) => new Promise((resolve) => waiters.push({ method, resolve }));
  await send('Page.enable');
  await send('Runtime.enable');
  await send('Page.bringToFront'); // a background tab may never paint, and screenshots then wait forever
  await send('Log.enable');
  await send('Emulation.setDeviceMetricsOverride', { width, height, deviceScaleFactor: 2, mobile: width < 600 });
  if (width < 600) await send('Emulation.setTouchEmulationEnabled', { enabled: true, maxTouchPoints: 5 });
  await send('Emulation.setEmulatedMedia', { features: [{ name: 'prefers-color-scheme', value: dark ? 'dark' : 'light' }] });
  const loaded = event('Page.loadEventFired');
  await send('Page.navigate', { url });
  await loaded;

  const page = {
    errors,
    send,
    async eval(expr) {
      const r = await send('Runtime.evaluate', { expression: expr, returnByValue: true, awaitPromise: true });
      if (r.exceptionDetails) throw new Error(`eval failed: ${expr}\n${r.exceptionDetails.exception?.description}`);
      return r.result.value;
    },
    async waitFor(expr, ms = 5000) {
      for (const end = Date.now() + ms; Date.now() < end; await sleep(50)) if (await page.eval(expr)) return;
      throw new Error(`timeout: ${expr}`);
    },
    async center(selector) {
      const box = await page.eval(`(() => { const e = document.querySelector(${JSON.stringify(selector)}); e?.scrollIntoView({ block: 'nearest' }); const r = e?.getBoundingClientRect(); return r && { x: r.x + r.width / 2, y: r.y + r.height / 2 }; })()`);
      if (!box) throw new Error(`no element: ${selector}`);
      return box;
    },
    async click(selector) {
      const box = await page.center(selector);
      for (const type of ['mousePressed', 'mouseReleased']) await send('Input.dispatchMouseEvent', { type, x: box.x, y: box.y, button: 'left', clickCount: 1 });
    },
    async hover(selector) {
      const box = await page.center(selector);
      await send('Input.dispatchMouseEvent', { type: 'mouseMoved', x: box.x, y: box.y });
    },
    /** Hold the mouse down on an element (optionally dragging by dx), for pressed-state shots. */
    async press(selector, dx = 0) {
      const box = await page.center(selector);
      await send('Input.dispatchMouseEvent', { type: 'mouseMoved', x: box.x, y: box.y });
      await send('Input.dispatchMouseEvent', { type: 'mousePressed', x: box.x, y: box.y, button: 'left', clickCount: 1 });
      if (dx) await send('Input.dispatchMouseEvent', { type: 'mouseMoved', x: box.x + dx, y: box.y, button: 'left', buttons: 1 });
      page.held = { x: box.x + dx, y: box.y };
    },
    async release() {
      await send('Input.dispatchMouseEvent', { type: 'mouseReleased', ...page.held, button: 'left', clickCount: 1 });
    },
    async type(selector, text) {
      await page.eval(`document.querySelector(${JSON.stringify(selector)}).focus()`);
      await send('Input.insertText', { text });
    },
    /** Press a key; modifiers is the CDP bitmask (2 = Ctrl, 4 = Meta). */
    async key(key, modifiers = 0) {
      const vk = { Enter: 13, Escape: 27, ArrowUp: 38, ArrowDown: 40 }[key] ?? key.toUpperCase().charCodeAt(0);
      const code = key.length === 1 ? `Key${key.toUpperCase()}` : key;
      await send('Input.dispatchKeyEvent', { type: 'keyDown', key, code, modifiers, windowsVirtualKeyCode: vk, text: key === 'Enter' ? '\r' : undefined });
      await send('Input.dispatchKeyEvent', { type: 'keyUp', key, code, modifiers, windowsVirtualKeyCode: vk });
    },
    /** Screenshot of one element as base64 PNG (for comparisons). */
    async grab(selector) {
      const r = await page.eval(`(() => { const r = document.querySelector(${JSON.stringify(selector)}).getBoundingClientRect(); return { x: r.x, y: r.y, width: r.width, height: r.height, scale: 1 }; })()`);
      return (await send('Page.captureScreenshot', { format: 'png', clip: r })).data;
    },
    async shot(name) {
      await sleep(250); // let transitions settle
      const { data } = await send('Page.captureScreenshot', { format: 'png' });
      writeFileSync(join(shots, `${name}.png`), Buffer.from(data, 'base64'));
    },
    async close() {
      ws.close();
      await fetch(`http://127.0.0.1:${cdpPort}/json/close/${t.id}`);
    },
  };
  return page;
}

// --- tests ---------------------------------------------------------------
const results = [];
class Skip extends Error {} // thrown to skip a test whose outside dependency is missing
async function test(name, fn) {
  const t0 = Date.now();
  try { await fn(); results.push([name, 'ok', Date.now() - t0]); }
  catch (e) { results.push([name, e instanceof Skip ? 'skip' : 'FAIL', Date.now() - t0, e.message]); }
}
const eq = (a, b, msg) => { if (a !== b) throw new Error(`${msg}: expected ${JSON.stringify(b)}, got ${JSON.stringify(a)}`); };
/** Close the tab, then fail if the page logged errors. */
async function done(p) {
  await p.close();
  if (p.errors.length) throw new Error(`browser errors:\n  ${p.errors.join('\n  ')}`);
}
/** Run fn once in light and once in dark mode. */
async function modes(fn) {
  for (const dark of [false, true]) await fn(dark, dark ? 'dark' : 'light');
}

const todo = app('todo', 8901);
const gallery = app('gallery', 8902);
const scene = app('scene', 8903);
const docs = app('docs', 8904, 'docs');
await Promise.all([waitHttp(todo), waitHttp(gallery), waitHttp(scene), waitHttp(docs), waitHttp(`http://127.0.0.1:${cdpPort}/json/version`)]);

await test('todo: add, complete, delete via z.js', async () => {
  const p = await open(todo);
  const count = () => p.eval(`document.querySelectorAll('#todos > li').length`);
  const badge = () => p.eval(`document.getElementById('remaining').textContent`);
  eq(await count(), 0, 'starts empty');
  await p.shot('todo-empty-light');
  for (const title of ['Buy oat milk', 'Book flights to Reykjavík', 'Renew passport']) {
    const before = await count();
    await p.type('input[name=title]', title);
    await p.key('Enter');
    await p.waitFor(`document.querySelectorAll('#todos > li').length === ${before + 1}`);
  }
  eq(await badge(), '3 left', 'badge after adding');
  eq(await p.eval(`document.querySelector('input[name=title]').value`), '', 'form reset');
  await p.click('#todos > li:nth-child(1) .zw-check');
  await p.waitFor(`document.querySelector('#todos > li:nth-child(1)').classList.contains('is-done')`);
  eq(await badge(), '2 left', 'badge after completing');
  await p.click('#todos > li:nth-child(3) .zw-btn--destructive');
  await p.waitFor(`document.querySelectorAll('#todos > li').length === 2`);
  eq(await badge(), '1 left', 'badge after deleting');
  await p.shot('todo-light');
  const html = await p.eval(`document.querySelector('#todos').textContent`);
  if (!html.includes('Reykjavík')) throw new Error('utf-8 title lost');
  await done(p);
  const d = await open(todo, { dark: true });
  eq(await d.eval(`document.querySelectorAll('#todos > li').length`), 2, 'server state persists');
  await d.shot('todo-dark');
  await done(d);
});

await test('todo: mobile layout has no horizontal scroll', async () => {
  const p = await open(todo, { width: 390, height: 760 });
  eq(await p.eval(`document.documentElement.scrollWidth <= innerWidth`), true, 'no overflow');
  await p.shot('todo-mobile');
  await p.close();
});

await test('gallery: controls, menu, picker, sheet', () => modes(async (dark, mode) => {
  const p = await open(gallery, { dark, height: 1100 });
  eq(await p.eval(`getComputedStyle(document.querySelector('.actions')).justifyContent`), 'flex-end', 'app css served');
  await p.shot(`gallery-${mode}`);
  // menu opens anchored under its button
  await p.click('[popovertarget=more]');
  await p.waitFor(`document.getElementById('more').matches(':popover-open')`);
  await p.waitFor(`!document.getElementById('more').getAnimations().length`); // let the open spring settle
  const below = await p.eval(`document.getElementById('more').getBoundingClientRect().top >= document.querySelector('[popovertarget=more]').getBoundingClientRect().bottom - 1`);
  eq(below, true, 'menu anchored below button');
  await p.shot(`gallery-menu-${mode}`);
  await p.key('Escape');
  await p.waitFor(`!document.getElementById('more').matches(':popover-open')`);
  // picker changes its label and closes
  await p.click('[popovertarget=accent]');
  await p.waitFor(`document.getElementById('accent').matches(':popover-open')`);
  await p.shot(`gallery-picker-${mode}`);
  await p.click('#accent label:nth-child(2)');
  await p.waitFor(`document.querySelector('.zw-picker-value').textContent === 'Purple'`);
  eq(await p.eval(`document.getElementById('accent').matches(':popover-open')`), false, 'picker closed');
  // switch and segmented change state
  await p.click('.zw-toggle:nth-of-type(2) input');
  eq(await p.eval(`document.querySelector('input[name=menubar]').checked`), true, 'switch on');
  await p.click('.zw-seg label:nth-of-type(2)');
  eq(await p.eval(`document.querySelector('input[name=theme]:checked').value`), 'dark', 'segment selected');
  // sheet opens
  await p.click('[popovertarget=new-list].zw-btn--primary');
  await p.waitFor(`document.getElementById('new-list').matches(':popover-open')`);
  await p.shot(`gallery-sheet-${mode}`);
  await done(p);
}));

await test('gallery: tabs, stepper, disclosure, tooltip, tags, toast, skeleton', async () => {
  const p = await open(gallery, { height: 1100 });
  const panel = (i) => `getComputedStyle(document.querySelectorAll('.zw-tabs > .zw-tab-panel')[${i}]).display !== 'none'`;
  // skeleton is replaced by the activity list once it loads
  await p.waitFor(`!!document.getElementById('activity') && !document.querySelector('.zw-skeleton')`, 4000);
  eq(await p.eval(`document.querySelectorAll('#activity .zw-avatar').length`), 2, 'activity avatars');
  // tabs: first panel shown, the second after a click
  eq(await p.eval(panel(0)), true, 'first tab panel visible');
  await p.click('.zw-tabs .zw-seg label:nth-of-type(2)');
  await p.waitFor(panel(1));
  eq(await p.eval(panel(0)), false, 'first tab panel hidden');
  await p.click('.zw-tabs .zw-seg label:nth-of-type(1)');
  await p.waitFor(panel(0));
  // stepper: clamps at min, increments
  const copies = `document.querySelector('input[name=copies]')`;
  eq(await p.eval(`${copies}.parentElement.querySelector('[data-step="-1"]').disabled`), true, 'minus disabled at min');
  await p.click('.zw-stepper [data-step="1"]');
  await p.click('.zw-stepper [data-step="1"]');
  eq(await p.eval(`${copies}.value`), '3', 'stepper incremented');
  eq(await p.eval(`${copies}.parentElement.querySelector('[data-step="-1"]').disabled`), false, 'minus enabled');
  // checkbox
  await p.click('.zw-checkbox');
  eq(await p.eval(`document.querySelector('input[name=news]').checked`), true, 'checkbox on');
  // disclosure opens
  await p.click('.zw-disclosure summary');
  await p.waitFor(`document.querySelector('.zw-disclosure').open`);
  // tag remove: the tag leaves
  const tags = await p.eval(`document.querySelectorAll('.zw-tag').length`);
  await p.click('.zw-tag:nth-child(2) button');
  await p.waitFor(`document.querySelectorAll('.zw-tag').length === ${tags - 1}`);
  // toast: saving the account shows a toast that leaves on its own
  await p.click('form[z-post="/account"] [type=submit]');
  await p.waitFor(`!!document.querySelector('#zw-toasts .zw-toast')`);
  await p.shot('gallery-toast');
  eq(await p.eval(`document.querySelector('input[name=news]').checked`), true, 'z-keep form kept its values');
  await p.waitFor(`!document.querySelector('#zw-toasts .zw-toast')`, 7000);
  // tooltip shows after hovering (500 ms delay)
  await p.hover('.zw-tip .zw-btn');
  await p.waitFor(`getComputedStyle(document.querySelector('.zw-tip-text')).opacity === '1'`, 3000);
  await p.shot('gallery-tooltip');
  await done(p);
});

await test('glass: refraction lenses, pressed knobs, springs', () => modes(async (dark, mode) => {
  const p = await open(gallery, { dark, height: 1100 });
  eq(await p.eval(`document.documentElement.classList.contains('zw-refract')`), true, 'refraction on in Chromium');
  const lensed = await p.eval(`getComputedStyle(document.querySelector('.zw-btn--primary')).getPropertyValue('--zw-lens')`);
  if (!/url\(#zw-lens-\d+-\d+-\d+\)/.test(lensed)) throw new Error(`primary button has no lens: ${lensed}`);
  const id = lensed.match(/#([\w-]+)/)[1];
  eq(await p.eval(`!!document.getElementById('${id}')?.querySelector('feDisplacementMap')`), true, 'lens filter exists');
  eq(await p.eval(`getComputedStyle(document.querySelector('.zw-btn--primary')).backdropFilter.includes('url(')`), true, 'backdrop-filter uses the lens');
  eq(await p.eval(`!!document.getElementById('zw-lens-knob')`), true, 'knob lens');
  eq(await p.eval(`getComputedStyle(document.documentElement).getPropertyValue('--spring-bouncy').trim().startsWith('linear(')`), true, 'spring tokens');
  // Pressed states: the knob becomes a glass drop, the segmented pill swells.
  await p.press('.zw-toggle:nth-of-type(1) input');
  await sleep(1000);
  await p.shot(`glass-toggle-pressed-${mode}`);
  await p.release();
  await p.press('.zw-slider input', 20);
  await sleep(1000);
  await p.shot(`glass-slider-pressed-${mode}`);
  await p.release();
  await p.press('.zw-seg label:nth-of-type(1)');
  await sleep(2000); // headless Chromium applies :active to ancestors late
  await p.shot(`glass-seg-pressed-${mode}`);
  await p.release();
  await p.waitFor(`!document.querySelector('.zw-seg-pill').getAnimations().length`);
  const pill = await p.eval(`getComputedStyle(document.querySelector('.zw-seg-pill')).translate`);
  eq(['0px', '0%', 'none', '0px 0px', '0% 0px'].includes(pill), true, `pill slid to the first segment (${pill})`);
  await done(p);
}));

await test('scene: three.js island renders', async () => {
  const three = 'https://cdn.jsdelivr.net/npm/three@0.170.0/build/three.module.js'; // examples/scene's import map
  const online = await fetch(three, { method: 'HEAD', signal: AbortSignal.timeout(3000) }).then((r) => r.ok, () => false);
  if (!online) throw new Skip(`skipped: ${new URL(three).host} unreachable`);
  const p = await open(scene);
  await p.waitFor(`!!document.querySelector('.zw-island canvas')`, 15000);
  await sleep(1500);
  // WebGL buffers can't be read back, so compare the island with and without its canvas.
  await p.eval(`document.documentElement.style.setProperty('--speed', '0s')`);
  const withCanvas = await p.grab('.zw-island');
  await p.eval(`document.querySelector('.zw-island canvas').style.visibility = 'hidden'`);
  const without = await p.grab('.zw-island');
  await p.eval(`document.querySelector('.zw-island canvas').style.visibility = ''`);
  if (withCanvas === without) throw new Error('canvas paints nothing');
  await p.shot('scene-light');
  await done(p);
});

await test('docs: every page renders its demos without errors', async () => {
  const p = await open(docs);
  const links = await p.eval(`[...document.querySelectorAll('.zw-sidebar a')].map((a) => a.getAttribute('href'))`);
  if (links.length < 30) throw new Error(`only ${links.length} sidebar links`);
  for (const href of links) {
    const res = await fetch(docs + href);
    eq(res.status, 200, `status of ${href}`);
    const html = await res.text();
    if (html.includes('Missing demo')) throw new Error(`missing demo on ${href}`);
    if (!html.includes(`aria-current="page" href="${href}"`) && !html.includes(`href="${href}" aria-current="page"`)) throw new Error(`${href} not marked current`);
  }
  eq((await fetch(docs + '/nope')).status, 404, 'unknown page');
  eq((await fetch(docs + '/orbit.js')).status, 200, 'static file behind GET /:page');
  await p.shot('docs-home-light');
  await done(p);
  await modes(async (dark, mode) => {
    for (const page of ['templates', 'components/picker', 'components/setting']) {
      const d = await open(`${docs}/${page}`, { dark, width: 1280, height: 1000 });
      await d.shot(`docs-${page.replace('/', '-')}-${mode}`);
      await done(d);
    }
  });
});

await test('docs: home todo demo adds, checks off and deletes', async () => {
  const p = await open(docs, { width: 1280 });
  const rows = () => p.eval(`document.querySelectorAll('#hero-list > li').length`);
  eq(await rows(), 3, 'starts with three rows');
  await p.type('#hero-list ~ * input, form[z-post="/demo/todos"] input[name=title]', 'Try zigworks');
  await p.key('Enter');
  await p.waitFor(`document.querySelectorAll('#hero-list > li').length === 4`);
  eq(await p.eval(`document.querySelector('#hero-list > li:last-child').textContent.includes('Try zigworks')`), true, 'new row text');
  await p.click('#hero-list > li:last-child .zw-check');
  await p.waitFor(`document.querySelector('#hero-list > li:last-child .zw-check').getAttribute('aria-checked') === 'true'`);
  await p.click('#hero-list > li:last-child .zw-check');
  await p.waitFor(`document.querySelector('#hero-list > li:last-child .zw-check').getAttribute('aria-checked') === 'false'`);
  await p.eval(`document.querySelector('#hero-list > li:first-child .zw-btn--destructive').style.opacity = 1`);
  await p.click('#hero-list > li:first-child .zw-btn--destructive');
  await p.waitFor(`document.querySelectorAll('#hero-list > li').length === 3`);
  await p.shot('docs-todo-demo');
  await done(p);
});

await test('docs: live search, copy button, pager', async () => {
  const p = await open(`${docs}/templates`, { width: 1280 });
  await p.send('Browser.grantPermissions', { permissions: ['clipboardReadWrite', 'clipboardSanitizedWrite'], origin: docs });
  await p.type('.zw-bar .zw-search input', 'picker');
  await p.waitFor(`!!document.querySelector('#zw-results a[href="/components/picker"]')`);
  await p.shot('docs-search-light');
  await p.key('Escape');
  await p.waitFor(`getComputedStyle(document.getElementById('zw-results')).display === 'none'`);
  await p.click('.zw-code [data-copy]');
  await p.waitFor(`document.querySelector('.zw-code [data-copy]').textContent === 'Copied'`);
  eq(await p.eval(`navigator.clipboard.readText()`), await p.eval(`document.querySelector('.zw-code code').textContent`), 'clipboard text');
  eq(await p.eval(`document.querySelector('.pager .next').getAttribute('href')`), '/interactivity', 'next page');
  await done(p);
});

await test('docs: sidebar stays in view while the page scrolls', () => modes(async (dark, mode) => {
  const p = await open(`${docs}/templates`, { dark, width: 1200, height: 800 });
  const top = `document.getElementById('zw-sidebar').getBoundingClientRect().top`;
  const before = await p.eval(top);
  await p.eval(`scrollTo(0, document.body.scrollHeight)`);
  await p.waitFor(`scrollY > 0`);
  eq(Math.round(await p.eval(top)), Math.round(before), 'sidebar sticky');
  eq(await p.eval(`getComputedStyle(document.getElementById('zw-sidebar')).backdropFilter.includes('url(')`), false, 'no lens on scrolling glass');
  await p.eval(`document.getElementById('zw-sidebar').scrollTop = 99999`);
  await p.shot(`docs-scrolled-${mode}`);
  await done(p);
}));

await test('docs: no zoom-on-focus on touch screens (text fields >= 16px)', async () => {
  const p = await open(docs, { width: 390, height: 800 });
  eq(await p.eval(`matchMedia('(pointer: coarse)').matches`), true, 'touch emulated');
  const small = await p.eval(`[...document.querySelectorAll('input:not([type=checkbox]):not([type=radio]):not([type=range]), textarea')]
    .filter((i) => parseFloat(getComputedStyle(i).fontSize) < 16).map((i) => i.name || i.type)`);
  eq(small.length, 0, `fields under 16px: ${small.join(', ')}`);
  await p.shot('docs-mobile-home');
  await done(p);
});

await test('docs: layout demos fit on phones', async () => {
  const p = await open(`${docs}/components/sidebar`, { width: 390, height: 844 });
  eq(await p.eval(`document.querySelectorAll('#zw-sidebar').length`), 1, 'one app sidebar id');
  eq(await p.eval(`document.querySelector('.zw-demo .zw-sidebar--inline').getBoundingClientRect().height > 100`), true, 'inline sidebar shown');
  eq(await p.eval(`getComputedStyle(document.querySelector('.zw-demo .zw-sidebar a')).textDecorationLine`), 'none', 'prose styles kept out');
  await p.close();
  const s = await open(`${docs}/components/setting`, { width: 390, height: 844 });
  eq(await s.eval(`(() => { const seg = document.querySelector('.zw-demo .zw-seg'); return seg.scrollWidth <= seg.clientWidth + 1 && seg.getBoundingClientRect().right <= seg.closest('.zw-card').getBoundingClientRect().right; })()`), true, 'segmented fits its card');
  await done(s);
});

await test('docs: mobile sidebar and island', async () => {
  const p = await open(`${docs}/islands`, { width: 390, height: 800 });
  eq(await p.eval(`document.documentElement.scrollWidth <= innerWidth`), true, 'no horizontal scroll');
  await p.waitFor(`!!document.querySelector('.zw-island canvas')`);
  // The chart island draws on a 2D canvas: count the pixels it painted.
  const painted = `(() => { const c = document.querySelector('.zw-island canvas'); if (!c.width || !c.height) return 0;
    const d = c.getContext('2d').getImageData(0, 0, c.width, c.height).data; let n = 0; for (let i = 3; i < d.length; i += 4) if (d[i]) n++; return n; })()`;
  await p.waitFor(`${painted} > 1000`);
  await p.shot('docs-mobile');
  await p.click('.zw-sidebar-toggle');
  await p.waitFor(`document.getElementById('zw-sidebar').matches(':popover-open')`);
  await p.shot('docs-mobile-sidebar');
  await done(p);
});

await test('docs: Enter in a change-triggered z form sends it instead of reloading the page', async () => {
  const p = await open(`${docs}/components/button`, { width: 1280 });
  await p.eval(`document.body.insertAdjacentHTML('beforeend', '<form id=zf z-post="/demo" z-trigger="change" z-swap="none"><input id=zq name=q></form>'); window.__stay = 1`);
  await p.click('#zq');
  await p.key('Enter');
  await sleep(300);
  eq(await p.eval(`window.__stay === 1 && location.search === ''`), true, 'page did not reload');
  await done(p);
});
await test('docs: z.js polling, error toasts, keep-open, stepper clamp, reset and search keys', async () => {
  const p = await open(`${docs}/components/button`, { width: 1280 });
  // A stubbed fetch answers by URL so the page needs no extra routes.
  await p.eval(`window.__calls = []; window.fetch = async (u) => { __calls.push(u);
    if (u.startsWith('/err')) return new Response('<div id="zw-toasts" z-oob="beforeend"><div class="zw-toast zw-toast--error">Nope</div></div><p id=x>swapped</p>', { status: 422 });
    if (u === '/pollers') return new Response('<div z-get="/poll" z-trigger="every 200ms" z-swap="none"></div>');
    if (u.startsWith('/open')) return new Response('<b>kept</b>', { headers: { 'z-keep-open': '1', 'z-keep': '1' } });
    return new Response('ok'); }`);
  // every 200ms polls once z.js swaps it in; swapping it out stops it
  await p.eval(`document.body.insertAdjacentHTML('beforeend', '<div id=ph></div><button id=pin z-get="/pollers" z-target="#ph"></button><button id=pout z-get="/gone" z-target="#ph"></button>'); document.querySelector('#pin').click()`);
  const polls = `__calls.filter((u) => u === '/poll').length`;
  await p.waitFor(`${polls} >= 2`, 3000);
  await p.eval(`document.querySelector('#pout').click()`);
  await p.waitFor(`document.querySelector('#ph').textContent === 'ok'`);
  const stopped = await p.eval(polls);
  await sleep(500);
  eq(await p.eval(polls), stopped, 'polling stops when the element leaves');
  // error status: the oob toast shows, nothing else is swapped
  await p.eval(`document.body.insertAdjacentHTML('beforeend', '<button id=eb z-post="/err" z-target="#et"></button><div id=et>before</div>'); document.querySelector('#eb').click()`);
  await p.waitFor(`!!document.querySelector('#zw-toasts .zw-toast--error')`);
  eq(await p.eval(`document.querySelector('#et').textContent`), 'before', 'error response swaps nothing but its oob parts');
  p.errors.splice(0, p.errors.length, ...p.errors.filter((e) => !e.includes('422 POST /err'))); // z.js logs failed requests on purpose
  // z-keep-open header keeps a popover open and the form keeps its value
  await p.eval(`document.body.insertAdjacentHTML('beforeend', '<div id=pp popover><form id=pf z-post="/open" z-target="#po"><input name=a value=typed><button>Go</button></form><div id=po></div></div>'); document.querySelector('#pp').showPopover(); document.querySelector('#pf input').value = 'changed'; document.querySelector('#pf button').click()`);
  await p.waitFor(`document.querySelector('#po').textContent === 'kept'`);
  eq(await p.eval(`document.querySelector('#pp').matches(':popover-open') && document.querySelector('#pf input').value`), 'changed', 'popover open, form kept');
  await done(p);
  // stepper: a typed value above max is clamped on change
  const s = await open(`${docs}/components/stepper`, { width: 1280 });
  const i = `[...document.querySelectorAll('.zw-stepper input')].find((x) => x.max !== '' && !x.readOnly && !x.disabled)`;
  await s.eval(`const i = ${i}; i.value = +i.max + 50; i.dispatchEvent(new Event('change', { bubbles: true }))`);
  eq(await s.eval(`${i}.value === ${i}.max`), true, 'typed value clamped to max');
  await done(s);
  // textarea counter follows a form reset
  const t = await open(`${docs}/components/textarea`, { width: 1280 });
  await t.eval(`document.body.insertAdjacentHTML('beforeend', '<form id=rf>' + document.querySelector('.zw-textarea:has([data-count])').outerHTML + '</form>'); const ta = document.querySelector('#rf textarea'); ta.value += ' extra'; ta.dispatchEvent(new Event('input', { bubbles: true })); document.querySelector('#rf').reset()`);
  await t.waitFor(`(() => { const ta = document.querySelector('#rf textarea'), c = document.querySelector('#rf [data-count]'); return c.textContent.startsWith([...ta.value].length + ' / '); })()`);
  await done(t);
  // search: ArrowDown moves from the field into its results and back up
  const q = await open(`${docs}/components/search`, { width: 1280 });
  await q.eval(`document.body.insertAdjacentHTML('beforeend', '<div class="zw-search" id=sx><input id=sxi><div class="zw-results"><a href="#1">One</a><a href="#2">Two</a></div></div>')`);
  await q.click('#sxi');
  await q.key('ArrowDown');
  await q.waitFor(`document.activeElement?.textContent === 'One'`);
  await q.key('ArrowDown');
  await q.waitFor(`document.activeElement?.textContent === 'Two'`);
  await q.key('ArrowUp');
  await q.key('ArrowUp');
  await q.waitFor(`document.activeElement?.id === 'sxi'`);
  await done(q);
});
await test('docs: toasts and the confirm dialog animate out before they leave', async () => {
  const p = await open(`${docs}/components/toast`, { width: 1280 });
  const undo = `document.querySelector('[z-post="/demo/toast/show?k=sticky"]')`;
  await p.eval(`${undo}.click()`);
  await p.waitFor(`document.querySelectorAll('#zw-toasts .zw-toast').length === 1`);
  await p.eval(`${undo}.click()`);
  await p.waitFor(`document.querySelectorAll('#zw-toasts .zw-toast').length === 2`);
  await p.click('#zw-toasts .zw-toast-x');
  eq(await p.eval(`document.querySelector('#zw-toasts .zw-toast').classList.contains('zw-leave')`), true, 'closed toast is leaving');
  eq(await p.eval(`getComputedStyle(document.querySelector('#zw-toasts .zw-toast')).display !== 'none'`), true, 'still visible while it animates');
  await p.waitFor(`document.querySelectorAll('#zw-toasts .zw-toast').length === 1`, 2000);
  await done(p);
  // z-confirm's dialog: Cancel closes it with an exit animation, then it is removed
  const d = await open(`${docs}/components/button`, { width: 1280 });
  await d.eval(`document.body.insertAdjacentHTML('beforeend', '<button id=cf z-post="/nowhere" z-confirm="Sure?">x</button>'); document.querySelector('#cf').click()`);
  await d.waitFor(`!!document.querySelector('.zw-dialog[open]')`);
  await d.eval(`document.querySelector('.zw-dialog button').click()`);
  eq(await d.eval(`!!document.querySelector('.zw-dialog')`), true, 'dialog stays to animate out');
  await d.waitFor(`!document.querySelector('.zw-dialog')`, 2000);
  await done(d);
});

await test('docs: slider readout and textarea counter follow input', async () => {
  const p = await open(`${docs}/components/slider`, { width: 1280 });
  const sel = '.zw-slider:has(.zw-slider-value) input';
  const input = `document.querySelector('${sel}')`;
  const readout = `(${input}.closest('.zw-slider').querySelector('.zw-slider-value').textContent)`;
  const shows = `${readout} === ${input}.value + ${input}.closest('.zw-slider').querySelector('.zw-slider-value').dataset.unit`;
  eq(await p.eval(shows), true, 'initial readout matches the value');
  const before = await p.eval(`${input}.value`);
  await p.eval(`${input}.scrollIntoView({ block: 'center' })`);
  await p.press(sel, -60);
  await p.release();
  await p.waitFor(`${input}.value !== '${before}' && ${shows}`);
  await done(p);
  const t = await open(`${docs}/components/textarea`, { width: 1280 });
  const ta = `document.querySelector('.zw-textarea:has([data-count]) textarea')`;
  const count = `${ta}.closest('.zw-textarea').querySelector('[data-count]')`;
  const len = await t.eval(`[...${ta}.value].length`), max = await t.eval(`${count}.dataset.count`);
  eq(await t.eval(`${count}.textContent`), `${len} / ${max}`, 'initial count');
  await t.eval(`${ta}.id ||= 'e2e-ta'`);
  await t.type(`#${await t.eval(`${ta}.id`)}`, ' Hi');
  await t.waitFor(`${count}.textContent === '${len + 3} / ${max}'`);
  await done(t);
});

await test('docs: stepper wraps, mixed checkbox clears, menu arrow keys', async () => {
  const p = await open(`${docs}/components/stepper`, { width: 1280 });
  const i = `document.querySelector('.zw-stepper input[data-wrap]')`;
  await p.eval(`${i}.value = ${i}.max; ${i}.closest('.zw-stepper').id ||= 'e2e-step'`);
  const id = await p.eval(`${i}.closest('.zw-stepper').id`);
  await p.click(`#${id} [data-step="1"]`);
  await p.waitFor(`${i}.value === ${i}.min`);
  await p.click(`#${id} [data-step="-1"]`);
  await p.waitFor(`${i}.value === ${i}.max`);
  await done(p);
  const c = await open(`${docs}/components/checkbox`, { width: 1280 });
  const all = `document.querySelector('input[data-mixed]')`;
  await c.eval(`${all}.id ||= 'e2e-mixed'`);
  const mid = await c.eval(`${all}.id`);
  const mixed = `document.getElementById('${mid}')`;
  await c.click(`#${mid}`);
  await c.waitFor(`!${mixed}.hasAttribute('data-mixed') && !${mixed}.hasAttribute('aria-checked')`);
  await done(c);
  // Menus: arrow keys move between enabled items and wrap around.
  const m = await open(`${docs}/components/menu`, { width: 1280 });
  const menuId = await m.eval(`[...document.querySelectorAll('.zw-menu')].find((x) => document.querySelector('[popovertarget="' + x.id + '"]')).id`);
  await m.click(`[popovertarget="${menuId}"]`);
  await m.waitFor(`document.getElementById('${menuId}').matches(':popover-open')`);
  const items = `[...document.querySelectorAll('#${menuId} [role^=menuitem]:not([disabled]):not([aria-disabled=true])')]`;
  const at = `${items}.indexOf(document.activeElement)`;
  await m.eval(`${items}[0].focus()`);
  await m.key('ArrowDown');
  await m.waitFor(`${at} === 1`);
  await m.key('End');
  await m.waitFor(`${at} === ${items}.length - 1`);
  await m.key('ArrowDown'); // wraps around
  await m.waitFor(`${at} === 0`);
  await done(m);
});

await test('docs: Ctrl+K search, sheet focuses first field, skip link', async () => {
  const p = await open(`${docs}/components/search`, { width: 1280 });
  await p.key('k', 2);
  await p.waitFor(`document.activeElement.matches('.zw-search [data-shortcut=k]')`);
  await done(p);
  const s = await open(`${docs}/components/sheet`, { width: 1280 });
  eq(await s.eval(`document.querySelector('a.zw-skip')?.getAttribute('href')`), '#zw-main', 'skip link target');
  eq(await s.eval(`document.getElementById('zw-main')?.tabIndex`), -1, 'skip target focusable');
  const sheetId = await s.eval(`[...document.querySelectorAll('.zw-sheet[data-focus-first]')].find((x) => x.querySelector('input:not([type=hidden]):not([type=checkbox]):not([type=radio])') && !x.querySelector('[autofocus]')).id`);
  await s.click(`[popovertarget="${sheetId}"]`);
  await s.waitFor(`document.getElementById('${sheetId}').matches(':popover-open')`);
  await s.waitFor(`document.activeElement === document.querySelector('#${sheetId} input:not([type=hidden]):not([disabled])')`);
  await done(s);
});

cleanup();
let failed = 0;
for (const [name, status, ms, err] of results) {
  console.log(`${{ ok: '✓', skip: '-' }[status] ?? '✗'} ${name} (${ms} ms)${err ? `\n    ${err.replaceAll('\n', '\n    ')}` : ''}`);
  if (status === 'FAIL') failed++;
}
const skipped = results.filter((r) => r[1] === 'skip').length;
console.log(`\n${results.length - failed - skipped}/${results.length} passed${skipped ? ` · ${skipped} skipped` : ''} · screenshots in ${shots}`);
process.exit(failed ? 1 : 0);
