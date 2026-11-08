/// Copy strings for app-owned post-issued HĐĐT sheets (SG-02 O05/O06 + SG-06).
abstract final class OrderEInvoicePostIssueCopy {
  static const sheetTitle = 'Hóa đơn điện tử';

  static const viewOfficialTitle = 'Xem hóa đơn điện tử';
  static const viewOfficialSupporting = 'Mở hóa đơn chính thức từ MISA';

  static const documentsTitle = 'Tài liệu XML & PDF';
  static const documentsSupporting = 'Lưu bản PDF hoặc tệp XML';

  static const sendTitle = 'Gửi hóa đơn';
  static const sendSupporting = 'Gửi qua email';
  static const deliverySecondaryAttention = 'Lần gửi gần nhất cần được kiểm tra trong lịch sử gửi.';

  static const deliveryNotSent = 'Chưa gửi';
  static const deliverySending = 'Đang gửi';
  static const deliverySent = 'Đã gửi';
  static const deliverySendFailed = 'Gửi lỗi';
  static const deliveryUnknown = 'Không xác định kết quả';

  static const documentsSheetTitle = 'Tài liệu hóa đơn điện tử';
  static const savePdfTitle = 'Lưu bản PDF';
  static const savePdfSupporting = 'Lưu hóa đơn dạng PDF vào thiết bị';
  static const saveXmlTitle = 'Lưu tệp XML';
  static const saveXmlSupporting = 'Lưu dữ liệu hóa đơn điện tử dạng XML';
}
