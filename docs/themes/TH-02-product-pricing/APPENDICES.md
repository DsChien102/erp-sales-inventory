# TH-02 — Phụ lục

Nguồn: Theme 2 v3 (`theme_snapshot.md`) — flow catalog, user flows, state diagrams, integration, ERD, permissions.

| Phụ lục | Nội dung |
| ------- | -------- |
| A | Flow catalog (UXF-01..12) |
| B | User flows chi tiết |
| C | State diagrams (lifecycle, readiness, stock mode, …) |
| D | Integration diagrams (Inventory, Costing, Sales, …) |
| E | Entity relationship diagram |
| F | Permission matrix |

## Mục lục

Các phụ lục dưới đây là phần triển khai chi tiết cho các flow, sơ đồ trạng thái, sơ đồ tích hợp và ma trận quyền của Theme 2. Phần nội dung chính của Theme chỉ mô tả phạm vi, nguyên tắc và requirement; các sơ đồ hỗ trợ thiết kế/triển khai được đặt tại phụ lục để tài liệu chính không bị quá nặng.

## Phụ lục A — Flow catalog

Bảng này tổng hợp các flow cần thiết kế hoặc vẽ sơ đồ cho Theme 2. Flow catalog dùng để liên kết giữa Theme overview, Epic, FR và bản thiết kế UX/UI.

|Flow ID|Flow|Mục tiêu|Epic liên quan|Loại sơ đồ|Ưu tiên|
|---|---|---|---|---|---|
|UXF-01|Guided Product Creation|Dẫn người dùng tạo sản phẩm tối thiểu mà không bị rối bởi quá nhiều field|Epic 2.2|User flow|Must-have|
|UXF-02|Hoàn thiện readiness|Cho biết sản phẩm còn thiếu gì và điều hướng đến bước tiếp theo|Epic 2.1, 2.2|User flow|Must-have|
|UXF-03|Product Control Center|Điều phối dữ liệu và hành động theo trạng thái sản phẩm|Epic 2.1|User flow|Must-have|
|UXF-04|Quản lý đơn vị đo lường|Thêm, ngừng, sử dụng lại, xóa, đổi đơn vị cơ sở|Epic 2.4|User flow / State diagram|Must-have|
|UXF-05|Quản lý tồn kho cơ bản|Nhập/chỉnh tồn kho trực tiếp trong Product ở Foundation|Epic 2.5|User flow|Must-have|
|UXF-06|Xem tồn kho nâng cao|Đọc stock summary từ module Kho khi dùng Advanced stock|Epic 2.5|Integration flow|Should-have|
|UXF-07|Quản lý Giá cơ sở định giá thủ công|Nhập/chỉnh manual base price trong Foundation|Epic 2.6|User flow|Must-have|
|UXF-08|Xem Giá cơ sở từ module Giá vốn|Hiển thị base price read-only khi dùng Costing module|Epic 2.6|Integration flow|Should-have|
|UXF-09|Quản lý khung giá bán|Thiết lập Giá niêm yết, Giá sàn theo sản phẩm/đơn vị|Epic 2.6|User flow|Must-have|
|UXF-10|Quản lý custom fields|Nhập thông tin bổ sung theo custom field groups|Epic 2.3|User flow|Should-have|
|UXF-11|Ngừng kinh doanh / kinh doanh lại|Kiểm soát trạng thái sử dụng trong giao dịch mới|Epic 2.7|User flow / State diagram|Must-have|
|UXF-12|Xóa sản phẩm / khôi phục|Xóa mềm, bảo toàn dữ liệu lịch sử và khôi phục nếu đủ điều kiện|Epic 2.7|User flow / State diagram|Should-have|

Các flow được chia thành ba nhóm triển khai:

|Nhóm|Flow|Cách triển khai|
|---|---|---|
|Core UX flows|UXF-01, UXF-02, UXF-03, UXF-04, UXF-09|Cần vẽ kỹ theo từng bước người dùng, gồm main flow và alternative flow|
|Source-aware flows|UXF-05, UXF-06, UXF-07, UXF-08|Vẽ ở mức ranh giới dữ liệu: nhập trực tiếp trong Product hay đọc từ module khác|
|Lifecycle/control flows|UXF-11, UXF-12|Nên vẽ kết hợp user flow và state diagram|

---

## Phụ lục B — User flows

Phụ lục B mô tả các flow người dùng chính của Theme 2. Mỗi flow được viết ở mức đủ để BA, UX và Dev cùng hiểu: ai thực hiện, bắt đầu từ đâu, điều kiện trước là gì, đi qua các bước nào, có nhánh ngoại lệ nào và kết quả cuối là gì.

Các flow dưới đây tập trung vào hành vi người dùng. Các flow thiên về tích hợp hệ thống như **UXF-06 — Xem tồn kho nâng cao** và **UXF-08 — Xem Giá cơ sở từ module Giá vốn** sẽ được triển khai kỹ hơn ở **Phụ lục D — Integration diagrams**.

### UXF-01 — Guided Product Creation

**Mục tiêu:** Dẫn người dùng tạo sản phẩm tối thiểu mà không bị rối bởi quá nhiều field, sau đó chuyển sang readiness checklist để hoàn thiện dần.

**Actor:** Owner, Product Manager, Admin hoặc người dùng có quyền tạo sản phẩm.

**Trigger:** Người dùng chọn hành động “Tạo sản phẩm mới”.

**Preconditions:**

- Người dùng đã đăng nhập vào đúng tenant.

- Người dùng có quyền tạo sản phẩm.

- Tenant đã có cấu hình cơ bản về ngành, đơn vị, stock mode và base price mode nếu có.

- Hệ thống có thể kiểm tra trùng SKU/barcode trong tenant.

    

**Main flow:**

1. Người dùng mở danh sách sản phẩm.

2. Người dùng chọn “Tạo sản phẩm mới”.

3. Hệ thống mở flow tạo sản phẩm có hướng dẫn.

4. Người dùng nhập thông tin nhận diện tối thiểu.

5. Hệ thống kiểm tra tên sản phẩm, SKU và barcode nếu có.

6. Người dùng chọn hoặc tạo đơn vị cơ sở nếu thực hiện ngay.

7. Người dùng nhập tồn kho ban đầu nếu tenant dùng Basic stock và muốn nhập ngay.

8. Người dùng nhập Giá cơ sở định giá nếu tenant dùng Manual base price và muốn nhập ngay.

9. Người dùng thiết lập Giá niêm yết và Giá sàn nếu muốn hoàn thiện giá ngay.

10. Người dùng nhập custom fields nếu tenant có cấu hình và muốn nhập ngay.

11. Người dùng lưu sản phẩm.

12. Hệ thống tạo sản phẩm, tính readiness ban đầu và điều hướng sang Product Control Center hoặc màn kết quả.

    

**Alternative flows:**

- AF-01. Người dùng chỉ nhập tên sản phẩm, bỏ qua các bước khác → hệ thống vẫn tạo sản phẩm nếu chính sách cho phép và gắn readiness blocker.

- AF-02. SKU/barcode bị trùng → hệ thống không cho lưu và gợi ý mở sản phẩm đang dùng mã đó.

- AF-03. Người dùng thiếu quyền nhập giá hoặc tồn kho → hệ thống cho bỏ qua bước đó và ghi nhận blocker nếu cần.

- AF-04. Upload ảnh lỗi → hệ thống cho người dùng bỏ qua ảnh nếu dữ liệu bắt buộc khác hợp lệ.

- AF-05. Tenant dùng Advanced stock hoặc Costing-module base price → hệ thống không cho nhập trực tiếp tồn kho hoặc Giá cơ sở trong Product.

    

**Output:**

- Sản phẩm mới được tạo trong tenant hiện tại.

- Product, Product Image, Product Unit, Product Stock Profile, Product Base Price Profile và readiness được tạo hoặc cập nhật theo dữ liệu đã nhập.

- Product Change History ghi nhận sự kiện tạo sản phẩm.

- Người dùng được điều hướng sang bước hoàn thiện tiếp theo.

    ```mermaid
    flowchart TD
    A[Danh sách sản phẩm] --> B[Chọn Tạo sản phẩm mới]
    B --> C[Nhập thông tin nhận diện]
    C --> D{SKU/barcode hợp lệ?}
    D -- Không --> D1[Hiển thị lỗi trùng mã]
    D1 --> C
    D -- Có --> E[Thiết lập đơn vị cơ sở]
    E --> F{Nhập tồn kho cơ bản?}
    F -- Có, Basic stock --> G[Nhập tồn kho ban đầu]
    F -- Không / Không áp dụng --> H{Nhập Giá cơ sở định giá?}
    G --> H
    H -- Có, Manual base price --> I[Nhập Giá cơ sở định giá]
    H -- Không / Không áp dụng --> J{Thiết lập khung giá?}
    I --> J
    J -- Có --> K[Nhập Giá niêm yết và Giá sàn]
    J -- Không --> L[Nhập custom fields nếu có]
    K --> L
    L --> M[Lưu sản phẩm]
    M --> N[Tính readiness ban đầu]
    N --> O[Product Control Center]    ```

---

### UXF-02 — Hoàn thiện readiness

**Mục tiêu:** Cho biết sản phẩm còn thiếu gì và điều hướng người dùng đến hành động tiếp theo phù hợp.

**Actor:** Owner, Product Manager, Admin hoặc người dùng có quyền xử lý blocker tương ứng.

**Trigger:** Người dùng mở Product Control Center, màn kết quả sau tạo sản phẩm hoặc chạm vào readiness blocker trên danh sách sản phẩm.

**Preconditions:**

- Sản phẩm đã tồn tại.

- Hệ thống có dữ liệu readiness hoặc có thể tính readiness.

- Người dùng có quyền xem sản phẩm.

- Các quyền xử lý blocker được xác định rõ.

    

**Main flow:**

1. Người dùng mở sản phẩm từ danh sách hoặc sau khi tạo mới.

2. Hệ thống hiển thị readiness status tổng quan.

3. Người dùng mở readiness checklist.

4. Hệ thống hiển thị các nhóm dữ liệu đã đủ và còn thiếu.

5. Hệ thống xác định blocker ưu tiên cao nhất.

6. Hệ thống hiển thị hành động gợi ý nếu người dùng có quyền.

7. Người dùng chọn hành động gợi ý.

8. Hệ thống điều hướng đến màn xử lý tương ứng.

9. Người dùng hoàn thiện dữ liệu.

10. Hệ thống cập nhật readiness.

11. Nếu vẫn còn blocker, hệ thống hiển thị blocker tiếp theo.

12. Nếu không còn blocker bắt buộc, sản phẩm được hiển thị là sẵn sàng theo trạng thái phù hợp.

    

**Alternative flows:**

- AF-01. Người dùng không có quyền xử lý blocker → hệ thống hiển thị blocker nhưng không hiển thị action khả dụng.

- AF-02. Blocker phụ thuộc module khác → hệ thống điều hướng sang module liên quan nếu khả dụng.

- AF-03. Readiness tính lỗi → hệ thống hiển thị trạng thái cần kiểm tra, không hiển thị sai là “Sẵn sàng”.

- AF-04. Sản phẩm đủ dữ liệu nhưng ngừng kinh doanh → readiness dữ liệu đủ, nhưng trạng thái kinh doanh vẫn ngăn dùng trong giao dịch mới.

- AF-05. Người dùng xử lý một blocker nhưng còn blocker khác → checklist tiếp tục hiển thị blocker còn lại.

    

**Output:**

- Readiness checklist được cập nhật.

- Blocker đã xử lý được xóa.

- Hành động tiếp theo được ưu tiên theo trạng thái mới nhất.

- Product Change History được ghi nhận nếu dữ liệu thay đổi quan trọng.

    ```mermaid
    flowchart TD
    A[Mở Product Control Center] --> B[Hiển thị readiness status]
    B --> C[Mở readiness checklist]
    C --> D{Có blocker?}
    D -- Không --> E[Hiển thị Sẵn sàng theo trạng thái phù hợp]
    D -- Có --> F[Xác định blocker ưu tiên]
    F --> G{Người dùng có quyền xử lý?}
    G -- Không --> G1[Hiển thị blocker không có action khả dụng]
    G -- Có --> H[Hiển thị action gợi ý]
    H --> I[Người dùng mở màn xử lý]
    I --> J[Hoàn thiện dữ liệu]
    J --> K[Cập nhật readiness]
    K --> D    ```

### UXF-03 — Product Control Center

**Mục tiêu:** Biến màn chi tiết sản phẩm thành trung tâm điều phối dữ liệu và hành động theo ngữ cảnh, không chỉ là màn xem/sửa thông tin.

**Actor:** Tất cả người dùng có quyền xem sản phẩm; hành động cụ thể phụ thuộc quyền.

**Trigger:** Người dùng mở một sản phẩm từ danh sách, kết quả tìm kiếm, barcode scan hoặc sau khi tạo sản phẩm.

**Preconditions:**

- Sản phẩm tồn tại trong tenant hiện tại.

- Người dùng có quyền xem sản phẩm.

- Hệ thống có thể đọc các dữ liệu liên quan như ảnh, đơn vị, tồn kho, giá, custom fields, readiness và lịch sử nếu có quyền.

    

**Main flow:**

1. Người dùng mở sản phẩm.

2. Hệ thống tải hồ sơ tổng quan của sản phẩm.

3. Hệ thống hiển thị ảnh đại diện, tên, SKU/barcode và trạng thái kinh doanh.

4. Hệ thống hiển thị readiness summary.

5. Hệ thống hiển thị các card vận hành: đơn vị, tồn kho, Giá cơ sở định giá, khung giá bán, custom fields.

6. Hệ thống xác định các hành động theo ngữ cảnh.

7. Người dùng chọn hành động cần xử lý.

8. Hệ thống điều hướng đến màn con phù hợp.

9. Sau khi hành động hoàn tất, Product Control Center refresh dữ liệu.

10. Readiness và lịch sử thay đổi được cập nhật nếu cần.

    

**Alternative flows:**

- AF-01. Sản phẩm đã ngừng kinh doanh → UI hiển thị trạng thái “Ngừng KD” và giới hạn hành động giao dịch mới.

- AF-02. Sản phẩm đã xóa mềm → UI hiển thị read-only nếu người dùng có quyền xem dữ liệu đã xóa.

- AF-03. Người dùng chỉ có quyền xem → các hành động chỉnh sửa không hiển thị.

- AF-04. Dữ liệu từ module khác chưa khả dụng → card tương ứng hiển thị trạng thái chờ/không có dữ liệu.

- AF-05. Sản phẩm có nhiều blocker → action ưu tiên dựa trên blocker quan trọng nhất.

    

**Output:**

- Người dùng hiểu trạng thái hiện tại của sản phẩm.

- Người dùng có thể mở đúng hành động tiếp theo.

- Dữ liệu sản phẩm không bị gom vào một form chỉnh sửa lớn.

- Product Control Center trở thành điểm điều phối chính của Theme 2.

    ```mermaid
    flowchart TD
    A[Mở sản phẩm] --> B[Hiển thị hồ sơ tổng quan]
    B --> C[Hiển thị readiness summary]
    C --> D[Hiển thị card đơn vị]
    C --> E[Hiển thị card tồn kho]
    C --> F[Hiển thị card Giá cơ sở]
    C --> G[Hiển thị card khung giá]
    C --> H[Hiển thị custom fields]
    C --> I[Xác định contextual actions]
    I --> J{Người dùng chọn action?}
    J -- Sửa thông tin --> J1[Màn sửa hồ sơ]
    J -- Quản lý ảnh --> J2[Màn quản lý ảnh]
    J -- Quản lý đơn vị --> J3[Màn quản lý đơn vị]
    J -- Quản lý tồn kho --> J4[Màn tồn kho / module Kho]
    J -- Quản lý giá --> J5[Màn khung giá]
    J1 --> K[Refresh Product Control Center]
    J2 --> K
    J3 --> K
    J4 --> K
    J5 --> K    ```

### UXF-04 — Quản lý đơn vị đo lường

