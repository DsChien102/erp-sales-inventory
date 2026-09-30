---
id: PAT-NAV
type: design-pattern
theme: theme-07
title: "Điều hướng và cấu trúc thông tin"
owner: BA
status: FROZEN
source_baseline: v4.6.7
---
# PAT-NAV — Điều hướng và cấu trúc thông tin

## 1. Mục đích

`PAT-NAV` là tài liệu quy định cách tổ chức và điều hướng trong Theme 7.

Tài liệu này xác định:

- Theme 7 được chia thành những khu vực nào trên giao diện;
- chức năng nào được đưa lên màn Kho, chức năng nào chỉ xuất hiện khi đúng ngữ cảnh, khi có ngoại lệ hoặc khi thiết lập;
- mỗi mục điều hướng mở tới màn hình và luồng nghiệp vụ nào;
- vai trò và quyền truy cập có thể làm giao diện gọn hơn như thế nào mà không làm thay đổi nghiệp vụ;
- cách truy vết từ màn điều hướng tới màn nghiệp vụ → UIF → BJ/UC tương ứng.

`PAT-NAV` không định nghĩa quy tắc nghiệp vụ mới, không định nghĩa vòng đời trạng thái mới và không cấp thêm quyền cho người dùng.

## 2. Ranh giới và thẩm quyền

### 2.1 Tuyến nghiệp vụ

```text
Quyết định / Hợp đồng nghiệp vụ
        ↓
BJ
        ↓
UC
        ↓
UIF
        ↓
Màn nghiệp vụ
```

Tuyến này quyết định nghiệp vụ phải làm gì, ai thực hiện, điều kiện nào áp dụng và kết quả là gì.

### 2.2 Tuyến điều hướng

```text
PAT-UI-UX
    ↓
PAT-NAV
    ↓
Màn điều hướng
    ↓
Màn vào nghiệp vụ
    ↓
UIF / BJ / UC
```

Tuyến này chỉ quyết định người dùng đi tới nghiệp vụ bằng cách nào.

Màn điều hướng không sở hữu nghiệp vụ phía sau. Khi người dùng mở một nghiệp vụ, thẩm quyền chuyển về màn nghiệp vụ, UIF, BJ và UC của nghiệp vụ đó.

### 2.3 Quy tắc bắt buộc

- Không tạo BJ, UC hoặc UIF chỉ để mô tả việc mở menu hoặc chuyển giữa các khu vực.
- Một thao tác chỉ điều hướng không được ghi như thao tác thay đổi dữ liệu nghiệp vụ.
- Màn điều hướng không tạo ra kết quả cuối của nghiệp vụ.
- Chức năng đã được xác định là `CONTEXTUAL_ONLY`, `EXCEPTION_ONLY` hoặc `SETUP_ONLY` không được đưa thành menu chính chỉ vì đã có mã Screen.
- Quyền truy cập có thể làm một mục bị ẩn hoặc xuất hiện ít nổi bật hơn. Quyền truy cập không được làm thay đổi ý nghĩa nghiệp vụ của chức năng đó.
- Cấu trúc cơ sở phải dùng được khi một Chủ cửa hàng có toàn quyền và tự làm toàn bộ công việc kho. Vai trò và quyền truy cập chỉ là lớp tinh chỉnh thêm.

### 2.4 Lý do thiết kế

Các nguyên tắc dưới đây giải thích vì sao Theme 7 được tổ chức theo cấu trúc hiện tại. Đây là nguyên tắc thiết kế giao diện, không phải quy tắc nghiệp vụ.

