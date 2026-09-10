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
          title: 'Colors — Blue (info)',
          child: _colorGrid([
            _tile('blue50', VColors.blue50, VColors.blue900),
            _tile('blue100', VColors.blue100, VColors.blue900),
            _tile('blue200', VColors.blue200, VColors.blue900),
            _tile('blue300', VColors.blue300, VColors.blue900),
            _tile('blue400', VColors.blue400, VColors.neutral0),
            _tile('blue500', VColors.blue500, VColors.neutral0),
            _tile('blue600', VColors.blue600, VColors.neutral0),
            _tile('blue700', VColors.blue700, VColors.neutral0),
            _tile('blue800', VColors.blue800, VColors.neutral0),
            _tile('blue900', VColors.blue900, VColors.neutral0),
          ]),
        ),
        PreviewSection(
          title: 'Colors — Yellow (warning)',
          child: _colorGrid([
            _tile('yellow50', VColors.yellow50, VColors.yellow900),
            _tile('yellow100', VColors.yellow100, VColors.yellow900),
            _tile('yellow200', VColors.yellow200, VColors.yellow900),
            _tile('yellow300', VColors.yellow300, VColors.yellow900),
            _tile('yellow400', VColors.yellow400, VColors.yellow900),
            _tile('yellow500', VColors.yellow500, VColors.neutral0),
            _tile('yellow600', VColors.yellow600, VColors.neutral0),
            _tile('yellow700', VColors.yellow700, VColors.neutral0),
            _tile('yellow800', VColors.yellow800, VColors.neutral0),
            _tile('yellow900', VColors.yellow900, VColors.neutral0),
          ]),
        ),
        PreviewSection(
          title: 'Colors — Red (danger)',
          child: _colorGrid([
            _tile('red50', VColors.red50, VColors.red900),
            _tile('red100', VColors.red100, VColors.red900),
            _tile('red200', VColors.red200, VColors.red900),
            _tile('red300', VColors.red300, VColors.neutral0),
            _tile('red400', VColors.red400, VColors.neutral0),
            _tile('red500', VColors.red500, VColors.neutral0),
            _tile('red600', VColors.red600, VColors.neutral0),
            _tile('red700', VColors.red700, VColors.neutral0),
            _tile('red800', VColors.red800, VColors.neutral0),
            _tile('red900', VColors.red900, VColors.neutral0),
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
              Text('Label Default — 14px / 20', style: VTypography.labelDefault),
              const Divider(height: VSpacing.space4),
              Text('Label Small — 11px', style: VTypography.labelSmall),
              const Divider(height: VSpacing.space4),
              Text('Action Default — 14px / 20', style: VTypography.actionDefault),
              const Divider(height: VSpacing.space4),
              Text('Display D1 Mono — 40px', style: VTypography.displayD1Mono),
              const Divider(height: VSpacing.space4),
              Text('Heading H1 Mono — 28px', style: VTypography.headingH1Mono),
              const Divider(height: VSpacing.space4),
              Text('Heading H2 Mono — 22px', style: VTypography.headingH2Mono),
              const Divider(height: VSpacing.space4),
              Text('Heading H3 Mono — 18px', style: VTypography.headingH3Mono),
              const Divider(height: VSpacing.space4),
              Text('Heading H4 Mono — 14px', style: VTypography.headingH4Mono),
              const Divider(height: VSpacing.space4),
              Text('Body Default Mono — 14px', style: VTypography.bodyDefaultMono),
              const Divider(height: VSpacing.space4),
              Text('Body Small Mono — 13px', style: VTypography.bodySmallMono),
              const Divider(height: VSpacing.space4),
              Text('Label Default Mono — 14px / 20', style: VTypography.labelDefaultMono),
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
              Text(
                'Screen padding mobile: ${VSpacing.screenMobile} px',
                style: VTypography.bodyDefault,
              ),
              Text(
                'Screen padding tablet: ${VSpacing.screenTablet} px',
                style: VTypography.bodyDefault,
              ),
              Text(
                'Screen padding desktop: ${VSpacing.screenDesktop} px',
                style: VTypography.bodyDefault,
              ),
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
        border: Border.all(color: VColors.neutral200),
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
        color: VColors.neutral0,
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
