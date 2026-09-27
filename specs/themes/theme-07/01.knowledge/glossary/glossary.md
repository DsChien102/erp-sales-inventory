---
id: GLOSSARY
type: glossary
theme: theme-07
title: "Danh mục thuật ngữ quản lý tồn kho, giá vốn và định giá bán"
owner: BA
status: FROZEN
source_baseline: v3.12.0
---
# Danh mục thuật ngữ quản lý tồn kho, giá vốn và định giá bán
Tài liệu này thống nhất cách dùng thuật ngữ trong Quyết định nghiệp vụ, bộ bài wiki và SRS. **Thuật ngữ tiếng Việt là tên ưu tiên trên giao diện và tài liệu nghiệp vụ**; tiếng Anh, enum và mã lỗi được giữ để đối chiếu với mô hình dữ liệu, hỗ trợ và tích hợp kỹ thuật, không dùng thay lời giải thích cho người dùng.

## 1. Phạm vi, tổ chức và quyền sở hữu dữ liệu
| Thuật ngữ tiếng Việt | Tiếng Anh tương đương | Giải nghĩa | Ví dụ | Ghi chú |
|---|---|---|---|---|
| Đơn vị vận hành | Tenant | Phạm vi tổ chức độc lập sở hữu dữ liệu, chính sách và sổ tồn kho. | Công ty A và B dùng cùng nền tảng nhưng có sổ tồn riêng. | Mọi khóa dữ liệu phải nằm trong Đơn vị vận hành. |
| Cửa hàng | Store | Đơn vị bán hàng và bối cảnh thương mại của giao dịch. | Nhân viên tại quầy và chủ cửa hàng trên đường cùng bán cho một cửa hàng. | Phase 1 có một cửa hàng hoạt động. |
| Kho | Warehouse | Nơi quản lý tồn vật lý ở cấp thấp nhất của phạm vi hiện tại. | Kho mặc định giữ 200 hộp vaccine. | Phase 1 có một kho hoạt động; chưa có bin/kệ. |
| Quan hệ cửa hàng–kho | Store–warehouse assignment | Quan hệ cấp quyền cho cửa hàng sử dụng một kho. | Cửa hàng A được phép bán từ kho W01. | Dữ liệu mở rộng nhiều–nhiều; Phase 1 chỉ có một quan hệ hoạt động. |
| Kho mặc định | Default warehouse | Kho được hệ thống tự điền và máy chủ kiểm tra cho giao dịch khi người dùng không phải lựa chọn. | Mọi đơn Phase 1 tự dùng W01 nhưng dữ liệu vẫn lưu `warehouse_id`. | Không có bộ chọn kho trong Phase 1; không hard-code ID trong mã nguồn. |
| Sản phẩm | Product | Hàng hóa do miền Sản phẩm sở hữu, được tồn kho tham chiếu bằng ID và phiên bản. | Vaccine P01 có đơn vị cơ sở là lọ và tracking mode là LOT. | Kho không tự tạo master sản phẩm. |
| Dữ liệu chủ | Master data | Dữ liệu nền có thẩm quyền như sản phẩm, đơn vị tính, cửa hàng và kho. | File đầu kỳ có mã kho lạ bị từ chối. | Không tự sinh master để “cho chạy được”. |
| Chủ sở hữu dữ liệu | Data owner | Miền có quyền tạo, thay đổi và công bố một loại dữ liệu. | Miền Sản phẩm sở hữu tracking policy. | Khác với miền chỉ đọc và thực thi. |
| Dữ liệu có thẩm quyền | Authoritative data | Dữ liệu được owner công bố và dùng làm căn cứ chính thức. | Tỷ lệ 1 hộp bằng 10 lọ được chụp khi operation khóa payload. | Có version và thời điểm hiệu lực. |
| Dữ liệu tham chiếu | Referenced data | Dữ liệu thuộc miền khác mà kho chỉ giữ ID, version hoặc snapshot cần thiết. | Operation giữ product_id và UOM version. | Không chuyển ownership sang kho. |
| Dữ liệu dẫn xuất | Derived data | Kết quả có thể tính hoặc dựng lại từ Dữ liệu gốc. | Tồn khả dụng hoặc danh sách bước tiếp theo được suy ra từ trạng thái, quyền và hợp đồng. | Không tự trở thành nguồn commit hoặc tạo hành động mới. |
| Cổng quyền sở hữu hàng | Ownership gate | Điều kiện xác nhận hàng đã thuộc doanh nghiệp trước khi nhập tồn sở hữu. | Hàng ký gửi chưa chuyển quyền sở hữu không được nhập kho sở hữu. | Điều kiện xác thực do nguồn mua/nhận cung cấp. |
| Hàng ký gửi | Consigned goods | Hàng của bên giao đặt tại điểm bán nhưng chưa thuộc sở hữu bên nhận. | Nhà cung cấp đặt 50 hộp tại cửa hàng và chỉ thu tiền sau khi bán. | Ngoài Phase 1. |
| Hàng demo | Demo stock | Hàng thuộc doanh nghiệp, còn trong tồn vật lý và giá trị nhưng không khả dụng để bán. | Hai máy được chuyển sang trạng thái DEMO. | Có thể chuyển lại bằng operation hợp lệ. |

