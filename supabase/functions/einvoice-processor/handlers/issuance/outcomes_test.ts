import { assertEquals, assertThrows } from 'jsr:@std/assert@1'
import {
  delayBeforeCheckSeconds,
  RECONCILIATION_MAX_CHECKS,
  shouldMarkUnresolved,
} from './outcomes.ts'

Deno.test('ReconciliationSchedule maxChecks constant is 5', () => {
  assertEquals(RECONCILIATION_MAX_CHECKS, 5)
})

Deno.test('ReconciliationSchedule poll cadence is exact and one-based', () => {
  assertEquals(delayBeforeCheckSeconds(1), 30)
  assertEquals(delayBeforeCheckSeconds(2), 120)
  assertEquals(delayBeforeCheckSeconds(3), 600)
  assertEquals(delayBeforeCheckSeconds(4), 1800)
  assertEquals(delayBeforeCheckSeconds(5), 7200)
})

Deno.test('ReconciliationSchedule throws RangeError when checkSequence is out of bounds (< 1 or > 5)', () => {
  assertThrows(() => delayBeforeCheckSeconds(0), RangeError)
  assertThrows(() => delayBeforeCheckSeconds(-1), RangeError)
  assertThrows(() => delayBeforeCheckSeconds(6), RangeError)
  assertThrows(() => delayBeforeCheckSeconds(10), RangeError)
})

Deno.test('ReconciliationSchedule shouldMarkUnresolved marks unresolved starting at maxChecks', () => {
  assertEquals(shouldMarkUnresolved(0), false)
  assertEquals(shouldMarkUnresolved(1), false)
  assertEquals(shouldMarkUnresolved(2), false)
  assertEquals(shouldMarkUnresolved(3), false)
  assertEquals(shouldMarkUnresolved(4), false)
  assertEquals(shouldMarkUnresolved(5), true)
  assertEquals(shouldMarkUnresolved(6), true)
})

