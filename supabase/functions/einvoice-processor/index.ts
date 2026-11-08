import { createClient, type SupabaseClient } from 'npm:@supabase/supabase-js@2'
import { authorizeRequest, jsonResponse as json, preflightResponse, readJwtRole } from './auth.ts'
import { type CredentialsRow, TenantMisaClientFactory } from './handlers/misa_client_factory.ts'
import { type MisaEnv, readMisaEnv } from './handlers/misa_env.ts'
import { buildDeadLetters, buildHandlers, type HandlerDeps } from './handlers/registry.ts'
import { createIssuanceProvider } from './handlers/issuance/issuance_provider.ts'
import { createSupabaseIssuanceGateways } from './handlers/issuance/supabase_gateways.ts'
import { createIssuedInvoiceProvider } from './handlers/issued_invoice/issued_invoice_provider.ts'
import { createSupabaseIssuedInvoiceGateway } from './handlers/issued_invoice/supabase_gateways.ts'
import {
  createDocumentStorage,
  createSupabaseDocumentBucket,
} from './handlers/issued_invoice/document_storage.ts'
import { createDeliveryProvider } from './handlers/delivery/delivery_provider.ts'
import { createMisaDeliveryObservationProvider } from './handlers/delivery/delivery_observation_provider.ts'
import { createSupabaseDeliveryGateway } from './handlers/delivery/supabase_gateways.ts'
import type { ConnectionRecorder } from './handlers/sync_capabilities.ts'
import { runInvocation } from './queue/processor.ts'
import { SupabaseQueueRpc } from './queue/supabase_queue_rpc.ts'

// Module-level state is kept between calls in the same isolate (MISA tokens live here, never in DB).
let supabase: SupabaseClient | null = null
let clientFactory: TenantMisaClientFactory | null = null

function getClient(url: string, key: string): SupabaseClient {
  supabase ??= createClient(url, key, { auth: { persistSession: false, autoRefreshToken: false } })
  return supabase
}

function credentialsReader(client: SupabaseClient) {
  return {
    async read(tenantId: string): Promise<CredentialsRow | null> {
      const { data, error } = await client.schema('einvoice').rpc('read_provider_credentials', {
        p_tenant_id: tenantId,
      })
      if (error) throw new Error(`read_provider_credentials: ${error.message}`)
      const rows = (data ?? []) as CredentialsRow[]
      return rows.length === 0 ? null : rows[0]
    },
  }
}

function connectionRecorder(client: SupabaseClient): ConnectionRecorder {
  return {
    async record(i) {
      const args: Record<string, unknown> = {
        p_tenant_id: i.tenantId,
        p_connection_id: i.connectionId,
        p_expected_connection_version: i.expectedConnectionVersion,
        p_status: i.status,
      }
      if (i.capabilities !== undefined) args.p_capabilities = i.capabilities
      if (i.verifiedAt !== undefined) args.p_verified_at = i.verifiedAt
      if (i.correlationId !== undefined) args.p_correlation_id = i.correlationId
      const { error } = await client.schema('einvoice').rpc('record_connection_verified', args)
      if (error) throw new Error(`record_connection_verified: ${error.message}`)
    },
  }
}

Deno.serve(async (req) => {
  const preflight = preflightResponse(req.method)
  if (preflight) return preflight
  try {
    // An empty body is normal for pg_net.
    let body: unknown = {}
    try {
      body = await req.json()
    } catch {
      body = {}
    }

    const decision = authorizeRequest(req.method, readJwtRole(req.headers.get('Authorization')), body)
    if (!decision.ok) return json({ error: decision.error }, decision.status)

    const supabaseUrl = Deno.env.get('SUPABASE_URL')
    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')
    if (!supabaseUrl || !serviceRoleKey) return json({ error: 'missing_supabase_env' }, 500)

    let env: MisaEnv
    try {
      env = readMisaEnv((k) => Deno.env.get(k))
    } catch {
      return json({ error: 'missing_misa_env' }, 500)
    }

    const client = getClient(supabaseUrl, serviceRoleKey)
    clientFactory ??= new TenantMisaClientFactory(env, credentialsReader(client))
    const log = (event: string, data: Record<string, unknown>) => console.log(JSON.stringify({ event, ...data }))
    const deps: HandlerDeps = {
      clients: clientFactory,
      recorder: connectionRecorder(client),
      env,
      issuance: {
        provider: createIssuanceProvider({ clients: clientFactory, log }),
        gateways: createSupabaseIssuanceGateways(client),
      },
      issuedInvoice: {
        provider: createIssuedInvoiceProvider({ clients: clientFactory, log }),
        gateway: createSupabaseIssuedInvoiceGateway(client),
        storage: createDocumentStorage(createSupabaseDocumentBucket(client)),
      },
      delivery: {
        provider: createDeliveryProvider({ clients: clientFactory, log }),
        observation: createMisaDeliveryObservationProvider(),
        gateway: createSupabaseDeliveryGateway(client),
      },
    }
    const handlers = buildHandlers(deps)

    const summary = await runInvocation(
      { rpc: new SupabaseQueueRpc(client), handlers, deadLetters: buildDeadLetters(deps) },
      decision.tenantId,
    )
    return json(summary)
  } catch (e) {
    // Never log the payload: errors may carry provider response text.
    console.error(JSON.stringify({ event: 'internal_error', error: String(e) }))
    return json({ error: 'internal_error' }, 500)
  }
})
