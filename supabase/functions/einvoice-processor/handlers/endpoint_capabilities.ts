/** Pure capability resolver for MISA meInvoice endpoints. */
export function resolveEndpointCapabilities(baseUrl: string, emailDeliveryEnabled: boolean): {
  supportsEmailDelivery: boolean
  supportedDocumentTypes: ('PDF' | 'XML')[]
  supportsPreview: boolean
} {
  let url: URL | null = null
  try {
    url = new URL(baseUrl)
  } catch {
    url = null
  }
  if (url === null || url.protocol.toLowerCase() !== 'https:') {
    throw new Error('MISA endpoint baseUrl must use HTTPS')
  }
  // Product host only: testapi never advertises email delivery.
  const emailSupported = emailDeliveryEnabled && url.hostname.toLowerCase() === 'api.meinvoice.vn'
  return {
    supportsEmailDelivery: emailSupported,
    supportedDocumentTypes: ['PDF', 'XML'],
    // MISA meInvoice exposes /invoice/unpublishview on both prod and testapi.
    supportsPreview: true,
  }
}
