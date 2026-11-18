import { assert } from 'jsr:@std/assert@1'
import { buildSystemPrompt } from './prompt.ts'

Deno.test('lời dặn có ngày dd/MM/yyyy, vai trò, tên cửa hàng, bao_khong_ho_tro', () => {
  const p = buildSystemPrompt({
    today: '2026-11-16',
    isOwner: false,
    tenantName: 'Cửa hàng Mai',
  })
  assert(p.includes('16/11/2026'))
  assert(p.includes('nhân viên'))
  assert(p.includes('"Cửa hàng Mai"'))
  assert(p.includes('bao_khong_ho_tro'))
  assert(!p.includes('{'))
})

Deno.test('chủ cửa hàng', () => {
  const p = buildSystemPrompt({
    today: '2026-01-05',
    isOwner: true,
    tenantName: 'X',
  })
  assert(p.includes('chủ cửa hàng của cửa hàng "X"'))
  assert(p.includes('05/01/2026'))
})

Deno.test('AI-3: có dự báo nhập hàng, chưa có công nợ; còn dòng chua_ho_tro', () => {
  const p = buildSystemPrompt({ today: '2026-11-16', isOwner: true, tenantName: 'X' })
  assert(!p.includes('công nợ khách'))
  assert(p.includes('dự báo nhập hàng'))
  assert(p.includes('KHÔNG trả lời nội dung'))
  assert(p.includes('chua_ho_tro'))
})

Deno.test('AI-4: lời dặn nhắc truy_van, ưu tiên công cụ chuyên dụng', () => {
  const p = buildSystemPrompt({ today: '2026-11-17', isOwner: true, tenantName: 'X' })
  assert(p.includes('truy_van'))
  assert(p.includes('KHÔNG dùng truy_van'))
  assert(p.includes('KHÔNG trả lời nội dung'))
})

Deno.test('AI-5: câu chào không được chứa chữ số (bộ lọc chống bịa số)', () => {
  const p = buildSystemPrompt({ today: '2026-11-18', isOwner: true, tenantName: 'X' })
  assert(p.includes('KHÔNG được chứa chữ số'))
  assert(p.includes('không gọi công cụ'))
})

Deno.test('AI-5: chỉ trả lời câu hỏi mới nhất, không chạy lại công cụ cho câu cũ', () => {
  const p = buildSystemPrompt({ today: '2026-11-18', isOwner: true, tenantName: 'X' })
  assert(p.includes('Chỉ trả lời câu hỏi MỚI NHẤT'))
  assert(p.includes('KHÔNG gọi lại công cụ cho câu hỏi cũ'))
})
