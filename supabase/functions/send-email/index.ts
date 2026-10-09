import { createClient, type SupabaseClient } from 'npm:@supabase/supabase-js@2'
import { renderEmail, UnknownTemplateError } from './templates.ts'

const UUID_PATTERN =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i

type ClaimedJob = {
  id: string
  template_id: string
  to_email: string
  locale: string
  template_data: Record<string, unknown>
  code: string
}

Deno.serve(async (req) => {
  if (req.method !== 'POST') {
    return json({ error: 'method_not_allowed' }, 405)
  }

  const expectedSecret = Deno.env.get('EMAIL_WEBHOOK_SECRET') ?? ''
  const providedSecret = req.headers.get('x-email-webhook-secret') ?? ''
  if (expectedSecret.length === 0 || !secretsMatch(providedSecret, expectedSecret)) {
    return json({ error: 'unauthorized' }, 401)
  }

  let jobId = ''
  try {
    const body = await req.json()
    jobId = typeof body?.job_id === 'string' ? body.job_id : ''
  } catch {
    return json({ error: 'invalid_json' }, 400)
  }
  if (!UUID_PATTERN.test(jobId)) {
    return json({ error: 'invalid_job_id' }, 400)
  }

  const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? ''
  const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
  if (supabaseUrl.length === 0 || serviceRoleKey.length === 0) {
    return json({ error: 'missing_supabase_env' }, 500)
  }

  const supabase = createClient(supabaseUrl, serviceRoleKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  })

  const claimed = await claimJob(supabase, jobId)
  if (claimed.error) {
    console.log(JSON.stringify({ job_id: jobId, result: 'claim_error' }))
    return json({ error: 'claim_failed' }, 500)
  }
  if (!claimed.job) {
    console.log(JSON.stringify({ job_id: jobId, result: 'skipped' }))
    return json({ skipped: true }, 200)
  }

  const job = claimed.job
  try {
    const rendered = renderEmail({
      templateId: job.template_id,
      templateData: job.template_data ?? {},
      code: job.code,
      appName: Deno.env.get('APP_NAME') ?? 'VET45',
    })
    const sent = await sendWithResend(job, rendered)
    if (!sent.ok) {
      await completeJob(supabase, job.id, false, null, sent.error)
      console.log(JSON.stringify({
        job_id: job.id,
        template_id: job.template_id,
        result: 'failed',
      }))
      return json({ ok: false }, 200)
    }

    await completeJob(supabase, job.id, true, sent.providerMessageId, null)
    console.log(JSON.stringify({
      job_id: job.id,
      template_id: job.template_id,
      result: 'sent',
    }))
    return json({ ok: true }, 200)
  } catch (error) {
    const message = error instanceof UnknownTemplateError
      ? 'UNKNOWN_TEMPLATE'
      : 'SEND_FAILED'
    await completeJob(supabase, job.id, false, null, message)
    console.log(JSON.stringify({
      job_id: job.id,
      template_id: job.template_id,
      result: 'failed',
    }))
    return json({ ok: false }, 200)
  }
})

async function claimJob(
  supabase: SupabaseClient,
  jobId: string,
): Promise<{ job: ClaimedJob | null; error: boolean }> {
  const { data, error } = await supabase.schema('iam').rpc('claim_email_job', {
    p_job_id: jobId,
  })
  if (error) return { job: null, error: true }
  if (data == null) return { job: null, error: false }
  return { job: data as ClaimedJob, error: false }
}

async function completeJob(
  supabase: SupabaseClient,
  jobId: string,
  ok: boolean,
  providerMessageId: string | null,
  errorText: string | null,
): Promise<void> {
  const { error } = await supabase.schema('iam').rpc('complete_email_job', {
    p_job_id: jobId,
    p_ok: ok,
    p_provider_message_id: providerMessageId,
    p_error: errorText,
  })
  if (error) {
    console.log(JSON.stringify({ job_id: jobId, result: 'complete_error' }))
  }
}

async function sendWithResend(
  job: ClaimedJob,
  rendered: { subject: string; html: string; text: string },
): Promise<{ ok: true; providerMessageId: string } | { ok: false; error: string }> {
  const apiKey = Deno.env.get('RESEND_API_KEY') ?? ''
  const from = Deno.env.get('EMAIL_FROM') ?? ''
  if (apiKey.length === 0 || from.length === 0) {
    return { ok: false, error: 'MISSING_EMAIL_CONFIG' }
  }

  const response = await fetch('https://api.resend.com/emails', {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${apiKey}`,
      'Content-Type': 'application/json',
      'Idempotency-Key': job.id,
    },
    body: JSON.stringify({
      from,
      to: [job.to_email],
      subject: rendered.subject,
      html: rendered.html,
      text: rendered.text,
    }),
  })

  if (!response.ok) {
    return { ok: false, error: await resendError(response) }
  }

  const payload = await response.json()
  const providerMessageId = typeof payload?.id === 'string' ? payload.id : ''
  if (providerMessageId.length === 0) {
    return { ok: false, error: `${response.status} missing provider id` }
  }
  return { ok: true, providerMessageId }
}

async function resendError(response: Response): Promise<string> {
  let message = ''
  try {
    const payload = await response.json()
    if (typeof payload?.message === 'string') message = payload.message
    else if (typeof payload?.error?.message === 'string') message = payload.error.message
  } catch {
    message = ''
  }
  return `${response.status} ${message}`.trim().slice(0, 500)
}

function secretsMatch(provided: string, expected: string): boolean {
  const left = new TextEncoder().encode(provided)
  const right = new TextEncoder().encode(expected)
  if (left.length !== right.length) return false
  let diff = 0
  for (let i = 0; i < left.length; i++) diff |= left[i]! ^ right[i]!
  return diff === 0
}

function json(body: unknown, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json' },
  })
}
