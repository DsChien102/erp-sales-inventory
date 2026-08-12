---
id: UC-04-03
type: use-case
theme: theme-07
title: "Kết thúc và giải phóng"
owner: BA
status: IN_REVIEW
source_baseline: v3.10.1
---
# UC-04-03 — Kết thúc và giải phóng

## 1. Mục tiêu và outcome

Giải phóng current held quantity còn lại.

**Kết quả thành công:** Current held = 0 cho scope kết thúc; reason `SOURCE_CANCEL`, `SOURCE_COMPLETE`, `SOURCE_RELEASE` hoặc `SOURCE_EXPIRY`; consumed history giữ nguyên.

## 2. Ranh giới

### 2.1 Bắt đầu khi

Source cancel/complete/release hoặc source-owned expires_at đến hạn

### 2.2 Kết thúc khi

Current held = 0 cho scope kết thúc; reason `SOURCE_CANCEL`, `SOURCE_COMPLETE`, `SOURCE_RELEASE` hoặc `SOURCE_EXPIRY`; consumed history giữ nguyên.

### 2.3 Không bao gồm

Phạm vi không thuộc UC được giữ theo BJ cha và các contract nguồn; migration không bổ sung negative scope mới.

## 3. Actor, trigger và điều kiện trước

- **Actor:** Source system / system process
- **Trigger:** Source cancel/complete/release hoặc source-owned expires_at đến hạn
- **Điều kiện trước:** Source/version current; Advanced Stock; tenant/store/warehouse hợp lệ; policy/lifecycle cho phép; server guard authoritative.

## 4. Hành vi nghiệp vụ

### Quy tắc và bất biến

<ul><li>Capability: chỉ `ADVANCED`; `reservation_policy=NONE` không tạo Reservation.</li><li>Quantity: bảo toàn transaction UOM + precision + conversion version; `reserved_base_quantity` là current hold, `consumed_base_quantity` là cumulative committed handover.</li><li>Priority khi thiếu: `reservation_priority` → `source_confirmed_at` cũ hơn → stable `source_line_id`.</li><li>Không auto top-up; source phải gửi amend/re-evaluate version mới.</li><li>`expires_at` chỉ source-owned; không implicit TTL.</li><li>Combo commit nguyên tử qua ReservationGroup + child component reservations.</li><li>Sau active PickAllocation, BJ-04 không sửa allocation; chỉ phát `allocation_review_required` cho BJ-05.</li><li>Expiry không được tự đặt TTL; chỉ thực thi `expires_at`/expiry semantics do source contract sở hữu.</li></ul>

## 5. Ngoại lệ và thất bại

**Không thành công:** No owner effect ngoài result/evidence hợp đồng cho phép; trả structured code/shortage.

**Chưa xác định:** UNKNOWN giữ nguyên command/idempotency identity và đối soát trước mọi retry.

## 6. Ảnh hưởng nghiệp vụ



**Kiểm toán:** source/version, policy, UOM/conversion snapshot, trigger/reason, priority facts, command identity và result.

## 7. Behavioral Contract

- **Hợp đồng hành vi chính:** [BC-IO-06 — Adjust reservation capacity](../behavioral-contracts/BC-IO-06.md)

## 8. Screen liên quan

| Thuộc tính | Nội dung |
|---|---|
| Màn hình | [SCR-021](../../../03.design/screens/SCR-021.md) — read-only current reservation projection khi source order có reservation context. |
| Trạng thái active | `READY`, `LOADING`, `PERMISSION_DENIED`; shortage/released/consumed là line facts, không global screen state. |
| Hành động | Back only; không mutation CTA cho reservation lifecycle. |
| Entry | Contextual from order/source; không global Inventory discovery. |

## 9. Acceptance Scenarios

| ID | Given | When | Then |
|---|---|---|---|
| AS-UC-04-03-01 | Source/version và capability hợp lệ | Source/system gửi release lifecycle action | Current held = 0 cho scope kết thúc; reason `SOURCE_CANCEL`, `SOURCE_COMPLETE`, `SOURCE_RELEASE` hoặc `SOURCE_EXPIRY`; consumed history giữ nguyên. |
| AS-UC-04-03-02 | `reservation_policy=NONE` hoặc Basic Stock | Source gửi/resolve capability | Không tạo Reservation/ReservationBucket effect; trả result `NOT_REQUIRED`/capability boundary. |
| AS-UC-04-03-03 | Cùng idempotency identity được gửi lại | Adapter retry | Trả cùng result hoặc payload conflict; không tạo effect trùng. |
| AS-UC-04-03-04 | Không chứng minh được commit/no-commit | Client timeout/xử lý gián đoạn | UNKNOWN; giữ cùng identity và reconcile. |

## 10. Truy vết

- **Nguồn quyết định:** [G04 — Khả dụng, giữ hàng, lấy hàng và xuất](../../../01.knowledge/decisions/decision-register.md#34-g04-kh%E1%BA%A3-d%E1%BB%A5ng-gi%E1%BB%AF-h%C3%A0ng-l%E1%BA%A5y-h%C3%A0ng-v%C3%A0-xu%E1%BA%A5t) · `T7-DR-144…149`



### Nguồn v3.10.1 — UC-04-03 — Kết thúc và giải phóng

> **Phiên bản:** 4.1.0 + v3.9.6 semantic amendment  
> **Loại:** Trường hợp sử dụng  
> **Hành trình nghiệp vụ:** [BJ-04 — Quản lý vòng đời giữ hàng](../journeys/BJ-04-quan-ly-vong-oi-giu-hang.md)  
> **Trạng thái:** DEEP_REVIEWED_CANDIDATE

> **Deep-review amendment v3.9.6:** Operation do source/system kích hoạt; Inventory UI không có direct mutation CTA. Reservation chỉ dành cho Advanced Stock và phải dùng explicit source reservation policy + transaction-UOM snapshot.

### Nguồn v3.10.1 — 6. Truy vết

BJ-04 sở hữu reservation capacity; BJ-05 sở hữu active LOT allocation/pick/handover. Mọi thay đổi ảnh hưởng allocation chỉ phát review signal, không cross-owner mutation.