## 2. Số lượng, trạng thái và khả dụng
| Thuật ngữ tiếng Việt | Tiếng Anh tương đương | Giải nghĩa | Ví dụ | Ghi chú |
|---|---|---|---|---|
| <a id="term-ton-vat-ly"></a>Tồn vật lý | Physical stock | Toàn bộ hàng thuộc doanh nghiệp đang hiện diện trong kho, kể cả chưa bán được. | 100 lọ gồm 80 bán được, 10 chờ giá và 10 hỏng. | Tổng vật lý là 100. |
| <a id="term-luong-du-dieu-kien-ban"></a>Lượng đủ điều kiện bán | Sellable-eligible quantity | Phần tồn vật lý thỏa trạng thái, dữ liệu lô/hạn và chính sách bán. | Lô hết hạn bị loại khỏi lượng đủ điều kiện. | Chưa trừ reservation. |
| <a id="term-luong-da-giu"></a>Lượng đã giữ | Reserved quantity | Lượng đã cam kết cho đơn nhưng chưa rời kho. | Đơn online giữ 12 lọ tại kho mặc định. | Không làm giảm tồn vật lý. |
| <a id="term-ton-kha-dung"></a>Tồn khả dụng | Available stock | Lượng còn có thể cam kết bán: lượng đủ điều kiện bán trừ lượng đã giữ. | 80 đủ điều kiện trừ 20 đã giữ còn 60 khả dụng. | Dùng dữ liệu giao dịch hiện hành khi commit. |
| Khóa số dư | Balance key | Tổ hợp định danh một số dư gồm tenant, sản phẩm, kho, trạng thái và lô nếu áp dụng. | P01, W01, SELLABLE, lot L01 khác lot L02. | Không có serial trong Phase 1. |
| <a id="term-so-du-hien-hanh"></a>Số dư hiện hành | Transactional balance | Số lượng hiện tại tại một khóa số dư, được cập nhật nguyên tử cùng movement. | Balance của P01/L01 là 83 lọ. | Có thể dựng lại từ ledger. |
| Trạng thái tồn kho | Inventory state | Phân loại cho biết lượng hàng được phép tham gia hoạt động nào. | DAMAGED còn vật lý nhưng không bán được. | Đổi trạng thái bằng operation. |
| Bán được | Sellable | Trạng thái cho phép tham gia kiểm tra khả dụng nếu không bị chặn khác. | Lô đủ dữ liệu, còn hạn và ở SELLABLE. | Không đồng nghĩa chắc chắn còn available. |
| Chờ chốt giá | Valuation pending | Hàng đã nhận và thuộc doanh nghiệp nhưng giá mua trực tiếp chưa đủ căn cứ. | Nhận 30 hộp, vật lý tăng 30 nhưng khả dụng tăng 0. | Mã kỹ thuật `VALUATION_PENDING`. |
| Chờ phân loại hàng trả | Return pending classification | Hàng khách trả đã nhận vật lý nhưng chưa xác định bán lại, hỏng hay hết hạn. | Nhận trả 3 hộp làm vật lý tăng 3, available chưa tăng. | Mã kỹ thuật có thể rút gọn trong model. |
| Cách ly | Quarantined | Hàng tạm thời bị tách khỏi luồng bán theo lý do nghiệp vụ. | Lô nghi sai nhãn được cách ly. | Không phải bước kiểm tra chất lượng nhập riêng. |
| Hư hỏng | Damaged | Hàng hỏng còn hiện diện vật lý, chờ xử lý. | Bốn hộp vỡ chỉ giảm vật lý khi tiêu hủy hoàn tất. | Không tự ghi giảm. |
| Hết hạn | Expired | Điều kiện không bán được xác định theo hạn dùng và ngày nghiệp vụ. | Lô hết hạn sau cuối ngày 31/8. | Availability phải chặn ngay, không chờ tác vụ nền. |
| Cận hạn | Near expiry | Chỉ báo dẫn xuất theo số ngày mặc định của đơn vị vận hành hoặc ghi đè theo sản phẩm. | Lô còn 20 ngày trong ngưỡng 30 ngày. | Hành động `WARN` hoặc `BLOCK_SALE`; không phải thực thể cảnh báo riêng. |
| Chờ trả nhà cung cấp | Return-to-vendor pending | Hàng đã được chấp thuận trả nhưng chưa bàn giao. | 10 hộp chờ xe NCC đến nhận không còn khả dụng. | Vẫn thuộc tồn vật lý cho đến bàn giao. |
| Chống xuất âm | No negative stock | Bất biến cấm giao dịch làm số lượng đủ điều kiện xuất xuống dưới 0. | Hai checkout tranh đơn vị cuối; commit sau bị từ chối. | Không có ngoại lệ offline trong Phase 1. |

