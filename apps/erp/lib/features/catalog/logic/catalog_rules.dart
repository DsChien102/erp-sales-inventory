/// Pure validation rules for catalog operations (TH-02).
library;

import 'package:erp/core/errors/app_exception.dart';

import '../data/models/catalog_enums.dart';
import '../data/models/product_inputs.dart';

const _allowedContentTypes = {
  'image/jpeg',
  'image/png',
  'image/webp',
};

const _maxByteSize = 10 * 1024 * 1024;

void checkCreateGuided(CreateGuidedProductInput input) {
  if (input.productName.trim().isEmpty) {
    throw const AppException(
      AppErrorCode.validation,
      serverMessage: 'Tenant, actor and product name are required.',
    );
  }
  if (input.images.length > 8) {
    throw const AppException(
      AppErrorCode.validation,
      serverMessage: 'A product can have at most 8 images.',
    );
  }
  if (input.images.where((image) => image.isPrimary).length > 1) {
    throw const AppException(
      AppErrorCode.validation,
      serverMessage: 'Only one primary image is allowed.',
    );
  }
  if (input.baseUnit case ExistingTenantUnit(:final unitId)) {
    if (unitId.trim().isEmpty) {
      throw const AppException(
        AppErrorCode.validation,
        serverMessage: 'Base unit id is required.',
      );
    }
  }
  if (input.baseUnit case NewTenantUnit(:final name)) {
    if (name.trim().isEmpty) {
      throw const AppException(
        AppErrorCode.validation,
        serverMessage: 'Base unit name is required.',
      );
    }
  }

  final requiresBaseUnit = input.basicStockQuantityBase != null ||
      input.basePrice != null ||
      input.listBeforeVat != null ||
      input.floorBeforeVat != null ||
      input.priceBandSourceType == PriceBandSourceType.customConfig ||
      input.priceBandSourceType == PriceBandSourceType.manual;

  if (requiresBaseUnit && input.baseUnit == null) {
    throw const AppException(
      AppErrorCode.validation,
      serverMessage: 'Cần thiết lập đơn vị cơ sở trước tồn kho hoặc giá.',
    );
  }
  if (input.basicStockQuantityBase != null && input.basicStockQuantityBase! < 0) {
    throw const AppException(
      AppErrorCode.validation,
      serverMessage: 'Số lượng tồn kho ban đầu phải là số nguyên không âm.',
    );
  }
  for (final value in [input.basePrice, input.listBeforeVat, input.floorBeforeVat]) {
    if (value != null && (!value.isFinite || value < 0)) {
      throw const AppException(
        AppErrorCode.validation,
        serverMessage: 'Giá phải là số không âm.',
      );
    }
  }
  if (input.floorBeforeVat != null &&
      input.listBeforeVat != null &&
      input.floorBeforeVat! > input.listBeforeVat!) {
    throw const AppException(
      AppErrorCode.validation,
      serverMessage: 'Giá sàn không được lớn hơn giá niêm yết.',
    );
  }
  switch (input.priceBandSourceType) {
    case PriceBandSourceType.customConfig:
      if (input.listMarkupRatio == null ||
          input.listMarkupRatio! < 0 ||
          (input.floorMarkupRatio != null &&
              (input.floorMarkupRatio! < 0 ||
                  input.floorMarkupRatio! > input.listMarkupRatio!))) {
        throw const AppException(
          AppErrorCode.validation,
          serverMessage: 'Cấu hình giá tự động riêng không hợp lệ.',
        );
      }
      break;
    case PriceBandSourceType.manual:
      if (input.listBeforeVat == null) {
        throw const AppException(
          AppErrorCode.validation,
          serverMessage: 'Giá niêm yết là bắt buộc.',
        );
      }
      break;
    case PriceBandSourceType.ruleBased:
      if (!input.useStorePriceRule) {
        throw const AppException(
          AppErrorCode.validation,
          serverMessage: 'Cần áp dụng khung giá cửa hàng.',
        );
      }
      break;
    case null:
      break;
  }
  final fieldIds = <String>{};
  for (final value in input.customFieldValues) {
    if (value.fieldId.trim().isEmpty || !fieldIds.add(value.fieldId)) {
      throw const AppException(
        AppErrorCode.validation,
        serverMessage: 'Custom field value không hợp lệ.',
      );
    }
    if (_typedValueCount(value) > 1) {
      throw const AppException(
        AppErrorCode.validation,
        serverMessage: 'Mỗi custom field chỉ được có một kiểu giá trị.',
      );
    }
  }
}

int _typedValueCount(ProductCustomFieldValueInput input) => [
  input.textValue?.trim().isNotEmpty == true,
  input.numberValue != null,
  input.dateValue != null,
  input.booleanValue != null,
  input.optionId?.trim().isNotEmpty == true,
].where((value) => value).length;

void checkImageUploadRequest({
  required String fileName,
  required String contentType,
  required int byteSize,
}) {
  if (fileName.trim().isEmpty) {
    throw const AppException(
      AppErrorCode.validation,
      serverMessage: 'File name is required.',
    );
  }
  if (!_allowedContentTypes.contains(contentType.toLowerCase())) {
    throw const AppException(
      AppErrorCode.validation,
      serverMessage: 'Unsupported image content type.',
    );
  }
  if (byteSize <= 0) {
    throw const AppException(
      AppErrorCode.validation,
      serverMessage: 'Image byte size must be positive.',
    );
  }
  if (byteSize > _maxByteSize) {
    throw const AppException(
      AppErrorCode.validation,
      serverMessage: 'Image exceeds maximum allowed size.',
    );
  }
}

void checkUpdateProfile({
  required String productName,
  String? sku,
  String? barcode,
  int? expectedVersion,
}) {
  if (productName.trim().isEmpty) {
    throw const AppException(
      AppErrorCode.validation,
      serverMessage: 'Product name is required.',
    );
  }
  if (expectedVersion != null && expectedVersion <= 0) {
    throw const AppException(
      AppErrorCode.validation,
      serverMessage: 'Expected version must be positive.',
    );
  }
}

void checkUpdateImages({
  required List<ProductImageMutationInput> images,
  int? expectedVersion,
}) {
  if (expectedVersion != null && expectedVersion <= 0) {
    throw const AppException(
      AppErrorCode.validation,
      serverMessage: 'Expected version must be positive.',
    );
  }
  if (images.where((image) => image.isPrimary).length > 1) {
    throw const AppException(
      AppErrorCode.validation,
      serverMessage: 'A product may have at most one primary image.',
    );
  }
  for (final image in images) {
    if (image.storageKey.trim().isEmpty) {
      throw const AppException(
        AppErrorCode.validation,
        serverMessage: 'Image storage key is required.',
      );
    }
  }
}

