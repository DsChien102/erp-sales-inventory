import 'package:erp/core/di/injection.dart';
import 'package:erp/features/inventory/data/core/inventory_error_codes.dart';
import 'package:erp/features/inventory/data/stock_policy/stock_policy_repository.dart';
import 'package:erp/features/inventory/logic/stock_policy/stock_policy_cubit.dart';
import 'package:erp/features/inventory/logic/stock_policy/stock_policy_state.dart';
import 'package:erp/features/inventory/presentation/patterns/inventory_footer.dart';
import 'package:erp/features/inventory/presentation/patterns/inventory_layout.dart';
import 'package:erp/features/inventory/presentation/patterns/inventory_states.dart';
import 'package:erp/features/inventory/presentation/stock_policy/near_expiry_tab.dart';
import 'package:erp/features/inventory/presentation/stock_policy/stock_threshold_tab.dart';
import 'package:erp/features/inventory/presentation/stock_policy/threshold_impact_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';

class StockPolicyPage extends StatelessWidget {
  final String? initialTab;

  const StockPolicyPage({super.key, this.initialTab});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => StockPolicyCubit(
        repository: getIt<StockPolicyRepository>(),
      )..load(),
      child: _StockPolicyView(initialTab: initialTab),
    );
  }
}

class _StockPolicyView extends StatefulWidget {
  final String? initialTab;

  const _StockPolicyView({this.initialTab});

  @override
  State<_StockPolicyView> createState() => _StockPolicyViewState();
}

class _StockPolicyViewState extends State<_StockPolicyView> {
  late int _selectedTab;

  @override
  void initState() {
    super.initState();
    _selectedTab = (widget.initialTab == 'expiry') ? 1 : 0;
  }

