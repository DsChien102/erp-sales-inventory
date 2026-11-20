/// TH-06 6.3. `PERMISSION_DENIED` đã được `AppException` đổi sang `NO_PERMISSION` (câu chung).
const Map<String, String> kReceivableErrorMessages = {
  'NOT_FOUND': 'Không tìm thấy khách hàng.',
  'AMOUNT_INVALID': 'Số tiền phải lớn hơn 0.',
  'NO_OUTSTANDING': 'Khách không còn khoản phải thu.',
  'OVERPAYMENT_NOT_ALLOWED': 'Số tiền vượt quá tổng còn nợ của khách.',
  'RECEIVABLE_CHANGED': 'Công nợ của khách vừa thay đổi. Hãy tải lại rồi thử lại.',
  'PAYMENT_METHOD_INVALID': 'Phương thức thanh toán không hợp lệ.',
};
