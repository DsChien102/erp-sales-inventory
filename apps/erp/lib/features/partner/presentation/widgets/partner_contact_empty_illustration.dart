import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

class PartnerContactEmptyIllustration extends StatelessWidget {
  const PartnerContactEmptyIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return SizedBox(
      width: 120,
      height: 120,
      child: Stack(
        children: [
          // Avatar 1 (Left background)
          Positioned(
            left: 10,
            top: 25,
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.surface,
                border: Border.all(color: colors.borderDefault, width: 2),
              ),
              child: VIcon(icon: VIcons.person, color: colors.textMuted, size: 30),
            ),
          ),
          // Avatar 2 (Right background)
          Positioned(
            right: 15,
            top: 15,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.surface,
                border: Border.all(color: colors.borderDefault, width: 2),
              ),
              child: VIcon(icon: VIcons.person, color: colors.textMuted, size: 36),
            ),
          ),
          // Avatar 3 (Middle foreground)
          Positioned(
            left: 28,
            bottom: 10,
            child: Container(
              width: 65,
              height: 65,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.surface,
                border: Border.all(color: colors.borderDefault, width: 2.5),
              ),
              child: VIcon(icon: VIcons.contact, color: colors.textMuted, size: 36),
            ),
          ),
          // Green plus badge (Bottom right)
          Positioned(
            right: 15,
            bottom: 10,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.success,
                border: Border.all(color: colors.surface, width: 2),
              ),
              child: const VIcon(
                icon: VIcons.add,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