**Mục tiêu:** Cho phép người dùng thiết lập đơn vị cơ sở, thêm đơn vị quy đổi, vô hiệu hóa/kích hoạt lại đơn vị và đổi đơn vị cơ sở có kiểm soát.

**Actor:** Owner, Product Manager, Admin hoặc người dùng có quyền quản lý đơn vị sản phẩm.

**Trigger:** Người dùng chọn hành động “Quản lý đơn vị” từ Product Control Center hoặc readiness blocker “Thiếu đơn vị cơ sở”.

**Preconditions:**

- Sản phẩm tồn tại.

- Người dùng có quyền quản lý đơn vị.

- Tenant có danh sách đơn vị hoặc cho phép tạo đơn vị mới.

- Nếu đổi đơn vị cơ sở, hệ thống có đủ dữ liệu để kiểm tra tác động.

    

**Main flow:**

1. Người dùng mở màn quản lý đơn vị.

2. Hệ thống hiển thị đơn vị cơ sở hiện tại nếu có.

3. Hệ thống hiển thị danh sách đơn vị quy đổi.

4. Người dùng chọn thêm đơn vị mới, sửa đơn vị, vô hiệu hóa đơn vị hoặc đổi đơn vị cơ sở.

5. Hệ thống kiểm tra điều kiện và dữ liệu phụ thuộc.

6. Người dùng nhập tỷ lệ quy đổi nếu thêm đơn vị quy đổi.

7. Nếu đổi đơn vị cơ sở, hệ thống hiển thị preview tác động.

8. Người dùng xác nhận thao tác nếu có rủi ro.

9. Hệ thống lưu thay đổi.

10. Hệ thống cập nhật readiness và lịch sử thay đổi.

    

**Alternative flows:**

- AF-01. Sản phẩm chưa có đơn vị cơ sở → chỉ cho thiết lập đơn vị cơ sở trước.

- AF-02. Thêm đơn vị quy đổi trùng → hệ thống không cho lưu.

- AF-03. Tỷ lệ quy đổi không hợp lệ → hệ thống hiển thị lỗi.

- AF-04. Đơn vị đã phát sinh giao dịch → không xóa cứng, chỉ cho vô hiệu hóa.

- AF-05. Đổi đơn vị cơ sở không an toàn → hệ thống chặn và hiển thị lý do.

    

**Output:**

- Đơn vị cơ sở và đơn vị quy đổi được cập nhật hợp lệ.

- Các đơn vị dùng cho bán/nhập/hiển thị được xác định.

- Readiness đơn vị được cập nhật.

- Lịch sử thay đổi đơn vị được ghi nhận nếu cần.

    ```mermaid
    flowchart TD
    A[Product Control Center] --> B[Chọn Quản lý đơn vị]
    B --> C{Đã có đơn vị cơ sở?}
    C -- Chưa --> D[Thiết lập đơn vị cơ sở]
    C -- Có --> E[Hiển thị đơn vị cơ sở và đơn vị quy đổi]
    D --> E
    E --> F{Người dùng chọn hành động}
    F -- Thêm đơn vị quy đổi --> G[Nhập đơn vị và tỷ lệ quy đổi]
    F -- Vô hiệu hóa đơn vị --> H[Kiểm tra dữ liệu phụ thuộc]
    F -- Kích hoạt lại --> I[Kiểm tra trùng và tỷ lệ]
    F -- Đổi đơn vị cơ sở --> J[Preview tác động]
    G --> K{Dữ liệu hợp lệ?}
    H --> K
    I --> K
    J --> L{An toàn để đổi?}
    L -- Không --> L1[Chặn và hiển thị lý do]
    L -- Có --> M[Xác nhận]
    M --> N[Lưu thay đổi]
    K -- Không --> K1[Hiển thị lỗi]
    K -- Có --> N
    N --> O[Cập nhật readiness và lịch sử]    ```

### UXF-05 — Quản lý tồn kho cơ bản

**Mục tiêu:** Cho phép người dùng Foundation nhập hoặc chỉnh tồn kho trực tiếp trong Product khi tenant dùng Basic stock mode.

**Actor:** Owner, Product Manager, Warehouse hoặc người dùng có quyền chỉnh tồn kho cơ bản.

**Trigger:** Người dùng chọn “Quản lý tồn kho” từ Product Control Center hoặc từ readiness blocker tồn kho.

**Preconditions:**

- Sản phẩm tồn tại.

- Tenant hoặc sản phẩm đang dùng Basic stock mode.

- Sản phẩm có đơn vị cơ sở.

- Người dùng có quyền chỉnh tồn kho cơ bản.

    

**Main flow:**

1. Người dùng mở card tồn kho trong Product Control Center.

2. Hệ thống xác định sản phẩm đang dùng Basic stock.

3. Hệ thống hiển thị tồn kho hiện tại theo đơn vị cơ sở.

4. Người dùng chọn “Chỉnh tồn kho”.

5. Hệ thống mở màn điều chỉnh tồn kho.

6. Người dùng nhập số lượng mới hoặc mức điều chỉnh.

7. Người dùng nhập lý do nếu chính sách yêu cầu.

8. Hệ thống validate số lượng.

9. Người dùng lưu thay đổi.

10. Hệ thống cập nhật tồn kho cơ bản, ghi lịch sử và cập nhật readiness.

    

**Alternative flows:**

- AF-01. Sản phẩm chưa có đơn vị cơ sở → hệ thống không cho chỉnh tồn kho, yêu cầu thiết lập đơn vị trước.

- AF-02. Tenant dùng Advanced stock → hệ thống không cho chỉnh tồn kho trong Product.

- AF-03. Điều chỉnh khiến tồn kho âm → chặn hoặc cảnh báo theo chính sách tenant.

- AF-04. Hai người cùng chỉnh tồn kho → hệ thống phát hiện dữ liệu đã thay đổi và yêu cầu tải lại.

- AF-05. Người dùng không có quyền → không hiển thị action chỉnh tồn kho.

    

**Output:**

- Tồn kho cơ bản được cập nhật.

- Lịch sử điều chỉnh tồn kho được ghi nhận.

- Readiness tồn kho được cập nhật.

- Product Control Center hiển thị tồn kho mới nhất.

    ```mermaid
    flowchart TD
    A[Product Control Center] --> B[Card tồn kho]
    B --> C{Stock mode?}
    C -- Advanced stock --> C1[Hiển thị read-only và hướng dẫn sang module Kho]
    C -- Basic stock --> D{Có đơn vị cơ sở?}
    D -- Không --> D1[Hiển thị blocker Thiếu đơn vị cơ sở]
    D -- Có --> E[Hiển thị tồn kho hiện tại]
    E --> F[Chọn Chỉnh tồn kho]
    F --> G[Nhập số lượng mới / mức điều chỉnh]
    G --> H[Nhập lý do nếu cần]
    H --> I{Dữ liệu hợp lệ?}
    I -- Không --> I1[Hiển thị lỗi]
    I -- Có --> J[Lưu thay đổi]
    J --> K[Ghi lịch sử tồn kho]
    K --> L[Cập nhật readiness]    ```

### UXF-07 — Quản lý Giá cơ sở định giá thủ công

**Mục tiêu:** Cho phép người dùng Foundation nhập hoặc chỉnh Giá cơ sở định giá thủ công trong Product khi tenant dùng Manual base price mode.

**Actor:** Owner, Product Manager, Accountant hoặc người dùng có quyền quản lý giá.

**Trigger:** Người dùng chọn “Quản lý Giá cơ sở định giá” từ Product Control Center hoặc readiness blocker “Thiếu Giá cơ sở định giá”.

**Preconditions:**

- Sản phẩm tồn tại.

- Tenant hoặc sản phẩm đang dùng Manual base price mode.

- Sản phẩm có đơn vị cơ sở.

- Người dùng có quyền quản lý giá.

    

**Main flow:**

1. Người dùng mở Product Control Center.

2. Hệ thống hiển thị card Giá cơ sở định giá.

3. Hệ thống xác định sản phẩm đang dùng Manual base price.

4. Người dùng chọn “Nhập/Chỉnh Giá cơ sở”.

5. Hệ thống mở màn nhập Giá cơ sở định giá.

6. Người dùng nhập giá.

7. Hệ thống validate giá không âm và đơn vị áp dụng.

8. Người dùng lưu thay đổi.

9. Hệ thống cập nhật Product Base Price Profile.

10. Hệ thống ghi lịch sử và cập nhật readiness.

    

**Alternative flows:**

- AF-01. Sản phẩm chưa có đơn vị cơ sở → không cho nhập Giá cơ sở, yêu cầu thiết lập đơn vị trước.

- AF-02. Tenant dùng Costing-module base price → không cho chỉnh trực tiếp trong Product.

- AF-03. Giá nhập âm → không cho lưu.

- AF-04. Giá nhập bằng 0 → cảnh báo hoặc cho lưu theo chính sách tenant.

- AF-05. Giá cơ sở thay đổi làm khung giá hiện hành có rủi ro → hệ thống gợi ý kiểm tra lại khung giá bán.

    

**Output:**

- Giá cơ sở định giá thủ công được cập nhật.

- Readiness Giá cơ sở được cập nhật.

- Lịch sử thay đổi giá cơ sở được ghi nhận nếu cần.

- Khung giá bán có thể được cảnh báo nếu không còn phù hợp.

```mermaid
flowchart TD
    A[Product Control Center] --> B[Card Giá cơ sở định giá]
    B --> C{Base price mode?}
    C -- Costing-module --> C1[Hiển thị read-only từ module Giá vốn]
    C -- Manual --> D{Có đơn vị cơ sở?}
    D -- Không --> D1[Hiển thị blocker Thiếu đơn vị cơ sở]
    D -- Có --> E[Chọn Nhập/Chỉnh Giá cơ sở]
    E --> F[Nhập Giá cơ sở định giá]
    F --> G{Giá hợp lệ?}
    G -- Không --> G1[Hiển thị lỗi]
    G -- Có --> H[Lưu Giá cơ sở]
    H --> I[Ghi lịch sử]
    I --> J[Cập nhật readiness]
    J --> K{Khung giá có rủi ro?}
    K -- Có --> K1[Gợi ý kiểm tra lại khung giá]
    K -- Không --> L[Hoàn tất]```

### UXF-09 — Quản lý khung giá bán

**Mục tiêu:** Cho phép người dùng thiết lập Giá niêm yết và Giá sàn theo từng đơn vị bán của sản phẩm.

**Actor:** Owner, Product Manager, Accountant hoặc người dùng có quyền quản lý giá.

**Trigger:** Người dùng chọn “Thiết lập giá” từ Product Control Center, readiness blocker “Thiếu giá” hoặc flow tạo sản phẩm.

**Preconditions:**

- Sản phẩm tồn tại.

- Sản phẩm có ít nhất một đơn vị bán hợp lệ.

- Người dùng có quyền quản lý giá.

- Nếu có Giá cơ sở định giá, hệ thống có thể dùng để cảnh báo/gợi ý giá.

**Main flow:**

1. Người dùng mở màn quản lý khung giá.

2. Hệ thống hiển thị các đơn vị bán hợp lệ.

3. Hệ thống hiển thị Giá niêm yết và Giá sàn hiện hành nếu có.

4. Nếu có Store Price Rule và Giá cơ sở, hệ thống hiển thị giá gợi ý.

5. Người dùng nhập hoặc chỉnh Giá niêm yết.

6. Người dùng nhập hoặc chỉnh Giá sàn.

7. Hệ thống validate Giá sàn không lớn hơn Giá niêm yết.

8. Hệ thống cảnh báo nếu giá thấp hơn Giá cơ sở định giá.

9. Người dùng lưu khung giá.

10. Hệ thống cập nhật Product Unit Price Band, ghi lịch sử và cập nhật readiness.

**Alternative flows:**

- AF-01. Sản phẩm chưa có đơn vị bán → hệ thống yêu cầu thiết lập đơn vị bán trước.

- AF-02. Thiếu Giá cơ sở định giá → vẫn có thể nhập giá nhưng readiness Giá cơ sở còn blocker.

- AF-03. Giá sàn lớn hơn Giá niêm yết → không cho lưu.

- AF-04. Giá thấp hơn Giá cơ sở → cảnh báo hoặc chặn theo chính sách tenant.

- AF-05. Có nhiều đơn vị bán → mỗi đơn vị cần price band riêng nếu được dùng cho bán hàng.

**Output:**

- Product Unit Price Band được tạo hoặc cập nhật.

- Readiness khung giá bán được cập nhật.

- Sales và Promotions có thể đọc Giá niêm yết và Giá sàn hiện hành.

- Lịch sử thay đổi giá được ghi nhận.

    ```mermaid
    flowchart TD
    A[Product Control Center] --> B[Chọn Thiết lập giá]
    B --> C{Có đơn vị bán hợp lệ?}
    C -- Không --> C1[Yêu cầu thiết lập đơn vị bán]
    C -- Có --> D[Hiển thị đơn vị bán]
    D --> E{Có Giá cơ sở và Store Price Rule?}
    E -- Có --> F[Hiển thị giá gợi ý]
    E -- Không --> G[Nhập giá thủ công]
    F --> G
    G --> H[Nhập Giá niêm yết và Giá sàn]
    H --> I{Giá sàn <= Giá niêm yết?}
    I -- Không --> I1[Hiển thị lỗi]
    I -- Có --> J{Giá thấp hơn Giá cơ sở?}
    J -- Có --> J1[Cảnh báo hoặc chặn theo chính sách]
    J -- Không --> K[Lưu khung giá]
    J1 --> K
    K --> L[Cập nhật Product Unit Price Band]
    L --> M[Cập nhật readiness và lịch sử]    ```

### UXF-10 — Quản lý nhóm & trường thông tin

**Mục tiêu:** Cho phép người dùng nhập và cập nhật thông tin bổ sung theo custom field groups đã được tenant cấu hình.

**Actor:** Owner, Product Manager, Admin hoặc người dùng có quyền chỉnh thông tin sản phẩm.

**Trigger:** Người dùng mở section thông tin bổ sung trong Product Control Center hoặc flow tạo sản phẩm.

**Preconditions:**

- Tenant có custom field groups và custom fields đang hoạt động.

- Sản phẩm tồn tại hoặc đang trong flow tạo mới.

- Người dùng có quyền nhập/chỉnh custom field values.

**Main flow:**

Thiết lập > Sản phẩm > Nhóm & trường thông tin

→ Tạo nhóm

→ Chọn icon

→ Nhập tên nhóm

→ Thêm trường

→ Cấu hình required/searchable/filterable/display on list

→ Sắp xếp nhóm / field

→ Nhóm hiển thị thành card trong Product Control Center và Guided creation

1. Người dùng mở section thông tin bổ sung.

2. Hệ thống hiển thị các Custom Field Group đang hoạt động.

3. Hệ thống hiển thị các Custom Field đang hoạt động theo thứ tự cấu hình.

4. Người dùng nhập giá trị cho từng field.

5. Hệ thống validate theo kiểu dữ liệu và required rule.

6. Người dùng lưu thông tin.

7. Hệ thống lưu Product Custom Field Values.

8. Hệ thống cập nhật readiness nếu field bắt buộc ảnh hưởng readiness.

9. Product Control Center hiển thị dữ liệu mới nhất.

**Alternative flows:**

- AF-01. Tenant chưa có custom fields → không hiển thị section rỗng.

- AF-02. Field bắt buộc chưa nhập → hệ thống hiển thị lỗi hoặc readiness blocker.

- AF-03. Field bị vô hiệu hóa → không cho nhập mới, dữ liệu cũ có thể hiển thị read-only.

- AF-04. Nhập sai kiểu dữ liệu → không cho lưu field đó.

- AF-05. Người dùng không có quyền chỉnh → hiển thị read-only hoặc ẩn section theo quyền.

    

**Output:**

- Product Custom Field Values được lưu.

- Readiness thông tin bổ sung được cập nhật.

- Custom fields có thể dùng cho tìm kiếm, lọc hoặc báo cáo nếu được cấu hình.