## 3. Đơn vị tính và danh tính lô
| Thuật ngữ tiếng Việt | Tiếng Anh tương đương | Giải nghĩa | Ví dụ | Ghi chú |
|---|---|---|---|---|
| Đơn vị cơ sở | Base unit of measure | Đơn vị dùng để lưu và cộng trừ số dư của sản phẩm. | Tồn lưu theo lọ dù mua theo hộp. | Bất biến sau movement đầu tiên; đổi bằng sản phẩm mới hoặc migration có kiểm soát. |
| Đơn vị giao dịch | Transaction unit of measure | Đơn vị xuất hiện trên chứng từ hoặc giao diện thao tác. | Nhập 3 hộp thay vì 30 lọ. | Operation giữ cả quantity giao dịch và base quantity. |
| Mục hàng nhận | Receipt item | Nhóm nghiệp vụ/UI trong một receipt ứng với một sản phẩm và một đơn vị giao dịch; có thể gồm nhiều lô hoặc tình trạng. | Nobivac DHPPi · hộp là một mục; cùng sản phẩm · lọ là mục khác. | Có thể materialize thành nhiều Operation line kỹ thuật nhưng phải giữ cùng receipt-item reference. |
| Tỷ lệ quy đổi | Conversion rate | Quan hệ giữa đơn vị giao dịch và đơn vị cơ sở. | 1 hộp bằng 10 lọ. | Do master có thẩm quyền cung cấp. |
| Ảnh chụp quy đổi | Conversion snapshot | Tỷ lệ và phiên bản được giữ tại thời điểm operation khóa nội dung. | Lần nhập cũ vẫn giữ 1 hộp bằng 10 lọ dù master đổi sau đó. | Bảo toàn lịch sử. |
| Chính sách theo dõi | Tracking policy | Cấu hình xác định sản phẩm không theo dõi hoặc theo dõi theo lô. | Bao tay dùng NONE; vaccine dùng LOT. | Phase 1 chỉ có `NONE` và `LOT`. |
| Không theo dõi lô | None tracking | Sản phẩm chỉ quản lý theo số lượng, kho và trạng thái. | Bao tay không hiển thị trường mã lô hoặc hạn dùng khi nhận hàng. | Khi `NONE`, hạn dùng bị vô hiệu hóa và UI/API không nhận dữ liệu lô. |
| Theo dõi theo lô | Lot tracking | Sản phẩm yêu cầu mã lô trong mọi operation làm phát sinh/di chuyển tồn. | Vaccine bắt buộc ghi lot V2408. | Hạn dùng có thể bắt buộc hoặc không. |
| Yêu cầu hạn dùng | Expiry required | Cấu hình phụ cho biết sản phẩm LOT có bắt buộc hạn dùng hay không. | Vaccine LOT phải nhập HSD; linh kiện LOT có thể không cần. | Chỉ có nghĩa khi tracking mode là LOT. |
| <a id="term-lo-san-xuat"></a>Lô sản xuất | Production lot | Nhóm hàng cùng đợt sản xuất/đóng gói được nhà sản xuất gắn chung mã. | Mã `ABC-2408` in trên hộp. | Là danh tính lô chính thức. |
| Batch giao hàng | Supplier delivery batch | Một lần hoặc nhóm giao hàng của nhà cung cấp. | NCC giao cùng lot L01 trong hai chuyến. | Không thay thế lot code. |
| Batch nhận hàng | Receipt batch | Nhóm thao tác nhận hàng nội bộ. | Ca sáng nhận hai chứng từ trong batch kiểm soát. | Không tạo danh tính lô mới. |
| Hồ sơ lô | Lot profile | Thực thể lưu danh tính và thuộc tính dùng chung của một lô sản phẩm. | L01 có ngày sản xuất và HSD dùng chung qua mọi lần nhập. | Khóa duy nhất tenant + product + lot code. |
| Mã lô | Lot code | Mã do nhà sản xuất hoặc đơn vị đóng gói công bố trên hàng. | Nhân viên quét `ABC-2408` từ bao bì. | Đơn vị bán không tự phát minh mã lô. |
| Độ chính xác hạn dùng | Expiry precision | Mức chi tiết gốc của hạn dùng: tháng/năm hoặc ngày/tháng/năm. | `08/2027` khác dữ liệu gốc `31/08/2027`. | Hệ thống giữ cả precision và ngày quy đổi. |
| Xung đột thuộc tính lô | Lot attribute conflict | Lần nhập sau khai ngày sản xuất/hạn dùng khác hồ sơ lô đã chính thức. | L01 đang có HSD 31/8 nhưng receipt mới khai 30/9. | Chặn hoàn tất cho đến khi sửa có thẩm quyền. |
| Serial | Serial number | Mã riêng cho từng đơn vị hàng. | Máy có mã SN001. | Kiến thức mở rộng; ngoài Phase 1. |

## 4. Nghiệp vụ tồn kho và vòng đời xử lý
| Thuật ngữ tiếng Việt | Tiếng Anh tương đương | Giải nghĩa | Ví dụ | Ghi chú |
|---|---|---|---|---|
| Nghiệp vụ tồn kho | Inventory Operation | Ý định có định danh làm thay đổi số lượng, trạng thái hoặc giá trị tồn kho. | Receipt, issue, adjustment và reversal là các loại operation. | Không hệ thống nguồn nào sửa balance trực tiếp. |
| Dòng nghiệp vụ | Operation line | Chi tiết sản phẩm, kho, lượng, trạng thái và lô trong operation. | Operation nhận có ba dòng sản phẩm. | Một dòng lỗi làm toàn operation không hoàn tất. |
| Nháp | Draft | Trạng thái duy nhất cho phép sửa nội dung operation. | Người lập bổ sung mã lô khi operation còn Nháp. | Chưa ảnh hưởng tồn. |
| Chờ duyệt | Pending approval | Operation đã khóa payload và chờ quyết định phê duyệt. | Điều chỉnh rủi ro cao được gửi duyệt. | Phê duyệt chưa làm thay đổi tồn. |
| Sẵn sàng | Ready | Operation đã đủ điều kiện hoặc không cần duyệt, chờ thực thi. | Receipt hợp lệ chuyển sang Sẵn sàng. | Payload đã khóa. |
| Đang xử lý | Processing | Hệ thống đang thực hiện operation và chưa có kết quả cuối. | Worker đang khóa balance và ghi movement. | Không được sửa/hủy mù. |
| Hoàn tất | Completed | Kết quả cuối xác nhận owner effect đã commit. | Movement, balance và outbox cùng commit. | Không phụ thuộc event đã giao thành công. |
| Từ chối duyệt | Approval rejected | Người duyệt từ chối operation trước thực thi. | Điều chỉnh bị từ chối kèm lý do. | Không ảnh hưởng tồn; muốn sửa tạo operation mới. |
| Từ chối thực thi | Execution rejected | Hệ thống chắc chắn không commit owner effect do điều kiện hiện hành không đạt. | Tồn không đủ khi bắt đầu xử lý. | Là kết quả cuối; thử lại dùng ID mới có liên kết. |
| Chưa xác định kết quả | Unknown result | Chưa đủ bằng chứng để biết operation đã commit hay chưa; tác động phải được trình bày là chưa xác định. | Timeout xảy ra ngay sau lệnh commit; giao diện hướng dẫn kiểm tra lại bằng cùng ID. | Mã kỹ thuật `UNKNOWN`; không coi là thất bại và không gợi ý tạo yêu cầu mới. |
| Đã hủy | Cancelled | Operation bị kết thúc trước khi bước xử lý không thể hủy bắt đầu. | Nháp hoặc Chờ duyệt được hủy. | Completed phải reversal, không chuyển Cancelled. |
| Mã yêu cầu nghiệp vụ | Operation request ID | Định danh ổn định của ý định tạo Inventory Operation từ nguồn. | Retry cùng `operation_request_id=REQ-001` trả cùng operation. | Khác `idempotency_key` của từng lần gọi command. |
| Dấu vân tay nội dung | Payload hash | Giá trị băm dùng phát hiện cùng Request ID nhưng nội dung khác. | REQ-001 gửi lại với quantity khác bị từ chối. | Bảo vệ idempotency. |
| Phiên bản nguồn | Source version | Số phiên bản tăng dần của chứng từ nguồn. | Version 2 đến trước version 1; version 1 bị coi là cũ. | Không sửa operation đã khóa. |
| Ghi nguyên tử | Atomic commit | Tất cả owner effects cùng thành công hoặc cùng rollback. | Operation, movement, balance, lot, value và outbox cùng commit. | Không có hoàn tất từng dòng. |
| Đảo nghiệp vụ | Reversal | Operation mới trung hòa effect của operation đã hoàn tất. | Đảo adjustment sai bằng reversal có liên kết. | Không sửa lịch sử gốc. |
| <a id="term-nghiep-vu-sua-sai"></a>Nghiệp vụ sửa sai | Correction operation | Operation mới ghi nhận cách sửa sai có thẩm quyền và liên kết operation gốc; có thể bao gồm reversal và operation thay thế tùy ma trận sửa sai. | OP02 thay thế OP01 sau khi REV01 trung hòa tác động sai. | Không sửa hoặc xóa lịch sử của operation gốc. |
| Chuỗi sửa sai | Correction chain | Quan hệ giữa operation gốc, reversal và operation thay thế. | OP01 → REV01 → OP02. | Mỗi thành viên giữ ID/ngày riêng. |

