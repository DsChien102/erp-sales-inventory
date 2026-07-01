import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_partner_application/application.dart';
import 'package:vet45_partner_domain/domain.dart';
import 'package:vet45_partner_presentation/presentation.dart';
import 'package:vet45_shared_application/application.dart';

import '../../../../core/di/injection.dart';
import 'partner_edit_page.dart';

class PartnerDetailPage extends StatefulWidget {
  final String partnerId;
  final PartnerItemModel? initialPartner;
  final WidgetBuilder? editPageBuilder;
  final bool? canManageStatus;
  final bool? canDelete;

  const PartnerDetailPage({
    super.key,
    required this.partnerId,
    this.initialPartner,
    this.editPageBuilder,
    this.canManageStatus,
    this.canDelete,
  });

  @override
  State<PartnerDetailPage> createState() => _PartnerDetailPageState();
}

class _PartnerDetailPageState extends State<PartnerDetailPage> {
  int _selectedIndex = 0;
  bool _hasPartnerChanges = false;

  bool get _canManageStatus =>
      widget.canManageStatus ??
      getIt<IPrincipalSnapshot>().hasPermission(PartnerPermissions.manageStatus);

  bool get _canDelete =>
      widget.canDelete ??
      getIt<IPrincipalSnapshot>().hasPermission(PartnerPermissions.delete);

  bool get _canUpdate =>
      getIt<IPrincipalSnapshot>().hasPermission(PartnerPermissions.update);

