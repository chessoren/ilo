// Renders deck.html slides to PNG through one headless Chrome (DevTools protocol, no dependencies).
// Usage: node render.mjs <outDir> [slide numbers...]   (Node 22+ for the global WebSocket)
import { spawn } from 'node:child_process';
import { mkdtempSync, writeFileSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join, dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const outDir = resolve(process.argv[2] || join(here, '..'));
const TOTAL = 14;
const slides = process.argv.slice(3).map(Number).filter(Boolean);
const list = slides.length ? slides : Array.from({ length: TOTAL }, (_, i) => i + 1);
const chromePath = process.env.CHROME || '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
const profile = mkdtempSync(join(tmpdir(), 'ilo-deck-'));
const port = 9300 + Math.floor(Math.random() * 500);

const chrome = spawn(chromePath, [
  '--headless=new', '--disable-gpu', '--hide-scrollbars', '--force-device-scale-factor=1',
  '--allow-file-access-from-files', `--user-data-dir=${profile}`, '--no-first-run',
  `--remote-debugging-port=${port}`, '--window-size=2400,1600', 'about:blank'
], { stdio: 'ignore' });

const sleep = ms => new Promise(r => setTimeout(r, ms));
async function targets() {
  for (let i = 0; i < 600; i++) {
    try { return await (await fetch(`http://127.0.0.1:${port}/json`)).json(); } catch { await sleep(150); }
  }
  throw new Error('Chrome did not start');
}

try {
  const page = (await targets()).find(t => t.type === 'page');
  const ws = new WebSocket(page.webSocketDebuggerUrl);
  await new Promise((ok, fail) => { ws.onopen = ok; ws.onerror = fail; });
  let id = 0; const pending = new Map(); const waiters = [];
  ws.onmessage = ev => {
    const msg = JSON.parse(ev.data);
    if (msg.id && pending.has(msg.id)) { pending.get(msg.id)(msg); pending.delete(msg.id); }
    else if (msg.method) waiters.filter(w => w.method === msg.method).forEach(w => { w.resolve(msg); waiters.splice(waiters.indexOf(w), 1); });
  };
  const send = (method, params = {}) => new Promise(r => { const i = ++id; pending.set(i, r); ws.send(JSON.stringify({ id: i, method, params })); });
  const once = method => new Promise(resolve => waiters.push({ method, resolve }));

  await send('Page.enable');
  await send('Emulation.setDeviceMetricsOverride', { width: 2400, height: 1600, deviceScaleFactor: 1, mobile: false });
  for (const n of list) {
    const loaded = once('Page.loadEventFired');
    await send('Page.navigate', { url: `file://${join(here, 'deck.html')}?n=${n}` });
    await loaded;
    await send('Runtime.evaluate', { expression: 'document.fonts.ready.then(() => new Promise(r => requestAnimationFrame(() => requestAnimationFrame(r))))', awaitPromise: true });
    const shot = await send('Page.captureScreenshot', { format: 'png', clip: { x: 0, y: 0, width: 2400, height: 1600, scale: 1 } });
    const file = join(outDir, `slide-${String(n).padStart(2, '0')}.png`);
    writeFileSync(file, Buffer.from(shot.result.data, 'base64'));
    console.log('rendered', file.split('/').pop());
  }
  ws.close();
} finally {
  chrome.kill();
  await sleep(800);
  try { rmSync(profile, { recursive: true, force: true, maxRetries: 5, retryDelay: 200 }); } catch {}
}
