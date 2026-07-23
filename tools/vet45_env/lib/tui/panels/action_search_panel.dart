import 'package:nocterm/nocterm.dart';

import '../services_bridge.dart';
import '../widgets/panel_frame.dart';

/// Vim-style `/` overlay: query line + flat target/action hits.
class ActionSearchPanel extends StatelessComponent {
  const ActionSearchPanel({
    super.key,
    required this.query,
    required this.hits,
    required this.cursor,
    this.scrollController,
  });

  final String query;
  final List<RunnableActionHit> hits;
  final int cursor;
  final ScrollController? scrollController;

  @override
  Component build(BuildContext context) {
    final theme = TuiTheme.of(context);
    final scrim = Colors.black.withOpacity(0.45);
    return Stack(
      fit: StackFit.expand,
      children: [
        ModalBarrier(color: scrim, obscure: true, dismissible: false),
        Center(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final maxW = constraints.maxWidth.isFinite
                  ? constraints.maxWidth.floor().clamp(50, 120)
                  : 80;
              final maxH = constraints.maxHeight.isFinite
                  ? constraints.maxHeight.floor().clamp(12, 36)
                  : 24;
              final boxW = (maxW - 4).clamp(46, 110);
              final boxH = (maxH - 2).clamp(10, 32);
              return SizedBox(
                width: boxW.toDouble(),
                height: boxH.toDouble(),
                child: PanelFrame(
                  title: 'Search actions',
                  focused: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        '/$query█',
                        style: TextStyle(
                          color: theme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        ' ${hits.length} hit${hits.length == 1 ? '' : 's'}'
                        '  ↑↓ move  Enter run  Ctrl+A args  Esc close',
                        style: TextStyle(color: theme.outline),
                      ),
                      Expanded(
                        child: hits.isEmpty
                            ? Text(
                                ' (no matches)',
                                style: TextStyle(color: theme.outline),
                              )
                            : Scrollbar(
                                controller: scrollController,
                                thumbVisibility: true,
                                child: ListView.builder(
                                  controller: scrollController,
                                  itemCount: hits.length,
                                  itemBuilder: (context, i) => _HitRow(
                                    hit: hits[i],
                                    selected: i == cursor,
                                  ),
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _HitRow extends StatelessComponent {
  const _HitRow({required this.hit, required this.selected});

  final RunnableActionHit hit;
  final bool selected;

  @override
  Component build(BuildContext context) {
    final theme = TuiTheme.of(context);
    final prefix = hit.enabled ? (selected ? '>' : ' ') : '!';
    final titleColor = !hit.enabled
        ? theme.outline
        : selected
        ? theme.primary
        : theme.onSurface;
    final metaColor = selected ? theme.secondary : theme.outline;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 1),
      decoration: selected ? BoxDecoration(color: theme.selectionColor) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '$prefix ${hit.label}',
            style: TextStyle(
              color: titleColor,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text('    ${hit.description}', style: TextStyle(color: metaColor)),
          if (!hit.enabled && hit.disabledReason != null)
            Text(
              '    ! ${hit.disabledReason}',
              style: TextStyle(color: theme.warning),
            ),
        ],
      ),
    );
  }
}
