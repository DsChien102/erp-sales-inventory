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

Deno.test('AI-1 chưa có công cụ công nợ / dự báo: không nằm trong phạm vi, có dòng chua_ho_tro', () => {
  const p = buildSystemPrompt({ today: '2026-11-16', isOwner: true, tenantName: 'X' })
  assert(!p.includes('công nợ khách'))
  assert(!p.includes('dự báo nhập hàng'))
  assert(p.includes('KHÔNG trả lời nội dung'))
  assert(p.includes('chua_ho_tro'))
})
