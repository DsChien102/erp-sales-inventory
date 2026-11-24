// Câu cố định — nguyên văn AI-0 mục 6, 8.
export const MESSAGES: Record<
  | 'ngoai_pham_vi'
  | 'chua_ho_tro'
  | 'tu_choi'
  | 'khong_quyen'
  | 'het_luot'
  | 'ban'
  | 'cham'
  | 'loi'
  | 'qua_phuc_tap',
  string
> = {
  ngoai_pham_vi:
    'Mình chỉ giúp xem số liệu cửa hàng thôi. Bạn có thể hỏi như: "Hôm nay bán được bao nhiêu?", "Hàng nào sắp hết?"',
  chua_ho_tro: 'Mình chưa hỗ trợ câu này.',
  tu_choi: 'Mình chỉ xem được, không sửa hay xoá.',
  khong_quyen: 'Bạn không có quyền xem số liệu này. Hãy nhờ chủ cửa hàng.',
  het_luot: 'Cửa hàng đã dùng hết 100 câu hỏi hôm nay. Mai bạn quay lại nhé.',
  ban: 'Trợ lý đang bận, thử lại sau ít phút.',
  cham: 'Trợ lý phản hồi chậm, bạn thử lại nhé.',
  loi: 'Có lỗi khi trả lời. Bạn thử lại nhé.',
  qua_phuc_tap: 'Câu này phức tạp quá, bạn hỏi tách ra nhé.',
}
