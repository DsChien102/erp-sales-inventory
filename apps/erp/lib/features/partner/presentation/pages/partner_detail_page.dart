import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_partner_application/application.dart';
import 'package:vet45_partner_domain/domain.dart';
import 'package:vet45_partner_presentation/presentation.dart';
import 'package:vet45_shared_application/application.dart';

import '../widgets/partner_detail_add_contact_flow.dart';
import '../widgets/partner_detail_soft_delete_flow.dart';

class PartnerDetailPage extends StatefulWidget {
  const PartnerDetailPage({
    super.key,
    required this.partnerId,
    required this.partnerModule,
    required this.executionContext,
    this.showCreateSuccessToast = false,
    this.showTransformSuccessToast = false,
  });

  final String partnerId;
  final IPartnerModule partnerModule;
  final IExecutionContext executionContext;
  final bool showCreateSuccessToast;
  final bool showTransformSuccessToast;

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
      partnerModule: widget.partnerModule,
      executionContext: widget.executionContext,
    )..loadDetail(widget.partnerId);
    _statusCubit = PartnerStatusCubit(
      partnerModule: widget.partnerModule,
      executionContext: widget.executionContext,
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

  Future<void> _openEdit(String partnerId) async {
    final updated = await context.push<bool>('/partner/$partnerId/edit');
    if (updated != true || !mounted) return;
    await _cubit.loadDetail(widget.partnerId);
    if (!mounted) return;
    showPartnerUpdateSuccessToast(context);
  }

  Future<void> _openContacts(String partnerId) async {
    await context.push('/partner/$partnerId/contacts');
    if (!mounted) return;
    await _cubit.loadDetail(widget.partnerId);
  }

  Future<void> _showActionSheet(
    BuildContext pageContext,
    PartnerDetailDto dto,
  ) async {
    final action = await showModalBottomSheet<PartnerDetailAction>(
      context: pageContext,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => PartnerDetailActionSheet(dto: dto),
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
      partnerModule: widget.partnerModule,
      executionContext: widget.executionContext,
      excludePersonPartnerIds: excludePersonPartnerIds,
      onReload: () => _cubit.loadDetail(widget.partnerId),
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
          partnerModule: widget.partnerModule,
          executionContext: widget.executionContext,
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

    final action = await showModalBottomSheet<PartnerTransformPrimaryContactBlockedAction>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => PartnerTransformPrimaryContactBlockedSheet(
        organizationName: dto.primaryContactOrganizationName ?? 'một tổ chức',
      ),
    );
    if (!context.mounted ||
        action != PartnerTransformPrimaryContactBlockedAction.viewOrganization) {
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

    final action = await showModalBottomSheet<PartnerDeletePrimaryContactBlockedAction>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => PartnerDeletePrimaryContactBlockedSheet(
        organizationName: dto.primaryContactOrganizationName ?? 'một tổ chức',
      ),
    );
    if (context.mounted && action == PartnerDeletePrimaryContactBlockedAction.viewOrganization) {
      await context.push('/partner/$organizationId');
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
        if (context.canPop()) {
          context.pop(true);
        } else {
          showPartnerSoftDeleteSuccessToast(context);
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
        child: Scaffold(
          key: const Key('wgt_e01_u04_fr01_01'),
          backgroundColor: colors.surface,
          appBar: const VAppBar(
            title: 'Hồ sơ KH & NCC',
            showBackButton: true,
          ),
          body: BlocBuilder<PartnerDetailCubit, PartnerDetailState>(
            builder: (context, state) {
              if (state is PartnerDetailLoading || state is PartnerDetailInitial) {
                return const PartnerDetailLoadingSkeleton();
              }

              if (state is PartnerDetailError) {
                if (state.isNoPermission) {
                  return Center(
                    child: PartnerDetailErrorState(
                      iconData: Icons.lock_outline_rounded,
                      title: 'Không có quyền xem hồ sơ',
                      description: 'Bạn không có quyền truy cập hồ sơ\nKhách hàng & Nhà cung cấp.',
                      actionLabel: 'Quay lại',
                      onActionPressed: () => context.pop(),
                    ),
                  );
                }
                if (state.isNotFound) {
                  return Center(
                    child: PartnerDetailErrorState(
                      iconData: Icons.search_off_rounded,
                      title: 'Không tìm thấy hồ sơ',
                      description:
                          'Hồ sơ có thể đã bị xóa hoặc không tồn tại\nhoặc bạn không có quyền xem.',
                      actionLabel: 'Quay lại',
                      onActionPressed: () => context.pop(),
                    ),
                  );
                }
                return Center(
                  child: PartnerDetailErrorState(
                    iconData: Icons.cloud_off_rounded,
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
                final hasWarning = isPerson
                    ? (dto.personProfile?.taxCode == null || dto.personProfile?.invoice == null)
                    : (dto.organizationProfile?.taxCode == null ||
                          dto.organizationProfile?.invoice == null);

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
                              const SizedBox(height: VSpacing.space4),

                              if (dto.status == PartnerStatus.inactive) ...[
                                const PartnerDetailInactiveBanner(),
                                const SizedBox(height: VSpacing.space4),
                              ],

                              if (contactInfoText.isNotEmpty) ...[
                                PartnerDetailContactQuickRow(text: contactInfoText),
                                const SizedBox(height: VSpacing.space4),
                              ],

                              if (hasWarning && dto.status == PartnerStatus.active) ...[
                                const PartnerDetailWarningBanner(),
                                const SizedBox(height: VSpacing.space4),
                              ],

                              PartnerDetailMainInfoCard(dto: dto),
                              const SizedBox(height: VSpacing.space2),

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
                                const SizedBox(height: VSpacing.space2),
                              ],

                              PartnerDetailInvoiceCard(dto: dto),
                              const SizedBox(height: VSpacing.space2),

                              PartnerDetailDeliveryCard(dto: dto),
                              const SizedBox(height: VSpacing.space2),

                              PartnerDetailNoteCard(dto: dto),
                              const SizedBox(height: VSpacing.space2),

                              const PartnerDetailHistoryCard(),
                              const SizedBox(height: VSpacing.space2),

                              PartnerDetailSystemCard(dto: dto),
                            ],
                          ),
                        ),
                      ),
                    ),

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
                                  variant: VButtonVariant.outline,
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
                                  trailingIcon: const Icon(
                                    Icons.expand_less,
                                    size: 20,
                                    color: Colors.white,
                                  ),
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
