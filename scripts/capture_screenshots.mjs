import http from 'node:http';
import fs from 'node:fs';
import path from 'node:path';
import os from 'node:os';
import { spawn } from 'node:child_process';
import { fileURLToPath } from 'node:url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const ROOT = path.resolve(__dirname, '..');
const WEB_DIR = path.join(ROOT, 'mobile', 'build', 'web');
const SHOTS_DIR = path.join(ROOT, 'docs', 'screenshots');

const MIME_TYPES = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'application/javascript; charset=utf-8',
  '.mjs': 'application/javascript; charset=utf-8',
  '.wasm': 'application/wasm',
  '.json': 'application/json; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.svg': 'image/svg+xml',
  '.ttf': 'font/ttf',
  '.otf': 'font/otf',
  '.woff': 'font/woff',
  '.woff2': 'font/woff2',
  '.ico': 'image/x-icon',
};

const ROUTES = [
  { route: '#/splash', out: '01_auth_onboarding/00_splash_sanctuary.png', waitMs: 1500 },
  { route: '#/onboarding', out: '01_auth_onboarding/01_welcome_onboarding.png', waitMs: 2500 },
  { route: '#/auth', out: '01_auth_onboarding/02_login_registration.png', waitMs: 1200 },
  { route: '#/', out: '02_home/01_home_dashboard.png', waitMs: 1400, scrolls: [{ y: 420, out: '02_home/02_home_modules_grid.png' }] },
  { route: '#/reflections', out: '03_reflections/01_reflections.png', waitMs: 1200 },
  { route: '#/documents', out: '14_documents/01_bibliotheque_documentaire.png', waitMs: 1200 },
  { route: '#/extra-groupe', out: '15_extra_groupe/01_extra_groupe.png', waitMs: 1200 },
  { route: '#/notifications', out: '16_notifications/01_notifications.png', waitMs: 1200 },
  { route: '#/challenges', out: '04_challenges/01_challenges.png', waitMs: 1200 },
  { route: '#/debates', out: '05_debates/01_face_a_face.png', waitMs: 1200, scrolls: [{ y: 650, out: '05_debates/02_face_a_face_rubric.png' }] },
  { route: '#/quiz-arena', out: '06_quiz_arena/01_quiz_arena.png', waitMs: 1200 },
  {
    route: '#/zikr',
    out: '07_zikr/01_zikr_session.png',
    waitMs: 1200,
    scrolls: [
      { y: 540, out: '07_zikr/02_zikr_salawat_10000_goal.png' },
      { y: 580, out: '07_zikr/03_zikr_tasbih.png' },
    ],
  },
  { route: '#/learning', out: '08_learning_hub/01_learning_hub.png', waitMs: 1200 },
  { route: '#/english-club', out: '08_english_club/01_english_club.png', waitMs: 1200, scrolls: [{ y: 920, out: '08_english_club/02_english_oral_eval.png' }] },
  { route: '#/professional', out: '09_professional/01_professional_development.png', waitMs: 1200 },
  { route: '#/personal-growth', out: '10_personal_growth/01_personal_growth.png', waitMs: 1200 },
  { route: '#/community', out: '11_community/01_community.png', waitMs: 1200 },
  { route: '#/admin', out: '12_admin/01_administration.png', waitMs: 1200 },
  { route: '#/settings', out: '13_settings/01_settings.png', waitMs: 1200 },
];

function startStaticServer() {
  return new Promise((resolve, reject) => {
    const server = http.createServer((req, res) => {
      const cleanPath = (req.url || '/').split('?')[0];
      let rel = cleanPath === '/' ? 'index.html' : cleanPath.replace(/^\/+/, '');
      let filePath = path.join(WEB_DIR, rel);
      if (!fs.existsSync(filePath) || fs.statSync(filePath).isDirectory()) {
        filePath = path.join(WEB_DIR, 'index.html');
      }
      const ext = path.extname(filePath).toLowerCase();
      res.writeHead(200, { 'Content-Type': MIME_TYPES[ext] || 'application/octet-stream' });
      fs.createReadStream(filePath).pipe(res);
    });
    server.on('error', reject);
    server.listen(0, '127.0.0.1', () => {
      resolve({ server, port: server.address().port });
    });
  });
}

function findEdge() {
  const candidates = [
    'C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe',
    'C:\\Program Files\\Microsoft\\Edge\\Application\\msedge.exe',
  ];
  for (const c of candidates) {
    if (fs.existsSync(c)) return c;
  }
  throw new Error('Microsoft Edge executable not found.');
}

async function waitForDevTools(port) {
  for (let i = 0; i < 40; i++) {
    try {
      const res = await fetch(`http://127.0.0.1:${port}/json/list`);
      if (res.ok) {
        const list = await res.json();
        const page = list.find((t) => t.type === 'page');
        if (page?.webSocketDebuggerUrl) return page.webSocketDebuggerUrl;
      }
    } catch {
      // retry
    }
    await new Promise((r) => setTimeout(r, 250));
  }
  throw new Error('Timed out waiting for Edge DevTools CDP endpoint.');
}

class CdpClient {
  constructor(wsUrl) {
    this.ws = new WebSocket(wsUrl);
    this.nextId = 1;
    this.pending = new Map();
    this.logs = [];
    this.exceptions = [];
  }

