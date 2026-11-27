// Chụp mọi ca → tools/proto-final/{iphone,web}/<screen>__<state>.png
// Dùng: node tools/capture.mjs [tiền-tố-tên-ca]   (PROTO_URL đổi server, mặc định http://127.0.0.1:8771; DEVICE=iphone|web chỉ chụp một khổ)
import { spawnSync } from 'node:child_process';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

import { CASES } from '../app/cases.js';

const SIZE = { iphone: '390,844', web: '1280,800' };
const CHROME = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
const BASE = process.env.PROTO_URL || 'http://127.0.0.1:8771';
const root = path.join(path.dirname(fileURLToPath(import.meta.url)), 'proto-final');
const filter = process.argv[2] || '';
const PROFILE = path.join(os.tmpdir(), 'proto-capture-chrome'); // hồ sơ Chrome riêng, không đụng Chrome đang mở

let n = 0; let bad = 0;
for (const device of Object.keys(SIZE).filter((d) => !process.env.DEVICE || d === process.env.DEVICE)) {
  fs.mkdirSync(path.join(root, device), { recursive: true });
  for (const [screen, states] of Object.entries(CASES)) for (const state of states) {
    const name = `${screen}__${state}`;
    if (!name.startsWith(filter)) continue;
    n++;
    const file = path.join(root, device, `${name}.png`);
    fs.rmSync(file, { force: true });
    // --virtual-time-budget làm Chrome treo khi Chrome thường đang mở (2026-11-27) → bỏ; hồ sơ riêng + timeout 45 s mỗi ảnh.
    spawnSync(CHROME, ['--headless', '--disable-gpu', '--no-first-run', `--user-data-dir=${PROFILE}`, '--hide-scrollbars', '--force-device-scale-factor=1', `--window-size=${SIZE[device]}`, `--screenshot=${file}`, `${BASE}/index.html?screen=${screen}&state=${state}&device=${device}`], { stdio: 'ignore', timeout: 45000 });
    const ok = fs.existsSync(file) && fs.statSync(file).size >= 2048;
    if (!ok) bad++;
    console.log(`${ok ? 'ok ' : 'lỗi'} ${device}/${name}`);
  }
}
console.log(`${n} ca, ${bad} lỗi`);
process.exit(bad ? 1 : 0);
