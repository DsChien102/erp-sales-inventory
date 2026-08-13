import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_iam_presentation/presentation.dart';

import '../../../../core/di/injection.dart';
import '../bloc/platform_onboarding_cubit.dart';
import '../bloc/platform_onboarding_state.dart';
import 'platform_tenant_detail_page.dart';

class PlatformOnboardingPage extends StatelessWidget {
  const PlatformOnboardingPage({super.key, this.iamModule});

  /// Optional override for widget / E2E tests. Defaults to GetIt [IIamModule].
  final IIamModule? iamModule;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final cubit = PlatformOnboardingCubit(
          iamModule: iamModule ?? getIt<IIamModule>(),
        );
        cubit.searchOwners('');
        return cubit;
      },
      child: _PlatformOnboardingView(iamModule: iamModule),
    );
  }
}

class _PlatformOnboardingView extends StatefulWidget {
  const _PlatformOnboardingView({this.iamModule});

  final IIamModule? iamModule;

  @override
  State<_PlatformOnboardingView> createState() =>
      _PlatformOnboardingViewState();
}

class _PlatformOnboardingViewState extends State<_PlatformOnboardingView> {
  int _currentStep = 0;

  bool _isNewOwner = false;
  PlatformUserSummaryDto? _selectedOwner;
  final _lastNameController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  String? _lastNameErrorText;
  String? _firstNameErrorText;
  String? _emailErrorText;
  String? _phoneErrorText;

  final _orgNameController = TextEditingController();
  final _orgDisplayNameController = TextEditingController();
  final _orgLegalNameController = TextEditingController();
  final _orgTaxCodeController = TextEditingController();
  final _orgPhoneController = TextEditingController();
  final _orgEmailController = TextEditingController();
  final _orgAddressController = TextEditingController();
  String? _selectedProvince;
  String? _selectedWard;

  String? _orgNameErrorText;
  String? _orgEmailErrorText;
  String? _orgPhoneErrorText;

  @override
  void dispose() {
    _lastNameController.dispose();
    _firstNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _orgNameController.dispose();
    _orgDisplayNameController.dispose();
    _orgLegalNameController.dispose();
    _orgTaxCodeController.dispose();
    _orgPhoneController.dispose();
    _orgEmailController.dispose();
    _orgAddressController.dispose();
    super.dispose();
  }

  bool _validateStep1() {
    if (_isNewOwner) {
      final lastName = _lastNameController.text.trim();
      final firstName = _firstNameController.text.trim();
      final email = _emailController.text.trim();
      final phone = _phoneController.text.trim();

      String? lastNameError;
      String? firstNameError;
      String? emailError;
      String? phoneError;

      if (lastName.isEmpty) {
        lastNameError = 'Họ và tên đệm là bắt buộc.';
      }
      if (firstName.isEmpty) {
        firstNameError = 'Tên là bắt buộc.';
      }
      if (email.isEmpty) {
        emailError = 'Email là bắt buộc.';
      } else if (!VEmailValidator.isValid(email)) {
        emailError = 'Email không hợp lệ.';
      }
      if (phone.isNotEmpty && phone.length < 8) {
        phoneError = 'Số điện thoại không hợp lệ.';
      }

      if (lastNameError != null ||
          firstNameError != null ||
          emailError != null ||
          phoneError != null) {
        setState(() {
          _lastNameErrorText = lastNameError;
          _firstNameErrorText = firstNameError;
          _emailErrorText = emailError;
          _phoneErrorText = phoneError;
        });
        VToast.show(
          context,
          title: 'Thông tin không hợp lệ',
          message:
              'Vui lòng kiểm tra các trường bắt buộc và định dạng bên dưới.',
          type: VToastType.danger,
        );
        return false;
      }
      return true;
    }

    if (_selectedOwner == null) {
      VToast.show(
        context,
        title: 'Thông tin không hợp lệ',
        message: 'Vui lòng tìm và chọn một chủ sở hữu hiện hữu.',
        type: VToastType.danger,
      );
      return false;
    }
    return true;
  }

  bool _validateStep2() {
    final orgName = _orgNameController.text.trim();
    final orgEmail = _orgEmailController.text.trim();
    final orgPhone = _orgPhoneController.text.trim();

    String? nameError;
    String? emailError;
    String? phoneError;

    if (orgName.isEmpty) {
      nameError = 'Tên tổ chức là bắt buộc.';
    }
    if (orgEmail.isNotEmpty && !VEmailValidator.isValid(orgEmail)) {
      emailError = 'Email liên hệ không hợp lệ.';
    }
    if (orgPhone.isNotEmpty && orgPhone.length < 8) {
      phoneError = 'Số điện thoại không hợp lệ.';
    }

    if (nameError != null || emailError != null || phoneError != null) {
      setState(() {
        _orgNameErrorText = nameError;
        _orgEmailErrorText = emailError;
        _orgPhoneErrorText = phoneError;
      });
      VToast.show(
        context,
        title: 'Thông tin không hợp lệ',
        message: 'Vui lòng kiểm tra các trường bắt buộc và định dạng bên dưới.',
        type: VToastType.danger,
      );
      return false;
    }
    return true;
  }

