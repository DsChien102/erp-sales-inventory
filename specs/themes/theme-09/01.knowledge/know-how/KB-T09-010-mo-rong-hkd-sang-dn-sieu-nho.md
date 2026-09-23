# KB-T09-010 — Mở rộng từ HKD sang doanh nghiệp siêu nhỏ

## Trả lời ngắn
Theme 09 không nên gắn cứng entity với TT152, vì VET45 hướng tới doanh nghiệp nhỏ và lộ trình pháp lý 2026 đã có chế độ riêng cho doanh nghiệp siêu nhỏ.

## Product implication
`AccountingSchemeVersion` phải chứa rule về:
- book set;
- account code có bắt buộc không;
- debit/credit có bắt buộc không;
- validation;
- report/form mapping;
- effective date.

## Vì sao abstraction này không phải over-engineering
Nó chỉ tách phần thay đổi theo chế độ khỏi source fact/entry identity. Nếu sau này TT58/2026 hoặc chế độ khác được bật, VET45 thêm scheme/policy thay vì migrate toàn bộ core model.

## Nguồn
Bộ Tài chính công bố Thông tư 58/2026/TT-BTC cho doanh nghiệp siêu nhỏ, hiệu lực từ 01/07/2026 theo thông tin công bố.
