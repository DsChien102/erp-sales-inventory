import type {
  DeliveryObservationContext,
  DeliveryObservationOutcome,
} from './outcomes.ts'

export interface DeliveryObservationProvider {
  observe(ctx: DeliveryObservationContext): Promise<DeliveryObservationOutcome>
}

export function createMisaDeliveryObservationProvider(): DeliveryObservationProvider {
  return {
    observe(_ctx: DeliveryObservationContext): Promise<DeliveryObservationOutcome> {
      return Promise.resolve({ kind: 'unsupported' })
    },
  }
}
