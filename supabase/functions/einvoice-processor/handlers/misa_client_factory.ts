import { type IMeInvoiceClient, type MeInvoiceConfig, MeInvoiceClient } from '../misa/mod.ts'
import type { MisaEnv } from './misa_env.ts'

export interface CredentialsRow {
  username: string | null
  password: string | null
  tax_code: string | null
  base_url: string | null
}

export interface CredentialsReader {
  /** Real implementation: client.schema('einvoice').rpc('read_provider_credentials', { p_tenant_id }). */
  read(tenantId: string): Promise<CredentialsRow | null>
}

function sameConfig(a: MeInvoiceConfig, b: MeInvoiceConfig): boolean {
  return a.baseUrl === b.baseUrl && a.appId === b.appId && a.taxCode === b.taxCode &&
    a.username === b.username && a.password === b.password
}

/**
 * Per-tenant client cache (token scoped by client instance). Tokens live in memory only,
 * never in the database (TH-08 9.1).
 */
export class TenantMisaClientFactory {
  readonly #clients = new Map<string, IMeInvoiceClient>()
  readonly #configs = new Map<string, MeInvoiceConfig>()

  constructor(
    private readonly env: MisaEnv,
    private readonly credentials: CredentialsReader,
    private readonly create: (c: MeInvoiceConfig) => IMeInvoiceClient = (c) => new MeInvoiceClient(c),
  ) {}

  /** Null when the tenant has no credentials row. */
  async getForTenant(tenantId: string): Promise<{ client: IMeInvoiceClient; baseUrl: string } | null> {
    const row = await this.credentials.read(tenantId)
    if (row === null) return null
    const baseUrl = row.base_url ?? this.env.baseUrl
    const config: MeInvoiceConfig = {
      baseUrl,
      appId: this.env.appId,
      taxCode: row.tax_code,
      username: row.username,
      password: row.password,
    }
    const existing = this.#clients.get(tenantId)
    const existingConfig = this.#configs.get(tenantId)
    if (existing && existingConfig && sameConfig(existingConfig, config)) {
      return { client: existing, baseUrl }
    }
    const client = this.create(config)
    this.#clients.set(tenantId, client)
    this.#configs.set(tenantId, config)
    return { client, baseUrl }
  }

  invalidate(tenantId: string): void {
    this.#clients.delete(tenantId)
    this.#configs.delete(tenantId)
  }
}
