import 'package:file_picker/file_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_catalog_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';
import '../mappers/guided_price_band_submission_resolver.dart';
import '../mappers/catalog_ui_mapper.dart';
import '../models/product_image_draft.dart';
import '../services/product_image_upload_client.dart';
import '../widgets/image_picker/product_image_add_sheet.dart';
import '../widgets/tenant_measurement_unit_search_field.dart';
import 'product_guided_create_state.dart';

class ProductGuidedCreateCubit extends Cubit<ProductGuidedCreateState> {
  ProductGuidedCreateCubit({
    required ICatalogModule catalogModule,
    required IExecutionContext executionContext,
  }) : _catalogModule = catalogModule,
       _executionContext = executionContext,
       super(const ProductGuidedCreateState()) {
    loadCustomFieldGroups();
  }

  final ICatalogModule _catalogModule;
  final IExecutionContext _executionContext;
  final ImagePicker _picker = ImagePicker();

  Future<void> loadCustomFieldGroups() async {
    emit(state.copyWith(isCustomFieldsLoading: true));
    try {
      final tenantId = await _executionContext.requireTenantId();
      final config = await _catalogModule.executeQueryAsync(
        ListCustomFieldConfigQuery(tenantId: tenantId),
      );
      final activeGroups = config.groups
          .where((g) => g.status == CustomFieldConfigStatus.active)
          .map((g) {
            final activeFields = g.fields
                .where((f) => f.status == CustomFieldConfigStatus.active)
                .toList();
            return CustomFieldGroupConfigDto(
              groupId: g.groupId,
              name: g.name,
              iconKey: g.iconKey,
              sortOrder: g.sortOrder,
              status: g.status,
              fieldCount: activeFields.length,
              requiredFieldCount: activeFields.where((f) => f.isRequired).length,
              fields: activeFields,
            );
          })
          .where((g) => g.fields.isNotEmpty)
          .toList();
      emit(
        state.copyWith(
          customFieldGroups: activeGroups,
          isCustomFieldsLoading: false,
        ),
      );
    } catch (_) {
      emit(state.copyWith(isCustomFieldsLoading: false));
    }
  }

  void updateCustomFieldValue(ProductCustomFieldValueInput input) {
    final values = Map<String, ProductCustomFieldValueInput>.from(state.customFieldValues);
    values[input.fieldId] = input;

    final errors = Map<String, String>.from(state.customFieldValidationErrors);
    errors.remove(input.fieldId);

    emit(
      state.copyWith(
        customFieldValues: values,
        customFieldValidationErrors: errors,
      ),
    );
  }

  Future<void> loadTenantMeasurementUnits() async {
    if (state.tenantUnits.isNotEmpty || state.isTenantUnitsLoading) {
      return;
    }

    emit(state.copyWith(isTenantUnitsLoading: true));
    try {
      final tenantId = await _executionContext.requireTenantId();
      final units = await _catalogModule.executeQueryAsync(
        ListTenantMeasurementUnitsQuery(
          tenantId: tenantId,
          limit: 50,
        ),
      );
      emit(
        state.copyWith(
          tenantUnits: units,
          isTenantUnitsLoading: false,
        ),
      );
    } catch (_) {
      emit(state.copyWith(isTenantUnitsLoading: false));
    }
  }

  void updateName(String val) {
    emit(state.copyWith(name: val, clearError: true));
  }

  void updateTradeName(String val) {
    emit(state.copyWith(tradeName: val));
  }

  void updateSku(String val) {
    emit(
      state.copyWith(
        sku: val,
        clearSkuError: true,
        clearDuplicateMatch: true,
        clearError: true,
      ),
    );
  }

  void updateBarcode(String val) {
    emit(
      state.copyWith(
        barcode: val,
        clearBarcodeError: true,
        clearDuplicateMatch: true,
        clearError: true,
      ),
    );
  }

  Future<void> checkDuplicateCodes() async {
    final sku = state.sku.trim();
    final barcode = state.barcode.trim();
    if (sku.isEmpty && barcode.isEmpty) {
      emit(
        state.copyWith(
          clearSkuError: true,
          clearBarcodeError: true,
          clearDuplicateMatch: true,
        ),
      );
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

      emit(
        state.copyWith(
          skuError: skuError,
          barcodeError: barcodeError,
          duplicateProductId: duplicateProductId,
          duplicateProductName: duplicateProductName,
          clearSkuError: skuError == null,
          clearBarcodeError: barcodeError == null,
          clearDuplicateMatch: duplicateProductId == null,
        ),
      );
    } catch (_) {
      // Non-blocking: submit will re-check.
    }
  }

