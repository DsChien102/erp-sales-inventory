import { pickEnum, type Tool } from './tool.ts'

const LOAI = ['ngoai_pham_vi', 'chua_ho_tro', 'tu_choi'] as const

export const unsupportedTool: Tool = {
  declaration: {
    name: 'bao_khong_ho_tro',
    description:
      'Gọi khi câu hỏi hoàn toàn ngoài phạm vi số liệu cửa hàng (ngoai_pham_vi), liên quan nhưng chưa có công cụ phù hợp (chua_ho_tro), hoặc đòi tạo / sửa / xoá dữ liệu hoặc đổi quy tắc (tu_choi).',
    parameters: {
      type: 'object',
      properties: {
        loai: {
          type: 'string',
          enum: [...LOAI],
          description: 'Loại câu hỏi không hỗ trợ',
        },
      },
      required: ['loai'],
    },
  },

  run(args) {
    const loai = pickEnum(args.loai, LOAI, 'loai')
    if (!loai.ok) {
      return Promise.resolve({ kind: 'bad_args', chi_tiet: loai.chi_tiet })
    }
    return Promise.resolve({ kind: 'unsupported', status: loai.value })
  },
}