- Dữ liệu cũ được bảo toàn khi field/group thay đổi trạng thái.

    ```mermaid
    flowchart TD
    A[Product Control Center] --> B[Section thông tin ngành]
    B --> C{Tenant có custom fields?}
    C -- Không --> C1[Không hiển thị section rỗng]
    C -- Có --> D[Hiển thị groups và fields]
    D --> E[Người dùng nhập giá trị]
    E --> F{Giá trị hợp lệ?}
    F -- Không --> F1[Hiển thị lỗi tại field]
    F -- Có --> G{Thiếu field bắt buộc?}
    G -- Có --> G1[Hiển thị lỗi hoặc readiness blocker]
    G -- Không --> H[Lưu Product Custom Field Values]
    H --> I[Cập nhật readiness]
    I --> J[Refresh Product Control Center]    ```

---

### UXF-11 — Ngừng kinh doanh / kinh doanh lại

**Mục tiêu:** Cho phép người dùng kiểm soát trạng thái kinh doanh của sản phẩm, đảm bảo sản phẩm ngừng kinh doanh không được dùng trong giao dịch mới nhưng vẫn bảo toàn dữ liệu lịch sử.

**Actor:** Owner, Product Manager, Admin hoặc người dùng có quyền quản lý trạng thái sản phẩm.

**Trigger:** Người dùng chọn “Ngừng kinh doanh” hoặc “Kinh doanh lại” từ Product Control Center.

**Preconditions:**

- Sản phẩm tồn tại.

- Người dùng có quyền quản lý trạng thái sản phẩm.

- Sản phẩm chưa bị xóa mềm.

- Hệ thống có thể kiểm tra readiness và dữ liệu liên quan nếu cần cảnh báo.

    

**Main flow — Ngừng kinh doanh:**

1. Người dùng mở Product Control Center.

2. Người dùng chọn “Ngừng kinh doanh”.

3. Hệ thống kiểm tra trạng thái hiện tại của sản phẩm.

4. Hệ thống kiểm tra dữ liệu cần cảnh báo như tồn kho, giao dịch mở, khuyến mãi.

5. Hệ thống hiển thị confirm dialog.

6. Người dùng xác nhận.

7. Hệ thống chuyển sản phẩm sang trạng thái “Ngừng KD”.

8. Hệ thống ghi lịch sử thay đổi trạng thái.

9. Product Control Center hiển thị trạng thái mới.

    

**Main flow — Kinh doanh lại:**

1. Người dùng mở sản phẩm đang “Ngừng KD”.

2. Người dùng chọn “Kinh doanh lại”.

3. Hệ thống kiểm tra readiness hiện tại.

4. Nếu đủ điều kiện theo chính sách, hệ thống chuyển sản phẩm sang “Đang KD”.

5. Nếu còn blocker, hệ thống hiển thị blocker cần xử lý.

6. Hệ thống ghi lịch sử thay đổi trạng thái.

7. Product Control Center hiển thị trạng thái mới.

    

**Alternative flows:**

- AF-01. Sản phẩm còn tồn kho khi ngừng kinh doanh → hiển thị cảnh báo.

- AF-02. Sản phẩm nằm trong giao dịch mở → cảnh báo hoặc chặn theo module liên quan.

- AF-03. Sản phẩm thiếu readiness khi kinh doanh lại → cho active nhưng không sẵn sàng bán, hoặc chặn theo chính sách.

- AF-04. Người dùng không có quyền → không hiển thị action.

- AF-05. Sản phẩm đã xóa mềm → không cho kinh doanh lại trực tiếp.

    

**Output:**

- Trạng thái kinh doanh của sản phẩm được cập nhật.

- Sản phẩm ngừng kinh doanh không được dùng trong giao dịch mới.

- Dữ liệu lịch sử vẫn được bảo toàn.

- Product Change History ghi nhận thay đổi trạng thái.

    ```mermaid
    flowchart TD
    A[Product Control Center] --> B{Trạng thái hiện tại}
    B -- Đang KD --> C[Chọn Ngừng kinh doanh]
    C --> D[Kiểm tra tồn kho/giao dịch/khuyến mãi]
    D --> E[Hiển thị xác nhận]
    E --> F{Người dùng xác nhận?}
    F -- Không --> F1[Hủy thao tác]
    F -- Có --> G[Chuyển sang Ngừng KD]
    G --> H[Ghi lịch sử]
    H --> I[Không dùng trong giao dịch mới]

    B -- Ngừng KD --> J[Chọn Kinh doanh lại]
    J --> K[Kiểm tra readiness]
    K --> L{Đủ điều kiện theo chính sách?}
    L -- Không --> L1[Hiển thị blocker cần xử lý]
    L -- Có --> M[Chuyển sang Đang KD]
    M --> H    ```

---

### UXF-12 — Xóa sản phẩm / khôi phục

**Mục tiêu:** Cho phép xóa mềm sản phẩm có kiểm soát, bảo toàn dữ liệu lịch sử và khôi phục nếu đủ điều kiện.

**Actor:** Owner, Admin hoặc người dùng có quyền xóa/khôi phục sản phẩm.

**Trigger:** Người dùng chọn “Xóa sản phẩm” hoặc “Khôi phục” từ Product Control Center hoặc danh sách sản phẩm đã xóa.

**Preconditions:**

- Sản phẩm tồn tại trong tenant hiện tại.

- Người dùng có quyền xóa hoặc khôi phục.

- Hệ thống có thể kiểm tra dữ liệu phụ thuộc như giao dịch, tồn kho, khuyến mãi, SKU/barcode.

    

**Main flow — Xóa sản phẩm:**

1. Người dùng mở Product Control Center.

2. Người dùng chọn “Xóa sản phẩm”.

3. Hệ thống kiểm tra dữ liệu phụ thuộc.

4. Nếu đủ điều kiện, hệ thống hiển thị confirm dialog.

5. Người dùng xác nhận.

6. Hệ thống chuyển sản phẩm sang trạng thái đã xóa mềm.

7. Hệ thống ghi lịch sử xóa.

8. Sản phẩm không hiển thị trong danh sách vận hành mặc định.

    

**Main flow — Khôi phục sản phẩm:**

1. Người dùng mở danh sách hoặc chi tiết sản phẩm đã xóa.

2. Người dùng chọn “Khôi phục”.

3. Hệ thống kiểm tra trùng SKU/barcode với sản phẩm hiện hành.

4. Hệ thống kiểm tra readiness hiện tại.

5. Nếu đủ điều kiện, hệ thống khôi phục sản phẩm khỏi trạng thái đã xóa mềm.

6. Hệ thống ghi lịch sử khôi phục.

7. Product Control Center hiển thị sản phẩm với readiness hiện tại.

    

**Alternative flows:**

- AF-01. Sản phẩm có giao dịch lịch sử → gợi ý ngừng kinh doanh thay vì xóa nếu chính sách không cho xóa.

- AF-02. Sản phẩm đang có giao dịch mở → chặn xóa.

- AF-03. Sản phẩm còn tồn kho → cảnh báo hoặc chặn theo chính sách.

- AF-04. Khôi phục bị trùng SKU/barcode → không cho khôi phục.

- AF-05. Người dùng không có quyền xem dữ liệu đã xóa → không hiển thị sản phẩm đã xóa.

    

**Output:**

- Sản phẩm được xóa mềm hoặc khôi phục.

- Dữ liệu lịch sử và giao dịch cũ được bảo toàn.

- Sản phẩm đã xóa không dùng được trong giao dịch mới.

- Readiness được tính lại sau khi khôi phục.

    ```mermaid
    flowchart TD
    A[Product Control Center] --> B[Chọn Xóa sản phẩm]
    B --> C[Kiểm tra dữ liệu phụ thuộc]
    C --> D{Đủ điều kiện xóa?}
    D -- Không --> D1[Chặn xóa hoặc gợi ý Ngừng kinh doanh]
    D -- Có --> E[Hiển thị xác nhận]
    E --> F{Người dùng xác nhận?}
    F -- Không --> F1[Hủy thao tác]
    F -- Có --> G[Xóa mềm sản phẩm]
    G --> H[Ghi lịch sử xóa]
    H --> I[Ẩn khỏi danh sách vận hành mặc định]

    J[Danh sách sản phẩm đã xóa] --> K[Chọn Khôi phục]
    K --> L[Kiểm tra trùng SKU/barcode]
    L --> M{Đủ điều kiện khôi phục?}
    M -- Không --> M1[Hiển thị lỗi không thể khôi phục]
    M -- Có --> N[Khôi phục sản phẩm]
    N --> O[Tính lại readiness]
    O --> P[Product Control Center]    ```

## Phụ lục C — State diagrams

Phụ lục C mô tả các sơ đồ trạng thái quan trọng của Theme 2. Các sơ đồ này giúp thống nhất cách hiểu giữa BA, UX và Dev về vòng đời sản phẩm, readiness, đơn vị đo lường, stock mode và base price mode.

Lưu ý chung:

- State diagram không thay thế FR.

- State diagram chỉ mô tả trạng thái nghiệp vụ chính.

- Một số trạng thái như readiness có thể là **calculated state**, không phải trạng thái người dùng chỉnh tay.

- Các transition quan trọng vẫn cần được kiểm soát bằng quyền, validation và lịch sử thay đổi.

    

---

### STD-01 — Product lifecycle

Sơ đồ này mô tả vòng đời kinh doanh của sản phẩm trong Theme 2.

Khuyến nghị thiết kế: khi khôi phục sản phẩm đã xóa mềm, hệ thống nên đưa sản phẩm về trạng thái **Ngừng KD** trước, thay vì tự động cho “Đang KD”. Lý do: sản phẩm đã xóa có thể đã lỗi thời về giá, đơn vị, tồn kho hoặc readiness.

|State|Tên hiển thị|Ý nghĩa|
|---|---|---|
|`ACTIVE`|Đang KD|Sản phẩm có thể được dùng trong giao dịch mới nếu readiness phù hợp|
|`INACTIVE`|Ngừng KD|Sản phẩm được giữ lại nhưng không dùng trong giao dịch mới|
|`SOFT_DELETED`|Đã xóa|Sản phẩm bị xóa mềm, không hiển thị mặc định và không dùng trong vận hành mới|

```mermaid
stateDiagram-v2
    [*] --> ACTIVE: Tạo sản phẩm mới

    ACTIVE --> INACTIVE: Ngừng kinh doanh
    INACTIVE --> ACTIVE: Kinh doanh lại

    ACTIVE --> SOFT_DELETED: Xóa mềm nếu đủ điều kiện
    INACTIVE --> SOFT_DELETED: Xóa mềm nếu đủ điều kiện

    SOFT_DELETED --> INACTIVE: Khôi phục

    SOFT_DELETED --> [*]: Xóa cứng kỹ thuật nếu có chính sách retention riêng```

**Quy tắc chuyển trạng thái**

|Transition|Điều kiện chính|
|---|---|
|Tạo mới → Đang KD|Người dùng có quyền tạo sản phẩm; dữ liệu tối thiểu hợp lệ|
|Đang KD → Ngừng KD|Người dùng có quyền; có xác nhận; cảnh báo nếu còn tồn kho/giao dịch mở|
|Ngừng KD → Đang KD|Người dùng có quyền; hệ thống kiểm tra readiness hiện tại|
|Đang KD/Ngừng KD → Đã xóa|Người dùng có quyền; đủ điều kiện xóa mềm; có xác nhận|
|Đã xóa → Ngừng KD|Người dùng có quyền khôi phục; không trùng SKU/barcode; tính lại readiness|
|Đã xóa → Xóa cứng|Không thuộc UI vận hành thường ngày; chỉ áp dụng nếu có chính sách kỹ thuật riêng|

**Ghi chú UX**

- Danh sách sản phẩm mặc định chỉ hiển thị `ACTIVE` và có thể hiển thị `INACTIVE` nếu người dùng bật filter.

- `SOFT_DELETED` không hiển thị mặc định.

- Giao dịch lịch sử vẫn hiển thị sản phẩm đã `INACTIVE` hoặc `SOFT_DELETED`.

- Sản phẩm `INACTIVE` hoặc `SOFT_DELETED` không được chọn cho giao dịch mới mặc định.

    

---

### STD-02 — Product readiness

Readiness là trạng thái tính toán từ dữ liệu hiện hành của sản phẩm. Đây không nên là một field người dùng chỉnh tay.

Readiness thực tế là một **checklist nhiều chiều**, vì một sản phẩm có thể thiếu nhiều dữ liệu cùng lúc. Sơ đồ dưới đây mô tả trạng thái hiển thị ưu tiên, không phải toàn bộ checklist nội bộ.

|State|Tên hiển thị|Ý nghĩa|
|---|---|---|
|`INCOMPLETE`|Chưa hoàn thiện|Sản phẩm còn thiếu dữ liệu quan trọng|
|`MISSING_PROFILE`|Thiếu hồ sơ|Thiếu dữ liệu nhận diện bắt buộc|
|`MISSING_BASE_UNIT`|Thiếu đơn vị|Chưa có đơn vị cơ sở hợp lệ|
|`MISSING_STOCK_SETUP`|Thiếu thiết lập tồn kho|Chưa có stock mode hoặc nguồn tồn kho hợp lệ|
|`MISSING_BASE_PRICE`|Thiếu Giá cơ sở|Chưa có Giá cơ sở định giá hoặc nguồn Giá cơ sở|
|`MISSING_PRICE_BAND`|Thiếu giá bán|Chưa có Giá niêm yết/Giá sàn hợp lệ|
|`MISSING_CUSTOM_FIELDS`|Thiếu thông tin bổ sung|Thiếu custom fields bắt buộc|
|`READY_FOR_PURCHASE`|Sẵn sàng nhập hàng|Đủ dữ liệu để dùng trong nhập hàng|
|`READY_FOR_SALE`|Sẵn sàng bán|Đủ dữ liệu để dùng trong bán hàng|
|`NOT_SELLABLE_BY_LIFECYCLE`|Không bán do trạng thái|Dữ liệu có thể đủ nhưng sản phẩm ngừng KD/đã xóa|

```mermaid
stateDiagram-v2
    [*] --> INCOMPLETE: Tạo sản phẩm mới

    INCOMPLETE --> MISSING_PROFILE: Thiếu hồ sơ bắt buộc
    INCOMPLETE --> MISSING_BASE_UNIT: Thiếu đơn vị cơ sở
    INCOMPLETE --> MISSING_STOCK_SETUP: Thiếu thiết lập tồn kho
    INCOMPLETE --> MISSING_BASE_PRICE: Thiếu Giá cơ sở định giá
    INCOMPLETE --> MISSING_PRICE_BAND: Thiếu khung giá bán
    INCOMPLETE --> MISSING_CUSTOM_FIELDS: Thiếu custom fields bắt buộc

    MISSING_PROFILE --> INCOMPLETE: Bổ sung hồ sơ
    MISSING_BASE_UNIT --> INCOMPLETE: Thiết lập đơn vị cơ sở
    MISSING_STOCK_SETUP --> INCOMPLETE: Thiết lập tồn kho hoặc nguồn tồn kho
    MISSING_BASE_PRICE --> INCOMPLETE: Thiết lập Giá cơ sở
    MISSING_PRICE_BAND --> INCOMPLETE: Thiết lập Giá niêm yết/Giá sàn
    MISSING_CUSTOM_FIELDS --> INCOMPLETE: Bổ sung thông tin ngành

    INCOMPLETE --> READY_FOR_PURCHASE: Đủ hồ sơ và đơn vị để nhập hàng
    READY_FOR_PURCHASE --> READY_FOR_SALE: Đủ khung giá và điều kiện bán hàng
    READY_FOR_SALE --> INCOMPLETE: Dữ liệu bắt buộc bị thiếu hoặc không hợp lệ

    READY_FOR_SALE --> NOT_SELLABLE_BY_LIFECYCLE: Ngừng KD hoặc đã xóa
    READY_FOR_PURCHASE --> NOT_SELLABLE_BY_LIFECYCLE: Ngừng KD hoặc đã xóa
    NOT_SELLABLE_BY_LIFECYCLE --> INCOMPLETE: Kinh doanh lại hoặc khôi phục, cần tính lại readiness```

