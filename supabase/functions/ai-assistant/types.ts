export type Status =
  | 'ok'
  | 'tro_chuyen'
  | 'ngoai_pham_vi'
  | 'chua_ho_tro'
  | 'tu_choi'
  | 'khong_quyen'
  | 'loi'
  | 'het_luot'
  | 'ban'

export type Turn = { role: 'user' | 'assistant'; text: string }

export type ColumnKind = 'chu' | 'tien' | 'so' | 'ngay' | 'phan_tram'

export type OpenTarget = {
  loai: 'san_pham' | 'khach_hang' | 'don_ban'
  id: string
}

export type TableBlock = {
  loai: 'bang'
  tieu_de: string
  cot: { khoa: string; ten: string; kieu: ColumnKind }[]
  dong: { o: Record<string, string | number | null>; mo?: OpenTarget }[]
}

export type AssistantReply = {
  trang_thai: Status
  cau_tra_loi: string
  khoi: TableBlock[]
  luot_con_lai: number | null
  cong_cu: string[] // tên công cụ đã gọi, cho script chạy câu thử
}