## 5. Sổ biến động, giữ hàng và kiểm kê
| Thuật ngữ tiếng Việt | Tiếng Anh tương đương | Giải nghĩa | Ví dụ | Ghi chú |
|---|---|---|---|---|
| Sổ biến động số lượng | Inventory movement ledger | Sổ append-only ghi mọi thay đổi số lượng và trạng thái. | Receipt +100; sale −10; state move 5. | Nguồn sự thật của quantity. |
| <a id="term-but-ghi-bien-dong"></a>Bút ghi biến động | Inventory movement | Một dòng bất biến gắn operation, line, balance key và quantity delta. | MOV-01 tăng 100 lọ vào L01. | Không cập nhật sau insert. |
| Giữ hàng | Reservation | Cam kết quantity theo order line, product và warehouse; tổng lượng giữ giao dịch được cộng trong Reservation Bucket theo sản phẩm + kho. | Đơn online giữ 10 lọ. | Chưa chọn lô, không nằm trên balance theo lô và chưa giảm vật lý. |
| Giao đủ | Ship complete | Chính sách chỉ xác nhận khi đủ toàn bộ quantity. | Cần 10 nhưng có 8 nên không giữ phần nào. | Do nguồn đơn hàng sở hữu. |
| Giao từng phần | Partial fulfillment | Chính sách cho giữ lượng có sẵn và để phần thiếu chờ hàng. | Cần 10, giữ 8, thiếu 2. | Nguồn đơn hàng quyết định. |
| Chờ hàng | Backorder | Phần nhu cầu được chấp nhận nhưng chưa có quantity khả dụng. | Hai lọ còn thiếu sau khi giữ 8. | Không phải stock quantity. |
| FEFO | First Expired, First Out | Ưu tiên lô còn hợp lệ có hạn dùng sớm nhất. | Lô hết 30/9 được chọn trước 31/10. | Dùng cho hàng có hạn dùng. |
| FIFO | First In, First Out | Ưu tiên lượng nhập trước. | Lượng nhập 1/8 được chọn trước 5/8. | Dùng khi không có hạn dùng. |
| Lấy hàng | Picking | Chọn và thu gom lượng/lô cho đơn; kết quả là một tập phân bổ có ID, version và dòng ổn định. | Nhân viên lấy 5 lọ thuộc L01. | Chỉ một version hoạt động; bàn giao mới consume đúng một lần. |
| Đóng gói | Packing | Chuẩn bị hàng đã lấy để bàn giao. | Năm lọ đã đóng thùng nhưng còn trong kho. | Chưa phải mốc xuất. |
| Bàn giao | Handover | Mốc hàng rời quyền kiểm soát vật lý của kho cho khách/carrier. | Shipper nhận 5 kiện. | Là mốc giảm vật lý với đơn giao hàng. |
| Checkout POS | POS checkout | Giao dịch trực tuyến kiểm tra và xuất nguyên tử tại quầy. | Quét hàng và thanh toán thành công làm tồn giảm ngay. | Không hỗ trợ checkout offline trong Phase 1. |
| Phiên kiểm kê | Stock count session | Hồ sơ quản lý phạm vi, cut-off, khóa, đếm và kết quả kiểm kê. | Kiểm kê nhóm vaccine tại W01. | Phạm vi materialize khi mở. |
| Đếm kín | Blind count | Người đếm chưa thấy quantity hệ thống trước khi nộp lần đầu. | Nhân viên nhập 98 trước khi biết sổ là 100. | Giảm thiên lệch. |
| Khóa kiểm kê | Count lock | Khóa đúng balance key thuộc phiên trong thời gian đếm. | Checkout P01 bị chặn khi P01 nằm trong phiên. | Không cần device ack offline. |
| Chênh lệch kiểm kê | Count discrepancy | Hiệu giữa quantity kiểm đếm được duyệt và quantity hệ thống tại cut-off. | Đếm 98, sổ 100, delta −2. | Ghi bằng Điều chỉnh tồn kho. |

