import { assertEquals } from 'jsr:@std/assert@1'
import { salesStatsTool } from './sales_stats.ts'
import { fakeRpc, makeCtx } from './test_util.ts'

const STATS = (total: number, rows: unknown[] = []) => ({ total, rows })

Deno.test('ánh xạ enum sang RPC', async () => {
  const { rpc, calls } = fakeRpc({ 'sales.get_sales_stats': STATS(5, []) })
  await salesStatsTool.run(
    {
      chi_so: 'gia_tri_tb_don',
      nhom_theo: 'khach_hang',
      ky: 'thang_nay',
      top_n: 99,
    },
    makeCtx(rpc),
  )
  assertEquals(calls.length, 1)
  assertEquals(calls[0].schema, 'sales')
  assertEquals(calls[0].fn, 'get_sales_stats')
  assertEquals(calls[0].args, {
    p_tenant_id: 'tenant-1',
    p_metric: 'avg_order_value',
    p_group_by: 'customer',
    p_from: '2026-11-01',
    p_to: '2026-11-16',
    p_top_n: 20,
  })
})

Deno.test('so_sanh_ky_truoc gọi 2 lần, lần 2 là kỳ trước', async () => {
  const { rpc, calls } = fakeRpc({ 'sales.get_sales_stats': STATS(100) })
  const out = await salesStatsTool.run(
    { chi_so: 'doanh_thu', ky: 'tuan_nay', so_sanh_ky_truoc: true },
    makeCtx(rpc, '2026-11-18'),
  )
  assertEquals(calls.length, 2)
  assertEquals(calls[0].args.p_from, '2026-11-16')
  assertEquals(calls[1].args.p_from, '2026-11-13')
  assertEquals(calls[1].args.p_to, '2026-11-15')
  if (out.kind !== 'data') throw new Error('expected data')
  assertEquals(
    (out.forModel as { ky_truoc: { tong: number } }).ky_truoc.tong,
    100,
  )
})

Deno.test('chi_so lạ ⇒ bad_args, không gọi RPC', async () => {
  const { rpc, calls } = fakeRpc({})
  const out = await salesStatsTool.run({ chi_so: 'loi_nhuan' }, makeCtx(rpc))
  assertEquals(out.kind, 'bad_args')
  assertEquals(calls.length, 0)
})

Deno.test('thiếu chi_so ⇒ bad_args', async () => {
  const { rpc, calls } = fakeRpc({})
  assertEquals((await salesStatsTool.run({}, makeCtx(rpc))).kind, 'bad_args')
  assertEquals(calls.length, 0)
})

Deno.test('tuy_chon thiếu ngày ⇒ bad_args, không gọi RPC', async () => {
  const { rpc, calls } = fakeRpc({})
  const out = await salesStatsTool.run(
    { chi_so: 'doanh_thu', ky: 'tuy_chon' },
    makeCtx(rpc),
  )
  assertEquals(out.kind, 'bad_args')
  assertEquals(calls.length, 0)
})

Deno.test('nhóm theo sản phẩm có mo; walk_in không có mo', async () => {
  const rows = [
    { key: 'p-1', label: 'SP Một', value: 300 },
    { key: 'walk_in', label: 'Khách lẻ', value: 100 },
  ]
  const { rpc } = fakeRpc({ 'sales.get_sales_stats': STATS(400, rows) })
  const prod = await salesStatsTool.run({
    chi_so: 'doanh_thu',
    nhom_theo: 'san_pham',
  }, makeCtx(rpc))
  if (prod.kind !== 'data' || !prod.block) throw new Error('expected block')
  assertEquals(prod.block.dong[0].mo, { loai: 'san_pham', id: 'p-1' })
  assertEquals(prod.block.dong[0].o, { nhom: 'SP Một', gia_tri: 300 })

  const cust = await salesStatsTool.run({
    chi_so: 'doanh_thu',
    nhom_theo: 'khach_hang',
  }, makeCtx(rpc))
  if (cust.kind !== 'data' || !cust.block) throw new Error('expected block')
  assertEquals(cust.block.dong[0].mo, { loai: 'khach_hang', id: 'p-1' })
  assertEquals(cust.block.dong[1].mo, undefined)
})

Deno.test('không nhóm ⇒ không có bảng', async () => {
  const { rpc } = fakeRpc({ 'sales.get_sales_stats': STATS(1234) })
  const out = await salesStatsTool.run({ chi_so: 'doanh_thu' }, makeCtx(rpc))
  if (out.kind !== 'data') throw new Error('expected data')
  assertEquals(out.block, undefined)
  assertEquals((out.forModel as { tong: number }).tong, 1234)
})

Deno.test('tiêu đề bảng có dấu tiếng Việt', async () => {
  const { rpc } = fakeRpc({ 'sales.get_sales_stats': STATS(1, [{ key: 'k', label: 'L', value: 1 }]) })
  const expected: Record<string, string> = {
    ngay: 'Doanh thu theo ngày',
    tuan: 'Doanh thu theo tuần',
    thang: 'Doanh thu theo tháng',
    san_pham: 'Doanh thu theo sản phẩm',
    khach_hang: 'Doanh thu theo khách hàng',
    nhan_vien: 'Doanh thu theo nhân viên',
  }
  for (const [nhom, title] of Object.entries(expected)) {
    const out = await salesStatsTool.run({ chi_so: 'doanh_thu', nhom_theo: nhom }, makeCtx(rpc))
    if (out.kind !== 'data') throw new Error('expected data')
    assertEquals(out.block?.tieu_de, title)
  }
})
