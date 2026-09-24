# Inventory Operations — Holistic Product UX Correction v1.4.1

**Parent:** v1.4.0  
**Scope:** UIF-01, UIF-02, UIF-04, UIF-05, UIF-06, UIF-07  
**Viewport:** 402×874  
**Design authority:** Flutter Design System  
**Change class:** Product UI/UX correction; no SRS/business-rule change.

## 1. Product finding that triggered this release

Product review phát hiện `BJ07 / SCR-036 — Hàng chờ trả nhà cung cấp`, đặc biệt card `Đang chờ`, đang dùng helper text như một nơi chứa nhiều explanation/state metadata. Card vì vậy mất hierarchy: user phải đọc prose để hiểu trạng thái thay vì scan request + source + badge.

Vấn đề này được dùng làm trigger để QA **toàn bộ Inventory Operations**, thay vì sửa cục bộ riêng BJ07.

## 2. QA lenses

Mỗi UIF được review qua các lớp sau:

1. **Information necessity** — thông tin nào thực sự cần để ra quyết định ở screen hiện tại.
2. **Visual hierarchy** — primary identity, supporting metadata và exception state không cạnh tranh nhau.
3. **Ownership/affordance** — source-owned/read-only task không giả lập khả năng thao tác.
4. **Feedback semantics** — READY yên tĩnh; warning/banner chỉ cho exception/blocker/stale/recovery.
5. **Duplicate communication** — số liệu, badge, helper và banner không nói lại cùng một fact.
6. **Business language** — không lộ technical IDs/internal operation wording khi không phục vụ user.
7. **Mixed-UOM/LOT safety** — không aggregate quantity sai nghĩa, không làm mất allocation evidence.
8. **Mobile execution** — touch/scroll/sticky footer/overflow ở 402×874.
9. **Finality** — consumed commit không quay lại; UNKNOWN không blind retry.
10. **Isolation** — không làm regression UIF03 valuation hoặc business specs.

## 3. Corrections by Business Journey

### BJ01 / UIF01 — Tồn kho

- Rút status chip về business keyword `Cận hạn / Hết hạn`; bỏ tiền tố lặp “Có lô…”.
- Context timestamp đổi sang data-first copy; bỏ wording nặng `Cập nhật lúc`.
- Attention banner dùng số liệu `Khả dụng / Ngưỡng` làm chính, helper ngắn hơn.
- Không đổi stock semantics hoặc provenance.

### BJ02 / UIF02 — Nhận hàng mua

- `SCR-008`: intro rút gọn; `Kho nhận` là system-owned read-only field, không còn dropdown chevron/select affordance giả; uploaded evidence helper rút còn `Thay file`.
- `SCR-009`: Product discovery card chỉ giữ identity + UOM; không hiển thị tracking-policy jargon `Theo lô / Không theo lô` ở browse surface.
- `SCR-084`: bỏ helper lặp “Tổng … được tính tự động”; derived total vẫn hiển thị như authoritative summary.
- Không thay đổi rule Supplier/Product master, UOM, LOT/expiry hay approval.

### BJ04 / UIF04 — Giữ hàng theo đơn

- READY/FULL không còn success banner thường trực `Đã giữ đủ hàng`.
- PARTIAL giữ warning vì user cần biết phần thiếu đã trả về source order.
- Bỏ metadata `Hệ thống tự cập nhật`; footnote về availability/physical được rút gọn.
- Reservation vẫn system/source-driven, không phát sinh mutation CTA.

### BJ05 / UIF05 — Soạn hàng và bàn giao

- `SCR-025`: waiting/source-owned order card là `<div>` read-only; không chevron/click; một metadata line; badge `Chờ đơn bán`.
- `SCR-026`: bỏ duplicate pick-state badges khi numeric progress đã đủ; LOT helper chỉ còn `Lô X` hoặc `N lô`; source-waiting detail không cho navigation.
- `SCR-027`: physical correction/alternative LOT helper ngắn và action-oriented hơn.
- `SCR-028`: summary dùng `mục hàng`; normal rule chuyển về quiet helper; không cross-UOM aggregation.
- `SCR-029`: completed không hiển thị `Còn lại 0`; UNKNOWN bỏ technical identity và cấm blind retry.

### BJ06 / UIF06 — Nhận hàng khách trả

- `SCR-030`: approval-owned waiting card read-only, không chevron; badge `Chờ duyệt lô`.
- `SCR-031`: normal unverified row không lặp badge `Chưa kiểm`; waiting item là true read-only; source/LOT helper concise.
- `SCR-032`: mismatch/evidence helper rút gọn nhưng giữ đủ maker-checker evidence requirement.
- `SCR-034`: approval list dẫn bằng Product/request identity; internal approval case ID không hiện cho Product user.
- `SCR-033`: incomplete classification không lặp warning badge trên mọi row; validation nêu số đã phân loại / số phải đủ.
- `SCR-035`: UNKNOWN dùng business-facing recovery copy.

### BJ07 / UIF07 — Trả hàng nhà cung cấp

- `SCR-036`: queue card tối đa một supporting metadata line. Waiting card chỉ còn request + `supplier · source` + badge `Chờ cập nhật`; không prose helper, không chevron/click.
- Source-changed actionable task dùng badge `Cần kiểm lại`; không lặp event copy trong helper.
- `SCR-037`: bỏ tracking tail `N LOT` ở Product header; normal allocations không lặp `Cần kiểm`; exception/verified state mới dùng badge. Verification sheet dùng standard VBottomSheet, không custom close icon; một concise helper trước CTA.
- `SCR-039`: bỏ per-allocation `Đã kiểm thực tế`; normal informational banner được đổi thành quiet footnote; source stale vẫn dùng warning/delta.
- `SCR-041`: result copy concise, no technical operation ID, no duplicate UOM in label.

## 4. Business invariants deliberately unchanged

- BJ05 Order/Fulfillment scoping, Product+UOM→1..N LOT allocations, physical repick after invalidation, actual handover commit semantics.
- BJ06 multi-line return receipt, all-or-nothing receipt commit, wrong-LOT maker-checker evidence/approval, classification model.
- BJ07 source-authorized return, granular source-delta invalidation, no warehouse silent LOT substitution/quantity amendment, actual handover physical/value commit, no second commercial approval.
- BJ01/BJ02/BJ04 business rules are unchanged.
- UIF03/BJ03 valuation behavior from v1.4.0 is protected and must remain pixel/text equivalent.

## 5. QA evidence

- End-user/state QA: `INVENTORY-OPERATIONS-END-USER-QA-v1.4.1.md`.
- Static/contract conformance: `INVENTORY-OPERATIONS-STATIC-CONFORMANCE-v1.4.1.md`.
- Runtime smoke: `ALL-FLOWS-RUNTIME-SMOKE-v1.4.1.md`.
- Visual QA: `VISUAL-QA-v1.4.1.md` + 402×874 contact sheet.
- UIF03 regression: `REGRESSION-UIF03-v1.4.1.md`.
- File isolation: `ISOLATION-REPORT-v1.4.1.md`.

## 6. Product gate

Technical QA PASS means release is a **Product review candidate**. Product approval/freeze remains an explicit Product decision.