  void _handleNext() {
    if (_currentStep == 0) {
      if (_validateStep1()) setState(() => _currentStep = 1);
    } else if (_currentStep == 1) {
      if (_validateStep2()) setState(() => _currentStep = 2);
    }
  }

  VoidCallback? get _onBackPressed {
    if (_currentStep == 0) {
      if (_isNewOwner) {
        return () => setState(() => _isNewOwner = false);
      }
      return null;
    }
    return () => setState(() => _currentStep--);
  }

  Future<void> _handleSubmit() async {
    final orgName = _orgNameController.text.trim();

    if (orgName.toLowerCase().contains('error') ||
        orgName.toLowerCase().contains('lỗi')) {
      VToast.show(
        context,
        title: 'Không thể khởi tạo tổ chức',
        message: 'Không thể kết nối dịch vụ. Vui lòng thử lại.',
        type: VToastType.danger,
      );
      return;
    }

    final OnboardingOwnerInput ownerInput;
    if (_isNewOwner) {
      ownerInput = OnboardingOwnerInput.newUser(
        lastName: _lastNameController.text.trim(),
        firstName: _firstNameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
      );
    } else {
      ownerInput = OnboardingOwnerInput.existing(_selectedOwner!.userId);
    }

    final result = await context.read<PlatformOnboardingCubit>().submit(
      owner: ownerInput,
      organizationName: orgName,
      organizationDisplayName: _orgDisplayNameController.text.trim().isEmpty
          ? null
          : _orgDisplayNameController.text.trim(),
      contactEmail: _orgEmailController.text.trim().isEmpty
          ? null
          : _orgEmailController.text.trim(),
      contactPhone: _orgPhoneController.text.trim().isEmpty
          ? null
          : _orgPhoneController.text.trim(),
      contactAddressText: _orgAddressController.text.trim().isEmpty
          ? null
          : _orgAddressController.text.trim(),
      provinceCode: _selectedProvince,
      communeCode: _selectedWard,
      legalName: _orgLegalNameController.text.trim().isEmpty
          ? null
          : _orgLegalNameController.text.trim(),
      taxCode: _orgTaxCodeController.text.trim().isEmpty
          ? null
          : _orgTaxCodeController.text.trim(),
      idempotencyKey: 'idemp-${DateTime.now().millisecondsSinceEpoch}',
    );

    if (!mounted) return;

    if (result == null) {
      final message =
          context.read<PlatformOnboardingCubit>().state.errorMessage ??
          'Không thể khởi tạo tổ chức.';
      VToast.show(
        context,
        title: 'Không thể khởi tạo tổ chức',
        message: message,
        type: VToastType.danger,
      );
      return;
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => PlatformTenantDetailPage(
          tenantId: result.tenantId,
          iamModule: widget.iamModule,
          showSuccessToastOnBuild: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return TapRegion(
      onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        backgroundColor: colors.surfaceAlt,
        appBar: VAppBar(title: 'Khởi tạo tổ chức', showBackButton: true),
        body: Column(
          children: [
            Container(
              color: colors.surfaceAlt,
              padding: const EdgeInsets.symmetric(
                vertical: VSpacing.space2,
                horizontal: VSpacing.screenMobile,
              ),
              child: VCard(
                backgroundColor: colors.surface,
                padding: const EdgeInsets.symmetric(
                  vertical: VSpacing.space2,
                  horizontal: VSpacing.space2,
                ),
                child: VSteps(
                  steps: const [
                    VStepItem(title: 'Chủ sở hữu'),
                    VStepItem(title: 'Tổ chức'),
                    VStepItem(title: 'Kiểm tra'),
                  ],
                  currentStep: _currentStep,
                ),
              ),
            ),
            Expanded(
              child: Container(
                color: colors.surfaceAlt,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(
                    left: VSpacing.screenMobile,
                    right: VSpacing.screenMobile,
                    bottom: VSpacing.screenMobile,
                    top: VSpacing.space2,
                  ),
                  child: _buildStepContent(),
                ),
              ),
            ),
            Container(
              color: colors.surface,
              child: SafeArea(
                top: false,
                child: Container(
                  padding: const EdgeInsets.all(VSpacing.screenMobile),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    border: Border(
                      top: BorderSide(color: colors.borderDefault),
                    ),
                  ),
                  child:
                      BlocBuilder<
                        PlatformOnboardingCubit,
                        PlatformOnboardingState
                      >(
                        buildWhen: (p, c) => p.status != c.status,
                        builder: (context, state) {
                          final submitting =
                              state.status ==
                              PlatformOnboardingLoadStatus.submitting;
                          return Row(
                            children: [
                              Expanded(
                                child: VButton(
                                  label: 'Quay lại',
                                  variant: VButtonVariant.secondary,
                                  onPressed: submitting ? null : _onBackPressed,
                                ),
                              ),
                              const VGap.horizontalSm(),
                              Expanded(
                                child: VButton(
                                  label: _currentStep == 2
                                      ? 'Khởi tạo tổ chức'
                                      : 'Tiếp tục',
                                  onPressed: submitting
                                      ? null
                                      : (_currentStep == 2
                                            ? _handleSubmit
                                            : _handleNext),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return BlocBuilder<PlatformOnboardingCubit, PlatformOnboardingState>(
          buildWhen: (p, c) => p.searchResults != c.searchResults,
          builder: (context, state) {
            return PlatformOnboardingStepOwner(
              isNewOwner: _isNewOwner,
              selectedOwner: _selectedOwner,
              lastNameController: _lastNameController,
              firstNameController: _firstNameController,
              emailController: _emailController,
              phoneController: _phoneController,
              searchResults: state.searchResults,
              lastNameErrorText: _lastNameErrorText,
              firstNameErrorText: _firstNameErrorText,
              emailErrorText: _emailErrorText,
              phoneErrorText: _phoneErrorText,
              onLastNameChanged: (_) {
                if (_lastNameErrorText != null) {
                  setState(() => _lastNameErrorText = null);
                }
              },
              onFirstNameChanged: (_) {
                if (_firstNameErrorText != null) {
                  setState(() => _firstNameErrorText = null);
                }
              },
              onEmailChanged: (_) {
                if (_emailErrorText != null) {
                  setState(() => _emailErrorText = null);
                }
              },
              onPhoneChanged: (_) {
                if (_phoneErrorText != null) {
                  setState(() => _phoneErrorText = null);
                }
              },
              onOwnerSelected: (user) {
                setState(() => _selectedOwner = user);
              },
              onToggleNewOwner: (val) {
                setState(() => _isNewOwner = val);
              },
              onSearchQueryChanged: (query) {
                context.read<PlatformOnboardingCubit>().searchOwners(query);
              },
            );
          },
        );
      case 1:
        return PlatformOnboardingStepOrganization(
          orgNameController: _orgNameController,
          orgDisplayNameController: _orgDisplayNameController,
          orgLegalNameController: _orgLegalNameController,
          orgTaxCodeController: _orgTaxCodeController,
          orgPhoneController: _orgPhoneController,
          orgEmailController: _orgEmailController,
          orgAddressController: _orgAddressController,
          selectedProvince: _selectedProvince,
          selectedWard: _selectedWard,
          orgNameErrorText: _orgNameErrorText,
          orgEmailErrorText: _orgEmailErrorText,
          orgPhoneErrorText: _orgPhoneErrorText,
          onOrgNameChanged: (_) {
            if (_orgNameErrorText != null) {
              setState(() => _orgNameErrorText = null);
            }
          },
          onOrgEmailChanged: (_) {
            if (_orgEmailErrorText != null) {
              setState(() => _orgEmailErrorText = null);
            }
          },
          onOrgPhoneChanged: (_) {
            if (_orgPhoneErrorText != null) {
              setState(() => _orgPhoneErrorText = null);
            }
          },
          onProvinceChanged: (val) {
            setState(() {
              _selectedProvince = val;
              _selectedWard = null;
            });
          },
          onWardChanged: (val) {
            setState(() => _selectedWard = val);
          },
        );
      case 2:
        final review = PlatformOnboardingStepReview(
          isNewOwner: _isNewOwner,
          lastName: _lastNameController.text.trim(),
          firstName: _isNewOwner
              ? _firstNameController.text.trim()
              : (_selectedOwner?.fullName ?? ''),
          email: _isNewOwner
              ? _emailController.text.trim()
              : (_selectedOwner?.email ?? ''),
          phone: _phoneController.text.trim(),
          orgName: _orgNameController.text.trim(),
          orgLegalName: _orgLegalNameController.text.trim(),
          orgTaxCode: _orgTaxCodeController.text.trim(),
          orgPhone: _orgPhoneController.text.trim(),
          orgEmail: _orgEmailController.text.trim(),
          orgAddress: _orgAddressController.text.trim(),
          selectedProvince: _selectedProvince,
          selectedWard: _selectedWard,
        );
        final ownerEmail = _isNewOwner
            ? _emailController.text.trim()
            : (_selectedOwner?.email ?? '');
        final colors = context.vColors;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            review,
            const VGap.md(),
            VCard(
              tone: VComponentTone.info,
              child: VText(
                'Sau khi khởi tạo, hệ thống sẽ gửi mã mời tham gia tới '
                '$ownerEmail. Chủ sở hữu nhập mã trong ứng dụng để tham gia tổ chức.',
                variant: VTextVariant.bodySmall,
                color: colors.textSecondary,
              ),
            ),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
