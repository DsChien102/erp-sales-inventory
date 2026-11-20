import { assertEquals } from 'jsr:@std/assert@1'
import { fakeRpc, makeCtx } from './test_util.ts'
import { stockMovementTool, stockOverviewTool } from './stock.ts'

const OVERVIEW = {
  products: [
    {
      product_id: 'a',
      name: 'Sữa tươi',
      code: 'S1',
      base_uom: 'hộp',
      available: 3,
      has_expired: false,
      has_near_expiry: false,
      reorder_threshold: 5,
    },
    {
      product_id: 'b',
      name: 'Bánh quy',
      code: 'B1',
      base_uom: 'gói',
      available: 0,
      has_expired: false,
      has_near_expiry: false,
      reorder_threshold: 5,
    },
    {
      product_id: 'c',
      name: 'Thuốc ho',
      code: 'T1',
      base_uom: 'chai',
      available: 50,
      has_expired: false,
      has_near_expiry: true,
      reorder_threshold: 5,
    },
    {
      product_id: 'd',
      name: 'Nước suối',
      code: 'N1',
      base_uom: 'chai',
      available: 2,
      has_expired: false,
      has_near_expiry: false,
      reorder_threshold: null,
    },
  ],
}

async function names(args: Record<string, unknown>): Promise<string[]> {
  const { rpc } = fakeRpc({ 'inventory.list_stock_overview': OVERVIEW })
  const out = await stockOverviewTool.run(args, makeCtx(rpc))
  if (out.kind !== 'data') throw new Error('expected data')
  return (out.forModel as { dong: { ten: string }[] }).dong.map((d) => d.ten)
}

Deno.test('sap_het: chỉ hàng có ngưỡng và 0 < tồn ≤ ngưỡng', async () => {
  assertEquals(await names({ loc: 'sap_het' }), ['Sữa tươi'])
})

Deno.test('het_hang: tồn ≤ 0', async () => {
  assertEquals(await names({ loc: 'het_hang' }), ['Bánh quy'])
})

Deno.test('can_han: cận hoặc quá hạn', async () => {
  assertEquals(await names({ loc: 'can_han' }), ['Thuốc ho'])
})

Deno.test('tat_ca + tu_khoa không dấu', async () => {
  assertEquals((await names({})).length, 4)
  assertEquals(await names({ tu_khoa: 'sua' }), ['Sữa tươi'])
  assertEquals(await names({ tu_khoa: 'n1' }), ['Nước suối'])
})

Deno.test('gioi_han cắt dòng nhưng so_mat_hang là số khớp', async () => {
  const { rpc } = fakeRpc({ 'inventory.list_stock_overview': OVERVIEW })
  const out = await stockOverviewTool.run({ gioi_han: 2 }, makeCtx(rpc))
  if (out.kind !== 'data') throw new Error('expected data')
  const m = out.forModel as { so_mat_hang: number; dong: unknown[] }
  assertEquals(m.so_mat_hang, 4)
  assertEquals(m.dong.length, 2)
  assertEquals(out.block?.dong[0].mo?.loai, 'san_pham')
})

Deno.test('loc lạ ⇒ bad_args', async () => {
  const { rpc, calls } = fakeRpc({})
  assertEquals(
    (await stockOverviewTool.run({ loc: 'tat_ca_hang' }, makeCtx(rpc))).kind,
    'bad_args',
  )
  assertEquals(calls.length, 0)
})

Deno.test('bien_dong_kho: san_pham_id không phải uuid ⇒ bad_args', async () => {
  const { rpc, calls } = fakeRpc({})
  const out = await stockMovementTool.run({ san_pham_id: 'Sữa' }, makeCtx(rpc))
  assertEquals(out.kind, 'bad_args')
  assertEquals(calls.length, 0)
})

Deno.test('bien_dong_kho: tóm tắt từ thẻ kho', async () => {
  const id = '11111111-1111-4111-8111-111111111111'
  const rows = Array.from({ length: 25 }, (_, i) => ({
    business_date: '2026-11-10',
    movement_kind: 'RECEIPT',
    quantity_delta: 1,
    balance_after: i,
  }))
  const { rpc, calls } = fakeRpc({
    'inventory.get_stock_card': {
      product: { name: 'Sữa tươi', uom: 'hộp' },
      summary: { opening_qty: 10, in_qty: 25, out_qty: 5, closing_qty: 30 },
      rows,
    },
  })
  const out = await stockMovementTool.run(
    { san_pham_id: id, ky: 'thang_nay' },
    makeCtx(rpc),
  )
  if (out.kind !== 'data') throw new Error('expected data')
  assertEquals(calls[0].args, {
    p_tenant_id: 'tenant-1',
    p_product_id: id,
    p_from: '2026-11-01',
    p_to: '2026-11-16',
  })
  const m = out.forModel as Record<string, unknown>
  assertEquals([m.ton_dau, m.tong_nhap, m.tong_xuat, m.ton_cuoi, m.so_dong], [
    10,
    25,
    5,
    30,
    25,
  ])
  assertEquals(out.block?.dong.length, 20)
  assertEquals(out.block?.dong[19].o.ton_sau, 24)
})
