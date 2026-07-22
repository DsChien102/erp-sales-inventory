import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

import '../data/vn_administrative_units_loader.dart';
import '../mock/organization_profile_mock_data.dart';
import '../models/organization_profile_ui_model.dart';
import '../../organizations/widgets/organization_empty_view.dart';

/// Trang Chỉnh thông tin tổ chức (TA-D-02).
class OrganizationEditProfilePage extends StatefulWidget {
  final OrganizationProfileUiModel profile;
  final bool hasPermission;

  const OrganizationEditProfilePage({
    super.key,
    this.profile = OrganizationProfileMockData.sampleProfile,
    this.hasPermission = true,
  });

  @override
  State<OrganizationEditProfilePage> createState() => _OrganizationEditProfilePageState();
}

class _OrganizationEditProfilePageState extends State<OrganizationEditProfilePage> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _addressController;
  late final Future<List<VnAdministrativeUnit>> _unitsFuture = VnAdministrativeUnitsLoader.load();

  String? _selectedCity = 'Đồng Nai';
  String? _selectedWard = 'Trấn Biên';

  VnAdministrativeUnit? _findProvince(
    List<VnAdministrativeUnit> units,
    String? name,
  ) {
    if (name == null || name.isEmpty) return null;
    for (final unit in units) {
      if (unit.fullName == name ||
          unit.fullName.endsWith(name) ||
          name.endsWith(unit.fullName)) {
        return unit;
      }
    }
    return null;
  }

  VnWard? _findWard(
    List<VnWard> wards,
    String? name,
  ) {
    if (name == null || name.isEmpty) return null;
    for (final ward in wards) {
      if (ward.fullName == name ||
          ward.fullName.endsWith(name) ||
          name.endsWith(ward.fullName)) {
        return ward;
      }
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.name);
    _phoneController = TextEditingController(text: widget.profile.phone);
    _emailController = TextEditingController(text: widget.profile.email);
    _addressController = TextEditingController(text: '125 Phạm Văn Thuận');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _saveChanges() {
    VToast.show(
      context,
      title: 'Đã lưu thay đổi',
      message: 'Thông tin tổ chức đã được cập nhật thành công.',
      type: VToastType.success,
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.hasPermission) {
      return VPageScaffold(
        title: 'Chỉnh thông tin tổ chức',
        body: OrganizationEmptyView(
          type: OrganizationEmptyStateType.unauthorized,
          onAction: () => Navigator.of(context).pop(),
        ),
      );
    }

    final colors = context.vColors;

    return VPageScaffold(
      title: 'Chỉnh thông tin tổ chức',
      bottomBar: Padding(
        padding: const EdgeInsets.all(VSpacing.screenMobile),
        child: Row(
          children: [
            Expanded(
              child: VButton(
                label: 'Hủy',
                variant: VButtonVariant.outline,
                fullWidth: true,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            const VGap.horizontalSm(),
            Expanded(
              child: VButton(
                label: 'Lưu thay đổi',
                variant: VButtonVariant.primary,
                tone: VComponentTone.success,
                fullWidth: true,
                onPressed: _saveChanges,
              ),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(VSpacing.screenMobile),
        children: [
          VText(
            'Thông tin liên hệ này độc lập với hồ sơ pháp lý và chứng từ đã phát hành.',
            variant: VTextVariant.bodySmall,
            color: colors.textSecondary,
          ),
          const VGap.md(),

          // Field 1: Tên tổ chức *
          VTextField(
            label: 'Tên tổ chức',
            isRequired: true,
            controller: _nameController,
            helperText: 'Tên hiển thị.',
          ),
          const VGap.md(),

          // Field 2: Số điện thoại
          VTextField(
            label: 'Số điện thoại',
            controller: _phoneController,
            keyboardType: TextInputType.phone,
          ),
          const VGap.md(),

          // Field 3: Email liên hệ
          VTextField(
            label: 'Email liên hệ',
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
          ),
          const VGap.md(),

          // Field 4: Địa chỉ liên hệ
          VTextField(
            label: 'Địa chỉ liên hệ',
            controller: _addressController,
          ),
          const VGap.md(),

          // Field 5 & 6: Tỉnh / thành phố & Xã / phường
          FutureBuilder<List<VnAdministrativeUnit>>(
            future: _unitsFuture,
            builder: (context, snapshot) {
              final units = snapshot.data ?? const [];
              final selectedProvince = _findProvince(units, _selectedCity);
              final provinceItems = units.isNotEmpty
                  ? units
                      .map((u) => DropdownMenuItem<String>(
                            value: u.fullName,
                            child: VText(u.fullName),
                          ))
                      .toList(growable: false)
                  : [
                      if (_selectedCity != null)
                        DropdownMenuItem<String>(
                          value: _selectedCity,
                          child: VText(_selectedCity!),
                        ),
                    ];

              final wardList = selectedProvince?.wards ?? const <VnWard>[];
              final wardItems = wardList.isNotEmpty
                  ? wardList
                      .map((w) => DropdownMenuItem<String>(
                            value: w.fullName,
                            child: VText(w.fullName),
                          ))
                      .toList(growable: false)
                  : [
                      if (_selectedWard != null)
                        DropdownMenuItem<String>(
                          value: _selectedWard,
                          child: VText(_selectedWard!),
                        ),
                    ];

              final effectiveCity = provinceItems.any((item) => item.value == _selectedCity)
                  ? _selectedCity
                  : (selectedProvince?.fullName ?? _selectedCity);

              final effectiveWard = wardItems.any((item) => item.value == _selectedWard)
                  ? _selectedWard
                  : (_findWard(wardList, _selectedWard)?.fullName ?? _selectedWard);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  VDropdown<String>(
                    label: 'Tỉnh / thành phố',
                    hintText: 'Chọn tỉnh / thành phố',
                    value: effectiveCity,
                    items: provinceItems,
                    onChanged: (val) {
                      setState(() {
                        _selectedCity = val;
                        _selectedWard = null;
                      });
                    },
                  ),
                  const VGap.md(),
                  VDropdown<String>(
                    label: 'Xã / phường',
                    hintText: _selectedCity != null && _selectedCity!.isNotEmpty
                        ? 'Chọn xã / phường'
                        : 'Chọn tỉnh / thành phố trước',
                    enabled: _selectedCity != null && _selectedCity!.isNotEmpty,
                    value: effectiveWard,
                    items: wardItems,
                    onChanged: (val) {
                      setState(() {
                        _selectedWard = val;
                      });
                    },
                  ),
                ],
              );
            },
          ),
          const VGap.md(),
        ],
      ),
    );
  }
}
