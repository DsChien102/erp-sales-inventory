import 'dart:math' as math;

import 'package:c45_design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/formatting/money_formatter.dart';
import '../../data/models/home_summary.dart';
import '../../logic/home_format.dart';
import '../../logic/home_state.dart';

/// Trang chủ "Bảng giá chợ" (APP-01, 10-8b) — prototype `specs/prototype/home/html/app/board.js`.
///
/// Chỉ vẽ: dữ liệu từ [state], hành động qua callback. [wide] = cửa sổ ≥ 1024.
class HomeBoard extends StatelessWidget {
  const HomeBoard({
    super.key,
    required this.state,
    required this.branchName,
    required this.onBranchTap,
    required this.now,
    required this.wide,
    required this.onRetry,
    required this.onRefresh,
  });

  final HomeState state;
  final String branchName;
  final VoidCallback onBranchTap;
  final DateTime now;
  final bool wide;
  final VoidCallback onRetry;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    return ColoredBox(
      key: const Key('home_board'),
      color: wide ? colors.background : colors.surface,
      child: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final padding = wide
                ? EdgeInsets.fromLTRB(
                    math.max(VSpacing.space8, (w - 1120) / 2 + VSpacing.space8),
                    VSpacing.space6,
                    math.max(VSpacing.space8, (w - 1120) / 2 + VSpacing.space8),
                    112,
                  )
                : const EdgeInsets.fromLTRB(VSpacing.space4, VSpacing.space4, VSpacing.space4, 96);
            final gap = wide ? VSpacing.space6 : VSpacing.space5;
            final children = <Widget>[
              if (!wide)
                _HomeHead(
                  // Lời chào theo giờ máy; ngày theo ngày của số liệu (server, Asia/Ho_Chi_Minh).
                  greeting: '${greetingForHour(now.hour)} · ${dateLine(state.summary?.today ?? now)}',
                  branchName: branchName,
                  onTap: onBranchTap,
                  wide: wide,
                ),
              ..._body(),
            ];
            if (wide) {
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: padding,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: math.max(0, constraints.maxHeight - padding.vertical),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var i = 0; i < children.length; i++) ...[
                        if (i > 0) SizedBox(height: gap),
                        children[i],
                      ],
                    ],
                  ),
                ),
              );
            }
            return RefreshIndicator(
              onRefresh: onRefresh,
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: padding,
                itemCount: children.length,
                separatorBuilder: (_, _) => SizedBox(height: gap),
                itemBuilder: (_, i) => children[i],
              ),
            );
          },
        ),
      ),
    );
  }

  List<Widget> _body() {
    final summary = state.summary;
    if (summary != null) {
      return [
        _Hero(summary: summary, wide: wide),
        _Boxes(summary: summary, wide: wide),
      ];
    }
    if (state.status == HomeStatus.error) {
      return [_ErrorCard(error: state.error, onRetry: onRetry)];
    }
    return [_Skeleton(wide: wide)];
  }
}

// ── Chữ dùng chung ─────────────────────────────────────────────────────────

TextStyle _num(double size, double height, double spacing, Color color) =>
    VTypography.bodyDefault.copyWith(
      fontSize: size,
      height: height / size,
      fontWeight: FontWeight.w800,
      letterSpacing: spacing,
      color: color,
      fontFeatures: const [FontFeature.tabularFigures(), FontFeature.liningFigures()],
    );

TextStyle _label(Color color) => VTypography.caption.copyWith(
  height: 18 / 12,
  fontWeight: FontWeight.w700,
  letterSpacing: .6,
  color: color,
);

TextStyle _unit(VColorScheme c, {double size = 16}) => VTypography.bodyDefault.copyWith(
  fontSize: size,
  height: 1.2,
  fontWeight: FontWeight.w500,
  color: c.textMuted,
);

String _money(int minor) => MoneyFormatter.formatMinorPlain(minor);

// ── Đầu trang ──────────────────────────────────────────────────────────────

class _HomeHead extends StatefulWidget {
  const _HomeHead({
    required this.greeting,
    required this.branchName,
    required this.onTap,
    required this.wide,
  });

  final String greeting;
  final String branchName;
  final VoidCallback onTap;
  final bool wide;

  @override
  State<_HomeHead> createState() => _HomeHeadState();
}