1. **Thiết kế cho trường hợp một người làm toàn bộ công việc kho trước.** Theme 7 phải dễ dùng ngay cả khi cửa hàng chỉ có Chủ cửa hàng và người này tự làm mọi việc. Không dùng vai trò để che một cấu trúc vốn đã quá phức tạp.
2. **BJ không phải menu.** Mười bảy BJ dùng để mô tả nghiệp vụ. Người dùng không cần nhìn thấy mười bảy BJ như mười bảy mục trên màn hình.
3. **Điều hướng theo mục đích công việc.** Người dùng cần biết mình đang muốn xem tồn, nhập hoặc xuất hàng, kiểm kê và xử lý sai lệch, quản lý giá trị kho hay xem báo cáo. Giao diện phải bám theo các nhu cầu này.
4. **Tra cứu là nhu cầu riêng.** Người dùng thường chỉ muốn biết một sản phẩm còn bao nhiêu mà không bắt đầu một quy trình nghiệp vụ. Vì vậy Tìm kiếm và `Tra cứu tồn` được ưu tiên trên màn Kho.
5. **Thao tác nhanh không phải danh mục chức năng.** Chỉ những việc thường xuyên, dễ hiểu và cần vào nhanh mới được đặt ở đầu màn Kho.
6. **Ưu tiên thao tác đúng ngữ cảnh.** Chức năng chỉ có ý nghĩa với một hàng hóa, chứng từ hoặc trạng thái cụ thể phải được mở từ đúng nơi đó. Không đưa tất cả thành menu thường trực.
7. **`Cần chú ý` chỉ dùng cho việc thật sự cần người dùng quan tâm.** Không đưa mọi công việc đang mở vào khu vực này. Công việc bình thường vẫn nằm trong khu vực nghiệp vụ tương ứng.
8. **Vai trò chỉ giúp giao diện tập trung hơn.** Vai trò có thể thay đổi thao tác nhanh, thứ tự các khu vực và nội dung cần nhìn thấy trước. Vai trò không tạo ra một cấu trúc Kho khác.
9. **Quyền, trách nhiệm và mức độ nổi bật trên giao diện là ba việc khác nhau.** Có quyền sử dụng một chức năng không có nghĩa chức năng đó phải nằm ở vị trí nổi bật. Một chức năng bị ẩn khỏi màn Kho cũng không đồng nghĩa người dùng bị mất quyền.
10. **Không đưa lý do thiết kế vào giao diện sản phẩm.** Các câu giải thích vì sao một chức năng được xếp ở đâu thuộc tài liệu thiết kế. Giao diện chỉ giữ nội dung người dùng cần để hiểu và thực hiện công việc.

## 3. Phân loại màn hình và điểm vào

### 3.1 Loại màn hình

| Mã loại | Dùng cho | Truy vết bắt buộc |
|---|---|---|
| `BUSINESS` | Màn hình thực hiện hoặc xem một nghiệp vụ | BJ/UC và UIF khi màn thuộc một luồng |
| `NAVIGATION` | Màn hình tổ chức các nhóm chức năng và dẫn người dùng tới màn nghiệp vụ | `PAT-NAV`, màn cha và bảng đích đến |
| `OVERLAY` | Lớp hiển thị phụ thuộc màn cha | Màn/UC nguồn |
| `RESULT` | Màn hình thể hiện kết quả của nghiệp vụ | UC/UIF nguồn |
| `SYSTEM` | Màn hình xử lý tình trạng hệ thống hoặc phục hồi | Contract/UIF nguồn |

`SCR-090` đến `SCR-096` là các màn `NAVIGATION`.

### 3.2 Loại điểm vào

| Mã loại | Khi dùng |
|---|---|
| `QUICK_ACTION` | Việc thường xuyên, dễ hiểu và cần mở nhanh từ màn Kho |
| `WORKSPACE_ENTRY` | Mở một khu vực quản lý gồm nhiều chức năng có cùng mục đích |
| `MODULE_ENTRY` | Mở trực tiếp một màn nghiệp vụ hoặc danh sách công việc |
| `CONTEXTUAL_ONLY` | Chỉ xuất hiện khi người dùng đang ở đúng đối tượng, trạng thái hoặc chứng từ |
| `EXCEPTION_ONLY` | Chỉ xuất hiện khi có bất thường cần chú ý hoặc xác minh |
| `SETUP_ONLY` | Chỉ dùng khi thiết lập hoặc khởi tạo |
| `ACTOR_HANDOFF_TASK` | Công việc được chuyển cho vai trò khác; không phải menu dùng chung |
| `RESULT_ONLY` | Chỉ xuất hiện sau khi một nghiệp vụ đã chạy |
| `SYSTEM_RECOVERY` | Chỉ dùng khi cần xử lý hoặc phục hồi một kết quả chưa xác định |