**Quy tắc tính readiness**

|Nhóm|Điều kiện đủ tối thiểu|
|---|---|
|Hồ sơ|Có tên sản phẩm và dữ liệu nhận diện bắt buộc theo tenant|
|Đơn vị|Có đơn vị cơ sở hợp lệ|
|Tồn kho|Có Basic stock hợp lệ hoặc nguồn tồn kho nâng cao hợp lệ|
|Giá cơ sở|Có manual base price hoặc Giá cơ sở từ module Giá vốn|
|Khung giá bán|Mỗi đơn vị bán cần có Giá niêm yết và Giá sàn hợp lệ|
|Custom fields|Các field bắt buộc theo ngành đã có giá trị hợp lệ|
|Vòng đời|Sản phẩm phải ở trạng thái Đang KD để dùng trong giao dịch mới|

**Ghi chú quan trọng**

- `READY_FOR_PURCHASE` không đồng nghĩa với `READY_FOR_SALE`.

- Tồn kho bằng 0 không tự động tạo blocker readiness; đó có thể là trạng thái hết hàng.

- Sản phẩm có đủ dữ liệu nhưng đang `INACTIVE` vẫn không được coi là bán được.

- Nếu có nhiều blocker, UI nên hiển thị blocker ưu tiên cao nhất ở danh sách và hiển thị đầy đủ trong checklist.

    

---

### STD-03 — Unit lifecycle

Sơ đồ này mô tả vòng đời của một đơn vị trong phạm vi một sản phẩm.

Đơn vị ở đây bao gồm đơn vị cơ sở và đơn vị quy đổi. Tuy nhiên, đơn vị cơ sở có nhiều ràng buộc hơn: không được vô hiệu hóa trực tiếp nếu chưa đổi đơn vị cơ sở hợp lệ.

|State|Tên hiển thị|Ý nghĩa|
|---|---|---|
|`ACTIVE`|Đang dùng|Đơn vị có thể dùng trong giao dịch mới nếu có vai trò phù hợp|
|`INACTIVE`|Ngừng dùng|Đơn vị không còn dùng cho giao dịch mới nhưng dữ liệu cũ được giữ|
|`INVALID`|Không hợp lệ|Đơn vị thiếu tỷ lệ quy đổi hoặc dữ liệu không hợp lệ|
|`DELETED`|Đã xóa|Chỉ dùng nếu đơn vị chưa phát sinh dữ liệu và được phép xóa cứng|

```mermaid
stateDiagram-v2
    [*] --> ACTIVE: Tạo đơn vị hợp lệ

    ACTIVE --> INACTIVE: Vô hiệu hóa
    INACTIVE --> ACTIVE: Kích hoạt lại

    ACTIVE --> INVALID: Tỷ lệ quy đổi lỗi hoặc dữ liệu không hợp lệ
    INACTIVE --> INVALID: Dữ liệu không còn hợp lệ
    INVALID --> ACTIVE: Sửa dữ liệu hợp lệ
    INVALID --> INACTIVE: Giữ ngừng dùng

    ACTIVE --> DELETED: Xóa nếu chưa phát sinh dữ liệu
    INACTIVE --> DELETED: Xóa nếu chưa phát sinh dữ liệu

    DELETED --> [*]```

**Vai trò của đơn vị**

Vai trò không nhất thiết là state riêng. Một đơn vị `ACTIVE` có thể có một hoặc nhiều vai trò:

|Role|Ý nghĩa|
|---|---|
|`base_unit`|Đơn vị cơ sở của sản phẩm|
|`sales_unit`|Đơn vị được dùng để bán hàng|
|`purchase_unit`|Đơn vị được dùng để nhập hàng|
|`display_unit`|Đơn vị hiển thị mặc định|

**Quy tắc chuyển trạng thái**

|Transition|Điều kiện chính|
|---|---|
|Tạo → Đang dùng|Có tên đơn vị hợp lệ; nếu là đơn vị quy đổi thì có tỷ lệ quy đổi > 0|
|Đang dùng → Ngừng dùng|Người dùng có quyền; không phải đơn vị cơ sở trực tiếp hoặc đã đổi đơn vị cơ sở trước|
|Ngừng dùng → Đang dùng|Không trùng đơn vị đang hoạt động; tỷ lệ quy đổi hợp lệ|
|Đang dùng → Không hợp lệ|Dữ liệu bị lỗi, thiếu tỷ lệ, hoặc cấu hình không tương thích|
|Không hợp lệ → Đang dùng|Người dùng sửa dữ liệu thành hợp lệ|
|Đang dùng/Ngừng dùng → Đã xóa|Chỉ khi chưa phát sinh dữ liệu cần bảo toàn|

**Ghi chú UX**

- Đơn vị cơ sở cần được hiển thị nổi bật.

- Đơn vị không hoạt động không xuất hiện trong giao dịch mới.

- Đơn vị đã phát sinh giao dịch không nên xóa cứng.

- Đổi đơn vị cơ sở cần flow riêng có preview tác động.

    

---

### STD-04 — Stock mode

Sơ đồ này mô tả trạng thái quản lý tồn kho của sản phẩm.

Stock mode là một phần của Product Stock Profile. Đây là cách Product biết tồn kho được nhập trực tiếp trong Product hay được đọc từ module Kho.

|State|Tên hiển thị|Ý nghĩa|
|---|---|---|
|`BASIC_STOCK`|Tồn kho cơ bản|Tồn kho được nhập/chỉnh trực tiếp trong Product|
|`ADVANCED_STOCK`|Tồn kho từ module Kho|Product chỉ đọc stock summary từ module Kho|
|`MIGRATING`|Đang chuyển đổi|Đang chuyển từ Basic stock sang Advanced stock|
|`SOURCE_MISSING`|Chưa có nguồn tồn kho|Advanced stock nhưng chưa có mapping hoặc stock summary hợp lệ|

```mermaid
stateDiagram-v2
    [*] --> BASIC_STOCK: Foundation mặc định

    BASIC_STOCK --> MIGRATING: Bắt đầu chuyển sang Advanced stock
    MIGRATING --> ADVANCED_STOCK: Mapping và nguồn tồn kho hợp lệ
    MIGRATING --> SOURCE_MISSING: Thiếu mapping hoặc nguồn tồn kho

    SOURCE_MISSING --> ADVANCED_STOCK: Mapping/stock summary đã sẵn sàng
    ADVANCED_STOCK --> SOURCE_MISSING: Mất mapping hoặc module Kho chưa trả dữ liệu

    ADVANCED_STOCK --> BASIC_STOCK: Rollback nếu chính sách tenant cho phép```

**Quy tắc chính**

|State|Product cho phép làm gì|
|---|---|
|`BASIC_STOCK`|Cho nhập và chỉnh tồn kho cơ bản nếu có quyền|
|`MIGRATING`|Hạn chế chỉnh tồn kho; cần kiểm soát dữ liệu đang chuyển|
|`ADVANCED_STOCK`|Không cho chỉnh tồn kho trực tiếp trong Product|
|`SOURCE_MISSING`|Không hiển thị stock summary như dữ liệu chắc chắn; cần xử lý mapping/source|

**Ghi chú quan trọng**

- Tồn kho bằng 0 khác với `SOURCE_MISSING`.

- Trong `ADVANCED_STOCK`, Product không tạo phiếu nhập/xuất/kiểm kê.

- Khi chuyển từ `BASIC_STOCK` sang `ADVANCED_STOCK`, tồn kho cơ bản cũ cần được bảo toàn dưới dạng lịch sử hoặc snapshot.

- Nếu module Kho chưa có dữ liệu, UI phải hiển thị “Chưa có nguồn tồn kho”, không hiển thị tồn kho cũ như tồn kho hiện hành.

    

---

### STD-05 — Base price mode

Sơ đồ này mô tả trạng thái nguồn Giá cơ sở định giá của sản phẩm.

Base price mode là một phần của Product Base Price Profile. Đây là cách Product biết Giá cơ sở định giá được nhập thủ công trong Product hay đọc từ module Giá vốn.

|State|Tên hiển thị|Ý nghĩa|
|---|---|---|
|`MANUAL_BASE_PRICE`|Giá cơ sở nhập thủ công|Người dùng nhập/chỉnh Giá cơ sở trong Product|
|`COSTING_MODULE_BASE_PRICE`|Giá cơ sở từ module Giá vốn|Product đọc Giá cơ sở từ Costing module|
|`MIGRATING`|Đang chuyển đổi|Đang chuyển từ manual sang Costing-module|
|`SOURCE_MISSING`|Chưa có nguồn Giá cơ sở|Costing-module mode nhưng chưa có Giá cơ sở hợp lệ|

```mermaid
stateDiagram-v2
    [*] --> MANUAL_BASE_PRICE: Foundation mặc định

    MANUAL_BASE_PRICE --> MIGRATING: Bắt đầu chuyển sang Costing module
    MIGRATING --> COSTING_MODULE_BASE_PRICE: Mapping và Giá cơ sở hợp lệ
    MIGRATING --> SOURCE_MISSING: Thiếu mapping hoặc module Giá vốn chưa có dữ liệu

    SOURCE_MISSING --> COSTING_MODULE_BASE_PRICE: Module Giá vốn cung cấp Giá cơ sở hợp lệ
    COSTING_MODULE_BASE_PRICE --> SOURCE_MISSING: Mất nguồn Giá cơ sở hoặc dữ liệu lỗi

    COSTING_MODULE_BASE_PRICE --> MANUAL_BASE_PRICE: Rollback nếu chính sách tenant cho phép```

**Quy tắc chính**

|State|Product cho phép làm gì|
|---|---|
|`MANUAL_BASE_PRICE`|Cho nhập/chỉnh Giá cơ sở định giá nếu có quyền|
|`MIGRATING`|Hạn chế chỉnh Giá cơ sở; cần kiểm soát dữ liệu đang chuyển|
|`COSTING_MODULE_BASE_PRICE`|Không cho chỉnh Giá cơ sở trực tiếp trong Product|
|`SOURCE_MISSING`|Hiển thị thiếu nguồn Giá cơ sở; không hiển thị giá cũ như giá hiện hành chắc chắn|

**Ghi chú quan trọng**

- Theme 2 không tính giá vốn FIFO, FILO hoặc bình quân.

- Nếu dùng module Giá vốn, Product chỉ đọc Giá cơ sở định giá từ module đó.

- Khi chuyển từ manual sang Costing-module, Giá cơ sở thủ công cũ cần được bảo toàn trong lịch sử.

- Giá cơ sở thay đổi có thể làm khung giá bán hiện hành cần được kiểm tra lại.

    

---

### STD-06 — Price band lifecycle

Sơ đồ này mô tả vòng đời của Product Unit Price Band, tức khung Giá niêm yết và Giá sàn theo từng đơn vị bán.

|State|Tên hiển thị|Ý nghĩa|
|---|---|---|
|`MISSING`|Thiếu giá|Đơn vị bán chưa có khung giá|
|`DRAFT`|Đang nhập|Người dùng đang nhập nhưng chưa lưu hợp lệ|
|`ACTIVE`|Đang áp dụng|Khung giá hiện hành hợp lệ|
|`INVALID`|Không hợp lệ|Giá sàn > Giá niêm yết hoặc dữ liệu lỗi|
|`INACTIVE`|Ngừng áp dụng|Khung giá không còn dùng cho giao dịch mới|

```mermaid
stateDiagram-v2
    [*] --> MISSING: Đơn vị bán chưa có giá

    MISSING --> DRAFT: Người dùng bắt đầu nhập giá
    DRAFT --> ACTIVE: Lưu Giá niêm yết và Giá sàn hợp lệ
    DRAFT --> INVALID: Dữ liệu giá không hợp lệ

    ACTIVE --> INVALID: Dữ liệu bị lỗi hoặc thay đổi phụ thuộc
    INVALID --> ACTIVE: Sửa giá hợp lệ

    ACTIVE --> INACTIVE: Đơn vị bán ngừng hoạt động hoặc price band bị vô hiệu hóa
    INACTIVE --> ACTIVE: Kích hoạt lại nếu đủ điều kiện```

**Quy tắc chính**

|Rule|Diễn giải|
|---|---|
|Giá niêm yết|Là giá trước khuyến mãi|
|Giá sàn|Là ngưỡng kiểm soát để bảo vệ lợi nhuận|
|Validation lõi|Giá sàn không được lớn hơn Giá niêm yết|
|Readiness|Đơn vị bán thiếu price band hợp lệ tạo blocker “Thiếu khung giá bán”|
|Snapshot|Sales cần lưu snapshot giá trên giao dịch nếu cần bảo toàn lịch sử|

---

### STD-07 — Custom field lifecycle

Sơ đồ này mô tả vòng đời của một Custom Field trong tenant.

|State|Tên hiển thị|Ý nghĩa|
|---|---|---|
|`ACTIVE`|Đang hoạt động|Field hiển thị khi nhập dữ liệu mới|
|`INACTIVE`|Ngừng dùng|Field không hiển thị khi nhập mới, nhưng dữ liệu cũ được giữ|
|`INVALID`|Không hợp lệ|Cấu hình field lỗi hoặc thiếu option bắt buộc|
|`DELETED`|Đã xóa|Chỉ áp dụng khi field chưa có dữ liệu và được phép xóa|

```mermaid
stateDiagram-v2
    [*] --> ACTIVE: Tạo field hợp lệ

    ACTIVE --> INACTIVE: Vô hiệu hóa
    INACTIVE --> ACTIVE: Kích hoạt lại

    ACTIVE --> INVALID: Cấu hình lỗi
    INACTIVE --> INVALID: Cấu hình không còn hợp lệ
    INVALID --> ACTIVE: Sửa cấu hình hợp lệ
    INVALID --> INACTIVE: Giữ field ở trạng thái ngừng dùng

    ACTIVE --> DELETED: Xóa nếu chưa có dữ liệu
    INACTIVE --> DELETED: Xóa nếu chưa có dữ liệu

    DELETED --> [*]```

**Quy tắc chính**

|Rule|Diễn giải|
|---|---|
|Field đang hoạt động|Được dùng để nhập dữ liệu mới|
|Field ngừng dùng|Không dùng để nhập mới, nhưng Product Custom Field Value cũ vẫn được bảo toàn|
|Field đã có dữ liệu|Không nên xóa cứng|
|Field required|Có thể ảnh hưởng readiness nếu được cấu hình tham gia readiness|
|Field searchable/filterable|Chỉ tham gia tìm kiếm/lọc khi đang được cấu hình phù hợp|

---

### STD-08 — Readiness blocker lifecycle

Sơ đồ này mô tả vòng đời của một readiness blocker cụ thể, ví dụ “Thiếu đơn vị cơ sở” hoặc “Thiếu khung giá bán”.

|State|Tên hiển thị|Ý nghĩa|
|---|---|---|
|`OPEN`|Đang thiếu|Blocker đang tồn tại|
|`ACTIONABLE`|Có thể xử lý|Người dùng hiện tại có quyền xử lý blocker|
|`BLOCKED_BY_PERMISSION`|Không có quyền xử lý|Người dùng thấy blocker nhưng không xử lý được|
|`BLOCKED_BY_SOURCE`|Chờ nguồn dữ liệu|Blocker phụ thuộc module khác như Kho/Giá vốn|
|`RESOLVED`|Đã xử lý|Dữ liệu đã đủ, blocker được xóa|
|`IGNORED`|Không áp dụng|Blocker không còn áp dụng do cấu hình hoặc trạng thái thay đổi|

