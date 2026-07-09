import 'package:equatable/equatable.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_catalog_presentation/presentation.dart';
import 'package:vet45_shared_application/application.dart';

enum ProductImagesMaintenanceStatus {
  initial,
  uploading,
  submitting,
  success,
  failure,
}

class ProductImageStateItem extends Equatable {
  const ProductImageStateItem({
    required this.storageKey,
    this.imageId,
    this.slotId,
    this.localPath,
    this.isPrimary = false,
  });

  final String? imageId;
  final String storageKey;
  final String? slotId;
  final String? localPath;
  final bool isPrimary;

  ProductImageStateItem copyWith({
    String? imageId,
    String? storageKey,
    String? slotId,
    String? localPath,
    bool? isPrimary,
  }) {
    return ProductImageStateItem(
      imageId: imageId ?? this.imageId,
      storageKey: storageKey ?? this.storageKey,
      slotId: slotId ?? this.slotId,
      localPath: localPath ?? this.localPath,
      isPrimary: isPrimary ?? this.isPrimary,
    );
  }

  @override
  List<Object?> get props => [imageId, storageKey, slotId, localPath, isPrimary];
}

class ProductImagesMaintenanceState extends Equatable {
  const ProductImagesMaintenanceState({
    this.images = const [],
    this.status = ProductImagesMaintenanceStatus.initial,
    this.errorMessage,
  });

  final List<ProductImageStateItem> images;
  final ProductImagesMaintenanceStatus status;
  final String? errorMessage;

