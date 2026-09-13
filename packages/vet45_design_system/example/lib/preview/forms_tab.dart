import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

import 'preview_section.dart';

// Flat field chrome is deprecated; demos below still exercise the bridge.
// ignore_for_file: deprecated_member_use

class FormsPreviewTab extends StatefulWidget {
  const FormsPreviewTab({super.key});

  @override
  State<FormsPreviewTab> createState() => _FormsPreviewTabState();
}

class _FormsPreviewTabState extends State<FormsPreviewTab> {
  final _optionalEmail = TextEditingController();
  final _filledPhone = TextEditingController(text: '0988 123 456');
  final _disabledPhone = TextEditingController(text: '028 3822 1122');
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
  String? _plainUnit;
  String? _twoLineUnit;
  String? _cardUnit;
  String? _aliasUnit;
  String? _skeletonDemoUnit;
  bool _skeletonDemoLoading = true;
  DateTime? _date;
  List<String> _companySelected = const ['hidden'];
  List<String> _notifSelected = const ['email'];
  List<String> _requiredChoice = const [];

  @override
  void dispose() {
    _filledPhone.dispose();
    _disabledPhone.dispose();
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
          title: 'VPhoneField',
          description: '9–11 chữ số, cho phép dấu cách. Chữ và ký tự khác bị từ chối khi nhập/dán.',
          child: Column(
            children: [
              const PreviewStateRow(
                label: 'Optional / empty',
                child: VPhoneField(
                  label: 'Số điện thoại',
                  hintText: 'Ví dụ: 0988123456',
                  helperText: 'Không bắt buộc',
                ),
              ),
              PreviewStateRow(
                label: 'Filled / spaces',
                child: VPhoneField(controller: _filledPhone, label: 'Số điện thoại'),
              ),
              const PreviewStateRow(
                label: 'Required / live validation',
                child: VPhoneField(
                  label: 'Số điện thoại',
                  isRequired: true,
                  helperText: 'Thử nhập dưới 9 chữ số hoặc xóa hết nội dung.',
                ),
              ),
              PreviewStateRow(
                label: 'Disabled',
                child: VPhoneField(
                  controller: _disabledPhone,
                  label: 'Số điện thoại',
                  enabled: false,
                ),
              ),
              const PreviewStateRow(
                label: 'External error',
                child: VPhoneField(label: 'Số điện thoại', errorText: 'Số điện thoại đã tồn tại'),
              ),
              const PreviewStateRow(
                label: 'Manual validation',
                child: VPhoneField(
                  label: 'Số điện thoại',
                  validateOnChanged: false,
                  helperText: 'Ứng dụng gọi VPhoneValidator khi gửi form.',
                ),
              ),
              const PreviewStateRow(
                label: 'Initial value / sync',
                child: VPhoneField(
                  initialValue: '0901 234 567',
                  label: 'Số điện thoại',
                  validateOnChanged: false,
                  helperText: 'Khởi tạo từ chuỗi, không dùng controller ngoài',
                ),
              ),
            ],
          ),
        ),
        PreviewSection(
          title: 'VField (preferred)',
          description:
              'Compose Label + input child + Description/Error. '
              'Flat label/helper/error on inputs is deprecated.',
          child: Column(
            children: [
              PreviewStateRow(
                label: 'Compose + helper',
                child: VField(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const VFieldLabel('Email', isRequired: true),
                      VTextField(
                        controller: _optionalEmail,
                        hintText: 'customer@company.com',
                      ),
                      const VFieldDescription('Dùng email công ty'),
                    ],
                  ),
                ),
              ),
              PreviewStateRow(
                label: 'Compose + invalid',
                child: VField(
                  invalid: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const VFieldLabel('Tax code'),
                      const VTextField(
                        hintText: 'Required',
                        tone: VComponentTone.danger,
                      ),
                      const VFieldError('Thiếu mã số thuế'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
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
                      tone: _otpError != null ? VComponentTone.danger : VComponentTone.neutral,
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
                      variant: VButtonVariant.secondary,
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
                      variant: VButtonVariant.secondary,
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
                      variant: VButtonVariant.secondary,
                      size: VButtonSize.small,
                      onPressed: () {
                        setState(() {
                          _externalPasswordError = 'Mật khẩu không khớp với xác nhận';
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
          title: 'VDatePicker',
          child: Column(
            children: [
              PreviewStateRow(
                label: 'Empty (icon left — default)',
                child: VDatePicker(
                  value: null,
                  label: 'Invoice date',
                  required: true,
                  onChanged: (picked) => setState(() => _date = picked),
                ),
              ),
              PreviewStateRow(
                label: 'Filled (icon right)',
                child: VDatePicker(
                  value: _date ?? DateTime(2026, 6, 3),
                  label: 'Invoice date',
                  iconPosition: VDatePickerIconPosition.right,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2035),
                  onChanged: (picked) => setState(() => _date = picked),
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
          title: 'VCombobox',
          description:
              'Searchable single-select; input chrome matches VTextField. '
              'Compose demos tách theo kiểu item (4–10 options); '
              'Footer = create item từ query.',
          child: Column(
            children: [
              PreviewStateRow(
                label: 'Compose · searchable',
                child: VField(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const VFieldLabel('Tỉnh/Thành'),
                      VCombobox<String>(
                        value: _searchableSelect,
                        displayTextForValue: (v) => switch (v) {
                          'hcm' => 'Hồ Chí Minh',
                          'hn' => 'Hà Nội',
                          'dn' => 'Đà Nẵng',
                          'hp' => 'Hải Phòng',
                          'ct' => 'Cần Thơ',
                          'bd' => 'Bình Dương',
                          'dna' => 'Đồng Nai',
                          _ => '',
                        },
                        onChanged: (v) => setState(() => _searchableSelect = v),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            VComboboxContent(
                              child: VComboboxList(
                                children: const [
                                  VComboboxItem(
                                    value: 'hcm',
                                    searchText: 'Hồ Chí Minh',
                                    child: Text('Hồ Chí Minh'),
                                  ),
                                  VComboboxItem(
                                    value: 'hn',
                                    searchText: 'Hà Nội',
                                    child: Text('Hà Nội'),
                                  ),
                                  VComboboxItem(
                                    value: 'dn',
                                    searchText: 'Đà Nẵng',
                                    child: Text('Đà Nẵng'),
                                  ),
                                  VComboboxItem(
                                    value: 'hp',
                                    searchText: 'Hải Phòng',
                                    child: Text('Hải Phòng'),
                                  ),
                                  VComboboxItem(
                                    value: 'ct',
                                    searchText: 'Cần Thơ',
                                    child: Text('Cần Thơ'),
                                  ),
                                  VComboboxItem(
                                    value: 'bd',
                                    searchText: 'Bình Dương',
                                    child: Text('Bình Dương'),
                                  ),
                                  VComboboxItem(
                                    value: 'dna',
                                    searchText: 'Đồng Nai',
                                    child: Text('Đồng Nai'),
                                  ),
                                ],
                              ),
                            ),
                            const VComboboxInput(hintText: 'Tìm tỉnh/thành...'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              PreviewStateRow(
                label: 'Disabled',
                child: VField(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const VFieldLabel('Tỉnh/Thành'),
                      VCombobox<String>(
                        value: 'hcm',
                        enabled: false,
                        displayTextForValue: (v) =>
                            v == 'hcm' ? 'Hồ Chí Minh' : '',
                        onChanged: (_) {},
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            VComboboxContent(
                              child: VComboboxList(
                                children: const [
                                  VComboboxItem(
                                    value: 'hcm',
                                    searchText: 'Hồ Chí Minh',
                                    child: Text('Hồ Chí Minh'),
                                  ),
                                ],
                              ),
                            ),
                            const VComboboxInput(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const PreviewStateRow(
                label: 'Empty overlay',
                child: VComboboxEmpty(),
              ),
              PreviewStateRow(
                label: 'Compose · plain text',
                child: _ComposePlainCombobox(
                  value: _plainUnit,
                  onChanged: (v) => setState(() => _plainUnit = v),
                ),
              ),
              PreviewStateRow(
                label: 'Compose · 2-line',
                child: _ComposeTwoLineCombobox(
                  value: _twoLineUnit,
                  onChanged: (v) => setState(() => _twoLineUnit = v),
                ),
              ),
              PreviewStateRow(
                label: 'Compose · VCard',
                child: _ComposeCardCombobox(
                  value: _cardUnit,
                  onChanged: (v) => setState(() => _cardUnit = v),
                ),
              ),
              PreviewStateRow(
                label: 'Compose · searchText alias',
                child: _ComposeAliasCombobox(
                  value: _aliasUnit,
                  onChanged: (v) => setState(() => _aliasUnit = v),
                ),
              ),
              PreviewStateRow(
                label: 'Compose · skeleton loading',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _ComposeSkeletonCombobox(
                      loading: _skeletonDemoLoading,
                      value: _skeletonDemoUnit,
                      onChanged: (v) => setState(() => _skeletonDemoUnit = v),
                    ),
                    const SizedBox(height: VSpacing.space2),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: VButton(
                        label: _skeletonDemoLoading ? 'Load xong' : 'Reload skeleton',
                        size: VButtonSize.small,
                        onPressed: () {
                          setState(() {
                            if (_skeletonDemoLoading) {
                              _skeletonDemoLoading = false;
                            } else {
                              _skeletonDemoLoading = true;
                              _skeletonDemoUnit = null;
                            }
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const PreviewStateRow(
                label: 'Compose · create (Footer)',
                child: _ComposeCreateCombobox(),
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

class _ComposePlainCombobox extends StatelessWidget {
  const _ComposePlainCombobox({
    required this.value,
    required this.onChanged,
  });

  final String? value;
  final ValueChanged<String?> onChanged;

  static const _labels = <String, String>{
    'chai': 'Chai',
    'hop': 'Hộp',
    'lo': 'Lọ',
    'ong': 'Ống',
    'goi': 'Gói',
    'tui': 'Túi',
    'vi': 'Vỉ',
    'thung': 'Thùng',
  };

  @override
  Widget build(BuildContext context) {
    return VCombobox<String>(
      value: value,
      onChanged: onChanged,
      displayTextForValue: (v) => _labels[v] ?? '',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          VComboboxContent(
            child: VComboboxList(
              children: [
                for (final entry in _labels.entries)
                  VComboboxItem<String>(
                    value: entry.key,
                    child: Text(entry.value),
                  ),
              ],
            ),
          ),
          const VComboboxInput(hintText: 'Chọn đơn vị (text)...'),
        ],
      ),
    );
  }
}

class _ComposeTwoLineCombobox extends StatelessWidget {
  const _ComposeTwoLineCombobox({
    required this.value,
    required this.onChanged,
  });

  final String? value;
  final ValueChanged<String?> onChanged;

  static const _items = <({String id, String title, String subtitle})>[
    (id: 'hop', title: 'Hộp', subtitle: 'Đơn vị cơ sở'),
    (id: 'lo', title: 'Lọ', subtitle: 'Dung dịch / tiêm'),
    (id: 'chai', title: 'Chai', subtitle: 'Siêu thị / OTC'),
    (id: 'ong', title: 'Ống', subtitle: 'Ampoule'),
    (id: 'goi', title: 'Gói', subtitle: 'Gói đơn'),
    (id: 'vi', title: 'Vỉ', subtitle: 'Vỉ 10 viên'),
    (id: 'tui', title: 'Túi', subtitle: 'Túi truyền'),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    return VCombobox<String>(
      value: value,
      onChanged: onChanged,
      displayTextForValue: (v) {
        for (final item in _items) {
          if (item.id == v) return item.title;
        }
        return '';
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          VComboboxContent(
            child: VComboboxList(
              children: [
                for (final item in _items)
                  VComboboxItem<String>(
                    value: item.id,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          item.title,
                          style: VTypography.bodyDefault.copyWith(
                            color: colors.textPrimary,
                          ),
                        ),
                        Text(
                          item.subtitle,
                          style: VTypography.bodySmall.copyWith(
                            color: colors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const VComboboxInput(hintText: 'Chọn đơn vị (2 dòng)...'),
        ],
      ),
    );
  }
}

class _ComposeCardCombobox extends StatelessWidget {
  const _ComposeCardCombobox({
    required this.value,
    required this.onChanged,
  });

  final String? value;
  final ValueChanged<String?> onChanged;

  static const _items = <({String id, String title, String subtitle, IconData icon})>[
    (id: 'thung', title: 'Thùng', subtitle: 'Đóng gói lớn', icon: Icons.warehouse_outlined),
    (id: 'pallet', title: 'Pallet', subtitle: 'Kho trung tâm', icon: Icons.grid_view_outlined),
    (id: 'carton', title: 'Carton', subtitle: 'Thùng giấy', icon: Icons.inventory_2_outlined),
    (id: 'crate', title: 'Crate', subtitle: 'Khay nhựa', icon: Icons.view_module_outlined),
    (id: 'bag', title: 'Bao', subtitle: 'Bao 25kg', icon: Icons.shopping_bag_outlined),
    (id: 'drum', title: 'Phuy', subtitle: 'Phuy 200L', icon: Icons.propane_tank_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    return VCombobox<String>(
      value: value,
      onChanged: onChanged,
      displayTextForValue: (v) {
        for (final item in _items) {
          if (item.id == v) return item.title;
        }
        return '';
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          VComboboxContent(
            child: VComboboxList(
              children: [
                for (final item in _items)
                  VComboboxItem<String>(
                    value: item.id,
                    child: VCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: VSpacing.space2,
                        vertical: VSpacing.space1,
                      ),
                      child: Row(
                        children: [
                          Icon(item.icon, size: 22, color: colors.textMuted),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  item.title,
                                  style: VTypography.bodyDefault.copyWith(
                                    color: colors.textPrimary,
                                  ),
                                ),
                                Text(
                                  item.subtitle,
                                  style: VTypography.bodySmall.copyWith(
                                    color: colors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const VComboboxInput(hintText: 'Chọn đóng gói (VCard)...'),
        ],
      ),
    );
  }
}

class _ComposeAliasCombobox extends StatelessWidget {
  const _ComposeAliasCombobox({
    required this.value,
    required this.onChanged,
  });

  final String? value;
  final ValueChanged<String?> onChanged;

  static const _items = <({String id, String label, String searchText})>[
    (id: 'hop', label: 'Hộp', searchText: 'hop box carton goi nho'),
    (id: 'chai', label: 'Chai', searchText: 'chai bottle lo thuy tinh'),
    (id: 'kg', label: 'Kilogram', searchText: 'kg kilogram can nang'),
    (id: 'g', label: 'Gram', searchText: 'g gram trong luong'),
    (id: 'ml', label: 'Millilit', searchText: 'ml milliliter the tich'),
    (id: 'l', label: 'Lít', searchText: 'lit liter dung tich'),
    (id: 'vien', label: 'Viên', searchText: 'vien tablet pill'),
  ];

  @override
  Widget build(BuildContext context) {
    return VCombobox<String>(
      value: value,
      onChanged: onChanged,
      displayTextForValue: (v) {
        for (final item in _items) {
          if (item.id == v) return item.label;
        }
        return '';
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          VComboboxContent(
            child: VComboboxList(
              children: [
                for (final item in _items)
                  VComboboxItem<String>(
                    value: item.id,
                    searchText: item.searchText,
                    child: Text(item.label),
                  ),
              ],
            ),
          ),
          const VComboboxInput(hintText: 'Thử gõ alias: box, kg, pill...'),
        ],
      ),
    );
  }
}

class _ComposeSkeletonCombobox extends StatelessWidget {
  const _ComposeSkeletonCombobox({
    required this.loading,
    required this.value,
    required this.onChanged,
  });

  final bool loading;
  final String? value;
  final ValueChanged<String?> onChanged;

  static const _loaded = <String, String>{
    'hop': 'Hộp',
    'chai': 'Chai',
    'lo': 'Lọ',
    'ong': 'Ống',
    'goi': 'Gói',
    'thung': 'Thùng',
  };

  @override
  Widget build(BuildContext context) {
    return VCombobox<String>(
      value: loading ? null : value,
      onChanged: loading ? null : onChanged,
      displayTextForValue: (v) => _loaded[v] ?? '',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          VComboboxContent(
            child: VComboboxList(
              children: [
                if (loading)
                  for (var i = 0; i < 5; i++)
                    VComboboxItem<String>(
                      value: 'skel_$i',
                      enabled: false,
                      child: const _ComboboxSkeletonRow(),
                    )
                else
                  for (final entry in _loaded.entries)
                    VComboboxItem<String>(
                      value: entry.key,
                      child: Text(entry.value),
                    ),
              ],
            ),
          ),
          VComboboxInput(
            hintText: loading ? 'Đang tải đơn vị...' : 'Chọn đơn vị...',
          ),
        ],
      ),
    );
  }
}

class _ComboboxSkeletonRow extends StatelessWidget {
  const _ComboboxSkeletonRow();

  @override
  Widget build(BuildContext context) {
    return const VSkeletonScope(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: VSpacing.space1),
        child: Row(
          children: [
            VSkeleton.circle(size: 28),
            SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  VSkeleton(width: double.infinity, height: 14),
                  SizedBox(height: 6),
                  VSkeleton(width: 96, height: 10),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Demo: gõ tên mới → Footer «Thêm …» giả lập API rồi append item (menu giữ mở).
class _ComposeCreateCombobox extends StatefulWidget {
  const _ComposeCreateCombobox();

  @override
  State<_ComposeCreateCombobox> createState() => _ComposeCreateComboboxState();
}

class _ComposeCreateComboboxState extends State<_ComposeCreateCombobox> {
  String? _value;
  late List<({String id, String label})> _items;
  bool _creating = false;
  String? _pendingLabel;

  @override
  void initState() {
    super.initState();
    _items = [
      (id: 'hop', label: 'Hộp'),
      (id: 'chai', label: 'Chai'),
      (id: 'lo', label: 'Lọ'),
      (id: 'goi', label: 'Gói'),
      (id: 'thung', label: 'Thùng'),
    ];
  }

  String _labelFor(String? id) {
    if (id == null) return '';
    for (final item in _items) {
      if (item.id == id) return item.label;
    }
    return '';
  }

  ({String id, String label})? _findByLabel(String label) {
    final needle = label.trim().toLowerCase();
    if (needle.isEmpty) return null;
    for (final item in _items) {
      if (item.label.toLowerCase() == needle) return item;
    }
    return null;
  }

  Future<void> _createOrSelect(VComboboxController root) async {
    final typed = root.query.trim();
    if (typed.isEmpty || _creating) return;

    final existing = _findByLabel(typed);
    if (existing != null) {
      root.select(existing.id);
      return;
    }

    setState(() {
      _creating = true;
      _pendingLabel = typed;
    });

    // Simulate create-unit API round-trip.
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;

    final id = 'custom_${DateTime.now().microsecondsSinceEpoch}';
    setState(() {
      _items = [..._items, (id: id, label: typed)];
      _value = id;
      _creating = false;
      _pendingLabel = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return VCombobox<String>(
      value: _value,
      onChanged: (v) => setState(() => _value = v),
      displayTextForValue: _labelFor,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          VComboboxContent(
            footer: VComboboxFooter(
              child: Icon(
                Icons.add,
                size: 16,
                color: context.vColors.textPrimary,
              ),
              builder: (context, child, root) {
                return ListenableBuilder(
                  listenable: root,
                  child: child,
                  builder: (context, child) {
                    final typed = root.query.trim();
                    final canCreate = !_creating &&
                        typed.isNotEmpty &&
                        _findByLabel(typed) == null;
                    return VButton(
                      label: _creating
                          ? 'Đang tạo "${_pendingLabel ?? typed}"…'
                          : canCreate
                              ? 'Thêm "$typed"'
                              : 'Gõ tên mới để thêm',
                      variant: VButtonVariant.secondary,
                      leadingIcon: _creating ? null : child,
                      isLoading: _creating,
                      enabled: canCreate || _creating,
                      onPressed:
                          canCreate ? () => _createOrSelect(root) : null,
                    );
                  },
                );
              },
            ),
            child: VComboboxList(
              children: [
                for (final item in _items)
                  VComboboxItem<String>(
                    value: item.id,
                    child: Text(item.label),
                  ),
                if (_creating)
                  VComboboxItem<String>(
                    value: '__creating__',
                    searchText: _pendingLabel,
                    enabled: false,
                    child: const _ComboboxSkeletonRow(),
                  ),
              ],
            ),
          ),
          const VComboboxInput(hintText: 'Tìm hoặc tạo đơn vị...'),
        ],
      ),
    );
  }
}