## 4. Cấu trúc điều hướng chính thức

```text
Kho — SCR-090
│
├── Tìm kiếm / Thao tác nhanh
│   ├── Nhận hàng → SCR-006 / UIF-02
│   ├── Lấy hàng → SCR-025 / UIF-05
│   ├── Kiểm kê → SCR-042 / UIF-08
│   └── Tra cứu tồn → SCR-001 / UIF-01
│
├── Cần chú ý
│   ├── Lô sắp hết hạn → UIF-09 theo đúng sản phẩm/lô
│   ├── Sai lệch cần đối soát → SCR-078 / UIF-16
│   └── Nghiệp vụ chưa xác định kết quả → SCR-078 / UIF-17
│
├── Tồn kho — SCR-091
├── Nhập, xuất & hoàn trả — SCR-092
├── Kiểm kê & xử lý — SCR-093
├── Giá trị kho — SCR-094
├── Báo cáo & lịch sử — SCR-095
└── Thiết lập kho — SCR-096
```

Màn Kho không phải bảng tổng hợp toàn hệ thống và không phải danh sách 17 BJ.

## 5. Danh sách các màn điều hướng

| Mã màn hình | Tên | Loại | Màn cha | Mục đích |
|---|---|---|---|---|
| [`SCR-090`](../screens/SCR-090.md) | Kho | `NAVIGATION` | Điều hướng ứng dụng | Điểm vào chính của Theme 7 |
| [`SCR-091`](../screens/SCR-091.md) | Tồn kho | `NAVIGATION` | `SCR-090` | Tra cứu tồn và tình trạng hàng |
| [`SCR-092`](../screens/SCR-092.md) | Nhập, xuất & hoàn trả | `NAVIGATION` | `SCR-090` | Các nghiệp vụ đưa hàng vào, đưa hàng ra hoặc đưa hàng quay lại kho |
| [`SCR-093`](../screens/SCR-093.md) | Kiểm kê & xử lý | `NAVIGATION` | `SCR-090` | Kiểm kê, đối soát sai lệch và xử lý bất thường |
| [`SCR-094`](../screens/SCR-094.md) | Giá trị kho | `NAVIGATION` | `SCR-090` | Giá trị hàng nhập, chi phí mua bổ sung và giá vốn |
| [`SCR-095`](../screens/SCR-095.md) | Báo cáo & lịch sử | `NAVIGATION` | `SCR-090` | Báo cáo, thẻ kho và lịch sử biến động |
| [`SCR-096`](../screens/SCR-096.md) | Thiết lập kho | `NAVIGATION` | `SCR-090` | Các việc thiết lập hoặc khởi tạo ít dùng |

Các màn này không có BJ, UC hoặc UIF riêng.

## 6. Màn Kho — `SCR-090`

### 6.1 Tìm kiếm

Tìm kiếm được đặt ở vị trí ưu tiên vì người dùng thường cần trả lời nhanh câu hỏi: “Sản phẩm này còn bao nhiêu?”.

- Người dùng có thể nhập tên, mã hoặc quét mã vạch.
- Khi chọn kết quả, hệ thống mở `SCR-001` / `UIF-01`.
- Màn Kho không tạo một quy trình tìm kiếm riêng.

### 6.2 Thao tác nhanh

Bản cơ sở hiện có đúng bốn thao tác nhanh:

