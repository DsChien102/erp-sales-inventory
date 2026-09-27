---
id: UC-XX-XX
type: use-case
theme: <theme-xx>
title: <Tên Use Case>
owner: BA
status: DRAFT
---

# UC-XX-XX — <Tên Use Case>

<!--
Quy ước V5:
- UC mô tả một mục tiêu nghiệp vụ với các đường đi tới kết quả; không chứa endpoint,
  handler, cấu trúc lưu trữ, transaction hoặc chi tiết bố cục màn hình.
- Viết đủ bối cảnh để triển khai, tham chiếu BC/Domain/Entity thay vì chép lại nguồn.
- Step ID có phạm vi nội bộ UC: BF-01, BF-02; AF-A-01, AF-A-02; EF-A-01, EF-A-02.
  Không dùng dấu chấm hoặc thêm cấp cho bước BF. Khi tham chiếu từ ngoài phải kèm UC ID.
- Cột Ghi chú và tham chiếu chỉ ghi “Mã — Tên”; nhiều tham chiếu ngăn bằng thẻ br.
  Điều kiện và hành vi nằm trong nội dung luồng/quy tắc được tham chiếu.
- Mỗi bước có nhánh phải dẫn trực tiếp đến AF/EF tương ứng; AF/EF có điều kiện,
  điểm phát sinh và bước quay lại/kết thúc/chuyển UC rõ ràng.
- AF là luồng thay thế, gồm lỗi sửa được để tiếp tục đạt mục tiêu.
  EF là luồng ngoại lệ khiến UC không thể tiếp tục bình thường hoặc phải bàn giao.
-->

## 1. Mục tiêu và kết quả nghiệp vụ

<!-- Mục tiêu của tác nhân, kết quả quan sát được và giá trị của UC. -->

## 2. Bối cảnh và ranh giới

### 2.1 Bắt đầu khi

<Dữ kiện xác lập phạm vi bắt đầu của UC>.

### 2.2 Kết thúc và thời điểm ghi nhận kết quả

<Khi nào kết quả được hệ thống xác nhận; trạng thái nào còn chờ hoặc chưa xác định>.

### 2.3 Không bao gồm

<Công việc ngoài UC và UC/nơi tiếp nhận nếu có>.

## 3. Tác nhân, thẩm quyền và điều kiện trước

- **Tác nhân chính:** <...>.
- **Thẩm quyền:** <Quyền thực hiện và giới hạn quyết định>.
- **Sự kiện khởi phát:** <...>.
- **Điều kiện trước:** <Điều phải đúng để bắt đầu; tách khỏi dữ liệu sẽ được bổ sung trong luồng>.

## 4. Đối tượng và dữ liệu nghiệp vụ

| Đối tượng / Dữ liệu | Ý nghĩa và yêu cầu | Nguồn |
|---|---|---|
| <Tên> | <Dữ kiện tác nhân cung cấp hoặc hệ thống xác định> | <Domain/Entity/BC> |

## 5. Các luồng của Use Case

### 5.1 Luồng chính (Basic Flow)

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| BF-01 | <Tác nhân> | <Hành động đầu tiên> | |
| BF-02 | Hệ thống | <Kiểm tra điều kiện nghiệp vụ> | AF-A — <Tên luồng thay thế><br>EF-A — <Tên luồng ngoại lệ><br>BR-01 — <Tên quy tắc> |
| BF-03 | Hệ thống | <Xác nhận kết quả> | |
| BF-04 | — | [Tiếp tục tại UC-XX-YY]. | UC-XX-YY — <Tên UC tiếp nhận> |

<!-- Nếu không bàn giao, bước cuối ghi [Kết thúc UC] và bỏ tham chiếu UC tiếp nhận. -->

### 5.2 Luồng thay thế (Alternate Flow)

#### AF-A — <Tên luồng thay thế>

**Phát sinh tại:** BF-02. **Điều kiện:** <Điều kiện rẽ nhánh>.

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| AF-A-01 | <Tác nhân> | <Hành động thay thế hoặc bổ sung> | BR-01 — <Tên quy tắc> |
| AF-A-02 | — | [Trở lại BF-02]. | BF-02 — <Tên bước kiểm tra> |

### 5.3 Luồng ngoại lệ (Exception Flow)

#### EF-A — <Tên luồng ngoại lệ>

**Phát sinh tại:** BF-02. **Điều kiện:** <Điều kiện khiến luồng chính không thể tiếp tục>.

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| EF-A-01 | Hệ thống | <Thông báo kết quả và nêu tác động nghiệp vụ được giữ/không phát sinh> | |
| EF-A-02 | — | [Kết thúc UC]. | |

<!-- Nếu bàn giao sang UC khác, thay bước cuối bằng [Tiếp tục tại UC-XX-ZZ]
và ghi Mã — Tên của UC tiếp nhận trong cột tham chiếu. -->

## 6. Quy tắc nghiệp vụ và Behavioral Contract

| Mã | Tên quy tắc nội bộ | Nội dung | Căn cứ |
|---|---|---|---|
| BR-01 | <Tên ngắn> | <Quy tắc chỉ thuộc UC này> | <Decision/Domain/Entity> |

<!-- BC sở hữu quy tắc dùng chung. Chỉ liệt kê ID — Tên và liên kết nguồn, không chép nội dung BC. -->

- <BC-ID — Tên Behavioral Contract>.

## 7. Kết quả và điều kiện sau

| Trường hợp | Trạng thái / Ảnh hưởng nghiệp vụ | Hướng tiếp tục |
|---|---|---|
| Thành công | <Dữ kiện đã được ghi nhận> | <UC tiếp theo hoặc kết thúc> |
| Cần bổ sung / Bị từ chối | <Những gì giữ nguyên, không phát sinh> | <Sửa, dừng hoặc bàn giao> |
| Thất bại đã xác nhận | <Kết quả có thể khẳng định> | <Hướng xử lý> |
| Chưa xác định (`UNKNOWN`), nếu có | <Điều chưa thể kết luận; không suy ra thất bại> | <Cách làm rõ cùng yêu cầu, tránh tạo tác động trùng> |

## 8. Liên hệ giao diện

<!-- Chỉ nêu Screen ID và vai trò hỗ trợ UC. Bố cục/điều hướng chi tiết thuộc Screen Contract
và luồng giao diện cấp hành trình; không biến UC thành hướng dẫn thao tác từng nút. -->

| Screen | Vai trò trong UC |
|---|---|
| <SCR-ID — Tên> | <Thông tin/hành động cần hỗ trợ> |

## 9. Kịch bản nghiệm thu (Acceptance Scenarios)

<!-- Scenario kiểm chứng Flow, không thay thế Flow. Bao phủ các kết quả và nhánh AF/EF;
mỗi Scenario phải chỉ rõ BF/AF/EF/BR liên quan. Không lặp Journey Acceptance của BJ.
Slice có thể chọn một tập Flow/Scenario có giá trị và kiểm thử được; không mặc định
1 UC = 1 Slice. Slice ghi phạm vi bao phủ và phần còn lại, không tự đổi ranh giới nghiệp vụ. -->

### AS-UC-XX-XX-01 — <Tên kịch bản>

- **Bao phủ:** <BF-01 → BF-04; BR-01>.
- **Given:** <Bối cảnh và điều kiện>.
- **When:** <Hành vi cần kiểm chứng>.
- **Then:** <Kết quả quan sát được và tác động không được phát sinh>.

## 10. Truy vết

- **Journey:** <BJ-ID — Tên>.
- **Domain / Entity:** <ID — Tên>.
- **Decision / Nguồn:** <ID/link — Tên>.
