import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../app/theme/lab_colors.dart';
import 'mind_pressable.dart';

/// Rounded vertical Quick Action card matching Phone 2 ("Quick Actions").
class QuickActionCard extends StatelessWidget {
  const QuickActionCard({
    super.key,
    required this.icon,
    required this.line1,
    required this.line2,
    required this.onTap,
  });

  final IconData icon;
  final String line1;
  final String line2;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bg = isDark ? LabColors.darkForestCard : LabColors.cardIvory;
    final border = isDark ? LabColors.darkForestBorder : LabColors.borderIvory;
    final iconBg = isDark ? LabColors.darkForestSurface : LabColors.secondaryIvory;
    final iconColor = isDark ? LabColors.lightOlive : LabColors.forestGreen;
    final textCol = isDark ? LabColors.darkTextPrimary : LabColors.primaryText;

    return Expanded(
      child: MindPressable(
        onPressed: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: border, width: 1.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: MergeSemantics(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 22, color: iconColor),
              ),
              const SizedBox(height: 10),
              Text(
                line1,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: textCol,
                  letterSpacing: -0.2,
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                line2,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: textCol,
                  letterSpacing: -0.2,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            ),
          ),
        ),
      ),
    );
  }
}