| Tên hiển thị | Loại điểm vào | Màn đích | Truy vết |
|---|---|---|---|
| Nhận hàng | `QUICK_ACTION` | `SCR-006` | `UIF-02` → BJ02 |
| Lấy hàng | `QUICK_ACTION` | `SCR-025` | `UIF-05` → BJ05 |
| Kiểm kê | `QUICK_ACTION` | `SCR-042` | `UIF-08` → BJ08 |
| Tra cứu tồn | `QUICK_ACTION` | `SCR-001` | `UIF-01` → BJ01 |

Không dùng tiêu đề “Làm nhanh”. Vị trí và cách trình bày của bốn nút đã đủ cho người dùng hiểu đây là các thao tác vào nhanh.

### 6.3 Cần chú ý

`Cần chú ý` chỉ hiển thị những việc bất thường hoặc cần người dùng xử lý.

Không dùng khu vực này như danh sách toàn bộ công việc đang mở.

| Nội dung | Loại điểm vào | Màn đích |
|---|---|---|
| Lô sắp hết hạn | `EXCEPTION_ONLY` | Mở theo đúng ngữ cảnh của `UIF-09` |
| Sai lệch cần đối soát | `EXCEPTION_ONLY` | `SCR-078` / `UIF-16` |
| Nghiệp vụ chưa xác định kết quả | `SYSTEM_RECOVERY` | `SCR-078` / `UIF-17` |

Nếu không có nội dung cần chú ý, toàn bộ khu vực này được phép không hiển thị.

## 7. Các khu vực quản lý và màn đích

### 7.1 `SCR-091` — Tồn kho

| Mục | Loại điểm vào | Màn đích | Truy vết |
|---|---|---|---|
| Tồn kho & khả dụng | `MODULE_ENTRY` | `SCR-001` | `UIF-01` → BJ01 |
| Tình trạng hàng | `MODULE_ENTRY` / tiếp tục theo ngữ cảnh | `SCR-036` hoặc màn phù hợp với ngữ cảnh | `UIF-09` → BJ09 |
| Chính sách tồn & cận hạn | `SETUP_ONLY` | `SCR-062` / `SCR-063` | Chức năng hỗ trợ |

### 7.2 `SCR-092` — Nhập, xuất & hoàn trả

| Mục | Loại điểm vào | Màn đích | Truy vết |
|---|---|---|---|
| Nhận hàng | `MODULE_ENTRY` | `SCR-006` | `UIF-02` → BJ02 |
| Lấy & bàn giao | `MODULE_ENTRY` | `SCR-025` | `UIF-05` → BJ05 |
| Hàng khách trả | `MODULE_ENTRY` | `SCR-030` | `UIF-06` → BJ06 |
| Trả nhà cung cấp | `MODULE_ENTRY` | `SCR-036` | `UIF-07` → BJ07 |

### 7.3 `SCR-093` — Kiểm kê & xử lý

| Mục | Loại điểm vào | Màn đích | Truy vết |
|---|---|---|---|
| Kiểm kê kho | `MODULE_ENTRY` | `SCR-042` | `UIF-08` → BJ08 |
| Hàng cần xử lý | `MODULE_ENTRY` / tiếp tục theo ngữ cảnh | `SCR-036` hoặc màn phù hợp với ngữ cảnh | `UIF-09` → BJ09 |
| Hủy & sửa sai nghiệp vụ | `MODULE_ENTRY` | `SCR-048` | `UIF-11` → BJ11 |
| Đối soát sai lệch | `MODULE_ENTRY` | `SCR-078` | `UIF-16` → BJ16 |

`Tiêu hủy` không có menu riêng. Chức năng này chỉ xuất hiện khi người dùng đang ở đúng hàng, lô và trạng thái cho phép, sau đó tiếp tục vào `UIF-10`.

`Phục hồi UNKNOWN` không có menu riêng. Chức năng này chỉ xuất hiện khi có nghiệp vụ chưa xác định kết quả và tiếp tục vào `UIF-17`.