  Future<void> _handleMenuAction(BuildContext context, String action) async {
    final cubit = context.read<PartnerDetailCubit>();

    if (action == 'delete') {
      if (!_canDelete) {
        VToast.show(
          context,
          title: 'Lỗi',
          message: 'Bạn không có quyền phù hợp.',
          type: VToastType.danger,
        );
        return;
      }
      final partner = cubit.state.partner;
      if (partner == null) {
        return;
      }
      
      if (!cubit.state.canDelete) {
        final deactivate = await CannotDeletePartnerDialog.show(context);
        if (deactivate && context.mounted) {
          await _handleMenuAction(context, 'deactivate');
        }
        return;
      }

      final confirmed = await DeletePartnerDialog.show(
        context,
        partnerName: partner.name,
      );
      if (!confirmed || !context.mounted) {
        return;
      }

      final success = await cubit.deletePartner();
      if (success) {
        _hasPartnerChanges = true;
      }
      return;
    }

    if (action == 'deactivate') {
      if (!_canManageStatus) {
        VToast.show(
          context,
          title: 'Lỗi',
          message: 'Bạn không có quyền phù hợp.',
          type: VToastType.danger,
        );
        return;
      }
      final partner = cubit.state.partner;
      if (partner == null) {
        return;
      }

      final confirmed = await DeactivatePartnerDialog.show(
        context,
        partner: partner,
      );
      if (!confirmed || !context.mounted) {
        return;
      }

      final success = await cubit.deactivatePartner();
      if (success) {
        _hasPartnerChanges = true;
      }
      return;
    }

    if (action == 'activate') {
      if (!_canManageStatus) {
        VToast.show(
          context,
          title: 'Lỗi',
          message: 'Bạn không có quyền phù hợp.',
          type: VToastType.danger,
        );
        return;
      }
      final partner = cubit.state.partner;
      if (partner == null) {
        return;
      }

      final confirmed = await ReactivatePartnerDialog.show(
        context,
        partner: partner,
      );
      if (!confirmed || !context.mounted) {
        return;
      }

      final success = await cubit.reactivatePartner();
      if (success) {
        _hasPartnerChanges = true;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dynamicColors = context.vColors;

    return BlocProvider(
      create: (_) => PartnerDetailCubit(
        partnerModule: getIt<IPartnerModule>(),
        executionContext: getIt<IExecutionContext>(),
        initialPartner: widget.initialPartner,
      )..load(widget.partnerId),
      child: BlocConsumer<PartnerDetailCubit, PartnerDetailState>(
        listenWhen: (previous, current) =>
            (previous.status != current.status &&
                current.status == PartnerDetailStatus.failure) ||
            previous.statusChangeMessage != current.statusChangeMessage ||
            previous.deleteMessage != current.deleteMessage ||
            previous.wasDeleted != current.wasDeleted,
        listener: (context, state) {
          if (state.wasDeleted) {
            VToast.show(
              context,
              title: 'Thành công',
              message: state.deleteMessage ?? 'Đã xóa hồ sơ đối tác.',
              type: VToastType.success,
            );
            Navigator.of(context).pop(true);
            return;
          }

          if (state.status == PartnerDetailStatus.failure &&
              state.errorMessage != null) {
            VToast.show(
              context,
              title: 'Lỗi',
              message: state.errorMessage!,
              type: VToastType.danger,
            );
            return;
          }

          final deleteMessage = state.deleteMessage;
          if (deleteMessage != null) {
            VToast.show(
              context,
              title: 'Lỗi',
              message: deleteMessage,
              type: VToastType.danger,
            );
            return;
          }

          final statusMessage = state.statusChangeMessage;
          if (statusMessage == null) {
            return;
          }

          final isSuccess = statusMessage.startsWith('Đã ');
          VToast.show(
            context,
            title: isSuccess ? 'Thành công' : 'Lỗi',
            message: statusMessage,
            type: isSuccess ? VToastType.success : VToastType.danger,
          );
        },
        builder: (context, state) {
          if (state.status == PartnerDetailStatus.failure && state.partner == null) {
            return Scaffold(
              backgroundColor: dynamicColors.background,
              appBar: const VAppBar(title: 'Chi tiết KH & NCC'),
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: VColors.danger,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Không thể tải dữ liệu',
                      style: VTypography.headingH4,
                    ),
                    const SizedBox(height: 16),
                    VButton(
                      variant: VButtonVariant.outline,
                      onPressed: () =>
                          context.read<PartnerDetailCubit>().load(widget.partnerId),
                      label: 'Tải lại',
                    ),
                  ],
                ),
              ),
            );
          }

          if (state.status == PartnerDetailStatus.loading && state.partner == null) {
            return Scaffold(
              backgroundColor: dynamicColors.background,
              appBar: const VAppBar(title: 'Chi tiết KH & NCC'),
              body: const Center(child: CircularProgressIndicator()),
            );
          }

          final partner = state.partner;
          if (partner == null) {
            return Scaffold(
              backgroundColor: dynamicColors.background,
              appBar: const VAppBar(title: 'Chi tiết KH & NCC'),
              body: const Center(child: CircularProgressIndicator()),
            );
          }

          return Scaffold(
            backgroundColor: dynamicColors.background,
            appBar: VAppBar(
              title: 'Chi tiết KH & NCC',
              leading: Navigator.of(context).canPop()
                  ? IconButton(
                      icon: Icon(
                        Icons.arrow_back,
                        color: dynamicColors.textPrimary,
                      ),
                      onPressed: () => _popWithRefreshResult(context),
                    )
                  : null,
              actions: [
                if (state.isChangingStatus || state.isDeletingPartner)
                  const Padding(
                    padding: EdgeInsets.only(right: VSpacing.space2),
                    child: Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
                PartnerDetailMenu(
                  partner: partner,
                  canManageStatus: _canManageStatus,
                  canDelete: _canDelete && state.canDelete,
                  onActionSelected: state.isChangingStatus || state.isDeletingPartner
                      ? null
                      : (action) => _handleMenuAction(context, action),
                ),
              ],
            ),
            body: Column(
              children: [
                PartnerDetailHeader(partner: partner),
                VTabs(
                  tabs: const ['Thông tin chung', 'Lịch sử giao dịch'],
                  selectedIndex: _selectedIndex,
                  onTabSelected: (index) {
                    setState(() {
                      _selectedIndex = index;
                    });
                  },
                ),
                Expanded(
                  child: IndexedStack(
                    index: _selectedIndex,
                    children: [
                      PartnerGeneralInfoTab(partner: partner),
                      const PartnerTransactionHistoryTab(),
                    ],
                  ),
                ),
              ],
            ),
            bottomNavigationBar: partner.status == 'Đã xóa' || !_canUpdate
                ? null
                : SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(VSpacing.space4),
                      child: VButton(
                        onPressed: () async {
                          if (!_canUpdate) {
                            VToast.show(
                              context,
                              title: 'Lỗi',
                              message: 'Bạn không có quyền phù hợp.',
                              type: VToastType.danger,
                            );
                            return;
                          }
                          final updated = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                              builder:
                                  widget.editPageBuilder ??
                                  (_) => PartnerEditPage(
                                    partnerId: partner.id,
                                    initialPartner: partner,
                                  ),
                            ),
                          );
                          if (updated == true && context.mounted) {
                            _hasPartnerChanges = true;
                            await context.read<PartnerDetailCubit>().load(widget.partnerId);
                          }
                        },
                        label: 'Chỉnh sửa',
                        leadingIcon: const Icon(
                          Icons.edit_outlined,
                          size: 20,
                          color: Colors.white,
                        ),
                        variant: VButtonVariant.primary,
                      ),
                    ),
                  ),
          );
        },
      ),
    );
  }

  void _popWithRefreshResult(BuildContext context) {
    Navigator.of(context).pop(_hasPartnerChanges ? true : null);
  }
}
