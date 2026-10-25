# Theme 7 HTML Prototype Harness · v5.3.0

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
node tools/golden.mjs compare tools/.golden-phase1 tools/.golden-now
node tools/golden.mjs usage tools/.usage-now   # CSS unused + JS uncovered
FULL=1 node tools/golden.mjs capture tools/.full-now  # ảnh toàn trang (harness)
AUDIT_JS=<tệp biểu thức JS> node tools/golden.mjs capture tools/.audit-now SC_journey_4  # chạy kiểm sau mỗi bước, ghi _audit.json

# Khung Web 1280×800 (chỉ chụp nhóm màn × trạng thái + kịch bản trong WEB_SCENARIOS của golden.mjs; tên ca thêm @web)
DEVICE=web node tools/golden.mjs capture tools/.golden-web-now
node tools/golden.mjs compare tools/.golden-web-base tools/.golden-web-now
```

Mốc `tools/.golden-phase1` (1348 ca) = trạng thái hết Giai đoạn 1 sau A12, khớp mọi mốc trước Giai đoạn 1. Mốc `tools/.golden-web-base` (555 ca, `DEVICE=web`) = khung web sau H1, mốc cho BJ-12. Thư mục `.golden*/`, `.full*/`, `.usage*/` không vào git — chụp lại mốc trên máy mới bằng `capture` ở một commit đã biết đúng. Mốc `tools/.golden-chang1` / `tools/.golden-chang1-web` = hết chặng 1 "Mở kho" (sau CAP-01, v5.7.0). Mốc `tools/.golden-bj02-after` / `tools/.golden-bj02-web-after` = sau BJ-02 (v5.8.0). Mốc `tools/.golden-bj03-after` / `tools/.golden-bj03-web-after` = sau BJ-03 (v5.9.0), mốc cho BJ-13.