### 7.4 `SCR-094` — Giá trị kho

| Mục | Loại điểm vào | Màn đích | Truy vết |
|---|---|---|---|
| Giá trị hàng nhập | `MODULE_ENTRY` | `SCR-014` | `UIF-03` → BJ03 |
| Chi phí mua bổ sung | `MODULE_ENTRY` | `SCR-085` | `UIF-13` → BJ13 |
| Giá vốn | `MODULE_ENTRY` | `SCR-072` | `UIF-14` → BJ14 |

### 7.5 `SCR-095` — Báo cáo & lịch sử

| Mục | Loại điểm vào | Màn đích | Truy vết |
|---|---|---|---|
| Báo cáo tồn & thẻ kho | `MODULE_ENTRY` | `SCR-054` | `UIF-15` → BJ15 |

Các màn chi tiết từ `SCR-055` đến `SCR-059` vẫn thuộc `UIF-15`. Không đưa các màn chi tiết này thành menu riêng trên màn Kho.

### 7.6 `SCR-096` — Thiết lập kho

| Mục | Loại điểm vào | Màn đích | Truy vết |
|---|---|---|---|
| Khởi tạo tồn đầu kỳ | `SETUP_ONLY` | `SCR-066` | `UIF-12` → BJ12 |
| Chính sách tồn & cận hạn | `SETUP_ONLY` | `SCR-062` / `SCR-063` | Chức năng hỗ trợ |

Thiết lập không được đặt ngang hàng với các việc người dùng thực hiện hằng ngày trên màn Kho.

## 8. Chức năng không được đưa thành menu chính

| Chức năng hoặc màn hình | Phân loại | Quy tắc |
|---|---|---|
| `SCR-021` — Giữ hàng theo đơn | `CONTEXTUAL_ONLY` | Mở từ đúng đơn bán; không mở từ màn Kho |
| `SCR-011` — Phê duyệt nhận hàng | `ACTOR_HANDOFF_TASK` | Mở từ công việc được giao cho người duyệt |
| `SCR-034` — Ngoại lệ lô cần duyệt | `ACTOR_HANDOFF_TASK` | Mở từ công việc được giao |
| `SCR-040` — Yêu cầu tiêu hủy | `CONTEXTUAL_ONLY` | Mở từ hàng hoặc lô có trạng thái phù hợp |
| `SCR-012`, `SCR-019`, `SCR-029`, `SCR-035`, `SCR-041`, `SCR-047`, `SCR-053`, `SCR-059`, `SCR-065`, `SCR-071`, `SCR-077`, `SCR-083`, `SCR-089` | `RESULT_ONLY` | Chỉ là màn kết quả; không phải điểm vào điều hướng |
| `SCR-013` | `SYSTEM_RECOVERY` | Chỉ mở khi kết quả nhận hàng là `UNKNOWN` |
| Các màn thuộc `UIF-17` | `SYSTEM_RECOVERY` | Chỉ mở từ nghiệp vụ chưa xác định kết quả, từ `Cần chú ý` hoặc từ đúng ngữ cảnh |

Màn đã ngừng dùng hoặc chỉ còn để phục vụ chuyển đổi phiên bản không được đưa trở lại menu chỉ vì vẫn còn mã Screen.

## 9. Quyền, trách nhiệm và hồ sơ điều hướng

Cấu trúc điều hướng cơ sở không phụ thuộc vai trò. Một Chủ cửa hàng có toàn quyền phải sử dụng được toàn bộ Theme 7 mà không cần cấu hình thêm.

### 9.1 Ba khái niệm phải tách riêng

