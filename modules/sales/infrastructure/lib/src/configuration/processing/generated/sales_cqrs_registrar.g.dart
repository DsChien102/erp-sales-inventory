// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint

import 'package:get_it/get_it.dart';
import 'package:vet45_sales_application/application.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import '../internal_commands/supabase_sales_internal_command_client.dart';
import 'sales_command_registration.g.dart';

void registerGeneratedSalesValidators(GetIt container) {
  container
    ..registerFactory<ICommandValidator<CancelReturnExchangeCommand>>(
      CancelReturnExchangeCommandValidator.new,
    )
    ..registerFactory<ICommandValidator<CancelSalesOrderDraftCommand>>(
      CancelSalesOrderDraftCommandValidator.new,
    )
    ..registerFactory<ICommandValidator<CompleteReturnExchangeCommand>>(
      CompleteReturnExchangeCommandValidator.new,
    )
    ..registerFactory<ICommandValidator<ConfirmReturnExchangeCommand>>(
      ConfirmReturnExchangeCommandValidator.new,
    )
    ..registerFactory<ICommandValidator<ConfirmSalesOrderCancellationCommand>>(
      ConfirmSalesOrderCancellationCommandValidator.new,
    )
    ..registerFactory<ICommandValidator<FinalizeSalesOrderCommand>>(
      FinalizeSalesOrderCommandValidator.new,
    )
    ..registerFactory<ICommandValidator<RecordSalesPaymentCommand>>(
      RecordSalesPaymentCommandValidator.new,
    )
    ..registerFactory<ICommandValidator<RecordSalesRefundCommand>>(
      RecordSalesRefundCommandValidator.new,
    )
    ..registerFactory<ICommandValidator<SaveSalesOrderDraftCommand>>(
      SaveSalesOrderDraftCommandValidator.new,
    )
    ..registerFactory<ICommandValidator<StartReturnExchangeCommand>>(
      StartReturnExchangeCommandValidator.new,
    )
    ..registerFactory<ICommandValidator<UpdateReturnExchangeCommand>>(
      UpdateReturnExchangeCommandValidator.new,
    )
    ..registerFactory<ICommandValidator<UpdateSalesOrderDraftCommand>>(
      UpdateSalesOrderDraftCommandValidator.new,
    )
    ;
}

