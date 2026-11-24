export class UnknownTemplateError extends Error {
  constructor(templateId: string) {
    super(`UNKNOWN_TEMPLATE:${templateId}`)
    this.name = 'UnknownTemplateError'
  }
}

export type RenderedEmail = {
  subject: string
  html: string
  text: string
}

export type TemplateInput = {
  templateId: string
  templateData: Record<string, unknown>
  code: string
  appName: string
}

export function renderEmail(input: TemplateInput): RenderedEmail {
  switch (input.templateId) {
    case 'tenant_invitation':
      return renderTenantInvitation(input)
    case 'password_reset_code':
      return renderPasswordReset(input)
    default:
      throw new UnknownTemplateError(input.templateId)
  }
}

function renderTenantInvitation(input: TemplateInput): RenderedEmail {
  const appName = input.appName
  const tenantName = textOrNull(input.templateData.tenant_name)
  const roleLabel = textOrNull(input.templateData.role_label) ?? 'thành viên'
  const inviterName = textOrNull(input.templateData.inviter_name)
  const expiresAt = formatExpiresAt(input.templateData.expires_at)
  const tenantLabel = tenantName ?? 'tổ chức'
  const code = input.code

  const subject = tenantName
    ? `Lời mời tham gia ${tenantName} trên ${appName}`
    : `Lời mời tham gia tổ chức trên ${appName}`

  const inviteSentence = inviterName
    ? `${inviterName} mời bạn tham gia ${tenantLabel} với vai trò ${roleLabel}.`
    : `Bạn được mời tham gia ${tenantLabel} với vai trò ${roleLabel}.`

  const expirySentence = expiresAt
    ? `Mã lời mời hết hạn lúc ${expiresAt} (7 ngày).`
    : 'Mã lời mời có hiệu lực trong 7 ngày.'

  const steps =
    `Mở ứng dụng ${appName}, chọn "Kích hoạt tài khoản", rồi nhập mã lời mời.`

  const html = [
    `<p>${escapeHtml(inviteSentence)}</p>`,
    '<p>Mã lời mời:</p>',
    `<p style="font-size:24px;letter-spacing:0.3em;font-weight:bold">${escapeHtml(code)}</p>`,
    `<p>${escapeHtml(expirySentence)}</p>`,
    `<p>${escapeHtml(steps)}</p>`,
  ].join('')

  const text = [
    inviteSentence,
    `Mã lời mời: ${code}`,
    expirySentence,
    steps,
  ].join('\n')

  return { subject, html, text }
}

function renderPasswordReset(input: TemplateInput): RenderedEmail {
  const appName = input.appName
  const minutes = minutesOrDefault(input.templateData.expires_in_minutes)
  const subject = `Mã đặt lại mật khẩu ${appName}`
  const intro = 'Mã đặt lại mật khẩu của bạn:'
  const expiry = `Mã hết hạn sau ${minutes} phút và chỉ dùng được một lần.`
  const ignore = 'Nếu bạn không yêu cầu đặt lại mật khẩu, hãy bỏ qua email này.'

  const html = [
    `<p>${escapeHtml(intro)}</p>`,
    `<p style="font-size:32px;letter-spacing:0.5em;font-weight:bold">${escapeHtml(input.code)}</p>`,
    `<p>${escapeHtml(expiry)}</p>`,
    `<p>${escapeHtml(ignore)}</p>`,
  ].join('')

  const text = [intro, `Mã: ${input.code}`, expiry, ignore].join('\n')
  return { subject, html, text }
}

function textOrNull(value: unknown): string | null {
  if (typeof value !== 'string') return null
  const trimmed = value.trim()
  return trimmed.length === 0 ? null : trimmed
}

function minutesOrDefault(value: unknown): number {
  if (typeof value === 'number' && Number.isFinite(value) && value > 0) {
    return Math.round(value)
  }
  if (typeof value === 'string' && /^[0-9]+$/.test(value)) {
    const parsed = Number(value)
    if (parsed > 0) return parsed
  }
  return 10
}

function formatExpiresAt(value: unknown): string | null {
  if (typeof value !== 'string' || value.trim().length === 0) return null
  const date = new Date(value)
  if (Number.isNaN(date.getTime())) return null
  return new Intl.DateTimeFormat('vi-VN', {
    timeZone: 'Asia/Ho_Chi_Minh',
    day: '2-digit',
    month: '2-digit',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
    hourCycle: 'h23',
  }).format(date)
}

export function escapeHtml(value: string): string {
  return value
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&#39;')
}
