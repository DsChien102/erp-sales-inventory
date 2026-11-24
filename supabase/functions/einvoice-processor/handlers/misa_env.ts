export interface MisaEnv {
  appId: string
  baseUrl: string
  emailDeliveryEnabled: boolean
  /** False unless the secret is explicitly `true` / `1` (fail-closed: no real invoice by accident). */
  publishEnabled: boolean
}

function readFlag(get: (key: string) => string | undefined, key: string): boolean {
  const flag = (get(key) ?? '').trim().toLowerCase()
  return flag === 'true' || flag === '1'
}

/** Reads the MISA settings from Edge Function secrets. */
export function readMisaEnv(get: (key: string) => string | undefined): MisaEnv {
  const appId = get('MISA_MEINVOICE_APP_ID')?.trim()
  if (!appId) throw new Error('missing_MISA_MEINVOICE_APP_ID')
  const baseUrl = get('MISA_MEINVOICE_BASE_URL')?.trim()
  if (!baseUrl) throw new Error('missing_MISA_MEINVOICE_BASE_URL')
  return {
    appId,
    baseUrl,
    emailDeliveryEnabled: readFlag(get, 'MISA_MEINVOICE_EMAIL_DELIVERY_ENABLED'),
    publishEnabled: readFlag(get, 'MISA_MEINVOICE_PUBLISH_ENABLED'),
  }
}
