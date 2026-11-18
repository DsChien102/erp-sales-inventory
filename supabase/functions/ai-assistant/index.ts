import { createClient } from 'npm:@supabase/supabase-js@2'
import { ClaudeClient } from './model/claude_client.ts'
import { handleRequest, type SupabaseLike } from './handler.ts'

Deno.serve((req) =>
  handleRequest(req, {
    now: () => new Date(),
    getEnv: (key) => Deno.env.get(key),
    makeClient: (authorization) =>
      createClient(
        Deno.env.get('SUPABASE_URL')!,
        Deno.env.get('SUPABASE_ANON_KEY')!,
        {
          global: { headers: { Authorization: authorization } },
          auth: { persistSession: false, autoRefreshToken: false },
        },
      ) as unknown as SupabaseLike,
    makeModel: (cfg) => new ClaudeClient(cfg),
  })
)
