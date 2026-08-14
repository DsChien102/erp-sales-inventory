import '../../internal/json_helpers.dart';

/// §13.2 Ticket — mẫu vé.
final class MeInvoiceTicket {
  const MeInvoiceTicket({
    required this.ticketTemplateId,
    required this.templateName,
    required this.invSeries,
    this.inactive = false,
    this.ticketType,
    this.serviceName,
    this.isInheritFromOldTemplate = false,
    this.isTicketCode = false,
  });

  final String ticketTemplateId;
  final String templateName;
  final String invSeries;
  final bool inactive;
  final int? ticketType;
  final String? serviceName;
  final bool isInheritFromOldTemplate;
  final bool isTicketCode;

  factory MeInvoiceTicket.fromJson(Map<String, dynamic> json) {
    return MeInvoiceTicket(
      ticketTemplateId:
          MeInvoiceJsonHelpers.readString(json, 'TicketTemplateID') ?? '',
      templateName:
          MeInvoiceJsonHelpers.readString(json, 'TemplateName') ?? '',
      invSeries: MeInvoiceJsonHelpers.readString(json, 'InvSeries') ?? '',
      inactive: MeInvoiceJsonHelpers.readBool(json, 'Inactive') ?? false,
      ticketType: MeInvoiceJsonHelpers.readInt(json, 'TicketType'),
      serviceName: MeInvoiceJsonHelpers.readString(json, 'ServiceName'),
      isInheritFromOldTemplate: MeInvoiceJsonHelpers.readBool(
            json,
            'IsInheritFromOldTemplate',
          ) ??
          false,
      isTicketCode:
          MeInvoiceJsonHelpers.readBool(json, 'IsTicketCode') ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'TicketTemplateID': ticketTemplateId,
      'TemplateName': templateName,
      'InvSeries': invSeries,
      'Inactive': inactive,
      'IsInheritFromOldTemplate': isInheritFromOldTemplate,
      'IsTicketCode': isTicketCode,
    };
    MeInvoiceJsonHelpers.writeIfPresent(map, 'TicketType', ticketType);
    MeInvoiceJsonHelpers.writeStringIfPresent(map, 'ServiceName', serviceName);
    return map;
  }
}
