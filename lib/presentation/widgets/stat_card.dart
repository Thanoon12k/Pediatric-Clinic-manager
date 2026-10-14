import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Compact metric tile that adapts to small phone widths and text scaling.
class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final narrow = constraints.maxWidth < 175;
      return Semantics(
        label: '$label: $value',
        child: Container(
          padding: EdgeInsets.all(narrow ? 10 : 14),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(children: [
            Container(
              width: narrow ? 35 : 43,
              height: narrow ? 35 : 43,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: color, size: narrow ? 19 : 23),
            ),
            const SizedBox(width: 9),
            Expanded(child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(value, style: TextStyle(
                    fontSize: narrow ? 21 : 24,
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.onSurface,
                  )),
                ),
                const SizedBox(height: 3),
                Text(label, maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, height: 1.3, color: AppColors.textSecondary)),
              ],
            )),
          ]),
        ),
      );
    },
  );
}