void registerGeneratedSalesHandlers({
  required CommandBus bus,
  required GetIt container,
  required ISalesInternalCommandClient internalCommandClient,
  ILogger? logger,
}) {
  registerGeneratedSalesValidators(container);

  SalesCommandRegistration.registerBusinessHandler<ArchiveSalesReceiptCommand, SalesReceiptDto, ArchiveSalesReceiptCommandHandler>(
    container: container,
    bus: bus,
    logger: logger,
    factory: () => ArchiveSalesReceiptCommandHandler(
      receiptGateway: container.get<ISalesReceiptGateway>(),
    ),
  );

  SalesCommandRegistration.registerBusinessHandler<CancelReturnExchangeCommand, ReturnExchangeResultDto, CancelReturnExchangeCommandHandler>(
    container: container,
    bus: bus,
    logger: logger,
    factory: () => CancelReturnExchangeCommandHandler(
      commandGateway: container.get<IReturnExchangeCommandGateway>(),
    ),
  );

  SalesCommandRegistration.registerBusinessHandler<CancelSalesOrderDraftCommand, SalesOrderDraftDto, CancelSalesOrderDraftCommandHandler>(
    container: container,
    bus: bus,
    logger: logger,
    factory: () => CancelSalesOrderDraftCommandHandler(
      gateway: container.get<ISalesOrderDraftGateway>(),
    ),
  );

  SalesCommandRegistration.registerBusinessHandler<CompleteReturnExchangeCommand, ReturnExchangeResultDto, CompleteReturnExchangeCommandHandler>(
    container: container,
    bus: bus,
    logger: logger,
    factory: () => CompleteReturnExchangeCommandHandler(
      commandGateway: container.get<IReturnExchangeCommandGateway>(),
    ),
  );

  SalesCommandRegistration.registerBusinessHandler<ConfirmReturnExchangeCommand, ReturnExchangeResultDto, ConfirmReturnExchangeCommandHandler>(
    container: container,
    bus: bus,
    logger: logger,
    factory: () => ConfirmReturnExchangeCommandHandler(
      readGateway: container.get<IReturnExchangeReadGateway>(),
      referencePort: container.get<IReturnExchangeReferencePort>(),
      commandGateway: container.get<IReturnExchangeCommandGateway>(),
    ),
  );

  SalesCommandRegistration.registerBusinessHandler<ConfirmSalesOrderCancellationCommand, SalesOrderCancellationResultDto, ConfirmSalesOrderCancellationCommandHandler>(
    container: container,
    bus: bus,
    logger: logger,
    factory: () => ConfirmSalesOrderCancellationCommandHandler(
      cancellationGateway: container.get<ISalesOrderCancellationGateway>(),
    ),
  );

  SalesCommandRegistration.registerBusinessHandler<FinalizeSalesOrderCommand, CheckoutResultDto, FinalizeSalesOrderCommandHandler>(
    container: container,
    bus: bus,
    logger: logger,
    factory: () => FinalizeSalesOrderCommandHandler(
      checkoutGateway: container.get<ICheckoutGateway>(),
      permissionChecker: container.get<IPermissionChecker>(),
    ),
  );

  SalesCommandRegistration.registerBusinessHandler<GenerateSalesReceiptCommand, SalesReceiptDto, GenerateSalesReceiptCommandHandler>(
    container: container,
    bus: bus,
    logger: logger,
    factory: () => GenerateSalesReceiptCommandHandler(
      receiptGateway: container.get<ISalesReceiptGateway>(),
    ),
  );

  SalesCommandRegistration.registerBusinessHandler<RecordSalesPaymentCommand, SalesOrderPaymentSummaryDto, RecordSalesPaymentCommandHandler>(
    container: container,
    bus: bus,
    logger: logger,
    factory: () => RecordSalesPaymentCommandHandler(
      settlementGateway: container.get<IReturnExchangeSettlementGateway>(),
    ),
  );

  SalesCommandRegistration.registerBusinessHandler<RecordSalesReceiptPrintedCommand, SalesReceiptDto, RecordSalesReceiptPrintedCommandHandler>(
    container: container,
    bus: bus,
    logger: logger,
    factory: () => RecordSalesReceiptPrintedCommandHandler(
      receiptGateway: container.get<ISalesReceiptGateway>(),
    ),
  );

  SalesCommandRegistration.registerBusinessHandler<RecordSalesReceiptSharedCommand, SalesReceiptDto, RecordSalesReceiptSharedCommandHandler>(
    container: container,
    bus: bus,
    logger: logger,
    factory: () => RecordSalesReceiptSharedCommandHandler(
      receiptGateway: container.get<ISalesReceiptGateway>(),
    ),
  );

  SalesCommandRegistration.registerBusinessHandler<RecordSalesRefundCommand, ReturnExchangeSettlementResultDto, RecordSalesRefundCommandHandler>(
    container: container,
    bus: bus,
    logger: logger,
    factory: () => RecordSalesRefundCommandHandler(
      settlementGateway: container.get<IReturnExchangeSettlementGateway>(),
    ),
  );

  SalesCommandRegistration.registerBusinessHandler<SaveSalesOrderDraftCommand, SalesOrderDraftDto, SaveSalesOrderDraftCommandHandler>(
    container: container,
    bus: bus,
    logger: logger,
    factory: () => SaveSalesOrderDraftCommandHandler(
      gateway: container.get<ISalesOrderDraftGateway>(),
    ),
  );

  SalesCommandRegistration.registerBusinessHandler<StartReturnExchangeCommand, ReturnExchangeDraftDto, StartReturnExchangeCommandHandler>(
    container: container,
    bus: bus,
    logger: logger,
    factory: () => StartReturnExchangeCommandHandler(
      commandGateway: container.get<IReturnExchangeCommandGateway>(),
      referencePort: container.get<IReturnExchangeReferencePort>(),
    ),
  );

  SalesCommandRegistration.registerBusinessHandler<UpdateReturnExchangeCommand, ReturnExchangeDraftDto, UpdateReturnExchangeCommandHandler>(
    container: container,
    bus: bus,
    logger: logger,
    factory: () => UpdateReturnExchangeCommandHandler(
      readGateway: container.get<IReturnExchangeReadGateway>(),
      commandGateway: container.get<IReturnExchangeCommandGateway>(),
      referencePort: container.get<IReturnExchangeReferencePort>(),
    ),
  );

  SalesCommandRegistration.registerBusinessHandler<UpdateSalesOrderDraftCommand, SalesOrderDraftDto, UpdateSalesOrderDraftCommandHandler>(
    container: container,
    bus: bus,
    logger: logger,
    factory: () => UpdateSalesOrderDraftCommandHandler(
      gateway: container.get<ISalesOrderDraftGateway>(),
    ),
  );

}

