import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_partner_application/application.dart';

class PartnerContactForm extends StatefulWidget {
  const PartnerContactForm({
    super.key,
    this.contact,
    required this.isSubmitting,
    this.errorMessage,
    required this.onSubmit,
    required this.onCancel,
    this.onFormCreated,
  });

  final PartnerContactDto? contact;
  final bool isSubmitting;
  final String? errorMessage;
  final void Function(
    String fullName,
    String phone,
    String? email,
    String? contactRole,
    bool isPrimary,
    String? note,
  ) onSubmit;
  final VoidCallback onCancel;
  final void Function(VoidCallback submit)? onFormCreated;

  @override
  State<PartnerContactForm> createState() => _PartnerContactFormState();
}

class _PartnerContactFormState extends State<PartnerContactForm> {
  late final TextEditingController _fullNameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _noteController;
  String? _selectedRole;
  bool _isPrimary = false;

  String? _fullNameError;
  String? _phoneError;
  String? _roleError;
  String? _emailError;

  final List<String> _roleOptions = const [
    'Chủ đại lý',
    'Quản lý kinh doanh',
    'Kế toán',
    'Nhân viên mua hàng',
    'Giao nhận',
    'Phụ trách công nợ',
    'Khác',
  ];

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController(text: widget.contact?.displayName ?? '');
    _phoneController = TextEditingController(text: widget.contact?.phone ?? '');
    _emailController = TextEditingController(text: widget.contact?.email ?? '');
    _noteController = TextEditingController(text: widget.contact?.note ?? '');
    _isPrimary = widget.contact?.isPrimary ?? false;

    final initialRole = widget.contact?.contactRole;
    if (initialRole != null && initialRole.isNotEmpty) {
      if (_roleOptions.contains(initialRole)) {
        _selectedRole = initialRole;
      } else {
        _selectedRole = 'Khác';
      }
    }

    widget.onFormCreated?.call(_submit);
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _submit() {
    setState(() {
      final fullName = _fullNameController.text.trim();
      _fullNameError = fullName.isEmpty ? 'Vui lòng nhập họ tên' : null;
      
      final phone = _phoneController.text.trim();
      _phoneError = phone.isEmpty ? 'Vui lòng nhập số điện thoại' : null;

      final role = _selectedRole;
      _roleError = (role == null || role.isEmpty) ? 'Vui lòng chọn vai trò' : null;
      
      final email = _emailController.text.trim();
      _emailError = VEmailValidator.validate(email, isRequired: false);
    });

    if (_fullNameError == null && _phoneError == null && _roleError == null && _emailError == null) {
      widget.onSubmit(
        _fullNameController.text,
        _phoneController.text,
        _emailController.text,
        _selectedRole,
        _isPrimary,
        _noteController.text,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(VSpacing.space4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (widget.errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(VSpacing.space3),
                    decoration: BoxDecoration(
                      color: colors.danger.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(VRadius.card),
                      border: Border.all(color: colors.danger.withValues(alpha: 0.2)),
                    ),
                    child: Text(
                      widget.errorMessage!,
                      style: VTypography.bodySmall.copyWith(color: colors.danger),
                    ),
                  ),
                  const SizedBox(height: VSpacing.space4),
                ],

                // 1. Họ và tên
                VTextField(
                  key: const Key('input_contact_fullname'),
                  controller: _fullNameController,
                  label: 'Họ và tên',
                  hintText: 'Nhập họ và tên người liên hệ',
                  errorText: _fullNameError,
                  enabled: !widget.isSubmitting,
                  isRequired: true,
                ),
                const SizedBox(height: VSpacing.space4),

                // 2. Vai trò liên hệ
                VSelect<String>(
                  key: const Key('input_contact_role'),
                  value: _selectedRole,
                  label: 'Vai trò liên hệ',
                  hintText: 'Chọn vai trò',
                  errorText: _roleError,
                  isRequired: true,
                  items: _roleOptions.map((role) {
                    return DropdownMenuItem<String>(
                      value: role,
                      child: Text(role),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedRole = val;
                      _roleError = null;
                    });
                  },
                  enabled: !widget.isSubmitting,
                ),
                const SizedBox(height: VSpacing.space4),

                // 3. SĐT chính
                VTextField(
                  key: const Key('input_contact_phone'),
                  controller: _phoneController,
                  label: 'SĐT chính',
                  hintText: 'Nhập số điện thoại',
                  keyboardType: TextInputType.phone,
                  errorText: _phoneError,
                  enabled: !widget.isSubmitting,
                  isRequired: true,
                ),
                const SizedBox(height: VSpacing.space4),

                // 4. Email
                VTextField(
                  key: const Key('input_contact_email'),
                  controller: _emailController,
                  label: 'Email',
                  hintText: 'Nhập địa chỉ email',
                  keyboardType: TextInputType.emailAddress,
                  errorText: _emailError,
                  enabled: !widget.isSubmitting,
                ),
                const SizedBox(height: VSpacing.space4),

                // 5. Switch "Người liên hệ chính" (with subtitle)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: widget.isSubmitting
                              ? null
                              : () {
                                  setState(() {
                                    _isPrimary = !_isPrimary;
                                  });
                                },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Người liên hệ chính',
                                style: VTypography.bodyDefault.copyWith(
                                  color: colors.textPrimary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Là người liên hệ chính cho tổ chức',
                                style: VTypography.bodySmall.copyWith(
                                  color: colors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      VSwitch(
                        key: const Key('input_contact_is_primary'),
                        value: _isPrimary,
                        onChanged: widget.isSubmitting
                            ? null
                            : (val) {
                                setState(() {
                                  _isPrimary = val;
                                });
                              },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: VSpacing.space4),

                // 6. Ghi chú
                VTextField(
                  key: const Key('input_contact_note'),
                  controller: _noteController,
                  label: 'Ghi chú',
                  hintText: 'Nhập ghi chú liên quan',
                  maxLines: 3,
                  enabled: !widget.isSubmitting,
                ),
              ],
            ),
          ),
        ),

        // Bottom action buttons (Hidden if using App Bar actions)
        if (widget.onFormCreated == null)
          Container(
            decoration: BoxDecoration(
              color: colors.surface,
              border: Border(top: BorderSide(color: colors.borderDefault)),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(VSpacing.space4),
                child: Row(
                  children: [
                    Expanded(
                      child: VButton(
                        label: 'Hủy',
                        variant: VButtonVariant.outline,
                        foregroundColor: colors.success,
                        onPressed: widget.isSubmitting ? null : widget.onCancel,
                      ),
                    ),
                    const SizedBox(width: VSpacing.space3),
                    Expanded(
                      child: VButton(
                        label: 'Lưu',
                        variant: VButtonVariant.primary,
                        onPressed: widget.isSubmitting ? null : _submit,
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
}
