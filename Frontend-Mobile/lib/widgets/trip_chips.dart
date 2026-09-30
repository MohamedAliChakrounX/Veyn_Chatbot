import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../l10n/translations.dart';
import '../providers/language_provider.dart';
import '../providers/trip_provider.dart';
import '../theme/colors.dart';

class TripChips extends StatelessWidget {
  final bool showHeader;

  const TripChips({super.key, this.showHeader = false});

  IconData _getFieldIcon(String field) {
    switch (field) {
      case 'origin':
        return LucideIcons.mapPin;
      case 'destination':
        return LucideIcons.navigation;
      case 'date':
        return LucideIcons.calendar;
      case 'time':
        return LucideIcons.clock;
      case 'travelers':
        return LucideIcons.users;
      case 'modes':
        return LucideIcons.bus;
      case 'budget':
        return LucideIcons.wallet;
      default:
        return LucideIcons.sparkles;
    }
  }

  Color _getFieldBg(String field) {
    switch (field) {
      case 'origin':
        return VeynColors.blueSoft;
      case 'destination':
        return VeynColors.emeraldSoft;
      case 'date':
        return VeynColors.amberSoft;
      case 'time':
        return VeynColors.purpleSoft;
      case 'travelers':
        return VeynColors.indigoSoft;
      case 'modes':
        return VeynColors.roseSoft;
      case 'budget':
        return VeynColors.emeraldSoft;
      default:
        return VeynColors.surfaceSunken;
    }
  }

  Color _getFieldText(String field) {
    switch (field) {
      case 'origin':
        return VeynColors.blueText;
      case 'destination':
        return VeynColors.emeraldText;
      case 'date':
        return VeynColors.amberText;
      case 'time':
        return VeynColors.purpleText;
      case 'travelers':
        return VeynColors.indigoText;
      case 'modes':
        return VeynColors.roseText;
      case 'budget':
        return VeynColors.emeraldText;
      default:
        return VeynColors.ink;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tripProvider = context.watch<TripProvider>();
    final lang = context.watch<LanguageProvider>().languageCode;
    final chips = tripProvider.chipsFor(lang);
    final isRtl = context.isRtl;

    if (chips.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: isRtl ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showHeader) ...[
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 4, bottom: 6),
            child: Text(
              context.tr('active_filters'),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: VeynColors.inkMuted,
              ),
            ),
          ),
        ],
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
            children: chips.map((chip) {
              final bg = _getFieldBg(chip.field);
              final fg = _getFieldText(chip.field);
              final icon = _getFieldIcon(chip.field);

              return Container(
                margin: const EdgeInsetsDirectional.only(end: 6, bottom: 4),
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: fg.withValues(alpha: 0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 12, color: fg),
                    const SizedBox(width: 5),
                    Text(
                      chip.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: fg,
                      ),
                    ),
                    const SizedBox(width: 4),
                    InkWell(
                      onTap: () => tripProvider.removeField(chip.field),
                      borderRadius: BorderRadius.circular(10),
                      child: Padding(
                        padding: const EdgeInsets.all(2.0),
                        child: Icon(LucideIcons.x, size: 12, color: fg.withValues(alpha: 0.7)),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
