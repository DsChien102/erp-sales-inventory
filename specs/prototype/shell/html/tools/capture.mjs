// Chụp mọi ca → tools/proto-final/{iphone,web}/<screen>__<state>.png
// Dùng: node tools/capture.mjs [tiền-tố-tên-ca]   (PROTO_URL đổi server, mặc định http://127.0.0.1:8767)
import { spawnSync } from 'node:child_process';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

import { CASES } from '../app/cases.js';

const SIZE = { iphone: '390,844', web: '1280,800' };
const CHROME = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
const BASE = process.env.PROTO_URL || 'http://127.0.0.1:8767';
const root = path.join(path.dirname(fileURLToPath(import.meta.url)), 'proto-final');
const filter = process.argv[2] || '';

let n = 0; let bad = 0;
for (const device of Object.keys(SIZE)) {
  fs.mkdirSync(path.join(root, device), { recursive: true });
  for (const [screen, states] of Object.entries(CASES)) for (const state of states) {
    const name = `${screen}__${state}`;
    if (!name.startsWith(filter)) continue;
    n++;
    const file = path.join(root, device, `${name}.png`);
    fs.rmSync(file, { force: true });
    spawnSync(CHROME, ['--headless=new', '--hide-scrollbars', '--force-device-scale-factor=1', '--virtual-time-budget=1500', `--window-size=${SIZE[device]}`, `--screenshot=${file}`, `${BASE}/index.html?screen=${screen}&state=${state}&device=${device}`], { stdio: 'ignore' });
    const ok = fs.existsSync(file) && fs.statSync(file).size >= 2048;
    if (!ok) bad++;
    console.log(`${ok ? 'ok ' : 'lỗi'} ${device}/${name}`);
  }
}
console.log(`${n} ca, ${bad} lỗi`);
process.exit(bad ? 1 : 0);
