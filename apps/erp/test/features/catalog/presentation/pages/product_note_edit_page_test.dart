import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/catalog/data/product_repository.dart';
import 'package:erp/features/catalog/presentation.dart';
import 'package:erp/features/catalog/presentation/pages/product_note_edit_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

final class _MockProductRepository extends Fake implements ProductRepository {
  _MockProductRepository({required this.onUpdateProfile});

  final Future<void> Function({
    required String productId,
    int? expectedVersion,
    required String productName,
    String? commercialName,
    String? sku,
    String? barcode,
    String? description,
    String? note,
  }) onUpdateProfile;

  @override
  Future<void> updateProfile({
    required String productId,
    int? expectedVersion,
    required String productName,
    String? commercialName,
    String? sku,
    String? barcode,
    String? description,
    String? note,
  }) {
    return onUpdateProfile(
      productId: productId,
      expectedVersion: expectedVersion,
      productName: productName,
      commercialName: commercialName,
      sku: sku,
      barcode: barcode,
      description: description,
      note: note,
    );
  }
}

void main() {
  final getIt = GetIt.instance;

  setUp(() async {
    await getIt.reset();
  });

  const dummyProduct = ProductListItemModel(
    id: 'prod-1',
    name: 'Sản phẩm thử nghiệm',
    sku: 'SP001',
    barcode: '8930000000001',
    businessStatus: ProductBusinessStatus.active,
    readinessStatus: ProductReadinessStatus.ready,
  );

  Widget buildWidget(ProductNoteEditRouteArgs args) {
    return MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ProductNoteEditPage(args: args),
                  ),
                );
              },
              child: const Text('Open Page'),
            );
          },
        ),
      ),
    );
  }

  testWidgets('ProductNoteEditPage (H8): saves note successfully and pops with true', (tester) async {
    String? savedNote;
    final repo = _MockProductRepository(
      onUpdateProfile: ({
        required productId,
        required productName,
        commercialName,
        sku,
        barcode,
        description,
        note,
        expectedVersion,
      }) async {
        savedNote = note;
      },
    );
    getIt.registerSingleton<ProductRepository>(repo);

    await tester.pumpWidget(
      buildWidget(
        const ProductNoteEditRouteArgs(
          product: dummyProduct,
          currentNote: 'Ghi chú ban đầu',
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Open note edit page
    await tester.tap(find.text('Open Page'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('input_product_note')), findsOneWidget);

    // Edit note
    await tester.enterText(find.byKey(const Key('input_product_note')), 'Ghi chú mới được cập nhật');
    await tester.pumpAndSettle();

    // Tap save button
    await tester.tap(find.byKey(const Key('btn_note_save')));
    await tester.pumpAndSettle();

    expect(savedNote, 'Ghi chú mới được cập nhật');
    expect(find.text('Đã lưu ghi chú sản phẩm'), findsWidgets);
    // Page popped, back to open button
    expect(find.text('Open Page'), findsOneWidget);
  });

  testWidgets('ProductNoteEditPage (H8): shows toast on save error', (tester) async {
    final repo = _MockProductRepository(
      onUpdateProfile: ({
        required productId,
        required productName,
        commercialName,
        sku,
        barcode,
        description,
        note,
        expectedVersion,
      }) async {
        throw const AppException(
          AppErrorCode.noPermission,
          serverMessage: 'Permission denied',
        );
      },
    );
    getIt.registerSingleton<ProductRepository>(repo);

    await tester.pumpWidget(
      buildWidget(
        const ProductNoteEditRouteArgs(
          product: dummyProduct,
          currentNote: 'Ghi chú ban đầu',
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Open note edit page
    await tester.tap(find.text('Open Page'));
    await tester.pumpAndSettle();

    // Edit note
    await tester.enterText(find.byKey(const Key('input_product_note')), 'Ghi chú bị lỗi');
    await tester.pumpAndSettle();

    // Tap save button
    await tester.tap(find.byKey(const Key('btn_note_save')));
    await tester.pumpAndSettle();

    expect(find.text('Bạn không có quyền thực hiện thao tác này.'), findsWidgets);
    // Page did not pop on error
    expect(find.byKey(const Key('wgt_note_edit_page')), findsOneWidget);
  });
}