class _HomeHeadState extends State<_HomeHead> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final c = context.vColors;
    final size = widget.wide ? 34.0 : 26.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.greeting,
          style: VTypography.bodySmall.copyWith(height: 20 / 13, color: c.textSecondary),
        ),
        Semantics(
          button: true,
          label: 'Đổi tổ chức, ${widget.branchName}',
          excludeSemantics: true,
          child: InkWell(
            onTap: widget.onTap,
            onHover: (v) => setState(() => _hover = v),
            hoverColor: Colors.transparent,
            borderRadius: BorderRadius.circular(VRadius.r8),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: VSpacing.minTouchTarget),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      widget.branchName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: VTypography.bodyDefault.copyWith(
                        fontSize: size,
                        height: (widget.wide ? 42 : 34) / size,
                        fontWeight: FontWeight.w800,
                        letterSpacing: widget.wide ? -1 : -.6,
                        color: c.textPrimary,
                        decoration: _hover ? TextDecoration.underline : TextDecoration.none,
                        decorationThickness: 2,
                        decorationColor: c.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: VSpacing.space1),
                  VIcon(icon: VIcons.chevronDown, size: 20, color: c.textMuted),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Doanh thu + 7 ngày ─────────────────────────────────────────────────────

class _Hero extends StatelessWidget {
  const _Hero({required this.summary, required this.wide});

  final HomeSummary summary;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final c = context.vColors;
    final rev = _RevenueRow(summary: summary, wide: wide);
    final week = _WeekChart(summary: summary, wide: wide);
    return Semantics(
      container: true,
      label: 'Doanh thu hôm nay',
      child: wide
          ? Container(
              padding: const EdgeInsets.symmetric(
                horizontal: VSpacing.space8,
                vertical: VSpacing.space6,
              ),
              decoration: BoxDecoration(
                color: c.surface,
                border: VBorders.all(c.borderDefault),
                borderRadius: BorderRadius.circular(VRadius.card),
                boxShadow: VShadows.e1,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(flex: 11, child: rev),
                  const SizedBox(width: VSpacing.space10),
                  Expanded(flex: 10, child: week),
                ],
              ),
            )
          : DecoratedBox(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: c.textPrimary, width: 2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [rev, week],
              ),
            ),
    );
  }
}

class _RevenueRow extends StatelessWidget {
  const _RevenueRow({required this.summary, required this.wide});

  final HomeSummary summary;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final c = context.vColors;
    final delta = percentDelta(summary.revenueToday, summary.revenueYesterday);
    return Padding(
      padding: wide
          ? EdgeInsets.zero
          : const EdgeInsets.only(top: VSpacing.space4, bottom: VSpacing.space3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('DOANH THU', style: _label(c.textSecondary)),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                _Flip(
                  index: 0,
                  child: Text(
                    _money(summary.revenueToday),
                    style: wide ? _num(96, 100, -5, c.textBrand) : _num(56, 62, -2.5, c.textBrand),
                  ),
                ),
                const SizedBox(width: VSpacing.space2),
                Text('₫', style: _unit(c, size: wide ? 32 : 16)),
              ],
            ),
          ),
          if (delta != null) ...[
            const SizedBox(height: 2),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '${delta.up ? '▲' : '▼'} ${delta.text}',
                  style: VTypography.labelDefault.copyWith(
                    fontSize: wide ? 20 : 14,
                    fontWeight: FontWeight.w700,
                    color: delta.up ? c.success : c.warning,
                  ),
                ),
                const SizedBox(width: VSpacing.space2),
                Text(
                  'so với hôm qua',
                  style: VTypography.caption.copyWith(
                    fontSize: wide ? 13 : 12,
                    fontWeight: FontWeight.w500,
                    color: c.textMuted,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _WeekChart extends StatelessWidget {
  const _WeekChart({required this.summary, required this.wide});

  final HomeSummary summary;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final c = context.vColors;
    final days = summary.revenueWeek;
    final total = days.fold<int>(0, (a, d) => a + d.revenueMinor);
    final maxV = days.fold<int>(0, (a, d) => math.max(a, d.revenueMinor));
    final h = wide ? 120.0 : 96.0;
    final small = VTypography.caption.copyWith(height: 14 / 12, fontWeight: FontWeight.w600);
    final chart = Padding(
      padding: wide
          ? EdgeInsets.zero
          : const EdgeInsets.only(
              top: VSpacing.space3,
              bottom: VSpacing.space4,
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  'Doanh thu 7 ngày gần nhất (triệu ₫)',
                  style: VTypography.caption.copyWith(
                    fontWeight: FontWeight.w500,
                    color: c.textMuted,
                  ),
                ),
              ),
              const SizedBox(width: VSpacing.space2),
              Text(
                millionsTotal(total),
                style: VTypography.labelDefault.copyWith(
                  fontWeight: FontWeight.w700,
                  color: wide ? c.textPrimary : c.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: VSpacing.space2),
          SizedBox(
            height: h,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < days.length; i++) ...[
                  if (i > 0) SizedBox(width: wide ? VSpacing.space3 : 6),
                  Expanded(
                    child: _WeekColumn(
                      value: days[i].revenueMinor,
                      maxValue: maxV,
                      barSpace: h - 36,
                      label: weekdayShort(days[i].day, today: i == days.length - 1),
                      today: i == days.length - 1,
                      style: small,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
    return Semantics(
      container: true,
      label: 'Doanh thu 7 ngày, tổng ${millionsTotal(total)}',
      child: wide
          ? chart
          : DecoratedBox(
              decoration: BoxDecoration(border: Border(bottom: VBorders.side(c.borderDefault))),
              child: chart,
            ),
    );
  }
}

class _WeekColumn extends StatelessWidget {
  const _WeekColumn({
    required this.value,
    required this.maxValue,
    required this.barSpace,
    required this.label,
    required this.today,
    required this.style,
  });

  final int value;
  final int maxValue;
  final double barSpace;
  final String label;
  final bool today;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final c = context.vColors;
    final ratio = maxValue == 0 ? 0.0 : value / maxValue;
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          millions(value),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.clip,
          style: style.copyWith(color: today ? c.textBrand : c.textMuted),
        ),
        const SizedBox(height: VSpacing.space1),
        Container(
          height: math.max(2, ratio * barSpace),
          decoration: BoxDecoration(
            color: today ? c.primary : c.borderDefault,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
          ),
        ),
        const SizedBox(height: VSpacing.space1),
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          style: style.copyWith(letterSpacing: .6, color: today ? c.textPrimary : c.textMuted),
        ),
      ],
    );
  }
}

