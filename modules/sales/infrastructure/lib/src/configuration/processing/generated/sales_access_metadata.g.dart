// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint

import 'package:vet45_sales_application/application.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

final salesAccessMetadataRegistry = AccessMetadataRegistry({
  CancelSalesOrderDraftCommand: AccessMetadata(
    permission: 'sales.draft.delete',
    requiresTenant: true,
  ),
  GetSalesOrderDraftForRestoreQuery: AccessMetadata(
    permission: 'sales.draft.restore',
    requiresTenant: true,
  ),
  ListSalesOrderDraftsQuery: AccessMetadata(
    permission: 'sales.draft.restore',
    requiresTenant: true,
  ),
  PrecheckSalesOrderCheckoutQuery: AccessMetadata(
    permission: 'sales.checkout.create',
    requiresTenant: true,
  ),
  PreviewSalesPricingQuery: AccessMetadata(
    permission: 'sales.checkout.create',
    requiresTenant: true,
  ),
  SaveSalesOrderDraftCommand: AccessMetadata(
    permission: 'sales.draft.create',
    requiresTenant: true,
  ),
  UpdateSalesOrderDraftCommand: AccessMetadata(
    permission: 'sales.draft.update',
    requiresTenant: true,
  ),
});

