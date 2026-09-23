# Impact Set — v0.2.0

## Added/expanded semantic areas

- Knowledge model cho toàn Theme 10.
- Ubiquitous language và thuật ngữ thân thiện tiếng Việt.
- Domain context + invariants.
- Semantic aggregates/entities.
- Candidate resolutions cho Q-01/Q-02/Q-04/Q-05/Q-08/Q-09.

## Explicitly not changed

- Không sửa Kho, Công nợ, Kế toán hay miền Định giá bán.
- Không đóng Q-03/Q-06/Q-07/Q-10.
- Không phát hành API/event schema.
- Không phát hành permission matrix.
- Không thêm UI behavior hoặc prototype.

## Cross-theme outbound pending

1. Kho → Mua hàng: kết quả nhận có source/version/reversal.
2. Mua hàng → Kho: lợi ích dự kiến theo program/version/scenario/allocation.
3. Mua hàng → Công nợ: nguồn nghĩa vụ tại mốc hóa đơn đủ điều kiện.
4. Kho → Mua hàng → Công nợ/Kế toán: trả NCC tách vật lý và thương mại.
