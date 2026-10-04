---
id: BC-IV-01
type: behavioral-contract
theme: theme-07
title: "Xác nhận giá trị nhập ban đầu"
owner: BA
status: FROZEN
source_baseline: v3.12.0
---
# BC-IV-01 — Xác nhận giá trị nhập ban đầu

## 1. Ý định

Ghi **giá trị nhập ban đầu** cho đúng lượng hàng đã nhận và đã thuộc tenant, dựa trên bộ căn cứ còn hiệu lực tại thời điểm xác nhận. Mutation ghi value movement và chuyển đúng quantity khỏi `VALUATION_PENDING`; **không** tạo `OfficialCostVersion`.

## 2. Phạm vi áp dụng

- **Loại:** Command.
- **Owner:** `DOM-IV`; phối hợp `DOM-IO` để chuyển valuation axis và đánh giá lại khả dụng.
- **Journey / UC:** `BJ-03` / `UC-03-01`.

## 3. Đầu vào nghiệp vụ

Mỗi phạm vi được xác nhận phải có:

- receipt item và exact quantity được căn cứ bao phủ;
- `valuation_basis_key`, version/hash của căn cứ hiện hành;
- scope/version dùng để bảo vệ quantity còn `VALUATION_PENDING`;
- transaction UOM + snapshot quy đổi sang base UOM;
- các thành phần giá trị đã đủ căn cứ: giá mua, khoản giảm giá trị mua, thuế/phí không thu hồi, chi phí mua trực tiếp đã biết và các component hợp lệ khác;
- tax treatment / FX / allocation policy version từ nguồn có thẩm quyền khi áp dụng;
- source/provenance và evidence reference cần thiết;
- command/idempotency identity.

Đối với Quick receipt, căn cứ trực tiếp có thể được xác lập trong Theme 7 theo `T7-DR-186/187`. Đối với nhận theo chứng từ, Theme 7 tiêu thụ nguồn thương mại hợp lệ từ Theme 10 và không sửa nguồn đó.

## 4. Điều kiện trước

- Actor có quyền tài chính phù hợp.
- Receipt đã hoàn tất vật lý và quantity thuộc tenant.
- Exact quantity còn `VALUATION_PENDING` và chưa được ghi initial value trước đó.
- Phạm vi xác nhận do **căn cứ/source coverage** chứng minh; không chấp nhận quantity do người dùng tùy ý chia.
- Căn cứ, source revision, tax/FX/allocation policy và scope version còn current.
- Mâu thuẫn thương mại thuộc Theme 10 đã được Theme 10 giải quyết; mâu thuẫn giữa các căn cứ trực tiếp của Quick chỉ được resolve trong Theme 7 khi policy cho phép.
- Hệ thống tính được VND value. Giá trị `0` chỉ hợp lệ khi source authoritative thực sự cho ra 0; không dùng 0 thay cho “chưa biết”.

## 5. Quy tắc nghiệp vụ

1. Server dựng lại bộ căn cứ hiện hành và xác định exact quantity được cover.
2. Server áp tax treatment từ policy có thẩm quyền; người dùng không chọn VAT/thuế có được thu hồi hay không.
3. Server chuẩn hóa tiền tệ/UOM, phân bổ deterministic và tính authoritative allocated value.
4. Server ghi `ReceiptValuation` + append `InventoryValueMovement` tại receipt business date, giữ recorded-at là commit time.
5. Cùng commit, exact quantity chuyển `VALUATION_PENDING → VALUATION_CONFIRMED`; physical state không đổi.
6. Khả dụng được đánh giá lại theo physical state, reservation và mọi blocker hiện hành.
7. Exact `Product + posting period` được đánh dấu cần cập nhật giá vốn cho BJ14.
8. **Không** bootstrap hoặc publish `OfficialCostVersion` trong BC này.

## 6. Điều kiện bắt buộc

- Không overwrite `ReceiptValuation` đã xác nhận; fact đến sau đi BJ13, lỗi nhập liệu đi BJ11.
- Nếu một selected scope/basis stale, toàn command bị từ chối trước mutation; không partial commit.
- `source` và `evidence` là hai khái niệm khác nhau và phải giữ provenance độc lập.
- VAT/thuế đã bao gồm trong giá nguồn không được cộng lần hai.

## 7. Ảnh hưởng trạng thái

Thành công tạo:

- `ReceiptValuation` bất biến cho exact covered quantity;
- một hoặc nhiều `InventoryValueMovement` theo atomic commit set;
- chuyển valuation state cho đúng quantity;
- dirty cause cho `Product + posting period` cần BJ14 xử lý;
- audit/provenance đầy đủ.

Không thay physical state và không tự đổi dữ liệu Theme 10.

## 8. Tính nguyên tử và kết quả cuối

`ReceiptValuation + value movement + valuation-state transition + dirty marking + outbox facts` phải cùng thành công hoặc cùng rollback. Nếu kết quả command chưa xác định, dùng cùng operation identity để làm rõ; không phát lại như yêu cầu mới.

## 9. Kết quả và semantics lỗi

- `PRICE_EVIDENCE_REQUIRED` — chưa đủ căn cứ để xác lập value.
- `VALUATION_BASIS_STALE` — căn cứ/source version đã đổi.
- `VALUATION_SCOPE_STALE` — quantity/scope không còn đúng.
- `VALUATION_QUANTITY_EXCEEDS_PENDING` — source coverage vượt quantity còn chờ.
- `VALUATION_BASIS_CONFLICT` — nhiều căn cứ còn mâu thuẫn và chưa có owner resolution hợp lệ.
- `CONFIRMATION_ALREADY_APPLIED` — exact economic scope đã ghi initial value.
- `CURRENCY_MISMATCH` / `FX_BASIS_REQUIRED` — chưa tính được VND value.
- `ORIGINAL_PERIOD_LOCKED` — business date không thể ghi theo policy hiện hành.

## 10. Domain và UC sử dụng

- **Domain / Entity:** `DOM-IV`; `ENT-IV-01`, `ENT-IV-02`; đọc `DOM-IO` / receipt facts.
- **UC:** `UC-03-01`.
- **API/Event trace:** `API-C-20`, `EVT-IV-03`. Mapping thực thi thuộc work slice lúc review để implement.
- **Decision:** `T7-DR-021`, `025`, `051`, `150…156`, `185…191`.
