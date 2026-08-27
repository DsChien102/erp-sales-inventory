import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

class UIAuditTab extends StatelessWidget {
  const UIAuditTab({super.key});

  /// Matches first public V* class from each audit entry + forms covered in example.
  static const Set<String> _exampleCoverage = {
    // Primitives
    'VBadge',
    'VChip',
    'VDivider',
    'VIcon',
    'VIconBox',
    'VSkeleton',
    'VText',
    // Foundation ambient
    'VComponentScope',
    // Components
    'VAvatar',
    'VButton',
    'VCard',
    'VCardHeader',
    'VCardTitle',
    'VCardIcon',
    'VCardAction',
    'VCardContent',
    'VCardFooter',
    'VCheckbox',
    'VRadio',
    'VSwitch',
    'VFloatingActionButton',
    'VTextField',
    'VVerificationCodeField',
    'VSearchBar',
    'VTabs',
    'VEmptyState',
    'VEmptyHeader',
    'VEmptyMedia',
    'VEmptyTitle',
    'VEmptyDescription',
    'VEmptyContent',
    'VBanner',
    'VFileDropZone',
    'VToast',
    'VLoading',
    'VSteps',
    'VProgress',
    'VCombobox',
    'VSegmentedControl',
    'VSwipeReveal',
    'VNumericKeypadSheet',
    'VBottomNavigationBar',
    'VConfirmDialog',
    'VBottomSheet',
    'VAppBar',
    'VTable',
    // Patterns (layout)
    'VGap',
    'VPagePadding',
    'VSection',
    'VPageScaffold',
    'VResponsive',
    'VResponsiveVisibility',
    'VContentWidth',
    'VResponsiveGrid',
    // Forms (tracked in example even if audit CLI skips forms)
    'VEmailField',
    'VPasswordField',
    'VMoneyField',
    'VNumberField',
    'VSelect',
    'VChoiceList',
    'VDatePicker',
  };

  @override
  Widget build(BuildContext context) {
    final rows = vComponentAuditEntries;
    final total = rows.length;
    final withSemantics = rows.where((e) => e.hasSemantics).length;
    final missingRequired = rows.where((e) => e.hasMissingRequired).length;
    final covered = rows.where((e) => _isCovered(e)).length;
    final colors = context.vColors;

    return ListView(
      padding: const EdgeInsets.all(VSpacing.screenMobile),
      children: [
        Text('Design System UI Audit', style: VTypography.headingH2),
        const SizedBox(height: VSpacing.space2),
        Text(
          'Contract matrix: docs/audit/contract_matrix.yaml — Pass / Missing / N/A / Pref↓',
          style: VTypography.bodyDefault.copyWith(color: colors.textSecondary),
        ),
        const SizedBox(height: VSpacing.space1),
        Text(
          'Snapshot: $vComponentAuditGeneratedAt',
          style: VTypography.caption.copyWith(color: colors.textMuted),
        ),
        const SizedBox(height: VSpacing.space3),
        VCard(
          child: Wrap(
            spacing: VSpacing.space2,
            runSpacing: VSpacing.space2,
            children: [
              _metricChip('Tổng component', '$total', colors.surfaceAlt),
              _metricChip('Đã có demo', '$covered/$total', colors.surfaceAlt),
              _metricChip('Có Semantics', '$withSemantics/$total', colors.surfaceAlt),
              _metricChip('Missing required', '$missingRequired', colors.surfaceAlt),
            ],
          ),
        ),
        const SizedBox(height: VSpacing.space3),
        VCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Regenerate audit', style: VTypography.headingH4),
              const SizedBox(height: VSpacing.space2),
              Text(
                'cd packages/vet45_design_system && dart run tool/component_audit.dart',
                style: VTypography.monoNumeric.copyWith(fontSize: 12),
              ),
              Text(
                'Fail CI: dart run tool/component_audit.dart --fail-on-required',
                style: VTypography.monoNumeric.copyWith(fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: VSpacing.space3),
        Text('Component matrix', style: VTypography.headingH3),
        const SizedBox(height: VSpacing.space2),
        VCard(
          padding: EdgeInsets.zero,
          child: VTable(
            headers: const [
              VTableHeader(title: 'Component'),
              VTableHeader(title: 'Role'),
              VTableHeader(title: 'Example'),
              VTableHeader(title: 'Tone'),
              VTableHeader(title: 'Emphasis'),
              VTableHeader(title: 'State'),
              VTableHeader(title: 'Label'),
            ],
            rows: rows
                .map(
                  (e) => [
                    Text(e.primaryClass),
                    Text(e.role),
                    _exampleBadge(_isCovered(e)),
                    _contractBadge(e.toneStatus),
                    _contractBadge(e.emphasisStatus),
                    _contractBadge(e.stateStatus),
                    _contractBadge(e.semanticLabelStatus),
                  ],
                )
                .toList(),
            stripedRows: true,
            semanticLabel: 'UI audit matrix',
          ),
        ),
        const SizedBox(height: VSpacing.space3),
        PreviewSectionNote(
          text:
              'Forms covered in example: ${_exampleCoverage.where((n) => n.contains('Field') || n == 'VSelect' || n == 'VChoiceList' || n == 'VDatePicker').join(', ')}',
        ),
      ],
    );
  }

  bool _isCovered(VComponentAuditEntry entry) {
    final name = entry.primaryClass;
    if (_exampleCoverage.contains(name)) return true;
    const aliases = {
      'VAppBarTitle': 'VAppBar',
      'VAppBarSubtitle': 'VAppBar',
      'VTableHeader': 'VTable',
      'VBottomNavigationItem': 'VBottomNavigationBar',
    };
    final parent = aliases[name];
    return parent != null && _exampleCoverage.contains(parent);
  }

  Widget _metricChip(String label, String value, Color background) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: VSpacing.space2,
        vertical: VSpacing.space1,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(VRadius.pill),
      ),
      child: Text('$label: $value', style: VTypography.bodySmall),
    );
  }

  Widget _exampleBadge(bool yes) {
    return VBadge(
      label: yes ? 'Yes' : 'No',
      status: yes ? VBadgeStatus.success : VBadgeStatus.draft,
      isSmall: true,
    );
  }

  Widget _contractBadge(String status) {
    final (label, badgeStatus) = switch (status) {
      'pass' => ('Pass', VBadgeStatus.success),
      'missing_required' => ('Missing', VBadgeStatus.danger),
      'missing_preferred' => ('Pref↓', VBadgeStatus.warning),
      'optional_absent' => ('—', VBadgeStatus.draft),
      'na' => ('N/A', VBadgeStatus.draft),
      'na_present' => ('N/A+', VBadgeStatus.info),
      _ => (status, VBadgeStatus.draft),
    };
    return VBadge(label: label, status: badgeStatus, isSmall: true);
  }
}

class PreviewSectionNote extends StatelessWidget {
  const PreviewSectionNote({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    return Text(
      text,
      style: VTypography.caption.copyWith(color: colors.textSecondary),
    );
  }
}