| Khái niệm | Câu hỏi cần trả lời | Ảnh hưởng tới giao diện |
|---|---|---|
| **Quyền** | Người dùng có được phép xem hoặc thực hiện chức năng này không? | Có thể chặn hoặc ẩn mục điều hướng theo hợp đồng phân quyền |
| **Trách nhiệm** | Chức năng này có thuộc công việc thường xuyên của người dùng không? | Giúp xác định phần nào cần được ưu tiên; không tự tạo quyền |
| **Mức độ nổi bật** | Chức năng nên xuất hiện ở đâu và có cần đưa lên trước không? | Ảnh hưởng tới thao tác nhanh, thứ tự các khu vực và nội dung hiển thị trên màn Kho |

Không suy quyền từ hồ sơ điều hướng. Không suy trách nhiệm chỉ từ việc một mục đang được hiển thị.

### 9.2 Hồ sơ điều hướng đang mô phỏng

Hồ sơ điều hướng là cách trình bày khác nhau của `SCR-090 — Kho`. Hồ sơ chỉ thay đổi **thao tác nhanh, nội dung `Cần chú ý`, thứ tự các khu vực và phần được hiển thị trên màn Kho**.

Màn đích và luồng nghiệp vụ phía sau không thay đổi.

| Vai trò đang mô phỏng | Mã hồ sơ | Thao tác nhanh | `Cần chú ý` | Các khu vực theo thứ tự | `Thiết lập kho` |
|---|---|---|---|---|---|
| Chủ cửa hàng | `FULL` | Nhận hàng; Lấy hàng; Kiểm kê; Tra cứu tồn | Lô sắp hết hạn; Sai lệch cần đối soát; Nghiệp vụ chưa xác định kết quả | Tồn kho → Nhập, xuất & hoàn trả → Kiểm kê & xử lý → Giá trị kho → Báo cáo & lịch sử | Hiện |
| Thủ kho | `WAREHOUSE` | Nhận hàng; Lấy hàng; Kiểm kê; Xử lý hàng | Lô sắp hết hạn; Nghiệp vụ chưa xác định kết quả | Nhập, xuất & hoàn trả → Tồn kho → Kiểm kê & xử lý → Báo cáo & lịch sử | Ẩn |
| Kế toán | `ACCOUNTING` | Xác nhận giá; Chi phí mua; Giá vốn; Tra cứu tồn | Sai lệch cần đối soát | Giá trị kho → Báo cáo & lịch sử → Tồn kho → Kiểm kê & xử lý | Ẩn |
| Nhân viên bán hàng | `SALES` | Tra cứu tồn | Không hiển thị | Tồn kho | Ẩn |

Các hồ sơ này phản ánh phương án giao diện đang được mô phỏng trong bản mẫu HTML. Chúng không phải ma trận phân quyền.

Một mục bị ẩn khỏi một hồ sơ không có nghĩa người dùng bị cấm sử dụng chức năng đó.

### 9.3 Quy tắc áp dụng

1. `FULL` là cấu hình đầy đủ và hiện là cấu hình mặc định cho Chủ cửa hàng trong phương án đang thử nghiệm.
2. `WAREHOUSE`, `ACCOUNTING` và `SALES` chỉ giúp giảm nội dung không cần thiết và đưa công việc liên quan lên trước.
3. Hồ sơ điều hướng không đổi mã Screen, màn đích, UIF, BJ, UC, CTA, chuyển trạng thái hoặc thao tác thay đổi dữ liệu nghiệp vụ.
4. `Cần chú ý` và công việc được bàn giao chỉ hiển thị khi thật sự có dữ liệu phù hợp. Hồ sơ điều hướng không tự tạo thêm công việc.
5. Hiện chưa có quy tắc gộp nhiều hồ sơ điều hướng. Prototype chỉ mô phỏng một hồ sơ tại một thời điểm. Nếu sau này một người kiêm nhiều trách nhiệm, quy tắc kết hợp phải được quyết định riêng.
6. Khi VET45 có phân quyền thật, quyền truy cập có thể tiếp tục làm một mục bị ẩn hoặc chặn thao tác. Hồ sơ điều hướng không thay thế hợp đồng phân quyền.

