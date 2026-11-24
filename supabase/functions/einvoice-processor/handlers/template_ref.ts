/** Port of invoice_series_classification.dart + provider_template_ref.dart. */
export interface ProviderTemplateRef {
  templateId: string
  name: string
  invoiceSeries: string
  invoiceWithCode: boolean
  isMtt: boolean
  isSendSummary: boolean
  serial: string | null
  isAvailable: boolean
}

/** Classification of a MISA `InvSeries` per §1.6. Null when it cannot be classified safely. */
export function classifyInvoiceSeries(invSeries: string): { invoiceWithCode: boolean; isMtt: boolean } | null {
  const normalized = invSeries.trim().toUpperCase()
  if (normalized.length < 5) return null
  const typeChar = normalized[0]
  if (typeChar !== '1' && typeChar !== '2' && typeChar !== '5' && typeChar !== '6') return null
  const codeChar = normalized[1]
  if (codeChar !== 'C' && codeChar !== 'K') return null
  const usageChar = normalized[4]
  if (usageChar !== 'T' && usageChar !== 'M') return null
  return { invoiceWithCode: codeChar === 'C', isMtt: usageChar === 'M' }
}

/** Builds a template ref by classifying invoiceSeries; null when malformed. */
export function tryCreateTemplateRef(input: {
  templateId: string
  name: string
  invoiceSeries: string
  isSendSummary: boolean
  serial?: string | null
  isAvailable?: boolean
}): ProviderTemplateRef | null {
  const classification = classifyInvoiceSeries(input.invoiceSeries)
  if (classification === null) return null
  return {
    templateId: input.templateId,
    name: input.name,
    invoiceSeries: input.invoiceSeries.trim(),
    invoiceWithCode: classification.invoiceWithCode,
    isMtt: classification.isMtt,
    isSendSummary: input.isSendSummary,
    serial: input.serial ?? null,
    isAvailable: input.isAvailable ?? true,
  }
}

/** First occurrence of each `invoiceSeries` wins; order preserved. */
export function mergeAndDedupe(refs: Iterable<ProviderTemplateRef>): ProviderTemplateRef[] {
  const seen = new Set<string>()
  const result: ProviderTemplateRef[] = []
  for (const ref of refs) {
    if (!seen.has(ref.invoiceSeries)) {
      seen.add(ref.invoiceSeries)
      result.push(ref)
    }
  }
  return result
}
