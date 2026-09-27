# Sổ theo dõi quyết định — BJ-AUD-D01…D17

> **Baseline Quyết định nghiệp vụ:** `T7-BASELINE-FREEZE-v4.0.0`  
> **Quy tắc thẩm quyền:** mọi locator dưới đây phải đọc cùng freeze ID; không tạo alias cho 207 ID tiền nhiệm.  
> **Kết luận:** D01–D16 đã có neo phù hợp trong v4.0.0; D17 là policy outbound của Theme 2 và còn receiver gate.

| Audit ID | Mức khớp v4 | Locator v4.0.0 | Target | Diễn giải |
|---|---|---|---|---|
| BJ-AUD-D01 | `ALIGNED_BOUNDARY` | `T7-DR-002`, `T7-DR-003`, `T7-DR-029#REQ-01`, `T7-DR-033`, `T7-DR-070` | `XREF-01`, `T5-BJ-CHECKOUT-POS`, `BJ-05/UC-05-05` | Việc chuyển Journey là quyết định migration; các locator v4 khóa phần Theme 7 giữ lại là hợp đồng Inventory Operation, kiểm tra/xuất nguyên tử và mốc thay đổi lượng. |
| BJ-AUD-D02 | `ALIGNED` | `T7-DR-002`, `T7-DR-003`, `T7-DR-030`, `T7-DR-031`, `T7-DR-032` | `BJ-05` | Inventory Operations sở hữu phân bổ, lấy/bàn giao và xử lý lượng giữ; Sales giữ quyết định promise/shortage ngoài ranh giới Theme 7. |
| BJ-AUD-D03 | `ALIGNED` | `T7-DR-002`, `T7-DR-003`, `T7-DR-040`, `T7-DR-041`, `T7-DR-042`, `T7-DR-043`, `T7-DR-044`, `T7-DR-045` | `BJ-06`, `BJ-07` | Theme 7 sở hữu inventory execution của hàng khách trả và trả nhà cung cấp; commercial intent tiếp tục do nguồn chịu trách nhiệm. |
| BJ-AUD-D04 | `ALIGNED_BOUNDARY` | `T7-DR-012`, `T7-DR-018`, `T7-DR-046`, `T7-DR-047`, `T7-DR-092` | `BJ-09` | Owner Inventory Control là quyết định migration; locator v4 khóa mô hình trạng thái, cận/hết hạn, tiêu hủy và hàng demo mà BJ-09 điều phối. |
| BJ-AUD-D05 | `ALIGNED_WITH_REFINEMENT` | `T7-DR-071`, `T7-DR-073`, `T7-DR-074`, `T7-DR-082` | `SHARED-FINALITY`, `BJ-01..BJ-17` | Bốn nhóm kết quả ở cấp Journey là phép chiếu trình bày; lifecycle Inventory Operation có thẩm quyền vẫn là T7-DR-074 và không bị thay bằng taxonomy rút gọn. |
| BJ-AUD-D06 | `ALIGNED` | `T7-DR-071`, `T7-DR-072`, `T7-DR-074#REQ-02`, `T7-DR-090#REQ-01` | `BJ-17`, `SHARED-FINALITY` | Query/continue chỉ dùng cùng operation/command identity; recovery kéo dài thuộc BJ-17 và không retry UNKNOWN bằng identity mới. |
| BJ-AUD-D07 | `ALIGNED` | `T7-DR-018`, `T7-DR-096`, `T7-DR-096#REQ-01`, `T7-DR-096#REQ-02` | `CAP-01` | Chính sách tồn/cận hạn là capability cấu hình có version; không phải Journey độc lập. |
| BJ-AUD-D08 | `ALIGNED` | `T7-DR-018`, `T7-DR-088`, `T7-DR-095`, `T7-DR-096` | `BJ-01` | Current monitoring và chỉ báo dẫn xuất được hợp nhất vào BJ-01; không tạo alert/proposal lifecycle mới. |
| BJ-AUD-D09 | `ALIGNED` | `T7-DR-084`, `T7-DR-085`, `T7-DR-085#REQ-01`, `T7-DR-087`, `T7-DR-091` | `BJ-15` | Báo cáo lịch sử/cut-off, thẻ kho và export giữ thành Journey riêng với một sequence/cut-off nhất quán. |
| BJ-AUD-D10 | `ALIGNED` | `T7-DR-071`, `T7-DR-086`, `T7-DR-088`, `T7-DR-090` | `BJ-16`, `BJ-17` | BJ-16 sở hữu Hồ sơ đối soát; BJ-17 sở hữu finality recovery của operation UNKNOWN. |
| BJ-AUD-D11 | `ALIGNED` | `T7-DR-084`, `T7-DR-084#REQ-02`, `T7-DR-086`, `T7-DR-090` | `PROC-01`, `BJ-16` | Dựng lại projection là procedure kỹ thuật từ ledger; BJ-16 điều phối qua hồ sơ đối soát. |
| BJ-AUD-D12 | `ALIGNED_BOUNDARY` | `T7-DR-002`, `T7-DR-098#REQ-01`, `T7-DR-099` | `XREF-02`, `T10-BJ-DISCOUNT-SCENARIO` | Kịch bản chiết khấu chuyển sang Theme 10 — Mua hàng; Theme 7 chỉ nhận dữ liệu ưu đãi đã phát sinh và hợp lệ cho định giá tồn. |
| BJ-AUD-D13 | `ALIGNED_BOUNDARY` | `T7-DR-002`, `T7-DR-098`, `T7-DR-100`, `T7-DR-100#REQ-01`, `T7-DR-100#REQ-02`, `T7-DR-100#REQ-03` | `XREF-03`, `T2-BJ-PRICING-BASIS` | Theme 7 cung cấp Official Cost; lựa chọn pricing basis, floor/list draft và công bố giá thuộc Theme 2. |
| BJ-AUD-D14 | `ALIGNED_BOUNDARY` | `T7-DR-076`, `T7-DR-098`, `T7-DR-100#REQ-03`, `T7-DR-101` | `XREF-04`, `T2-BJ-PRICING-REVIEW` | Review thuộc Theme 2; event chỉ mở review, không tự ghi đè pricing basis hoặc giá bán đang hiệu lực. |
| BJ-AUD-D15 | `ALIGNED_BOUNDARY` | `T7-DR-002`, `T7-DR-083`, `T7-DR-102` | `XREF-05`, `RPT-BJ-PROFIT-VIEWS` | Ba cách nhìn lợi nhuận chuyển Reporting/Management Analytics và giữ tách với báo cáo tồn của BJ-15. |
| BJ-AUD-D16 | `ALIGNED` | `T7-DR-049`, `T7-DR-050`, `T7-DR-052`, `T7-DR-053`, `T7-DR-098`, `T7-DR-102` | `BJ-14`, `XREF-02`, `XREF-03`, `XREF-04`, `XREF-05` | Theme 7 chỉ giữ Official Cost/COGS provider contracts; không sở hữu pricing UI, purchase scenario hay management reporting. |
| BJ-AUD-D17 | `EXTERNAL_POLICY_REQUIRES_RECEIVER_ADOPTION` | `T7-DR-098`, `T7-DR-100#REQ-02`, `T7-DR-101` | `T2-BJ-PRICING-BASIS`, `T2-BJ-PRICING-REVIEW` | V4.0.0 khóa provenance và quyền lựa chọn nguồn nhưng không quy định heuristic MAX hoặc override reason. Hai phần này là policy outbound đã duyệt ở BJ audit và chỉ có hiệu lực sau khi Theme 2 tiếp nhận/đóng băng. |

## Quy tắc sử dụng

- `ALIGNED`: nội dung audit được quyết định v4 bao phủ trực tiếp.
- `ALIGNED_BOUNDARY`: v4 khóa ranh giới/contract; thao tác MOVE/RECLASSIFY vẫn do gói migration BJ quyết định.
- `ALIGNED_WITH_REFINEMENT`: ý định được giữ nhưng thuật ngữ/lifecycle có thẩm quyền là mô hình chi tiết trong v4.
- `EXTERNAL_POLICY_REQUIRES_RECEIVER_ADOPTION`: không được tuyên bố là Quyết định nghiệp vụ Theme 7; chỉ có hiệu lực tại receiver sau khi tiếp nhận và đóng băng.
