import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';

import '../models/user_ui_model.dart';
import 'organization_invitation_detail_page.dart';

/// Trang Mời thành viên (TA-D-03).
class OrganizationInviteMemberPage extends StatefulWidget {
  const OrganizationInviteMemberPage({super.key});

  @override
  State<OrganizationInviteMemberPage> createState() => _OrganizationInviteMemberPageState();
}

class _OrganizationInviteMemberPageState extends State<OrganizationInviteMemberPage> {
  late final TextEditingController _emailController;
  String? _selectedRole = 'Nhân viên bán hàng';
  String? _emailError;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _emailController.addListener(_onEmailChanged);
  }

  void _onEmailChanged() {
    if (_emailController.text.trim().isNotEmpty && _emailError != null) {
      setState(() {
        _emailError = null;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _submitInvitation() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() {
        _emailError = 'Vui lòng nhập đúng địa chỉ email.';
      });
      VToast.show(
        context,
        title: 'Thiếu thông tin',
        message: 'Vui lòng nhập địa chỉ email hợp lệ.',
        type: VToastType.danger,
      );
      return;
    }

    final newInvitation = InvitationUiModel(
      id: 'inv-new',
      email: email,
      role: _selectedRole ?? 'Nhân viên bán hàng',
      status: InvitationStatus.pending,
      statusDetail: '${_selectedRole ?? 'Nhân viên bán hàng'} · Hết hạn sau 7 ngày',
    );

    VToast.show(
      context,
      title: 'Đã gửi lời mời thành công.',
      message: '',
      type: VToastType.success,
    );

    dynamic result;
    try {
      result = await context.push('/more/users/invitation-detail', extra: newInvitation);
    } catch (_) {
      result = await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => OrganizationInvitationDetailPage(invitation: newInvitation),
        ),
      );
    }

    if (mounted) {
      if (result == true) {
        try {
          context.pop(true);
        } catch (_) {
          Navigator.of(context).pop(true);
        }
      } else {
        try {
          context.pop();
        } catch (_) {
          Navigator.of(context).pop();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return VPageScaffold(
      title: 'Mời thành viên',
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
                label: 'Gửi lời mời',
                variant: VButtonVariant.primary,
                tone: VComponentTone.success,
                fullWidth: true,
                onPressed: _submitInvitation,
              ),
            ),
          ],
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.translucent,
        child: ListView(
          padding: const EdgeInsets.all(VSpacing.screenMobile),
          children: [
            VText(
              'Người nhận phải đăng nhập đúng email. Lời mời sẽ hết hạn sau 7 ngày.',
              variant: VTextVariant.bodySmall,
              color: colors.textSecondary,
            ),
            const VGap.md(),

            // Field 1: Email *
            VTextField(
              label: 'Email',
              isRequired: true,
              hintText: 'nhanvien@minhphat.vn',
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              helperText: 'Người nhận phải đăng nhập đúng email.',
              errorText: _emailError,
              tone: _emailError != null ? VComponentTone.danger : VComponentTone.neutral,
            ),
            const VGap.md(),

            // Field 2: Vai trò ban đầu *
            VDropdown<String>(
              label: 'Vai trò ban đầu',
              hintText: 'Chọn vai trò',
              value: _selectedRole,
              items: const [
                DropdownMenuItem(value: 'Nhân viên bán hàng', child: VText('Nhân viên bán hàng')),
                DropdownMenuItem(value: 'Thủ kho', child: VText('Thủ kho')),
                DropdownMenuItem(value: 'Kế toán', child: VText('Kế toán')),
                DropdownMenuItem(value: 'Quản lý', child: VText('Quản lý')),
              ],
              onChanged: (val) {
                setState(() => _selectedRole = val);
              },
            ),
            const VGap.xs(),
            VText(
              'Vai trò có thể thay đổi sau khi tham gia.',
              variant: VTextVariant.bodySmall,
              color: colors.textSecondary,
            ),
            const VGap.md(),
          ],
        ),
      ),
    );
  }
}
