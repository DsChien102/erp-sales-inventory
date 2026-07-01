import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_partner_application/application.dart';
import 'package:vet45_partner_presentation/presentation.dart';
import 'package:vet45_shared_application/application.dart';

import '../../../../core/di/injection.dart';

class PartnerEditPage extends StatelessWidget {
  final String partnerId;
  final PartnerItemModel? initialPartner;

  const PartnerEditPage({
    super.key,
    required this.partnerId,
    this.initialPartner,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PartnerEditCubit(
        partnerModule: getIt<IPartnerModule>(),
        executionContext: getIt<IExecutionContext>(),
        initialPartner: initialPartner,
      )..loadPartner(partnerId),
      child: const _PartnerEditView(),
    );
  }
}

class _PartnerEditView extends StatefulWidget {
  const _PartnerEditView();

  @override
  State<_PartnerEditView> createState() => _PartnerEditViewState();
}

class _PartnerEditViewState extends State<_PartnerEditView> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _addressController;
  late final TextEditingController _taxIdController;
  late final TextEditingController _billingNameController;
  late final TextEditingController _billingAddressController;
  late final TextEditingController _billingEmailController;
  late final TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _emailController = TextEditingController();
    _addressController = TextEditingController();
    _taxIdController = TextEditingController();
    _billingNameController = TextEditingController();
    _billingAddressController = TextEditingController();
    _billingEmailController = TextEditingController();
    _noteController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _taxIdController.dispose();
    _billingNameController.dispose();
    _billingAddressController.dispose();
    _billingEmailController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dynamicColors = context.vColors;

    return BlocConsumer<PartnerEditCubit, PartnerEditState>(
      listenWhen: (previous, current) =>
          previous.status != current.status || previous.errorMessage != current.errorMessage,
      listener: (context, state) {
        if (state.status == PartnerEditStatus.error && state.errorMessage != null) {
          VToast.show(
            context,
            title: 'Lỗi',
            message: state.errorMessage!,
            type: VToastType.danger,
          );
        } else if (state.status == PartnerEditStatus.loadingDataError &&
            state.errorMessage != null) {
          VToast.show(
            context,
            title: 'Lỗi tải dữ liệu',
            message: state.errorMessage!,
            type: VToastType.danger,
          );
        } else if (state.status == PartnerEditStatus.duplicateWarning) {
          _showDuplicateWarningBottomSheet(context, state.duplicateWarnings);
        } else if (state.status == PartnerEditStatus.ready && !state.hasChanges) {
          _syncControllersFromState(state);
        } else if (state.status == PartnerEditStatus.success) {
          VToast.show(
            context,
            title: 'Thành công',
            message: 'Đã cập nhật KH & NCC thành công!',
            type: VToastType.success,
          );
          context.pop(true);
        }
      },
      builder: (context, state) {
        final isLoadingData =
            state.status == PartnerEditStatus.initial ||
            state.status == PartnerEditStatus.loadingData;

        return PopScope(
          canPop: !state.hasChanges,
          onPopInvoked: (didPop) async {
            if (didPop) return;
            _handleCancel(context, state);
          },
          child: Scaffold(
            backgroundColor: dynamicColors.background,
            appBar: VAppBar(
              title: 'Chỉnh sửa KH & NCC',
              leading: IconButton(
                icon: Icon(
                  Icons.arrow_back,
                  color: dynamicColors.textPrimary,
                ),
                onPressed: () => _handleCancel(context, state),
              ),
              actions: [
                TextButton(
                  onPressed: state.status == PartnerEditStatus.saving || isLoadingData
                      ? null
                      : () => _handleCancel(context, state),
                  child: Text(
                    'Hủy',
                    style: VTypography.bodyDefault.copyWith(
                      color: state.status == PartnerEditStatus.saving || isLoadingData
                          ? dynamicColors.textMuted
                          : dynamicColors.textSecondary,
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
                              context.read<PartnerEditCubit>().loadPartner(state.partnerId),
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
                                  onRoleChanged: (v) =>
                                      context.read<PartnerEditCubit>().updateRole(v),
                                  profileType: state.profileType,
                                  onProfileTypeChanged: (v) =>
                                      context.read<PartnerEditCubit>().updateProfileType(v),
                                  nameController: _nameController,
                                  name: state.name,
                                  onNameChanged: (v) =>
                                      context.read<PartnerEditCubit>().updateName(v),
                                  contactName: '', // TODO: Support contactName in Edit
                                  onContactNameChanged: (_) {},
                                  showValidationErrors: state.showValidationErrors,
                                ),
                              ),
                              const SizedBox(height: VSpacing.space4),
                              VCard(
                                child: PartnerContactInfoSection(
                                  phoneController: _phoneController,
                                  phone: state.phone,
                                  onPhoneChanged: (v) =>
                                      context.read<PartnerEditCubit>().updatePhone(v),
                                  emailController: _emailController,
                                  email: state.email,
                                  onEmailChanged: (v) =>
                                      context.read<PartnerEditCubit>().updateEmail(v),
                                  addressController: _addressController,
                                  address: state.address,
                                  onAddressChanged: (v) =>
                                      context.read<PartnerEditCubit>().updateAddress(v),
                                  showValidationErrors: state.showValidationErrors,
                                ),
                              ),
                              const SizedBox(height: VSpacing.space4),
                              VCard(
                                child: PartnerTaxInfoSection(
                                  taxIdController: _taxIdController,
                                  taxId: state.taxId,
                                  onTaxIdChanged: (v) =>
                                      context.read<PartnerEditCubit>().updateTaxId(v),
                                  profileType: state.profileType,
                                  showValidationErrors: state.showValidationErrors,
                                ),
                              ),
                              const SizedBox(height: VSpacing.space4),
                              VCard(
                                child: PartnerNoteSection(
                                  noteController: _noteController,
                                  note: state.note,
                                  onNoteChanged: (v) =>
                                      context.read<PartnerEditCubit>().updateNote(v),
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
          ),
        );
      },
    );
  }

  void _syncControllersFromState(PartnerEditState state) {
    _syncController(_nameController, state.name);
    _syncController(_phoneController, state.phone);
    _syncController(_emailController, state.email);
    _syncController(_addressController, state.address);
    _syncController(_taxIdController, state.taxId);
    _syncController(_billingNameController, state.billingName);
    _syncController(_billingAddressController, state.billingAddress);
    _syncController(_billingEmailController, state.billingEmail);
    _syncController(_noteController, state.note);
  }

  void _syncController(TextEditingController controller, String value) {
    if (controller.text == value) {
      return;
    }

    controller.value = controller.value.copyWith(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
      composing: TextRange.empty,
    );
  }

  void _handleCancel(BuildContext context, PartnerEditState state) async {
    if (state.hasChanges) {
      final shouldExit = await showVBottomSheet<bool>(
        context: context,
        child: const PartnerCancelConfirmBottomSheet(),
      );
      if (shouldExit == true && context.mounted) {
        context.pop();
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
    final cubit = context.read<PartnerEditCubit>();
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
