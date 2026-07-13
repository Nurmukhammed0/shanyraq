import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/zhk.dart';

/// Статус стройки (построен/строится) и год — виден всем бесплатно,
/// в отличие от документации/нарушений/суда, которые остаются за подпиской.
class ConstructionStatusRow extends StatelessWidget {
  final Zhk zhk;
  final double iconSize;
  final double fontSize;

  const ConstructionStatusRow({super.key, required this.zhk, this.iconSize = 16, this.fontSize = 13});

  @override
  Widget build(BuildContext context) {
    final status = zhk.constructionStatus;
    if (status == null) return const SizedBox.shrink();

    final year = zhk.completionYear;
    final isBuilt = status == 'built';
    final icon = isBuilt ? Icons.check_circle_outline : Icons.construction_outlined;
    final label = isBuilt
        ? (year != null
            ? context.tr('zhk_year_built', {'year': '$year'})
            : context.tr('zhk_construction_built'))
        : (year != null
            ? context.tr('zhk_year_expected', {'year': '$year'})
            : context.tr('zhk_construction_in_progress'));

    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: iconSize, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: 5),
        Text(label,
            style: TextStyle(
                fontSize: fontSize, color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
