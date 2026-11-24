import { MeInvoiceJsonHelpers as J } from '../../internal/json_helpers.ts'

export interface MeInvoiceOtherInfoInit {
  fieldName?: string | null
  dataType?: string | null
  fieldValue?: string | null
}

export class MeInvoiceOtherInfo {
  readonly fieldName: string | null
  readonly dataType: string | null
  readonly fieldValue: string | null
  constructor(init: MeInvoiceOtherInfoInit = {}) {
    this.fieldName = init.fieldName ?? null
    this.dataType = init.dataType ?? null
    this.fieldValue = init.fieldValue ?? null
  }

  static fromJson(json: Record<string, unknown>): MeInvoiceOtherInfo {
    return new MeInvoiceOtherInfo({
      fieldName: J.readString(json, 'FieldName'),
      dataType: J.readString(json, 'DataType'),
      fieldValue: J.readString(json, 'FieldValue'),
    })
  }

  toJson(): Record<string, unknown> {
    const map: Record<string, unknown> = {}
    J.writeIfPresent(map, 'FieldName', this.fieldName)
    J.writeIfPresent(map, 'DataType', this.dataType)
    J.writeIfPresent(map, 'FieldValue', this.fieldValue)
    return map
  }
}
