# BJ-02 / UIF-02 — Pilot Review v0.2.7

## 1. Mục tiêu vòng này

Thiết kế lại BJ-02 thành golden candidate cho Theme 7 theo đúng các quyết định đã brainstorm: multi-product thực tế, one-supplier receipt, one-item mobile editor, multi-UOM bằng separate items, LOT/expiry theo Product policy, không tạo master data trong receipt, và giảm tối đa thông tin/action không giúp user hoàn thành việc nhận hàng.

## 2. Kiến trúc UX sau redesign

```text
Nhận theo chứng từ
SCR-006 → SCR-007 ─┐
                    ├→ SCR-009 ⇄ SCR-084 → SCR-010 → approval/routing → SCR-012
Nhập hàng nhanh     │
SCR-006 → SCR-008 ─┘                                      └ UNKNOWN → SCR-013
```

### Mental task

| Screen | Task duy nhất |
|---|---|
| `SCR-006` | Chọn cách nhận hàng |
| `SCR-007` | Chọn chứng từ đang nhận |
| `SCR-008` | Khai thông tin chung của lần nhập nhanh |
| `SCR-009` | Theo dõi các mục hàng đã/chưa xử lý |
| `SCR-084` | Ghi thực nhận cho đúng một Product + UOM |
| `SCR-010` | Rà soát toàn bộ receipt trước submit |
| `SCR-011` | Duyệt hoặc từ chối |
| `SCR-012` | Xem processing/final result |
| `SCR-013` | Theo dõi recovery khi kết quả chưa rõ |

## 3. Các quyết định đã khóa

1. **Một receipt = một Supplier.** Một Supplier có thể có nhiều receipt; không mixed Supplier trong cùng receipt.
2. **BJ-02 không tạo Supplier/Product.** Master chưa tồn tại thì user chuẩn bị ở Theme 3/Theme 2 rồi quay lại.
3. Document và Quick đều hỗ trợ **nhiều sản phẩm**.
4. `SCR-009` là shared overview; không render giant multi-product form.
5. Thêm `SCR-084` làm canonical item editor trên mobile.
6. Ở UX, một receipt item = **Product + transaction UOM**.
7. Document UOM lấy từ source; Quick chỉ hỏi UOM khi Product có nhiều UOM nhập hợp lệ.
8. Same Product + different UOM = separate items. Quick same Product + same UOM duplicate = block và mở item hiện có.
9. Product tracking policy do Product domain cung cấp; receipt không cho user chọn `NONE/LOT`.
10. `NONE`: không hiển thị LOT. `LOT`: code required; expiry required/optional theo policy; manufacture date optional; multi-lot được phép.
11. Quantity defaults all actual as `Đạt`; quarantine/damaged/rejected chỉ reveal khi có exception.
12. Document item không giao có explicit `Chưa nhận lần này`; khác `Chưa ghi nhận`.
13. Quick always approval; Document chỉ approval khi policy/exception.
14. Approval chỉ Approve/Reject; reject reason bắt buộc trong `VBottomSheet`.
15. Execution auto after routing; UNKNOWN không tạo lần nhận mới.

## 4. Vì sao thêm SCR-084

`SCR-084` không phải screen kỹ thuật. Nó giải quyết một mental task riêng: "mục hàng này thực tế nhận bao nhiêu và ở tình trạng/lô nào?".

Nếu giữ tất cả trong `SCR-009`, một receipt 10–50 sản phẩm sẽ tạo trang mobile rất dài, lặp Product card, quantity, LOT, expiry và exception inputs. `SCR-084` cho phép:

- overview vẫn scan nhanh;
- chỉ một editor hoạt động tại một thời điểm;
- user luôn biết tiến độ receipt;
- Document/Quick reuse cùng interaction pattern;
- multi-lot không làm nổ chiều dài của overview;
- Back giữ draft, không phát sinh CTA `Lưu nháp` vô ích.

## 5. Receipt item và technical lines

UI/business item được nhóm theo Product + transaction UOM để user thao tác tự nhiên. Backend line hiện còn atomic theo lot/state, vì vậy một UI item có thể materialize thành nhiều `InventoryOperationLine` kỹ thuật. `receipt_item_ref` được thêm vào contract để giữ grouping ổn định và tái hiện đúng receipt item trên UI/audit.

Ví dụ:

```text
Nobivac DHPPi · hộp
  LOT A: 8 đạt + 2 cách ly
  LOT B: 10 đạt
```

UI = một item `Nobivac DHPPi + hộp`; persistence có thể gồm nhiều technical lines theo LOT/state nhưng cùng `receipt_item_ref`.

## 6. Multi-UOM

Không có UX `+ Thêm đơn vị khác` bên trong một item.

- Document: UOM đã do source xác định.
- Quick: user chọn UOM nếu có nhiều lựa chọn nhập hợp lệ.
- Nếu thực tế nhận cùng Product bằng hai UOM (`2 hộp + 5 lọ`), tạo hai receipt items của cùng Product, mỗi item một UOM.
- Không cộng tổng quantity xuyên UOM trên list/review/result nếu chưa quy đổi có ý nghĩa cho user.

## 7. Quantity và LOT UX

### NONE

User nhập `Số lượng thực nhận`; mặc định accepted = total. Chỉ khi có ngoại lệ mới reveal Cách ly/Hỏng/Từ chối.

### LOT

Không nhập total ở Product level rồi nhập lại ở LOT. User nhập ở từng LOT; total item derive từ tổng LOT. `Thêm lô` là secondary action. Không Badge `LOT`; section title đã đủ nghĩa.

## 8. Các sửa tài liệu đi kèm

V0.2.7 back-propagates pilot decisions vào:

- BJ-02;
- UC-02-01, UC-02-02, UC-02-03;
- shared behavioral contracts;
- data entities (`supplier_id`, `supplier_version_id`, `receipt_item_ref`);
- decision register (`T7-DR-103..105`);
- glossary (`Mục hàng nhận / Receipt item`);
- wiki nhận hàng mua;
- UIF-02 flow;
- nine Screen Contracts including new SCR-084;
- UIF-02 component usage MD/YAML;
- screen registry/workbench data.

Theme 2 tracking-policy configuration itself is intentionally **not invented here**; BJ-02 only consumes Product-domain `NONE/LOT/expiry_required` as agreed.

## 9. Mandatory fixture gate

BJ-02 is not a golden standard until all of these remain usable:

1. Document · 1 Product · NONE.
2. Document · nhiều Product.
3. Document · partial / `Chưa nhận lần này`.
4. LOT · 1 lot.
5. LOT · nhiều lot.
6. Quick · nhiều Product.
7. Quick · same Product, different UOM.
8. Quick · duplicate same Product + UOM.
9. LOT expiry conflict.
10. Missing Supplier/Product master → no-create state.

## 10. Freeze boundary

V0.2.7 intentionally changes BJ-02 and shared source-of-truth documents only where required by the BJ-02 decisions. Other UIF flow/component/screen contracts remain byte-identical to the v0.2.6 baseline. Historical Design Readiness checkpoint files are not rewritten; SCR-084 must enter the next readiness checkpoint if the pilot is accepted.
