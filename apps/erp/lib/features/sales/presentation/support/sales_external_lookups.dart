import '../models/shared/sales_customer_selection.dart';
import '../models/shared/sales_sellable_product_vm.dart';

/// Lookup KH — implement ở ERP bằng `PartnerRepository`, không import Partner vào
/// `sales_presentation`.
typedef SalesCustomerSearchFn =
    Future<List<SalesCustomerListItemVm>> Function(
      String query,
    );

/// Exact Partner resolve by persisted id — ERP implements with `PartnerRepository.getDetail`.
typedef SalesCustomerResolveFn = Future<SalesCustomerSelection> Function(String partnerId);

enum SalesQuickCustomerType { person, organization }

final class SalesQuickCustomerDraft {
  const SalesQuickCustomerDraft({
    required this.type,
    required this.displayName,
    required this.phone,
    this.taxCode,
    this.address,
  });

  final SalesQuickCustomerType type;
  final String displayName;
  final String phone;
  final String? taxCode;
  final String? address;
}

typedef SalesCustomerDuplicateCheckFn =
    Future<SalesCustomerListItemVm?> Function(SalesQuickCustomerDraft draft);

typedef SalesCustomerCreateFn =
    Future<SalesCustomerSelection> Function(
      SalesQuickCustomerDraft draft, {
      required bool confirmDuplicate,
    });

final class SalesExternalOperationException implements Exception {
  const SalesExternalOperationException(this.message);

  final String message;

  @override
  String toString() => message;
}

typedef SalesCustomerOperationException = SalesExternalOperationException;

/// Lookup SP bán được — implement ở ERP bằng [ICatalogModule].
typedef SalesProductSearchFn =
    Future<List<SalesSellableProductVm>> Function(
      String query, {
      int limit,
    });

typedef SalesProductBarcodeResolveFn =
    Future<List<SalesSellableProductVm>> Function(String barcode);

/// Resolve đầy đủ đơn vị bán sau khi chọn suggestion (search chỉ trả base).
typedef SalesProductUnitsResolveFn =
    Future<SalesSellableProductVm> Function(
      SalesSellableProductVm product,
    );
