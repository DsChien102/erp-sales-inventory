/// Output DTO models for catalog mutation operations.
library;

import 'catalog_enums.dart';
import 'product_readiness.dart';

final class CreateGuidedProductResult {
  const CreateGuidedProductResult({
    required this.productId,
    required this.readinessSummary,
  });

  final String productId;
  final ReadinessSummaryDto readinessSummary;

  factory CreateGuidedProductResult.fromJson(Map<String, dynamic> row) {
    return CreateGuidedProductResult(
      productId: row['product_id'] as String,
      readinessSummary: ReadinessSummaryDto.fromRow(row),
    );
  }
}

final class ProductImageUploadSlotDto {
  const ProductImageUploadSlotDto({
    required this.slotId,
    required this.storageKey,
    required this.signedUploadUrl,
    required this.expiresAt,
  });

  final String slotId;
  final String storageKey;
  final String signedUploadUrl;
  final DateTime expiresAt;
}

final class ProductDuplicateMatchDto {
  const ProductDuplicateMatchDto({
    required this.field,
    required this.productId,
    required this.productName,
    required this.matchedValue,
  });

  final ProductDuplicateField field;
  final String productId;
  final String productName;
  final String matchedValue;

  factory ProductDuplicateMatchDto.fromJson(Map<String, dynamic> row) {
    final fieldStr = row['duplicate_field'] as String;
    final field = switch (fieldStr) {
      'sku' => ProductDuplicateField.sku,
      'barcode' => ProductDuplicateField.barcode,
      _ => throw ArgumentError('Unknown duplicate field: $fieldStr'),
    };

    return ProductDuplicateMatchDto(
      field: field,
      productId: row['product_id'] as String,
      productName: row['product_name'] as String,
      matchedValue: row['matched_value'] as String,
    );
  }
}

final class ProductDeletionIssueDto {
  const ProductDeletionIssueDto({
    required this.code,
    required this.message,
    required this.severity,
  });

  final String code;
  final String message;
  final ProductDeletionIssueSeverity severity;

  factory ProductDeletionIssueDto.fromJson(Map<String, dynamic> row) {
    final sevStr = row['severity'] as String?;
    final severity = switch (sevStr) {
      'blocker' => ProductDeletionIssueSeverity.blocker,
      'recommendation' => ProductDeletionIssueSeverity.recommendation,
      _ => ProductDeletionIssueSeverity.warning,
    };

    return ProductDeletionIssueDto(
      code: row['code'] as String,
      message: row['message'] as String,
      severity: severity,
    );
  }
}

final class ProductDeletionEligibilityDto {
  const ProductDeletionEligibilityDto({
    required this.productId,
    required this.canDelete,
    this.issues = const [],
    this.suggestedActionId,
  });

  final String productId;
  final bool canDelete;
  final List<ProductDeletionIssueDto> issues;
  final String? suggestedActionId;

  List<ProductDeletionIssueDto> get blockers => issues
      .where((issue) => issue.severity == ProductDeletionIssueSeverity.blocker)
      .toList(growable: false);

  List<ProductDeletionIssueDto> get warnings => issues
      .where((issue) => issue.severity == ProductDeletionIssueSeverity.warning)
      .toList(growable: false);

  factory ProductDeletionEligibilityDto.fromRow(Map<String, dynamic> row) {
    final issuesRaw = row['issues'] as List<dynamic>? ?? const [];
    final issues = issuesRaw.map((item) {
      final map = Map<String, dynamic>.from(item as Map);
      return ProductDeletionIssueDto.fromJson(map);
    }).toList(growable: false);

    return ProductDeletionEligibilityDto(
      productId: row['product_id'] as String,
      canDelete: row['can_delete'] as bool? ?? false,
      issues: issues,
      suggestedActionId: row['suggested_action_id'] as String?,
    );
  }
}

final class ProductBusinessStatusWarningDto {
  const ProductBusinessStatusWarningDto({
    required this.code,
    required this.message,
  });

  final String code;
  final String message;

  factory ProductBusinessStatusWarningDto.fromJson(Map<String, dynamic> row) {
    return ProductBusinessStatusWarningDto(
      code: row['code'] as String,
      message: row['message'] as String,
    );
  }
}

