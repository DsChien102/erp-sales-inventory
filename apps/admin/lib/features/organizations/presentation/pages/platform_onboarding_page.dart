import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_iam_presentation/presentation.dart';

class PlatformOnboardingPage extends StatefulWidget {
  const PlatformOnboardingPage({super.key});

  @override
  State<PlatformOnboardingPage> createState() => _PlatformOnboardingPageState();
}

class _PlatformOnboardingPageState extends State<PlatformOnboardingPage> {
  int _currentStep = 0;

  // Step 1: Owner state
  bool _isNewOwner = false;
  PlatformUserSummaryDto? _selectedOwner;
  final _lastNameController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  String _ownerSearchQuery = '';

  String? _lastNameErrorText;
  String? _firstNameErrorText;
  String? _emailErrorText;
  String? _phoneErrorText;

  // Step 2: Organization state
  final _orgNameController = TextEditingController();
  final _orgDisplayNameController = TextEditingController();
  final _orgLegalNameController = TextEditingController();
  final _orgTaxCodeController = TextEditingController();
  final _orgPhoneController = TextEditingController();
  final _orgEmailController = TextEditingController();
  final _orgAddressController = TextEditingController();
  String? _selectedProvince = 'Đồng Nai';
  String? _selectedWard = 'Trấn Biên';

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

      String? lError;
      String? fError;
      String? eError;
      String? pError;

      if (lastName.isEmpty) {
        lError = 'Họ và tên đệm là bắt buộc.';
      }
      if (firstName.isEmpty) {
        fError = 'Tên là bắt buộc.';
      }
      if (email.isEmpty) {
        eError = 'Email là bắt buộc.';
      } else if (!VEmailValidator.isValid(email)) {
        eError = 'Email không hợp lệ (ví dụ: user@domain.com).';
      }
      if (phone.isNotEmpty && phone.length < 8) {
        pError = 'Số điện thoại không hợp lệ.';
      }

      if (lError != null || fError != null || eError != null || pError != null) {
        setState(() {
          _lastNameErrorText = lError;
          _firstNameErrorText = fError;
          _emailErrorText = eError;
          _phoneErrorText = pError;
        });
        VToast.show(
          context,
          title: 'Thông tin không hợp lệ',
          message: 'Vui lòng kiểm tra lại thông tin chủ sở hữu mới.',
          type: VToastType.danger,
        );
        return false;
      }
    } else {
      if (_selectedOwner == null) {
        VToast.show(
          context,
          title: 'Thông tin không hợp lệ',
          message: 'Vui lòng tìm và chọn một chủ sở hữu hiện hữu.',
          type: VToastType.danger,
        );
        return false;
      }
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
      if (_validateStep1()) {
        setState(() {
          _currentStep = 1;
        });
      }
    } else if (_currentStep == 1) {
      if (_validateStep2()) {
        setState(() {
          _currentStep = 2;
        });
      }
    }
  }

  VoidCallback? get _onBackPressed {
    if (_currentStep == 0) {
      if (_isNewOwner) {
        return () {
          setState(() {
            _isNewOwner = false;
          });
        };
      } else {
        return null;
      }
    }
    return _handleBack;
  }

  void _handleBack() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    } else {
      context.pop();
    }
  }

  void _handleSubmit() {
    final service = FakePlatformUserService.instance;
    final orgName = _orgNameController.text.trim();

    if (orgName.toLowerCase().contains('error') || orgName.toLowerCase().contains('lỗi')) {
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
        phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
      );
    } else {
      ownerInput = OnboardingOwnerInput.existing(_selectedOwner!.userId);
    }

    final result = service.createTenantOnboarding(
      owner: ownerInput,
      organizationName: orgName,
      idempotencyKey: 'idemp-${DateTime.now().millisecondsSinceEpoch}',
    );

    final ownerName = _isNewOwner
        ? '${_lastNameController.text.trim()} ${_firstNameController.text.trim()}'.trim()
        : (_selectedOwner?.fullName ?? 'Lê Thị Lan');
    final ownerEmail = _isNewOwner
        ? _emailController.text.trim()
        : (_selectedOwner?.email ?? 'lan@gmail.com');

    final initials = orgName.isNotEmpty
        ? orgName.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase()
        : 'TC';

    final newOrg = OrganizationUiModel(
      id: result.tenantId,
      name: orgName,
      code: 'TEN-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      initials: initials.isEmpty ? 'TC' : initials,
      type: 'Tổ chức nền tảng',
      status: OrganizationStatus.settingUp,
      ownerName: ownerName,
      ownerEmail: ownerEmail,
      ownerRole: 'Chủ cửa hàng',
      unverifiedEmail: _isNewOwner,
      incompleteProfile: true,
      createdAt: DateTime.now(),
    );

    FakeOrganizationData.sampleOrganizations.insert(0, newOrg);

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => OrganizationDetailPage(
          organization: newOrg,
          showSuccessToastOnBuild: true,
          onBackPressed: () => Navigator.of(context).pop(true),
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
        appBar: VAppBar(
          title: 'Khởi tạo tổ chức',
          showBackButton: true,
        ),
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
                child: Row(
                  children: [
                    Expanded(
                      child: VButton(
                        label: 'Quay lại',
                        variant: VButtonVariant.outline,
                        onPressed: _onBackPressed,
                      ),
                    ),
                    const VGap.horizontalSm(),
                    Expanded(
                      child: VButton(
                        label: _currentStep == 2 ? 'Khởi tạo tổ chức' : 'Tiếp tục',
                        onPressed: _currentStep == 2 ? _handleSubmit : _handleNext,
                      ),
                    ),
                  ],
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
        final service = FakePlatformUserService.instance;
        final results = service.searchPlatformUsers(query: _ownerSearchQuery);

        return PlatformOnboardingStepOwner(
          isNewOwner: _isNewOwner,
          selectedOwner: _selectedOwner,
          lastNameController: _lastNameController,
          firstNameController: _firstNameController,
          emailController: _emailController,
          phoneController: _phoneController,
          searchResults: results,
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
            setState(() {
              _selectedOwner = user;
            });
          },
          onToggleNewOwner: (val) {
            setState(() {
              _isNewOwner = val;
            });
          },
          onSearchQueryChanged: (query) {
            setState(() {
              _ownerSearchQuery = query;
            });
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
            });
          },
          onWardChanged: (val) {
            setState(() {
              _selectedWard = val;
            });
          },
        );
      case 2:
        return PlatformOnboardingStepReview(
          isNewOwner: _isNewOwner,
          lastName: _lastNameController.text.trim(),
          firstName: _isNewOwner
              ? _firstNameController.text.trim()
              : (_selectedOwner?.fullName ?? ''),
          email: _isNewOwner ? _emailController.text.trim() : (_selectedOwner?.email ?? ''),
          phone: _isNewOwner ? _phoneController.text.trim() : '',
          orgName: _orgNameController.text.trim(),
          orgLegalName: _orgLegalNameController.text.trim(),
          orgTaxCode: _orgTaxCodeController.text.trim(),
          orgPhone: _orgPhoneController.text.trim(),
          orgEmail: _orgEmailController.text.trim(),
          orgAddress: _orgAddressController.text.trim(),
          selectedProvince: _selectedProvince,
          selectedWard: _selectedWard,
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
