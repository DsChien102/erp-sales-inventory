import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';

import '../../../../core/di/injection.dart';
import '../../data/goods_receipt_repository.dart';
import '../../data/models/receipt_document_model.dart';
import '../../logic/receipt_reconciliation_cubit.dart';
import '../widgets/inventory_state_views.dart';

/// SCR-013: xác minh kết quả `UNKNOWN` trên cùng lần nhận, không bao giờ làm lại.
class GoodsReceiptReconciliationPage extends StatelessWidget {
  const GoodsReceiptReconciliationPage({
    super.key,
    required this.receiptId,
    this.repository,
    this.clock,
    this.autoReturnDelay = const Duration(seconds: 2),
  });

  final String receiptId;
  final GoodsReceiptRepository? repository;
  final DateTime Function()? clock;

  /// Thời gian chờ trước khi tự về SCR-012 khi đã có kết quả cuối.
  final Duration autoReturnDelay;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ReceiptReconciliationCubit(
        repository: repository ?? getIt<GoodsReceiptRepository>(),
        clock: clock,
      )..check(receiptId),
      child: _ReconciliationView(
        receiptId: receiptId,
        clock: clock ?? DateTime.now,
        autoReturnDelay: autoReturnDelay,
      ),
    );
  }
}

class _ReconciliationView extends StatefulWidget {
  const _ReconciliationView({
    required this.receiptId,
    required this.clock,
    required this.autoReturnDelay,
  });

  final String receiptId;
  final DateTime Function() clock;
  final Duration autoReturnDelay;

  @override
  State<_ReconciliationView> createState() => _ReconciliationViewState();
}

class _ReconciliationViewState extends State<_ReconciliationView> {
  Timer? _autoReturn;

  @override
  void dispose() {
    _autoReturn?.cancel();
    super.dispose();
  }

  void _openResult() {
    _autoReturn?.cancel();
    if (!mounted) return;
    context.go('/warehouse/receipts/result/${widget.receiptId}');
  }

  String _two(int v) => v.toString().padLeft(2, '0');

  String _date(DateTime dt) => '${_two(dt.day)}/${_two(dt.month)}/${dt.year}';