```mermaid
stateDiagram-v2
    [*] --> OPEN: Hệ thống phát hiện thiếu dữ liệu

    OPEN --> ACTIONABLE: Người dùng có quyền xử lý
    OPEN --> BLOCKED_BY_PERMISSION: Người dùng không có quyền xử lý
    OPEN --> BLOCKED_BY_SOURCE: Chờ module khác cung cấp dữ liệu

    ACTIONABLE --> RESOLVED: Người dùng hoàn thiện dữ liệu
    BLOCKED_BY_SOURCE --> RESOLVED: Nguồn dữ liệu đã sẵn sàng
    BLOCKED_BY_PERMISSION --> ACTIONABLE: Người dùng được cấp quyền

    OPEN --> IGNORED: Cấu hình thay đổi, blocker không còn áp dụng
    ACTIONABLE --> IGNORED: Cấu hình thay đổi
    BLOCKED_BY_SOURCE --> IGNORED: Mode/source thay đổi

    RESOLVED --> OPEN: Dữ liệu bị xóa hoặc trở nên không hợp lệ
    IGNORED --> OPEN: Cấu hình bật lại điều kiện blocker```

**Ghi chú UX**

- Danh sách sản phẩm chỉ nên hiển thị blocker ưu tiên cao nhất.

- Product Control Center hiển thị đầy đủ blocker trong checklist.

- Nếu blocker `BLOCKED_BY_PERMISSION`, UI không hiển thị action như khả dụng.

- Nếu blocker `BLOCKED_BY_SOURCE`, UI cần nói rõ đang chờ module nào hoặc cần mapping gì.

    

---

### Tổng kết Phụ lục C

Các state diagram trong phụ lục này giúp chuẩn hóa các điểm dễ nhầm:

|**Điểm dễ nhầm**|**Cách chuẩn hóa**|
|---|---|
|Đang KD không đồng nghĩa với sẵn sàng bán|Tách Product lifecycle và Product readiness|
|Hết hàng không đồng nghĩa với thiếu thiết lập tồn kho|Tách stock quantity và stock setup/source|
|Giá cơ sở không đồng nghĩa với Giá niêm yết|Tách Base price mode và Price band lifecycle|
|Xóa sản phẩm không được làm mất lịch sử|Dùng soft delete và bảo toàn snapshot/lịch sử|
|Custom field ngừng dùng không được xóa dữ liệu cũ|Tách inactive và deleted|
|Readiness blocker không phải lúc nào cũng xử lý được bởi người dùng hiện tại|Tách actionable, blocked by permission và blocked by source|

## Phụ lục D — Integration diagrams

Phụ lục D mô tả ranh giới tích hợp giữa Theme 2 và các module khác. Mục tiêu là làm rõ dữ liệu nào thuộc Product, dữ liệu nào Product chỉ đọc từ module chuyên trách, và dữ liệu nào Product cung cấp cho các module khác sử dụng.

Nguyên tắc chung:

- Theme 2 là nguồn quản lý dữ liệu nền của sản phẩm.

- Theme 2 không xử lý nghiệp vụ chuyên sâu của Kho, Giá vốn, Sales, Promotions hoặc Reporting.

- Khi dữ liệu thuộc module khác, Product chỉ đọc hoặc điều hướng, không tự chỉnh sửa.

- Khi module khác dùng dữ liệu Product, module đó cần lưu snapshot nếu nghiệp vụ yêu cầu bảo toàn lịch sử.

- Dữ liệu tích hợp luôn phải nằm trong phạm vi tenant hiện tại.

    

---

### INT-00 — Integration context tổng quan

Sơ đồ này mô tả Theme 2 ở trung tâm dữ liệu sản phẩm và các module liên quan.

```mermaid
flowchart LR
    ONB[Onboarding] -->|Ngành kinh doanh / template| P[Theme 2: Product]

    P -->|Product identity / status / readiness| S[Sales]
    P -->|Giá niêm yết / Giá sàn| PR[Promotions]
    P -->|Product data / custom fields / readiness| R[Reporting]

    I[Inventory / Kho] -->|Stock summary| P
    C[Costing / Giá vốn] -->|Giá cơ sở định giá| P

    S -->|Snapshot giao dịch| SH[Sales History]
    PR -->|Giá sau khuyến mãi| S```

|Module|Quan hệ với Theme 2|Ranh giới|
|---|---|---|
|Onboarding|Cung cấp ngành kinh doanh để khởi tạo custom fields|Onboarding không quản lý dữ liệu sản phẩm sau khi khởi tạo|
|Inventory / Kho|Cung cấp stock summary khi dùng Advanced stock|Product không tạo phiếu nhập/xuất/kiểm kê|
|Costing / Giá vốn|Cung cấp Giá cơ sở định giá khi dùng Costing-module base price|Product không tính FIFO/FILO/bình quân|
|Sales|Đọc sản phẩm, đơn vị, Giá niêm yết, Giá sàn|Sales ghi nhận giao dịch và snapshot|
|Promotions|Đọc Giá niêm yết và Giá sàn để tính/kiểm soát khuyến mãi|Promotions tính giá sau khuyến mãi|
|Reporting|Đọc dữ liệu sản phẩm, readiness, custom fields và lịch sử|Reporting không sửa dữ liệu Product|

---

### INT-01 — Product ↔ Inventory

**Mục tiêu:** Làm rõ cách Product đọc tồn kho khi tenant dùng Advanced stock.

Trong Basic stock, tồn kho được nhập và chỉnh trực tiếp trong Product. Trong Advanced stock, tồn kho thuộc module Kho; Product chỉ hiển thị stock summary read-only.

**Ranh giới dữ liệu**

|Dữ liệu|Nguồn quản lý|Theme 2 làm gì|
|---|---|---|
|Basic stock quantity|Product Stock Profile|Nhập/chỉnh trực tiếp trong Product|
|Stock mode|Product Stock Profile|Quản lý trong Product|
|Stock summary nâng cao|Inventory / Kho|Product chỉ đọc|
|Nhập kho / xuất kho / kiểm kê|Inventory / Kho|Product không xử lý|
|Stock snapshot trên giao dịch|Sales / Inventory tùy nghiệp vụ|Product không ghi snapshot giao dịch|

**Flow đọc stock summary**

```mermaid
sequenceDiagram
    participant U as User
    participant P as Product Control Center
    participant PS as Product Stock Profile
    participant I as Inventory / Kho

    U->>P: Mở sản phẩm
    P->>PS: Kiểm tra stock mode
    alt Basic stock
        PS-->>P: Basic stock quantity
        P-->>U: Hiển thị tồn kho cơ bản, cho chỉnh nếu có quyền
    else Advanced stock
        P->>I: Yêu cầu stock summary theo product_id / tenant
        alt Có stock summary
            I-->>P: Tổng tồn / tồn theo kho nếu có
            P-->>U: Hiển thị stock summary read-only
        else Chưa có dữ liệu
            I-->>P: Không có stock summary / chưa mapping
            P-->>U: Hiển thị trạng thái chưa có nguồn tồn kho
        end
    end```

**Quy tắc tích hợp**

- Product phải kiểm tra stock mode trước khi hiển thị hành động tồn kho.

- Nếu `Basic stock`, Product có thể cho nhập/chỉnh tồn kho cơ bản theo quyền.

- Nếu `Advanced stock`, Product không cho chỉnh tồn kho trực tiếp.

- Nếu module Kho chưa có dữ liệu, Product không được hiển thị tồn kho cũ như tồn kho hiện hành.

- Tồn kho bằng 0 từ module Kho là “hết hàng”, không phải “thiếu nguồn tồn kho”.

- Product cần hiển thị rõ nguồn dữ liệu: “Tồn kho cơ bản” hoặc “Từ module Kho”.

    

**Trạng thái lỗi cần xử lý**

|Trạng thái|Hành vi UI|
|---|---|
|Module Kho chưa khả dụng|Hiển thị “Chưa có dữ liệu tồn kho”|
|Sản phẩm chưa mapping với Kho|Hiển thị blocker “Chưa có nguồn tồn kho”|
|Người dùng không có quyền xem tồn kho|Không hiển thị số lượng tồn|
|Dữ liệu Kho stale|Hiển thị cảnh báo nếu module Kho cung cấp trạng thái stale|
|Stock mode thay đổi trong lúc chỉnh|Chặn lưu và yêu cầu tải lại|

---

### INT-02 — Product ↔ Costing

**Mục tiêu:** Làm rõ cách Product lấy Giá cơ sở định giá khi tenant dùng module Giá vốn.

Trong Manual base price mode, Giá cơ sở định giá được nhập thủ công trong Product. Trong Costing-module base price mode, Giá cơ sở định giá thuộc module Giá vốn; Product chỉ hiển thị read-only.

**Ranh giới dữ liệu**

|Dữ liệu|Nguồn quản lý|Theme 2 làm gì|
|---|---|---|
|Manual base price|Product Base Price Profile|Nhập/chỉnh trực tiếp trong Product|
|Base price mode|Product Base Price Profile|Quản lý trong Product|
|Giá cơ sở từ giá vốn|Costing / Giá vốn|Product chỉ đọc|
|Phương pháp giá vốn FIFO/FILO/bình quân|Costing / Giá vốn|Product không tính|
|Giá vốn trên giao dịch/báo cáo|Costing / Reporting|Product không ghi nhận|

**Flow đọc Giá cơ sở từ module Giá vốn**

```mermaid
sequenceDiagram
    participant U as User
    participant P as Product Control Center
    participant BP as Product Base Price Profile
    participant C as Costing / Giá vốn

    U->>P: Mở sản phẩm
    P->>BP: Kiểm tra base price mode
    alt Manual base price
        BP-->>P: Manual base price
        P-->>U: Hiển thị Giá cơ sở, cho chỉnh nếu có quyền
    else Costing-module base price
        P->>C: Yêu cầu Giá cơ sở định giá theo product_id / tenant
        alt Có Giá cơ sở
            C-->>P: Giá cơ sở, phương pháp, thời điểm hiệu lực nếu có
            P-->>U: Hiển thị Giá cơ sở read-only
        else Chưa có Giá cơ sở
            C-->>P: Không có dữ liệu
            P-->>U: Hiển thị trạng thái thiếu nguồn Giá cơ sở
        end
    end```

**Quy tắc tích hợp**

- Product phải kiểm tra base price mode trước khi hiển thị hành động Giá cơ sở.

- Nếu `Manual base price`, Product cho nhập/chỉnh Giá cơ sở theo quyền.

- Nếu `Costing-module base price`, Product chỉ đọc Giá cơ sở từ module Giá vốn.

- Product không tính FIFO, FILO, bình quân cuối kỳ hoặc bình quân linh hoạt.

- Nếu Costing chưa trả dữ liệu, readiness có thể ghi nhận blocker “Thiếu Giá cơ sở định giá”.

- Khi Giá cơ sở thay đổi, Product có thể cảnh báo cần kiểm tra lại khung giá bán.

    

**Trạng thái lỗi cần xử lý**

|Trạng thái|Hành vi UI|
|---|---|
|Module Giá vốn chưa có dữ liệu|Hiển thị “Chưa có Giá cơ sở từ module Giá vốn”|
|Sản phẩm chưa mapping với Costing|Hiển thị blocker hoặc trạng thái cần mapping|
|Người dùng không có quyền xem giá|Không hiển thị số Giá cơ sở|
|Giá cơ sở stale|Hiển thị thời điểm cập nhật/hiệu lực nếu có|
|Base price mode thay đổi trong lúc chỉnh|Chặn lưu Giá cơ sở thủ công và yêu cầu tải lại|

---

### INT-03 — Product ↔ Sales

**Mục tiêu:** Làm rõ cách Sales sử dụng dữ liệu sản phẩm từ Theme 2 để tạo giao dịch bán hàng.

Sales đọc sản phẩm, trạng thái, readiness, đơn vị bán, Giá niêm yết và Giá sàn từ Theme 2. Sales là module ghi nhận đơn hàng, số lượng bán, giá cuối cùng và snapshot giao dịch.

**Ranh giới dữ liệu**

|Dữ liệu|Nguồn quản lý|Ghi chú|
|---|---|---|
|Tên sản phẩm, SKU, barcode|Product|Sales đọc để tìm/chọn sản phẩm|
|Trạng thái kinh doanh|Product|Sản phẩm ngừng KD không dùng cho giao dịch mới mặc định|
|Readiness bán hàng|Product|Sales dùng để biết sản phẩm có đủ điều kiện bán không|
|Đơn vị bán|Product Unit|Sales chỉ dùng đơn vị đang hoạt động và được phép bán|
|Giá niêm yết|Product Unit Price Band|Sales dùng làm giá trước khuyến mãi|
|Giá sàn|Product Unit Price Band|Sales dùng để kiểm soát bán dưới ngưỡng|
|Giá bán cuối cùng|Sales|Không thuộc Product|
|Snapshot giao dịch|Sales|Sales lưu theo chính sách giao dịch|

**Flow chọn sản phẩm trong Sales**

```mermaid
sequenceDiagram
    participant U as Sales User
    participant S as Sales
    participant P as Product
    participant O as Order

    U->>S: Tìm/chọn sản phẩm trong đơn bán
    S->>P: Yêu cầu sản phẩm khả dụng theo tenant
    P-->>S: Product identity, status, readiness, sales units, price band

    alt Sản phẩm bán được
        S-->>U: Hiển thị sản phẩm và giá trước khuyến mãi
        U->>S: Chọn sản phẩm, đơn vị, số lượng
        S->>O: Ghi dòng đơn hàng
        O->>O: Lưu snapshot sản phẩm/đơn vị/giá nếu chính sách yêu cầu
    else Không bán được
        S-->>U: Hiển thị lý do không thể chọn
    end```

**Quy tắc tích hợp**

- Sales không tự tạo hoặc sửa dữ liệu Product.

- Sales không được chọn sản phẩm đã `SOFT_DELETED`.

- Sản phẩm `INACTIVE` không xuất hiện trong lựa chọn bán hàng mặc định.

- Sales cần kiểm tra đơn vị bán đang hoạt động.

- Sales cần đọc Giá niêm yết và Giá sàn theo đúng đơn vị bán.

- Sales chịu trách nhiệm lưu giá cuối cùng và snapshot giao dịch.

    

**Trạng thái lỗi cần xử lý**

|Trạng thái|Hành vi Sales|
|---|---|
|Sản phẩm thiếu readiness bán hàng|Không cho chọn hoặc cảnh báo theo chính sách|
|Thiếu Giá niêm yết|Không có giá trước khuyến mãi hợp lệ|
|Thiếu Giá sàn|Không có ngưỡng kiểm soát giá|
|Đơn vị bán không hoạt động|Không hiển thị đơn vị đó|
|Sản phẩm ngừng KD|Không hiển thị mặc định trong đơn mới|
|Giá thay đổi trong lúc tạo đơn|Sales cần xác nhận lại hoặc lưu snapshot đúng thời điểm|

---

### INT-04 — Product ↔ Promotions

**Mục tiêu:** Làm rõ ranh giới giữa khung giá trong Theme 2 và giá sau khuyến mãi trong Promotions.

Theme 2 cung cấp Giá niêm yết và Giá sàn. Promotions dùng dữ liệu này để tính hoặc kiểm soát giá sau khuyến mãi, nhưng không ghi đè Giá niêm yết hoặc Giá sàn trong Product.

**Ranh giới dữ liệu**

|Dữ liệu|Nguồn quản lý|Ghi chú|
|---|---|---|
|Giá niêm yết|Product Unit Price Band|Giá trước khuyến mãi|
|Giá sàn|Product Unit Price Band|Ngưỡng kiểm soát lợi nhuận|
|Coupon/discount/combo/loyalty|Promotions|Không thuộc Theme 2|
|Giá sau khuyến mãi|Promotions / Sales|Không ghi đè vào Product|
|Phê duyệt bán dưới Giá sàn|Sales control / Promotions|Không thuộc Theme 2|

**Flow tính giá khuyến mãi**

```mermaid
sequenceDiagram
    participant U as User
    participant PR as Promotions
    participant P as Product
    participant S as Sales

    U->>PR: Tạo hoặc áp dụng khuyến mãi
    PR->>P: Đọc Giá niêm yết và Giá sàn theo product/unit
    P-->>PR: Listed price, floor price

    PR->>PR: Tính giá sau khuyến mãi

    alt Giá sau khuyến mãi >= Giá sàn
        PR-->>S: Trả giá khuyến mãi hợp lệ
    else Giá sau khuyến mãi < Giá sàn
        PR-->>S: Trả cảnh báo hoặc yêu cầu kiểm soát
        S->>S: Chặn, cảnh báo hoặc yêu cầu phê duyệt theo chính sách
    end```

