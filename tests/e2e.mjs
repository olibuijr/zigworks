// Browser end-to-end tests + screenshots. No dependencies: Chromium over the DevTools protocol.
// Run: `zig build e2e` (builds first). Screenshots land in zig-out/e2e/<name>-<light|dark>.png.
// Env: CHROMIUM (browser path, default "chromium"), ZW_BIN (default zig-out/bin), ZW_SHOTS (default zig-out/e2e).
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

async function waitHttp(url, ms = 10000) {
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
  '--use-gl=angle', '--use-angle=swiftshader', '--enable-unsafe-swiftshader', '--hide-scrollbars', 'about:blank',
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
    async key(key) {
      const vk = { Enter: 13, Escape: 27 }[key] ?? 0;
      await send('Input.dispatchKeyEvent', { type: 'keyDown', key, code: key, windowsVirtualKeyCode: vk, text: key === 'Enter' ? '\r' : undefined });
      await send('Input.dispatchKeyEvent', { type: 'keyUp', key, code: key, windowsVirtualKeyCode: vk });
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
async function test(name, fn) {
  const t0 = Date.now();
  try { await fn(); results.push([name, 'ok', Date.now() - t0]); }
  catch (e) { results.push([name, 'FAIL', Date.now() - t0, e.message]); }
}
const eq = (a, b, msg) => { if (a !== b) throw new Error(`${msg}: expected ${JSON.stringify(b)}, got ${JSON.stringify(a)}`); };
const noErrors = (p) => { if (p.errors.length) throw new Error(`browser errors:\n  ${p.errors.join('\n  ')}`); };

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
  noErrors(p);
  await p.close();
  const d = await open(todo, { dark: true });
  eq(await d.eval(`document.querySelectorAll('#todos > li').length`), 2, 'server state persists');
  await d.shot('todo-dark');
  noErrors(d);
  await d.close();
});

await test('todo: mobile layout has no horizontal scroll', async () => {
  const p = await open(todo, { width: 390, height: 760 });
  eq(await p.eval(`document.documentElement.scrollWidth <= innerWidth`), true, 'no overflow');
  await p.shot('todo-mobile');
  await p.close();
});

await test('gallery: controls, menu, picker, sheet', async () => {
  for (const dark of [false, true]) {
    const mode = dark ? 'dark' : 'light';
    const p = await open(gallery, { dark, height: 1100 });
    eq(await p.eval(`getComputedStyle(document.querySelector('.actions')).justifyContent`), 'flex-end', 'app css served');
    await p.shot(`gallery-${mode}`);
    // menu opens anchored under its button
    await p.click('[popovertarget=more]');
    await p.waitFor(`document.getElementById('more').matches(':popover-open')`);
    await sleep(800); // let the open spring settle
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
    noErrors(p);
    await p.close();
  }
});

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
  await sleep(1100);
  eq(await p.eval(`getComputedStyle(document.querySelector('.zw-tip-text')).opacity`), '1', 'tooltip visible');
  await p.shot('gallery-tooltip');
  noErrors(p);
  await p.close();
});

await test('glass: refraction lenses, pressed knobs, springs', async () => {
  for (const dark of [false, true]) {
    const mode = dark ? 'dark' : 'light';
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
    await sleep(800);
    const pill = await p.eval(`getComputedStyle(document.querySelector('.zw-seg-pill')).translate`);
    eq(['0px', '0%', 'none', '0px 0px', '0% 0px'].includes(pill), true, `pill slid to the first segment (${pill})`);
    noErrors(p);
    await p.close();
  }
});

await test('scene: three.js island renders', async () => {
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
  noErrors(p);
  await p.close();
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
  noErrors(p);
  await p.close();
  for (const dark of [false, true]) {
    const mode = dark ? 'dark' : 'light';
    for (const page of ['templates', 'components/picker', 'components/setting']) {
      const d = await open(`${docs}/${page}`, { dark, width: 1280, height: 1000 });
      await d.shot(`docs-${page.replace('/', '-')}-${mode}`);
      noErrors(d);
      await d.close();
    }
  }
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
  noErrors(p);
  await p.close();
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
  noErrors(p);
  await p.close();
});

await test('docs: no zoom-on-focus on touch screens (text fields >= 16px)', async () => {
  const p = await open(docs, { width: 390, height: 800 });
  eq(await p.eval(`matchMedia('(pointer: coarse)').matches`), true, 'touch emulated');
  const small = await p.eval(`[...document.querySelectorAll('input:not([type=checkbox]):not([type=radio]):not([type=range]), textarea')]
    .filter((i) => parseFloat(getComputedStyle(i).fontSize) < 16).map((i) => i.name || i.type)`);
  eq(small.length, 0, `fields under 16px: ${small.join(', ')}`);
  await p.shot('docs-mobile-home');
  noErrors(p);
  await p.close();
});

await test('docs: mobile sidebar and island', async () => {
  const p = await open(`${docs}/islands`, { width: 390, height: 800 });
  eq(await p.eval(`document.documentElement.scrollWidth <= innerWidth`), true, 'no horizontal scroll');
  await p.waitFor(`!!document.querySelector('.zw-island canvas')`);
  await sleep(300);
  const withCanvas = await p.grab('.zw-island');
  await p.eval(`document.querySelector('.zw-island canvas').style.visibility = 'hidden'`);
  if (withCanvas === await p.grab('.zw-island')) throw new Error('orbit island paints nothing');
  await p.eval(`document.querySelector('.zw-island canvas').style.visibility = ''`);
  await p.shot('docs-mobile');
  await p.click('.zw-sidebar-toggle');
  await p.waitFor(`document.getElementById('zw-sidebar').matches(':popover-open')`);
  await p.shot('docs-mobile-sidebar');
  noErrors(p);
  await p.close();
});

cleanup();
let failed = 0;
for (const [name, status, ms, err] of results) {
  console.log(`${status === 'ok' ? '✓' : '✗'} ${name} (${ms} ms)${err ? `\n    ${err.replaceAll('\n', '\n    ')}` : ''}`);
  if (status !== 'ok') failed++;
}
console.log(`\n${results.length - failed}/${results.length} passed · screenshots in ${shots}`);
process.exit(failed ? 1 : 0);
