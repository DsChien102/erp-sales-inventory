import { assertEquals, assertNotEquals } from 'jsr:@std/assert@1'
import { providerCallReference } from './provider_call_reference.ts'

Deno.test(
  'S4 worker command serialization provider-call correlation differs per worker attempt',
  async () => {
    const first = await providerCallReference('cmd-1', 1)
    const second = await providerCallReference('cmd-1', 2)

    assertNotEquals(first, second)
  },
)

Deno.test('provider call reference matches Dart vector', async () => {
  const ref = await providerCallReference('cmd-1', 1)
  assertEquals(ref, '7d99ddea-18d5-bea4-c874-7b0de44f56a5')
})
