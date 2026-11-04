import 'package:equatable/equatable.dart';
import 'package:erp/core/errors/app_exception.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/catalog_errors.dart';
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
  })  : _productRepository = productRepository,
        _initialName = initialName,
        _initialTradeName = initialTradeName ?? '',
        _initialSku = initialSku ?? '',
        _initialBarcode = initialBarcode ?? '',
        super(
          ProductProfileMaintenanceState(
            name: initialName,
            tradeName: initialTradeName ?? '',
            sku: initialSku ?? '',
            barcode: initialBarcode ?? '',
          ),
        );

  final ProductRepository _productRepository;
  final String productId;
  final String _initialName;
  final String _initialTradeName;
  final String _initialSku;
  final String _initialBarcode;

  bool get hasChanges =>
      state.name.trim() != _initialName.trim() ||
      state.tradeName.trim() != _initialTradeName.trim() ||
      state.sku.trim() != _initialSku.trim() ||
      state.barcode.trim() != _initialBarcode.trim();

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
      await _productRepository.updateProfile(
        productId: productId,
        productName: state.name.trim(),
        commercialName: state.tradeName.trim().isEmpty ? null : state.tradeName.trim(),
        sku: state.sku.trim().isEmpty ? null : state.sku.trim(),
        barcode: state.barcode.trim().isEmpty ? null : state.barcode.trim(),
        description: null,
        note: null,
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
