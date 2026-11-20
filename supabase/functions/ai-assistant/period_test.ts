import { assertEquals } from 'jsr:@std/assert@1'
import { previousPeriod, resolvePeriod, todayInVietnam } from './period.ts'

const ok = (r: ReturnType<typeof resolvePeriod>) => {
  if (!r.ok) throw new Error(`expected ok, got ${r.chi_tiet}`)
  return r.range
}

Deno.test('hom_nay là mặc định khi thiếu ky', () => {
  assertEquals(ok(resolvePeriod({}, '2026-11-16')), {
    from: '2026-11-16',
    to: '2026-11-16',
  })
})

Deno.test('hom_qua', () => {
  assertEquals(ok(resolvePeriod({ ky: 'hom_qua' }, '2026-11-01')), {
    from: '2026-10-31',
    to: '2026-10-31',
  })
})

Deno.test('tuần bắt đầu thứ Hai: 16/11/2026 là thứ Hai', () => {
  assertEquals(ok(resolvePeriod({ ky: 'tuan_nay' }, '2026-11-16')), {
    from: '2026-11-16',
    to: '2026-11-16',
  })
  assertEquals(ok(resolvePeriod({ ky: 'tuan_truoc' }, '2026-11-16')), {
    from: '2026-11-09',
    to: '2026-11-15',
  })
  assertEquals(ok(resolvePeriod({ ky: 'tuan_nay' }, '2026-11-18')), {
    from: '2026-11-16',
    to: '2026-11-18',
  })
})

Deno.test('Chủ nhật thuộc tuần của thứ Hai trước đó', () => {
  assertEquals(ok(resolvePeriod({ ky: 'tuan_nay' }, '2026-11-22')), {
    from: '2026-11-16',
    to: '2026-11-22',
  })
})

Deno.test('thang_nay và thang_truoc (qua năm)', () => {
  assertEquals(ok(resolvePeriod({ ky: 'thang_nay' }, '2026-11-16')), {
    from: '2026-11-01',
    to: '2026-11-16',
  })
  assertEquals(ok(resolvePeriod({ ky: 'thang_truoc' }, '2026-01-10')), {
    from: '2025-12-01',
    to: '2025-12-31',
  })
})

Deno.test('tuy_chon hợp lệ', () => {
  assertEquals(
    ok(
      resolvePeriod({
        ky: 'tuy_chon',
        tu_ngay: '2026-10-01',
        den_ngay: '2026-10-31',
      }, '2026-11-16'),
    ),
    { from: '2026-10-01', to: '2026-10-31' },
  )
})

Deno.test('tuy_chon sai bị từ chối', () => {
  const today = '2026-11-16'
  const bad = [
    { ky: 'tuy_chon' },
    { ky: 'tuy_chon', tu_ngay: '2026-13-40', den_ngay: '2026-13-41' },
    { ky: 'tuy_chon', tu_ngay: '2026-10-31', den_ngay: '2026-10-01' },
    { ky: 'tuy_chon', tu_ngay: '2025-01-01', den_ngay: '2026-01-02' }, // 367 ngày
    { ky: 'tuy_chon', tu_ngay: 20261001, den_ngay: '2026-10-31' },
    { ky: 'nam_nay' },
    { ky: 42 },
  ]
  for (const input of bad) {
    assertEquals(resolvePeriod(input, today).ok, false, JSON.stringify(input))
  }
})

Deno.test('tuy_chon đúng 366 ngày vẫn được', () => {
  assertEquals(
    resolvePeriod({
      ky: 'tuy_chon',
      tu_ngay: '2025-01-01',
      den_ngay: '2026-01-01',
    }, '2026-11-16').ok,
    true,
  )
})

Deno.test('todayInVietnam đổi sang giờ VN', () => {
  assertEquals(todayInVietnam(new Date('2026-11-15T17:30:00Z')), '2026-11-16')
  assertEquals(todayInVietnam(new Date('2026-11-15T16:30:00Z')), '2026-11-15')
})

Deno.test('previousPeriod', () => {
  assertEquals(
    previousPeriod('thang_nay', { from: '2026-03-01', to: '2026-03-31' }),
    {
      from: '2026-02-01',
      to: '2026-02-28',
    },
  )
  assertEquals(
    previousPeriod('thang_nay', { from: '2026-11-01', to: '2026-11-16' }),
    {
      from: '2026-10-01',
      to: '2026-10-16',
    },
  )
  assertEquals(
    previousPeriod('thang_truoc', { from: '2026-10-01', to: '2026-10-31' }),
    {
      from: '2026-09-01',
      to: '2026-09-30',
    },
  )
  assertEquals(
    previousPeriod('tuan_nay', { from: '2026-11-16', to: '2026-11-18' }),
    {
      from: '2026-11-13',
      to: '2026-11-15',
    },
  )
  assertEquals(
    previousPeriod('hom_nay', { from: '2026-11-16', to: '2026-11-16' }),
    {
      from: '2026-11-15',
      to: '2026-11-15',
    },
  )
})
