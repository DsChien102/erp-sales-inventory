import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_catalog_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';
import '../mappers/catalog_ui_mapper.dart';
import '../models/product_image_draft.dart';
import '../services/product_image_upload_client.dart';
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
  final ImagePicker _picker = ImagePicker();

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

  Future<void> pickImagesFromGallery() async {
    if (state.imageDrafts.length >= ProductGuidedCreateState.maxImages) {
      return;
    }

    try {
      final picked = await _picker.pickMultiImage(imageQuality: 85);
      if (picked.isEmpty) {
        return;
      }

      final remaining = ProductGuidedCreateState.maxImages - state.imageDrafts.length;
      final toAdd = picked.take(remaining).toList();
      await _uploadPickedFiles(toAdd);
    } catch (_) {
      emit(state.copyWith(
        errorMessage: 'Không mở được thư viện ảnh.',
        status: ProductGuidedCreateStatus.error,
      ));
    }
  }

  Future<void> _uploadPickedFiles(List<XFile> files) async {
    if (files.isEmpty) {
      return;
    }

    final tenantId = await _executionContext.requireTenantId();
    final actorId = await _executionContext.requireUserId();

    var drafts = [...state.imageDrafts];
    for (final file in files) {
      drafts = [
        ...drafts,
        ProductImageDraft(localPath: file.path, status: ProductImageUploadStatus.uploading),
      ];
      emit(state.copyWith(
        imageDrafts: drafts,
        coverImageIndex: state.coverImageIndex.clamp(0, drafts.length - 1),
        status: ProductGuidedCreateStatus.uploadingImages,
        clearError: true,
      ));

      final index = drafts.length - 1;
      final fileName = file.name.isNotEmpty ? file.name : file.path.split('/').last;
      final contentType = ProductImageUploadClient.contentTypeForFileName(fileName);

      try {
        final bytes = await file.readAsBytes();
        final slot = await _catalogModule.executeCommandAsync(
          RequestProductImageUploadCommand(
            tenantId: tenantId,
            actorId: actorId,
            fileName: fileName,
            contentType: contentType,
            byteSize: bytes.length,
          ),
        );

        await ProductImageUploadClient.uploadBytes(
          signedUploadUrl: slot.signedUploadUrl,
          bytes: bytes,
          contentType: contentType,
        );

        drafts = [...drafts];
        drafts[index] = ProductImageDraft(
          localPath: file.path,
          storageKey: slot.storageKey,
          slotId: slot.slotId,
          status: ProductImageUploadStatus.uploaded,
        );
      } on ValidationException catch (e) {
        drafts = [...drafts];
        drafts[index] = ProductImageDraft(
          localPath: file.path,
          status: ProductImageUploadStatus.failed,
          errorMessage: e.message,
        );
      } on ApplicationException catch (e) {
        drafts = [...drafts];
        drafts[index] = ProductImageDraft(
          localPath: file.path,
          status: ProductImageUploadStatus.failed,
          errorMessage: e.message,
        );
      } catch (_) {
        drafts = [...drafts];
        drafts[index] = ProductImageDraft(
          localPath: file.path,
          status: ProductImageUploadStatus.failed,
          errorMessage: 'Upload ảnh thất bại.',
        );
      }

      emit(state.copyWith(
        imageDrafts: drafts,
        coverImageIndex: state.coverImageIndex.clamp(0, drafts.length - 1),
        status: ProductGuidedCreateStatus.initial,
      ));
    }
  }

  void setCoverImageIndex(int index) {
    if (state.imageDrafts.isEmpty) {
      return;
    }
    emit(state.copyWith(
      coverImageIndex: index.clamp(0, state.imageDrafts.length - 1),
    ));
  }

  void removeImageAt(int index) {
    if (index < 0 || index >= state.imageDrafts.length) {
      return;
    }
    final next = [...state.imageDrafts]..removeAt(index);
    var cover = state.coverImageIndex;
    if (cover >= next.length) {
      cover = next.isEmpty ? 0 : next.length - 1;
    } else if (index < cover) {
      cover -= 1;
    } else if (index == cover && next.isNotEmpty) {
      cover = 0;
    }
    emit(state.copyWith(imageDrafts: next, coverImageIndex: cover));
  }

  void updateBaseUnit(String val) {
    emit(state.copyWith(baseUnit: val));
  }

  void updateInitialStock(String val) {
    emit(state.copyWith(initialStock: val));
  }

  void updateBaseCost(String val) {
    emit(state.copyWith(baseCost: val));
  }

  void updatePricingMethod(String val) {
    emit(state.copyWith(pricingMethod: val));
  }

  void updateCustomAutoMarkup(String val) {
    emit(state.copyWith(customAutoMarkup: val));
  }

  void updateCustomAutoFloorMarkup(String val) {
    emit(state.copyWith(customAutoFloorMarkup: val));
  }

  void updateManualListPrice(String val) {
    emit(state.copyWith(manualListPrice: val));
  }

  void updateManualFloorPrice(String val) {
    emit(state.copyWith(manualFloorPrice: val));
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

  void deferPriceBandStep() {
    emit(state.copyWith(priceBandConfigured: false));
    nextStep();
  }

  void confirmPriceBandStep() {
    emit(state.copyWith(priceBandConfigured: true));
    nextStep();
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

    if (state.isUploadingImages) {
      emit(state.copyWith(
        status: ProductGuidedCreateStatus.error,
        errorMessage: 'Đang tải ảnh lên, vui lòng đợi.',
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

      final productId = createResult.productId;

      final stockQty = int.tryParse(state.initialStock.trim());
      if (stockQty != null) {
        await _catalogModule.executeCommandAsync(
          SetInitialStockCommand(
            tenantId: tenantId,
            productId: productId,
            quantity: stockQty,
          ),
        );
      }

      final baseCostVal = double.tryParse(state.baseCost.trim());
      if (baseCostVal != null) {
        await _catalogModule.executeCommandAsync(
          SetManualBasePriceCommand(
            tenantId: tenantId,
            productId: productId,
            basePrice: baseCostVal,
          ),
        );
      }

      double? listPrice;
      double? floorPrice;
      bool useStoreRule = false;

      if (state.priceBandConfigured) {
        final resolved = CatalogUiMapper.resolvePriceBand(state);
        listPrice = resolved.listPrice;
        floorPrice = resolved.floorPrice;
        useStoreRule = state.pricingMethod == 'storeRule';
      }

      if (state.priceBandConfigured) {
        await _catalogModule.executeCommandAsync(
          SetInitialPriceBandCommand(
            tenantId: tenantId,
            productId: productId,
            listPrice: listPrice,
            floorPrice: floorPrice,
            useStoreRule: useStoreRule,
          ),
        );
      }

      final productModel = CatalogUiMapper.toListItemModelFromCreate(
        state: state,
        productId: productId,
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
    final uploaded = state.imageDrafts
        .where((draft) => draft.isUploaded && draft.storageKey != null)
        .toList();
    if (uploaded.isEmpty) {
      return const [];
    }

    return uploaded.asMap().entries.map((entry) {
      final draft = entry.value;
      final originalIndex = state.imageDrafts.indexOf(draft);
      final isPrimary = originalIndex == state.coverImageIndex;
      return ProductImageInput(
        storageKey: draft.storageKey!,
        slotId: draft.slotId,
        isPrimary: isPrimary,
        sortOrder: entry.key,
      );
    }).toList();
  }
}
