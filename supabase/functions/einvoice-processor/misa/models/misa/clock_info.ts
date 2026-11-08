import { MeInvoiceJsonHelpers as J } from '../../internal/json_helpers.ts'

export interface MeInvoiceClockInfoInit {
  clockOrder?: number | null
  clockCode?: string | null
  clockSeri?: string | null
  lastIndex?: number | null
  firstIndex?: number | null
  coefficient?: number | null
  refuelerNo?: string | null
  lotNo?: string | null
  startMeter?: number | null
  endMeter?: number | null
  temperature?: number | null
  density?: number | null
  gallon?: number | null
  liters?: number | null
  clockStatus?: number | null
  clockCodeOld?: string | null
  clockSeriOld?: string | null
  lastIndexOld?: number | null
  firstIndexOld?: number | null
  coefficientOld?: number | null
}

export class MeInvoiceClockInfo {
  readonly clockOrder: number | null
  readonly clockCode: string | null
  readonly clockSeri: string | null
  readonly lastIndex: number | null
  readonly firstIndex: number | null
  readonly coefficient: number | null
  readonly refuelerNo: string | null
  readonly lotNo: string | null
  readonly startMeter: number | null
  readonly endMeter: number | null
  readonly temperature: number | null
  readonly density: number | null
  readonly gallon: number | null
  readonly liters: number | null
  readonly clockStatus: number | null
  readonly clockCodeOld: string | null
  readonly clockSeriOld: string | null
  readonly lastIndexOld: number | null
  readonly firstIndexOld: number | null
  readonly coefficientOld: number | null
  constructor(init: MeInvoiceClockInfoInit = {}) {
    this.clockOrder = init.clockOrder ?? null
    this.clockCode = init.clockCode ?? null
    this.clockSeri = init.clockSeri ?? null
    this.lastIndex = init.lastIndex ?? null
    this.firstIndex = init.firstIndex ?? null
    this.coefficient = init.coefficient ?? null
    this.refuelerNo = init.refuelerNo ?? null
    this.lotNo = init.lotNo ?? null
    this.startMeter = init.startMeter ?? null
    this.endMeter = init.endMeter ?? null
    this.temperature = init.temperature ?? null
    this.density = init.density ?? null
    this.gallon = init.gallon ?? null
    this.liters = init.liters ?? null
    this.clockStatus = init.clockStatus ?? null
    this.clockCodeOld = init.clockCodeOld ?? null
    this.clockSeriOld = init.clockSeriOld ?? null
    this.lastIndexOld = init.lastIndexOld ?? null
    this.firstIndexOld = init.firstIndexOld ?? null
    this.coefficientOld = init.coefficientOld ?? null
  }

  static fromJson(json: Record<string, unknown>): MeInvoiceClockInfo {
    return new MeInvoiceClockInfo({
      clockOrder: J.readInt(json, 'ClockOrder'),
      clockCode: J.readString(json, 'ClockCode'),
      clockSeri: J.readString(json, 'ClockSeri'),
      lastIndex: J.readDouble(json, 'LastIndex'),
      firstIndex: J.readDouble(json, 'FirstIndex'),
      coefficient: J.readDouble(json, 'Coefficient'),
      refuelerNo: J.readString(json, 'RefuelerNo'),
      lotNo: J.readString(json, 'LotNo'),
      startMeter: J.readDouble(json, 'StartMeter'),
      endMeter: J.readDouble(json, 'EndMeter'),
      temperature: J.readDouble(json, 'Temperature'),
      density: J.readDouble(json, 'Density'),
      gallon: J.readDouble(json, 'Gallon'),
      liters: J.readDouble(json, 'Liters'),
      clockStatus: J.readInt(json, 'ClockStatus'),
      clockCodeOld: J.readString(json, 'ClockCodeOld'),
      clockSeriOld: J.readString(json, 'ClockSeriOld'),
      lastIndexOld: J.readDouble(json, 'LastIndexOld'),
      firstIndexOld: J.readDouble(json, 'FirstIndexOld'),
      coefficientOld: J.readDouble(json, 'CoefficientOld'),
    })
  }

  toJson(): Record<string, unknown> {
    const map: Record<string, unknown> = {}
    J.writeIfPresent(map, 'ClockOrder', this.clockOrder)
    J.writeIfPresent(map, 'ClockCode', this.clockCode)
    J.writeIfPresent(map, 'ClockSeri', this.clockSeri)
    J.writeIfPresent(map, 'LastIndex', this.lastIndex)
    J.writeIfPresent(map, 'FirstIndex', this.firstIndex)
    J.writeIfPresent(map, 'Coefficient', this.coefficient)
    J.writeIfPresent(map, 'RefuelerNo', this.refuelerNo)
    J.writeIfPresent(map, 'LotNo', this.lotNo)
    J.writeIfPresent(map, 'StartMeter', this.startMeter)
    J.writeIfPresent(map, 'EndMeter', this.endMeter)
    J.writeIfPresent(map, 'Temperature', this.temperature)
    J.writeIfPresent(map, 'Density', this.density)
    J.writeIfPresent(map, 'Gallon', this.gallon)
    J.writeIfPresent(map, 'Liters', this.liters)
    J.writeIfPresent(map, 'ClockStatus', this.clockStatus)
    J.writeIfPresent(map, 'ClockCodeOld', this.clockCodeOld)
    J.writeIfPresent(map, 'ClockSeriOld', this.clockSeriOld)
    J.writeIfPresent(map, 'LastIndexOld', this.lastIndexOld)
    J.writeIfPresent(map, 'FirstIndexOld', this.firstIndexOld)
    J.writeIfPresent(map, 'CoefficientOld', this.coefficientOld)
    return map
  }
}
