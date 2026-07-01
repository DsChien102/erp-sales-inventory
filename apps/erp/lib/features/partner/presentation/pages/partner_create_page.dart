import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_partner_application/application.dart';
import 'package:vet45_partner_presentation/presentation.dart';
import 'package:vet45_shared_application/application.dart';

import '../../../../core/di/injection.dart';

class PartnerCreatePage extends StatelessWidget {
  const PartnerCreatePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PartnerCreateCubit(
        partnerModule: getIt<IPartnerModule>(),
        executionContext: getIt<IExecutionContext>(),
      ),
      child: const _PartnerCreateView(),
    );
  }
}

class _PartnerCreateView extends StatelessWidget {
  const _PartnerCreateView();

  @override
  Widget build(BuildContext context) {
    final dynamicColors = context.vColors;

    return BlocConsumer<PartnerCreateCubit, PartnerCreateState>(
      listenWhen: (previous, current) =>
          previous.status != current.status || previous.errorMessage != current.errorMessage,
      listener: (context, state) {
        if (state.status == PartnerCreateStatus.error && state.errorMessage != null) {
          VToast.show(
            context,
            title: 'Lỗi',
            message: state.errorMessage!,
            type: VToastType.danger,
          );
        } else if (state.status == PartnerCreateStatus.duplicateWarning) {
          _showDuplicateWarningBottomSheet(context, state.duplicateWarnings);
        } else if (state.status == PartnerCreateStatus.success) {
          VToast.show(
            context,
            title: 'Thành công',
            message: 'Đã lưu KH & NCC thành công!',
            type: VToastType.success,
          );
          if (state.createdPartnerId != null) {
            final model = PartnerItemModel(
              id: state.createdPartnerId!,
              avatarText: state.name.isNotEmpty ? state.name[0].toUpperCase() : '?',
              name: state.name,
              role: state.role,
              status: 'Đang hoạt động',
              phone: state.phone,
              email: state.email,
              taxId: state.taxId,
              updatedAt: 'Vừa xong',
              address: state.address,
              note: state.note,
              profileType: state.profileType,
              creator: 'Bạn',
              createdAt: 'Vừa xong',
              updatedBy: 'Bạn',
            );
            context.pushReplacement('/partner/detail', extra: model);
          } else {
            context.pop(true);
          }
        }
      },
      builder: (context, state) {
        return PopScope(
          canPop: !state.isDirty,
          onPopInvoked: (didPop) async {
            if (didPop) return;
            _handleCancel(context, state);
          },
          child: Scaffold(
            backgroundColor: dynamicColors.background,
            appBar: VAppBar(
              title: 'Thêm KH & NCC',
              leading: IconButton(
                icon: Icon(
                  Icons.arrow_back,
                  color: dynamicColors.textPrimary,
                ),
                onPressed: () => _handleCancel(context, state),
              ),
              actions: [
                TextButton(
                  onPressed: state.status == PartnerCreateStatus.loading
                      ? null
                      : () => _handleCancel(context, state),
                  child: Text(
                    'Hủy',
                    style: VTypography.bodyDefault.copyWith(
                      color: state.status == PartnerCreateStatus.loading
                          ? dynamicColors.textMuted
                          : dynamicColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: VSpacing.space2),
              ],
            ),
            body: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(VSpacing.space4),
                    child: Column(
                      children: [
                        VCard(
                          child: PartnerRoleTypeSection(
                            role: state.role,
                            onRoleChanged: (v) => context.read<PartnerCreateCubit>().updateRole(v),
                            profileType: state.profileType,
                            onProfileTypeChanged: (v) =>
                                context.read<PartnerCreateCubit>().updateProfileType(v),
                            name: state.name,
                            onNameChanged: (v) => context.read<PartnerCreateCubit>().updateName(v),
                            contactName: state.contactName,
                            onContactNameChanged: (v) =>
                                context.read<PartnerCreateCubit>().updateContactName(v),
                            showValidationErrors: state.showValidationErrors,
                          ),
                        ),
                        const SizedBox(height: VSpacing.space4),
                        VCard(
                          child: PartnerContactInfoSection(
                            phone: state.phone,
                            onPhoneChanged: (v) =>
                                context.read<PartnerCreateCubit>().updatePhone(v),
                            email: state.email,
                            onEmailChanged: (v) =>
                                context.read<PartnerCreateCubit>().updateEmail(v),
                            address: state.address,
                            onAddressChanged: (v) =>
                                context.read<PartnerCreateCubit>().updateAddress(v),
                            showValidationErrors: state.showValidationErrors,
                          ),
                        ),
                        const SizedBox(height: VSpacing.space4),
                        VCard(
                          child: PartnerTaxInfoSection(
                            taxId: state.taxId,
                            onTaxIdChanged: (v) =>
                                context.read<PartnerCreateCubit>().updateTaxId(v),
                            profileType: state.profileType,
                            showValidationErrors: state.showValidationErrors,
                          ),
                        ),
                        const SizedBox(height: VSpacing.space4),
                        VCard(
                          child: PartnerNoteSection(
                            note: state.note,
                            onNoteChanged: (v) => context.read<PartnerCreateCubit>().updateNote(v),
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
                      onPressed: state.status == PartnerCreateStatus.loading
                          ? null
                          : () => context.read<PartnerCreateCubit>().submit(),
                      isLoading: state.status == PartnerCreateStatus.loading,
                      fullWidth: true,
                      label: 'Lưu KH & NCC',
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _handleCancel(BuildContext context, PartnerCreateState state) async {
    if (state.isDirty) {
      final shouldExit = await showVBottomSheet<bool>(
        context: context,
        child: const PartnerCancelConfirmBottomSheet(),
      );
      if (shouldExit == true && context.mounted) {
        context.read<PartnerCreateCubit>().resetForm();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            context.pop();
          }
        });
      }
    } else {
      if (context.mounted) {
        context.pop();
      }
    }
  }

  void _showDuplicateWarningBottomSheet(
    BuildContext context,
    List<PartnerDuplicateMatchDto> warnings,
  ) {
    final cubit = context.read<PartnerCreateCubit>();
    showVBottomSheet(
      context: context,
      child: PartnerDuplicateWarningBottomSheet(
        warnings: warnings,
        onCancel: () {
          Navigator.pop(context);
          cubit.cancelSubmit();
        },
        onConfirm: () {
          Navigator.pop(context);
          cubit.confirmSubmit();
        },
        onViewExisting: () {
          Navigator.pop(context);
          cubit.cancelSubmit();
          // TODO: Implement navigation to existing partner
        },
      ),
    );
  }
}
