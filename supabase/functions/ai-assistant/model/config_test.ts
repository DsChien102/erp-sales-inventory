import { assertEquals } from 'jsr:@std/assert@1'
import { modelConfigFromEnv } from './config.ts'

const env = (o: Record<string, string>) => (k: string) => o[k]

Deno.test('default_haiku_low', () => {
  assertEquals(modelConfigFromEnv(env({ ANTHROPIC_API_KEY: 'k' })), {
    apiKey: 'k',
    model: 'claude-haiku-5-5',
    effort: 'low',
  })
})
Deno.test('overrides', () => {
  assertEquals(
    modelConfigFromEnv(env({ ANTHROPIC_API_KEY: 'k', CLAUDE_MODEL: 'claude-sonnet-5-5', CLAUDE_EFFORT: 'medium' })),
    { apiKey: 'k', model: 'claude-sonnet-5-5', effort: 'medium' },
  )
})
Deno.test('bad_effort_falls_back_low', () => {
  assertEquals(modelConfigFromEnv(env({ ANTHROPIC_API_KEY: 'k', CLAUDE_EFFORT: 'max' }))?.effort, 'low')
})
Deno.test('missing_key_null', () => {
  assertEquals(modelConfigFromEnv(env({})), null)
})
