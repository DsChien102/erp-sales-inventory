/// Pure validation rules for catalog operations (TH-02).
library;

import 'package:erp/core/errors/app_exception.dart';

import '../data/catalog_errors.dart';
import '../data/models/catalog_enums.dart';
import '../data/models/custom_field_config.dart';
import '../data/models/custom_field_filter_option.dart';
import '../data/models/price_band.dart';
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

const maxUnitNameLength = 80;

void checkBaseUnitSelection(BaseUnitSelection selection) {
  switch (selection) {
    case ExistingTenantUnit(:final unitId):
      if (unitId.trim().isEmpty) {
        throw const AppException(
          AppErrorCode.validation,
          serverMessage: 'Measurement unit id is required.',
        );
      }
    case NewTenantUnit(:final name):
      final trimmed = name.trim();
      if (trimmed.isEmpty) {
        throw const AppException(
          AppErrorCode.validation,
          serverMessage: 'Unit name must not be empty.',
        );
      }
      if (trimmed.length > maxUnitNameLength) {
        throw const AppException(
          AppErrorCode.validation,
          serverMessage: 'Unit name is too long.',
        );
      }
  }
}

void checkConversionUnit({
  required String unitName,
  required double conversionRateToBase,
}) {
  final trimmed = unitName.trim();
  if (trimmed.isEmpty) {
    throw const AppException(
      AppErrorCode.validation,
      serverMessage: 'Unit name must not be empty.',
    );
  }
  if (trimmed.length > maxUnitNameLength) {
    throw const AppException(
      AppErrorCode.validation,
      serverMessage: 'Unit name is too long.',
    );
  }
  if (conversionRateToBase <= 0) {
    throw const AppException(
      AppErrorCode.validation,
      serverMessage: 'Conversion rate must be greater than zero.',
    );
  }
}

void checkUpsertCustomFieldGroup(String name) {
  if (name.trim().isEmpty) {
    throw const AppException(
      AppErrorCode.validation,
      serverMessage: 'Group name must not be empty.',
    );
  }
}

void checkReorderGroups(List<String> orderedGroupIds) {
  if (orderedGroupIds.isEmpty) {
    throw const AppException(
      AppErrorCode.validation,
      serverMessage: 'Ordered group ids must include all groups.',
    );
  }
  for (final id in orderedGroupIds) {
    if (id.trim().isEmpty) {
      throw const AppException(
        AppErrorCode.validation,
        serverMessage: 'Group id must not be empty.',
      );
    }
  }
}

void checkReorderFields(List<String> orderedFieldIds) {
  if (orderedFieldIds.isEmpty) {
    throw const AppException(
      AppErrorCode.validation,
      serverMessage: 'Ordered field ids must include all fields.',
    );
  }
  for (final id in orderedFieldIds) {
    if (id.trim().isEmpty) {
      throw const AppException(
        AppErrorCode.validation,
        serverMessage: 'Field id must not be empty.',
      );
    }
  }
}

void checkUpsertCustomField({
  String? fieldId,
  required String name,
  required CustomFieldType fieldType,
  List<CustomFieldSelectOptionDto> options = const [],
}) {
  if (name.trim().isEmpty) {
    throw const AppException(
      AppErrorCode.validation,
      serverMessage: 'Field name must not be empty.',
    );
  }
  if (fieldType == CustomFieldType.singleSelect &&
      options.isEmpty &&
      fieldId == null) {
    throw const AppException(
      AppErrorCode.validation,
      serverMessage: 'Single select field requires options.',
    );
  }
  if (fieldType == CustomFieldType.singleSelect &&
      options.where((o) => o.label.trim().isNotEmpty).isEmpty) {
    throw const AppException(
      AppErrorCode.validation,
      serverMessage: 'Trường single select phải có ít nhất một option hợp lệ.',
    );
  }
}

void checkUpsertProductValues(List<ProductCustomFieldValueInput> values) {
  final fieldIds = <String>{};
  for (final value in values) {
    if (value.fieldId.trim().isEmpty) {
      throw const AppException(
        AppErrorCode.validation,
        serverMessage: 'Field id is required.',
      );
    }
    if (!fieldIds.add(value.fieldId)) {
      throw const AppException(
        AppErrorCode.validation,
        serverMessage: 'Duplicate custom field value.',
      );
    }
    if (_typedValueCount(value) > 1) {
      throw const AppException(
        AppErrorCode.validation,
        serverMessage: 'Only one typed value is allowed per custom field.',
      );
    }
  }
}

void checkManualBasePrice(double basePrice) {
  if (basePrice < 0) {
    throw const AppException(
      AppErrorCode.validation,
      serverMessage: 'Giá cơ sở không được âm.',
    );
  }
}