## 6. Giá trị tồn kho và giá vốn
| Thuật ngữ tiếng Việt | Tiếng Anh tương đương | Giải nghĩa | Ví dụ | Ghi chú |
|---|---|---|---|---|
| Giá trị nhập ban đầu | Initial receipt value | Giá trị được xác lập lần đầu cho lượng hàng thực tế đã nhận, từ các căn cứ hợp lệ đang có tại thời điểm BJ03 xác nhận. | Nhận 100 hộp; căn cứ hợp lệ xác lập tổng giá trị nhập ban đầu 11 triệu đồng. | Không đồng nghĩa giá vốn chính thức; BJ03 không tạo `OfficialCostVersion`. |
| Căn cứ giá trực tiếp | Direct price basis | Căn cứ giá do Theme 7 quản lý cho hàng nhập nhanh khi không phụ thuộc nguồn thương mại từ Theme 10; phải có nguồn, thời điểm và dấu vết người xác lập. | Kế toán xác lập 110.000 đ/hộp từ xác nhận NCC cho một Quick Receipt. | Không dùng để sửa PO/hóa đơn thuộc Theme 10. |
| Điều chỉnh giá trị hàng nhập | Receipt value adjustment | Thành phần có dấu làm thay đổi giá trị hàng nhập sau khi BJ03 đã xác nhận; có thể tăng hoặc giảm. | Hóa đơn vận chuyển đến sau làm tăng 600.000 đồng; credit note làm giảm 200.000 đồng. | Không dùng để che lỗi nhập liệu; lỗi nhập sai đi correction. |
| Cấu phần giá trị | Cost component | Khoản làm hình thành hoặc điều chỉnh giá trị hàng nhập, như giá mua, khoản giảm giá trị mua, thuế/phí không thu hồi và chi phí mua phân bổ. | Phí vận chuyển 200.000 đồng được phân bổ vào receipt. | Phải có nguồn, phương pháp và kỳ hiệu lực. |
| Sổ biến động giá trị | Inventory value ledger | Sổ append-only ghi delta giá trị tồn kho. | Receipt +5 triệu; issue −500.000; true-up −20.000. | Authority tổng hợp ở tenant + product. |
| Bút ghi giá trị | Inventory value movement | Một dòng giá trị bất biến gắn nguồn, sản phẩm, kỳ và loại movement. | VAL-01 ghi tăng 5 triệu cho P01. | Không sửa lại chứng từ gốc. |
| Bình quân gia quyền liên hoàn | Moving weighted average | Bình quân được cập nhật theo trình tự movement đủ điều kiện. | Sau receipt mới, chỉ số bình quân thay đổi. | Tính song song để theo dõi/đối chiếu. |
| Bình quân gia quyền cuối kỳ | Periodic weighted average | Bình quân tính tại cut-off trên toàn bộ hàng sẵn có của kỳ. | Tổng giá trị hàng sẵn có chia tổng quantity hàng sẵn có. | Có thể được chọn làm phương pháp nguồn. |
| Phương pháp nguồn | Source costing method | Phương pháp được chính sách tenant chọn trước để BJ14 dùng khi công bố giá vốn chính thức. | Tenant cấu hình bình quân cuối kỳ làm phương pháp công bố. | Phương pháp còn lại không tự ghi sổ. |
| <a id="term-gia-von-chinh-thuc"></a>Giá vốn chính thức | Official inventory cost | Phiên bản đơn giá được công bố và có hiệu lực để ghi giảm tồn/giá vốn ban đầu. | C_official của P01 là 50.000 đồng từ 1/8. | Một thời điểm chỉ có một phiên bản hiệu lực. |
| Phiên bản giá vốn | Official cost version | Bản giá vốn chính thức có nguồn tính, thời điểm hiệu lực và người công bố. | COST-P01-V3 có hiệu lực 1/9. | Bất biến sau công bố. |
| Giá vốn ban đầu của giao dịch | Transaction-time COGS | Giá vốn ghi khi bàn giao dựa trên official cost đang hiệu lực. | Bán 10 lọ × 50.000 = 500.000 đồng. | Không dùng giá dự kiến từ kịch bản. |
| Điều chỉnh giá vốn cuối kỳ | Period-end COGS true-up | Delta bổ sung cho lượng đã xuất khi kết quả cuối kỳ khác cost ban đầu. | Giá cuối kỳ 48.000 làm COGS 10 lọ giảm 20.000. | Ghi dòng adjustment liên kết, không sửa đơn. |
| Điều chỉnh giá trị tồn cuối kỳ | Ending inventory adjustment | Delta đưa giá trị lượng còn lại về kết quả tính giá cuối kỳ. | 90 lọ còn lại được điều chỉnh −180.000. | Ghi value-only adjustment. |
| Đợt điều chỉnh định giá | Valuation adjustment batch | Batch nguyên tử gồm COGS true-up, ending adjustment và công bố cost version. | Close tháng 8 tạo batch VA-08. | Mỗi thành phần chỉ ghi delta. |
| <a id="term-gia-tri-ghi-so"></a>Giá trị ghi sổ | Book value | Tổng giá trị có thẩm quyền từ value ledger. | Tổng value movement của P01 là 4,32 triệu. | Không bắt buộc luôn bằng quantity × official cost giữa hai lần close. |
| Ngày nghiệp vụ | Business date | Ngày sự kiện kinh doanh gốc. | Hàng giao ngày 31/7. | Tách ngày ghi nhận. |
| Ngày ghi nhận | Posting date | Ngày effect được ghi vào sổ. | Correction của giao dịch 31/7 được post ngày 5/8. | Bảo toàn kỳ đã khóa. |
| Ngày hiệu lực | Effective time | Thời điểm version hoặc chính sách bắt đầu áp dụng. | Cost V3 có hiệu lực 00:00 ngày 1/9. | Không nhất thiết bằng created_at. |