  connect() {
    return new Promise((resolve, reject) => {
      this.ws.addEventListener('open', resolve);
      this.ws.addEventListener('error', reject);
      this.ws.addEventListener('message', (ev) => {
        const msg = JSON.parse(ev.data.toString());
        if (msg.id && this.pending.has(msg.id)) {
          const { res, rej } = this.pending.get(msg.id);
          this.pending.delete(msg.id);
          if (msg.error) rej(new Error(msg.error.message));
          else res(msg.result);
        } else if (msg.method === 'Runtime.consoleAPICalled') {
          const text = (msg.params.args || []).map((a) => a.value ?? a.description ?? '').join(' ');
          if (['error', 'warning'].includes(msg.params.type) || /overflow|exception|error/i.test(text)) {
            this.logs.push(`[${msg.params.type}] ${text}`);
          }
        } else if (msg.method === 'Runtime.exceptionThrown') {
          const details = msg.params.exceptionDetails;
          this.exceptions.push(details?.exception?.description || details?.text || 'Uncaught exception');
        }
      });
    });
  }

  send(method, params = {}) {
    const id = this.nextId++;
    return new Promise((res, rej) => {
      this.pending.set(id, { res, rej });
      this.ws.send(JSON.stringify({ id, method, params }));
    });
  }

  close() {
    this.ws.close();
  }
}

async function wait(ms) {
  return new Promise((r) => setTimeout(r, ms));
}

async function main() {
  if (!fs.existsSync(path.join(WEB_DIR, 'index.html'))) {
    throw new Error(`Missing Flutter web build at ${WEB_DIR}. Run flutter build web first.`);
  }

  const { server, port } = await startStaticServer();
  const cdpPort = 9235;
  const userDataDir = fs.mkdtempSync(path.join(os.tmpdir(), 'yitte-edge-'));
  const edgePath = findEdge();

  const edge = spawn(
    edgePath,
    [
      '--headless=new',
      '--disable-gpu',
      '--no-first-run',
      '--no-default-browser-check',
      `--remote-debugging-port=${cdpPort}`,
      `--user-data-dir=${userDataDir}`,
      '--window-size=430,900',
      `http://127.0.0.1:${port}/#/onboarding`,
    ],
    { stdio: 'ignore' }
  );

  let client;
  const report = { captured: [], navClicks: [], logs: [], exceptions: [] };

  try {
    const wsUrl = await waitForDevTools(cdpPort);
    client = new CdpClient(wsUrl);
    await client.connect();
    await client.send('Page.enable');
    await client.send('Runtime.enable');
    await client.send('Emulation.setDeviceMetricsOverride', {
      width: 390,
      height: 844,
      deviceScaleFactor: 2,
      mobile: true,
    });

    // Wait for initial Flutter CanvasKit render
    for (let i = 0; i < 40; i++) {
      const check = await client.send('Runtime.evaluate', {
        expression: `Boolean(document.querySelector('flutter-view') || document.querySelector('flt-glass-pane') || document.querySelector('canvas'))`,
        returnByValue: true,
      });
      if (check?.result?.value === true) break;
      await wait(350);
    }
    await wait(3000);

    for (const item of ROUTES) {
      await client.send('Runtime.evaluate', {
        expression: `window.location.hash = ${JSON.stringify(item.route)};`,
      });
      await wait(item.waitMs);

      const shot = await client.send('Page.captureScreenshot', { format: 'png' });
      const outPath = path.join(SHOTS_DIR, item.out);
      fs.mkdirSync(path.dirname(outPath), { recursive: true });
      fs.writeFileSync(outPath, Buffer.from(shot.data, 'base64'));
      report.captured.push({ route: item.route, file: item.out, bytes: Buffer.from(shot.data, 'base64').length });

      for (const s of item.scrolls || []) {
        await client.send('Input.dispatchMouseEvent', {
          type: 'mouseWheel',
          x: 195,
          y: 420,
          deltaX: 0,
          deltaY: s.y,
        });
        await wait(900);
        const shot2 = await client.send('Page.captureScreenshot', { format: 'png' });
        const outPath2 = path.join(SHOTS_DIR, s.out);
        fs.mkdirSync(path.dirname(outPath2), { recursive: true });
        fs.writeFileSync(outPath2, Buffer.from(shot2.data, 'base64'));
        report.captured.push({
          route: `${item.route} (scrolled +${s.y})`,
          file: s.out,
          bytes: Buffer.from(shot2.data, 'base64').length,
        });
      }
    }

    // Verify real interactive tab bar clicks starting at #/
    await client.send('Runtime.evaluate', { expression: `window.location.hash = '#/';` });
    await wait(1200);
    for (const tab of [
      { label: 'Réflexions', x: 117, expectedHash: '#/reflections' },
      { label: 'Défis', x: 195, expectedHash: '#/challenges' },
      { label: 'Apprendre', x: 273, expectedHash: '#/learning' },
      { label: 'Communauté', x: 351, expectedHash: '#/community' },
    ]) {
      await client.send('Input.dispatchMouseEvent', { type: 'mousePressed', x: tab.x, y: 810, button: 'left', clickCount: 1 });
      await client.send('Input.dispatchMouseEvent', { type: 'mouseReleased', x: tab.x, y: 810, button: 'left', clickCount: 1 });
      await wait(900);
      const res = await client.send('Runtime.evaluate', { expression: 'window.location.hash', returnByValue: true });
      report.navClicks.push({ tab: tab.label, observedHash: res?.result?.value, expectedHash: tab.expectedHash });
    }

    report.logs = client.logs;
    report.exceptions = client.exceptions;
    console.log(JSON.stringify(report, null, 2));
  } finally {
    client?.close();
    edge.kill();
    server.close();
    try {
      fs.rmSync(userDataDir, { recursive: true, force: true });
    } catch {
      // ignore temp lock on windows
    }
  }
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
