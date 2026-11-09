import 'package:equatable/equatable.dart';
import 'package:erp/core/errors/app_exception.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/catalog_errors.dart';
import '../data/models/catalog_enums.dart';
import '../data/product_repository.dart';
import 'catalog_error_messages.dart';

enum ProductProfileMaintenanceStatus {
  initial,
  submitting,
  success,
  failure,
}

class ProductProfileMaintenanceState extends Equatable {
  const ProductProfileMaintenanceState({
    this.name = '',
    this.tradeName = '',
    this.sku = '',
    this.barcode = '',
    this.trackingMode = ProductTrackingMode.none,
    this.expiryRequired = false,
    this.trackingLocked = false,
    this.status = ProductProfileMaintenanceStatus.initial,
    this.errorMessage,
    this.skuError,
    this.barcodeError,
    this.nameError,
  });

  final String name;
  final String tradeName;
  final String sku;
  final String barcode;
  final ProductTrackingMode trackingMode;
  final bool expiryRequired;
  final bool trackingLocked;
  final ProductProfileMaintenanceStatus status;
  final String? errorMessage;
  final String? skuError;
  final String? barcodeError;
  final String? nameError;

  ProductProfileMaintenanceState copyWith({
    String? name,
    String? tradeName,
    String? sku,
    String? barcode,
    ProductTrackingMode? trackingMode,
    bool? expiryRequired,
    bool? trackingLocked,
    ProductProfileMaintenanceStatus? status,
    String? errorMessage,
    String? skuError,
    String? barcodeError,
    String? nameError,
    bool clearErrors = false,
  }) {
    return ProductProfileMaintenanceState(
      name: name ?? this.name,
      tradeName: tradeName ?? this.tradeName,
      sku: sku ?? this.sku,
      barcode: barcode ?? this.barcode,
      trackingMode: trackingMode ?? this.trackingMode,
      expiryRequired: expiryRequired ?? this.expiryRequired,
      trackingLocked: trackingLocked ?? this.trackingLocked,
      status: status ?? this.status,
      errorMessage: clearErrors ? null : (errorMessage ?? this.errorMessage),
      skuError: clearErrors ? null : (skuError ?? this.skuError),
      barcodeError: clearErrors ? null : (barcodeError ?? this.barcodeError),
      nameError: clearErrors ? null : (nameError ?? this.nameError),
    );
  }

  @override
  List<Object?> get props => [
    name,
    tradeName,
    sku,
    barcode,
    trackingMode,
    expiryRequired,
    trackingLocked,
    status,
    errorMessage,
    skuError,
    barcodeError,
    nameError,
  ];
}

class ProductProfileMaintenanceCubit extends Cubit<ProductProfileMaintenanceState> {
  ProductProfileMaintenanceCubit({
    required ProductRepository productRepository,
    required this.productId,
    required String initialName,
    String? initialTradeName,
    String? initialSku,
    String? initialBarcode,
    ProductTrackingMode initialTrackingMode = ProductTrackingMode.none,
    bool initialExpiryRequired = false,
    bool trackingLocked = false,
  })  : _productRepository = productRepository,
        _initialName = initialName,
        _initialTradeName = initialTradeName ?? '',
        _initialSku = initialSku ?? '',
        _initialBarcode = initialBarcode ?? '',
        _initialTrackingMode = initialTrackingMode,
        _initialExpiryRequired = initialExpiryRequired,
        super(
          ProductProfileMaintenanceState(
            name: initialName,
            tradeName: initialTradeName ?? '',
            sku: initialSku ?? '',
            barcode: initialBarcode ?? '',
            trackingMode: initialTrackingMode,
            expiryRequired: initialExpiryRequired,
            trackingLocked: trackingLocked,
          ),
        );

  final ProductRepository _productRepository;
  final String productId;
  final String _initialName;
  final String _initialTradeName;
  final String _initialSku;
  final String _initialBarcode;
  final ProductTrackingMode _initialTrackingMode;
  final bool _initialExpiryRequired;