  Future<void> pickImages(ProductImageSource source) async {
    if (state.imageDrafts.length >= ProductGuidedCreateState.maxImages) {
      return;
    }

    try {
      final remaining = ProductGuidedCreateState.maxImages - state.imageDrafts.length;
      List<String> paths = [];

      if (source == ProductImageSource.camera) {
        final picked = await _picker.pickImage(source: ImageSource.camera, imageQuality: 85);
        if (picked != null) {
          paths.add(picked.path);
        }
      } else if (source == ProductImageSource.gallery) {
        final picked = await _picker.pickMultiImage(imageQuality: 85);
        paths.addAll(picked.map((e) => e.path));
      } else if (source == ProductImageSource.file) {
        final result = await FilePicker.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['jpg', 'jpeg', 'png', 'heic', 'webp'],
          allowMultiple: true,
        );
        if (result != null) {
          paths.addAll(result.paths.whereType<String>());
        }
      }

      if (paths.isEmpty) {
        return;
      }

      final toAdd = paths.take(remaining).map((p) => XFile(p)).toList();
      await _uploadPickedFiles(toAdd);
    } catch (_) {
      emit(
        state.copyWith(
          errorMessage: 'Không mở được trình chọn ảnh.',
          status: ProductGuidedCreateStatus.error,
        ),
      );
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
      emit(
        state.copyWith(
          imageDrafts: drafts,
          coverImageIndex: state.coverImageIndex.clamp(0, drafts.length - 1),
          status: ProductGuidedCreateStatus.uploadingImages,
          clearError: true,
        ),
      );

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

      emit(
        state.copyWith(
          imageDrafts: drafts,
          coverImageIndex: state.coverImageIndex.clamp(0, drafts.length - 1),
          status: ProductGuidedCreateStatus.initial,
        ),
      );
    }
  }

  void setCoverImageIndex(int index) {
    if (state.imageDrafts.isEmpty) {
      return;
    }
    emit(
      state.copyWith(
        coverImageIndex: index.clamp(0, state.imageDrafts.length - 1),
      ),
    );
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

  void updateBasicStockQuantityBase(String val) {
    emit(state.copyWith(basicStockQuantityBase: val));
  }

  void updateBaseCost(String val) {
    emit(state.copyWith(baseCost: val));
  }

  void updatePricingMethod(String val) {
    emit(state.copyWith(pricingMethod: val, clearError: true));
    if (val == 'storeRule') {
      loadStorePriceRule();
    }
  }

  Future<void> loadStorePriceRule() async {
    if (state.isStorePriceRuleLoading) {
      return;
    }

    emit(
      state.copyWith(
        isStorePriceRuleLoading: true,
        clearStorePriceRuleUnavailable: true,
        clearStorePriceRule: true,
      ),
    );

    try {
      final tenantId = await _executionContext.requireTenantId();
      final rule = await _catalogModule.executeQueryAsync(
        GetStorePriceRuleQuery(tenantId: tenantId),
      );

      if (rule == null) {
        emit(
          state.copyWith(
            isStorePriceRuleLoading: false,
            storePriceRuleUnavailableReason:
                'Chưa cấu hình khung giá cửa hàng. Vui lòng thiết lập trong Cài đặt sản phẩm.',
          ),
        );
        return;
      }

      if (!rule.isActive) {
        emit(
          state.copyWith(
            isStorePriceRuleLoading: false,
            storePriceRuleUnavailableReason: 'Khung giá cửa hàng đang không hoạt động.',
          ),
        );
        return;
      }

      emit(
        state.copyWith(
          isStorePriceRuleLoading: false,
          storePriceRuleName: rule.name,
          storeRuleListMarkupRatio: rule.listMarkupRatio,
          storeRuleFloorMarkupRatio: rule.floorMarkupRatio,
          clearStorePriceRuleUnavailable: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isStorePriceRuleLoading: false,
          storePriceRuleUnavailableReason: e.toString(),
        ),
      );
    }
  }

  void updateCustomAutoMarkup(String val) {
    emit(state.copyWith(customAutoMarkup: val));
  }

  void updateCustomAutoFloorMarkup(String val) {
    emit(state.copyWith(customAutoFloorMarkup: val));
  }

  void updateManualListPrice(String val) {
    emit(state.copyWith(manualListPrice: val, clearManualPriceError: true, clearError: true));
  }

  void updateManualFloorPrice(String val) {
    emit(state.copyWith(manualFloorPrice: val, clearManualPriceError: true, clearError: true));
  }

  void setStep(int idx) {
    final clamped = idx.clamp(0, state.stepCount - 1);
    if (state.activeStepIndex == idx) {
      emit(state.copyWith(activeStepIndex: -1));
    } else {
      emit(state.copyWith(activeStepIndex: clamped));
      _onStepEntered(clamped);
    }
  }

  void nextStep() {
    if (state.activeStepIndex < state.stepCount - 1) {
      final nextIndex = state.activeStepIndex + 1;
      emit(state.copyWith(activeStepIndex: nextIndex));
      _onStepEntered(nextIndex);
    } else if (state.activeStepIndex >= 0) {
      emit(state.copyWith(activeStepIndex: -1));
    }
  }

  void prevStep() {
    if (state.activeStepIndex > 0) {
      final previousIndex = state.activeStepIndex - 1;
      emit(state.copyWith(activeStepIndex: previousIndex));
      _onStepEntered(previousIndex);
    }
  }

  void _onStepEntered(int stepIndex) {
    if (stepIndex == 2) {
      loadTenantMeasurementUnits();
    } else if (stepIndex == 5) {
      loadStorePriceRule();
    }
  }

  void deferPriceBandStep() {
    emit(
      state.copyWith(
        pricingMethod: 'storeRule',
        customAutoMarkup: '',
        customAutoFloorMarkup: '',
        manualListPrice: '',
        manualFloorPrice: '',
        priceBandConfigured: false,
        clearManualPriceError: true,
        clearError: true,
      ),
    );
    nextStep();
  }

  void confirmPriceBandStep() {
    final resolution = GuidedPriceBandSubmissionResolver.resolve(state);
    if (resolution case GuidedPriceBandInvalid()) {
      _emitPriceBandValidationError(resolution);
      return;
    }

    emit(state.copyWith(priceBandConfigured: true, clearError: true));
    nextStep();
  }

  Future<void> submit() async {
    if (!state.isStep1Valid) {
      emit(
        state.copyWith(
          activeStepIndex: 0,
          showValidationErrors: true,
          status: ProductGuidedCreateStatus.error,
          errorMessage: 'Vui lòng nhập tên nội bộ sản phẩm.',
        ),
      );
      return;
    }

    if (state.basicStockQuantityBaseError != null) {
      emit(
        state.copyWith(
          activeStepIndex: 3,
          showValidationErrors: true,
          status: ProductGuidedCreateStatus.error,
          errorMessage: state.basicStockQuantityBaseError,
        ),
      );
      return;
    }

    if (state.baseCostError != null) {
      emit(
        state.copyWith(
          activeStepIndex: 4,
          showValidationErrors: true,
          status: ProductGuidedCreateStatus.error,
          errorMessage: state.baseCostError,
        ),
      );
      return;
    }

    if (state.isUploadingImages) {
      emit(
        state.copyWith(
          status: ProductGuidedCreateStatus.error,
          errorMessage: 'Đang tải ảnh lên, vui lòng đợi.',
        ),
      );
      return;
    }

    await checkDuplicateCodes();
    if (state.hasDuplicateError) {
      emit(
        state.copyWith(
          activeStepIndex: 0,
          status: ProductGuidedCreateStatus.initial,
        ),
      );
      return;
    }

    final priceBandResolution = GuidedPriceBandSubmissionResolver.resolve(state);
    if (priceBandResolution case GuidedPriceBandInvalid()) {
      _emitPriceBandValidationError(priceBandResolution);
      return;
    }
    final priceBandSubmission = (priceBandResolution as GuidedPriceBandReady).submission;

    emit(
      state.copyWith(
        status: ProductGuidedCreateStatus.loading,
        clearError: true,
      ),
    );

    // Validate custom fields BEFORE creating the product to avoid duplicate/split products
    final validationErrors = <String, String>{};
    int? firstFailedGroupIndex;

    for (int i = 0; i < state.customFieldGroups.length; i++) {
      final group = state.customFieldGroups[i];
      for (final field in group.fields) {
        if (field.isRequired && field.status == CustomFieldConfigStatus.active) {
          final val = state.customFieldValues[field.fieldId];
          if (val == null || val.isEmpty) {
            validationErrors[field.fieldId] = 'Trường này là bắt buộc';
            firstFailedGroupIndex ??= i;
          }
        }
      }
    }

    if (validationErrors.isNotEmpty) {
      emit(
        state.copyWith(
          status: ProductGuidedCreateStatus.error,
          errorMessage: 'Vui lòng điền đầy đủ các trường bắt buộc.',
          customFieldValidationErrors: validationErrors,
          activeStepIndex: 6 + firstFailedGroupIndex!,
        ),
      );
      return;
    }

    try {
      final tenantId = await _executionContext.requireTenantId();
      final actorId = await _executionContext.requireUserId();

      final activeValues = state.customFieldValues.values.where((input) {
        final field = state.customFieldGroups
            .expand((g) => g.fields)
            .firstWhere((f) => f.fieldId == input.fieldId);
        return field.status == CustomFieldConfigStatus.active;
      }).toList();
      final createResult = await _catalogModule.executeCommandAsync(
        CreateGuidedProductCommand(
          tenantId: tenantId,
          actorId: actorId,
          productName: state.name.trim(),
          commercialName: state.tradeName.trim().isNotEmpty ? state.tradeName.trim() : null,
          sku: state.sku.trim().isNotEmpty ? state.sku.trim() : null,
          barcode: state.barcode.trim().isNotEmpty ? state.barcode.trim() : null,
          images: _toImageInputs(),
          baseUnit: state.baseUnit.trim().isEmpty
              ? null
              : _resolveBaseUnitSelection(state.baseUnit),
          basicStockQuantityBase: state.parsedBasicStockQuantityBase,
          basePrice: double.tryParse(state.baseCost.trim().replaceAll(',', '')),
          listBeforeVat: priceBandSubmission.listBeforeVat,
          floorBeforeVat: priceBandSubmission.floorBeforeVat,
          useStorePriceRule: priceBandSubmission.useStorePriceRule,
          priceBandSourceType: priceBandSubmission.sourceType,
          listMarkupRatio: priceBandSubmission.listMarkupRatio,
          floorMarkupRatio: priceBandSubmission.floorMarkupRatio,
          customFieldValues: activeValues,
        ),
      );

      final productId = createResult.productId;

      final productModel = CatalogUiMapper.toListItemModelFromCreate(
        state: state,
        productId: productId,
        readinessSummary: createResult.readinessSummary,
      );

      emit(
        state.copyWith(
          status: ProductGuidedCreateStatus.success,
          createdProduct: productModel,
        ),
      );
    } on DuplicateSkuException catch (e) {
      emit(
        state.copyWith(
          activeStepIndex: 0,
          status: ProductGuidedCreateStatus.initial,
          skuError: 'SKU "${e.sku}" đã được sử dụng',
          duplicateProductId: e.existingProductId,
          duplicateProductName: e.existingProductName,
          clearError: true,
        ),
      );
    } on DuplicateBarcodeException catch (e) {
      emit(
        state.copyWith(
          activeStepIndex: 0,
          status: ProductGuidedCreateStatus.initial,
          barcodeError: 'Barcode "${e.barcode}" đã được sử dụng',
          duplicateProductId: e.existingProductId,
          duplicateProductName: e.existingProductName,
          clearError: true,
        ),
      );
    } on ValidationException catch (e) {
      emit(
        state.copyWith(
          activeStepIndex: 0,
          showValidationErrors: true,
          status: ProductGuidedCreateStatus.error,
          errorMessage: e.message,
        ),
      );
    } on ApplicationException catch (e) {
      emit(
        state.copyWith(
          status: ProductGuidedCreateStatus.error,
          errorMessage: e.message,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: ProductGuidedCreateStatus.error,
          errorMessage: 'Lỗi hệ thống khi tạo sản phẩm.',
        ),
      );
    }
  }

  void _emitPriceBandValidationError(GuidedPriceBandInvalid invalid) {
    emit(
      state.copyWith(
        activeStepIndex: invalid.targetStepIndex,
        showValidationErrors: true,
        status: ProductGuidedCreateStatus.error,
        errorMessage: invalid.message,
        manualPriceError: invalid.manualPriceError,
        clearManualPriceError: invalid.manualPriceError == null,
      ),
    );
  }

  BaseUnitSelection _resolveBaseUnitSelection(String baseUnit) {
    final trimmed = baseUnit.trim();
    for (final unit in state.tenantUnits) {
      if (isSameMeasurementUnitName(trimmed, unit.name)) {
        return ExistingTenantUnit(unit.id);
      }
    }
    return NewTenantUnit(trimmed.toLowerCase());
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