  String _dateTime(DateTime dt, {bool seconds = false}) =>
      '${_date(dt)} · ${_two(dt.hour)}:${_two(dt.minute)}'
      '${seconds ? ':${_two(dt.second)}' : ''}';

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return BlocConsumer<ReceiptReconciliationCubit, ReceiptReconciliationState>(
      listenWhen: (prev, curr) => !prev.isTerminal && curr.isTerminal,
      listener: (context, state) {
        _autoReturn?.cancel();
        _autoReturn = Timer(widget.autoReturnDelay, _openResult);
      },
      builder: (context, state) {
        final cubit = context.read<ReceiptReconciliationCubit>();
        final doc = state.document;

        Widget? footer;
        if (state.status == ReconciliationStatus.ready && doc != null) {
          footer = state.isTerminal
              ? VButton(
                  label: 'Xem kết quả',
                  fullWidth: true,
                  size: VButtonSize.large,
                  onPressed: _openResult,
                )
              : VButton(
                  label: 'Làm mới',
                  variant: VButtonVariant.secondary,
                  fullWidth: true,
                  size: VButtonSize.large,
                  isLoading: state.isRefreshing,
                  enabled: !state.isRefreshing,
                  onPressed: () => cubit.check(widget.receiptId),
                );
        } else if (state.status == ReconciliationStatus.empty) {
          footer = VButton(
            label: 'Làm mới',
            variant: VButtonVariant.secondary,
            fullWidth: true,
            size: VButtonSize.large,
            onPressed: () => cubit.check(widget.receiptId),
          );
        }

        return Scaffold(
          backgroundColor: colors.surfaceAlt,
          appBar: const VAppBar(
            title: 'Đối soát nhận hàng',
            subtitle: 'Tự mở khi kết quả lần nhận chưa xác định',
            showBackButton: true,
          ),
          body: switch (state.status) {
            ReconciliationStatus.loading => const Center(child: VLoading()),
            ReconciliationStatus.permissionDenied => const InventoryPermissionDenied(),
            ReconciliationStatus.empty => const Center(
              child: Padding(
                padding: EdgeInsets.all(VSpacing.space6),
                child: VEmptyState(
                  child: VEmptyHeader(
                    children: [
                      VEmptyMedia(icon: VIcons.clock),
                      VEmptyTitle('Chưa có kết quả mới'),
                      VEmptyDescription(
                        'Hệ thống vẫn đang theo dõi lần nhận này. Bạn không cần tạo lại thao tác.',
                      ),
                    ],
                  ),
                ),
              ),
            ),
            ReconciliationStatus.ready => _content(context, state),
          },
          bottomNavigationBar: footer == null
              ? null
              : SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(VSpacing.space4),
                    child: footer,
                  ),
                ),
        );
      },
    );
  }

  Widget _content(BuildContext context, ReceiptReconciliationState state) {
    final colors = context.vColors;
    final doc = state.document!;
    final checkedAt = state.checkedAt;
    final stale =
        checkedAt != null && widget.clock().difference(checkedAt) > const Duration(minutes: 1);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(VSpacing.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (state.isTerminal) ...[
            const VBanner(
              status: VBannerStatus.success,
              title: 'Đã xác lập kết quả',
              description: 'Kết quả cuối cùng đã có; hệ thống sẽ đưa bạn về màn kết quả.',
            ),
          ] else ...[
            VText(
              'Đang xác minh kết quả nhận hàng',
              style: VTypography.headingH4.copyWith(
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),
            const VGap(VSpacing.space1),
            VText(
              'Chưa cần thực hiện lại lần nhận.',
              style: VTypography.bodySmall.copyWith(color: colors.textSecondary),
            ),
            if (checkedAt != null) ...[
              const VGap.cozy(),
              VText(
                'Lần kiểm tra gần nhất',
                style: VTypography.caption.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colors.textSecondary,
                ),
              ),
              VText(
                _dateTime(checkedAt, seconds: true),
                style: VTypography.bodyDefault,
              ),
            ],
            if (stale) ...[
              const VGap.cozy(),
              const InventoryNoticeBanner(InventoryNotice.stale),
            ],
          ],
          const VGap(VSpacing.space4),
          VCard(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: VSpacing.space4),
              child: Column(children: _timeline(doc)),
            ),
          ),
        ],
      ),
    );
  }

  /// Chỉ sự kiện đã có bằng chứng (SCR-013 §4); không hiện mã kỹ thuật ngoài mã lần nhận.
  List<Widget> _timeline(ReceiptDocumentModel doc) {
    final settled =
        doc.status == ReceiptStatus.completed || doc.status == ReceiptStatus.executionRejected;
    final pending =
        doc.status == ReceiptStatus.processing || doc.status == ReceiptStatus.executionUnknown;
    final stockLines = doc.items.where((i) => i.totalPhysicalStock > 0).length;

    final events = <_TimelineEvent>[
      _TimelineEvent(
        'Hồ sơ nhận đã được khóa',
        doc.id,
        '${_dateTime(doc.submittedAt)} · ${doc.submittedByName}',
      ),
      if (doc.decidedAt != null)
        _TimelineEvent(
          'Yêu cầu đã được duyệt',
          'Người duyệt: ${doc.decidedByName ?? '--'}',
          _dateTime(doc.decidedAt!),
        ),
      if (settled)
        _TimelineEvent(
          'Kết quả ghi nhận đã được xác lập',
          'Kết quả của lần nhận hiện tại',
          doc.executedAt != null ? _dateTime(doc.executedAt!) : '',
        ),
      if (pending)
        const _TimelineEvent(
          'Đang xác lập kết quả cuối cùng',
          'Kết quả của lần nhận hiện tại',
          'Đang tiếp tục kiểm tra',
        ),
      if (doc.status == ReceiptStatus.completed)
        _TimelineEvent(
          'Biến động tồn kho đã được ghi',
          '$stockLines dòng hàng',
          doc.executedAt != null ? _dateTime(doc.executedAt!) : '',
        ),
      if (pending)
        const _TimelineEvent(
          'Đang kiểm tra biến động tồn kho',
          'Chưa có bằng chứng xác nhận biến động tồn kho đã được ghi',
          'Không cần tạo lần nhận mới',
        ),
    ];

    return [
      for (var i = 0; i < events.length; i++) ...[
        if (i > 0) const VDivider(),
        _TimelineRow(event: events[i]),
      ],
    ];
  }
}

class _TimelineEvent {
  const _TimelineEvent(this.title, this.subtitle, this.time);

  final String title;
  final String subtitle;
  final String time;
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.event});

  final _TimelineEvent event;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: VSpacing.space3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          VText(
            event.title,
            style: VTypography.labelDefault.copyWith(fontWeight: FontWeight.w700),
          ),
          const VGap(VSpacing.space1),
          VText(
            event.subtitle,
            style: VTypography.caption.copyWith(color: colors.textSecondary),
          ),
          if (event.time.isNotEmpty) ...[
            const VGap(VSpacing.space1),
            VText(
              event.time,
              style: VTypography.caption.copyWith(color: colors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}