// ── Ba hộp ─────────────────────────────────────────────────────────────────

class _Boxes extends StatelessWidget {
  const _Boxes({required this.summary, required this.wide});

  final HomeSummary summary;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final orders = _OrdersBox(summary: summary, wide: wide);
    final cash = _CashBox(summary: summary, wide: wide);
    final debt = _DebtBox(summary: summary, wide: wide);
    if (wide) {
      return IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(flex: 125, child: orders),
            const SizedBox(width: VSpacing.space4),
            Expanded(flex: 100, child: cash),
            const SizedBox(width: VSpacing.space4),
            Expanded(flex: 100, child: debt),
          ],
        ),
      );
    }
    // iPhone: Công nợ ngay sau Đơn (trong màn đầu), Tiền đã thu xuống cuối.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        orders,
        const SizedBox(height: VSpacing.space3),
        debt,
        const SizedBox(height: VSpacing.space3),
        cash,
      ],
    );
  }
}

class _Box extends StatelessWidget {
  const _Box({required this.label, required this.figs, required this.legend, required this.wide});

  final String label;
  final Widget figs;
  final Widget legend;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final c = context.vColors;
    return Semantics(
      container: true,
      label: label,
      child: Container(
        padding: wide
            ? const EdgeInsets.symmetric(vertical: VSpacing.space5, horizontal: VSpacing.space6)
            : const EdgeInsets.all(VSpacing.space4),
        decoration: BoxDecoration(
          color: c.surface,
          border: VBorders.all(c.borderDefault),
          borderRadius: BorderRadius.circular(VRadius.card),
          boxShadow: wide ? VShadows.e1 : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            figs,
            const SizedBox(height: VSpacing.space3),
            if (wide) const Spacer(),
            Container(
              padding: const EdgeInsets.only(top: VSpacing.space3),
              decoration: BoxDecoration(border: Border(top: VBorders.side(c.borderDefault))),
              child: legend,
            ),
          ],
        ),
      ),
    );
  }
}

/// Một con số: nhãn in hoa, số lớn (+ đơn vị / ▲▼).
class _Fig extends StatelessWidget {
  const _Fig({
    required this.label,
    required this.value,
    required this.index,
    required this.numStyle,
    this.unit,
    this.delta,
    this.warn = false,
  });

  final String label;
  final String value;
  final int index;
  final TextStyle numStyle;
  final String? unit;
  final HomeDelta? delta;
  final bool warn;

