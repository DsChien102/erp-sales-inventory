import { assertEquals, assertStringIncludes, assertThrows } from 'jsr:@std/assert@1'
import { renderEmail, UnknownTemplateError } from './templates.ts'

const appName = 'VET45'

Deno.test('tenant_invitation renders organization, role, code, and expiry', () => {
  const rendered = renderEmail({
    templateId: 'tenant_invitation',
    appName,
    code: 'AB12CD34',
    templateData: {
      tenant_name: 'Phòng khám An',
      role_label: 'Nhân viên',
      inviter_name: 'Nguyễn An',
      expires_at: '2026-10-16T03:30:00.000Z',
    },
  })

  assertEquals(rendered.subject, 'Lời mời tham gia Phòng khám An trên VET45')
  assertStringIncludes(rendered.html, 'Nguyễn An mời bạn tham gia Phòng khám An với vai trò Nhân viên.')
  assertStringIncludes(rendered.html, 'AB12CD34')
  assertStringIncludes(rendered.html, 'Kích hoạt tài khoản')
  assertStringIncludes(rendered.html, 'mã lời mời')
  assertStringIncludes(rendered.text, 'Mã lời mời: AB12CD34')
  assertStringIncludes(rendered.html, '16/10/2026')
  assertNoPlaceholder(rendered.html)
  assertNoPlaceholder(rendered.text)
})

Deno.test('tenant_invitation escapes HTML in organization and inviter names', () => {
  const rendered = renderEmail({
    templateId: 'tenant_invitation',
    appName,
    code: 'AB12CD34',
    templateData: {
      tenant_name: '<b>Shop</b>',
      role_label: '<script>',
      inviter_name: 'A & B',
      expires_at: '2026-10-16T03:30:00.000Z',
    },
  })

  assertStringIncludes(rendered.html, '&lt;b&gt;Shop&lt;/b&gt;')
  assertStringIncludes(rendered.html, '&lt;script&gt;')
  assertStringIncludes(rendered.html, 'A &amp; B')
  assertEquals(rendered.html.includes('<b>'), false)
  assertEquals(rendered.html.includes('<script>'), false)
  assertEquals(rendered.subject, 'Lời mời tham gia <b>Shop</b> trên VET45')
})

Deno.test('tenant_invitation uses a fallback sentence without inviter_name', () => {
  const rendered = renderEmail({
    templateId: 'tenant_invitation',
    appName,
    code: 'AB12CD34',
    templateData: {
      tenant_name: 'Phòng khám An',
      role_label: 'Nhân viên',
      inviter_name: null,
      expires_at: null,
    },
  })

  assertStringIncludes(
    rendered.html,
    'Bạn được mời tham gia Phòng khám An với vai trò Nhân viên.',
  )
  assertStringIncludes(rendered.text, 'Mã lời mời có hiệu lực trong 7 ngày.')
  assertEquals(rendered.html.includes('null'), false)
  assertEquals(rendered.text.includes('null'), false)
  assertEquals(rendered.html.includes('undefined'), false)
  assertEquals(rendered.text.includes('undefined'), false)
})

Deno.test('password_reset_code renders a one-time 10 minute code', () => {
  const rendered = renderEmail({
    templateId: 'password_reset_code',
    appName,
    code: '123456',
    templateData: { expires_in_minutes: 10 },
  })

  assertEquals(rendered.subject, 'Mã đặt lại mật khẩu VET45')
  assertStringIncludes(rendered.html, '123456')
  assertStringIncludes(rendered.html, 'hết hạn sau 10 phút')
  assertStringIncludes(rendered.html, 'chỉ dùng được một lần')
  assertStringIncludes(
    rendered.text,
    'Nếu bạn không yêu cầu đặt lại mật khẩu, hãy bỏ qua email này.',
  )
  assertNoPlaceholder(rendered.html)
  assertNoPlaceholder(rendered.text)
})

Deno.test('unknown template throws UNKNOWN_TEMPLATE', () => {
  assertThrows(
    () =>
      renderEmail({
        templateId: 'activation_invitation',
        appName,
        code: 'ABCDEFGH',
        templateData: {},
      }),
    UnknownTemplateError,
  )
})

function assertNoPlaceholder(value: string) {
  assertEquals(value.includes('undefined'), false)
  assertEquals(value.includes('null'), false)
}
