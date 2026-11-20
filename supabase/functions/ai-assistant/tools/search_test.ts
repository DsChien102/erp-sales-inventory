import { assertEquals } from 'jsr:@std/assert@1'
import { searchTool } from './search.ts'
import { fakeRpc, makeCtx } from './test_util.ts'

Deno.test('don_ban truyền actor_id = ctx.actorId, gioi_han 50 ⇒ 5', async () => {
  const { rpc, calls } = fakeRpc({
    'sales.search_sales_orders': {
      items: [{
        salesOrderId: 'o1',
        orderNumber: 'HD01',
        committedAt: '2026-11-16T03:00:00.000Z',
        customer: { displayName: 'Lan', phone: '09' },
        total: { amountMinor: 150000 },
      }],
    },
  })
  const out = await searchTool.run({
    loai: 'don_ban',
    tu_khoa: 'HD01',
    gioi_han: 50,
  }, makeCtx(rpc))
  assertEquals(calls[0].args.actor_id, 'actor-1')
  assertEquals(calls[0].args.tenant_id, 'tenant-1')
  assertEquals(calls[0].args.page_size, 5)
  assertEquals(calls[0].args.search_text, 'HD01')
  if (out.kind !== 'data') throw new Error('expected data')
  assertEquals(JSON.stringify(out.forModel).includes('09'), false)
  assertEquals(out.block?.dong[0].mo, { loai: 'don_ban', id: 'o1' })
  assertEquals(out.block?.dong[0].o.tong_tien, 150000)
})

Deno.test('khach_hang dùng p_role customer, bỏ SĐT / email', async () => {
  const { rpc, calls } = fakeRpc({
    'partner.search_partners': [{
      items: [{
        partner_id: 'c1',
        display_name: 'Lan',
        phone: '0988',
        email: 'a@b.c',
      }],
      page: 1,
      limit: 5,
      total: 1,
    }],
  })
  const out = await searchTool.run(
    { loai: 'khach_hang', tu_khoa: 'Lan' },
    makeCtx(rpc),
  )
  assertEquals(calls[0].args, {
    p_tenant_id: 'tenant-1',
    p_query: 'Lan',
    p_role: 'customer',
    p_limit: 5,
  })
  if (out.kind !== 'data') throw new Error('expected data')
  assertEquals(out.forModel, { ket_qua: [{ id: 'c1', ten: 'Lan' }] })
  assertEquals(out.block?.dong[0].mo, { loai: 'khach_hang', id: 'c1' })
})

Deno.test('san_pham gọi catalog.search_products', async () => {
  const { rpc, calls } = fakeRpc({
    'catalog.search_products': [{
      product_id: 'p1',
      name: 'Sữa',
      sku: 'S1',
      stock_qty: 7,
      base_unit_name: 'hộp',
    }],
  })
  const out = await searchTool.run({
    loai: 'san_pham',
    tu_khoa: 'sữa',
    gioi_han: 3,
  }, makeCtx(rpc))
  assertEquals(calls[0].args, {
    p_tenant_id: 'tenant-1',
    p_keyword: 'sữa',
    p_limit: 3,
  })
  if (out.kind !== 'data') throw new Error('expected data')
  assertEquals(out.block?.dong[0].mo, { loai: 'san_pham', id: 'p1' })
})

Deno.test('loai lạ hoặc thiếu từ khoá ⇒ bad_args', async () => {
  const { rpc, calls } = fakeRpc({})
  assertEquals(
    (await searchTool.run({ loai: 'nha_cung_cap', tu_khoa: 'x' }, makeCtx(rpc)))
      .kind,
    'bad_args',
  )
  assertEquals(
    (await searchTool.run({ loai: 'san_pham', tu_khoa: '  ' }, makeCtx(rpc)))
      .kind,
    'bad_args',
  )
  assertEquals(calls.length, 0)
})
