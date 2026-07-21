import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_iam_presentation/presentation.dart';

import 'package:admin/features/users/presentation/mock_platform_service.dart';

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

  // Step 2: Organization state
  final _orgNameController = TextEditingController();
  final _orgDisplayNameController = TextEditingController();
  final _orgPhoneController = TextEditingController();
  final _orgEmailController = TextEditingController();
  final _orgAddressController = TextEditingController();
  String? _selectedProvince = 'Đồng Nai';
  String? _selectedWard = 'Trấn Biên';

  @override
  void dispose() {
    _lastNameController.dispose();
    _firstNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _orgNameController.dispose();
    _orgDisplayNameController.dispose();
    _orgPhoneController.dispose();
    _orgEmailController.dispose();
    _orgAddressController.dispose();
    super.dispose();
  }

  bool _validateStep1() {
    if (_isNewOwner) {
      if (_lastNameController.text.trim().isEmpty ||
          _firstNameController.text.trim().isEmpty ||
          _emailController.text.trim().isEmpty) {
        VToast.show(
          context,
          title: 'Lỗi',
          message: 'Vui lòng nhập đầy đủ Họ, Tên và Email chủ sở hữu mới.',
          type: VToastType.danger,
        );
        return false;
      }
      if (!VEmailValidator.isValid(_emailController.text.trim())) {
        VToast.show(
          context,
          title: 'Lỗi',
          message: 'Định dạng email chủ sở hữu không hợp lệ.',
          type: VToastType.danger,
        );
        return false;
      }
    } else {
      if (_selectedOwner == null) {
        VToast.show(
          context,
          title: 'Lỗi',
          message: 'Vui lòng tìm và chọn một chủ sở hữu hiện hữu.',
          type: VToastType.danger,
        );
        return false;
      }
    }
    return true;
  }

  bool _validateStep2() {
    if (_orgNameController.text.trim().isEmpty) {
      VToast.show(
        context,
        title: 'Lỗi',
        message: 'Tên tổ chức là bắt buộc.',
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
    final service = MockPlatformService.instance;
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

    service.createTenantOnboarding(
      owner: ownerInput,
      organizationName: orgName,
      idempotencyKey: 'idemp-${DateTime.now().millisecondsSinceEpoch}',
    );

    VToast.show(
      context,
      title: 'Khởi tạo thành công',
      message: 'Đã khởi tạo tổ chức thành công.',
      type: VToastType.success,
    );

    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: VAppBar(
        title: 'Khởi tạo tổ chức',
        showBackButton: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: VSpacing.space3,
              horizontal: VSpacing.screenMobile,
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
          const Divider(height: 1),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(VSpacing.screenMobile),
              child: _buildStepContent(),
            ),
          ),

          SafeArea(
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
                      onPressed: _handleBack,
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
        ],
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        final service = MockPlatformService.instance;
        final results = service.searchPlatformUsers(query: _ownerSearchQuery);

        return PlatformOnboardingStepOwner(
          isNewOwner: _isNewOwner,
          selectedOwner: _selectedOwner,
          lastNameController: _lastNameController,
          firstNameController: _firstNameController,
          emailController: _emailController,
          phoneController: _phoneController,
          searchResults: results,
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
          orgPhoneController: _orgPhoneController,
          orgEmailController: _orgEmailController,
          orgAddressController: _orgAddressController,
          selectedProvince: _selectedProvince,
          selectedWard: _selectedWard,
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
          onOrgNameChanged: (val) {
            if (_orgDisplayNameController.text.trim().isEmpty) {
              setState(() {
                _orgDisplayNameController.text = val;
              });
            }
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
