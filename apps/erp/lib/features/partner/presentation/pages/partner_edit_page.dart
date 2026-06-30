import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';

import '../../mock_partner_data.dart';
import '../bloc/partner_edit_cubit.dart';
import '../bloc/partner_edit_state.dart';
import '../widgets/partner_form_sections.dart';
import '../widgets/partner_role_type_section.dart';
import '../widgets/partner_cancel_confirm_dialog.dart';
import '../widgets/partner_duplicate_warning_dialog.dart';

class PartnerEditPage extends StatelessWidget {
  final String partnerId;
  
  const PartnerEditPage({
    super.key,
    required this.partnerId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PartnerEditCubit(MockPartnerRepository())..loadPartner(partnerId),
      child: const _PartnerEditView(),
    );
  }
}

class _PartnerEditView extends StatelessWidget {
  const _PartnerEditView();

  @override
  Widget build(BuildContext context) {
    final dynamicColors = context.vColors;

    return BlocConsumer<PartnerEditCubit, PartnerEditState>(
      listenWhen: (previous, current) => previous.status != current.status || previous.errorMessage != current.errorMessage,
      listener: (context, state) {
        if (state.status == PartnerEditStatus.error && state.errorMessage != null) {
          VToast.show(context, title: 'Lỗi', message: state.errorMessage!, type: VToastType.danger);
        } else if (state.status == PartnerEditStatus.loadingDataError && state.errorMessage != null) {
          VToast.show(context, title: 'Lỗi tải dữ liệu', message: state.errorMessage!, type: VToastType.danger);
        } else if (state.status == PartnerEditStatus.duplicateWarning) {
          _showDuplicateWarningDialog(context, state.duplicateWarnings);
        } else if (state.status == PartnerEditStatus.success) {
          VToast.show(context, title: 'Thành công', message: 'Đã cập nhật KH & NCC thành công!', type: VToastType.success);
          context.pop(); // quay lại trang trước
        }
      },
      builder: (context, state) {
        final isLoadingData = state.status == PartnerEditStatus.initial || state.status == PartnerEditStatus.loadingData;

        return Scaffold(
          backgroundColor: dynamicColors.background,
          appBar: VAppBar(
            title: 'Chỉnh sửa KH & NCC',
            actions: [
              TextButton(
                onPressed: state.status == PartnerEditStatus.saving || isLoadingData ? null : () => _handleCancel(context, state),
                child: Text(
                  'Hủy',
                  style: VTypography.bodyDefault.copyWith(
                    color: state.status == PartnerEditStatus.saving || isLoadingData ? dynamicColors.textMuted : dynamicColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: VSpacing.space2),
            ],
          ),
          body: isLoadingData
              ? const Center(child: CircularProgressIndicator())
              : state.status == PartnerEditStatus.loadingDataError
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, size: 48, color: VColors.danger),
                          const SizedBox(height: 16),
                          Text('Không thể tải dữ liệu', style: VTypography.headingH4),
                          const SizedBox(height: 16),
                          VButton(
                            variant: VButtonVariant.outline,
                            onPressed: () => context.read<PartnerEditCubit>().loadPartner(state.partnerId),
                            label: 'Tải lại',
                          ),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(VSpacing.space4),
                            child: Column(
                              children: [
                                VCard(
                                  child: PartnerRoleTypeSection(
                                    role: state.role,
                                    onRoleChanged: (v) => context.read<PartnerEditCubit>().updateRole(v),
                                    profileType: state.profileType,
                                    onProfileTypeChanged: (v) => context.read<PartnerEditCubit>().updateProfileType(v),
                                    onNameChanged: (v) => context.read<PartnerEditCubit>().updateName(v),
                                  ),
                                ),
                                const SizedBox(height: VSpacing.space4),
                                VCard(
                                  child: PartnerContactInfoSection(
                                    phone: state.phone,
                                    onPhoneChanged: (v) => context.read<PartnerEditCubit>().updatePhone(v),
                                    email: state.email,
                                    onEmailChanged: (v) => context.read<PartnerEditCubit>().updateEmail(v),
                                    address: state.address,
                                    onAddressChanged: (v) => context.read<PartnerEditCubit>().updateAddress(v),
                                  ),
                                ),
                                const SizedBox(height: VSpacing.space4),
                                VCard(
                                  child: PartnerTaxInfoSection(
                                    taxId: state.taxId,
                                    onTaxIdChanged: (v) => context.read<PartnerEditCubit>().updateTaxId(v),
                                  ),
                                ),
                                const SizedBox(height: VSpacing.space4),
                                VCard(
                                  child: PartnerNoteSection(
                                    note: state.note,
                                    onNoteChanged: (v) => context.read<PartnerEditCubit>().updateNote(v),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(VSpacing.space4),
                          decoration: BoxDecoration(
                            color: dynamicColors.surface,
                            boxShadow: VShadows.e2,
                          ),
                          child: SafeArea(
                            top: false,
                            child: VButton(
                              onPressed: state.status == PartnerEditStatus.saving || !state.hasChanges 
                                  ? null 
                                  : () => context.read<PartnerEditCubit>().submit(),
                              isLoading: state.status == PartnerEditStatus.saving,
                              fullWidth: true,
                              label: 'Lưu thay đổi',
                            ),
                          ),
                        ),
                      ],
                    ),
        );
      },
    );
  }

  void _handleCancel(BuildContext context, PartnerEditState state) {
    if (state.hasChanges) {
      showDialog(
        context: context,
        builder: (dialogContext) => const PartnerCancelConfirmDialog(),
      );
    } else {
      context.pop();
    }
  }

  void _showDuplicateWarningDialog(BuildContext context, List<String> warnings) {
    final cubit = context.read<PartnerEditCubit>();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => PartnerDuplicateWarningDialog(
        warnings: warnings,
        onCancel: () => cubit.cancelSubmit(),
        onConfirm: () => cubit.confirmSubmit(),
      ),
    );
  }
}