### 9.4 Quan hệ với mô phỏng vai trò theo BJ/UIF

Hồ sơ điều hướng của màn Kho và mô phỏng vai trò trong tab Theo BJ/UIF phục vụ hai mục đích khác nhau:

- Hồ sơ điều hướng trả lời: **Màn Kho nên ưu tiên phần công việc nào cho người đang sử dụng?**
- Mô phỏng vai trò theo BJ/UIF trả lời: **Ở bước hiện tại của một hành trình, vai trò nào đang thực hiện hoặc nhận bàn giao công việc?**

Không dùng hồ sơ điều hướng để thay đổi vai trò trong BJ. Không dùng vai trò ghi trong hợp đồng màn hình để tự suy ra hồ sơ điều hướng.

## 10. Chuyển từ cấu trúc cũ sang cấu trúc hiện tại

Các nhóm `NAV-01` đến `NAV-06` của bản trước không còn là cấu trúc điều hướng chính thức. Các mã này chỉ được giữ để truy vết và đối chiếu khi chuyển phiên bản.

| Nhóm cũ | Cấu trúc hiện tại |
|---|---|
| `NAV-01` — Tổng quan tồn kho và chỉ báo | `SCR-091` — Tồn kho + Tìm kiếm/`Cần chú ý` ở `SCR-090` |
| `NAV-02` — Tác nghiệp kho | `SCR-092` — Nhập, xuất & hoàn trả; một phần `SCR-093` |
| `NAV-03` — Kiểm soát và phục hồi | `SCR-093` — Kiểm kê & xử lý + các điểm vào theo ngoại lệ hoặc ngữ cảnh |
| `NAV-04` — Giá trị và giá vốn | `SCR-094` — Giá trị kho |
| `NAV-05` — Báo cáo và truy vết | `SCR-095` — Báo cáo & lịch sử |
| `NAV-06` — Thiết lập và khởi tạo | `SCR-096` — Thiết lập kho |

Việc chuyển cấu trúc điều hướng này không làm thay đổi BJ, UC hoặc UIF.

## 11. Quy tắc truy vết cho màn điều hướng

Mỗi màn `NAVIGATION` bắt buộc phải có:

- `screen_class: NAVIGATION`;
- `authority: PAT-NAV`;
- màn điều hướng cha;
- bảng các mục và màn đích;
- quy tắc hiển thị và quyền truy cập;
- hành vi khi quay lại;
- các trạng thái có ý nghĩa với màn điều hướng.

Không bắt buộc và không được tạo giả:

- BJ riêng cho màn điều hướng;
- UC riêng cho màn điều hướng;
- UIF riêng cho màn điều hướng;
- hợp đồng thay đổi dữ liệu nếu thao tác chỉ dùng để chuyển màn hình.

Truy vết của từng mục kết thúc tại màn nghiệp vụ được mở. Ví dụ:

```text
SCR-094 — Giá trị kho
  → Giá trị hàng nhập
  → SCR-014
  → UIF-03
  → BJ03 / UC-03-01
```

## 12. Áp dụng Hệ thống thiết kế

Ưu tiên dùng lại thành phần đã có trong `design-system-profile.md`:

- `VPageScaffold` + `VAppBar` cho khung màn hình;
- `VSearchBar` cho Tìm kiếm;
- `VQuickActionButton` cho bốn thao tác nhanh trên màn Kho;
- `DS v2 / List Row` cho các mục dẫn tới khu vực hoặc chức năng khác;
- `VSection` để chia nhóm nội dung;
- `VBadge` chỉ dùng khi thật sự có trạng thái hoặc nội dung cần chú ý; không dùng như nhãn trang trí;
- không tạo thẻ điều hướng riêng cho Theme 7 nếu các thành phần hiện có đã đủ để ghép thành giao diện cần thiết.

Màn điều hướng phải dùng cùng quy tắc khoảng cách, kiểu chữ và cách viết câu thông thường như các màn khác của VET45.
