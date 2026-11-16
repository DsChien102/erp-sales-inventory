import { assertEquals } from 'jsr:@std/assert@1'
import { redactPersonal } from './redact.ts'

Deno.test('redact bỏ đệ quy khoá thông tin cá nhân', () => {
  assertEquals(
    redactPersonal({
      ten: 'A',
      phone: '09',
      dia_chi: { address: 'x' },
      rows: [{ email: 'e' }],
    }),
    { ten: 'A', dia_chi: {}, rows: [{}] },
  )
})

Deno.test('redact bỏ mã số thuế và CCCD', () => {
  assertEquals(
    redactPersonal({ tax_code: '1', cccd: '2', identity_no: '3', ok: 4 }),
    { ok: 4 },
  )
})
