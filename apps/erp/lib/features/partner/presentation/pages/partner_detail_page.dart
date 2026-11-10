import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:erp/features/partner/data/models/partner_models.dart';
import 'package:erp/features/partner/data/partner_repository.dart';
import 'package:erp/features/partner/presentation.dart';

import '../widgets/partner_detail_add_contact_flow.dart';
import '../widgets/partner_detail_soft_delete_flow.dart';

class PartnerDetailPage extends StatefulWidget {
  const PartnerDetailPage({
    super.key,
    required this.partnerId,
    required this.repository,
    this.showCreateSuccessToast = false,
    this.showTransformSuccessToast = false,
    this.onMutated,
    this.supplierSection,
  });

  final String partnerId;
  final PartnerRepository repository;
  final bool showCreateSuccessToast;
  final bool showTransformSuccessToast;

  /// Gọi sau mỗi thao tác đổi dữ liệu đang hiện ở danh sách (sửa, chuyển đổi,
  /// ngừng / kích hoạt, xoá). Ở web 2 cột, route dùng nó để tải lại danh sách.
  final VoidCallback? onMutated;

  /// Khối bổ sung cho nhà cung cấp (Kho gắn "Chương trình ưu đãi" qua router; Theme 3
  /// không import Kho). Chỉ dựng khi hồ sơ có vai trò nhà cung cấp và không phải đối tác
  /// hệ thống.
  final Widget Function(BuildContext context, PartnerDetailDto dto)? supplierSection;

  @override
  State<PartnerDetailPage> createState() => _PartnerDetailPageState();
}

class _PartnerDetailPageState extends State<PartnerDetailPage> {
  late final PartnerDetailCubit _cubit;
  late final PartnerStatusCubit _statusCubit;