  bool get hasChanges =>
      state.name.trim() != _initialName.trim() ||
      state.tradeName.trim() != _initialTradeName.trim() ||
      state.sku.trim() != _initialSku.trim() ||
      state.barcode.trim() != _initialBarcode.trim() ||
      state.trackingMode != _initialTrackingMode ||
      state.expiryRequired != _initialExpiryRequired;

  void nameChanged(String value) {
    emit(
      state.copyWith(
        name: value,
        nameError: null,
        status: ProductProfileMaintenanceStatus.initial,
        clearErrors: true,
      ),
    );
  }

  void tradeNameChanged(String value) {
    emit(
      state.copyWith(
        tradeName: value,
        status: ProductProfileMaintenanceStatus.initial,
        clearErrors: true,
      ),
    );
  }

  void skuChanged(String value) {
    emit(
      state.copyWith(
        sku: value,
        skuError: null,
        status: ProductProfileMaintenanceStatus.initial,
        clearErrors: true,
      ),
    );
  }

  void barcodeChanged(String value) {
    emit(
      state.copyWith(
        barcode: value,
        barcodeError: null,
        status: ProductProfileMaintenanceStatus.initial,
        clearErrors: true,
      ),
    );
  }

  void trackingModeChanged(ProductTrackingMode mode) {
    if (state.trackingLocked) return;
    emit(
      state.copyWith(
        trackingMode: mode,
        expiryRequired: mode == ProductTrackingMode.none ? false : state.expiryRequired,
        status: ProductProfileMaintenanceStatus.initial,
        clearErrors: true,
      ),
    );
  }

  void expiryRequiredChanged(bool value) {
    if (state.trackingLocked || state.trackingMode == ProductTrackingMode.none) return;
    emit(
      state.copyWith(
        expiryRequired: value,
        status: ProductProfileMaintenanceStatus.initial,
        clearErrors: true,
      ),
    );
  }

  Future<void> submit() async {
    if (state.name.trim().isEmpty) {
      emit(
        state.copyWith(
          nameError: 'Tên sản phẩm là bắt buộc',
          status: ProductProfileMaintenanceStatus.failure,
        ),
      );
      return;
    }

    emit(state.copyWith(status: ProductProfileMaintenanceStatus.submitting, clearErrors: true));

    try {
      final trackingModeToSend =
          state.trackingMode != _initialTrackingMode ? state.trackingMode : null;
      final expiryRequiredToSend =
          state.expiryRequired != _initialExpiryRequired ? state.expiryRequired : null;

      await _productRepository.updateProfile(
        productId: productId,
        productName: state.name.trim(),
        commercialName: state.tradeName.trim().isEmpty ? null : state.tradeName.trim(),
        sku: state.sku.trim().isEmpty ? null : state.sku.trim(),
        barcode: state.barcode.trim().isEmpty ? null : state.barcode.trim(),
        description: null,
        note: null,
        trackingMode: trackingModeToSend,
        expiryRequired: expiryRequiredToSend,
      );

      emit(state.copyWith(status: ProductProfileMaintenanceStatus.success));
    } on AppException catch (e) {
      if (e.code == CatalogErrorCodes.duplicateSku) {
        emit(
          state.copyWith(
            status: ProductProfileMaintenanceStatus.failure,
            skuError: 'Mã SKU đã được sử dụng',
          ),
        );
        return;
      }
      if (e.code == CatalogErrorCodes.duplicateBarcode) {
        emit(
          state.copyWith(
            status: ProductProfileMaintenanceStatus.failure,
            barcodeError: 'Mã vạch đã được sử dụng',
          ),
        );
        return;
      }
      if (e.code == CatalogErrorCodes.trackingLocked) {
        emit(
          state.copyWith(
            status: ProductProfileMaintenanceStatus.failure,
            errorMessage: 'Đã có biến động kho, không đổi được.',
          ),
        );
        return;
      }
      emit(
        state.copyWith(
          status: ProductProfileMaintenanceStatus.failure,
          errorMessage: catalogErrorMessage(e, fallback: 'Đã xảy ra lỗi không xác định. Vui lòng thử lại.'),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ProductProfileMaintenanceStatus.failure,
          errorMessage: catalogErrorMessage(e, fallback: 'Đã xảy ra lỗi không xác định. Vui lòng thử lại.'),
        ),
      );
    }
  }
}
