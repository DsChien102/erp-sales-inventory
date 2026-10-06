# Open Question Register

| ID | Câu hỏi | Vì sao chặn | Hướng đề xuất hiện tại | Owner cần chốt |
|---|---|---|---|---|
| OQ-01 | Theme 09 có sở hữu toàn vòng đời kê khai/nộp thuế không? | Quyết định domain Tax Compliance | Sở hữu chuẩn bị/tờ khai; submission deferred | Product |
| OQ-02 | Phase 1 chỉ TT152 hay thêm TT58/2026? | Quy mô entity/rule/sổ | TT152 trước | Product |
| OQ-03 | Có expose Nợ/Có ở UI Phase 1 không? | Tác động UX và entity field bắt buộc | Ẩn mặc định; chỉ expert/regime cần | Product/Accounting |
| OQ-04 | Có manual journal ngay Phase 1 không? | Permission, audit, risk | Có, nhưng giới hạn và bắt buộc lý do/evidence | Product/Accounting |
| OQ-05 | Manual journal có cần approval? | Segregation of duties | Deferred hoặc cấu hình theo quyền | Product/Security |
| OQ-06 | Late event vào kỳ khóa xử lý mặc định thế nào? | Period correctness | Không back-post; ghi kỳ mở gần nhất + giữ ngày gốc, trừ khi mở lại kỳ | Accounting |
| OQ-07 | Có cần soft close? | UX vận hành cuối kỳ | Không trong MVP | Accounting/Product |
| OQ-08 | Doanh thu kế toán lấy từ SalesOrder hay invoice? | Tránh double count/mismatch | Source transaction quyết định recognition; invoice là evidence/tax input | Accounting/Tax |
| OQ-09 | Tax form catalog cụ thể 2026 gồm những mẫu nào cho từng nhóm HKD? | Không được hard-code sai form | Tạo catalog versioned sau legal mapping riêng | Tax SME |
| OQ-10 | Dimension tối thiểu Phase 1 gồm gì? | Ảnh hưởng reporting/query | Store, partner, source document; product/channel optional | Product/Accounting |
| OQ-11 | Closing checklist gồm điều kiện bắt buộc nào? | Khóa kỳ | Không pending critical posting/reconciliation | Accounting |
| OQ-12 | Retention policy từng class dữ liệu? | Compliance/storage | Policy versioned; không hard-code một số năm cho mọi artifact | Legal/Security |
| OQ-13 | Có cần quản lý số dư đầu kỳ trong Theme 09? | Migration/onboarding | Có accounting opening position, nhưng không chiếm subledger opening của Theme 6/7 | Product/Accounting |
| OQ-14 | Tax liability authoritative nằm Theme 09 hay một Tax subdomain khác? | Boundary | Theme 09 hiện giữ Tax Compliance | Product |
| OQ-15 | Các báo cáo P&L/financial statement thuộc Theme 09 hay Theme Báo cáo? | Consumer boundary | Theme 09 sở hữu accounting read model; presentation cross-domain có thể downstream | Product |
| OQ-16 | Reopen kỳ cần cấp duyệt hay chỉ permission + reason? | Audit/risk | Permission đặc quyền + reason; approval để future | Product/Security |