  ProductImagesMaintenanceState copyWith({
    List<ProductImageStateItem>? images,
    ProductImagesMaintenanceStatus? status,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ProductImagesMaintenanceState(
      images: images ?? this.images,
      status: status ?? this.status,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [images, status, errorMessage];
}

class ProductImagesMaintenanceCubit extends Cubit<ProductImagesMaintenanceState> {
  ProductImagesMaintenanceCubit({
    required this.catalogModule,
    required this.executionContext,
    required this.productId,
    required List<String> initialImages,
  }) : super(ProductImagesMaintenanceState(
          images: _initialImageItems(initialImages),
        ));

  final ICatalogModule catalogModule;
  final IExecutionContext executionContext;
  final String productId;
  final ImagePicker _picker = ImagePicker();

  static List<ProductImageStateItem> _initialImageItems(List<String> initialImages) {
    if (initialImages.isEmpty) {
      return const [];
    }

    return initialImages.asMap().entries.map((entry) {
      final index = entry.key;
      final reference = entry.value;
      final storageKey =
          ProductImageDisplayResolver.normalizeToStorageKey(reference) ?? reference;

      return ProductImageStateItem(
        storageKey: storageKey,
        isPrimary: index == 0,
      );
    }).toList(growable: false);
  }

  void addImage({
    required String storageKey,
    required String slotId,
    String? localPath,
  }) {
    if (state.images.length >= 8) {
      emit(state.copyWith(
        status: ProductImagesMaintenanceStatus.failure,
        errorMessage: 'Chỉ được tải lên tối đa 8 ảnh.',
      ));
      emit(state.copyWith(status: ProductImagesMaintenanceStatus.initial, clearError: true));
      return;
    }

    final isFirst = state.images.isEmpty;
    final newItem = ProductImageStateItem(
      storageKey: storageKey,
      slotId: slotId,
      localPath: localPath,
      isPrimary: isFirst,
    );

    emit(state.copyWith(
      images: [...state.images, newItem],
      status: ProductImagesMaintenanceStatus.initial,
      clearError: true,
    ));
  }

  void removeImage(int index) {
    if (index < 0 || index >= state.images.length) return;

    final newImages = List<ProductImageStateItem>.from(state.images);
    final removedItem = newImages.removeAt(index);

    if (removedItem.isPrimary && newImages.isNotEmpty) {
      newImages[0] = newImages[0].copyWith(isPrimary: true);
    }

    emit(state.copyWith(images: newImages));
  }

  void setPrimaryImage(int index) {
    if (index < 0 || index >= state.images.length) return;

    final newImages = state.images.asMap().entries.map((entry) {
      final i = entry.key;
      final img = entry.value;
      return img.copyWith(isPrimary: i == index);
    }).toList();

    emit(state.copyWith(images: newImages));
  }

  void reorderImages(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= state.images.length) return;
    if (newIndex < 0 || newIndex > state.images.length) return;

    var actualNewIndex = newIndex;
    if (oldIndex < actualNewIndex) {
      actualNewIndex -= 1;
    }

    final newImages = List<ProductImageStateItem>.from(state.images);
    final item = newImages.removeAt(oldIndex);
    newImages.insert(actualNewIndex, item);

    emit(state.copyWith(images: newImages));
  }

  Future<void> pickImages(ProductImageSource source) async {
    final maxAllowed = 8 - state.images.length;
    if (maxAllowed <= 0) {
      emit(state.copyWith(
        status: ProductImagesMaintenanceStatus.failure,
        errorMessage: 'Chỉ được tải lên tối đa 8 ảnh.',
      ));
      emit(state.copyWith(status: ProductImagesMaintenanceStatus.initial, clearError: true));
      return;
    }

    try {
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

      final toAdd = paths.take(maxAllowed).map((p) => XFile(p)).toList();
      await _uploadPickedFiles(toAdd);
    } catch (_) {
      emit(state.copyWith(
        status: ProductImagesMaintenanceStatus.failure,
        errorMessage: 'Không mở được trình chọn ảnh.',
      ));
    }
  }

  Future<void> _uploadPickedFiles(List<XFile> files) async {
    if (files.isEmpty) return;

    final tenantId = await executionContext.requireTenantId();
    final actorId = await executionContext.requireUserId();

    for (final file in files) {
      try {
        emit(state.copyWith(status: ProductImagesMaintenanceStatus.uploading, clearError: true));

        final fileName = file.name.isNotEmpty ? file.name : file.path.split('/').last;
        final contentType = ProductImageUploadClient.contentTypeForFileName(fileName);
        final bytes = await file.readAsBytes();

        final command = RequestProductMaintenanceImageUploadCommand(
          tenantId: tenantId,
          actorId: actorId,
          productId: productId,
          fileName: fileName,
          contentType: contentType,
          byteSize: bytes.length,
        );

        final slot = await catalogModule.executeCommandAsync(command);

        await ProductImageUploadClient.uploadBytes(
          signedUploadUrl: slot.signedUploadUrl,
          bytes: bytes,
          contentType: contentType,
        );

        addImage(
          storageKey: slot.storageKey,
          slotId: slot.slotId,
          localPath: file.path,
        );
      } on ValidationException catch (e) {
        emit(state.copyWith(status: ProductImagesMaintenanceStatus.failure, errorMessage: e.message));
        return;
      } on ApplicationException catch (e) {
        emit(state.copyWith(status: ProductImagesMaintenanceStatus.failure, errorMessage: e.message));
        return;
      } catch (e) {
        emit(state.copyWith(status: ProductImagesMaintenanceStatus.failure, errorMessage: 'Lỗi tải ảnh'));
        return;
      }
    }
  }

  Future<void> submit() async {
    emit(state.copyWith(status: ProductImagesMaintenanceStatus.submitting, clearError: true));

    try {
      final inputImages = state.images.asMap().entries.map((entry) {
        final i = entry.key;
        final img = entry.value;
        return ProductImageMutationInput(
          imageId: img.imageId,
          storageKey: img.storageKey,
          slotId: img.slotId,
          isPrimary: img.isPrimary,
          sortOrder: i,
        );
      }).toList();

      final tenantId = await executionContext.requireTenantId();
      final actorId = await executionContext.requireUserId();

      final command = UpdateProductImagesCommand(
        tenantId: tenantId,
        actorId: actorId,
        productId: productId,
        images: inputImages,
        expectedVersion: null,
      );

      await catalogModule.executeCommandAsync(command);

      emit(state.copyWith(status: ProductImagesMaintenanceStatus.success));
    } on ValidationException catch (e) {
      emit(state.copyWith(
        status: ProductImagesMaintenanceStatus.failure,
        errorMessage: e.message,
      ));
    } on ApplicationException catch (e) {
      emit(state.copyWith(
        status: ProductImagesMaintenanceStatus.failure,
        errorMessage: e.message,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ProductImagesMaintenanceStatus.failure,
        errorMessage: 'Đã xảy ra lỗi không xác định. Vui lòng thử lại.',
      ));
    }
  }
}
