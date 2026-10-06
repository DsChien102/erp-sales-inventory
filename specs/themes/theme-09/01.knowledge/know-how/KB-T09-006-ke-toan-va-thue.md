# KB-T09-006 — Kế toán và thuế

## Trả lời ngắn
Kế toán và thuế dùng chung nhiều dữ liệu nhưng không nên là một record duy nhất.

## Vì sao
Một giao dịch có thể được trình bày kế toán theo một cách nhưng taxable base, kỳ khai hoặc rule thuế lại khác. Pháp luật/form cũng thay đổi nhanh hơn core accounting history.

## Mô hình đề xuất
- Accounting Entry: kết quả ghi sổ.
- Tax Calculation Run: phép tính thuế theo policy/source watermark.
- Tax Return Snapshot: nội dung hồ sơ theo form schema version.

## Lợi ích
- sửa rule thuế không rewrite sổ;
- tái tính được theo policy version;
- audit biết tờ khai đã dùng dữ liệu nào;
- dễ thay form mà không đổi core entity.