  @override
  Widget build(BuildContext context) {
    final c = context.vColors;
    final d = delta;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: _label(warn ? c.warning : c.textSecondary),
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              _Flip(
                index: index,
                child: Text(
                  value,
                  style: numStyle.copyWith(color: warn ? c.warning : c.textPrimary),
                ),
              ),
              if (unit != null) ...[
                const SizedBox(width: VSpacing.space2),
                Text(unit!, style: _unit(c)),
              ],
              if (d != null) ...[
                const SizedBox(width: VSpacing.space2),
                Text(
                  '${d.up ? '▲' : '▼'} ${d.text}',
                  style: VTypography.labelDefault.copyWith(
                    fontWeight: FontWeight.w700,
                    color: d.up ? c.success : c.warning,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Một mục chú thích: nhãn + số đậm (một Text để tự xuống dòng khi hộp hẹp).
class _LegendItem extends StatelessWidget {
  const _LegendItem(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final c = context.vColors;
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: '$label '),
          TextSpan(
            text: value,
            style: TextStyle(fontWeight: FontWeight.w700, color: c.textPrimary),
          ),
        ],
      ),
      style: VTypography.bodySmall.copyWith(color: c.textSecondary),
    );
  }
}

Widget _legend(List<Widget> items) =>
    Wrap(spacing: VSpacing.space5, runSpacing: VSpacing.space1, children: items);

class _OrdersBox extends StatelessWidget {
  const _OrdersBox({required this.summary, required this.wide});

  final HomeSummary summary;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final c = context.vColors;
    final style = _num(44, 50, -2, c.textPrimary);
    final uninvoiced = summary.ordersUninvoiced;
    return _Box(
      label: 'Đơn hôm nay',
      wide: wide,
      figs: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _Fig(
                label: 'ĐƠN HÔM NAY',
                value: '${summary.ordersToday}',
                index: 1,
                numStyle: style,
                delta: countDelta(summary.ordersToday, summary.ordersYesterday),
              ),
            ),
            if (uninvoiced != null)
              Expanded(
                child: Container(
                  padding: EdgeInsets.only(left: wide ? VSpacing.space6 : VSpacing.space4),
                  decoration: BoxDecoration(border: Border(left: VBorders.side(c.borderDefault))),
                  child: _Fig(
                    label: 'CHƯA XUẤT HOÁ ĐƠN',
                    value: '$uninvoiced',
                    index: 2,
                    numStyle: style,
                    warn: true,
                  ),
                ),
              ),
          ],
        ),
      ),
      legend: _legend([
        _LegendItem('Tiền mặt', '${summary.ordersCash}'),
        _LegendItem('Chuyển khoản', '${summary.ordersBank}'),
        _LegendItem('Ghi nợ', '${summary.ordersDebt}'),
      ]),
    );
  }
}

TextStyle _moneyStyle(VColorScheme c, bool wide) =>
    wide ? _num(36, 44, -1.4, c.textPrimary) : _num(32, 40, -1.2, c.textPrimary);

class _CashBox extends StatelessWidget {
  const _CashBox({required this.summary, required this.wide});

  final HomeSummary summary;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final c = context.vColors;
    return _Box(
      label: 'Tiền đã thu hôm nay',
      wide: wide,
      figs: _Fig(
        label: 'TIỀN ĐÃ THU HÔM NAY',
        value: _money(summary.cashInTotal),
        unit: '₫',
        index: 3,
        numStyle: _moneyStyle(c, wide),
      ),
      legend: wide
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _LegendItem('Tiền mặt', _money(summary.cashInCash)),
                const SizedBox(height: VSpacing.space1),
                _LegendItem('Chuyển khoản', _money(summary.cashInBank)),
              ],
            )
          : _legend([
              _LegendItem('Tiền mặt', _money(summary.cashInCash)),
              _LegendItem('Chuyển khoản', _money(summary.cashInBank)),
            ]),
    );
  }
}

class _DebtBox extends StatelessWidget {
  const _DebtBox({required this.summary, required this.wide});

  final HomeSummary summary;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final c = context.vColors;
    final overdue = summary.receivableOverdueCount;
    final style = VTypography.bodySmall;
    return _Box(
      label: 'Công nợ phải thu',
      wide: wide,
      figs: _Fig(
        label: 'CÔNG NỢ PHẢI THU',
        value: _money(summary.receivableTotal),
        unit: '₫',
        index: 4,
        numStyle: _moneyStyle(c, wide),
      ),
      legend: overdue == 0
          ? Text('Không có khoản quá hạn', style: style.copyWith(color: c.textSecondary))
          : Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '$overdue',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const TextSpan(text: ' khoản quá hạn'),
                ],
              ),
              style: style.copyWith(fontWeight: FontWeight.w600, color: c.warning),
            ),
    );
  }
}

// ── Số lật lên khi mở ─────────────────────────────────────────────────────

