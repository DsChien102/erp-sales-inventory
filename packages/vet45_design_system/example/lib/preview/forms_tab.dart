import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

import 'preview_section.dart';

class FormsPreviewTab extends StatefulWidget {
  const FormsPreviewTab({super.key});

  @override
  State<FormsPreviewTab> createState() => _FormsPreviewTabState();
}

class _FormsPreviewTabState extends State<FormsPreviewTab> {
  final _optionalEmail = TextEditingController();
  final _requiredEmail = TextEditingController();
  final _externalEmail = TextEditingController();
  final _optionalPassword = TextEditingController();
  final _requiredPassword = TextEditingController();
  final _externalPassword = TextEditingController();
  final _disabledPassword = TextEditingController(text: 'secret123');
  final _hintController = TextEditingController();
  String? _externalEmailError;
  String? _externalPasswordError;
  String? _otpError;
  String _otpCompleted = '';
  String _inviteCompleted = '';
  int? _moneyValue;
  int? _requiredMoney;
  num? _integerValue;
  num? _decimalValue;
  String? _selectValue;
  String? _requiredSelect;
  String? _searchableSelect;
  List<String> _companySelected = const ['hidden'];
  List<String> _notifSelected = const ['email'];
  List<String> _requiredChoice = const [];

  @override
  void dispose() {
    _optionalEmail.dispose();
    _requiredEmail.dispose();
    _externalEmail.dispose();
    _optionalPassword.dispose();
    _requiredPassword.dispose();
    _externalPassword.dispose();
    _disabledPassword.dispose();
    _hintController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(VSpacing.screenMobile),
      children: [
        PreviewSection(
          title: 'VVerificationCodeField',
          child: Column(
            children: [
              PreviewStateRow(
                label: 'Default + helper + onCompleted',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    VVerificationCodeField(
                      label: 'Mã xác thực',
                      helperText: 'Nhập 6 số từ SMS / authenticator.',
                      autofocus: false,
                      onChanged: (_) {
                        if (_otpError != null) {
                          setState(() => _otpError = null);
                        }
                      },
                      onCompleted: (code) {
                        setState(() => _otpCompleted = code);
                        VToast.show(
                          context,
                          title: 'OTP đủ',
                          message: code,
                          type: VToastType.success,
                        );
                      },
                    ),
                    if (_otpCompleted.isNotEmpty) ...[
                      const SizedBox(height: VSpacing.space2),
                      VText(
                        'Completed: $_otpCompleted',
                        variant: VTextVariant.bodySmall,
                        color: context.vColors.textSecondary,
                      ),
                    ],
                  ],
                ),
              ),
              PreviewStateRow(
                label: 'External error / danger',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    VVerificationCodeField(
                      label: 'Mã 2FA',
                      errorText: _otpError,
                      tone: _otpError != null
                          ? VComponentTone.danger
                          : VComponentTone.neutral,
                      onChanged: (_) {
                        if (_otpError != null) {
                          setState(() => _otpError = null);
                        }
                      },
                      onCompleted: (code) {
                        setState(() => _otpCompleted = code);
                      },
                    ),
                    const SizedBox(height: VSpacing.space2),
                    VButton(
                      label: 'Set external error',
                      variant: VButtonVariant.outline,
                      size: VButtonSize.small,
                      onPressed: () {
                        setState(() {
                          _otpError = 'Mã xác thực không đúng hoặc đã hết hạn';
                        });
                      },
                    ),
                  ],
                ),
              ),
              PreviewStateRow(
                label: 'Alphanumeric 8-char (uppercase)',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    VVerificationCodeField(
                      length: 8,
                      charset: VVerificationCodeCharset.alphanumeric,
                      label: 'Mã lời mời',
                      helperText: '8 ký tự chữ và số, tự viết hoa.',
                      onCompleted: (code) {
                        setState(() => _inviteCompleted = code);
                        VToast.show(
                          context,
                          title: 'Mã đủ',
                          message: code,
                          type: VToastType.success,
                        );
                      },
                    ),
                    if (_inviteCompleted.isNotEmpty) ...[
                      const SizedBox(height: VSpacing.space2),
                      VText(
                        'Completed: $_inviteCompleted',
                        variant: VTextVariant.bodySmall,
                        color: context.vColors.textSecondary,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        PreviewSection(
          title: 'VEmailField',
          child: Column(
            children: [
              PreviewStateRow(
                label: 'Optional (built-in validation)',
                child: VEmailField(
                  controller: _optionalEmail,
                  label: 'Email',
                  hintText: 'customer@gmail.com',
                  helperText: 'Validation sau debounce.',
                ),
              ),
              PreviewStateRow(
                label: 'Required',
                child: VEmailField(
                  controller: _requiredEmail,
                  label: 'Email bắt buộc',
                  isRequired: true,
                ),
              ),
              PreviewStateRow(
                label: 'External errorText override',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    VEmailField(
                      controller: _externalEmail,
                      label: 'Email',
                      errorText: _externalEmailError,
                      onChanged: (_) {
                        if (_externalEmailError != null) {
                          setState(() => _externalEmailError = null);
                        }
                      },
                    ),
                    const SizedBox(height: VSpacing.space2),
                    VButton(
                      label: 'Set external error',
                      variant: VButtonVariant.outline,
                      size: VButtonSize.small,
                      onPressed: () {
                        setState(() {
                          _externalEmailError = 'Email đã tồn tại trong hệ thống';
                        });
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        PreviewSection(
          title: 'VPasswordField',
          child: Column(
            children: [
              PreviewStateRow(
                label: 'Optional (built-in validation)',
                child: VPasswordField(
                  controller: _optionalPassword,
                  label: 'Mật khẩu',
                  hintText: '••••••••',
                  helperText: 'Tối thiểu 8 ký tự; validation sau debounce.',
                ),
              ),
              PreviewStateRow(
                label: 'Required',
                child: VPasswordField(
                  controller: _requiredPassword,
                  label: 'Mật khẩu bắt buộc',
                  isRequired: true,
                ),
              ),
              PreviewStateRow(
                label: 'External errorText override',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    VPasswordField(
                      controller: _externalPassword,
                      label: 'Mật khẩu',
                      errorText: _externalPasswordError,
                      onChanged: (_) {
                        if (_externalPasswordError != null) {
                          setState(() => _externalPasswordError = null);
                        }
                      },
                    ),
                    const SizedBox(height: VSpacing.space2),
                    VButton(
                      label: 'Set external error',
                      variant: VButtonVariant.outline,
                      size: VButtonSize.small,
                      onPressed: () {
                        setState(() {
                          _externalPasswordError =
                              'Mật khẩu không khớp với xác nhận';
                        });
                      },
                    ),
                  ],
                ),
              ),
              PreviewStateRow(
                label: 'Disabled',
                child: VPasswordField(
                  controller: _disabledPassword,
                  label: 'Mật khẩu',
                  enabled: false,
                ),
              ),
              PreviewStateRow(
                label: 'Toggle visibility (initially visible)',
                child: VPasswordField(
                  label: 'Mật khẩu',
                  initiallyObscured: false,
                  helperText: 'Bấm icon mắt để ẩn/hiện.',
                ),
              ),
            ],
          ),
        ),
        PreviewSection(
          title: 'VMoneyField',
          child: Column(
            children: [
              PreviewStateRow(
                label: 'Optional',
                child: VMoneyField(
                  label: 'Số tiền',
                  value: _moneyValue,
                  onChanged: (v) => setState(() => _moneyValue = v),
                ),
              ),
              PreviewStateRow(
                label: 'Required + min/max',
                child: VMoneyField(
                  label: 'Số tiền bắt buộc',
                  value: _requiredMoney,
                  isRequired: true,
                  min: 1000,
                  max: 100000000,
                  onChanged: (v) => setState(() => _requiredMoney = v),
                ),
              ),
            ],
          ),
        ),
        PreviewSection(
          title: 'VNumberField',
          child: Column(
            children: [
              PreviewStateRow(
                label: 'Integer',
                child: VNumberField(
                  label: 'Số lượng',
                  value: _integerValue,
                  min: 0,
                  max: 9999,
                  onChanged: (v) => setState(() => _integerValue = v),
                ),
              ),
              PreviewStateRow(
                label: 'Decimal',
                child: VNumberField(
                  label: 'Tỷ lệ',
                  value: _decimalValue,
                  allowDecimal: true,
                  min: 0,
                  max: 100,
                  suffixText: '%',
                  onChanged: (v) => setState(() => _decimalValue = v),
                ),
              ),
            ],
          ),
        ),
        PreviewSection(
          title: 'VSelect',
          child: Column(
            children: [
              PreviewStateRow(
                label: 'Basic',
                child: VSelect<String>(
                  label: 'Lý do',
                  value: _selectValue,
                  items: const [
                    DropdownMenuItem(value: 'defect', child: Text('Sản phẩm lỗi')),
                    DropdownMenuItem(value: 'return', child: Text('Khách trả')),
                  ],
                  onChanged: (v) => setState(() => _selectValue = v),
                ),
              ),
              PreviewStateRow(
                label: 'Required',
                child: VSelect<String>(
                  label: 'Trạng thái',
                  value: _requiredSelect,
                  isRequired: true,
                  items: const [
                    DropdownMenuItem(value: 'active', child: Text('Active')),
                    DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
                  ],
                  onChanged: (v) => setState(() => _requiredSelect = v),
                ),
              ),
            ],
          ),
        ),
        PreviewSection(
          title: 'VChoiceList',
          child: Column(
            children: [
              PreviewStateRow(
                label: 'Single + childBuilder',
                child: VChoiceList<String>(
                  title: 'Tên công ty',
                  selected: _companySelected,
                  choices: [
                    const VChoiceOption(value: 'hidden', label: 'Ẩn'),
                    const VChoiceOption(value: 'optional', label: 'Tùy chọn'),
                    VChoiceOption(
                      value: 'required',
                      label: 'Bắt buộc',
                      childBuilder: (isSelected) => isSelected
                          ? VTextField(
                              controller: _hintController,
                              label: 'Gợi ý nhập',
                              hintText: 'Công ty TNHH ABC',
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                  onChanged: (v) => setState(() => _companySelected = v),
                ),
              ),
              PreviewStateRow(
                label: 'Multiple + minSelections',
                child: VChoiceList<String>(
                  title: 'Thông báo',
                  allowMultiple: true,
                  selected: _notifSelected,
                  minSelections: 1,
                  choices: const [
                    VChoiceOption(value: 'email', label: 'Email'),
                    VChoiceOption(value: 'sms', label: 'SMS'),
                    VChoiceOption(value: 'push', label: 'Push'),
                  ],
                  onChanged: (v) => setState(() => _notifSelected = v),
                ),
              ),
              PreviewStateRow(
                label: 'Required',
                child: VChoiceList<String>(
                  title: 'Thanh toán',
                  isRequired: true,
                  selected: _requiredChoice,
                  choices: const [
                    VChoiceOption(value: 'cash', label: 'Tiền mặt'),
                    VChoiceOption(value: 'transfer', label: 'Chuyển khoản'),
                  ],
                  onChanged: (v) => setState(() => _requiredChoice = v),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
