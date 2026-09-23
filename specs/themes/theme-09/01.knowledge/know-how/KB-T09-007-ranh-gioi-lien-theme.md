# KB-T09-007 — Ranh giới liên Theme

## Trả lời ngắn
Theme 09 ghi sổ, nhưng không vì thế mà sở hữu mọi số xuất hiện trên sổ.

## Ownership map
- Theme 5: giao dịch bán.
- Theme 6: phải thu/phải trả và thu/chi/phân bổ.
- Theme 7: tồn kho, valuation, giá vốn chính thức.
- Theme 8: hóa đơn điện tử.
- Theme 10: mua hàng, điều khoản và quyền lợi thương mại.
- Theme 09: accounting representation, period, books, tax compliance theo scope.

## Anti-corruption rule
Nếu upstream thay semantic, integration adapter map về `AccountingFact`; Theme 09 không copy nguyên state machine của upstream vào domain mình.

## Ví dụ trả NCC
Theme 7 có thể xác nhận hàng trả; Theme 10 xác nhận commercial adjustment; Theme 6 cập nhật payable theo căn cứ; Theme 09 ghi accounting effect. Không để Theme 09 “giảm công nợ” trực tiếp.
