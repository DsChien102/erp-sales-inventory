# Epic 02: Quản lý giá niêm yết và giá sàn

## Epic overview

Epic này giúp cửa hàng thiết lập và quản lý giá bán chuẩn cho sản phẩm, bao gồm Giá niêm yết và Giá sàn ở cấp cửa hàng, cấp sản phẩm và theo từng đơn vị đo lường\.

Hệ thống tách Giá niêm yết và Giá sàn vì cửa hàng vừa cần một mức giá bán mặc định để nhân viên bán hàng nhanh, vừa cần một ngưỡng kiểm soát để tránh bán quá thấp\. Giá niêm yết là giá hệ thống ưu tiên đưa vào đơn bán, giúp nhân viên không phải nhớ giá hoặc nhập tay\. Giá sàn là mức giá thấp nhất cửa hàng muốn kiểm soát nội bộ, dùng để cảnh báo hoặc chặn khi phát sinh giảm giá, chiết khấu hoặc điều chỉnh giá dưới mức lợi nhuận mong muốn\.

Giá cấp cửa hàng đóng vai trò là cấu hình mặc định cho các sản phẩm chưa có giá riêng\. Giá cấp sản phẩm được dùng cho những mặt hàng có đặc thù định giá khác với cấu hình chung\. Với sản phẩm có nhiều đơn vị đo lường, hệ thống cần quản lý Giá niêm yết và Giá sàn theo từng đơn vị để đảm bảo nhân viên bán đúng giá theo đúng quy cách thực tế\.

Giá bán được tính dựa trên giá vốn cơ sở định giá và tỷ lệ tính giá đang áp dụng\. Với sản phẩm dùng giá cấp cửa hàng, hệ thống lấy tỷ lệ thiết lập chung của cửa hàng để tính Giá niêm yết và Giá sàn\. Với sản phẩm có giá riêng, hệ thống ưu tiên sử dụng thiết lập riêng của sản phẩm\. Nếu sản phẩm có nhiều đơn vị đo lường, giá theo từng đơn vị cần được xác định theo cấu hình giá và quy đổi đơn vị tương ứng\. Về chi tiết giá vốn cơ sở và cách tính sẽ được để trong theme 6 kho \& giá vốn\.

Epic này bao gồm các nghiệp vụ thiết lập và gỡ thiết lập tỷ lệ tính giá cấp cửa hàng, chọn cách áp dụng giá cho từng sản phẩm, thiết lập hoặc hủy giá riêng cấp sản phẩm, và quản lý Giá niêm yết/Giá sàn theo đơn vị đo lường\. Mục tiêu là giúp cửa hàng bán hàng nhanh hơn, kiểm soát giá tốt hơn và giữ dữ liệu giá bán nhất quán cho các nghiệp vụ phía sau\.

## User roles

|Role|Role definition|Role intent in this epic|
|---|---|---|
|Chủ cửa hàng|Người chịu trách nhiệm cao nhất về dữ liệu vận hành, chính sách bán hàng và hiệu quả kinh doanh của cửa hàng\.|Cần thiết lập cấu hình giá bán chung, kiểm soát Giá niêm yết và Giá sàn để đảm bảo sản phẩm được bán theo mức giá phù hợp với lợi nhuận mong muốn\.|
|Kế toán|Người kiểm tra dữ liệu phục vụ đối soát, giá vốn, chứng từ và báo cáo kinh doanh\.|Cần tham chiếu giá vốn cơ sở định giá, Giá niêm yết, Giá sàn và lịch sử cập nhật giá để kiểm tra tính hợp lý của giá bán khi cần đối soát hoặc giải thích sai lệch\.|

## User stories

| US | Tên | Folder | FR |
| -- | --- | ------ | -- |
| US-01 | Thiết lập Giá niêm yết và Giá sàn cấp cửa hàng | [US-01/](US-01/) | 2 |
| US-02 | Thiết lập Giá niêm yết và Giá sàn cấp sản phẩm | [US-02/](US-02/) | 3 |

Theme index: [README.md](../README.md)