## 7. Chiết khấu mua hàng và định giá bán
| Thuật ngữ tiếng Việt | Tiếng Anh tương đương | Giải nghĩa | Ví dụ | Ghi chú |
|---|---|---|---|---|
| Khoản ưu đãi mua hàng từ nhà cung cấp | Supplier incentive | Tên chung cho quyền lợi doanh nghiệp mua nhận từ nhà cung cấp. | Giảm 5% khi đạt doanh số quý. | Ưu tiên dùng tiếng Việt thay “rebate”. |
| Chiết khấu mua hàng theo kỳ | Period purchase rebate | Ưu đãi được xác định theo doanh số hoặc sản lượng tích lũy trong kỳ. | Mua đủ 1.000 hộp được giảm 5%. | Có thể dự kiến trước, ghi nhận sau. |
| Kịch bản chiết khấu mua hàng | Purchase-discount scenario | Bản tính dự kiến theo sản phẩm trước khi PO/hàng về. | Chủ cửa hàng giả định mua 500 hộp để ước lượng cost. | Không tác động tồn, AP hoặc official cost. |
| <a id="term-gia-von-du-kien"></a>Giá vốn dự kiến | Projected cost | Kết quả ước lượng sau khi áp các điều kiện ưu đãi giả định. | Giá niêm yết mua 100.000, dự kiến sau ưu đãi còn 95.000. | Chỉ phục vụ phân tích/định giá bán. |
| <a id="term-gia-von-tham-chieu-dinh-gia"></a>Giá vốn tham chiếu định giá | Pricing cost basis | Mốc cost do miền định giá bán công bố để tính giá sàn và giá niêm yết. | Pricing basis của P01 là 48.000 đồng. | Nguồn official cost hoặc projected scenario. |
| Nguồn giá vốn tham chiếu | Pricing basis source | Loại nguồn và phiên bản hình thành pricing cost basis. | `OFFICIAL_COST:V3` hoặc `PROJECTED_PURCHASE_DISCOUNT:S2`. | Bắt buộc giữ provenance. |
| Giá sàn | Floor price | Mức giá tối thiểu theo chính sách lợi nhuận/rủi ro. | Promotion đưa giá xuống dưới sàn thì cảnh báo hoặc chặn. | Owner thuộc miền định giá bán. |
| Giá niêm yết | List price | Giá công bố trước khuyến mại và điều chỉnh theo bối cảnh giao dịch. | P01 niêm yết 75.000 đồng. | Có thể là mức vận hành cao nhất trong Phase 1 nhưng không đồng nghĩa khái niệm ceiling. |
| Giá bán giao dịch | Transaction sales price | Giá cuối cùng áp cho một dòng bán trong bối cảnh cụ thể. | Khách VIP mua 10 lọ trong tuần khuyến mại với giá 68.000. | Snapshot trên dòng đơn. |
| Chính sách lợi nhuận | Profit policy | Quy tắc chuyển pricing cost basis thành floor/list price. | Mức lợi nhuận tối thiểu tạo floor price. | Phải ghi rõ dùng margin hay markup nếu cấu hình. |
| Tỷ suất lợi nhuận trên doanh thu | Margin | Lợi nhuận chia cho giá bán. | Cost 80, price 100 thì margin 20%. | Không dùng lẫn với markup. |
| Tỷ lệ cộng trên giá vốn | Markup | Lợi nhuận chia cho cost. | Cost 80, price 100 thì markup 25%. | Cùng số liệu nhưng khác margin. |
| Dự thảo giá | Pricing draft | Gói thay đổi chưa có hiệu lực gồm basis, floor, list và bằng chứng tính. | Kịch bản S2 tạo draft giá P01. | Không tự thay giá bán hiện hành. |
| Công bố giá | Price publication | Quyết định của người có thẩm quyền đưa phiên bản giá bán vào hiệu lực. | Giá niêm yết V5 có hiệu lực từ 1/9. | Tách khỏi công bố official cost. |
| Cập nhật hàng loạt theo giá vốn mới | Bulk pricing-basis update | Lựa chọn cập nhật nhiều sản phẩm đang dùng official cost cũ sang official cost mới. | 200 sản phẩm dùng basis kỳ trước được chọn cập nhật. | Không áp tự động cho basis từ scenario. |
| Rà soát giá dựa trên kịch bản | Scenario-based pricing review | Quyết định giữ, thay bằng official cost hoặc tính lại scenario. | P01 đang dùng scenario S2 nên phải người có quyền xem lại. | Không dùng ngưỡng chênh lệch để tự quyết. |
| Lợi nhuận tại giao dịch | Transaction-time margin | Lợi nhuận dùng giá bán giao dịch và COGS ban đầu. | Báo cáo tức thời sau checkout. | Có thể thay đổi sau true-up. |
| Lợi nhuận sau đối soát | Reconciled margin | Lợi nhuận dùng COGS ban đầu cộng adjustment cuối kỳ. | Báo cáo tháng sau khi close. | Không sửa dòng đơn gốc. |
| Lợi nhuận dự kiến | Projected margin | Lợi nhuận dùng pricing cost basis để ra quyết định giá. | Chủ cửa hàng thử giá 70.000 trên cost dự kiến 48.000. | Không phải lợi nhuận kế toán. |

