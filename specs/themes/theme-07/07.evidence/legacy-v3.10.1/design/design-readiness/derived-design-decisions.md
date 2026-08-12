# Derived Design Decisions — DR1

> Chỉ ghi các quyết định có thể dẫn xuất chắc chắn; không thay thế business decision còn mở.

## DD-DR-01 — Flutter DS là nguồn giao diện duy nhất

HTML không có token/component authority riêng. Module Theme 7 compose public Flutter DS và chỉ tạo business chrome ở module presentation.

## DD-DR-02 — Action lineage không đồng nghĩa CTA hiện hữu

Action ID trên result/detail có thể chỉ giải thích lineage. Chỉ `visible_action_ids` từ outgoing flow transition mới được render thành CTA; `trace_only_action_ids` không được lặp mutation.

## DD-DR-03 — State không tự tạo Screen

Loading, validation, conflict, locked, permission, unknown và result variants ở cùng user task là state của canonical Screen. Chỉ split khi user task/actor/lifecycle/mental context thay đổi.

## DD-DR-04 — Shared Screen phải có context mode

Screen dùng bởi nhiều BJ phải nhận explicit `operation_type`/context, object identity, allowed-next-actions và copy/anatomy theo mode; không suy mode từ route name.

## DD-DR-05 — CAP-01 giữ ngoài 17 BJ

Bốn policy screen thuộc supporting capability; cần supporting UI flow riêng, không gán giả vào BJ-01/BJ-04.

## DD-DR-06 — UNKNOWN giữ operation identity

Mọi retry/query/recovery giữ cùng operation/idempotency identity; UI không tạo action blind retry bằng identity mới.

## DD-DR-07 — Task queue phân biệt actionable và waiting

Một row trong khu vực `Cần xử lý` phải có action thực sự thuộc actor hiện tại. Trạng thái đang chờ source/hệ thống/actor khác phải được tách bằng filter/group nhẹ, không giả làm task hiện hành.

## DD-DR-08 — Product+UOM có thể chứa nhiều LOT allocations

UI operational không được giả định một Product chỉ có một LOT. Khi domain cho phép nhiều allocation lines, user xử lý Product+UOM và nhìn/nhập từng LOT allocation bên trong.

## DD-DR-09 — Stale phải phục hồi cả digital state và physical task

Nếu stale có thể xảy ra sau khi user đã cầm/chuẩn bị hàng, recovery copy phải nêu rõ vật lý cần đổi gì. Một generic refresh success không đủ.

## DD-DR-10 — Event không thay lifecycle state

`Đã cập nhật`, `vừa thay đổi`, `đã đồng bộ` là event/supporting information. Chúng không được thay thế lifecycle label authoritative như `Chờ bàn giao`, `Cần phân loại`, `Đang chờ duyệt`.
