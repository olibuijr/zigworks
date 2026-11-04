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

function app(name, port) {
  const p = spawn(join(bin, name), [], { cwd: join(root, 'examples', name), env: { ...process.env, PORT: String(port) }, stdio: ['ignore', 'ignore', 'pipe'] });
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
  await send('Emulation.setEmulatedMedia', { features: [{ name: 'prefers-color-scheme', value: dark ? 'dark' : 'light' }] });
  const loaded = event('Page.loadEventFired');
  await send('Page.navigate', { url });
  await loaded;

  const page = {
    errors,
    async eval(expr) {
      const r = await send('Runtime.evaluate', { expression: expr, returnByValue: true, awaitPromise: true });
      if (r.exceptionDetails) throw new Error(`eval failed: ${expr}\n${r.exceptionDetails.exception?.description}`);
      return r.result.value;
    },
    async waitFor(expr, ms = 5000) {
      for (const end = Date.now() + ms; Date.now() < end; await sleep(50)) if (await page.eval(expr)) return;
      throw new Error(`timeout: ${expr}`);
    },
    async click(selector) {
      const box = await page.eval(`(() => { const r = document.querySelector(${JSON.stringify(selector)})?.getBoundingClientRect(); return r && { x: r.x + r.width / 2, y: r.y + r.height / 2 }; })()`);
      if (!box) throw new Error(`no element: ${selector}`);
      for (const type of ['mousePressed', 'mouseReleased']) await send('Input.dispatchMouseEvent', { type, x: box.x, y: box.y, button: 'left', clickCount: 1 });
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
await Promise.all([waitHttp(todo), waitHttp(gallery), waitHttp(scene), waitHttp(`http://127.0.0.1:${cdpPort}/json/version`)]);

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
    await p.click('.zw-seg label:nth-child(2)');
    eq(await p.eval(`document.querySelector('input[name=theme]:checked').value`), 'dark', 'segment selected');
    // sheet opens
    await p.click('[popovertarget=new-list].zw-btn--primary');
    await p.waitFor(`document.getElementById('new-list').matches(':popover-open')`);
    await p.shot(`gallery-sheet-${mode}`);
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

cleanup();
let failed = 0;
for (const [name, status, ms, err] of results) {
  console.log(`${status === 'ok' ? '✓' : '✗'} ${name} (${ms} ms)${err ? `\n    ${err.replaceAll('\n', '\n    ')}` : ''}`);
  if (status !== 'ok') failed++;
}
console.log(`\n${results.length - failed}/${results.length} passed · screenshots in ${shots}`);
process.exit(failed ? 1 : 0);
