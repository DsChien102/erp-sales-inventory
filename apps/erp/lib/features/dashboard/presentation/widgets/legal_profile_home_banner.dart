import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/session/session_controller.dart';
import '../../../../core/session/session_state.dart';
import '../../../iam/data/models/tenant_profile.dart';
import '../../../iam/data/organization_repository.dart';

/// Banner trang chủ khi chủ cửa hàng chưa có hồ sơ pháp lý.
class LegalProfileHomeBanner extends StatefulWidget {
  const LegalProfileHomeBanner({super.key, this.organizations, this.session});

  final OrganizationRepository? organizations;
  final SessionController? session;

  @override
  State<LegalProfileHomeBanner> createState() => _LegalProfileHomeBannerState();
}

class _LegalProfileHomeBannerState extends State<LegalProfileHomeBanner> {
  TenantProfile? _tenant;
  var _loaded = false;

  OrganizationRepository? get _organizations {
    final injected = widget.organizations;
    if (injected != null) return injected;
    if (!getIt.isRegistered<OrganizationRepository>()) return null;
    return getIt<OrganizationRepository>();
  }

  SessionController? get _session {
    final injected = widget.session;
    if (injected != null) return injected;
    if (!getIt.isRegistered<SessionController>()) return null;
    return getIt<SessionController>();
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final organizations = _organizations;
    if (organizations == null) return;
    try {
      final tenant = await organizations.getTenant();
      if (!mounted) return;
      setState(() {
        _tenant = tenant;
        _loaded = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loaded = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = _session;
    if (session == null) return const SizedBox.shrink();
    return BlocBuilder<SessionController, SessionState>(
      bloc: session,
      builder: (context, state) {
        if (!session.isOwner || state.legalProfileBannerDismissed) {
          return const SizedBox.shrink();
        }
        if (!_loaded || _tenant == null || _tenant!.legalProfile != null) {
          return const SizedBox.shrink();
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: VSpacing.space4),
          child: VBanner(
            key: const Key('legal_profile_home_banner'),
            title: 'Bổ sung hồ sơ pháp lý để xuất hoá đơn điện tử.',
            status: VBannerStatus.info,
            trailing: IconButton(
              key: const Key('legal_profile_banner_dismiss'),
              onPressed: session.dismissLegalProfileBanner,
              icon: Icon(Icons.close, color: context.vColors.textSecondary),
            ),
            footer: VButton(
              key: const Key('legal_profile_banner_add'),
              label: 'Bổ sung',
              variant: VButtonVariant.link,
              onPressed: () => context.push('/more/organization-profile/legal'),
            ),
          ),
        );
      },
    );
  }
}
