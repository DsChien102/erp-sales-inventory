import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_einvoice_domain/domain.dart';

/// In-memory [IDeliveryReadGateway] for query handler tests.
final class FakeDeliveryReadGateway implements IDeliveryReadGateway {
  FakeDeliveryReadGateway({
    SendInvoiceSheetContextDto? sheet,
    InvoiceDeliveryHistoryDto? history,
  }) : _sheet =
           sheet ??
           const SendInvoiceSheetContextDto(
             mode: SendInvoiceSheetMode.send,
             suggestedEmail: null,
             suggestedEmailSource: null,
             history: [],
             operationLocked: false,
             displayState: DeliveryDisplayState.notSent,
           ),
       _history =
           history ??
           const InvoiceDeliveryHistoryDto(
             deliveries: [],
             displayState: DeliveryDisplayState.notSent,
             hasSecondaryAttention: false,
           );

  final SendInvoiceSheetContextDto _sheet;
  final InvoiceDeliveryHistoryDto _history;

  String? lastSheetTenantId;
  String? lastSheetActorId;
  String? lastSheetSalesOrderId;
  String? lastHistoryTenantId;
  String? lastHistoryActorId;
  String? lastHistorySalesOrderId;

  @override
  Future<SendInvoiceSheetContextDto> getSendSheetContext({
    required String tenantId,
    required String actorId,
    required String salesOrderId,
  }) async {
    lastSheetTenantId = tenantId;
    lastSheetActorId = actorId;
    lastSheetSalesOrderId = salesOrderId;
    return _sheet;
  }

  @override
  Future<InvoiceDeliveryHistoryDto> getHistory({
    required String tenantId,
    required String actorId,
    required String salesOrderId,
  }) async {
    lastHistoryTenantId = tenantId;
    lastHistoryActorId = actorId;
    lastHistorySalesOrderId = salesOrderId;
    return _history;
  }
}
