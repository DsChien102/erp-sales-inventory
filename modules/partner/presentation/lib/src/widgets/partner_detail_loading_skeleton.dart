import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

class PartnerDetailLoadingSkeleton extends StatefulWidget {
  const PartnerDetailLoadingSkeleton({super.key});

  @override
  State<PartnerDetailLoadingSkeleton> createState() => _PartnerDetailLoadingSkeletonState();
}

class _PartnerDetailLoadingSkeletonState extends State<PartnerDetailLoadingSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _opacityAnimation = Tween<double>(begin: 0.4, end: 0.8).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildSkeletonBox({
    required double width,
    required double height,
    required double borderRadius,
    EdgeInsetsGeometry? margin,
  }) {
    return AnimatedBuilder(
      animation: _opacityAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnimation.value,
          child: Container(
            width: width,
            height: height,
            margin: margin,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(borderRadius),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(VSpacing.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header skeleton (D-06A)
          Row(
            children: [
              // Circular avatar placeholder
              AnimatedBuilder(
                animation: _opacityAnimation,
                builder: (context, child) {
                  return Opacity(
                    opacity: _opacityAnimation.value,
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        shape: BoxShape.circle,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: VSpacing.space4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSkeletonBox(width: 160, height: 18, borderRadius: 4),
                    const SizedBox(height: 8),
                    _buildSkeletonBox(width: 100, height: 14, borderRadius: 4),
                    const SizedBox(height: 8),
                    _buildSkeletonBox(width: 80, height: 12, borderRadius: 4),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: VSpacing.space6),

          // List item skeletons (D-06A)
          Expanded(
            child: ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 5,
              separatorBuilder: (context, index) => const SizedBox(height: VSpacing.space3),
              itemBuilder: (context, index) {
                return Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: VSpacing.space4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(VRadius.card),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Row(
                    children: [
                      // Square checkbox placeholder
                      _buildSkeletonBox(width: 18, height: 18, borderRadius: 4),
                      const SizedBox(width: VSpacing.space3),
                      // Text block placeholder
                      Expanded(
                        child: _buildSkeletonBox(width: double.infinity, height: 16, borderRadius: 4),
                      ),
                      const SizedBox(width: VSpacing.space3),
                      // Chevron placeholder
                      _buildSkeletonBox(width: 12, height: 12, borderRadius: 2),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
