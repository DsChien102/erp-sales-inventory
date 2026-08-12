# CHANGELOG — v1.3.6

Parent: `v1.3.5` · Cumulative incremental release.

## BJ02 / UIF02
- `SCR-008`: bỏ helper copy `Không chọn ngày trước hôm nay.`.
- Date picker vẫn giữ minimum = ngày hiện tại; invalid date vẫn bị server/UI validation chặn.
- Không thay đổi các refinement BJ02 khác của v1.3.5.

## BJ05 / UIF05
- Queue phân biệt `Cần lấy` với `Đang chờ`; shortage/source-waiting không giả thành warehouse task.
- Product+UOM hỗ trợ `1..N` LOT allocations; override LOT áp dụng đúng allocation và cần lý do.
- Stale recovery nói rõ correction vật lý cần trả/lấy lại LOT nào.
- Handover review có customer context.
- Actual handover quantity nhập theo từng allocation/LOT; partial chỉ được dùng khi source cho phép và không vượt picked quantity.
- Physical/value chỉ giảm theo lượng thực bàn giao sau server recheck + actor confirmation.

## BJ06 / UIF06
- Return request hỗ trợ nhiều dòng và all-or-nothing receipt commit.
- Queue phân biệt actionable với waiting; `Cần phân loại` đi thẳng vào task classification.
- Wrong-LOT giữ maker-checker; maker cung cấp reason + ảnh nhãn LOT, approver xem evidence độc lập.
- Classification là overview nhiều line/LOT; tap line mở contextual editor với Bán được/Cách ly/Hỏng/Hết hạn.
- Tổng phân loại từng line phải bằng pending quantity; hàng hết hạn không thể chuyển Sellable.

## BJ07 / UIF07
- `SCR-037` trở thành physical preparation/verification cho source-authorized supplier return.
- User xác nhận đúng Product/quantity/LOT; scan là hỗ trợ, không bắt buộc Phase 1.
- Source change hiển thị delta before→after và reset verification bị ảnh hưởng.
- Lifecycle vẫn là `Chờ bàn giao`; `Yêu cầu vừa thay đổi` chỉ là supporting copy.
- `SCR-039` là final handover review riêng; không commercial reapproval lần hai.

## Cross-UIF / contracts
- Bổ sung guardrail: actionable-vs-waiting queue, Product+UOM→1..N LOT allocations, physical stale recovery, direct task re-entry, event≠lifecycle, source delta invalidates verification.
- Back-propagate vào BJ/UC, UIF flow, Screen Contract, Component Usage, Screen Registry và workbench metadata.
