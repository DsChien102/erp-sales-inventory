enum ProductImageUploadStatus {
  local,
  uploading,
  uploaded,
  failed,
}

/// Local pick + remote staging metadata for guided create.
class ProductImageDraft {
  const ProductImageDraft({
    required this.localPath,
    this.storageKey,
    this.slotId,
    this.status = ProductImageUploadStatus.local,
    this.errorMessage,
  });

  final String localPath;
  final String? storageKey;
  final String? slotId;
  final ProductImageUploadStatus status;
  final String? errorMessage;

  bool get isUploaded => status == ProductImageUploadStatus.uploaded;

  ProductImageDraft copyWith({
    String? localPath,
    String? storageKey,
    String? slotId,
    ProductImageUploadStatus? status,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ProductImageDraft(
      localPath: localPath ?? this.localPath,
      storageKey: storageKey ?? this.storageKey,
      slotId: slotId ?? this.slotId,
      status: status ?? this.status,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