  @override
  void initState() {
    super.initState();
    _cubit = PartnerDetailCubit(
      repository: widget.repository,
    )..loadDetail(widget.partnerId);
    _statusCubit = PartnerStatusCubit(
      repository: widget.repository,
    );

    if (widget.showCreateSuccessToast || widget.showTransformSuccessToast) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (widget.showTransformSuccessToast) {
          showPartnerTransformSuccessToast(context);
        } else {
          showPartnerCreateSuccessToast(context);
        }
      });
    }
  }

  @override
  void dispose() {
    _cubit.close();
    _statusCubit.close();
    super.dispose();
  }

  /// Nút "Quay lại" của trạng thái lỗi: web 2 cột về `/partner` (ô phải trống).
  void _goBackToList() {
    if (VListDetailLayout.isSplitOf(context)) {
      context.go('/partner');
    } else {
      context.pop();
    }
  }

  Future<void> _openEdit(String partnerId) async {
    final updated = await context.push<bool>('/partner/$partnerId/edit');
    if (updated != true || !mounted) return;
    widget.onMutated?.call();
    await _cubit.loadDetail(widget.partnerId);
    if (!mounted) return;
    showPartnerUpdateSuccessToast(context);
  }

  Future<void> _openContacts(String partnerId) async {
    await context.push('/partner/$partnerId/contacts');
    if (!mounted) return;
    widget.onMutated?.call();
    await _cubit.loadDetail(widget.partnerId);
  }

  Future<void> _showActionSheet(
    BuildContext pageContext,
    PartnerDetailDto dto,
  ) async {
    final action = await showPartnerDetailActionSheet(
      pageContext,
      dto: dto,
    );
    if (action == null || !pageContext.mounted) return;
    await _handleAction(pageContext, dto, action);
  }

  void _showAddMethodSheet(
    BuildContext context, {
    List<String> excludePersonPartnerIds = const [],
  }) {
    runPartnerDetailAddContactFlow(
      context: context,
      partnerId: widget.partnerId,
      repository: widget.repository,
      excludePersonPartnerIds: excludePersonPartnerIds,
      onReload: () {
        widget.onMutated?.call();
        return _cubit.loadDetail(widget.partnerId);
      },
    );
  }

  Future<void> _handleAction(
    BuildContext context,
    PartnerDetailDto dto,
    PartnerDetailAction action,
  ) async {
    switch (action) {
      case PartnerDetailAction.transform:
        await _handleTransform(context, dto);
      case PartnerDetailAction.toggleStatus:
        if (dto.status == PartnerStatus.active) {
          final reason = await showPartnerDeactivateConfirmationSheet(
            context,
            primaryContactOrganizationName: dto.primaryContactOrganizationName,
          );
          if (reason == null || !mounted) return;
          await _statusCubit.deactivate(
            partnerId: dto.partnerId,
            expectedVersion: dto.expectedVersion,
            reason: reason.isEmpty ? null : reason,
          );
        } else {
          final confirmed = await showPartnerReactivateConfirmationSheet(context);
          if (confirmed != true || !mounted) return;
          await _statusCubit.reactivate(
            partnerId: dto.partnerId,
            expectedVersion: dto.expectedVersion,
          );
        }
      case PartnerDetailAction.delete:
        if (await _handlePrimaryContactDeleteBlock(context, dto)) {
          return;
        }
        if (!context.mounted) return;
        final deleteResult = await runPartnerDetailSoftDeleteFlow(
          context: context,
          repository: widget.repository,
          statusCubit: _statusCubit,
          dto: dto,
        );
        if (deleteResult == PartnerSoftDeleteFlowResult.openDeactivate && context.mounted) {
          final reason = await showPartnerDeactivateConfirmationSheet(
            context,
            primaryContactOrganizationName: dto.primaryContactOrganizationName,
          );
          if (reason == null || !mounted) return;
          await _statusCubit.deactivate(
            partnerId: dto.partnerId,
            expectedVersion: dto.expectedVersion,
            reason: reason.isEmpty ? null : reason,
          );
        }
    }
  }

  Future<void> _openTransform(
    BuildContext context,
    PartnerDetailDto dto,
  ) async {
    final transformed = await context.push<bool>(
      '/partner/${dto.partnerId}/transform',
      extra: dto,
    );
    if (transformed == true && context.mounted) {
      widget.onMutated?.call();
      await _cubit.loadDetail(dto.partnerId);
      if (!context.mounted) return;
      showPartnerTransformSuccessToast(context);
    }
  }

  Future<void> _handleTransform(
    BuildContext context,
    PartnerDetailDto dto,
  ) async {
    final organizationId = dto.primaryContactOrganizationId;
    if (organizationId == null) {
      await _openTransform(context, dto);
      return;
    }

    final action = await showPartnerTransformPrimaryContactBlockedSheet(
      context,
      organizationName: dto.primaryContactOrganizationName ?? 'một tổ chức',
    );
    if (!context.mounted ||
        action != PartnerTransformPrimaryContactBlockedAction.viewOrganization) {
      return;
    }
    await _openOrganization(context, organizationId);
  }

  /// Mở hồ sơ tổ chức: web 2 cột đổi cột phải (`go`), hẹp thì đẩy lên như cũ.
  Future<void> _openOrganization(BuildContext context, String organizationId) async {
    if (VListDetailLayout.isSplitOf(context)) {
      context.go('/partner/$organizationId');
      return;
    }
    await context.push('/partner/$organizationId');
  }

  Future<bool> _handlePrimaryContactDeleteBlock(
    BuildContext context,
    PartnerDetailDto dto,
  ) async {
    final organizationId = dto.primaryContactOrganizationId;
    if (organizationId == null) return false;

    final action = await showPartnerDeletePrimaryContactBlockedSheet(
      context,
      organizationName: dto.primaryContactOrganizationName ?? 'một tổ chức',
    );
    if (context.mounted && action == PartnerDeletePrimaryContactBlockedAction.viewOrganization) {
      await _openOrganization(context, organizationId);
    }
    return true;
  }

  void _onStatusSubmitChanged(
    BuildContext context,
    PartnerStatusSubmitState state,
  ) {
    if (state.status == PartnerStatusSubmitStatus.success) {
      if (state.successMessage == PartnerStatusCubit.softDeleteSuccessMessage) {
        _statusCubit.clearFeedback();
        // Hồ sơ nằm trong tab (4-W Q1) nên mở thẳng URL vẫn có danh sách bên dưới;
        // không còn ai chờ kết quả `pop(true)` để hiện toast. Hồ sơ tự báo toast +
        // tải lại danh sách rồi quay về.
        showPartnerSoftDeleteSuccessToast(context);
        widget.onMutated?.call();
        if (!VListDetailLayout.isSplitOf(context) && context.canPop()) {
          context.pop();
        } else {
          context.go('/partner');
        }
        return;
      }
      if (state.successMessage == PartnerStatusCubit.deactivateSuccessMessage) {
        showPartnerDeactivateSuccessToast(context);
      } else if (state.successMessage == PartnerStatusCubit.reactivateSuccessMessage) {
        showPartnerReactivateSuccessToast(context);
      }
      _statusCubit.clearFeedback();
      widget.onMutated?.call();
      _cubit.loadDetail(widget.partnerId);
      return;
    }
    if (state.status == PartnerStatusSubmitStatus.failure && state.generalError != null) {
      VToast.show(
        context,
        title: 'Không thành công',
        message: state.generalError!,
        type: VToastType.danger,
      );
      _statusCubit.clearFeedback();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _cubit),
        BlocProvider.value(value: _statusCubit),
      ],
      child: BlocListener<PartnerStatusCubit, PartnerStatusSubmitState>(
        listenWhen: (previous, current) => previous.status != current.status,
        listener: _onStatusSubmitChanged,
        child: VPageScaffold(
          key: const Key('wgt_e01_u04_fr01_01'),
          title: 'Hồ sơ KH & NCC',
          showBackButton: !VListDetailLayout.isSplitOf(context),
          body: BlocBuilder<PartnerDetailCubit, PartnerDetailState>(
            builder: (context, state) {
              if (state is PartnerDetailLoading || state is PartnerDetailInitial) {
                return const PartnerDetailLoadingSkeleton();
              }

              if (state is PartnerDetailError) {
                if (state.isNoPermission) {
                  return Center(
                    child: PartnerDetailErrorState(
                      icon: VIcons.lock,
                      title: 'Không có quyền xem hồ sơ',
                      description: 'Bạn không có quyền truy cập hồ sơ\nKhách hàng & Nhà cung cấp.',
                      actionLabel: 'Quay lại',
                      onActionPressed: _goBackToList,
                    ),
                  );
                }
                if (state.isNotFound) {
                  return Center(
                    child: PartnerDetailErrorState(
                      icon: VIcons.search,
                      title: state.isContactOnly
                          ? 'Không phải hồ sơ đối tác'
                          : 'Không tìm thấy hồ sơ',
                      description: state.isContactOnly
                          ? 'Người liên hệ chỉ quản lý trong hồ sơ tổ chức.\nKhông mở như hồ sơ cá nhân độc lập.'
                          : 'Hồ sơ có thể đã bị xóa hoặc không tồn tại\nhoặc bạn không có quyền xem.',
                      actionLabel: 'Quay lại',
                      onActionPressed: _goBackToList,
                    ),
                  );
                }
                return Center(
                  child: PartnerDetailErrorState(
                    icon: VIcons.cloudOff,
                    title: 'Không tải được hồ sơ',
                    description: 'Vui lòng kiểm tra kết nối internet hoặc thử lại sau.',
                    actionLabel: 'Thử lại',
                    onActionPressed: () => _cubit.loadDetail(widget.partnerId),
                  ),
                );
              }

              if (state is PartnerDetailLoaded) {
                final dto = state.dto;
                final isPerson = dto.partnerType == PartnerType.person;
                final phone = isPerson ? dto.personProfile?.phone : dto.organizationProfile?.phone;
                final taxCode = isPerson
                    ? dto.personProfile?.taxCode
                    : dto.organizationProfile?.taxCode;
                final missingRequired = isPerson
                    ? <String>[
                        if (dto.personProfile?.taxCode?.trim().isEmpty ?? true) 'MST',
                        if (dto.personProfile?.invoice?.invoiceAddress?.trim().isEmpty ?? true)
                          'địa chỉ hóa đơn',
                      ]
                    : <String>[
                        if (dto.organizationProfile?.taxCode?.trim().isEmpty ?? true) 'MST',
                        if (dto.organizationProfile?.invoice?.invoiceName?.trim().isEmpty ?? true)
                          'tên xuất hóa đơn',
                        if (dto.organizationProfile?.invoice?.invoiceAddress?.trim().isEmpty ??
                            true)
                          'địa chỉ hóa đơn',
                      ];
                final warningDescription = missingRequired.isEmpty
                    ? null
                    : 'Thiếu ${_joinWarningLabels(missingRequired)}. ';
                final List<String> contactParts = [];
                if (phone != null && phone.isNotEmpty) contactParts.add(phone);
                if (taxCode != null && taxCode.isNotEmpty) contactParts.add('MST $taxCode');
                final contactInfoText = contactParts.join('  •  ');

                return Column(
                  children: [
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () => _cubit.loadDetail(widget.partnerId),
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(VSpacing.space4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              PartnerDetailHeader(dto: dto),
                              const VGap.md(),

                              if (dto.status == PartnerStatus.inactive) ...[
                                const PartnerDetailInactiveBanner(),
                                const VGap.md(),
                              ],

                              if (contactInfoText.isNotEmpty) ...[
                                PartnerDetailContactQuickRow(text: contactInfoText),
                                const VGap.md(),
                              ],

                              if (dto.isSystem) ...[
                                const VBanner(
                                  status: VBannerStatus.info,
                                  title:
                                      'Đối tác hệ thống, dùng cho phiếu nhận mua lẻ. Không sửa hoặc xoá được.',
                                ),
                                const VGap.md(),
                              ] else if (warningDescription != null &&
                                  dto.status == PartnerStatus.active) ...[
                                PartnerDetailWarningBanner(
                                  description: warningDescription,
                                ),
                                const VGap.md(),
                              ],

                              PartnerDetailMainInfoCard(dto: dto),
                              const VGap.sm(),

                              if (!isPerson) ...[
                                PartnerDetailContactsCard(
                                  dto: dto,
                                  onTapAdd: () => _showAddMethodSheet(
                                    context,
                                    excludePersonPartnerIds: dto.contacts
                                        .map((c) => c.personPartnerId)
                                        .toList(),
                                  ),
                                  onTapViewAll: () => _openContacts(dto.partnerId),
                                ),
                                const VGap.sm(),
                              ],

                              PartnerDetailInvoiceCard(dto: dto),
                              const VGap.sm(),

                              PartnerDetailDeliveryCard(dto: dto),
                              const VGap.sm(),

                              PartnerDetailNoteCard(dto: dto),
                              const VGap.sm(),

                              if (widget.supplierSection != null &&
                                  !dto.isSystem &&
                                  dto.roles.contains(PartnerRoleType.supplier)) ...[
                                widget.supplierSection!(context, dto),
                                const VGap.sm(),
                              ],

                              PartnerDetailSystemCard(
                                dto: dto,
                                onTapHistory: () => context.push(
                                  '/partner/${dto.partnerId}/history',
                                  extra: dto.displayName,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    if (!dto.isSystem)
                    Container(
                      decoration: BoxDecoration(
                        color: colors.surface,
                        border: Border(top: BorderSide(color: colors.borderDefault)),
                      ),
                      child: SafeArea(
                        top: false,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(
                            VSpacing.space4,
                            VSpacing.space3,
                            VSpacing.space4,
                            VSpacing.space4,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: VButton(
                                  label: 'Chỉnh sửa',
                                  variant: VButtonVariant.secondary,
                                  foregroundColor: colors.success,
                                  onPressed:
                                      dto.availableActions.contains(
                                        PartnerAvailableAction.update,
                                      )
                                      ? () => _openEdit(dto.partnerId)
                                      : null,
                                ),
                              ),
                              const SizedBox(width: VSpacing.space3),
                              Expanded(
                                child: VButton(
                                  label: 'Thao tác',
                                  variant: VButtonVariant.primary,
                                  trailing: VIcons.expandLess,
                                  onPressed: () => _showActionSheet(context, dto),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }

              return const SizedBox();
            },
          ),
        ),
      ),
    );
  }
}

String _joinWarningLabels(List<String> labels) {
  if (labels.length == 1) return labels.single;
  if (labels.length == 2) return '${labels[0]} và ${labels[1]}';
  final head = labels.sublist(0, labels.length - 1).join(', ');
  return '$head và ${labels.last}';
}
