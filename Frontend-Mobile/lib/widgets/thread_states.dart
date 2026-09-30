import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../l10n/translations.dart';
import '../models/chat_message.dart';
import '../theme/colors.dart';

class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: VeynColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: VeynColors.line),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            return AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final delay = index * 0.2;
                final val = (_controller.value + delay) % 1.0;
                final scale = 0.5 + (0.5 * (1 - (val - 0.5).abs() * 2));
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2.5),
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: VeynColors.inkMuted.withValues(alpha: scale),
                  ),
                );
              },
            );
          }),
        ),
      ),
    );
  }
}

class ResultSkeletons extends StatelessWidget {
  const ResultSkeletons({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: VeynColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: VeynColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 70,
                height: 20,
                decoration: BoxDecoration(
                  color: VeynColors.surfaceSunken,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const Spacer(),
              Container(
                width: 90,
                height: 20,
                decoration: BoxDecoration(
                  color: VeynColors.surfaceSunken,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                width: 140,
                height: 24,
                decoration: BoxDecoration(
                  color: VeynColors.surfaceSunken,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const Spacer(),
              Container(
                width: 60,
                height: 24,
                decoration: BoxDecoration(
                  color: VeynColors.surfaceSunken,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: 100,
            height: 14,
            decoration: BoxDecoration(
              color: VeynColors.surfaceSunken,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }
}

class QuickReplyRow extends StatelessWidget {
  final List<QuickReply> replies;
  final Function(String) onPick;

  const QuickReplyRow({
    super.key,
    required this.replies,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: replies.map((reply) {
          return Padding(
            padding: const EdgeInsetsDirectional.only(end: 6, bottom: 4),
            child: ActionChip(
              label: Text(
                reply.label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: VeynColors.inkSoft,
                ),
              ),
              backgroundColor: VeynColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: VeynColors.line),
              ),
              onPressed: () => onPick(reply.value),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class ErrorNotice extends StatelessWidget {
  final VoidCallback onRetry;

  const ErrorNotice({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: VeynColors.errorSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: VeynColors.errorBorder),
      ),
      child: Row(
        textDirection: context.isRtl ? TextDirection.rtl : TextDirection.ltr,
        children: [
          const Icon(LucideIcons.alertTriangle, size: 16, color: VeynColors.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              context.tr('error_notice'),
              style: const TextStyle(fontSize: 12, color: VeynColors.error),
              textAlign: context.isRtl ? TextAlign.right : TextAlign.left,
            ),
          ),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              foregroundColor: VeynColors.error,
            ),
            child: Text(context.tr('retry'), style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class NoResultsActions extends StatelessWidget {
  final Function(String) onPick;

  const NoResultsActions({super.key, required this.onPick});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        ActionChip(
          label: Text(context.tr('no_results_change_date'), style: const TextStyle(fontSize: 12)),
          backgroundColor: VeynColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: VeynColors.line),
          ),
          onPressed: () => onPick(context.tr('no_results_change_date_msg')),
        ),
        ActionChip(
          label: Text(context.tr('no_results_remove_budget'), style: const TextStyle(fontSize: 12)),
          backgroundColor: VeynColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: VeynColors.line),
          ),
          onPressed: () => onPick(context.tr('no_results_remove_budget_msg')),
        ),
      ],
    );
  }
}
