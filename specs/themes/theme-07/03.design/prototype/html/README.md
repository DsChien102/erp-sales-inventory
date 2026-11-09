# Theme 7 HTML Prototype Harness · v5.28.0 (rút gọn)

> **v5.28.0 — bản rút gọn** theo `docs/refactor/PLAN.md` mục Theme 7 → "Rút gọn 2026-11-09": mặc định chỉ hiện 6 luồng app làm (UIF-12, 01, 02, 08, 14, 15) và đã gỡ duyệt / nhập tệp / nhận theo chứng từ mua / tình trạng hàng / K3. Thêm `?scope=full` để hiện cả luồng đã lược bỏ (tra cứu; luồng còn giữ vẫn là bản rút gọn — bản đầy đủ v5.27.0 xem git). Chi tiết: CHANGELOG 5.28.0. Ảnh `tools/proto-final/` là của v5.27.0, chụp lại màn đã đổi trước khi dùng.

Prototype thiết kế Theme 7 (Kho & Giá vốn). Sau **T7-P A11**: `core.js` chỉ còn khung; harness tách; mọi BJ ở `app/bjNN.js`.

## Chạy

```bash
cd specs/themes/theme-07/03.design/prototype/html
python3 -m http.server 8765 --bind 127.0.0.1
# mở http://127.0.0.1:8765/index.html
```

Tham số URL: `uif`, `screen`, `state`, `flow`, `mode`, `app`, `entry`, `hubView`, `inspect`.

## Cấu trúc

```text
html/
  index.html
  styles/           tokens.css, components.css, screens.css
  app/              core.js (khung), hub.js, bj01.js…bj17.js, cap01.js,
                    shared-control.js, shared-valuation.js, shared-patterns.js, shared-problem.js
  harness/          workbench.js, workbench.css, figma-ds-map.js
  data/             workbench-data.js, workbench-data.json
  tools/golden.mjs  capture | compare | usage
  CHANGELOG.md
```

- **CSS:** `tokens` → `components` → `harness/workbench` → `screens` (workbench trước screens để không đè chỉnh frame v281).
- **JS:** `data/workbench-data.js` → `app/core.js` → `harness/figma-ds-map.js` → `harness/workbench.js` → `shared-*.js` → `bj*.js` / `cap01.js` → `hub.js`.
- **Khung:** `renderAppScreen()` → theme root `ThemeApp.renderRoot()` hoặc `rendererFor(…)(state)` + `ThemeApp.afterFlowRender()`. Routing lối vào: `entryTargets` / `applyEntry` / `onEntry`. Actor: `currentActor()`.
- **QA:** một object `window.__VET45_QA__` (BJ chỉ `Object.assign`). Fixture `__VET45_MONEY_*` / `FX` / `TAX` / `COST_POLICY` và metadata `__VET45_PROTOTYPE__` giữ riêng.
- Sửa UI: **sửa thẳng** file sở hữu; không thêm lớp vá `vNNN`.

## Golden

```bash
python3 -m http.server 8765 --bind 127.0.0.1 &
node tools/golden.mjs capture tools/.golden-now
node tools/golden.mjs compare tools/.golden-g3 tools/.golden-now
node tools/golden.mjs usage tools/.usage-now   # CSS unused + JS uncovered
FULL=1 node tools/golden.mjs capture tools/.full-now  # ảnh toàn trang (harness)
AUDIT_JS=<tệp biểu thức JS> node tools/golden.mjs capture tools/.audit-now SC_journey_4  # chạy kiểm sau mỗi bước, ghi _audit.json
AUDIT_JS=tools/audit.js node tools/golden.mjs capture tools/.audit-now   # audit toàn theme (tools/audit.js)

# Khung Web 1280×800 (chỉ chụp nhóm màn × trạng thái + kịch bản trong WEB_SCENARIOS của golden.mjs; tên ca thêm @web)
DEVICE=web node tools/golden.mjs capture tools/.golden-web-now
node tools/golden.mjs compare tools/.golden-g3-web tools/.golden-web-now
```

Mốc hiện có: `tools/.golden-g3` (2241 ca, iPhone) / `tools/.golden-g3-web` (1350 ca) = hết Giai đoạn 3 (G3-7, v5.26.1); prototype sau đó chỉ đổi chữ phiên bản (v5.27.0 FROZEN) nên mốc này là bản cuối. Các mốc cũ hơn (Giai đoạn 1, chặng 1–6, từng BJ, G3-1…G3-7, audit / keys / deadends) đã xoá 2026-11-09; cần thì chụp lại bằng `capture` ở commit tương ứng (xem CHANGELOG). Thư mục `.golden*/`, `.full*/`, `.usage*/`, `.audit*/`, `.keys*/`, `.deadends*/` không vào git.

**Ảnh đích cho Flutter:** `tools/proto-final/iphone/` và `tools/proto-final/web/` (500 ảnh mỗi khổ, chép từ `.golden-g3` / `-web`: chỉ ca màn × trạng thái `UIF-*`, `HUB_*`, `CAP-*`; bỏ kịch bản `SC_*` và `.txt`). Không vào git; plan Flutter chép ảnh cần dùng sang `docs/refactor/plans/T7/img/<plan>/` (PLAN.md, quy ước "UI Flutter: trích nguyên code prototype vào plan"). Tạo lại:

```bash
cd tools && mkdir -p proto-final/iphone proto-final/web
cp .golden-g3/{UIF-,HUB_,CAP-}*.png proto-final/iphone/
cp .golden-g3-web/{UIF-,HUB_,CAP-}*.png proto-final/web/
```
