# VET45 Theme 10 — Mua hàng

**Package:** `VET45-Theme10-Mua-hang-v0.2.0`  
**Ngày:** 23/09/2026  
**Trạng thái package:** `OFFICIAL_BASELINE_SNAPSHOT / IN_REVIEW / NOT_FROZEN`  
**Parent semantic:** `v0.1.1` — freeze phạm vi `T10-SCOPE-2026-09-23-01`

## Mục đích

Đây là baseline đầu tiên của Theme 10 được mở rộng đủ để một BA/Product/Stakeholder có thể hình dung **bức tranh đích của miền Mua hàng**, trước khi đi vào Trường hợp sử dụng, UI Flow và hợp đồng kỹ thuật.

Package kế thừa phạm vi, quyền sở hữu và 5 Business Journey đã đồng ý ở `v0.1.1`, đồng thời bổ sung:

- toàn bộ lớp **Knowledge**: Decision Register, Glossary, Know-how;
- lớp **Specification**: Overview, Domain Foundation, semantic Aggregate model và Entity catalog;
- các đề xuất tự quyết để hoàn thiện bức tranh được ghi rõ là `PROPOSED / UNFROZEN`, không được hiểu là quyết định đã khóa.

## Cách đọc

1. `VERSION.md` — phiên bản, parent, semantic delta và giới hạn kiểm định.
2. `00.governance/` — nguồn, scope, câu hỏi mở, giả định và impact set.
3. `01.knowledge/decisions/decision-register.md` — quyết định đã kế thừa và quyết định đề xuất mới.
4. `01.knowledge/glossary/glossary.md` — ngôn ngữ chuẩn của miền Mua hàng.
5. `01.knowledge/know-how/` — các bài giải thích theo câu hỏi thực tế.
6. `02.specification/overview/overview.md` — bức tranh nghiệp vụ toàn Theme.
7. `02.specification/domain/` — domain model, aggregate và entity.
8. `02.specification/behavior/00-business-journey-map.md` — danh mục 5 BJ đã đồng ý; chưa phải UC chi tiết.

## Ranh giới của baseline này

**Có:** nghiệp vụ Mua hàng ở mức semantic; ownership; chứng từ mua; theo dõi giao; hóa đơn NCC; trả NCC; chương trình chiết khấu; tiến độ/dự báo; ranh giới Kho/Công nợ/Kế toán/Định giá.

**Chưa có:** Trường hợp sử dụng chi tiết; behavioral contracts dùng chung; permission matrix cuối; API/event/error/idempotency/NFR; UI Flow/Screen/Component contracts; prototype; quiz; presentation.

Các phần chưa có không được suy ra từ aggregate/entity trong package này.

## Quy ước ngôn ngữ

- Narrative và tên nghiệp vụ ưu tiên **thuật ngữ Việt, ngắn, dễ hiểu**.
- English chỉ dùng khi cần mã kỹ thuật, class/entity ID hoặc mapping tích hợp.
- Không gọi một khái niệm bằng số Theme nếu tên miền nghiệp vụ đủ rõ, ví dụ dùng **Kho**, **Công nợ**, **Kế toán**, **Định giá bán**.
- Dùng **Nhà cung cấp (NCC)** trong nội dung người dùng/BA; `Supplier` chỉ dùng ở mã kỹ thuật.
- Dùng **Đơn mua**, không dùng “PO” trong narrative trừ khi giải thích mapping kỹ thuật.
- Dùng **chương trình chiết khấu mua hàng**, **tiến độ**, **dự báo mức đạt**, **lợi ích thương mại dự kiến**; không dùng các từ tiếng Anh như rebate/forecast trong UI copy.

## Nguyên tắc an toàn semantic

- Đặt mua không làm tăng tồn.
- Nhận hàng thực tế do Kho sở hữu; Mua hàng chỉ tiêu thụ kết quả có nguồn.
- Tải tệp hóa đơn không tự tạo nghĩa vụ phải trả.
- Bàn giao hàng trả khỏi kho không tự chứng minh NCC đã giảm số tiền phải trả.
- Dữ liệu dự báo không được ghi thành quyền lợi thực tế, công nợ, giá trị kho hoặc giá vốn chính thức.
- Mọi dữ liệu dự kiến phải có phiên bản, thời điểm và giả định.

## Lưu ý về parent

Tại lượt dựng package này, ZIP `v0.1.1` không được materialize trong runtime. Parent, checksum và semantic được xác định từ hand-off canonical và hồ sơ review đã đồng bộ với `v0.1.1`. Vì vậy package này **không tuyên bố byte-preserve/diff tuyệt đối với parent**; chỉ tuyên bố semantic carry-forward theo bằng chứng hiện có. Đây là một trong các lý do package vẫn `NOT_FROZEN`.
