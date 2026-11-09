import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

enum InventorySkeletonBlock {
  heading,
  card,
  row,
  search,
  text,
}

class InventoryLoading extends StatelessWidget {
  const InventoryLoading({
    super.key,
    this.blocks = const [
      InventorySkeletonBlock.heading,
      InventorySkeletonBlock.card,
      InventorySkeletonBlock.card,
    ],
  });

  final List<InventorySkeletonBlock> blocks;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Đang tải',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < blocks.length; i++) ...[
            _buildBlock(blocks[i]),
            if (i < blocks.length - 1) const SizedBox(height: VSpacing.space3),
          ],
        ],
      ),
    );
  }

  Widget _buildBlock(InventorySkeletonBlock block) {
    final double height;
    final double radius;

    switch (block) {
      case InventorySkeletonBlock.heading:
        height = 24;
        radius = VRadius.r4;
      case InventorySkeletonBlock.card:
        height = 96;
        radius = VRadius.r12;
      case InventorySkeletonBlock.row:
        height = 64;
        radius = VRadius.r12;
      case InventorySkeletonBlock.search:
        height = 44;
        radius = VRadius.r12;
      case InventorySkeletonBlock.text:
        height = 13;
        radius = VRadius.r4;
    }

    return VSkeleton(
      width: double.infinity,
      height: height,
      borderRadius: radius,
    );
  }
}

class InventoryDenied extends StatelessWidget {
  const InventoryDenied({
    super.key,
    required this.what,
    required this.next,
    required this.onExit,
  });

  final String what;
  final String next;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    return VEmptyState(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          VEmptyHeader(
            children: [
              const VEmptyMedia(icon: VIcons.lock),
              VEmptyTitle('Bạn chưa có quyền $what'),
              VEmptyDescription(next),
            ],
          ),
          const SizedBox(height: VSpacing.space4),
          VEmptyContent(
            child: VButton(
              label: 'Về Kho',
              variant: VButtonVariant.secondary,
              onPressed: onExit,
            ),
          ),
        ],
      ),
    );
  }
}

class InventoryStale extends StatelessWidget {
  const InventoryStale({
    super.key,
    required this.title,
    required this.description,
    this.actionLabel = 'Tải lại',
    required this.onAction,
  });

  final String title;
  final String description;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        VBanner(
          tone: VComponentTone.warning,
          title: title,
          description: description,
        ),
        const SizedBox(height: VSpacing.space2),
        VButton(
          label: actionLabel,
          variant: VButtonVariant.secondary,
          onPressed: onAction,
        ),
      ],
    );
  }
}

class InventoryLocked extends StatelessWidget {
  const InventoryLocked({
    super.key,
    required this.title,
    required this.description,
  });

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return VBanner(
      tone: VComponentTone.info,
      title: title,
      description: description,
    );
  }
}

class InventoryEmpty extends StatelessWidget {
  const InventoryEmpty({
    super.key,
    required this.title,
    required this.description,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String description;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return VEmptyState(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          VEmptyHeader(
            children: [
              const VEmptyMedia(icon: VIcons.inbox),
              VEmptyTitle(title),
              VEmptyDescription(description),
            ],
          ),
          if (actionLabel != null && actionLabel!.isNotEmpty) ...[
            const SizedBox(height: VSpacing.space4),
            VEmptyContent(
              child: VButton(
                label: actionLabel!,
                variant: VButtonVariant.secondary,
                onPressed: onAction,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
