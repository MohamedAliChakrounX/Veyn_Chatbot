import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../data/locations.dart';
import '../l10n/translations.dart';
import '../models/trip.dart';
import '../theme/colors.dart';

class StopsTimeline extends StatelessWidget {
  final List<TripStop> stops;

  const StopsTimeline({super.key, required this.stops});

  @override
  Widget build(BuildContext context) {
    if (stops.isEmpty) return const SizedBox.shrink();

    final isRtl = context.isRtl;
    final lang = Localizations.localeOf(context).languageCode;

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: VeynColors.surfaceSunken,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: VeynColors.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(stops.length, (index) {
            final stop = stops[index];
            final isFirst = index == 0;
            final isLast = index == stops.length - 1;
            final isBorder = stop.kind == StopKind.border;

            final localizedName = localizeCityName(stop.name, lang);
            final localizedPlace = localizePlaceName(stop.place, lang);

            final waitBadgeText = lang == 'ar'
                ? 'توقف ${stop.waitMinutes} د'
                : lang == 'en'
                    ? '${stop.waitMinutes} min stop'
                    : 'Arrêt ${stop.waitMinutes} min';

            final borderBadgeText = lang == 'ar'
                ? 'مراقبة الجوازات والجمارك'
                : lang == 'en'
                    ? 'Customs & passport control'
                    : 'Contrôle des passeports et douanes';

            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Heure
                  SizedBox(
                    width: 44,
                    child: Text(
                      stop.time,
                      textAlign: isRtl ? TextAlign.right : TextAlign.left,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isFirst || isLast ? FontWeight.w700 : FontWeight.w500,
                        color: isFirst || isLast ? VeynColors.ink : VeynColors.inkMuted,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Ligne & Point indicateur
                  Column(
                    children: [
                      Container(
                        width: isBorder ? 12 : 8,
                        height: isBorder ? 12 : 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isBorder
                              ? VeynColors.amberText
                              : isFirst || isLast
                                  ? VeynColors.accent
                                  : VeynColors.lineStrong,
                        ),
                      ),
                      if (!isLast)
                        Expanded(
                          child: Container(
                            width: 2,
                            color: VeynColors.lineStrong,
                            margin: const EdgeInsets.symmetric(vertical: 2),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  // Détails de l'arrêt
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  localizedName,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: isFirst || isLast ? FontWeight.w700 : FontWeight.w500,
                                    color: VeynColors.ink,
                                  ),
                                ),
                              ),
                              if (stop.waitMinutes != null && stop.waitMinutes! > 0) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isBorder ? VeynColors.amberSoft : VeynColors.surface,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: isBorder ? VeynColors.amberText.withValues(alpha: 0.3) : VeynColors.line,
                                    ),
                                  ),
                                  child: Text(
                                    waitBadgeText,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: isBorder ? VeynColors.amberText : VeynColors.inkMuted,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          if (localizedPlace.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              localizedPlace,
                              style: const TextStyle(
                                fontSize: 11,
                                color: VeynColors.inkMuted,
                              ),
                            ),
                          ],
                          if (isBorder) ...[
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: VeynColors.amberSoft,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(LucideIcons.shieldAlert, size: 12, color: VeynColors.amberText),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      borderBadgeText,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: VeynColors.amberText,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }
}
