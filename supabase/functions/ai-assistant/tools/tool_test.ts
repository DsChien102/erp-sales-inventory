import { assertEquals } from 'jsr:@std/assert@1'
import { rpcErrorFromPostgrest } from './tool.ts'

Deno.test('code lấy từ JSON trong message', () => {
  const e = rpcErrorFromPostgrest({ message: JSON.stringify({ code: 'QUOTA_EXCEEDED', message: 'hết' }) })
  assertEquals([e.code, e.message], ['QUOTA_EXCEEDED', 'hết'])
})

Deno.test('chuỗi bắt đầu PERMISSION_DENIED ⇒ PERMISSION_DENIED', () => {
  assertEquals(rpcErrorFromPostgrest({ message: 'PERMISSION_DENIED' }).code, 'PERMISSION_DENIED')
})

Deno.test('permission denied for function … (thiếu GRANT) ⇒ UNKNOWN, không che lỗi cấu hình', () => {
  assertEquals(rpcErrorFromPostgrest({ message: 'permission denied for function get_sales_stats' }).code, 'UNKNOWN')
  assertEquals(rpcErrorFromPostgrest({ message: 'permission denied: partner.view' }).code, 'UNKNOWN')
})

Deno.test('không đọc được ⇒ UNKNOWN', () => {
  assertEquals(rpcErrorFromPostgrest(null).code, 'UNKNOWN')
  assertEquals(rpcErrorFromPostgrest({ message: 'boom' }).code, 'UNKNOWN')
})