/// `.bz-flip`: 0.7 s, trễ `index × 90 + 120` ms, `rotateX(−80°) → 0`, mờ → rõ.
/// Chỉ chạy khi widget mới dựng; giảm chuyển động thì hiện ngay.
class _Flip extends StatelessWidget {
  const _Flip({required this.index, required this.child});

  final int index;
  final Widget child;

  static const _curve = Cubic(.16, 1, .3, 1);

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    final delayMs = index * 90 + 120;
    final totalMs = delayMs + 700;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: totalMs),
      curve: Interval(delayMs / totalMs, 1, curve: _curve),
      child: child,
      builder: (context, t, child) {
        final k = 1 - t;
        return Opacity(
          opacity: t.clamp(0.0, 1.0),
          child: Transform(
            alignment: Alignment.topCenter,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 1 / 400)
              ..rotateX(-80 * k * math.pi / 180)
              ..translateByDouble(0, -6 * k, 0, 1),
            child: child,
          ),
        );
      },
    );
  }
}

// ── Đang tải / lỗi ─────────────────────────────────────────────────────────

class _Skeleton extends StatelessWidget {
  const _Skeleton({required this.wide});

  final bool wide;

  @override
  Widget build(BuildContext context) {
    final c = context.vColors;
    Widget box() => Container(
      height: 150,
      padding: const EdgeInsets.all(VSpacing.space4),
      decoration: BoxDecoration(
        color: c.surface,
        border: VBorders.all(c.borderDefault),
        borderRadius: BorderRadius.circular(VRadius.card),
        boxShadow: wide ? VShadows.e1 : null,
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          VSkeleton(width: 96, height: 14),
          SizedBox(height: VSpacing.space2),
          VSkeleton(width: 140, height: 40),
          Spacer(),
          VSkeleton(width: 180, height: 14),
        ],
      ),
    );
    final hero = wide
        ? Container(
            padding: const EdgeInsets.symmetric(
              horizontal: VSpacing.space8,
              vertical: VSpacing.space6,
            ),
            decoration: BoxDecoration(
              color: c.surface,
              border: VBorders.all(c.borderDefault),
              borderRadius: BorderRadius.circular(VRadius.card),
              boxShadow: VShadows.e1,
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  flex: 11,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      VSkeleton(width: 80, height: 14),
                      SizedBox(height: VSpacing.space2),
                      VSkeleton(width: 420, height: 96),
                    ],
                  ),
                ),
                SizedBox(width: VSpacing.space10),
                Expanded(flex: 10, child: VSkeleton(height: 120)),
              ],
            ),
          )
        : DecoratedBox(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: c.textPrimary, width: 2)),
            ),
            child: const Padding(
              padding: EdgeInsets.only(top: VSpacing.space4, bottom: VSpacing.space3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  VSkeleton(width: 80, height: 14),
                  SizedBox(height: VSpacing.space2),
                  VSkeleton(width: 260, height: 56),
                  SizedBox(height: VSpacing.space4),
                  VSkeleton(height: 96),
                ],
              ),
            ),
          );
    return Semantics(
      label: 'Đang tải số liệu',
      child: VSkeletonScope(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            hero,
            SizedBox(height: wide ? VSpacing.space6 : VSpacing.space5),
            if (wide)
              Row(
                children: [
                  Expanded(flex: 125, child: box()),
                  const SizedBox(width: VSpacing.space4),
                  Expanded(flex: 100, child: box()),
                  const SizedBox(width: VSpacing.space4),
                  Expanded(flex: 100, child: box()),
                ],
              )
            else ...[
              box(),
              const SizedBox(height: VSpacing.space3),
              box(),
              const SizedBox(height: VSpacing.space3),
              box(),
            ],
          ],
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.error, required this.onRetry});

  final AppException? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final c = context.vColors;
    return Container(
      padding: const EdgeInsets.all(VSpacing.space4),
      decoration: BoxDecoration(
        color: c.surface,
        border: VBorders.all(c.borderDefault),
        borderRadius: BorderRadius.circular(VRadius.card),
        boxShadow: VShadows.e1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Không tải được số liệu hôm nay',
            style: VTypography.labelDefault.copyWith(color: c.textPrimary),
          ),
          const SizedBox(height: VSpacing.space1),
          Text(
            error?.userMessage() ?? 'Đã có lỗi xảy ra.',
            style: VTypography.bodySmall.copyWith(color: c.textSecondary),
          ),
          const SizedBox(height: VSpacing.space3),
          VButton(label: 'Thử lại', variant: VButtonVariant.secondary, onPressed: onRetry),
        ],
      ),
    );
  }
}
