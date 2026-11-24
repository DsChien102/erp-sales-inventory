import { assert, assertEquals, assertRejects } from 'jsr:@std/assert@1'
import { grossProfitTool } from './gross_profit.ts'
import { fakeRpc, makeCtx } from './test_util.ts'
import { RpcError } from './tool.ts'

Deno.test('PERMISSION_DENIED từ RPC được ném tiếp, không thành data', async () => {
  const { rpc } = fakeRpc({
    'inventory.get_gross_profit_report': new RpcError(
      'PERMISSION_DENIED',
      'no',
    ),
  })
  const err = await assertRejects(
    () => grossProfitTool.run({ ky: 'thang_nay' }, makeCtx(rpc)),
    RpcError,
  )
  assertEquals(err.code, 'PERMISSION_DENIED')
})

Deno.test('san_pham: top_n theo lãi gộp giảm dần, totals nguyên văn', async () => {
  const rows = [
    {
      product_id: 'a',
      name: 'A',
      net_revenue_vnd: 100,
      gross_profit_vnd: 10,
      margin_pct: 10,
    },
    {
      product_id: 'b',
      name: 'B',
      net_revenue_vnd: 200,
      gross_profit_vnd: 90,
      margin_pct: 45,
    },
    {
      product_id: 'c',
      name: 'C',
      net_revenue_vnd: 50,
      gross_profit_vnd: 30,
      margin_pct: 60,
    },
  ]
  const totals = { net_revenue: 350, gross_profit: 130 }
  const { rpc, calls } = fakeRpc({
    'inventory.get_gross_profit_report': { rows, totals },
  })
  const out = await grossProfitTool.run(
    { ky: 'thang_nay', top_n: 2 },
    makeCtx(rpc),
  )
  assertEquals(calls[0].args.p_mode, 'PRODUCT')
  if (out.kind !== 'data') throw new Error('expected data')
  const m = out.forModel as { tong: unknown; dong: { nhan: string }[] }
  assertEquals(m.tong, totals)
  assertEquals(m.dong.map((d) => d.nhan), ['B', 'C'])
  assertEquals(out.block?.dong[0].mo, { loai: 'san_pham', id: 'b' })
})

Deno.test('che_do don ánh xạ ORDER; che_do lạ ⇒ bad_args', async () => {
  const { rpc, calls } = fakeRpc({
    'inventory.get_gross_profit_report': { rows: [], totals: {} },
  })
  await grossProfitTool.run({ che_do: 'don' }, makeCtx(rpc))
  assertEquals(calls[0].args.p_mode, 'ORDER')
  assert(
    (await grossProfitTool.run({ che_do: 'x' }, makeCtx(rpc))).kind ===
      'bad_args',
  )
})
