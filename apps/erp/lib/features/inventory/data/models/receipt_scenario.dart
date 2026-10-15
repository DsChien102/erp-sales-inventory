/// Ép trạng thái chung của BJ-02 khi chạy trên fixture. Chỉ test và demo dùng;
/// khi có backend, trạng thái đến từ lỗi RPC thật và enum này bị xoá.
enum ReceiptScenario {
  normal,
  permissionDenied, // mọi lời gọi ném AppException(noPermission)
  warehouseLocked, // capability.warehouseLocked = true → chỉ xem
  catalogChanged, // lần tải danh mục đầu ném stateChanged, lần sau thành công
  approverMissing, // gửi phê duyệt ném 'APPROVER_CONFIGURATION_MISSING'
  executionProcessing, // duyệt xong → processing; kiểm tra lần 2 → completed
  executionUnknown, // duyệt xong → executionUnknown; lần xác minh thứ 2 → completed
  executionUnknownStuck, // duyệt xong → executionUnknown; xác minh mãi chưa có kết quả
  executionRejected, // duyệt xong → executionRejected (tồn không đổi)
}
