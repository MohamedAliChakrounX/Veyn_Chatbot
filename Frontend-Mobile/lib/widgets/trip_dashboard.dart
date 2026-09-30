import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../data/locations.dart';
import '../l10n/translations.dart';
import '../models/trip.dart';
import '../providers/language_provider.dart';
import '../providers/trip_provider.dart';
import '../theme/colors.dart';
import 'location_picker_sheet.dart';
import 'quick_selection_sheets.dart';

/// Tableau de bord du trajet masquable avec badge de précisions :
///
/// Ligne 1 : [📍 Départ]  ➔  [📍 Destination]
/// Ligne 2 : [📅 Dates sélectionnées]     [🌅 ☀️ 🌙 Créneaux horaires (icônes)]
/// Ligne 3 : [🚗 🚌 🚆 Transports (icônes)] [👤 2 👶 1 Voyageurs (icônes + compteurs)]
///
/// Peut être masqué en appuyant sur la flèche vers le haut.
/// Lorsque masqué, un badge indique le nombre de précisions actives.
class TripDashboard extends StatefulWidget {
  final VoidCallback onSearch;

  const TripDashboard({
    super.key,
    required this.onSearch,
  });

  @override
  State<TripDashboard> createState() => _TripDashboardState();
}

class _TripDashboardState extends State<TripDashboard> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    final tripProvider = context.watch<TripProvider>();
    final lang = context.watch<LanguageProvider>().languageCode;
    final isRtl = context.isRtl;
    final trip = tripProvider.trip;
    final precisionsCount = tripProvider.activePrecisionsCount;

    final hasRoute = trip.origin != null || trip.destination != null;
    final canSearch = trip.origin != null && trip.destination != null;

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 4, 14, 8),
      decoration: BoxDecoration(
        color: VeynColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: hasRoute ? VeynColors.lineStrong : VeynColors.line,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ─────────────────────────────────────────────────────────────────
          // EN-TÊTE : Badge de précisions + Flèche masquer/afficher
          // ─────────────────────────────────────────────────────────────────
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: _isExpanded
                ? const BorderRadius.only(
                    topLeft: Radius.circular(18),
                    topRight: Radius.circular(18),
                  )
                : BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                children: [
                  // Icône tableau de bord
                  Icon(
                    LucideIcons.slidersHorizontal,
                    size: 14,
                    color: hasRoute ? VeynColors.ink : VeynColors.inkMuted,
                  ),
                  const SizedBox(width: 8),

                  // Titre
                  Expanded(
                    child: Text(
                      context.tr('trip_dashboard'),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: hasRoute ? VeynColors.ink : VeynColors.inkMuted,
                      ),
                    ),
                  ),

                  // Badge — nombre de précisions actives (toujours visible)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: precisionsCount > 0
                          ? VeynColors.accent
                          : VeynColors.lineStrong,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$precisionsCount',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.1,
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Flèche vers le haut (ouvert) / bas (fermé)
                  AnimatedRotation(
                    turns: _isExpanded ? 0.0 : 0.5,
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    child: Icon(
                      LucideIcons.chevronUp,
                      size: 16,
                      color: VeynColors.inkMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ─────────────────────────────────────────────────────────────────
          // CORPS : Affiché uniquement quand _isExpanded == true
          // ─────────────────────────────────────────────────────────────────
          AnimatedSize(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: _isExpanded
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Divider(height: 1, color: VeynColors.line),
                        const SizedBox(height: 8),

                        // LIGNE 1 — TRAJET : [📍 Départ] ➔ [📍 Destination]
                        Row(
                          textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                          children: [
                            Expanded(
                              child: _buildLocationBox(
                                context: context,
                                isOrigin: true,
                                city: trip.origin,
                                lang: lang,
                                isRtl: isRtl,
                                onTap: () {
                                  LocationPickerSheet.show(
                                    context: context,
                                    isOrigin: true,
                                    currentCity: trip.origin,
                                    excludeCityId: trip.destination?.id,
                                    lang: lang,
                                    onSelectCity: (city) {
                                      tripProvider.patchTrip({'origin': city});
                                    },
                                  );
                                },
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 6),
                              child: InkWell(
                                onTap: hasRoute ? () => tripProvider.swapCities() : null,
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  padding: const EdgeInsets.all(7),
                                  decoration: BoxDecoration(
                                    color: hasRoute ? VeynColors.surfaceSunken : VeynColors.surfaceSunken,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: hasRoute ? VeynColors.lineStrong : VeynColors.line,
                                      width: hasRoute ? 1.2 : 1,
                                    ),
                                  ),
                                  child: Icon(
                                    isRtl ? LucideIcons.arrowLeft : LucideIcons.arrowRight,
                                    size: 14,
                                    color: hasRoute ? VeynColors.ink : VeynColors.inkMuted,
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: _buildLocationBox(
                                context: context,
                                isOrigin: false,
                                city: trip.destination,
                                lang: lang,
                                isRtl: isRtl,
                                onTap: () {
                                  LocationPickerSheet.show(
                                    context: context,
                                    isOrigin: false,
                                    currentCity: trip.destination,
                                    excludeCityId: trip.origin?.id,
                                    lang: lang,
                                    onSelectCity: (city) {
                                      tripProvider.patchTrip({'destination': city});
                                    },
                                  );
                                },
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        // LIGNE 2 — DATE ET CRÉNEAUX HORAIRES
                        Row(
                          textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                          children: [
                            Expanded(
                              child: _buildDateBox(
                                context: context,
                                trip: trip,
                                lang: lang,
                                onTap: () => QuickSelectionSheets.showDateSheet(context, tripProvider, lang),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildTimeBox(
                                context: context,
                                trip: trip,
                                lang: lang,
                                onTap: () => QuickSelectionSheets.showTimeSheet(context, tripProvider, lang),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        // LIGNE 3 — TRANSPORTS ET VOYAGEURS
                        Row(
                          textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                          children: [
                            Expanded(
                              child: _buildTransportBox(
                                context: context,
                                trip: trip,
                                lang: lang,
                                onTap: () => QuickSelectionSheets.showTransportSheet(context, tripProvider, lang),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildTravelersBox(
                                context: context,
                                trip: trip,
                                onTap: () => QuickSelectionSheets.showTravelersSheet(context, tripProvider, lang),
                              ),
                            ),
                          ],
                        ),

                        // BOUTON RECHERCHER
                        if (canSearch) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: widget.onSearch,
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: VeynColors.accent,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: VeynColors.accent.withValues(alpha: 0.3),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(LucideIcons.search, size: 14, color: Colors.white),
                                        const SizedBox(width: 6),
                                        Text(
                                          context.tr('search_trips_btn'),
                                          style: const TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              if (!trip.isEmpty) ...[
                                const SizedBox(width: 6),
                                InkWell(
                                  onTap: () => tripProvider.resetTrip(),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    height: 38,
                                    width: 38,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: VeynColors.surfaceSunken,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: VeynColors.line),
                                    ),
                                    child: const Icon(
                                      LucideIcons.rotateCcw,
                                      size: 14,
                                      color: VeynColors.inkMuted,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // LIGNE 1 : BOÎTE DE LIEU [📍 Ville] (CONSERVÉE TELLE QUELLE)
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildLocationBox({
    required BuildContext context,
    required bool isOrigin,
    required City? city,
    required String lang,
    required bool isRtl,
    required VoidCallback onTap,
  }) {
    final hasValue = city != null;
    final flag = hasValue ? getCountryFlag(city.country) : '';
    final cityName = hasValue ? localizeCityName(city.name, lang) : '';
    final defaultLabel = isOrigin ? context.tr('departure') : context.tr('destination');

    final iconColor = VeynColors.amberText;
    final iconBg = VeynColors.amberSoft;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        decoration: BoxDecoration(
          color: hasValue ? iconBg.withValues(alpha: 0.25) : VeynColors.surfaceSunken,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasValue ? iconColor.withValues(alpha: 0.35) : VeynColors.line,
            width: hasValue ? 1.2 : 1,
          ),
        ),
        child: Row(
          textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
          children: [
            // Drapeau ou icône de position
            Container(
              width: 26,
              height: 26,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: hasValue ? Colors.white : VeynColors.surface,
                shape: BoxShape.circle,
                border: Border.all(
                  color: hasValue ? iconColor.withValues(alpha: 0.3) : VeynColors.line,
                ),
              ),
              child: hasValue
                  ? Text(flag, style: const TextStyle(fontSize: 14))
                  : Icon(
                      isOrigin ? LucideIcons.mapPin : LucideIcons.navigation,
                      size: 13,
                      color: iconColor,
                    ),
            ),
            const SizedBox(width: 7),
            // Nom de la ville ou libellé Départ/Destination
            Expanded(
              child: Text(
                hasValue ? cityName : defaultLabel,
                style: TextStyle(
                  fontSize: hasValue ? 13.5 : 12.5,
                  fontWeight: hasValue ? FontWeight.bold : FontWeight.w600,
                  color: hasValue ? VeynColors.ink : VeynColors.inkMuted,
                ),
                maxLines: 1,
                overflow: TextOverflow.clip,
                softWrap: false,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // LIGNE 2 : BOÎTE DATE DYNAMIQUE (SUPPORT SÉLECTION MULTIPLE DE DATES)
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildDateBox({
    required BuildContext context,
    required TripQuery trip,
    required String lang,
    required VoidCallback onTap,
  }) {
    final hasDate = trip.date != null || trip.dates.isNotEmpty;

    // Calcul du libellé dynamique des dates sélectionnées
    String displayText = context.tr('date');
    if (trip.dates.isNotEmpty) {
      if (trip.dates.length == 1) {
        displayText = _formatCompactDate(trip.dates.first, context, lang);
      } else {
        // Affiche les dates multiples séparées : ex. "15 oct. • 18 oct."
        displayText = trip.dates
            .map((d) => _formatCompactDate(d, context, lang))
            .join(' • ');
      }
    } else if (trip.date != null) {
      displayText = _formatCompactDate(trip.date!, context, lang);
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: hasDate ? VeynColors.accentSoft : VeynColors.surfaceSunken,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasDate ? VeynColors.accent.withValues(alpha: 0.4) : VeynColors.line,
            width: hasDate ? 1.2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              LucideIcons.calendar,
              size: 15,
              color: hasDate ? VeynColors.accent : VeynColors.inkMuted,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                displayText,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: hasDate ? FontWeight.bold : FontWeight.w600,
                  color: hasDate ? VeynColors.accent : VeynColors.inkMuted,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // LIGNE 2 : BOÎTE CRÉNEAUX HORAIRES (ICÔNES GRAPHIQUES CÔTE À CÔTE)
  // [🌅 Matin] [☀️ Après-midi] [🌙 Soir]
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildTimeBox({
    required BuildContext context,
    required TripQuery trip,
    required String lang,
    required VoidCallback onTap,
  }) {
    final hasPeriods = trip.periods.isNotEmpty || trip.period != null;
    final hasExactTime = trip.exactTime != null && trip.exactTime!.isNotEmpty;
    final isActive = hasPeriods || hasExactTime;

    // Récupère la liste de tous les créneaux sélectionnés
    final Set<TimePeriod> activePeriods = {};
    if (trip.periods.isNotEmpty) {
      activePeriods.addAll(trip.periods);
    } else if (trip.period != null) {
      activePeriods.add(trip.period!);
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? VeynColors.accentSoft : VeynColors.surfaceSunken,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? VeynColors.accent.withValues(alpha: 0.4) : VeynColors.line,
            width: isActive ? 1.2 : 1,
          ),
        ),
        child: isActive
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icône Matin 🌅
                  if (activePeriods.contains(TimePeriod.morning)) ...[
                    const Icon(LucideIcons.sunrise, size: 16, color: VeynColors.accent),
                  ],

                  // Icône Après-midi ☀️
                  if (activePeriods.contains(TimePeriod.afternoon)) ...[
                    if (activePeriods.contains(TimePeriod.morning)) const SizedBox(width: 8),
                    const Icon(LucideIcons.sun, size: 16, color: VeynColors.accent),
                  ],

                  // Icône Soir 🌙
                  if (activePeriods.contains(TimePeriod.evening)) ...[
                    if (activePeriods.contains(TimePeriod.morning) || activePeriods.contains(TimePeriod.afternoon))
                      const SizedBox(width: 8),
                    const Icon(LucideIcons.moon, size: 16, color: VeynColors.accent),
                  ],

                  // Heure exacte (si renseignée)
                  if (hasExactTime) ...[
                    if (activePeriods.isNotEmpty) const SizedBox(width: 8),
                    const Icon(LucideIcons.clock, size: 13, color: VeynColors.accent),
                    const SizedBox(width: 3),
                    Text(
                      trip.exactTime!,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: VeynColors.accent,
                      ),
                    ),
                  ],
                ],
              )
            : Row(
                children: [
                  const Icon(
                    LucideIcons.clock,
                    size: 15,
                    color: VeynColors.inkMuted,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    context.tr('time'),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: VeynColors.inkMuted,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // LIGNE 3 : BOÎTE TRANSPORT (UNIQUEMENT LES ICÔNES CÔTE À CÔTE [🚗] [🚌] [🚆])
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildTransportBox({
    required BuildContext context,
    required TripQuery trip,
    required String lang,
    required VoidCallback onTap,
  }) {
    final hasTransport = trip.modes.isNotEmpty;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: hasTransport ? VeynColors.accentSoft : VeynColors.surfaceSunken,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasTransport ? VeynColors.accent.withValues(alpha: 0.4) : VeynColors.line,
            width: hasTransport ? 1.2 : 1,
          ),
        ),
        child: hasTransport
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (int i = 0; i < trip.modes.length; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    Icon(
                      _getModeIcon(trip.modes[i]),
                      size: 16,
                      color: VeynColors.accent,
                    ),
                  ],
                ],
              )
            : Row(
                children: [
                  const Icon(
                    LucideIcons.car,
                    size: 15,
                    color: VeynColors.inkMuted,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    context.tr('transport'),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: VeynColors.inkMuted,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // LIGNE 3 : BOÎTE VOYAGEURS DYNAMIQUE (ICÔNES ET NOMBRES VISUELS)
  // [👤 2] [👶 1] [♿ 1]
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildTravelersBox({
    required BuildContext context,
    required TripQuery trip,
    required VoidCallback onTap,
  }) {
    final t = trip.travelers;
    final hasTravelers = t.total > 0;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: hasTravelers ? VeynColors.accentSoft : VeynColors.surfaceSunken,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasTravelers ? VeynColors.accent.withValues(alpha: 0.4) : VeynColors.line,
            width: hasTravelers ? 1.2 : 1,
          ),
        ),
        child: hasTravelers
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 👤 Adultes
                  if (t.adults > 0) ...[
                    const Icon(LucideIcons.user, size: 14, color: VeynColors.inkMuted),
                    const SizedBox(width: 3),
                    Text(
                      '${t.adults}',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: VeynColors.accent,
                      ),
                    ),
                  ],

                  // 👶 Enfants
                  if (t.children > 0) ...[
                    if (t.adults > 0) const SizedBox(width: 8),
                    const Icon(LucideIcons.smile, size: 14, color: VeynColors.inkMuted),
                    const SizedBox(width: 3),
                    Text(
                      '${t.children}',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: VeynColors.accent,
                      ),
                    ),
                  ],

                  // ♿ Personnes en situation de handicap (PMR / Assistance)
                  if (t.assisted > 0) ...[
                    if (t.adults > 0 || t.children > 0) const SizedBox(width: 8),
                    const Icon(LucideIcons.accessibility, size: 14, color: VeynColors.inkMuted),
                    const SizedBox(width: 3),
                    Text(
                      '${t.assisted}',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: VeynColors.accent,
                      ),
                    ),
                  ],
                ],
              )
            : Row(
                children: [
                  const Icon(LucideIcons.users, size: 15, color: VeynColors.inkMuted),
                  const SizedBox(width: 8),
                  Text(
                    context.tr('travelers'),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: VeynColors.inkMuted,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // AIDES DE FORMATAGE ET D'ICÔNES
  // ───────────────────────────────────────────────────────────────────────────
  String _formatCompactDate(String dateStr, BuildContext context, String lang) {
    try {
      final parsed = DateTime.parse(dateStr);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final target = DateTime(parsed.year, parsed.month, parsed.day);
      final diff = target.difference(today).inDays;

      if (diff == 0) return context.tr('today');
      if (diff == 1) return context.tr('tomorrow');

      final locale = lang == 'ar' ? 'ar' : lang == 'en' ? 'en_US' : 'fr_FR';
      return DateFormat('d MMM', locale).format(parsed);
    } catch (_) {
      return dateStr;
    }
  }

  IconData _getModeIcon(TransportMode mode) {
    switch (mode) {
      case TransportMode.bus:
        return LucideIcons.bus;
      case TransportMode.sharedTaxi:
        return LucideIcons.car;
      case TransportMode.train:
        return LucideIcons.train;
      case TransportMode.plane:
        return LucideIcons.plane;
      case TransportMode.ferry:
        return LucideIcons.ship;
      case TransportMode.other:
        return LucideIcons.moreHorizontal;
    }
  }
}
