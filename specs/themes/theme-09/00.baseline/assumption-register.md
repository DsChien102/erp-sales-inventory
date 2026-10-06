# Assumption Register

| ID | Giả định | Căn cứ | Rủi ro nếu sai | Mất hiệu lực khi |
|---|---|---|---|---|
| A-01 | Phase 1 ưu tiên HKD/CKD thương mại tại Việt Nam | Product Vision + hướng sản phẩm hiện tại | Scope sổ/tax khác nếu ưu tiên doanh nghiệp | Product chốt persona khác |
| A-02 | Phase 1 chỉ ghi sổ VND | Phù hợp phạm vi MVP các Theme liên quan | Multi-currency làm đổi Money, FX, period close | Product yêu cầu ngoại tệ |
| A-03 | Theme 09 có capability thuế trong end-state | Product Vision và Theme 8 boundary lịch sử | Nếu tách Theme thuế riêng, domain phải phân lại | Có quyết định tách Theme |
| A-04 | Submission thuế điện tử chưa cần Phase 1 | Chưa có integration contract/eTax provider | Người dùng có thể vẫn phải nộp ngoài hệ thống | Product chốt tích hợp nộp thuế |
| A-05 | Sự thật nguồn có version/correlation đủ để idempotent | Mẫu tích hợp Theme 5/6/7/8 | Nếu source thiếu version cần adapter | Integration contract chốt khác |
| A-06 | Một Tenant có một hồ sơ kế toán hiệu lực tại một thời điểm | Đơn giản cho MVP | Multi-entity/branch statutory accounting có thể phá giả định | Product yêu cầu nhiều pháp nhân trong tenant |
| A-07 | Hạch toán dự báo không đi vào official ledger | Nguyên tắc source truth | Nếu cần management accrual/estimate, phải có ledger lớp khác | Product chốt management ledger riêng |
| A-08 | Người dùng phổ thông không cần thấy Nợ/Có nếu chế độ không yêu cầu | UX mục tiêu thân thiện | Kế toán chuyên nghiệp có thể cần chi tiết | Research/requirement yêu cầu |