**Quy tắc tích hợp**

- Product không tính giá sau khuyến mãi.

- Promotions không ghi đè Giá niêm yết trong Product.

- Promotions không ghi đè Giá sàn trong Product.

- Giá sau khuyến mãi thấp hơn Giá sàn cần được Promotions hoặc Sales xử lý theo chính sách.

- Nếu Product thiếu Giá niêm yết hoặc Giá sàn, Promotions cần nhận trạng thái thiếu dữ liệu thay vì giá rỗng.

- Sales là nơi ghi nhận giá cuối cùng trên giao dịch.

    

**Trạng thái lỗi cần xử lý**

|Trạng thái|Hành vi Promotions/Sales|
|---|---|
|Thiếu Giá niêm yết|Không tính được giá trước khuyến mãi chuẩn|
|Thiếu Giá sàn|Không kiểm soát được ngưỡng giá|
|Giá khuyến mãi thấp hơn Giá sàn|Cảnh báo/chặn/phê duyệt theo chính sách|
|Sản phẩm ngừng KD|Không thêm vào chương trình mới mặc định|
|Đơn vị bán không hoạt động|Không áp dụng khuyến mãi cho đơn vị đó|

---

### INT-05 — Product ↔ Reporting

**Mục tiêu:** Làm rõ cách Reporting sử dụng dữ liệu Product để phân tích, báo cáo và quản trị.

Reporting đọc dữ liệu sản phẩm, readiness, trạng thái, custom fields, giá, đơn vị và lịch sử nếu cần. Reporting không sửa dữ liệu Product.

**Ranh giới dữ liệu**

|Dữ liệu|Nguồn quản lý|Reporting dùng để|
|---|---|---|
|Product identity|Product|Nhóm báo cáo theo sản phẩm|
|Product status|Product|Lọc Đang KD / Ngừng KD / Đã xóa|
|Readiness|Product Readiness|Báo cáo chất lượng dữ liệu nền|
|Custom fields|Product Custom Field Value|Lọc/nhóm theo thông tin bổ sung|
|Đơn vị|Product Unit|Diễn giải số lượng nếu cần|
|Giá niêm yết/Giá sàn|Product Unit Price Band|Phân tích khung giá hiện hành|
|Lịch sử thay đổi|Product Change History|Truy vết thay đổi|
|Giao dịch bán/nhập|Sales/Purchase|Báo cáo doanh thu, nhập hàng, lợi nhuận|

**Flow báo cáo readiness sản phẩm**

```mermaid
sequenceDiagram
    participant U as Manager
    participant R as Reporting
    participant P as Product
    participant CF as Custom Fields

    U->>R: Mở báo cáo chất lượng dữ liệu sản phẩm
    R->>P: Đọc product list, status, readiness
    R->>CF: Đọc custom field values nếu cần lọc/nhóm
    P-->>R: Product readiness summary
    CF-->>R: Custom field values
    R-->>U: Hiển thị sản phẩm đủ/thiếu dữ liệu theo nhóm blocker```

**Quy tắc tích hợp**

- Reporting chỉ đọc dữ liệu Product.

- Reporting không tự sửa readiness, custom fields, giá hoặc đơn vị.

- Reporting cần tôn trọng tenant isolation.

- Reporting cần tôn trọng quyền xem dữ liệu giá, tồn kho, lịch sử và dữ liệu đã xóa.

- Custom fields chỉ nên được dùng để lọc/nhóm nếu được cấu hình phù hợp.

- Báo cáo lịch sử giao dịch phải dùng snapshot giao dịch nếu có, không dùng dữ liệu Product hiện hành để viết lại lịch sử.

    

**Trạng thái lỗi cần xử lý**

|Trạng thái|Hành vi Reporting|
|---|---|
|Product đã xóa mềm|Vẫn có thể xuất hiện trong báo cáo lịch sử nếu có quyền|
|Custom field đã vô hiệu hóa|Có thể dùng dữ liệu cũ nếu báo cáo lịch sử cần|
|Thiếu snapshot giao dịch|Hiển thị thận trọng hoặc dùng dữ liệu fallback theo chính sách|
|Người dùng không có quyền xem giá|Không hiển thị dữ liệu giá nhạy cảm|
|Readiness chưa cập nhật|Hiển thị thời điểm cập nhật hoặc trạng thái cần đồng bộ nếu có|

---

### INT-06 — Onboarding → Product setup

**Mục tiêu:** Làm rõ cách Onboarding cung cấp ngành kinh doanh để Theme 2 khởi tạo cấu hình thông tin sản phẩm đặc thù ngành.

Onboarding không quản lý dữ liệu sản phẩm sau khi tenant đã vận hành. Onboarding chỉ cung cấp input ban đầu như ngành kinh doanh để Product khởi tạo custom field groups và custom fields mặc định.

**Ranh giới dữ liệu**

|Dữ liệu|Nguồn quản lý|Theme 2 làm gì|
|---|---|---|
|Ngành kinh doanh chính|Onboarding / Tenant setup|Dùng để chọn template custom fields|
|Custom Field Group|Product setup|Tạo theo template ngành|
|Custom Field|Product setup|Tạo theo template ngành|
|Product Custom Field Value|Product|Người dùng nhập theo từng sản phẩm|
|Thay đổi cấu hình sau onboarding|Product setup / Admin|Không thuộc Onboarding|

**Flow khởi tạo nhóm & trường thông tin bổ sung**

```mermaid
sequenceDiagram
    participant U as Admin / Owner
    participant O as Onboarding
    participant P as Product Setup
    participant CF as Custom Field Config

    U->>O: Chọn ngành kinh doanh
    O->>P: Gửi ngành kinh doanh của tenant

    alt Có template ngành
        P->>CF: Khởi tạo Custom Field Groups và Fields
        CF-->>P: Cấu hình field mặc định
        P-->>U: Hoàn tất setup thông tin ngành
    else Chưa có template ngành
        P-->>U: Không khởi tạo field đặc thù, cho phép cấu hình sau
    end```

**Quy tắc tích hợp**

- Ngành kinh doanh từ Onboarding chỉ dùng để khởi tạo template ban đầu.

- Template ngành không được hard-code vào Product entity.

- Tenant có thể chỉnh, thêm, vô hiệu hóa custom fields sau onboarding nếu có quyền.

- Đổi ngành sau onboarding không được tự động xóa custom field values đã có.

- Nếu ngành chưa có template, hệ thống vẫn cho tenant tiếp tục sử dụng Product với cấu hình cơ bản.

- Custom fields đã khởi tạo thuộc tenant hiện tại.

    

**Trạng thái lỗi cần xử lý**

|Trạng thái|Hành vi|
|---|---|
|Tenant chưa chọn ngành|Không khởi tạo custom fields đặc thù|
|Ngành chưa có template|Cho tiếp tục, admin có thể cấu hình sau|
|Template lỗi|Không chặn Product cơ bản; ghi nhận lỗi setup nếu cần|
|Đổi ngành sau khi có dữ liệu|Không xóa dữ liệu cũ; yêu cầu admin rà soát cấu hình|
|Field template trùng với field đã có|Bỏ qua, merge hoặc yêu cầu xử lý theo chính sách setup|

---

### Tổng kết Phụ lục D

Các integration diagram trong phụ lục này giúp chuẩn hóa ranh giới module:

|**Ranh giới**|**Cách hiểu chuẩn**|
|---|---|
|Product vs Inventory|Product quản lý stock mode; Inventory quản lý tồn kho nâng cao|
|Product vs Costing|Product quản lý base price mode; Costing tính Giá cơ sở nâng cao|
|Product vs Sales|Product cung cấp dữ liệu nền; Sales ghi nhận giao dịch và snapshot|
|Product vs Promotions|Product cung cấp khung giá; Promotions tính giá sau khuyến mãi|
|Product vs Reporting|Product cung cấp dữ liệu đọc; Reporting phân tích, không sửa Product|
|Onboarding vs Product setup|Onboarding cung cấp ngành; Product setup tạo custom fields theo template|

Một câu tóm tắt:

> Theme 2 là nguồn dữ liệu nền của sản phẩm,  
> 
> nhưng không thay thế các module chuyên trách về kho, giá vốn, bán hàng, khuyến mãi và báo cáo.
> 
> 

## Phụ lục E — Entity relationship diagram

Phụ lục E mô tả mô hình entity khái niệm của Theme 2. Đây là ERD ở mức nghiệp vụ, dùng để thống nhất cách hiểu giữa BA, UX và Dev. Khi thiết kế database vật lý, Dev có thể tách thêm bảng, thêm index, thêm audit field hoặc tối ưu theo kiến trúc hệ thống.

Nguyên tắc đọc ERD:

- `Product` là entity trung tâm của Theme 2.

- Các dữ liệu có vòng đời riêng nên tách khỏi `Product`.

- Các dữ liệu có thể đến từ module khác cần được tách bằng profile/source.

- Các dữ liệu dùng cho lịch sử giao dịch cần được module giao dịch lưu snapshot riêng.

- Tất cả entity nghiệp vụ đều thuộc phạm vi tenant.

    

---

### ERD-01 — Conceptual ERD tổng quan

```mermaid
erDiagram
    TENANT ||--o{ PRODUCT : owns
    TENANT ||--o{ CUSTOM_FIELD_GROUP : owns
    TENANT ||--o{ STORE_PRICE_RULE : owns

    PRODUCT ||--o{ PRODUCT_IMAGE : has
    PRODUCT ||--o{ PRODUCT_UNIT : has
    PRODUCT ||--|| PRODUCT_STOCK_PROFILE : has
    PRODUCT ||--|| PRODUCT_BASE_PRICE_PROFILE : has
    PRODUCT ||--|| PRODUCT_READINESS : has
    PRODUCT ||--o{ PRODUCT_CUSTOM_FIELD_VALUE : has
    PRODUCT ||--o{ PRODUCT_CHANGE_HISTORY : has

    PRODUCT_UNIT ||--o{ PRODUCT_UNIT_PRICE_BAND : has

    STORE_PRICE_RULE ||--o{ PRODUCT_UNIT_PRICE_BAND : suggests_or_applies

    CUSTOM_FIELD_GROUP ||--o{ CUSTOM_FIELD : contains
    CUSTOM_FIELD ||--o{ PRODUCT_CUSTOM_FIELD_VALUE : defines

    USER ||--o{ PRODUCT_CHANGE_HISTORY : performs```

---

### ERD-02 — Entity catalog

|**Entity**|**Vai trò**|
|---|---|
|`Product`|Hồ sơ trung tâm của sản phẩm|
|`Product Image`|Quản lý ảnh sản phẩm, ảnh đại diện và thứ tự hiển thị|
|`Product Unit`|Quản lý đơn vị cơ sở, đơn vị quy đổi và vai trò đơn vị|
|`Product Stock Profile`|Xác định sản phẩm dùng Basic stock hay Advanced stock|
|`Product Base Price Profile`|Xác định Giá cơ sở định giá được nhập thủ công hay đọc từ module Giá vốn|
|`Store Price Rule`|Quy tắc gợi ý giá theo cửa hàng hoặc tenant|
|`Product Unit Price Band`|Giá niêm yết và Giá sàn theo từng đơn vị bán|
|`Custom Field Group`|Nhóm thông tin bổ sung|
|`Custom Field`|Định nghĩa field đặc thù ngành|
|`Product Custom Field Value`|Giá trị custom field của từng sản phẩm|
|`Product Readiness`|Trạng thái/checklist readiness của sản phẩm|
|`Product Change History`|Lịch sử thay đổi quan trọng của sản phẩm|
|`Tenant`|Phạm vi dữ liệu của doanh nghiệp/người dùng|
|`User`|Người thực hiện thay đổi|
|`Store`|Tham chiếu ngoài nếu hệ thống quản lý nhiều cửa hàng|

---

### ERD-03 — Product

`Product` là entity trung tâm, lưu thông tin nhận diện và trạng thái kinh doanh của sản phẩm.

|**Field gợi ý**|**Ghi chú**|
|---|---|
|`id`|Khóa chính (UUID)|
|`reference_id`|Mã sản phẩm nội bộ, bắt buộc, unique per tenant (case-sensitive); hash tự động hoặc legacy explicit (`SP-0001`) — **không expose UI**|
|`tenant_id`|Phân tách dữ liệu theo tenant|
|`name`|Tên sản phẩm, bắt buộc|
|`trade_name`|Tên thương mại nếu có|
|`sku`|Mã SKU, unique trong tenant nếu có nhập|
|`barcode`|Mã barcode, unique trong tenant nếu có nhập|
|`description`|Mô tả sản phẩm|
|`note`|Ghi chú nội bộ|
|`business_status`|Đang KD / Ngừng KD|
|`deleted_at`|Dùng cho soft delete|
|`created_at`|Thời điểm tạo|
|`updated_at`|Thời điểm cập nhật|

Quan hệ chính:

|**Quan hệ**|**Diễn giải**|
|---|---|
|`Product` → `Product Image`|Một sản phẩm có nhiều ảnh|
|`Product` → `Product Unit`|Một sản phẩm có nhiều đơn vị|
|`Product` → `Product Stock Profile`|Một sản phẩm có một cấu hình tồn kho|
|`Product` → `Product Base Price Profile`|Một sản phẩm có một cấu hình Giá cơ sở|
|`Product` → `Product Readiness`|Một sản phẩm có một readiness summary hiện hành|
|`Product` → `Product Change History`|Một sản phẩm có nhiều dòng lịch sử thay đổi|

---

### ERD-04 — Product Image

`Product Image` tách khỏi `Product` để hỗ trợ nhiều ảnh, ảnh đại diện, thứ tự hiển thị và xóa mềm ảnh.

|**Field gợi ý**|**Ghi chú**|
|---|---|
|`id`|Khóa chính|
|`tenant_id`|Phân tách dữ liệu theo tenant|
|`product_id`|Sản phẩm sở hữu ảnh|
|`file_url`|Đường dẫn file ảnh|
|`is_primary`|Có phải ảnh đại diện không|
|`sort_order`|Thứ tự hiển thị|
|`status`|Active / inactive nếu cần|
|`deleted_at`|Xóa mềm ảnh nếu cần|
|`created_at`|Thời điểm tạo|

Quy tắc chính:

|Rule|Diễn giải|
|---|---|
|Một sản phẩm có thể có nhiều ảnh|Hỗ trợ quản lý hình ảnh tốt hơn MVP một ảnh|
|Mỗi sản phẩm nên có tối đa một ảnh đại diện|Nếu ảnh đại diện bị xóa, hệ thống chọn ảnh khác hoặc hiển thị placeholder|
|Ảnh không nên nằm trực tiếp trong `Product`|Tránh làm `Product` phình to và khó mở rộng|

---

### ERD-05 — Product Unit

`Product Unit` quản lý đơn vị cơ sở, đơn vị quy đổi và vai trò đơn vị trong nhập/bán/hiển thị.

|Field gợi ý|Ghi chú|
|---|---|
|`id`|Khóa chính|
|`tenant_id`|Phân tách dữ liệu theo tenant|
|`product_id`|Sản phẩm sở hữu đơn vị|
|`unit_name`|Tên đơn vị, ví dụ: Viên, Lọ, Hộp|
|`unit_code`|Mã đơn vị nếu có|
|`is_base_unit`|Có phải đơn vị cơ sở không|
|`conversion_rate_to_base`|Tỷ lệ quy đổi về đơn vị cơ sở|
|`is_sales_unit`|Có được dùng để bán không|
|`is_purchase_unit`|Có được dùng để nhập không|
|`is_display_unit`|Có phải đơn vị hiển thị mặc định không|
|`status`|Active / inactive|
|`created_at`|Thời điểm tạo|
|`updated_at`|Thời điểm cập nhật|

Quy tắc chính:

|**Rule**|**Diễn giải**|
|---|---|
|Mỗi sản phẩm có tối đa một đơn vị cơ sở active|Đơn vị cơ sở là gốc để diễn giải tồn kho và quy đổi|
|Đơn vị cơ sở có `conversion_rate_to_base = 1`|Các đơn vị khác quy đổi về đơn vị cơ sở|
|Đơn vị bán cần có price band|Nếu dùng để bán mà thiếu giá, readiness tạo blocker|
|Đơn vị đã phát sinh giao dịch không nên xóa cứng|Chỉ vô hiệu hóa để bảo toàn lịch sử|

---

### ERD-06 — Product Stock Profile

`Product Stock Profile` xác định cách Product quản lý hoặc đọc dữ liệu tồn kho.

|**Field gợi ý**|**Ghi chú**|
|---|---|
|`id`|Khóa chính|
|`tenant_id`|Phân tách dữ liệu theo tenant|
|`product_id`|Sản phẩm liên quan|
|`stock_mode`|Basic stock / Advanced stock|
|`basic_stock_quantity_base`|Tồn kho cơ bản (integer ≥ 0) nếu dùng Basic stock|
|`inventory_source_id`|Tham chiếu module Kho nếu dùng Advanced stock|
|`source_status`|Ready / source missing / stale nếu cần|
|`last_synced_at`|Thời điểm đồng bộ gần nhất nếu có|
|`created_at`|Thời điểm tạo|
|`updated_at`|Thời điểm cập nhật|

Quy tắc chính:

|**Rule**|**Diễn giải**|
|---|---|
|Basic stock|Product cho nhập/chỉnh tồn kho trực tiếp|
|Advanced stock|Product chỉ đọc stock summary từ module Kho|
|Không trộn hai nguồn hiện hành|Tránh hiển thị tồn kho cũ như tồn kho hiện tại|
|Khi chuyển sang Advanced stock|Basic stock cũ cần được bảo toàn dưới dạng lịch sử/snapshot|

---

### ERD-07 — Product Base Price Profile

`Product Base Price Profile` xác định nguồn Giá cơ sở định giá của sản phẩm.

|**Field gợi ý**|**Ghi chú**|
|---|---|
|`id`|Khóa chính|
|`tenant_id`|Phân tách dữ liệu theo tenant|
|`product_id`|Sản phẩm liên quan|
|`base_price_mode`|Manual base price / Costing-module base price|
|`manual_base_price`|Giá cơ sở nhập thủ công|
|`costing_source_id`|Tham chiếu module Giá vốn nếu có|
|`source_status`|Ready / source missing / stale nếu cần|
|`last_synced_at`|Thời điểm đồng bộ gần nhất nếu có|
|`created_at`|Thời điểm tạo|
|`updated_at`|Thời điểm cập nhật|

Quy tắc chính:

|Rule|Diễn giải|
|---|---|
|Manual base price|Product cho nhập/chỉnh Giá cơ sở định giá|
|Costing-module base price|Product chỉ đọc Giá cơ sở từ module Giá vốn|
|Theme 2 không tính giá vốn|FIFO, FILO, bình quân thuộc module Giá vốn|
|Giá cơ sở thay đổi|Có thể cần kiểm tra lại khung giá bán|

---

### ERD-08 — Store Price Rule

`Store Price Rule` là quy tắc gợi ý giá theo tenant hoặc cửa hàng. Rule này không phải giá chính thức của sản phẩm cho đến khi được áp dụng vào `Product Unit Price Band`.

|Field gợi ý|Ghi chú|
|---|---|
|`id`|Khóa chính|
|`tenant_id`|Phân tách dữ liệu theo tenant|
|`store_id`|Cửa hàng áp dụng nếu có|
|`name`|Tên quy tắc|
|`rule_type`|Markup / margin / fixed formula|
|`listed_price_formula`|Công thức gợi ý Giá niêm yết|
|`floor_price_formula`|Công thức gợi ý Giá sàn|
|`status`|Active / inactive|
|`created_at`|Thời điểm tạo|
|`updated_at`|Thời điểm cập nhật|

Quy tắc chính:

|Rule|Diễn giải|
|---|---|
|Rule chỉ tạo giá gợi ý|Không tự ghi đè price band nếu chưa xác nhận|
|Có thể áp dụng theo cửa hàng|Hỗ trợ mở rộng multi-store|
|Product Unit Price Band là giá chính thức|Sales/Promotions đọc price band, không đọc trực tiếp rule|

---

### ERD-09 — Product Unit Price Band

`Product Unit Price Band` lưu Giá niêm yết và Giá sàn theo từng đơn vị bán.

|Field gợi ý|Ghi chú|
|---|---|
|`id`|Khóa chính|
|`tenant_id`|Phân tách dữ liệu theo tenant|
|`product_id`|Sản phẩm liên quan|
|`product_unit_id`|Đơn vị bán liên quan|
|`store_id`|Cửa hàng áp dụng nếu có|
|`store_price_rule_id`|Rule đã dùng để gợi ý/áp dụng nếu có|
|`listed_price`|Giá niêm yết|
|`floor_price`|Giá sàn|
|`source_type`|Manual / rule-based|
|`status`|Active / inactive|
|`effective_from`|Thời điểm hiệu lực nếu cần|
|`effective_to`|Thời điểm hết hiệu lực nếu cần|
|`created_at`|Thời điểm tạo|
|`updated_at`|Thời điểm cập nhật|

Quy tắc chính:

|Rule|Diễn giải|
|---|---|
|Price band gắn với đơn vị bán|Cùng một sản phẩm có thể có giá khác nhau theo Lọ/Hộp/Thùng|
|Giá sàn không được lớn hơn Giá niêm yết|Validation lõi|
|Sales đọc Giá niêm yết và Giá sàn|Sales vẫn ghi nhận giá cuối cùng trên giao dịch|
|Promotions không ghi đè price band|Giá sau khuyến mãi thuộc Promotions/Sales|

---

### ERD-10 — Custom Field Group và Custom Field

`Custom Field Group` và `Custom Field` giúp Theme 2 mở rộng thông tin sản phẩm theo ngành mà không hard-code vào `Product`.

|Entity|Field gợi ý|Ghi chú|
|---|---|---|
|`Custom Field Group`|`id`|Khóa chính|
|`Custom Field Group`|`tenant_id`|Phân tách dữ liệu theo tenant|
|`Custom Field Group`|`icon`|Lưu unicode icon hoặc mã icon được hệ thống hỗ trợ. Icon dùng để hiển thị card nhóm thông tin trong Product Control Center và các màn liên quan. Hệ thống cung cấp bộ unicode icons giới hạn để đảm bảo hiển thị nhất quán.|
|`Custom Field Group`|`name`|Tên nhóm, ví dụ: Thông tin thuốc|
|`Custom Field Group`|`description`|Mô tả|
|`Custom Field Group`|`sort_order`|Thứ tự hiển thị|
|`Custom Field Group`|`status`|Active / inactive|
|`Custom Field`|`id`|Khóa chính|
|`Custom Field`|`group_id`|Thuộc nhóm nào|
|`Custom Field`|`tenant_id`|Phân tách dữ liệu theo tenant|
|`Custom Field`|`name`|Tên field|
|`Custom Field`|`field_type`|Text / number / date / boolean / single select|
|`Custom Field`|`options`|Danh sách option nếu là select|
|`Custom Field`|`is_required`|Có bắt buộc không|
|`Custom Field`|`is_searchable`|Có tham gia tìm kiếm không|
|`Custom Field`|`is_filterable`|Có tham gia filter không|
|`Custom Field`|`display_on_list`|Có hiển thị ở danh sách không|
|`Custom Field`|`sort_order`|Thứ tự field|
|`Custom Field`|`status`|Active / inactive|

Quy tắc chính:

|Rule|Diễn giải|
|---|---|
|Không hard-code field ngành vào Product|Dễ mở rộng sang ngành mới|
|Field inactive không dùng nhập mới|Nhưng dữ liệu cũ vẫn cần bảo toàn|
|Field đã có dữ liệu không nên xóa cứng|Tránh mất lịch sử sản phẩm|
|Required field có thể tạo readiness blocker|Nếu được cấu hình ảnh hưởng readiness|

---

### ERD-11 — Product Custom Field Value

`Product Custom Field Value` lưu giá trị custom field theo từng sản phẩm.

|Field gợi ý|Ghi chú|
|---|---|
|`id`|Khóa chính|
|`tenant_id`|Phân tách dữ liệu theo tenant|
|`product_id`|Sản phẩm liên quan|
|`custom_field_id`|Field được định nghĩa|
|`value_text`|Giá trị dạng text nếu dùng|
|`value_number`|Giá trị dạng số nếu dùng|
|`value_date`|Giá trị dạng ngày nếu dùng|
|`value_boolean`|Giá trị đúng/sai nếu dùng|
|`value_option`|Option được chọn nếu là single select|
|`created_at`|Thời điểm tạo|
|`updated_at`|Thời điểm cập nhật|

Quy tắc chính:

|Rule|Diễn giải|
|---|---|
|Mỗi product-field có tối đa một giá trị hiện hành|Tránh trùng dữ liệu|
|Value phải đúng kiểu dữ liệu field|Validate theo `field_type`|
|Field inactive vẫn giữ value cũ|Có thể hiển thị read-only nếu cần|
|Search/filter chỉ dùng field được cấu hình|Không tự động search/filter tất cả custom values|

---

### ERD-12 — Product Readiness

`Product Readiness` là read model/cache hoặc trạng thái tính toán giúp UI hiển thị sản phẩm đang thiếu gì.

|Field gợi ý|Ghi chú|
|---|---|
|`id`|Khóa chính|
|`tenant_id`|Phân tách dữ liệu theo tenant|
|`product_id`|Sản phẩm liên quan|
|`readiness_status`|Trạng thái tổng quan|
|`ready_for_purchase`|Có đủ điều kiện nhập hàng không|
|`ready_for_sale`|Có đủ điều kiện bán hàng không|
|`blocker_count`|Số blocker hiện tại|
|`primary_blocker_code`|Blocker ưu tiên cao nhất|
|`blockers_json`|Danh sách blocker nếu dùng dạng cache|
|`calculated_at`|Thời điểm tính readiness|

Quy tắc chính:

|Rule|Diễn giải|
|---|---|
|Readiness không phải dữ liệu người dùng nhập tay|Được tính từ dữ liệu sản phẩm hiện hành|
|Có thể là cache/read model|Miễn là luôn nhất quán với dữ liệu nguồn|
|Có nhiều blocker cùng lúc|Danh sách hiển thị đầy đủ ở Product Control Center|
|Danh sách chỉ nên hiển thị blocker ưu tiên|Tránh làm UI quá tải|

---

### ERD-13 — Product Change History

`Product Change History` ghi nhận các thay đổi quan trọng của sản phẩm ở mức nghiệp vụ.

|Field gợi ý|Ghi chú|
|---|---|
|`id`|Khóa chính|
|`tenant_id`|Phân tách dữ liệu theo tenant|
|`product_id`|Sản phẩm liên quan|
|`changed_by_user_id`|Người thực hiện nếu có|
|`change_type`|Loại thay đổi|
|`target_entity`|Entity bị thay đổi|
|`target_id`|ID bản ghi liên quan nếu có|
|`old_value`|Giá trị cũ nếu lưu được|
|`new_value`|Giá trị mới nếu lưu được|
|`source`|User / system / integration|
|`reason`|Lý do nếu có|
|`created_at`|Thời điểm thay đổi|

Các loại thay đổi nên ghi nhận:

|Change type|Ví dụ|
|---|---|
|`PRODUCT_CREATED`|Tạo sản phẩm mới|
|`PROFILE_UPDATED`|Sửa tên, SKU, barcode|
|`IMAGE_UPDATED`|Thêm/xóa/đổi ảnh đại diện|
|`UNIT_UPDATED`|Thêm/sửa/vô hiệu hóa đơn vị|
|`BASE_UNIT_CHANGED`|Đổi đơn vị cơ sở|
|`BASIC_STOCK_UPDATED`|Chỉnh tồn kho cơ bản|
|`BASE_PRICE_UPDATED`|Chỉnh Giá cơ sở định giá|
|`PRICE_BAND_UPDATED`|Chỉnh Giá niêm yết/Giá sàn|
|`CUSTOM_FIELD_UPDATED`|Sửa thông tin bổ sung|
|`STATUS_CHANGED`|Ngừng KD / Kinh doanh lại|
|`SOFT_DELETED`|Xóa mềm sản phẩm|
|`RESTORED`|Khôi phục sản phẩm|

---

### ERD-14 — Relationship rules

|Quan hệ|Cardinality|Rule|
|---|---|---|
|Tenant → Product|1-n|Mỗi sản phẩm thuộc một tenant|
|Product → Product Image|1-n|Một sản phẩm có nhiều ảnh|
|Product → Product Unit|1-n|Một sản phẩm có nhiều đơn vị|
|Product → Product Stock Profile|1-1|Một sản phẩm có một stock profile hiện hành|
|Product → Product Base Price Profile|1-1|Một sản phẩm có một base price profile hiện hành|
|Product Unit → Product Unit Price Band|1-n|Một đơn vị bán có thể có nhiều price band theo store/effective time nếu cần|
|Store Price Rule → Product Unit Price Band|1-n|Một rule có thể được dùng để gợi ý nhiều price band|
|Custom Field Group → Custom Field|1-n|Một group có nhiều field|
|Product + Custom Field → Product Custom Field Value|1-1|Mỗi sản phẩm có tối đa một value hiện hành cho mỗi field|
|Product → Product Readiness|1-1|Một sản phẩm có một readiness summary hiện hành|
|Product → Product Change History|1-n|Một sản phẩm có nhiều dòng lịch sử thay đổi|

---

### ERD-15 — External references

Một số entity được tham chiếu nhưng không thuộc phạm vi quản lý chính của Theme 2.

|External entity|Module sở hữu|Theme 2 dùng để|
|---|---|---|
|`Tenant`|Tenant / Account setup|Phân tách dữ liệu|
|`User`|User / IAM|Ghi nhận người thực hiện thay đổi|
|`Store`|Store / Branch setup|Áp dụng price rule hoặc price band theo cửa hàng|
|`Inventory Source`|Inventory / Kho|Đọc stock summary khi dùng Advanced stock|
|`Costing Source`|Costing / Giá vốn|Đọc Giá cơ sở định giá khi dùng Costing-module|
|`Sales Order`|Sales|Lưu snapshot giao dịch, không thuộc Product|
|`Promotion Campaign`|Promotions|Tính giá sau khuyến mãi, không thuộc Product|

---

### Tổng kết Phụ lục E

Mô hình entity của Theme 2 cần giữ được hai mục tiêu cùng lúc:

|Mục tiêu|Cách mô hình đáp ứng|
|---|---|
|Foundation đơn giản|Product có thể dùng với Basic stock, Manual base price và price band cơ bản|
|Growth mở rộng|Có sẵn profile/source để đọc Inventory, Costing, Promotions và dữ liệu ngành|
|Không hard-code ngành|Dùng Custom Field Group / Custom Field / Product Custom Field Value|
|Không phá lịch sử|Dùng soft delete, inactive state, Change History và snapshot ở module giao dịch|
|Không gom tất cả vào Product|Tách image, unit, stock profile, base price profile, price band, readiness và history|

Một câu tóm tắt:

> Product là trung tâm,  
> 
> nhưng các dữ liệu có vòng đời riêng phải được tách thành entity riêng.
> 
> 

## Phụ lục F — Permission matrix

Phụ lục F mô tả ma trận phân quyền khái niệm cho Theme 2. Đây là bản đề xuất ở mức SRS, dùng để thống nhất hành vi giữa BA, UX và Dev. Khi triển khai thật, tên role và permission code có thể được điều chỉnh theo mô hình IAM chung của Mosaic Retail.

Nguyên tắc chung:

- Permission phải được kiểm tra ở cả UI và API.

- UI không nên hiển thị hành động mà người dùng chắc chắn không có quyền thực hiện.

- Dữ liệu nhạy cảm như giá, tồn kho, lịch sử thay đổi và sản phẩm đã xóa cần có quyền xem riêng nếu cần.

