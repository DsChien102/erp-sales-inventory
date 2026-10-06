# KB-T09-005 — Sổ kế toán HKD theo TT152

## Trả lời ngắn
Từ 01/01/2026, Thông tư 152/2025/TT-BTC hướng dẫn kế toán cho hộ/cá nhân kinh doanh. Baseline Theme 09 coi đây là chế độ đầu tiên đề xuất cho Phase 1.

## Các mẫu sổ xuất hiện trong hướng dẫn
- `S1a-HKD` — Sổ doanh thu bán hàng hóa, dịch vụ cho trường hợp áp dụng tương ứng.
- `S2a-HKD` — Sổ doanh thu theo nhóm ngành/tỷ lệ theo trường hợp tương ứng.
- `S2b-HKD` — Sổ doanh thu bán hàng hóa, dịch vụ trong nhóm phương pháp tương ứng.
- `S2c-HKD` — Sổ chi tiết doanh thu, chi phí.
- `S2d-HKD` — Sổ chi tiết vật liệu, dụng cụ, sản phẩm, hàng hóa.
- `S2e-HKD` — Sổ chi tiết tiền.
- `S3a-HKD` — Sổ theo dõi nghĩa vụ thuế khác khi có.

## Điểm product phải hiểu đúng
“Có 7 mẫu sổ” không có nghĩa một hộ phải mở cả 7. `AccountingProfile/AccountingSchemeVersion` phải xác định tập sổ áp dụng theo classification và rule hiện hành.

## Cách model
Không biến từng mẫu sổ thành source-of-truth database riêng. Canonical entries/facts là nguồn; mỗi book là projection có rule/version và export snapshot.

## Nguồn pháp lý
Thông tư 152/2025/TT-BTC và hướng dẫn Bộ Tài chính tháng 01/2026.
