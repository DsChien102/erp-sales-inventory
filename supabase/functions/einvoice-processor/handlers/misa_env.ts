export interface MisaEnv {
  appId: string
  baseUrl: string
  emailDeliveryEnabled: boolean
}

/** Reads the MISA settings from Edge Function secrets. */
export function readMisaEnv(get: (key: string) => string | undefined): MisaEnv {
  const appId = get('MISA_MEINVOICE_APP_ID')?.trim()
  if (!appId) throw new Error('missing_MISA_MEINVOICE_APP_ID')
  const baseUrl = get('MISA_MEINVOICE_BASE_URL')?.trim()
  if (!baseUrl) throw new Error('missing_MISA_MEINVOICE_BASE_URL')
  const flag = (get('MISA_MEINVOICE_EMAIL_DELIVERY_ENABLED') ?? '').trim().toLowerCase()
  return { appId, baseUrl, emailDeliveryEnabled: flag === 'true' || flag === '1' }
}
