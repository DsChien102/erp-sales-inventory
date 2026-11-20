import { MeInvoiceJsonHelpers as J } from '../../internal/json_helpers.ts'

export interface MeInvoiceTicketInit {
  ticketTemplateId: string
  templateName: string
  invSeries: string
  inactive?: boolean
  ticketType?: number | null
  serviceName?: string | null
  isInheritFromOldTemplate?: boolean
  isTicketCode?: boolean
}

/** §13.2 Ticket — mẫu vé. */
export class MeInvoiceTicket {
  readonly ticketTemplateId: string
  readonly templateName: string
  readonly invSeries: string
  readonly inactive: boolean
  readonly ticketType: number | null
  readonly serviceName: string | null
  readonly isInheritFromOldTemplate: boolean
  readonly isTicketCode: boolean

  constructor(i: MeInvoiceTicketInit) {
    this.ticketTemplateId = i.ticketTemplateId
    this.templateName = i.templateName
    this.invSeries = i.invSeries
    this.inactive = i.inactive ?? false
    this.ticketType = i.ticketType ?? null
    this.serviceName = i.serviceName ?? null
    this.isInheritFromOldTemplate = i.isInheritFromOldTemplate ?? false
    this.isTicketCode = i.isTicketCode ?? false
  }

  static fromJson(json: Record<string, unknown>): MeInvoiceTicket {
    return new MeInvoiceTicket({
      ticketTemplateId: J.readString(json, 'TicketTemplateID') ?? '',
      templateName: J.readString(json, 'TemplateName') ?? '',
      invSeries: J.readString(json, 'InvSeries') ?? '',
      inactive: J.readBool(json, 'Inactive') ?? false,
      ticketType: J.readInt(json, 'TicketType'),
      serviceName: J.readString(json, 'ServiceName'),
      isInheritFromOldTemplate: J.readBool(json, 'IsInheritFromOldTemplate') ?? false,
      isTicketCode: J.readBool(json, 'IsTicketCode') ?? false,
    })
  }

  toJson(): Record<string, unknown> {
    const map: Record<string, unknown> = {
      TicketTemplateID: this.ticketTemplateId,
      TemplateName: this.templateName,
      InvSeries: this.invSeries,
      Inactive: this.inactive,
      IsInheritFromOldTemplate: this.isInheritFromOldTemplate,
      IsTicketCode: this.isTicketCode,
    }
    J.writeIfPresent(map, 'TicketType', this.ticketType)
    J.writeStringIfPresent(map, 'ServiceName', this.serviceName)
    return map
  }
}
