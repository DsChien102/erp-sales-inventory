import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

import 'preview_section.dart';

class TokensPreviewTab extends StatelessWidget {
  const TokensPreviewTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(VSpacing.screenMobile),
      children: [
        PreviewSection(
          title: 'Colors — Primary',
          child: _colorGrid([
            _tile('primary50', VColors.primary50, VColors.primary900),
            _tile('primary100', VColors.primary100, VColors.primary900),
            _tile('primary200', VColors.primary200, VColors.primary900),
            _tile('primary300', VColors.primary300, VColors.primary900),
            _tile('primary400', VColors.primary400, VColors.neutral0),
            _tile('primary500', VColors.primary500, VColors.neutral0),
            _tile('primary600', VColors.primary600, VColors.neutral0),
            _tile('primary700', VColors.primary700, VColors.neutral0),
            _tile('primary800', VColors.primary800, VColors.neutral0),
            _tile('primary900', VColors.primary900, VColors.neutral0),
          ]),
        ),
        PreviewSection(
          title: 'Colors — Neutrals',
          child: _colorGrid([
            _tile('neutral0', VColors.neutral0, VColors.neutral900),
            _tile('neutral50', VColors.neutral50, VColors.neutral900),
            _tile('neutral100', VColors.neutral100, VColors.neutral900),
            _tile('neutral200', VColors.neutral200, VColors.neutral900),
            _tile('neutral300', VColors.neutral300, VColors.neutral900),
            _tile('neutral400', VColors.neutral400, VColors.neutral900),
            _tile('neutral500', VColors.neutral500, VColors.neutral0),
            _tile('neutral600', VColors.neutral600, VColors.neutral0),
            _tile('neutral700', VColors.neutral700, VColors.neutral0),
            _tile('neutral900', VColors.neutral900, VColors.neutral0),
          ]),
        ),
        PreviewSection(
          title: 'Colors — Semantics',
          child: _colorGrid([
            _tile('success', VColors.success, VColors.neutral0),
            _tile('successBg', VColors.successBg, VColors.success),
            _tile('warning', VColors.warning, VColors.neutral0),
            _tile('warningBg', VColors.warningBg, VColors.warning),
            _tile('danger', VColors.danger, VColors.neutral0),
            _tile('dangerBg', VColors.dangerBg, VColors.danger),
            _tile('info', VColors.info, VColors.neutral0),
            _tile('infoBg', VColors.infoBg, VColors.info),
          ]),
        ),
        PreviewSection(
          title: 'Typography',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Display D1 — 40px', style: VTypography.displayD1),
              const Divider(height: VSpacing.space4),
              Text('Heading H1 — 28px', style: VTypography.headingH1),
              const Divider(height: VSpacing.space4),
              Text('Heading H2 — 22px', style: VTypography.headingH2),
              const Divider(height: VSpacing.space4),
              Text('Heading H3 — 18px', style: VTypography.headingH3),
              const Divider(height: VSpacing.space4),
              Text('Heading H4 — 16px', style: VTypography.headingH4),
              const Divider(height: VSpacing.space4),
              Text('Body Default — 14px', style: VTypography.bodyDefault),
              const Divider(height: VSpacing.space4),
              Text('Body Small — 13px', style: VTypography.bodySmall),
              const Divider(height: VSpacing.space4),
              Text('Caption — 12px', style: VTypography.caption),
              const Divider(height: VSpacing.space4),
              Text('Display D1 Mono — 40px', style: VTypography.displayD1Mono),
              const Divider(height: VSpacing.space4),
              Text('Heading H3 Mono — 18px', style: VTypography.headingH3Mono),
              const Divider(height: VSpacing.space4),
              Text('Heading H4 Mono — 14px', style: VTypography.headingH4Mono),
              const Divider(height: VSpacing.space4),
              Text('Body Default Mono — 14px', style: VTypography.bodyDefaultMono),
              const Divider(height: VSpacing.space4),
              Text('Body Small Mono — 13px', style: VTypography.bodySmallMono),
              const Divider(height: VSpacing.space4),
              Text('1234567890 (Inter)', style: VTypography.bodyDefault),
              Text('1234567890 (monoNumeric)', style: VTypography.monoNumeric),
            ],
          ),
        ),
        PreviewSection(
          title: 'Shadows',
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _shadowBox('e1 (Card)', VShadows.e1),
              _shadowBox('e2 (Hover)', VShadows.e2),
              _shadowBox('e3 (Popover)', VShadows.e3),
              _shadowBox('e4 (Modal)', VShadows.e4),
            ],
          ),
        ),
        PreviewSection(
          title: 'Radius & Spacing',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Radius Input: ${VRadius.input} px', style: VTypography.bodyDefault),
              Text('Radius Card: ${VRadius.card} px', style: VTypography.bodyDefault),
              Text('Radius Sheet: ${VRadius.sheet} px', style: VTypography.bodyDefault),
              const SizedBox(height: VSpacing.space3),
              Text('Screen padding mobile: ${VSpacing.screenMobile} px', style: VTypography.bodyDefault),
              Text('Screen padding tablet: ${VSpacing.screenTablet} px', style: VTypography.bodyDefault),
              Text('Screen padding desktop: ${VSpacing.screenDesktop} px', style: VTypography.bodyDefault),
              Text('Breakpoint tablet ≥ ${VBreakpoints.tablet}', style: VTypography.bodyDefault),
              Text('Breakpoint desktop ≥ ${VBreakpoints.desktop}', style: VTypography.bodyDefault),
              Text('Min touch: ${VSpacing.minTouchTarget} px', style: VTypography.bodyDefault),
            ],
          ),
        ),
        PreviewSection(
          title: 'Duration',
          description: 'Motion timing tokens (VDuration).',
          child: PreviewStateWrap(
            children: [
              _durationChip('fast', VDuration.fast),
              _durationChip('medium', VDuration.medium),
              _durationChip('normal', VDuration.normal),
              _durationChip('slow', VDuration.slow),
            ],
          ),
        ),
      ],
    );
  }

  Widget _colorGrid(List<Widget> children) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      // Wider than tall enough for name + hex without bottom overflow.
      childAspectRatio: 2.4,
      crossAxisSpacing: VSpacing.space2,
      mainAxisSpacing: VSpacing.space2,
      children: children,
    );
  }

  Widget _tile(String name, Color color, Color textColor) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(VRadius.r6),
        // ignore: deprecated_member_use
        border: Border.all(color: VColors.borderDefault),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: VSpacing.space2,
        vertical: VSpacing.space1,
      ),
      alignment: Alignment.center,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: VTypography.bodySmall.copyWith(
                color: textColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: VTypography.caption.copyWith(
                color: textColor.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _shadowBox(String label, List<BoxShadow> shadow) {
    return Container(
      width: 76,
      height: 76,
      decoration: BoxDecoration(
        // ignore: deprecated_member_use
        color: VColors.surface,
        borderRadius: BorderRadius.circular(VRadius.r8),
        boxShadow: shadow,
      ),
      padding: const EdgeInsets.all(VSpacing.space2),
      alignment: Alignment.center,
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: VTypography.caption.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _durationChip(String name, Duration duration) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: VSpacing.space3,
        vertical: VSpacing.space2,
      ),
      decoration: BoxDecoration(
        color: VColors.neutral100,
        borderRadius: BorderRadius.circular(VRadius.pill),
      ),
      child: Text(
        '$name · ${duration.inMilliseconds}ms',
        style: VTypography.bodySmall.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }
}
