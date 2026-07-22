import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_iam_application/application.dart';

class PlatformOnboardingStepOwner extends StatefulWidget {
  const PlatformOnboardingStepOwner({
    super.key,
    required this.isNewOwner,
    required this.selectedOwner,
    required this.lastNameController,
    required this.firstNameController,
    required this.emailController,
    required this.phoneController,
    required this.searchResults,
    required this.onOwnerSelected,
    required this.onToggleNewOwner,
    required this.onSearchQueryChanged,
  });

  final bool isNewOwner;
  final PlatformUserSummaryDto? selectedOwner;
  final TextEditingController lastNameController;
  final TextEditingController firstNameController;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final List<PlatformUserSummaryDto> searchResults;
  final ValueChanged<PlatformUserSummaryDto?> onOwnerSelected;
  final ValueChanged<bool> onToggleNewOwner;
  final ValueChanged<String> onSearchQueryChanged;

  @override
  State<PlatformOnboardingStepOwner> createState() => _PlatformOnboardingStepOwnerState();
}

class _PlatformOnboardingStepOwnerState extends State<PlatformOnboardingStepOwner> {
  late final FocusNode _searchFocusNode;
  late final TextEditingController _searchController;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _searchFocusNode = FocusNode();
    _searchController = TextEditingController();
    _searchFocusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (_searchFocusNode.hasFocus) {
      if (!_isSearching) {
        setState(() {
          _isSearching = true;
        });
      }
      if (_searchController.text.isNotEmpty) {
        _searchController.clear();
      }
      widget.onSearchQueryChanged('');
    }
  }

  @override
  void dispose() {
    _searchFocusNode.removeListener(_onFocusChange);
    _searchFocusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    // Trạng thái Tạo chủ sở hữu mới (PA-D-03)
    if (widget.isNewOwner) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          VTextFormField(
            controller: widget.lastNameController,
            label: 'Họ và tên đệm',
            isRequired: true,
            hintText: 'Nhập họ và tên đệm',
          ),
          const VGap.sm(),
          VTextFormField(
            controller: widget.firstNameController,
            label: 'Tên',
            isRequired: true,
            hintText: 'Nhập tên',
          ),
          const VGap.sm(),
          VTextFormField(
            controller: widget.emailController,
            label: 'Email',
            isRequired: true,
            hintText: 'Nhập email',
            keyboardType: TextInputType.emailAddress,
          ),
          const VGap.sm(),
          VTextFormField(
            controller: widget.phoneController,
            label: 'Số điện thoại',
            hintText: 'Nhập số điện thoại',
            helperText: 'Không bắt buộc',
            keyboardType: TextInputType.phone,
          ),
          const VGap.md(),
          VCard(
            backgroundColor: colors.surface,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                VText(
                  'Quy ước tài khoản',
                  variant: VTextVariant.bodyDefault,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const VGap.sm(),
                _buildConventionRow('Mật khẩu', 'Người dùng tự thiết lập', colors),
                const VGap.sm(),
                _buildConventionRow('Tư cách', 'Chủ sở hữu', colors),
                const VGap.sm(),
                _buildConventionRow('Vai trò mặc định', 'Chủ cửa hàng', colors),
              ],
            ),
          ),
        ],
      );
    }

    // Trạng thái Chọn / Đã chọn Chủ sở hữu (PA-D-02 Ảnh 1 & Dropdown Overlay)
    return TapRegion(
      onTapOutside: (_) {
        if (_isSearching) {
          _searchFocusNode.unfocus();
          setState(() {
            _isSearching = false;
          });
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          VSearchBar(
            hintText: 'Tìm tên hoặc email',
            focusNode: _searchFocusNode,
            controller: _searchController,
            onChanged: (query) {
              if (!_isSearching) {
                setState(() {
                  _isSearching = true;
                });
              }
              widget.onSearchQueryChanged(query);
            },
          ),
          const VGap.md(),

          // Dropdown List khi đang tìm kiếm (Inline trong Column để hit test toàn bộ item)
          if (_isSearching) ...[
            VCard(
              elevated: true,
              padding: const EdgeInsets.all(VSpacing.space2),
              backgroundColor: colors.surface,
              borderRadius: VRadius.r16,
              border: Border.all(
                color: colors.borderDefault,
                width: 1.5,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 260.0),
                child: widget.searchResults.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(VSpacing.space4),
                        child: Center(
                          child: VText(
                            'Không tìm thấy người dùng phù hợp.',
                            color: colors.textMuted,
                          ),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        itemCount: widget.searchResults.length,
                        separatorBuilder: (_, _) => const VGap.xs(),
                        itemBuilder: (context, index) {
                          final user = widget.searchResults[index];
                          final isSelected = widget.selectedOwner?.userId == user.userId;

                          return VCard(
                            padding: const EdgeInsets.symmetric(
                              horizontal: VSpacing.space3,
                              vertical: VSpacing.space2,
                            ),
                            backgroundColor: isSelected ? colors.surfaceBrand : colors.surface,
                            border: Border.all(
                              color: isSelected ? colors.primary : colors.borderDefault,
                              width: 1.5,
                            ),
                            borderRadius: VRadius.r12,
                            onTap: () {
                              widget.onOwnerSelected(user);
                              _searchController.clear();
                              _searchFocusNode.unfocus();
                              setState(() {
                                _isSearching = false;
                              });
                            },
                            child: Row(
                              children: [
                                VIcon(
                                  icon: VIcons.person,
                                  color: isSelected ? colors.primary : colors.textSecondary,
                                  size: 20,
                                ),
                                const VGap.horizontalSm(),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      VText(
                                        user.fullName,
                                        variant: VTextVariant.bodyDefault,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: colors.textPrimary,
                                        ),
                                      ),
                                      const VGap.xs(),
                                      VText(
                                        user.email,
                                        variant: VTextVariant.bodySmall,
                                        color: colors.textSecondary,
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected ? colors.primary : colors.borderDefault,
                                      width: isSelected ? 6.0 : 1.5,
                                    ),
                                    color: colors.surface,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ),
            const VGap.md(),
          ],

          // Nội dung hiển thị bên dưới ô VSearchBar khi KHÔNG ở chế độ mở dropdown overlay
          if (!_isSearching && widget.selectedOwner != null) ...[
            VText(
              'Người dùng đã chọn',
              variant: VTextVariant.bodyDefault,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const VGap.sm(),
            VCard(
              backgroundColor: colors.surfaceBrand,
              border: Border.all(
                color: colors.primary,
                width: 1.5,
              ),
              padding: const EdgeInsets.all(VSpacing.space4),
              borderRadius: VRadius.card,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  VText(
                    widget.selectedOwner!.fullName,
                    variant: VTextVariant.bodyDefault,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                  const VGap.xs(),
                  VText(
                    widget.selectedOwner!.email,
                    variant: VTextVariant.bodySmall,
                    color: colors.textSecondary,
                  ),
                  const VGap.xs(),
                  VText(
                    '0901 234 567',
                    variant: VTextVariant.bodySmall,
                    color: colors.textSecondary,
                  ),
                ],
              ),
            ),
            const VGap.xs(),
            VText(
              'Chọn người dùng khác sẽ thay thế lựa chọn hiện tại.',
              variant: VTextVariant.bodySmall,
              color: colors.textSecondary,
            ),
            const VGap.md(),
          ],

          if (!_isSearching)
            VButton(
              label: 'Tạo mới',
              variant: VButtonVariant.outline,
              fullWidth: true,
              onPressed: () => widget.onToggleNewOwner(true),
            ),
        ],
      ),
    );
  }

  Widget _buildConventionRow(String label, String value, VColorScheme colors) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        VText(
          label,
          variant: VTextVariant.bodySmall,
          color: colors.textSecondary,
        ),
        VText(
          value,
          variant: VTextVariant.bodySmall,
          color: colors.textPrimary,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