- Permission cần xét thêm trạng thái sản phẩm, stock mode, base price mode và tenant hiện tại.

- Không có permission nào được vượt qua tenant boundary.

    

---

### PER-01 — Role catalog đề xuất

|Role|Vai trò nghiệp vụ|
|---|---|
|`Owner`|Chủ doanh nghiệp hoặc người chịu trách nhiệm cao nhất trong tenant|
|`Admin`|Người quản trị hệ thống trong tenant|
|`Product Manager`|Người quản lý dữ liệu sản phẩm|
|`Sales`|Người bán hàng, cần tra cứu và chọn sản phẩm|
|`Accountant`|Người phụ trách giá, giá vốn, dữ liệu kế toán liên quan|
|`Warehouse`|Người phụ trách tồn kho, nhập/xuất/kiểm kê|
|`Viewer`|Người chỉ có quyền xem dữ liệu được cho phép|

Role catalog này không nhất thiết là role cuối cùng của hệ thống. Khi Mosaic Retail có mô hình phân quyền chung, các quyền trong phụ lục này có thể được map sang permission code cụ thể.

---

### PER-02 — Ký hiệu trong ma trận quyền

|Ký hiệu|Ý nghĩa|
|---|---|
|`Y`|Được phép thực hiện|
|`R`|Chỉ được xem|
|`N`|Không được phép|
|`P`|Phụ thuộc chính sách tenant hoặc cấu hình gói|
|`M`|Thực hiện ở module chuyên trách, không thực hiện trực tiếp trong Product|
|`S`|Dữ liệu nhạy cảm, cần quyền xem riêng|

---

### PER-03 — Permission matrix tổng quan

|**Hành động**|**Owner**|**Admin**|**Product Manager**|**Sales**|**Accountant**|**Warehouse**|**Viewer**|
|---|---|---|---|---|---|---|---|
|Xem danh sách sản phẩm|Y|Y|Y|Y|Y|Y|R|
|Xem chi tiết sản phẩm|Y|Y|Y|Y|Y|Y|R|
|Tìm kiếm / quét barcode|Y|Y|Y|Y|Y|Y|R|
|Tạo sản phẩm mới|Y|Y|Y|N|P|P|N|
|Sửa hồ sơ sản phẩm|Y|Y|Y|N|P|N|N|
|Quản lý ảnh sản phẩm|Y|Y|Y|N|N|N|N|
|Quản lý đơn vị đo lường|Y|Y|Y|N|P|P|N|
|Đổi đơn vị cơ sở|Y|Y|P|N|P|P|N|
|Nhập/chỉnh tồn kho cơ bản|Y|Y|P|N|N|Y|N|
|Xem tồn kho|Y|Y|Y|P|P|Y|P|
|Xem tồn kho nâng cao từ Kho|Y|Y|R|P|P|R|P|
|Nhập/chỉnh Giá cơ sở thủ công|Y|Y|P|N|Y|N|N|
|Xem Giá cơ sở|Y|Y|S|N|Y|N|N|
|Xem Giá cơ sở từ module Giá vốn|Y|Y|S|N|R|N|N|
|Thiết lập Giá niêm yết / Giá sàn|Y|Y|P|N|Y|N|N|
|Xem Giá niêm yết|Y|Y|Y|Y|Y|P|P|
|Xem Giá sàn|Y|Y|S|N|Y|N|N|
|Quản lý Store Price Rule|Y|Y|P|N|Y|N|N|
|Nhập/chỉnh custom field values|Y|Y|Y|N|P|N|N|
|Cấu hình custom field groups/fields|Y|Y|P|N|N|N|N|
|Ngừng kinh doanh sản phẩm|Y|Y|Y|N|P|N|N|
|Kinh doanh lại sản phẩm|Y|Y|Y|N|P|N|N|
|Xóa mềm sản phẩm|Y|Y|P|N|N|N|N|
|Khôi phục sản phẩm đã xóa|Y|Y|P|N|N|N|N|
|Xem sản phẩm đã xóa|Y|Y|P|N|P|N|N|
|Xem Product Change History|Y|Y|P|N|S|P|N|

Ghi chú:

- `Product Manager` có thể được phép quản lý giá ở doanh nghiệp nhỏ, nhưng ở doanh nghiệp có kiểm soát chặt, quyền này nên thuộc `Accountant` hoặc `Owner`.

- `Warehouse` chỉ nên chỉnh tồn kho trong Basic stock; nếu dùng Advanced stock, thao tác tồn kho thuộc module Kho.

- `Sales` cần xem Giá niêm yết để bán hàng, nhưng không nhất thiết được xem Giá sàn hoặc Giá cơ sở.

- `Viewer` chỉ xem dữ liệu không nhạy cảm theo chính sách tenant.

    

---

### PER-04 — Permission theo nhóm dữ liệu

|Nhóm dữ liệu|Quyền xem|Quyền sửa|Ghi chú|
|---|---|---|---|
|Hồ sơ sản phẩm|Hầu hết role vận hành|Owner, Admin, Product Manager|Sales thường chỉ xem|
|Ảnh sản phẩm|Hầu hết role vận hành|Owner, Admin, Product Manager|Ảnh không nên do Sales sửa trực tiếp|
|Đơn vị đo lường|Product, Sales, Warehouse cần xem|Owner, Admin, Product Manager|Đổi đơn vị cơ sở cần quyền cao hơn|
|Tồn kho cơ bản|Warehouse, Product, Owner/Admin|Warehouse, Owner/Admin|Chỉ áp dụng Basic stock|
|Tồn kho nâng cao|Theo quyền Inventory|Module Kho|Product chỉ đọc summary|
|Giá cơ sở định giá|Owner, Admin, Accountant|Accountant, Owner/Admin|Là dữ liệu nhạy cảm|
|Giá niêm yết|Sales, Product, Accountant|Accountant, Owner/Admin, Product Manager nếu được phân quyền|Dùng cho bán hàng|
|Giá sàn|Owner, Admin, Accountant|Accountant, Owner/Admin|Là dữ liệu kiểm soát nhạy cảm|
|Custom fields|Product, Sales nếu cần xem|Product Manager, Admin|Tùy field có nhạy cảm hay không|
|Readiness|Hầu hết role vận hành|Không sửa tay|Readiness là calculated state|
|Change History|Owner, Admin, role được cấp quyền|Không sửa|Lịch sử chỉ append-only|
|Sản phẩm đã xóa|Owner, Admin, role được cấp quyền|Restore/delete theo quyền riêng|Không hiển thị mặc định|

---

### PER-05 — Permission theo trạng thái sản phẩm

|Trạng thái sản phẩm|Hành vi phân quyền|
|---|---|
|`ACTIVE` / Đang KD|Cho phép thao tác bình thường theo quyền|
|`INACTIVE` / Ngừng KD|Cho xem và chỉnh dữ liệu nền theo quyền; không dùng trong giao dịch mới mặc định|
|`SOFT_DELETED` / Đã xóa|Không hiển thị mặc định; chỉ người có quyền mới xem/khôi phục được|
|Đủ dữ liệu nhưng ngừng KD|Không được bán dù readiness dữ liệu đủ|
|Thiếu readiness nhưng đang KD|Có thể hiển thị trong danh sách, nhưng Sales bị chặn hoặc cảnh báo khi chọn|
|Đang có giao dịch mở|Một số thao tác như xóa, đổi đơn vị cơ sở, ngừng kinh doanh có thể bị chặn hoặc cảnh báo|
|Đã phát sinh lịch sử|Không được xóa cứng qua UI vận hành thông thường|

Nguyên tắc quan trọng:

- Trạng thái kinh doanh không thay thế permission.

- Permission không thay thế readiness.

- Readiness không thay thế kiểm soát giao dịch trong Sales/Inventory.

- Sản phẩm đã xóa mềm không được dùng trong giao dịch mới, kể cả người dùng có quyền cao.

    

---

### PER-06 — Permission theo source/mode

|Mode / Source|Hành vi permission|
|---|---|
|`Basic stock`|Product có thể cho chỉnh tồn kho cơ bản nếu người dùng có quyền|
|`Advanced stock`|Product chỉ đọc stock summary; chỉnh tồn kho thuộc module Kho|
|`Manual base price`|Product có thể cho chỉnh Giá cơ sở nếu người dùng có quyền|
|`Costing-module base price`|Product chỉ đọc Giá cơ sở; chỉnh/tính Giá cơ sở thuộc module Giá vốn|
|`Manual price band`|Product cho chỉnh Giá niêm yết/Giá sàn nếu có quyền|
|`Rule-based price suggestion`|Store Price Rule chỉ gợi ý; áp dụng/ghi đè price band cần xác nhận và quyền phù hợp|
|`Custom field active`|Cho nhập/chỉnh value nếu có quyền|
|`Custom field inactive`|Không cho nhập mới; dữ liệu cũ có thể xem read-only theo quyền|

Ví dụ kiểm soát UI:

|Tình huống|Hành động UI|
|---|---|
|Người dùng có quyền Warehouse, sản phẩm dùng Basic stock|Hiển thị “Chỉnh tồn kho”|
|Người dùng có quyền Warehouse, sản phẩm dùng Advanced stock|Hiển thị “Xem trong Kho” nếu có quyền module Kho|
|Người dùng có quyền Accountant, sản phẩm dùng Manual base price|Hiển thị “Chỉnh Giá cơ sở”|
|Người dùng có quyền Accountant, sản phẩm dùng Costing-module base price|Hiển thị Giá cơ sở read-only và link sang module Giá vốn nếu có|
|Người dùng Sales mở Product Control Center|Hiển thị dữ liệu cần bán hàng, ẩn hành động chỉnh sửa|
|Người dùng không có quyền xem Giá sàn|Không hiển thị Giá sàn, kể cả qua direct URL/API|

---

### PER-07 — Permission theo hành động nguy hiểm

Các hành động dưới đây cần kiểm soát chặt hơn thao tác sửa thông thường.

|Hành động|Kiểm soát bắt buộc|
|---|---|
|Đổi đơn vị cơ sở|Cần quyền cao, preview tác động, xác nhận rõ|
|Chỉnh tồn kho cơ bản|Cần quyền tồn kho, ghi lịch sử, xử lý cập nhật đồng thời|
|Chỉnh Giá cơ sở|Cần quyền giá/kế toán, ghi lịch sử, cảnh báo ảnh hưởng khung giá|
|Chỉnh Giá sàn|Cần quyền kiểm soát giá, không cho Sales thường sửa|
|Ngừng kinh doanh|Cần xác nhận, cảnh báo nếu còn tồn kho/giao dịch mở|
|Kinh doanh lại|Cần kiểm tra readiness hiện tại|
|Xóa mềm|Cần quyền cao, kiểm tra dữ liệu phụ thuộc, xác nhận|
|Khôi phục|Cần kiểm tra trùng SKU/barcode và tính lại readiness|
|Cấu hình custom field|Cần quyền admin/product setup, không làm mất dữ liệu cũ|
|Xem lịch sử giá/tồn kho|Có thể cần quyền riêng vì nhạy cảm|

Nguyên tắc UX:

- Hành động nguy hiểm không nên nằm lẫn trong nhóm hành động thường.

- Cần hiển thị hậu quả nghiệp vụ trước khi xác nhận.

- Cần nói rõ dữ liệu nào được giữ lại và dữ liệu nào bị ảnh hưởng.

- Sau khi thực hiện, hệ thống phải ghi Product Change History.

    

---

### PER-08 — UI contract cho permission

|Tình huống|Hành vi UI|
|---|---|
|Không có quyền xem dữ liệu|Không hiển thị dữ liệu|
|Có quyền xem nhưng không có quyền sửa|Hiển thị read-only|
|Không có quyền thực hiện action|Ẩn action hoặc disable kèm lý do|
|Action bị chặn do trạng thái sản phẩm|Hiển thị lý do nghiệp vụ|
|Action bị chặn do mode/source|Điều hướng sang module đúng nếu người dùng có quyền|
|Direct URL tới màn không có quyền|Từ chối truy cập|
|Dữ liệu nhạy cảm bị ẩn|Không để lộ qua tooltip, export, API response hoặc log UI|
|Người dùng vừa mất quyền khi đang thao tác|Chặn lưu và yêu cầu tải lại quyền hiện tại|

Thông điệp UI nên dùng ngôn ngữ nghiệp vụ:

|Không nên|Nên|
|---|---|
|`403 Forbidden`|Bạn không có quyền thực hiện hành động này|
|`Invalid state`|Sản phẩm đang ngừng kinh doanh nên không thể dùng trong giao dịch mới|
|`Source missing`|Chưa có nguồn tồn kho từ module Kho|
|`Permission denied`|Bạn cần quyền quản lý giá để chỉnh Giá sàn|
|`Readonly mode`|Dữ liệu này được lấy từ module Giá vốn nên không chỉnh trực tiếp tại Product|

---

### PER-09 — API contract cho permission

|Quy tắc API|Diễn giải|
|---|---|
|Kiểm tra tenant|Mọi API phải kiểm tra `tenant_id`|
|Kiểm tra permission|Không dựa vào UI để bảo vệ dữ liệu|
|Kiểm tra status/mode|Permission đủ nhưng trạng thái/mode không phù hợp vẫn phải chặn|
|Không trả dữ liệu nhạy cảm nếu thiếu quyền|Ví dụ Giá cơ sở, Giá sàn, lịch sử giá, tồn kho|
|Không cho mutate dữ liệu thuộc module khác|Product API không chỉnh Advanced stock hoặc Costing-module base price|
|Ghi history sau mutation quan trọng|Tạo, sửa, đổi đơn vị, chỉnh tồn kho, chỉnh giá, đổi trạng thái, xóa/khôi phục|
|Xử lý cập nhật đồng thời|API cần chống ghi đè im lặng|
|Thông báo lỗi có ý nghĩa nghiệp vụ|Trả error code đủ rõ để UI hiển thị đúng|

Error code gợi ý:

|Error code|Ý nghĩa|
|---|---|
|`PRODUCT_PERMISSION_DENIED`|Người dùng không có quyền với hành động Product|
|`PRODUCT_TENANT_MISMATCH`|Dữ liệu không thuộc tenant hiện tại|
|`PRODUCT_STATUS_NOT_ALLOWED`|Trạng thái sản phẩm không cho thực hiện hành động|
|`PRODUCT_MODE_NOT_ALLOWED`|Mode/source không cho chỉnh trực tiếp|
|`PRODUCT_SENSITIVE_DATA_DENIED`|Không có quyền xem dữ liệu nhạy cảm|
|`PRODUCT_DIRECT_EDIT_BLOCKED`|Dữ liệu phải chỉnh ở module chuyên trách|
|`PRODUCT_CONCURRENT_UPDATE`|Dữ liệu đã thay đổi bởi người khác|
|`PRODUCT_DELETE_BLOCKED`|Không đủ điều kiện xóa sản phẩm|
|`PRODUCT_RESTORE_BLOCKED`|Không đủ điều kiện khôi phục sản phẩm|

---

### Tổng kết Phụ lục F

Permission của Theme 2 cần kiểm soát theo nhiều lớp:

|Lớp kiểm soát|Mục tiêu|
|---|---|
|Tenant|Không lẫn dữ liệu giữa các doanh nghiệp|
|Role/permission|Ai được xem, tạo, sửa, xóa, khôi phục|
|Data sensitivity|Giá, tồn kho, lịch sử có thể cần quyền riêng|
|Product status|Đang KD, Ngừng KD, Đã xóa ảnh hưởng hành động|
|Readiness|Dữ liệu chưa đủ thì chặn/cảnh báo nghiệp vụ|
|Source/mode|Dữ liệu thuộc Product hay module chuyên trách|
|History|Thay đổi quan trọng phải có truy vết|

Một câu tóm tắt:

> Permission trong Theme 2 không chỉ trả lời “ai được làm gì”,  
> 
> mà còn phải xét “sản phẩm đang ở trạng thái nào” và “dữ liệu này thuộc nguồn nào”.
> 
>
