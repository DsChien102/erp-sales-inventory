# EVD — Snapshot-led Visual QA v4.5.0

## Kết quả

- **PASS** — 82/82 active screen snapshots.
- **PASS** — 17/17 UIF contact sheets.
- **PASS** — 486/486 canonical screen-state renders.
- **PASS** — 13 high-risk state snapshots.
- Browser runtime errors: **0**.

## Cách review

1. Chụp product viewport `402×874` cho từng màn active, không dùng screenshot của workbench thay cho màn sản phẩm.
2. Ghép contact sheet theo từng UIF và review trực quan typography, spacing, alignment, card/surface, form rhythm, banner, list row, footer và overflow.
3. Đối chiếu v4.4.0 để xác định regression; dùng snapshot v3.5.x như visual reference ở các màn từng ổn, nhưng không dùng bản cũ làm nguồn semantic.
4. Render mọi canonical state để bắt lỗi chỉ xuất hiện ở warning/error/approval/processing.

## Finding đã sửa

- `SCR-008` và các state dùng banner dài: copy tràn khỏi `VBanner` Compact; sửa bằng đúng density/copy budget theo Figma DS, không kéo cao component.
- Các banner dài ở BJ03/BJ04/BJ06/BJ07/BJ09/BJ11/BJ13: rút copy hoặc dùng density phù hợp, giữ semantic.
- BJ13: lý do kỳ ghi nhận dài không còn bị ép vào `Info Row` 44px; chuyển thành read-only text block trong cùng grouped surface.
- BJ16: `VProgress` không còn chứa title/helper trong thanh progress; bar và copy tách đúng anatomy.
- Giữ nguyên grouped-surface rule của v4.4.0 và các sửa valuation UI/UX v4.3.x.

## Giới hạn

Đây là bằng chứng prototype/design review. Không thay thế production implementation, device-native integration hoặc production E2E evidence.