void registerGeneratedSalesQueries({
  required QueryBus bus,
  required GetIt container,
}) {
  SalesCommandRegistration.registerQueryHandler<EvaluateReturnPricingImpactQuery, ReturnExchangeValuationDto, EvaluateReturnPricingImpactQueryHandler>(
    bus: bus,
    factory: () => EvaluateReturnPricingImpactQueryHandler(
      permissionChecker: container.get<IPermissionChecker>(),
      readGateway: container.get<IReturnExchangeReadGateway>(),
      referencePort: container.get<IReturnExchangeReferencePort>(),
    ),
    invoke: (query, handler) => handler.handle(query),
  );

  SalesCommandRegistration.registerQueryHandler<GetAvailablePostSaleActionsQuery, AvailablePostSaleActionsDto, GetAvailablePostSaleActionsQueryHandler>(
    bus: bus,
    factory: () => GetAvailablePostSaleActionsQueryHandler(
      permissionChecker: container.get<IPermissionChecker>(),
      postSaleActionsGateway: container.get<IPostSaleActionsGateway>(),
    ),
    invoke: (query, handler) => handler.handle(query),
  );

  SalesCommandRegistration.registerQueryHandler<GetCheckoutResultQuery, CheckoutResultDto, GetCheckoutResultQueryHandler>(
    bus: bus,
    factory: () => GetCheckoutResultQueryHandler(
      permissionChecker: container.get<IPermissionChecker>(),
      checkoutGateway: container.get<ICheckoutGateway>(),
    ),
    invoke: (query, handler) => handler.handle(query),
  );

  SalesCommandRegistration.registerQueryHandler<GetReturnExchangeDetailQuery, ReturnExchangeDetailDto, GetReturnExchangeDetailQueryHandler>(
    bus: bus,
    factory: () => GetReturnExchangeDetailQueryHandler(
      permissionChecker: container.get<IPermissionChecker>(),
      returnExchangeReadGateway: container.get<IReturnExchangeReadGateway>(),
    ),
    invoke: (query, handler) => handler.handle(query),
  );

  SalesCommandRegistration.registerQueryHandler<GetReturnExchangeFormPolicyQuery, ReturnExchangeFormPolicyDto, GetReturnExchangeFormPolicyQueryHandler>(
    bus: bus,
    factory: () => GetReturnExchangeFormPolicyQueryHandler(
      permissionChecker: container.get<IPermissionChecker>(),
      returnExchangeReadGateway: container.get<IReturnExchangeReadGateway>(),
    ),
    invoke: (query, handler) => handler.handle(query),
  );

  SalesCommandRegistration.registerQueryHandler<GetReturnExchangeOrdersBySalesOrderQuery, SalesOrderReturnSummaryDto, GetReturnExchangeOrdersBySalesOrderQueryHandler>(
    bus: bus,
    factory: () => GetReturnExchangeOrdersBySalesOrderQueryHandler(
      permissionChecker: container.get<IPermissionChecker>(),
      inquiryGateway: container.get<ISalesOrderInquiryGateway>(),
    ),
    invoke: (query, handler) => handler.handle(query),
  );

  SalesCommandRegistration.registerQueryHandler<GetReturnableOrderLinesQuery, ReturnableOrderLinesDto, GetReturnableOrderLinesQueryHandler>(
    bus: bus,
    factory: () => GetReturnableOrderLinesQueryHandler(
      permissionChecker: container.get<IPermissionChecker>(),
      returnExchangeReadGateway: container.get<IReturnExchangeReadGateway>(),
    ),
    invoke: (query, handler) => handler.handle(query),
  );

  SalesCommandRegistration.registerQueryHandler<GetSalesOrderCancellationQuery, SalesOrderCancellationDetailDto, GetSalesOrderCancellationQueryHandler>(
    bus: bus,
    factory: () => GetSalesOrderCancellationQueryHandler(
      permissionChecker: container.get<IPermissionChecker>(),
      cancellationGateway: container.get<ISalesOrderCancellationGateway>(),
    ),
    invoke: (query, handler) => handler.handle(query),
  );

  SalesCommandRegistration.registerQueryHandler<GetSalesOrderDetailQuery, SalesOrderDetailDto, GetSalesOrderDetailQueryHandler>(
    bus: bus,
    factory: () => GetSalesOrderDetailQueryHandler(
      permissionChecker: container.get<IPermissionChecker>(),
      inquiryGateway: container.get<ISalesOrderInquiryGateway>(),
    ),
    invoke: (query, handler) => handler.handle(query),
  );

  SalesCommandRegistration.registerQueryHandler<GetSalesOrderDraftForRestoreQuery, SalesOrderDraftForRestoreDto, GetSalesOrderDraftForRestoreQueryHandler>(
    bus: bus,
    factory: () => GetSalesOrderDraftForRestoreQueryHandler(
      gateway: container.get<ISalesOrderDraftGateway>(),
      permissionChecker: container.get<IPermissionChecker>(),
    ),
    invoke: (query, handler) => handler.handle(query),
  );

  SalesCommandRegistration.registerQueryHandler<GetSalesOrderOriginalReceiptQuery, SalesReceiptDocumentDto, GetSalesOrderOriginalReceiptQueryHandler>(
    bus: bus,
    factory: () => GetSalesOrderOriginalReceiptQueryHandler(
      permissionChecker: container.get<IPermissionChecker>(),
      receiptGateway: container.get<ISalesReceiptGateway>(),
    ),
    invoke: (query, handler) => handler.handle(query),
  );

  SalesCommandRegistration.registerQueryHandler<GetSalesOrderPaymentSummaryQuery, SalesOrderPaymentSummaryDto, GetSalesOrderPaymentSummaryQueryHandler>(
    bus: bus,
    factory: () => GetSalesOrderPaymentSummaryQueryHandler(
      permissionChecker: container.get<IPermissionChecker>(),
      readGateway: container.get<ISalesOrderReadGateway>(),
    ),
    invoke: (query, handler) => handler.handle(query),
  );

  SalesCommandRegistration.registerQueryHandler<GetSalesOrderPaymentTransactionsQuery, SalesPaymentTransactionsDto, GetSalesOrderPaymentTransactionsQueryHandler>(
    bus: bus,
    factory: () => GetSalesOrderPaymentTransactionsQueryHandler(
      permissionChecker: container.get<IPermissionChecker>(),
      inquiryGateway: container.get<ISalesOrderInquiryGateway>(),
    ),
    invoke: (query, handler) => handler.handle(query),
  );

  SalesCommandRegistration.registerQueryHandler<GetSalesOrderQuery, SalesOrderResultDto, GetSalesOrderQueryHandler>(
    bus: bus,
    factory: () => GetSalesOrderQueryHandler(
      permissionChecker: container.get<IPermissionChecker>(),
      readGateway: container.get<ISalesOrderReadGateway>(),
    ),
    invoke: (query, handler) => handler.handle(query),
  );

  SalesCommandRegistration.registerQueryHandler<GetSalesOrderReturnSummaryQuery, SalesOrderReturnSummaryDto, GetSalesOrderReturnSummaryQueryHandler>(
    bus: bus,
    factory: () => GetSalesOrderReturnSummaryQueryHandler(
      permissionChecker: container.get<IPermissionChecker>(),
      inquiryGateway: container.get<ISalesOrderInquiryGateway>(),
    ),
    invoke: (query, handler) => handler.handle(query),
  );

  SalesCommandRegistration.registerQueryHandler<GetSalesOrderSettlementQuery, SalesOrderSettlementDto, GetSalesOrderSettlementQueryHandler>(
    bus: bus,
    factory: () => GetSalesOrderSettlementQueryHandler(
      permissionChecker: container.get<IPermissionChecker>(),
      inquiryGateway: container.get<ISalesOrderInquiryGateway>(),
    ),
    invoke: (query, handler) => handler.handle(query),
  );

  SalesCommandRegistration.registerQueryHandler<GetSalesOrderTimelineQuery, SalesOrderTimelineDto, GetSalesOrderTimelineQueryHandler>(
    bus: bus,
    factory: () => GetSalesOrderTimelineQueryHandler(
      permissionChecker: container.get<IPermissionChecker>(),
      inquiryGateway: container.get<ISalesOrderInquiryGateway>(),
    ),
    invoke: (query, handler) => handler.handle(query),
  );

  SalesCommandRegistration.registerQueryHandler<GetSalesReceiptQuery, SalesReceiptDto, GetSalesReceiptQueryHandler>(
    bus: bus,
    factory: () => GetSalesReceiptQueryHandler(
      permissionChecker: container.get<IPermissionChecker>(),
      receiptGateway: container.get<ISalesReceiptGateway>(),
    ),
    invoke: (query, handler) => handler.handle(query),
  );

  SalesCommandRegistration.registerQueryHandler<ListSalesOrderCancellationReasonsQuery, List<CancellationReasonPolicyDto>, ListSalesOrderCancellationReasonsQueryHandler>(
    bus: bus,
    factory: () => ListSalesOrderCancellationReasonsQueryHandler(
      permissionChecker: container.get<IPermissionChecker>(),
      cancellationGateway: container.get<ISalesOrderCancellationGateway>(),
    ),
    invoke: (query, handler) => handler.handle(query),
  );

  SalesCommandRegistration.registerQueryHandler<ListSalesOrderDraftsQuery, PagedSalesOrderDraftListDto, ListSalesOrderDraftsQueryHandler>(
    bus: bus,
    factory: () => ListSalesOrderDraftsQueryHandler(
      gateway: container.get<ISalesOrderDraftGateway>(),
      permissionChecker: container.get<IPermissionChecker>(),
    ),
    invoke: (query, handler) => handler.handle(query),
  );

  SalesCommandRegistration.registerQueryHandler<ListSalesOrdersQuery, PagedSalesOrderListDto, ListSalesOrdersQueryHandler>(
    bus: bus,
    factory: () => ListSalesOrdersQueryHandler(
      permissionChecker: container.get<IPermissionChecker>(),
      inquiryGateway: container.get<ISalesOrderInquiryGateway>(),
    ),
    invoke: (query, handler) => handler.handle(query),
  );

  SalesCommandRegistration.registerQueryHandler<PrecheckReturnExchangeQuery, ReturnExchangePrecheckDto, PrecheckReturnExchangeQueryHandler>(
    bus: bus,
    factory: () => PrecheckReturnExchangeQueryHandler(
      permissionChecker: container.get<IPermissionChecker>(),
      returnExchangeReadGateway: container.get<IReturnExchangeReadGateway>(),
    ),
    invoke: (query, handler) => handler.handle(query),
  );

  SalesCommandRegistration.registerQueryHandler<PrecheckSalesOrderCancellationQuery, CancellationPrecheckDto, PrecheckSalesOrderCancellationQueryHandler>(
    bus: bus,
    factory: () => PrecheckSalesOrderCancellationQueryHandler(
      permissionChecker: container.get<IPermissionChecker>(),
      cancellationGateway: container.get<ISalesOrderCancellationGateway>(),
    ),
    invoke: (query, handler) => handler.handle(query),
  );

  SalesCommandRegistration.registerQueryHandler<PrecheckSalesOrderCheckoutQuery, CheckoutPrecheckDto, PrecheckSalesOrderCheckoutQueryHandler>(
    bus: bus,
    factory: () => PrecheckSalesOrderCheckoutQueryHandler(
      permissionChecker: container.get<IPermissionChecker>(),
      checkoutGateway: container.get<ICheckoutGateway>(),
    ),
    invoke: (query, handler) => handler.handle(query),
  );

  SalesCommandRegistration.registerQueryHandler<PreviewReturnExchangePricingQuery, ReturnExchangePricingPreviewDto, PreviewReturnExchangePricingQueryHandler>(
    bus: bus,
    factory: () => PreviewReturnExchangePricingQueryHandler(
      permissionChecker: container.get<IPermissionChecker>(),
      returnExchangeReadGateway: container.get<IReturnExchangeReadGateway>(),
    ),
    invoke: (query, handler) => handler.handle(query),
  );

  SalesCommandRegistration.registerQueryHandler<PreviewSalesPricingQuery, PricingPreviewDto, PreviewSalesPricingQueryHandler>(
    bus: bus,
    factory: () => PreviewSalesPricingQueryHandler(
      pricing: container.get<IPricingPreviewPort>(),
      permissionChecker: container.get<IPermissionChecker>(),
    ),
    invoke: (query, handler) => handler.handle(query),
  );

  SalesCommandRegistration.registerQueryHandler<SearchSalesOrdersQuery, PagedSalesOrderListDto, SearchSalesOrdersQueryHandler>(
    bus: bus,
    factory: () => SearchSalesOrdersQueryHandler(
      permissionChecker: container.get<IPermissionChecker>(),
      inquiryGateway: container.get<ISalesOrderInquiryGateway>(),
    ),
    invoke: (query, handler) => handler.handle(query),
  );

}

