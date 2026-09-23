# Source Register — Theme 10 Mua hàng

| ID | Nguồn | Version/ngày | Authority | Phạm vi dùng | Giới hạn |
|---|---|---|---|---|---|
| SRC-01 | Xác nhận trực tiếp của Business Owner trong phiên 23/09/2026 | 2026-09-23 | Cao nhất cho yêu cầu hiện tại | Dựng baseline chính thức đầu tiên; cho phép tự đề xuất nhưng phải `NOT_FROZEN`; yêu cầu ngôn ngữ Việt thân thiện/chuyên môn | Không tự biến đề xuất thành quyết định đã khóa |
| SRC-02 | `Hand-off-02-Tiep-tuc-Theme10.md` | 2026-09-23 | Canonical hand-off v0.1.1 | Scope, 5 BJ, D-01–D-10, Q-01–Q-10, A-01–A-04, version chain | Không đóng các câu hỏi mở |
| SRC-03 | `Theme10-review-01.md` | 2026-09-23 | Hồ sơ lập luận đã đồng bộ v0.1.1 | Ranh giới liên miền, ví dụ chiết khấu, handoff, nguồn đối chiếu Theme 6/7 | Không phải hợp đồng tính cuối cùng |
| SRC-04 | `Hand-off-01-Theme7-tich-hop-Theme10.md` | 2026-09-23 | Outbound requirement | Yêu cầu Kho → Mua hàng và Mua hàng → Kho, quy tắc dự báo không ghi sổ | Theme 7 chưa xác nhận đã tích hợp |
| SRC-05 | Theme 6 `VET45-Cong-no-v2.1.3.zip` | nguồn đã đọc tại review 01 | Authority miền Công nợ tại thời điểm review | Ranh giới nghĩa vụ/số dư phải trả, nguồn nghĩa vụ, Kế toán | Cần đối chiếu lại nếu Theme 6 có parent mới hơn |
| SRC-06 | Theme 7 Harness/Prototype `v3.10.1` | nguồn đã đọc tại review 01 | Authority miền Kho/Giá vốn tại thời điểm review | Nhận thực tế, tồn/lô, giá trị kho, mô phỏng giá dự kiến, trả hàng vật lý | Không mặc định là parent Theme 7 mới nhất |
| SRC-07 | Baseline Theme 10 `v0.1.1` | freeze `T10-SCOPE-2026-09-23-01` | Parent semantic | Nguồn cấp phạm vi trực tiếp | ZIP không materialize trong runtime; checksum từ hand-off |

## Checksum/định danh nguồn

- `v0.1.1`: `2b76f6f78dee1d9e075cdb86f9c53707e0b23fd3f2271df2a8e62cc9b3223570`
- Theme 6 v2.1.3 tại lần review: `3f376f9910697082b79a31cde0e291ab9a364c8976ba4ba87cfd5e754be48b72`
- Theme 7 Harness v3.10.1 template-aligned tại lần review: `376296fd20e81fe06b25d5d74fe4e2252a7f78e6a663f4f2542a9cba9b40cdb6`
- Theme 7 Prototype v3.10.1 tại lần review: `1e85def14fae12443992bac3bc2affd309ede055d44047ae36b47781ecf47523`

## Quy tắc authority

1. Xác nhận trực tiếp mới nhất của Business Owner.
2. Decision đã xác nhận trong baseline Theme 10.
3. Contract/freeze của miền nguồn tương ứng.
4. Specification Theme 10.
5. Design/Architecture/Prototype dẫn xuất.
6. Wiki/Glossary dùng để giải thích, không tự tạo behavior.
