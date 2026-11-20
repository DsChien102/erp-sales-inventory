import { MeInvoiceJsonHelpers as J } from '../../internal/json_helpers.ts'

export interface MeInvoiceTemplateInit {
  ipTemplateId: string
  companyId?: number | null
  templateName: string
  invTemplateNo: string
  invSeries: string
  orgInvSeries?: string | null
  createdDate?: string | null
  modifiedDate?: string | null
  inactive?: boolean
  isInheritFromOldTemplate?: boolean
  isSendSummary?: boolean
  isTemplatePetrol?: boolean
  isMoreVatRate?: boolean
}

/** §13.1 Template — mẫu hóa đơn. */
export class MeInvoiceTemplate {
  readonly ipTemplateId: string
  readonly companyId: number | null
  readonly templateName: string
  readonly invTemplateNo: string
  readonly invSeries: string
  readonly orgInvSeries: string | null
  readonly createdDate: string | null
  readonly modifiedDate: string | null
  readonly inactive: boolean
  readonly isInheritFromOldTemplate: boolean
  readonly isSendSummary: boolean
  readonly isTemplatePetrol: boolean
  readonly isMoreVatRate: boolean

  constructor(i: MeInvoiceTemplateInit) {
    this.ipTemplateId = i.ipTemplateId
    this.companyId = i.companyId ?? null
    this.templateName = i.templateName
    this.invTemplateNo = i.invTemplateNo
    this.invSeries = i.invSeries
    this.orgInvSeries = i.orgInvSeries ?? null
    this.createdDate = i.createdDate ?? null
    this.modifiedDate = i.modifiedDate ?? null
    this.inactive = i.inactive ?? false
    this.isInheritFromOldTemplate = i.isInheritFromOldTemplate ?? false
    this.isSendSummary = i.isSendSummary ?? false
    this.isTemplatePetrol = i.isTemplatePetrol ?? false
    this.isMoreVatRate = i.isMoreVatRate ?? false
  }

  static fromJson(json: Record<string, unknown>): MeInvoiceTemplate {
    return new MeInvoiceTemplate({
      ipTemplateId: J.readString(json, 'IPTemplateID') ?? '',
      companyId: J.readInt(json, 'CompanyID'),
      templateName: J.readString(json, 'TemplateName') ?? '',
      invTemplateNo: J.readString(json, 'InvTemplateNo') ?? '',
      invSeries: J.readString(json, 'InvSeries') ?? '',
      orgInvSeries: J.readString(json, 'OrgInvSeries'),
      createdDate: J.readString(json, 'CreatedDate'),
      modifiedDate: J.readString(json, 'ModifiedDate'),
      inactive: J.readBool(json, 'Inactive') ?? false,
      isInheritFromOldTemplate: J.readBool(json, 'IsInheritFromOldTemplate') ?? false,
      isSendSummary: J.readBool(json, 'IsSendSummary') ?? false,
      isTemplatePetrol: J.readBool(json, 'IsTemplatePetrol') ?? false,
      isMoreVatRate: J.readBool(json, 'IsMoreVATRate') ?? false,
    })
  }

  toJson(): Record<string, unknown> {
    const map: Record<string, unknown> = {
      IPTemplateID: this.ipTemplateId,
      TemplateName: this.templateName,
      InvTemplateNo: this.invTemplateNo,
      InvSeries: this.invSeries,
      Inactive: this.inactive,
      IsInheritFromOldTemplate: this.isInheritFromOldTemplate,
      IsSendSummary: this.isSendSummary,
      IsTemplatePetrol: this.isTemplatePetrol,
      IsMoreVATRate: this.isMoreVatRate,
    }
    J.writeIfPresent(map, 'CompanyID', this.companyId)
    J.writeStringIfPresent(map, 'OrgInvSeries', this.orgInvSeries)
    J.writeStringIfPresent(map, 'CreatedDate', this.createdDate)
    J.writeStringIfPresent(map, 'ModifiedDate', this.modifiedDate)
    return map
  }
}