void checkUnitPriceBand({
  required PriceBandSourceType sourceType,
  int? listBeforeVat,
  int? listAfterVat,
  int? floorBeforeVat,
  int? floorAfterVat,
  double? listMarkupRatio,
  double? floorMarkupRatio,
}) {
  switch (sourceType) {
    case PriceBandSourceType.ruleBased:
      throw const AppException(
        AppErrorCode.validation,
        serverMessage: 'Vui lòng dùng lệnh áp dụng khung giá cửa hàng.',
      );
    case PriceBandSourceType.customConfig:
      if (listBeforeVat != null ||
          listAfterVat != null ||
          floorBeforeVat != null ||
          floorAfterVat != null) {
        throw const AppException(
          AppErrorCode.validation,
          serverMessage: 'Cấu hình riêng chỉ nhận tỷ lệ phần trăm.',
        );
      }
      if (listMarkupRatio == null) {
        throw const AppException(
          AppErrorCode.validation,
          serverMessage: 'Tỷ lệ giá niêm yết là bắt buộc.',
        );
      }
      if (listMarkupRatio < 0) {
        throw const AppException(
          AppErrorCode.validation,
          serverMessage: 'Tỷ lệ không được âm.',
        );
      }
      if (floorMarkupRatio != null) {
        if (floorMarkupRatio < 0) {
          throw const AppException(
            AppErrorCode.validation,
            serverMessage: 'Tỷ lệ không được âm.',
          );
        }
        if (floorMarkupRatio > listMarkupRatio) {
          throw const AppException(
            AppErrorCode.validation,
            serverMessage: 'Tỷ lệ giá sàn không được lớn hơn tỷ lệ giá niêm yết.',
          );
        }
      }
    case PriceBandSourceType.manual:
      if (listMarkupRatio != null || floorMarkupRatio != null) {
        throw const AppException(
          AppErrorCode.validation,
          serverMessage: 'Giá thủ công không được có nguồn công thức.',
        );
      }
      if (listBeforeVat == null || listAfterVat == null) {
        throw const AppException(
          AppErrorCode.validation,
          serverMessage: 'Giá niêm yết là bắt buộc.',
        );
      }
      if (listBeforeVat < 0 || listAfterVat < 0) {
        throw const AppException(
          AppErrorCode.validation,
          serverMessage: 'Giá không được âm.',
        );
      }
      if (floorBeforeVat != null) {
        if (floorBeforeVat < 0) {
          throw const AppException(
            AppErrorCode.validation,
            serverMessage: 'Giá không được âm.',
          );
        }
        if (floorBeforeVat > listBeforeVat) {
          throw const AppException(CatalogErrorCodes.floorGreaterThanList);
        }
      }
      if (floorAfterVat != null) {
        if (floorAfterVat < 0) {
          throw const AppException(
            AppErrorCode.validation,
            serverMessage: 'Giá không được âm.',
          );
        }
        if (floorAfterVat > listAfterVat) {
          throw const AppException(CatalogErrorCodes.floorGreaterThanList);
        }
      }
  }
}

void checkStorePriceRule({
  required String name,
  required double listMarkupRatio,
  required double floorMarkupRatio,
}) {
  if (name.trim().isEmpty) {
    throw const AppException(
      AppErrorCode.validation,
      serverMessage: 'Tên quy tắc giá là bắt buộc.',
    );
  }
  if (listMarkupRatio < 0) {
    throw const AppException(
      AppErrorCode.validation,
      serverMessage: 'Tỷ lệ cộng thêm Giá niêm yết phải lớn hơn hoặc bằng 0.',
    );
  }
  if (floorMarkupRatio < 0) {
    throw const AppException(
      AppErrorCode.validation,
      serverMessage: 'Tỷ lệ cộng thêm Giá sàn phải lớn hơn hoặc bằng 0.',
    );
  }
  final listPrice = (100 * (1 + listMarkupRatio)).roundToDouble();
  final floorPrice = (100 * (1 + floorMarkupRatio)).roundToDouble();
  if (floorPrice > listPrice) {
    throw const AppException(
      AppErrorCode.validation,
      serverMessage: 'Giá sàn không được lớn hơn giá niêm yết.',
    );
  }
  if (floorMarkupRatio > listMarkupRatio) {
    throw const AppException(
      AppErrorCode.validation,
      serverMessage: 'Floor markup ratio must not be greater than list markup ratio.',
    );
  }
}

void checkPriceBandSnapshotRequest(List<ProductPriceBandSnapshotRequest> items) {
  if (items.isEmpty) {
    throw const AppException(
      AppErrorCode.validation,
      serverMessage: 'At least one item is required.',
    );
  }
  if (items.length > 100) {
    throw const AppException(
      AppErrorCode.validation,
      serverMessage: 'At most 100 items can be read at once.',
    );
  }
  final seen = <String>{};
  for (final item in items) {
    if (item.productId.trim().isEmpty) {
      throw const AppException(
        AppErrorCode.validation,
        serverMessage: 'Product id is required.',
      );
    }
    if (item.productUnitId.trim().isEmpty) {
      throw const AppException(
        AppErrorCode.validation,
        serverMessage: 'Product unit id is required.',
      );
    }
    final key = '${item.productId}:${item.productUnitId}';
    if (!seen.add(key)) {
      throw const AppException(
        AppErrorCode.validation,
        serverMessage: 'Duplicate product and unit pair is not allowed.',
      );
    }
  }
}

void checkSetBasicStock(int quantity) {
  if (quantity < 0) {
    throw const AppException(
      AppErrorCode.validation,
      serverMessage: 'Số lượng tồn kho ban đầu không được âm.',
    );
  }
}

void checkAdjustBasicStock(int newQuantity) {
  if (newQuantity < 0) {
    throw const AppException(
      AppErrorCode.validation,
      serverMessage: 'Số lượng tồn kho không được âm.',
    );
  }
}