## 8. Phê duyệt, đối soát và bảo mật
| Thuật ngữ tiếng Việt | Tiếng Anh tương đương | Giải nghĩa | Ví dụ | Ghi chú |
|---|---|---|---|---|
| Người lập–người duyệt | Maker–checker | Người tạo không được tự phê duyệt operation của mình. | A lập adjustment, B duyệt. | Áp dụng khi policy yêu cầu duyệt. |
| Chính sách phê duyệt | Approval policy | Quy tắc xác định operation nào cần duyệt và cấp quyền cần có. | Reversal giá trị cao yêu cầu cấp 3. | Chụp version khi gửi duyệt. |
| Giá trị rủi ro | Approval risk value | Giá trị tuyệt đối quantity nhân căn cứ giá tại lúc gửi. | 100 × 50.000 = 5 triệu đồng. | Thiếu mọi căn cứ giá thì chặn gửi. |
| Phạm vi kho | Warehouse scope | Tập kho người dùng được phép xem hoặc thao tác. | User chỉ được xác nhận operation của W01. | Phase 1 vẫn kiểm tra dù chỉ có một kho. |
| Quyền tài chính | Financial permission | Quyền xem nhóm `FINANCIAL_RESTRICTED`: giá mua/chi phí, official/book value, COGS/adjustment, projected/pricing-reference cost và kịch bản ưu đãi. | Thủ kho thấy quantity nhưng giá bị che. | Server lọc cả API, export, event/projection, log và DOM; risk engine vẫn tính nội bộ. |
| <a id="term-doi-soat"></a>Đối soát | Reconciliation | Quá trình thu thập và kiểm tra bằng chứng để xác định nguyên nhân, finality và cách xử lý an toàn cho sai lệch hoặc kết quả chưa xác định. | Đối chiếu request, operation, movement và ledger trước khi kết luận một timeout đã commit hay chưa. | Không sửa tay ledger hoặc balance để làm cho số liệu khớp. |
| Hồ sơ đối soát | Reconciliation case | Hồ sơ theo dõi sai lệch giữa nguồn, ledger hoặc projection đến khi có bằng chứng xử lý. | Đơn đã giao nhưng thiếu operation xuất. | Không tự sửa tồn. |
| Nguồn sự thật | Source of truth | Dữ liệu được ưu tiên khi có sai lệch. | Nhật ký biến động được ưu tiên hơn balance projection. | Mỗi loại dữ liệu có owner riêng. |
| Thẻ kho | Stock card | Báo cáo movement theo thời gian có opening, in, out, closing và lineage. | Xem P01/W01 trong tháng 8. | Dựng từ ledger. |
| Báo cáo tại thời điểm | Point-in-time report | Báo cáo dựng số dư đến một cut-off lịch sử nhất quán. | Tồn lúc 23:59 ngày 31/7. | Ghi ledger sequence/as-of. |
| Mốc chuyển đổi | Chuyển đổi chính thức | Thời điểm chuyển từ hệ thống cũ sang hệ thống mới. | Chốt 23:00 ngày 31/8. | Activation giữ `PREPARING`; opening/report commit nguyên tử mới chuyển `ACTIVE`. |
| Batch số dư đầu kỳ | Opening balance batch | Batch nguyên tử nhập quantity và total book value ban đầu. | Một dòng lỗi làm toàn batch không post. | Maker không tự xác nhận. |
| Số kiểm soát | Control total | Tổng đã được duyệt dùng để đối chiếu migration/batch. | W01 có 20.000 đơn vị; product P có value 2 tỷ. | Quantity theo kho; value authority theo tenant + product. |

## 9. Độ tin cậy kỹ thuật và quản trị thay đổi
| Thuật ngữ tiếng Việt | Tiếng Anh tương đương | Giải nghĩa | Ví dụ | Ghi chú |
|---|---|---|---|---|
| Chống xử lý trùng | Idempotency | Retry cùng command key trả lại cùng kết quả, không lặp owner effect; key tách khỏi operation request ID. | Retry SUBMIT-REQ-001 không gửi duyệt hai lần. | Áp cho mọi mutation bằng `CommandReceipt`; cùng key khác payload bị chặn. |
| Kiểm soát đồng thời | Concurrency control | Cơ chế bảo đảm các giao dịch cạnh tranh không phá invariant. | Hai checkout tranh đơn vị cuối; commit đầu thắng. | Dùng lock/version phù hợp. |
| Sự kiện chờ phát | Transactional outbox event | Event được ghi trong cùng transaction với owner effect rồi gửi lại đến khi được nhận. | Operation completed nhưng event giao trễ. | Không đảo tồn vì lỗi gửi event. |
| Sổ nối thêm | Append-only ledger | Cấu trúc chỉ thêm bản ghi mới, không sửa lịch sử. | Correction tạo movement mới thay vì sửa movement cũ. | Áp dụng quantity/value/audit. |
| Dựng lại số dư | Balance rebuild | Tái tạo projection từ movement ledger. | Balance lệch được replay về 83. | Phải khóa phạm vi bị ảnh hưởng. |
| Mục tiêu không mất dữ liệu | Recovery Point Objective zero | Không mất movement đã commit sau sự cố. | Restore giữ đủ transaction cuối đã hoàn tất. | Viết tắt `RPO = 0`. |
| Độ trễ p95 | P95 latency | 95% yêu cầu có thời gian phản hồi không vượt ngưỡng. | Availability p95 không quá 300 ms. | Mục tiêu phi chức năng. |
| Năng lực xử lý | Throughput | Số operation hệ thống xử lý trong một khoảng thời gian. | 50 mutation operations mỗi giây. | Không được đánh đổi tính đúng. |
| Quyết định làm căn cứ | Canonical decision | Kết luận nghiệp vụ duy nhất đang có hiệu lực cho một vấn đề. | Available bằng eligible trừ reserved. | Tên tiếng Việt được ưu tiên. |
| Nhật ký thay thế | Supersession log | Hồ sơ cho biết quyết định mới thay quyết định cũ nào và vì sao. | Offline chuyển từ ACTIVE sang DEFERRED trong v2.0.0. | Không xóa lịch sử cũ. |
| Kiểm tra nhất quán | Consistency audit | Rà soát chéo scope, owner, aggregate, invariant và finality. | Phát hiện UI tạo đường sửa balance trực tiếp. | Phải sửa lớp downstream. |
| Đóng băng phiên bản | Baseline freeze | Phát hành snapshot bất biến sau kiểm tra. | `T7-BASELINE-FREEZE-v2.0.4`. | Thay đổi sau đó tạo version mới. |
| Bản kê đóng băng | Freeze manifest | Danh sách file, checksum và bằng chứng của baseline. | Manifest ghi SHA-256 của mọi Markdown. | Dùng phát hiện drift. |
| Mức bằng chứng | Evidence level | Nhãn phân biệt file được tạo, kiểm tra tĩnh, mô phỏng hay chạy trên repo thật. | Package này đạt `STATIC_VALIDATED`. | Không được nâng cấp bằng suy đoán. |

