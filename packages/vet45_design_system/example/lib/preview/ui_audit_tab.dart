import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

class UIAuditTab extends StatelessWidget {
  const UIAuditTab({super.key});

  /// Matches first public V* class from each audit entry + forms covered in example.
  static const Set<String> _exampleCoverage = {
    // Primitives
    'VBadge',
    'VChip',
    'VIcon',
    'VIconBox',
    'VText',
    // Components
    'VButton',
    'VCard',
    'VCheckbox',
    'VRadio',
    'VSwitch',
    'VFloatingActionButton',
    'VTextField',
    'VSearchBar',
    'VQuickActionButton',
    'VTabs',
    'VEmptyState',
    'VToast',
    'VDropdown',
    'VSearchableDropdown',
    'VCompactSearchableDropdown',
    'VQuantitySelector',
    'VDatePickerField',
    'VHomeHeader',
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
    // Business
    'VTodoItem',
    'VActivityItem',
    'VMetricCard',
    'VCreateOrderButton',
    'VRevenueCard',
    // Forms (tracked in example even if audit CLI skips forms)
    'VEmailField',
    'VMoneyField',
    'VNumberField',
    'VSelect',
    'VChoiceList',
  };

  @override
  Widget build(BuildContext context) {
    final rows = vComponentAuditEntries;
    final total = rows.length;
    final withSemantics = rows.where((e) => e.hasSemantics).length;
    final withTone = rows.where((e) => e.hasTone).length;
    final withState = rows.where((e) => e.hasState).length;
    final covered = rows.where((e) => _isCovered(e)).length;

    return ListView(
      padding: const EdgeInsets.all(VSpacing.screenMobile),
      children: [
        Text('Design System UI Audit', style: VTypography.headingH2),
        const SizedBox(height: VSpacing.space2),
        Text(
          'Rà soát coverage và readiness của component public. Forms được track trong example coverage.',
          style: VTypography.bodyDefault.copyWith(color: VColors.textSecondary),
        ),
        const SizedBox(height: VSpacing.space1),
        Text(
          'Snapshot: $vComponentAuditGeneratedAt',
          style: VTypography.caption.copyWith(color: VColors.textMuted),
        ),
        const SizedBox(height: VSpacing.space3),
        VCard(
          child: Wrap(
            spacing: VSpacing.space2,
            runSpacing: VSpacing.space2,
            children: [
              _metricChip('Tổng component', '$total'),
              _metricChip('Đã có demo', '$covered/$total'),
              _metricChip('Có Semantics', '$withSemantics/$total'),
              _metricChip('Có tone', '$withTone/$total'),
              _metricChip('Có state', '$withState/$total'),
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
              VTableHeader(title: 'Category'),
              VTableHeader(title: 'Example'),
              VTableHeader(title: 'Semantics'),
              VTableHeader(title: 'Tone'),
              VTableHeader(title: 'State'),
            ],
            rows: rows
                .map(
                  (e) => [
                    Text(_componentName(e)),
                    Text(_displayCategory(e.category)),
                    _statusBadge(_isCovered(e)),
                    _statusBadge(e.hasSemantics),
                    _statusBadge(e.hasTone),
                    _statusBadge(e.hasState),
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
              'Forms covered in example: ${_exampleCoverage.where((n) => n.contains('Field') || n == 'VSelect' || n == 'VChoiceList').join(', ')}',
        ),
      ],
    );
  }

  bool _isCovered(VComponentAuditEntry entry) {
    final name = _componentName(entry);
    if (_exampleCoverage.contains(name)) return true;
    // Nested helpers counted if parent is covered
    const aliases = {
      'VAppBarTitle': 'VAppBar',
      'VAppBarSubtitle': 'VAppBar',
      'VTableHeader': 'VTable',
      'VBottomNavigationItem': 'VBottomNavigationBar',
    };
    final parent = aliases[name];
    return parent != null && _exampleCoverage.contains(parent);
  }

  Widget _metricChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: VSpacing.space2,
        vertical: VSpacing.space1,
      ),
      decoration: BoxDecoration(
        color: VColors.neutral100,
        borderRadius: BorderRadius.circular(VRadius.pill),
      ),
      child: Text('$label: $value', style: VTypography.bodySmall),
    );
  }

  Widget _statusBadge(bool yes) {
    return VBadge(
      label: yes ? 'Yes' : 'No',
      status: yes ? VBadgeStatus.success : VBadgeStatus.draft,
      isSmall: true,
    );
  }

  String _componentName(VComponentAuditEntry entry) {
    final preferred = entry.classNames.where((name) => name.startsWith('V')).toList();
    if (preferred.isNotEmpty) return preferred.first;
    if (entry.classNames.isNotEmpty) return entry.classNames.first;
    return entry.exportPath.split('/').last;
  }

  String _displayCategory(String category) {
    if (category.isEmpty) return category;
    return '${category[0].toUpperCase()}${category.substring(1)}';
  }
}

class PreviewSectionNote extends StatelessWidget {
  const PreviewSectionNote({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: VTypography.caption.copyWith(color: VColors.textSecondary),
    );
  }
}
