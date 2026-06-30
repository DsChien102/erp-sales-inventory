import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';

import '../../mock_partner_data.dart';
import '../bloc/partner_create_cubit.dart';
import '../bloc/partner_create_state.dart';
import '../widgets/partner_form_sections.dart';
import '../widgets/partner_role_type_section.dart';

class PartnerCreatePage extends StatelessWidget {
  const PartnerCreatePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PartnerCreateCubit(MockPartnerRepository()),
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
      listenWhen: (previous, current) => previous.status != current.status || previous.errorMessage != current.errorMessage,
      listener: (context, state) {
        if (state.status == PartnerCreateStatus.error && state.errorMessage != null) {
          VToast.show(context, title: 'Lỗi', message: state.errorMessage!, type: VToastType.danger);
        } else if (state.status == PartnerCreateStatus.duplicateWarning) {
          _showDuplicateWarningDialog(context, state.duplicateWarnings);
        } else if (state.status == PartnerCreateStatus.success) {
          VToast.show(context, title: 'Thành công', message: 'Đã lưu KH & NCC thành công!', type: VToastType.success);
          context.pop();
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: dynamicColors.background,
          appBar: VAppBar(
            title: 'Thêm KH & NCC',
            actions: [
              TextButton(
                onPressed: state.status == PartnerCreateStatus.loading ? null : () => _handleCancel(context, state),
                child: Text(
                  'Hủy',
                  style: VTypography.bodyDefault.copyWith(
                    color: state.status == PartnerCreateStatus.loading ? dynamicColors.textMuted : dynamicColors.textSecondary,
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
                          onProfileTypeChanged: (v) => context.read<PartnerCreateCubit>().updateProfileType(v),
                          onNameChanged: (v) => context.read<PartnerCreateCubit>().updateName(v),
                        ),
                      ),
                      const SizedBox(height: VSpacing.space4),
                      VCard(
                        child: PartnerContactInfoSection(
                          phone: state.phone,
                          onPhoneChanged: (v) => context.read<PartnerCreateCubit>().updatePhone(v),
                          email: state.email,
                          onEmailChanged: (v) => context.read<PartnerCreateCubit>().updateEmail(v),
                          address: state.address,
                          onAddressChanged: (v) => context.read<PartnerCreateCubit>().updateAddress(v),
                        ),
                      ),
                      const SizedBox(height: VSpacing.space4),
                      VCard(
                        child: PartnerTaxInfoSection(
                          taxId: state.taxId,
                          onTaxIdChanged: (v) => context.read<PartnerCreateCubit>().updateTaxId(v),
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
                    onPressed: state.status == PartnerCreateStatus.loading ? null : () => context.read<PartnerCreateCubit>().submit(),
                    isLoading: state.status == PartnerCreateStatus.loading,
                    fullWidth: true,
                    label: 'Lưu KH & NCC',
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _handleCancel(BuildContext context, PartnerCreateState state) {
    if (state.name.isNotEmpty || state.phone.isNotEmpty) {
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(VRadius.card)),
          title: Text('Xác nhận thoát', style: VTypography.headingH4),
          content: Text('Bạn có dữ liệu chưa lưu. Bạn có chắc chắn muốn thoát?', style: VTypography.bodyDefault),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Tiếp tục nhập'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                context.pop();
              },
              child: const Text('Thoát', style: TextStyle(color: VColors.danger)),
            ),
          ],
        ),
      );
    } else {
      context.pop();
    }
  }

  void _showDuplicateWarningDialog(BuildContext context, List<String> warnings) {
    final cubit = context.read<PartnerCreateCubit>();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(VRadius.card)),
        title: Text('Cảnh báo trùng lặp', style: VTypography.headingH4),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hệ thống phát hiện dữ liệu có khả năng trùng:', style: VTypography.bodyDefault),
            const SizedBox(height: 8),
            ...warnings.map((w) => Text('- $w', style: VTypography.bodyDefault.copyWith(color: VColors.danger))),
            const SizedBox(height: 16),
            Text('Bạn có muốn tiếp tục lưu hồ sơ này?', style: VTypography.bodyDefault),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              cubit.cancelSubmit();
            },
            child: const Text('Quay lại kiểm tra'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              cubit.confirmSubmit();
            },
            child: const Text('Vẫn tiếp tục lưu', style: TextStyle(color: VColors.success)),
          ),
        ],
      ),
    );
  }
}
