import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_catalog_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';
import '../mappers/catalog_ui_mapper.dart';
import 'product_guided_create_state.dart';

class ProductGuidedCreateCubit extends Cubit<ProductGuidedCreateState> {
  ProductGuidedCreateCubit({
    required ICatalogModule catalogModule,
    required IExecutionContext executionContext,
  })  : _catalogModule = catalogModule,
        _executionContext = executionContext,
        super(const ProductGuidedCreateState());

  final ICatalogModule _catalogModule;
  final IExecutionContext _executionContext;

  void updateName(String val) {
    emit(state.copyWith(name: val, clearError: true));
  }

  void updateTradeName(String val) {
    emit(state.copyWith(tradeName: val));
  }

  void updateSku(String val) {
    emit(state.copyWith(
      sku: val,
      clearSkuError: true,
      clearDuplicateMatch: true,
      clearError: true,
    ));
  }

  void updateBarcode(String val) {
    emit(state.copyWith(
      barcode: val,
      clearBarcodeError: true,
      clearDuplicateMatch: true,
      clearError: true,
    ));
  }

  Future<void> checkDuplicateCodes() async {
    final sku = state.sku.trim();
    final barcode = state.barcode.trim();
    if (sku.isEmpty && barcode.isEmpty) {
      emit(state.copyWith(
        clearSkuError: true,
        clearBarcodeError: true,
        clearDuplicateMatch: true,
      ));
      return;
    }

    try {
      final tenantId = await _executionContext.requireTenantId();
      final matches = await _catalogModule.executeQueryAsync(
        CheckDuplicateProductCodeQuery(
          tenantId: tenantId,
          sku: sku.isNotEmpty ? sku : null,
          barcode: barcode.isNotEmpty ? barcode : null,
        ),
      );

      String? skuError;
      String? barcodeError;
      String? duplicateProductId;
      String? duplicateProductName;

      for (final match in matches) {
        if (match.field == ProductDuplicateField.sku) {
          skuError = 'SKU "${match.matchedValue}" đã được sử dụng';
          duplicateProductId ??= match.productId;
          duplicateProductName ??= match.productName;
        }
        if (match.field == ProductDuplicateField.barcode) {
          barcodeError = 'Barcode "${match.matchedValue}" đã được sử dụng';
          duplicateProductId ??= match.productId;
          duplicateProductName ??= match.productName;
        }
      }

      emit(state.copyWith(
        skuError: skuError,
        barcodeError: barcodeError,
        duplicateProductId: duplicateProductId,
        duplicateProductName: duplicateProductName,
        clearSkuError: skuError == null,
        clearBarcodeError: barcodeError == null,
        clearDuplicateMatch: duplicateProductId == null,
      ));
    } catch (_) {
      // Non-blocking: submit will re-check.
    }
  }

  void setImages(List<String> images, int coverImageIndex) {
    emit(state.copyWith(
      images: images,
      coverImageIndex: images.isEmpty ? 0 : coverImageIndex.clamp(0, images.length - 1),
    ));
  }

  void updateBaseUnit(String val) {
    emit(state.copyWith(baseUnit: val));
  }

  void setStep(int idx) {
    if (state.activeStepIndex == idx) {
      emit(state.copyWith(activeStepIndex: -1));
    } else {
      emit(state.copyWith(
        activeStepIndex: idx.clamp(0, ProductGuidedCreateState.stepCount - 1),
      ));
    }
  }

  void nextStep() {
    if (state.activeStepIndex < ProductGuidedCreateState.stepCount - 1) {
      emit(state.copyWith(activeStepIndex: state.activeStepIndex + 1));
    }
  }

  void prevStep() {
    if (state.activeStepIndex > 0) {
      emit(state.copyWith(activeStepIndex: state.activeStepIndex - 1));
    }
  }

  Future<void> submit() async {
    if (!state.isStep1Valid) {
      emit(state.copyWith(
        activeStepIndex: 0,
        showValidationErrors: true,
        status: ProductGuidedCreateStatus.error,
        errorMessage: 'Vui lòng nhập tên nội bộ sản phẩm.',
      ));
      return;
    }

    await checkDuplicateCodes();
    if (state.hasDuplicateError) {
      emit(state.copyWith(
        activeStepIndex: 0,
        status: ProductGuidedCreateStatus.initial,
      ));
      return;
    }

    emit(state.copyWith(status: ProductGuidedCreateStatus.loading, clearError: true));

    try {
      final tenantId = await _executionContext.requireTenantId();
      final actorId = await _executionContext.requireUserId();

      final createResult = await _catalogModule.executeCommandAsync(
        CreateProductCommand(
          tenantId: tenantId,
          actorId: actorId,
          productName: state.name.trim(),
          commercialName: state.tradeName.trim().isNotEmpty ? state.tradeName.trim() : null,
          sku: state.sku.trim().isNotEmpty ? state.sku.trim() : null,
          barcode: state.barcode.trim().isNotEmpty ? state.barcode.trim() : null,
          images: _toImageInputs(),
          baseUnitName: state.baseUnit.trim().isNotEmpty ? state.baseUnit.trim() : null,
        ),
      );

      final productModel = CatalogUiMapper.toListItemModelFromCreate(
        state: state,
        productId: createResult.productId,
        readinessSummary: createResult.readinessSummary,
      );

      emit(state.copyWith(
        status: ProductGuidedCreateStatus.success,
        createdProduct: productModel,
      ));
    } on DuplicateSkuException catch (e) {
      emit(state.copyWith(
        activeStepIndex: 0,
        status: ProductGuidedCreateStatus.initial,
        skuError: 'SKU "${e.sku}" đã được sử dụng',
        duplicateProductId: e.existingProductId,
        duplicateProductName: e.existingProductName,
        clearError: true,
      ));
    } on DuplicateBarcodeException catch (e) {
      emit(state.copyWith(
        activeStepIndex: 0,
        status: ProductGuidedCreateStatus.initial,
        barcodeError: 'Barcode "${e.barcode}" đã được sử dụng',
        duplicateProductId: e.existingProductId,
        duplicateProductName: e.existingProductName,
        clearError: true,
      ));
    } on ValidationException catch (e) {
      emit(state.copyWith(
        activeStepIndex: 0,
        showValidationErrors: true,
        status: ProductGuidedCreateStatus.error,
        errorMessage: e.message,
      ));
    } on ApplicationException catch (e) {
      emit(state.copyWith(
        status: ProductGuidedCreateStatus.error,
        errorMessage: e.message,
      ));
    } catch (_) {
      emit(state.copyWith(
        status: ProductGuidedCreateStatus.error,
        errorMessage: 'Lỗi hệ thống khi tạo sản phẩm.',
      ));
    }
  }

  List<ProductImageInput> _toImageInputs() {
    if (state.images.isEmpty) {
      return const [];
    }

    return state.images.asMap().entries.map((entry) {
      final path = entry.value;
      final isPrimary = entry.key == state.coverImageIndex;
      return ProductImageInput(
        storageKey: path,
        url: path.startsWith('http') ? path : null,
        isPrimary: isPrimary,
        sortOrder: entry.key,
      );
    }).toList();
  }
}
