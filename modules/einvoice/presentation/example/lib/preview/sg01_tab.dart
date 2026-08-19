import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_einvoice_application/testing.dart';
import 'package:vet45_einvoice_presentation/presentation.dart';
import 'package:vet45_shared_testing/shared_testing.dart';

import 'preview_helpers.dart';
import 'preview_section.dart';

class EInvoiceSg01Tab extends StatelessWidget {
  const EInvoiceSg01Tab({super.key});

  @override
  Widget build(BuildContext context) {
    return previewList([
      const PreviewSection(
        title: 'SG01-D01 — Tổng quan — Chưa sẵn sàng',
        description:
            'EP-01 / Slice S1 · FakeEInvoiceScenario.configReadinessBlocked',
        child: PreviewEmbedFrame(
          height: 560,
          child: _OverviewPreview(
            scenario: FakeEInvoiceScenario.configReadinessBlocked,
          ),
        ),
      ),
      const PreviewSection(
        title: 'SG01-D02 — Tổng quan — Sẵn sàng',
        description:
            'EP-01 / Slice S1 · FakeEInvoiceScenario.configReadinessReady',
        child: PreviewEmbedFrame(
          height: 560,
          child: _OverviewPreview(
            scenario: FakeEInvoiceScenario.configReadinessReady,
          ),
        ),
      ),
      const PreviewSection(
        title: 'SG01-D04-A — Kết nối MISA — Chưa kết nối',
        description:
            'EP-01 / Slice S1 · FakeEInvoiceScenario.connectionScreenDisconnected',
        child: PreviewEmbedFrame(
          height: 620,
          child: _ConnectionPreview(
            scenario: FakeEInvoiceScenario.connectionScreenDisconnected,
          ),
        ),
      ),
      const PreviewSection(
        title: 'SG01-D04-B — Kết nối MISA — Đã kết nối',
        description:
            'EP-01 / Slice S1 · FakeEInvoiceScenario.configReadinessReady',
        child: PreviewEmbedFrame(
          height: 560,
          child: _ConnectionPreview(
            scenario: FakeEInvoiceScenario.configReadinessReady,
          ),
        ),
      ),
      PreviewSection(
        title: 'SG01-O02 — Thao tác kết nối',
        description: 'Action sheet · showProviderConnectionActionSheet',
        child: PreviewActionButton(
          label: 'Mở thao tác kết nối',
          onPressed: () => showProviderConnectionActionSheet(context),
        ),
      ),
      PreviewSection(
        title: 'SG01-O01 — Xác nhận ngắt kết nối',
        description: 'Centered VConfirmDialog · showDisconnectProviderSheet',
        child: PreviewActionButton(
          label: 'Mở xác nhận ngắt kết nối',
          onPressed: () => showDisconnectProviderSheet(context),
        ),
      ),
      const PreviewSection(
        title: 'SG01-D05 — Cấu hình phát hành mặc định',
        description: 'EP-01 / Slice S1 · FakeEInvoiceScenario.listTemplatesOk',
        child: PreviewEmbedFrame(
          height: 620,
          child: _IssuancePreview(
            scenario: FakeEInvoiceScenario.listTemplatesOk,
          ),
        ),
      ),
      const PreviewSection(
        title: 'SG01-D05 — Chưa chọn mẫu',
        description:
            'EP-01 / Slice S1 · FakeEInvoiceScenario.configReadinessBlocked',
        child: PreviewEmbedFrame(
          height: 560,
          child: _IssuancePreview(
            scenario: FakeEInvoiceScenario.configReadinessBlocked,
          ),
        ),
      ),
      const PreviewSection(
        title: 'SG01-D06 — Chính sách tự động',
        description:
            'EP-01 / Slice S1 · FakeEInvoiceScenario.automationPolicyOk',
        child: PreviewEmbedFrame(
          height: 520,
          child: _AutomationPreview(
            scenario: FakeEInvoiceScenario.automationPolicyOk,
          ),
        ),
      ),
      const PreviewSection(
        title: 'SG01-S01 — Không có quyền',
        description:
            'EP-01 / Slice S1 · FakeEInvoiceScenario.connectPermissionDenied',
        child: PreviewEmbedFrame(
          height: 420,
          child: _OverviewPreview(
            scenario: FakeEInvoiceScenario.connectPermissionDenied,
          ),
        ),
      ),
      const PreviewSection(
        title: 'SG01-S02 — Không tải được thiết lập',
        description:
            'EP-01 / Slice S1 · FakeEInvoiceScenario.configurationLoadFailure',
        child: PreviewEmbedFrame(
          height: 420,
          child: _OverviewPreview(
            scenario: FakeEInvoiceScenario.configurationLoadFailure,
          ),
        ),
      ),
    ]);
  }
}

class _OverviewPreview extends StatelessWidget {
  const _OverviewPreview({required this.scenario});

  final FakeEInvoiceScenario scenario;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => EInvoiceConfigurationOverviewCubit(
        einvoiceModule: FakeEInvoiceModule(scenario: scenario),
        executionContext: FakeExecutionContext(),
      )..load(),
      child: VPageScaffold(
        title: 'Hóa đơn điện tử',
        showBackButton: true,
        leading: previewScaffoldBackButton(context),
        body: EInvoiceConfigurationOverviewView(
          onConnectionTap: previewNoop,
          onIssuanceTap: previewNoop,
          onAutomationTap: previewNoop,
          onBack: previewNoop,
        ),
      ),
    );
  }
}

class _ConnectionPreview extends StatelessWidget {
  const _ConnectionPreview({required this.scenario});

  final FakeEInvoiceScenario scenario;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ProviderConnectionCubit(
        einvoiceModule: FakeEInvoiceModule(scenario: scenario),
        executionContext: FakeExecutionContext(),
      )..load(),
      child: VPageScaffold(
        title: ProviderConnectionCopy.pageTitle,
        showBackButton: true,
        leading: previewScaffoldBackButton(context),
        body: const ProviderConnectionView(
          onCancel: previewNoop,
          onBack: previewNoop,
        ),
      ),
    );
  }
}

class _IssuancePreview extends StatelessWidget {
  const _IssuancePreview({required this.scenario});

  final FakeEInvoiceScenario scenario;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => DefaultIssuanceConfigurationCubit(
        einvoiceModule: FakeEInvoiceModule(scenario: scenario),
        executionContext: FakeExecutionContext(),
      )..load(),
      child: VPageScaffold(
        title: DefaultIssuanceConfigurationCopy.pageTitle,
        showBackButton: true,
        leading: previewScaffoldBackButton(context),
        body: const DefaultIssuanceConfigurationView(
          onCancel: previewNoop,
          onBack: previewNoop,
        ),
      ),
    );
  }
}

class _AutomationPreview extends StatelessWidget {
  const _AutomationPreview({required this.scenario});

  final FakeEInvoiceScenario scenario;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AutomationPolicyCubit(
        einvoiceModule: FakeEInvoiceModule(scenario: scenario),
        executionContext: FakeExecutionContext(),
      )..load(),
      child: VPageScaffold(
        title: AutomationPolicyCopy.pageTitle,
        showBackButton: true,
        leading: previewScaffoldBackButton(context),
        body: const AutomationPolicyView(
          onCancel: previewNoop,
          onBack: previewNoop,
        ),
      ),
    );
  }
}
