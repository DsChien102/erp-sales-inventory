import '../../internal/json_helpers.dart';

/// §13.1 Template — mẫu hóa đơn.
final class MeInvoiceTemplate {
  const MeInvoiceTemplate({
    required this.ipTemplateId,
    this.companyId,
    required this.templateName,
    required this.invTemplateNo,
    required this.invSeries,
    this.orgInvSeries,
    this.createdDate,
    this.modifiedDate,
    this.inactive = false,
    this.isInheritFromOldTemplate = false,
    this.isSendSummary = false,
    this.isTemplatePetrol = false,
    this.isMoreVatRate = false,
  });

  final String ipTemplateId;
  final int? companyId;
  final String templateName;
  final String invTemplateNo;
  final String invSeries;
  final String? orgInvSeries;
  final String? createdDate;
  final String? modifiedDate;
  final bool inactive;
  final bool isInheritFromOldTemplate;
  final bool isSendSummary;
  final bool isTemplatePetrol;
  final bool isMoreVatRate;

  factory MeInvoiceTemplate.fromJson(Map<String, dynamic> json) {
    return MeInvoiceTemplate(
      ipTemplateId:
          MeInvoiceJsonHelpers.readString(json, 'IPTemplateID') ?? '',
      companyId: MeInvoiceJsonHelpers.readInt(json, 'CompanyID'),
      templateName:
          MeInvoiceJsonHelpers.readString(json, 'TemplateName') ?? '',
      invTemplateNo:
          MeInvoiceJsonHelpers.readString(json, 'InvTemplateNo') ?? '',
      invSeries: MeInvoiceJsonHelpers.readString(json, 'InvSeries') ?? '',
      orgInvSeries: MeInvoiceJsonHelpers.readString(json, 'OrgInvSeries'),
      createdDate: MeInvoiceJsonHelpers.readString(json, 'CreatedDate'),
      modifiedDate: MeInvoiceJsonHelpers.readString(json, 'ModifiedDate'),
      inactive: MeInvoiceJsonHelpers.readBool(json, 'Inactive') ?? false,
      isInheritFromOldTemplate: MeInvoiceJsonHelpers.readBool(
            json,
            'IsInheritFromOldTemplate',
          ) ??
          false,
      isSendSummary:
          MeInvoiceJsonHelpers.readBool(json, 'IsSendSummary') ?? false,
      isTemplatePetrol: MeInvoiceJsonHelpers.readBool(
            json,
            'IsTemplatePetrol',
          ) ??
          false,
      isMoreVatRate:
          MeInvoiceJsonHelpers.readBool(json, 'IsMoreVATRate') ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'IPTemplateID': ipTemplateId,
      'TemplateName': templateName,
      'InvTemplateNo': invTemplateNo,
      'InvSeries': invSeries,
      'Inactive': inactive,
      'IsInheritFromOldTemplate': isInheritFromOldTemplate,
      'IsSendSummary': isSendSummary,
      'IsTemplatePetrol': isTemplatePetrol,
      'IsMoreVATRate': isMoreVatRate,
    };
    MeInvoiceJsonHelpers.writeIfPresent(map, 'CompanyID', companyId);
    MeInvoiceJsonHelpers.writeStringIfPresent(map, 'OrgInvSeries', orgInvSeries);
    MeInvoiceJsonHelpers.writeStringIfPresent(map, 'CreatedDate', createdDate);
    MeInvoiceJsonHelpers.writeStringIfPresent(map, 'ModifiedDate', modifiedDate);
    return map;
  }
}
