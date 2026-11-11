import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:erp/core/di/injection.dart';
import 'package:erp/features/inventory/data/goods_receipt/goods_receipt_models.dart';
import 'package:erp/features/inventory/data/goods_receipt/goods_receipt_repository.dart';
import 'package:erp/features/inventory/data/supplier_program/supplier_program_repository.dart';
import 'package:erp/features/inventory/logic/goods_receipt/receipt_draft_cubit.dart';
import 'package:erp/features/inventory/logic/goods_receipt/receipt_list_cubit.dart';
import 'package:erp/features/inventory/presentation/goods_receipt/receipt_detail_page.dart';
import 'package:erp/features/inventory/presentation/goods_receipt/receipt_header_page.dart';
import 'package:erp/features/inventory/presentation/goods_receipt/receipt_line_editor_page.dart';
import 'package:erp/features/inventory/presentation/goods_receipt/receipt_lines_page.dart';
import 'package:erp/features/inventory/presentation/goods_receipt/receipt_list_page.dart';
import 'package:erp/features/inventory/presentation/goods_receipt/receipt_result_page.dart';
import 'package:erp/features/inventory/presentation/goods_receipt/receipt_review_page.dart';

List<RouteBase> goodsReceiptRoutes({
  GoodsReceiptRepository? repository,
  SupplierProgramRepository? programs,
}) {
  GoodsReceiptRepository resolveRepo(BuildContext context) {
    if (repository != null) return repository;
    try {
      return context.read<GoodsReceiptRepository>();
    } catch (_) {
      return getIt<GoodsReceiptRepository>();
    }
  }

  SupplierProgramRepository resolvePrograms(BuildContext context) {
    if (programs != null) return programs;
    try {
      return context.read<SupplierProgramRepository>();
    } catch (_) {
      return getIt<SupplierProgramRepository>();
    }
  }

  return [
    GoRoute(
      path: '/warehouse/receipts',
      builder: (context, state) {
        final supplierId = state.uri.queryParameters['supplier_id'];
        return BlocProvider(
          create: (_) => ReceiptListCubit(
            repository: resolveRepo(context),
            initialSupplierId: supplierId,
          )..load(),
          child: ReceiptListPage(
            onOpenDetail: (id) => context.push('/warehouse/receipts/$id'),
            onNewReceipt: () => context.push('/warehouse/receipts/new'),
          ),
        );
      },
      routes: [
        ShellRoute(
          builder: (context, state, child) {
            final initialProductId = state.uri.queryParameters['product_id'];
            return BlocProvider(
              create: (_) => ReceiptDraftCubit(
                repository: resolveRepo(context),
                programs: resolvePrograms(context),
                initialProductId: initialProductId,
              )..load(),
              child: child,
            );
          },
          routes: [
            GoRoute(
              path: 'new',
              builder: (context, state) => ReceiptHeaderPage(
                onContinue: () => context.push('/warehouse/receipts/new/lines'),
              ),
              routes: [
                GoRoute(
                  path: 'lines',
                  builder: (context, state) => ReceiptLinesPage(
                    onContinue: () async {
                      await context.read<ReceiptDraftCubit>().prepareReview();
                      if (context.mounted) {
                        context.push('/warehouse/receipts/new/review');
                      }
                    },
                    onEditLine: (key) => context.push(
                      '/warehouse/receipts/new/lines/editor?key=$key',
                    ),
                  ),
                  routes: [
                    GoRoute(
                      path: 'editor',
                      builder: (context, state) {
                        final lineKey = state.uri.queryParameters['key'] ?? '';
                        return ReceiptLineEditorPage(
                          lineKey: lineKey,
                          onDone: () => context.pop(),
                        );
                      },
                    ),
                  ],
                ),
                GoRoute(
                  path: 'review',
                  builder: (context, state) => ReceiptReviewPage(
                    onSuccess: (result) {
                      context.go(
                        '/warehouse/receipts/${result.receiptId}/result',
                        extra: result,
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
        GoRoute(
          path: ':id/result',
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            final extraResult = state.extra as RecordReceiptResult?;
            if (extraResult != null) {
              return ReceiptResultPage(
                result: extraResult,
                onViewReceipt: (receiptId) =>
                    context.go('/warehouse/receipts/$receiptId'),
                onViewStock: () => context.go('/warehouse/stock'),
                onNewReceipt: () => context.go('/warehouse/receipts/new'),
              );
            }
            return FutureBuilder<ReceiptDetail>(
              future: resolveRepo(context).get(id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snapshot.hasError || !snapshot.hasData) {
                  return Scaffold(
                    body: Center(
                      child: Text('Không tìm thấy kết quả phiếu nhận: $id'),
                    ),
                  );
                }
                final detail = snapshot.data!;
                final fallbackResult = RecordReceiptResult(
                  receiptId: detail.header.receiptId,
                  receiptNo: detail.header.receiptNo,
                  businessDate: detail.header.businessDate,
                  supplierName: detail.header.supplierName,
                  supplierDocNo: detail.header.supplierDocNo,
                  lineCount: detail.header.lineCount,
                  lotCount: detail.header.lotCount,
                  landedTotalVnd: detail.header.landedTotalVnd,
                  createdByName: detail.header.createdByName,
                  stockChanges: const [],
                  reachedPrograms: const [],
                );
                return ReceiptResultPage(
                  result: fallbackResult,
                  onViewReceipt: (receiptId) =>
                      context.go('/warehouse/receipts/$receiptId'),
                  onViewStock: () => context.go('/warehouse/stock'),
                  onNewReceipt: () => context.go('/warehouse/receipts/new'),
                );
              },
            );
          },
        ),
        GoRoute(
          path: ':id',
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            return ReceiptDetailPage(receiptId: id);
          },
        ),
      ],
    ),
  ];
}
