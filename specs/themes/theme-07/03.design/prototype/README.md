---
id: PROTOTYPE
type: prototype-manifest
theme: theme-07
title: "Theme 07 mobile prototype mapping"
owner: BA
status: FROZEN
source_baseline: v5.27.0
version: v5.27.0
---
# Prototype — Theme 07

Prototype HTML của Theme 7 (Kho & Giá vốn) cho điện thoại. Nguồn hình ảnh và hành vi cho code Flutter; nghiệp vụ theo BJ / UC.

## Chạy

    cd specs/themes/theme-07/03.design/prototype/html
    python3 -m http.server 8765 --bind 127.0.0.1
    # mở http://127.0.0.1:8765/index.html

- Theo từng luồng: `?uif=UIF-02&screen=SCR-010&state=PENDING_APPROVAL` (UIF-02 thêm `&flow=quick` hoặc `&flow=document`).
- Toàn Theme 7 từ Hub Kho: `?mode=theme&app=inventory`.

## Cấu trúc và cách sửa

Xem [`html/README.md`](html/README.md): cấu trúc thư mục, khung `app/core.js` + `app/hub.js`, mỗi BJ một file `app/bjNN.js`, công cụ golden.

## Đặc tả đi kèm

- Screen Contract: [`../screens/`](../screens/) — bảng tra [`INDEX.md`](../screens/INDEX.md), màn đã bỏ [`RETIRED.md`](../screens/RETIRED.md).
- UI Flow: [`../flows/`](../flows/).
- Kế hoạch thiết kế lại: `docs/refactor/plans/T7/T7-P-thiet-ke-lai-luong.md`.

## Lịch sử

[`html/CHANGELOG.md`](html/CHANGELOG.md) từ v5.0.0; các phiên bản trước (v0.2 → v4.6.8) xem lịch sử git của thư mục này.