  void _leave(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      context.go('/warehouse');
    }
  }

  void _confirmLeave(BuildContext context, VoidCallback onLeave) {
    final cubit = context.read<StockPolicyCubit>();
    if (cubit.state.hasUnsavedChanges) {
      showVConfirmDialog(
        context: context,
        title: 'Bỏ thay đổi chưa lưu?',
        message: 'Các giá trị vừa sửa sẽ không được lưu.',
        cancelLabel: 'Ở lại',
        actionLabel: 'Bỏ thay đổi',
        isDestructive: true,
        onAction: onLeave,
      );
    } else {
      onLeave();
    }
  }

  Widget? _buildBottomBar(
    BuildContext context,
    StockPolicyCubit cubit,
    StockPolicyState state,
    bool isWide,
  ) {
    if (state.readOnly ||
        state.status == StockPolicyStatus.loading ||
        state.status == StockPolicyStatus.denied ||
        state.status == StockPolicyStatus.loadError) {
      return null;
    }

    Widget? footer;
    if (_selectedTab == 0) {
      if (!isWide) return null;
      footer = InventoryFooter(
        actions: [
          InventoryFooterAction(
            label: 'Huỷ thay đổi',
            onPressed: state.dirtyProductIds.isEmpty
                ? null
                : () => cubit.discardThresholds(),
          ),
          InventoryFooterAction(
            label: 'Lưu thay đổi (${state.dirtyProductIds.length})',
            primary: true,
            onPressed: (state.dirtyProductIds.isEmpty || state.hasThresholdError)
                ? null
                : () => ThresholdImpactSheet.show(context, cubit),
          ),
        ],
      );
    } else {
      footer = InventoryFooter(
        actions: [
          InventoryFooterAction(
            label: 'Lưu thay đổi',
            primary: true,
            onPressed: (!state.expiryDirty || state.expiryHasError)
                ? null
                : () => cubit.saveNearExpiry(),
          ),
        ],
      );
    }

    final colors = context.vColors;
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.borderDefault)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: VSpacing.space4,
            vertical: VSpacing.space3,
          ),
          child: Center(
            heightFactor: 1.0,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isWide ? 1024 : double.infinity,
              ),
              child: footer,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<StockPolicyCubit>();
    final state = cubit.state;
    final isWide = inventoryIsWide(context);

    return PopScope(
      canPop: !state.hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _confirmLeave(context, () => _leave(context));
      },
      child: Scaffold(
        appBar: VAppBar(
          title: 'Chính sách tồn & cận hạn',
          showBackButton: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              _confirmLeave(context, () => _leave(context));
            },
          ),
        ),
        bottomNavigationBar: _buildBottomBar(context, cubit, state, isWide),
        body: BlocListener<StockPolicyCubit, StockPolicyState>(
          listenWhen: (previous, current) =>
              previous.savedRevision != current.savedRevision &&
              current.savedRevision != null,
          listener: (context, state) {
            final rev = state.savedRevision;
            if (rev != null) {
              VToast.show(
                context,
                title: 'Đã lưu chính sách · Lần $rev',
                message: '',
                type: VToastType.success,
              );
              cubit.consumeSavedRevision();
            }
          },
          child: Builder(
            builder: (context) {
              if (state.status == StockPolicyStatus.loading) {
                return const Padding(
                  padding: EdgeInsets.all(VSpacing.space4),
                  child: InventoryLoading(
                    blocks: [
                      InventorySkeletonBlock.card,
                      InventorySkeletonBlock.row,
                      InventorySkeletonBlock.row,
                      InventorySkeletonBlock.row,
                    ],
                  ),
                );
              }

              if (state.status == StockPolicyStatus.denied) {
                return Center(
                  child: InventoryDenied(
                    what: 'xem hoặc thay đổi chính sách tồn',
                    next: 'Liên hệ chủ cửa hàng nếu cần.',
                    onExit: () => context.go('/warehouse'),
                  ),
                );
              }

              if (state.status == StockPolicyStatus.loadError) {
                return Center(
                  child: InventoryEmpty(
                    title: 'Không thể tải chính sách',
                    description: state.saveError?.userMessage() ??
                        'Đã có lỗi xảy ra khi tải dữ liệu.',
                    actionLabel: 'Thử lại',
                    onAction: () => cubit.load(),
                  ),
                );
              }

              final isWide = inventoryIsWide(context);

              return SingleChildScrollView(
                padding: const EdgeInsets.all(VSpacing.space4),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isWide ? 1024 : double.infinity,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!(state.snapshot?.isOwner ?? false)) ...[
                          const InventoryLocked(
                            title:
                                'Chỉ chủ cửa hàng thay đổi được chính sách.',
                            description: 'Bạn có thể xem các mức hiện tại.',
                          ),
                          const SizedBox(height: VSpacing.space3),
                        ],
                        if (state.status == StockPolicyStatus.conflict) ...[
                          InventoryStale(
                            title: 'Chính sách vừa được cập nhật',
                            description:
                                'Tải lại giá trị hiện hành trước khi lưu thay đổi.',
                            actionLabel: 'Tải lại',
                            onAction: () => cubit.reload(),
                          ),
                          const SizedBox(height: VSpacing.space3),
                        ],
                        if (state.saveError != null &&
                            state.status != StockPolicyStatus.conflict) ...[
                          VBanner(
                            tone: VComponentTone.danger,
                            title: 'Chưa lưu được chính sách',
                            description: inventoryErrorMessage(
                              state.saveError!,
                              fallback: 'Chưa lưu được chính sách.',
                            ),
                            footer: VButton(
                              label: 'Thử lại',
                              variant: VButtonVariant.secondary,
                              onPressed: () {
                                if (state.lastFailedSave != null) {
                                  cubit.retryLastSave();
                                } else if (_selectedTab == 0) {
                                  cubit.saveThresholds();
                                } else {
                                  cubit.saveNearExpiry();
                                }
                              },
                            ),
                          ),
                          const SizedBox(height: VSpacing.space3),
                        ],
                        VSegmentedControl(
                          segments: const ['Ngưỡng tồn', 'Cận hạn'],
                          selectedIndex: _selectedTab,
                          semanticLabel: 'Loại chính sách',
                          onChanged: (idx) {
                            setState(() => _selectedTab = idx);
                          },
                        ),
                        const SizedBox(height: VSpacing.space3),
                        if (_selectedTab == 0)
                          StockThresholdTab(cubit: cubit)
                        else
                          NearExpiryTab(cubit: cubit),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
