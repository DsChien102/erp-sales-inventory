# Harness — semantic component và UI trace overlay v4.3.0

Các catalog contract/test/fixture của Harness v4.1.0 được giữ nguyên vì package v4.3.0 **không thay đổi nghiệp vụ**. Validator tiền nhiệm tiếp tục đạt `14 PASS / 1 BLOCKED`.

- `trace-index.json` và `srs-inventory.json`: bằng chứng tiền nhiệm, còn alias Screen Group cũ.
- [`ui-trace-overlay-v4.3.0.json`](ui-trace-overlay-v4.3.0.json): trace hiện hành `BJ/UC → SCR-001…SCR-083 → contract → test`.
- [`../prototype/contracts/ui-traceability.json`](../../../../09.generated/matrices/design/ui-traceability.json): nguồn trace UI hiện hành.
- Prototype v4.1.0 được carry-forward nguyên trạng; `prototype_status=NOT_RENDERED` trong overlay nghĩa là Screen Registry/UI flow v4.2.0-rc1 chưa được render lại vào prototype.
- Repository execution vẫn `BLOCKED_BY_REPO_ADAPTER`.

Không dùng alias Screen Group trong Harness tiền nhiệm để tạo scope UI mới.
