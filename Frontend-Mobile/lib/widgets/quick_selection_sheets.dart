import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:lucide_icons/lucide_icons.dart';
import '../data/options.dart';
import '../l10n/translations.dart';
import '../models/trip.dart';
import '../providers/trip_provider.dart';
import '../theme/colors.dart';

class QuickSelectionSheets {
  // ───────────────────────────────────────────────────────────────────────────
  // FEUILLE 1 : SÉLECTION DIRECTE DU CALENDRIER MULTI-DATES
  // ───────────────────────────────────────────────────────────────────────────
  static Future<void> showDateSheet(
    BuildContext context,
    TripProvider tripProvider,
    String lang,
  ) {
    final now = DateTime.now();
    DateTime currentMonth = DateTime(now.year, now.month, 1);

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (sheetCtx, setState) {
            final trip = tripProvider.trip;
            final isRtl = context.isRtl;
            final locale = lang == 'ar' ? 'ar' : lang == 'en' ? 'en_US' : 'fr_FR';

            final monthTitle = DateFormat('MMMM yyyy', locale).format(currentMonth);
            final capitalizedMonthTitle = monthTitle.isNotEmpty
                ? monthTitle[0].toUpperCase() + monthTitle.substring(1)
                : monthTitle;

            final canGoPrevious = currentMonth.isAfter(DateTime(now.year, now.month, 1));

            // Calcul des jours du mois
            final daysInMonth = DateTime(currentMonth.year, currentMonth.month + 1, 0).day;
            // DateTime.weekday: 1 = Lundi, 7 = Dimanche
            final firstWeekday = currentMonth.weekday; // 1 to 7
            final leadingBlanks = firstWeekday - 1;

            final weekdaysLabels = lang == 'ar'
                ? ['إث', 'ثل', 'أر', 'خم', 'جم', 'سب', 'أح']
                : lang == 'en'
                    ? ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                    : ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];

            final selectedCount = trip.dates.length + (trip.date != null && !trip.dates.contains(trip.date) ? 1 : 0);

            return Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              decoration: const BoxDecoration(
                color: VeynColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Poignée
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: VeynColors.line,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // En-tête de la feuille
                  Row(
                    textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: VeynColors.accentSoft,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(LucideIcons.calendar, size: 18, color: VeynColors.accent),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          context.tr('select_date'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: VeynColors.ink,
                          ),
                        ),
                      ),
                      if (selectedCount > 0)
                        TextButton(
                          onPressed: () {
                            tripProvider.removeField('date');
                            setState(() {});
                          },
                          child: Text(
                            context.tr('clear_filters'),
                            style: const TextStyle(fontSize: 12, color: VeynColors.accent, fontWeight: FontWeight.w600),
                          ),
                        ),
                      IconButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        icon: const Icon(LucideIcons.x, size: 18),
                        style: IconButton.styleFrom(visualDensity: VisualDensity.compact),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Barre de navigation du mois
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    decoration: BoxDecoration(
                      color: VeynColors.surfaceSunken,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: canGoPrevious
                              ? () {
                                  setState(() {
                                    currentMonth = DateTime(currentMonth.year, currentMonth.month - 1, 1);
                                  });
                                }
                              : null,
                          icon: Icon(
                            isRtl ? LucideIcons.chevronRight : LucideIcons.chevronLeft,
                            size: 18,
                            color: canGoPrevious ? VeynColors.ink : VeynColors.inkFaint,
                          ),
                          visualDensity: VisualDensity.compact,
                        ),
                        Text(
                          capitalizedMonthTitle,
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.bold,
                            color: VeynColors.ink,
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              currentMonth = DateTime(currentMonth.year, currentMonth.month + 1, 1);
                            });
                          },
                          icon: Icon(
                            isRtl ? LucideIcons.chevronLeft : LucideIcons.chevronRight,
                            size: 18,
                            color: VeynColors.ink,
                          ),
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Ligne des noms de jours (Lun - Dim)
                  Row(
                    children: weekdaysLabels.map((lbl) {
                      return Expanded(
                        child: Center(
                          child: Text(
                            lbl,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: VeynColors.inkMuted,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 8),

                  // Grille des jours du calendrier direct
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: leadingBlanks + daysInMonth,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 7,
                      mainAxisSpacing: 6,
                      crossAxisSpacing: 6,
                      childAspectRatio: 1.05,
                    ),
                    itemBuilder: (context, index) {
                      if (index < leadingBlanks) {
                        return const SizedBox.shrink();
                      }

                      final dayNumber = index - leadingBlanks + 1;
                      final dayDate = DateTime(currentMonth.year, currentMonth.month, dayNumber);
                      final dayStr = DateFormat('yyyy-MM-dd').format(dayDate);

                      final isPast = dayDate.isBefore(DateTime(now.year, now.month, now.day));
                      final isToday = dayDate.year == now.year &&
                          dayDate.month == now.month &&
                          dayDate.day == now.day;
                      final isSelected = trip.dates.contains(dayStr) || trip.date == dayStr;

                      return InkWell(
                        onTap: isPast
                            ? null
                            : () {
                                tripProvider.toggleDate(dayStr);
                                setState(() {});
                              },
                        borderRadius: BorderRadius.circular(20),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? VeynColors.accent
                                : (isToday ? VeynColors.accentSoft : Colors.transparent),
                            shape: BoxShape.circle,
                            border: isToday && !isSelected
                                ? Border.all(color: VeynColors.accent, width: 1.2)
                                : null,
                          ),
                          child: Text(
                            '$dayNumber',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.w500,
                              color: isSelected
                                  ? Colors.white
                                  : (isPast
                                      ? VeynColors.inkFaint.withValues(alpha: 0.5)
                                      : (isToday ? VeynColors.accent : VeynColors.ink)),
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 14),

                  // Résumé des dates sélectionnées si applicable
                  if (selectedCount > 0) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$selectedCount ${context.tr('date')}(s) sélectionnée(s)',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: VeynColors.accent,
                          ),
                        ),
                        Text(
                          'Sélection multiple active',
                          style: const TextStyle(
                            fontSize: 11,
                            color: VeynColors.inkMuted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],

                  // Bouton Confirmer
                  ElevatedButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: VeynColors.accent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                    child: Text(
                      context.tr('confirm'),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // FEUILLE 2 : SÉLECTION DE L'HEURE (PÉRIODES MATIN, APRÈS-MIDI, SOIR SUR 1 LIGNE)
  // ───────────────────────────────────────────────────────────────────────────
  static Future<void> showTimeSheet(
    BuildContext context,
    TripProvider tripProvider,
    String lang,
  ) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (sheetCtx, setState) {
            final trip = tripProvider.trip;
            final isRtl = context.isRtl;

            final isMorning = trip.periods.contains(TimePeriod.morning) || trip.period == TimePeriod.morning;
            final isAfternoon = trip.periods.contains(TimePeriod.afternoon) || trip.period == TimePeriod.afternoon;
            final isEvening = trip.periods.contains(TimePeriod.evening) || trip.period == TimePeriod.evening;
            final hasSelected = isMorning || isAfternoon || isEvening;

            return Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              decoration: const BoxDecoration(
                color: VeynColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Poignée
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: VeynColors.line,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // En-tête
                  Row(
                    textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: VeynColors.accentSoft,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(LucideIcons.clock, size: 18, color: VeynColors.accent),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          context.tr('select_time'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: VeynColors.ink,
                          ),
                        ),
                      ),
                      if (hasSelected)
                        TextButton(
                          onPressed: () {
                            tripProvider.removeField('time');
                            setState(() {});
                          },
                          child: Text(
                            context.tr('clear_filters'),
                            style: const TextStyle(fontSize: 12, color: VeynColors.accent, fontWeight: FontWeight.w600),
                          ),
                        ),
                      IconButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        icon: const Icon(LucideIcons.x, size: 18),
                        style: IconButton.styleFrom(visualDensity: VisualDensity.compact),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // LES TROIS PÉRIODES SUR UNE SEULE LIGNE [Matin] [Après-midi] [Soir]
                  Row(
                    textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                    children: [
                      // Matin
                      Expanded(
                        child: _buildTimePeriodTile(
                          label: context.tr('morning'),
                          range: context.tr('morning_range'),
                          icon: LucideIcons.sunrise,
                          isSelected: isMorning,
                          onTap: () {
                            tripProvider.togglePeriod(TimePeriod.morning);
                            setState(() {});
                          },
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Après-midi
                      Expanded(
                        child: _buildTimePeriodTile(
                          label: context.tr('afternoon'),
                          range: context.tr('afternoon_range'),
                          icon: LucideIcons.sun,
                          isSelected: isAfternoon,
                          onTap: () {
                            tripProvider.togglePeriod(TimePeriod.afternoon);
                            setState(() {});
                          },
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Soir
                      Expanded(
                        child: _buildTimePeriodTile(
                          label: context.tr('evening'),
                          range: context.tr('evening_range'),
                          icon: LucideIcons.moon,
                          isSelected: isEvening,
                          onTap: () {
                            tripProvider.togglePeriod(TimePeriod.evening);
                            setState(() {});
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  ElevatedButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: VeynColors.accent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                    child: Text(
                      context.tr('confirm'),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  static Widget _buildTimePeriodTile({
    required String label,
    required String range,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected ? VeynColors.accentSoft : VeynColors.surfaceSunken,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? VeynColors.accent : VeynColors.line,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? VeynColors.accent : VeynColors.inkMuted,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? VeynColors.accent : VeynColors.ink,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              range,
              style: TextStyle(
                fontSize: 10,
                color: isSelected ? VeynColors.accent.withValues(alpha: 0.8) : VeynColors.inkMuted,
              ),
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // FEUILLE 3 : SÉLECTION SOBRE DES VOYAGEURS (ICÔNES GRISES, NOMS NOIRS, ROUGE ACTIF)
  // ───────────────────────────────────────────────────────────────────────────
  static Future<void> showTravelersSheet(
    BuildContext context,
    TripProvider tripProvider,
    String lang,
  ) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (sheetCtx, setState) {
            final trip = tripProvider.trip;
            final isRtl = context.isRtl;

            return Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              decoration: const BoxDecoration(
                color: VeynColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: VeynColors.line,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: VeynColors.accentSoft,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(LucideIcons.users, size: 18, color: VeynColors.accent),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          context.tr('select_travelers'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: VeynColors.ink,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        icon: const Icon(LucideIcons.x, size: 18),
                        style: IconButton.styleFrom(visualDensity: VisualDensity.compact),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 1. Adulte
                  _buildSoberCounterRow(
                    context: context,
                    icon: LucideIcons.user,
                    title: context.tr('adults'),
                    subtitle: context.tr('adults_hint'),
                    count: trip.travelers.adults,
                    isRtl: isRtl,
                    onChanged: (val) {
                      tripProvider.patchTrip({
                        'travelers': trip.travelers.copyWith(adults: val),
                      });
                      setState(() {});
                    },
                  ),

                  const SizedBox(height: 10),

                  // 2. Enfant
                  _buildSoberCounterRow(
                    context: context,
                    icon: LucideIcons.smile,
                    title: context.tr('children'),
                    subtitle: context.tr('children_hint'),
                    count: trip.travelers.children,
                    isRtl: isRtl,
                    onChanged: (val) {
                      tripProvider.patchTrip({
                        'travelers': trip.travelers.copyWith(children: val),
                      });
                      setState(() {});
                    },
                  ),

                  const SizedBox(height: 10),

                  // 3. Personne en situation de handicap / mobilité réduite
                  _buildSoberCounterRow(
                    context: context,
                    icon: LucideIcons.accessibility,
                    title: context.tr('assisted'),
                    subtitle: context.tr('assisted_hint'),
                    count: trip.travelers.assisted,
                    isRtl: isRtl,
                    onChanged: (val) {
                      tripProvider.patchTrip({
                        'travelers': trip.travelers.copyWith(assisted: val),
                      });
                      setState(() {});
                    },
                  ),

                  const SizedBox(height: 20),

                  ElevatedButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: VeynColors.accent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                    child: Text(
                      context.tr('confirm'),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  static Widget _buildSoberCounterRow({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required int count,
    required bool isRtl,
    required Function(int) onChanged,
  }) {
    final isActive = count > 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isActive ? VeynColors.accentSoft.withValues(alpha: 0.25) : VeynColors.surfaceSunken,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isActive ? VeynColors.accent.withValues(alpha: 0.35) : VeynColors.line,
          width: isActive ? 1.2 : 1,
        ),
      ),
      child: Row(
        textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
        children: [
          // Style gris pour l'icône
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: VeynColors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: VeynColors.line),
            ),
            child: Icon(icon, size: 18, color: VeynColors.inkMuted),
          ),
          const SizedBox(width: 12),
          // Texte noir pour le nom
          Expanded(
            child: Column(
              crossAxisAlignment: isRtl ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: VeynColors.ink,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 11, color: VeynColors.inkMuted),
                ),
              ],
            ),
          ),
          // Contrôles - / +
          Row(
            children: [
              IconButton(
                onPressed: count > 0 ? () => onChanged(count - 1) : null,
                icon: const Icon(LucideIcons.minus, size: 14),
                style: IconButton.styleFrom(
                  backgroundColor: VeynColors.surface,
                  foregroundColor: count > 0 ? VeynColors.ink : VeynColors.inkFaint,
                  side: const BorderSide(color: VeynColors.line),
                  padding: const EdgeInsets.all(6),
                  visualDensity: VisualDensity.compact,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isActive ? VeynColors.accent : VeynColors.inkMuted,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => onChanged(count + 1),
                icon: const Icon(LucideIcons.plus, size: 14),
                style: IconButton.styleFrom(
                  backgroundColor: isActive ? VeynColors.accentSoft : VeynColors.surface,
                  foregroundColor: isActive ? VeynColors.accent : VeynColors.ink,
                  side: BorderSide(color: isActive ? VeynColors.accent : VeynColors.line),
                  padding: const EdgeInsets.all(6),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // FEUILLE 4 : SÉLECTION DU MODE DE TRANSPORT
  // ───────────────────────────────────────────────────────────────────────────
  static Future<void> showTransportSheet(
    BuildContext context,
    TripProvider tripProvider,
    String lang,
  ) {
    final transportOptions = getTransportOptions(context);

    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (sheetCtx, setState) {
            final trip = tripProvider.trip;
            final isRtl = context.isRtl;

            return Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              decoration: const BoxDecoration(
                color: VeynColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: VeynColors.line,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: VeynColors.accentSoft,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(LucideIcons.bus, size: 18, color: VeynColors.accent),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          context.tr('select_transport'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: VeynColors.ink,
                          ),
                        ),
                      ),
                      if (trip.modes.isNotEmpty)
                        TextButton(
                          onPressed: () {
                            tripProvider.removeField('modes');
                            setState(() {});
                          },
                          child: Text(
                            context.tr('clear_filters'),
                            style: const TextStyle(fontSize: 12, color: VeynColors.accent, fontWeight: FontWeight.w600),
                          ),
                        ),
                      IconButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        icon: const Icon(LucideIcons.x, size: 18),
                        style: IconButton.styleFrom(visualDensity: VisualDensity.compact),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                    children: transportOptions.map((opt) {
                      final isSelected = trip.modes.contains(opt.id);

                      return InkWell(
                        onTap: () {
                          tripProvider.toggleMode(opt.id);
                          setState(() {});
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? VeynColors.accentSoft : VeynColors.surfaceSunken,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected ? VeynColors.accent : VeynColors.line,
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                opt.icon,
                                size: 16,
                                color: isSelected ? VeynColors.accent : VeynColors.inkSoft,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                opt.label,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  color: isSelected ? VeynColors.accent : VeynColors.ink,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 20),

                  ElevatedButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: VeynColors.accent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                    child: Text(
                      context.tr('confirm'),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
