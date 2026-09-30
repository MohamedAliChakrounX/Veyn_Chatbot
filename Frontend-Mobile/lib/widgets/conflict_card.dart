import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../l10n/translations.dart';
import '../models/chat_message.dart';
import '../theme/colors.dart';

class ConflictCard extends StatelessWidget {
  final TripConflict conflict;
  final Function(bool useProposed) onResolve;

  const ConflictCard({
    super.key,
    required this.conflict,
    required this.onResolve,
  });

  @override
  Widget build(BuildContext context) {
    final isRtl = context.isRtl;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: VeynColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: VeynColors.amberText.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: isRtl ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
            children: [
              const Icon(LucideIcons.alertCircle, color: VeynColors.amberText, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  conflict.question,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: VeynColors.ink,
                  ),
                  textAlign: isRtl ? TextAlign.right : TextAlign.left,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => onResolve(false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: VeynColors.inkSoft,
                    side: const BorderSide(color: VeynColors.line),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  child: Text(
                    conflict.currentLabel,
                    style: const TextStyle(fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => onResolve(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: VeynColors.accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    elevation: 0,
                  ),
                  child: Text(
                    conflict.proposedLabel,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
