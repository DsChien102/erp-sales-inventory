import { assertEquals } from 'jsr:@std/assert@1'
import { unsupportedTool } from './unsupported.ts'
import { fakeRpc, makeCtx } from './test_util.ts'

Deno.test('loai hợp lệ ⇒ unsupported đúng loại', async () => {
  const { rpc } = fakeRpc({})
  for (const loai of ['ngoai_pham_vi', 'chua_ho_tro', 'tu_choi'] as const) {
    assertEquals(await unsupportedTool.run({ loai }, makeCtx(rpc)), {
      kind: 'unsupported',
      status: loai,
    })
  }
})

Deno.test('loai lạ ⇒ bad_args', async () => {
  const { rpc } = fakeRpc({})
  assertEquals(
    (await unsupportedTool.run({ loai: 'khac' }, makeCtx(rpc))).kind,
    'bad_args',
  )
})