## 10. Khả năng tương lai và ngoài phạm vi Phase 1
| Thuật ngữ tiếng Việt | Tiếng Anh tương đương | Giải nghĩa | Ví dụ | Ghi chú |
|---|---|---|---|---|
| Chuyển kho nội bộ | Internal warehouse transfer | Luồng đưa hàng từ kho nguồn qua trạng thái vận chuyển đến kho đích. | W01 gửi 10, W02 nhận 10. | Ngoài Phase 1; không mô phỏng bằng hai adjustment. |
| Hàng đang vận chuyển | In-transit stock | Hàng đã rời kho nguồn nhưng chưa nhận tại kho đích. | 10 hộp trên xe. | Không có state này trong Phase 1. |
| Định tuyến kho | Warehouse sourcing | Chọn kho đáp ứng đơn hàng trong mô hình nhiều kho. | Hệ thống chọn W02 vì W01 thiếu hàng. | Tương lai; owner thuộc order/fulfillment. |
| Bán hàng khi mất kết nối | Offline POS | Giao dịch được hoàn tất cục bộ rồi đồng bộ sau. | Mất mạng nhưng quầy vẫn bán. | Định hướng dài hạn, ngoài Phase 1. |
| Quản lý theo serial | Serial tracking | Theo dõi từng đơn vị hàng bằng identity riêng. | Máy SN001 có lịch sử vòng đời. | Ngoài Phase 1. |
| Chuyển đổi tracking khi còn tồn | Tracking conversion batch | Batch gán lô/serial cho tồn hiện hữu trước khi đổi policy. | Gán lô cho 200 đơn vị cũ. | Ngoài Phase 1; hiện tại chỉ đổi khi tồn bằng 0. |
| Dự báo tồn kho | Inventory forecasting | Dự báo cung/cầu dựa trên lịch sử bán, inbound và horizon. | Dự báo hết hàng sau 12 ngày. | Ngoài Phase 1. |
| Đề xuất bổ sung có vòng đời | Replenishment proposal lifecycle | Hồ sơ đề xuất mua có identity, trạng thái và liên kết PO. | Proposal RP01 chuyển sang PO01. | Ngoài Phase 1. |
| Đóng kho | Warehouse closure | Quy trình ngừng kho sau khi xử lý hết tồn và nghĩa vụ mở. | W01 chuyển sang chỉ đọc. | Không được thao tác trong Phase 1. |

## 11. Các cặp dễ nhầm
| Cặp thuật ngữ | Cách phân biệt ngắn |
|---|---|
| Tồn vật lý và tồn khả dụng | Vật lý là hàng hiện diện; khả dụng chỉ là phần đủ điều kiện bán sau khi trừ reservation. |
| Lô sản xuất và batch giao hàng | Lô do nhà sản xuất/đóng gói định danh; batch giao hàng chỉ là một lần NCC giao. |
| Hạn dùng và trạng thái hết hạn | Hạn dùng là thuộc tính lô; hết hạn là kết quả đánh giá theo ngày nghiệp vụ. |
| Reservation và xuất kho | Reservation chỉ giữ quantity; handover/checkout mới giảm vật lý. |
| Operation và movement | Operation giải thích ý định/kết quả; movement ghi sự thay đổi bất biến. |
| Balance và ledger | Balance là trạng thái hiện tại dựng lại được; ledger là Dữ liệu gốc. |
| Phê duyệt và hoàn tất | Phê duyệt chỉ cho phép thực thi; Completed mới xác nhận owner effect đã commit. |
| Từ chối thực thi và UNKNOWN | Rejected chắc chắn chưa commit; UNKNOWN chưa biết đã commit hay chưa. |
| Giá trị nhập ban đầu và giá vốn chính thức | Giá trị nhập ban đầu thuộc lượng hàng nhận và được BJ03 xác lập; giá vốn chính thức là version do BJ14 công bố theo phương pháp tenant. |
| Giá vốn chính thức và giá vốn tham chiếu định giá | Official cost thuộc valuation; pricing basis thuộc định giá bán và có thể dùng nguồn dự kiến. |
| Giá vốn dự kiến và giá vốn kế toán | Projected cost phục vụ quyết định giá; COGS chỉ dùng official cost và adjustment hợp lệ. |
| Giá niêm yết và giá bán giao dịch | List price là giá trước promotion; transaction price là giá thực áp cho dòng bán. |
| Margin và markup | Margin chia cho giá bán; markup chia cho cost. |
| Chỉ báo tồn thấp và proposal mua | Chỉ báo là dữ liệu dẫn xuất; proposal có identity/lifecycle và chưa thuộc Phase 1. |
| Cập nhật pricing basis và công bố giá | Đổi basis chỉ tạo dự thảo; giá bán chỉ đổi sau price publication. |


<a id="quy-uoc-su-dung-thuat-ngu"></a>
## 12. `TERMINOLOGY_STANDARD` — Quy ước sử dụng thuật ngữ

- Dùng **“Quyết định nghiệp vụ”** cho `Decision Register`.
- Dùng **“Sổ theo dõi quyết định”** cho `decision ledger`.
- Dùng **“Dữ liệu gốc”** cho `Dữ liệu gốc`.
- Dùng **“Chuyển đổi chính thức”** cho `Chuyển đổi chính thức`.
- Ưu tiên tiếng Việt trong Quyết định nghiệp vụ, wiki và SRS; tên kỹ thuật có thể giữ tiếng Anh trong mã, API và mô hình dữ liệu.
- Dùng “quyết định làm căn cứ” thay cho “canonical decision”; dùng “chiết khấu mua hàng theo kỳ” hoặc “khoản ưu đãi mua hàng từ nhà cung cấp” theo đúng ngữ cảnh nghiệp vụ.

**Chủ trì:** BA Lead. **Phối hợp:** Nhóm thẩm định miền.
