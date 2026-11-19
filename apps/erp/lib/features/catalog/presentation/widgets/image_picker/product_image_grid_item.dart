import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:c45_design_system/design_system.dart';
import 'package:erp/features/catalog/presentation.dart';

class ProductImageGridItem extends StatelessWidget {
  const ProductImageGridItem({
    super.key,
    required this.localPath,
    this.storageKey,
    this.isPrimary = false,
    this.isUploading = false,
    this.isFailed = false,
    this.errorMessage,
    required this.onSetPrimary,
    required this.onRemove,
  });

  final String? localPath;
  final String? storageKey;
  final bool isPrimary;
  final bool isUploading;
  final bool isFailed;
  final String? errorMessage;
  final VoidCallback onSetPrimary;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final dynamicColors = context.vColors;

    Widget imageChild;
    if (localPath != null && localPath!.startsWith('http')) {
      imageChild = Image.network(localPath!, fit: BoxFit.cover);
    } else if (storageKey != null && storageKey!.isNotEmpty) {
      imageChild = CatalogStorageImage(
        storageReference: storageKey!,
        localPath: localPath,
        width: 100,
        height: 100,
        fit: BoxFit.cover,
        placeholder: ColoredBox(
          color: dynamicColors.surfaceAlt,
          child: Icon(
            Icons.image,
            color: dynamicColors.textSecondary,
          ),
        ),
      );
    } else if (localPath != null && !kIsWeb && File(localPath!).existsSync()) {
      imageChild = Image.file(File(localPath!), fit: BoxFit.cover);
    } else {
      imageChild = Center(
        child: Icon(Icons.broken_image_outlined, color: dynamicColors.textMuted),
      );
    }

    return Container(
      padding: EdgeInsets.all(isPrimary ? 0 : 1),
      decoration: BoxDecoration(
        border: Border.all(
          color: isFailed
              ? dynamicColors.danger
              : (isPrimary ? dynamicColors.success : dynamicColors.borderDefault),
          width: isPrimary ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(VRadius.card),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(isPrimary ? VRadius.card - 2 : VRadius.card - 1),
        child: GestureDetector(
          onTap: isFailed ? null : onSetPrimary,
          child: Stack(
            fit: StackFit.expand,
            children: [
              imageChild,
              if (isUploading)
                Container(
                  color: dynamicColors.surface.withValues(alpha: 0.8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: VSpacing.space6,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: dynamicColors.primary,
                        ),
                      ),
                      const SizedBox(height: VSpacing.space1),
                      VText(
                        'Đang tải',
                        style: VTypography.caption.copyWith(
                          color: dynamicColors.primary,
                          fontWeight: FontWeight.w500,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              if (isFailed)
                Container(
                  color: dynamicColors.surface.withValues(alpha: 0.8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, color: dynamicColors.danger, size: 24),
                      const SizedBox(height: VSpacing.space1),
                      VText(
                        errorMessage ?? 'Lỗi tải',
                        textAlign: TextAlign.center,
                        style: VTypography.caption.copyWith(
                          color: dynamicColors.danger,
                          fontWeight: FontWeight.w500,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              if (isPrimary && !isFailed && !isUploading)
                Positioned(
                  top: 0,
                  left: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: dynamicColors.success,
                      borderRadius: const BorderRadius.only(
                        bottomRight: Radius.circular(VRadius.card),
                      ),
                    ),
                    child: VText(
                      'Mặc định',
                      style: VTypography.caption.copyWith(
                        color: dynamicColors.surface,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
              Positioned(
                top: 4,
                right: 4,
                child: GestureDetector(
                  onTap: onRemove,
                  child: CircleAvatar(
                    radius: 12,
                    backgroundColor: dynamicColors.surface,
                    child: Icon(Icons.close, size: 14, color: dynamicColors.textSecondary),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
