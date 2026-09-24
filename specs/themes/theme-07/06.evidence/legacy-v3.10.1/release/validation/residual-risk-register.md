# Sổ rủi ro còn lại — Theme 7 v4.3.1

| ID | Khoảng trống bằng chứng | Tác động | Owner | Hành động gỡ chặn | Gate |
|---|---|---|---|---|---|
| `RR-430-01` | Prototype v4.1.0 chưa được nâng cấp theo UI flow v4.2.0-rc1 | UI hiện có thể lệch Screen Registry/flow hiện hành | BA/UX Lead | Duyệt UI flow/registry, nâng cấp prototype rồi chạy browser/accessibility E2E | Trước Flutter |
| `RR-430-02` | Link chỉ mới kiểm tra tĩnh | Có thể khác thuật toán heading của GitLab self-hosted | BA Lead | Mở link đại diện G01…G14 và Mermaid trên GitLab | Trước release docs |
| `RR-430-03` | Harness gốc còn alias SG | Có thể bị đọc nhầm làm UI model hiện hành | QA/Harness Lead | Dùng overlay v4.3.0; tái sinh full Harness khi prototype freeze | Trước TDD UI |
| `RR-430-04` | Repository/database chưa có | Chưa chứng minh implementation | Engineering Lead | Gắn repo adapter, chạy RED/GREEN và regression | Trước READY |
| `RR-430-05` | External BJ/outbound chưa được Theme đích tiếp nhận | Có thể còn ownership tạm thời | Product Architecture Lead | Theme 2/5/10 tiếp nhận và re-ID theo migration plan | Trước canonical cut-over liên Theme |
