# UIF Plain BA Language Rewrite — v4.2.0

**Parent:** v4.1.0  
**Scope:** `03.design/flows/UIF-01 … UIF-17`  
**Semantic change:** Không.

## Mục tiêu

Làm cho UIF trở thành tài liệu mà BA, Designer, FE và QA có thể đọc trực tiếp để hiểu luồng màn hình, thay vì phải dịch ngược từ ngôn ngữ harness/engineer.

## Cách sửa

- Viết phần đọc chính bằng tiếng Việt nghiệp vụ.
- Tách phần luồng cho con người đọc khỏi phần truy vết kỹ thuật.
- Giữ mã trạng thái khi cần đối chiếu, nhưng luôn đặt cạnh diễn giải tiếng Việt.
- Không copy lại business flow của UC và không đưa anatomy của Screen Contract vào UIF.
- Loại câu nửa Việt nửa Anh, nhãn kỹ thuật không cần thiết và boilerplate không đặc thù cho từng luồng.

## Bằng chứng bảo toàn contract

- 17/17 UIF đã được viết lại.
- 183/183 transition kỹ thuật giữ nguyên ID, From, To, loại, Action và UC/BC trace so với v4.1.0.
- 17/17 Mermaid flow giữ nguyên topology cạnh nối; chỉ thay nhãn hiển thị để dễ đọc hơn.
- BJ, UC, Screen Contract và HTML prototype nằm ngoài change scope.
- Trạng thái active/retired của các screen valuation BJ03/BJ13/BJ14 không đổi.

## Cấu trúc đọc mới của mỗi UIF

1. Mục đích và phạm vi.
2. Người dùng bắt đầu và kết thúc ở đâu.
3. Luồng màn hình.
4. Các bước chuyển màn hình.
5. Các tình huống cần chú ý.
6. Màn hình và Trường hợp sử dụng liên quan.
7. Truy vết kỹ thuật.
8. Kiểm tra tính đầy đủ và liên kết.
