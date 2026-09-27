# Báo cáo tự kiểm tra kho bài viết tri thức — v4.1.3

## Kết quả

| Kiểm tra | Kết quả |
|---|---|
| 45 Article ID duy nhất và liên tục | `PASS` |
| Cấu trúc câu trả lời ngắn/lý do/ghi nhớ/chủ đề/nguồn | `PASS` |
| Liên kết mục lục và chủ đề liên quan | `PASS` |
| Nguồn quyết định mới hoặc quy tắc quản trị | `PASS` |
| Không còn tham chiếu quyết định legacy ngoài package tiền nhiệm | `PASS` |
| Scope, authority, finality và ngôn ngữ | `PASS` |
| Bài Wiki đã được rà soát | `PASS` — 45/45; `KB-KGV-040` không có nguồn quyết định (`NOT_APPLICABLE`) |
| Bài có liên kết Decision Register | `PASS` — 44/44 |
| Liên kết quyết định/yêu cầu chi tiết | `PASS` — 244/244 được đặt về full heading permalink của đúng cụm `G01…G14` |
| Đường dẫn tương đối | `PASS` — 244/244 resolve đến `../decisions/decision-register.md` |
| Fragment ngắn/custom còn lại | `PASS` — 0 href dạng `#gNN`; 0 href dạng `#t7-dr-*` |
| Fixture G03 | `PASS` — `#33-g03-nh%E1%BA%ADn-h%C3%A0ng-v%C3%A0-x%C3%A1c-nh%E1%BA%ADn-gi%C3%A1-tr%E1%BB%8B` |
| Nhãn truy vết | `PASS` — giữ nguyên toàn bộ `T7-DR-nnn` và `T7-DR-nnn#REQ-mm` |

Các chủ đề rủi ro cao đã được rà soát: nhận hàng–chờ giá, giữ/xuất, khách trả, trả nhà cung cấp, số dư đầu kỳ, correction, `UNKNOWN`, giá vốn, chiết khấu mua và định giá bán.

`PASS — STATIC_VALIDATED`; trạng thái phát hành vẫn là `RELEASE_CANDIDATE` cho đến khi hoàn tất preview trên GitLab self-hosted.
