import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../data/locations.dart';
import '../l10n/translations.dart';
import '../models/trip.dart';
import '../providers/language_provider.dart';
import 'package:provider/provider.dart';
import '../theme/colors.dart';
import 'stops_timeline.dart';

/// Formate une date ISO (yyyy-MM-dd) en label localisé court.
/// Exemple: "2024-05-15" → "15 mai" (fr), "May 15" (en), "15 مايو" (ar)
String _formatDateLabel(String? dateStr, String lang) {
  if (dateStr == null || dateStr.isEmpty) return '';
  try {
    final parts = dateStr.split('-');
    if (parts.length != 3) return dateStr;
    final day = int.parse(parts[2]);
    final month = int.parse(parts[1]);
    if (month < 1 || month > 12) return dateStr;

    const monthsFr = ['janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin', 'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.'];
    const monthsEn = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    const monthsAr = ['يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو', 'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'];

    final idx = month - 1;
    if (lang == 'ar') return '$day ${monthsAr[idx]}';
    if (lang == 'en') return '${monthsEn[idx]} $day';
    return '$day ${monthsFr[idx]}';
  } catch (_) {
    return dateStr;
  }
}

class ResultCard extends StatefulWidget {
  final List<TripResult> trips;
  final bool featured;
  final Function(TripResult) onBook;

  const ResultCard({
    super.key,
    required this.trips,
    this.featured = false,
    required this.onBook,
  });

  @override
  State<ResultCard> createState() => _ResultCardState();
}

class _ResultCardState extends State<ResultCard> {
  String _selectedDate = '';
  String _selectedTripId = '';
  bool _stopsOpen = false;

  @override
  void initState() {
    super.initState();
    _initSelection();
  }

  @override
  void didUpdateWidget(ResultCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.trips != widget.trips) {
      final dates = _availableDates;
      if (!dates.contains(_selectedDate)) {
        if (dates.isNotEmpty) _selectedDate = dates.first;
      }
      final trips = _tripsForDate;
      if (!trips.any((t) => t.id == _selectedTripId)) {
        _selectedTripId = trips.isNotEmpty ? trips.first.id : '';
      }
    }
  }

  void _initSelection() {
    final dates = _availableDates;
    if (dates.isNotEmpty) _selectedDate = dates.first;
    final trips = _tripsForDate;
    _selectedTripId = trips.isNotEmpty ? trips.first.id : (widget.trips.isNotEmpty ? widget.trips.first.id : '');
  }

  List<String> get _availableDates {
    final seen = <String>{};
    final result = <String>[];
    for (final t in widget.trips) {
      final d = t.date ?? '';
      if (d.isNotEmpty && seen.add(d)) result.add(d);
    }
    // Si moins de 2 dates sont fournies, proposer automatiquement les 5 prochains jours
    if (result.length < 2) {
      DateTime baseDate = DateTime.now();
      if (result.isNotEmpty) {
        try {
          baseDate = DateTime.parse(result.first);
        } catch (_) {}
      }
      for (int i = 0; i < 5; i++) {
        final nextDay = baseDate.add(Duration(days: i));
        final yyyy = nextDay.year.toString();
        final mm = nextDay.month.toString().padLeft(2, '0');
        final dd = nextDay.day.toString().padLeft(2, '0');
        final formatted = '$yyyy-$mm-$dd';
        if (seen.add(formatted)) {
          result.add(formatted);
        }
      }
    }
    result.sort();
    return result;
  }

  List<TripResult> get _tripsForDate {
    if (_selectedDate.isEmpty) return widget.trips;
    final filtered = widget.trips.where((t) => t.date == _selectedDate).toList();
    if (filtered.isNotEmpty) {
      return filtered..sort((a, b) => a.departure.compareTo(b.departure));
    }
    // Projeter les horaires existants sur la date sélectionnée
    return widget.trips.map((t) => t.copyWith(date: _selectedDate)).toList()
      ..sort((a, b) => a.departure.compareTo(b.departure));
  }

  TripResult get _currentTrip {
    final trips = _tripsForDate;
    if (trips.isEmpty) return widget.trips.first;
    final found = trips.firstWhere(
      (t) => t.id == _selectedTripId,
      orElse: () => trips.first,
    );
    return found.copyWith(date: _selectedDate.isNotEmpty ? _selectedDate : found.date);
  }

  IconData _modeIcon(TransportMode mode) {
    switch (mode) {
      case TransportMode.bus:        return LucideIcons.bus;
      case TransportMode.sharedTaxi: return LucideIcons.car;
      case TransportMode.train:      return LucideIcons.train;
      case TransportMode.plane:      return LucideIcons.plane;
      case TransportMode.ferry:      return LucideIcons.ship;
      default:                       return LucideIcons.moreHorizontal;
    }
  }

  String _modeLabel(BuildContext context, TransportMode mode) {
    switch (mode) {
      case TransportMode.bus:        return context.tr('bus');
      case TransportMode.sharedTaxi: return context.tr('shared_taxi');
      case TransportMode.train:      return context.tr('train');
      case TransportMode.plane:      return context.tr('plane');
      case TransportMode.ferry:      return context.tr('ferry');
      default:                       return context.tr('other');
    }
  }

  String? _badgeLabel(BuildContext context, String? raw) {
    if (raw == null) return null;
    final l = raw.toLowerCase();
    if (l.contains('meilleur') || l.contains('best') || l.contains('أفضل')) {
      return context.tr('best_rate');
    }
    return raw;
  }

  String _seatsLabel(int seats, String lang) {
    if (lang == 'ar') {
      if (seats == 1) return 'مقعد واحد متبقٍ';
      if (seats >= 2 && seats <= 10) return '$seats مقاعد متبقية';
      return '$seats مقعداً متبقياً';
    }
    if (lang == 'en') {
      return seats <= 1 ? '$seats seat left' : '$seats seats left';
    }
    // Français
    return seats <= 1 ? '$seats place restante' : '$seats places restantes';
  }

  @override
  Widget build(BuildContext context) {
    final isRtl = context.isRtl;
    final lang = context.watch<LanguageProvider>().languageCode;
    final trip = _currentTrip;
    final stops = trip.stops;
    final intermediate = stops.where((s) => s.kind == StopKind.stop || s.kind == StopKind.border).toList();
    final availableDates = _availableDates;
    final tripsForDate = _tripsForDate;
    final badge = _badgeLabel(context, trip.badge);
    final arrowSymbol = isRtl ? '←' : '→';
    final dateLabel = _formatDateLabel(
      _selectedDate.isNotEmpty ? _selectedDate : trip.date,
      lang,
    );
    final localizedCurrency = formatCurrency(trip.currency, lang);
    final priceStr =
        '${trip.price.toStringAsFixed(trip.price.truncateToDouble() == trip.price ? 0 : 2)} $localizedCurrency';

    // Noms de villes localisés (depuis stops s'ils existent)
    final originName = localizeCityName(
      stops.isNotEmpty ? stops.first.name : trip.departure,
      lang,
    );
    final destName = localizeCityName(
      stops.isNotEmpty ? stops.last.name : trip.arrival,
      lang,
    );

    // Arrêts avec noms localisés pour StopsTimeline
    final localizedStops = stops.map((s) => TripStop(
      name: localizeCityName(s.name, lang),
      place: s.place,
      time: s.time,
      kind: s.kind,
      waitMinutes: s.waitMinutes,
    )).toList();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: VeynColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.featured ? VeynColors.accent.withValues(alpha: 0.35) : VeynColors.line,
          width: widget.featured ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── 1. En-tête : Badge | Mode · Transferts · Durée (2 lignes anti-overflow) ──
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
            child: Column(
              crossAxisAlignment: isRtl ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                // Ligne 1a : Badge meilleur tarif (si présent)
                if (badge != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: widget.featured ? VeynColors.accent : VeynColors.accentSoft,
                      borderRadius: BorderRadius.circular(20),
                      border: widget.featured
                          ? null
                          : Border.all(color: VeynColors.accentBorder),
                    ),
                    child: Text(
                      badge,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                        color: widget.featured ? Colors.white : VeynColors.accent,
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                ],
                // Ligne 1b : Icône mode + label + · + Direct/Transferts + · + Durée
                // Utilise Wrap pour éviter tout overflow horizontal
                Wrap(
                  spacing: 0,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                  children: [
                    // Icône + label du mode
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                      children: [
                        Icon(_modeIcon(trip.mode), size: 12, color: VeynColors.accent),
                        const SizedBox(width: 4),
                        Text(
                          _modeLabel(context, trip.mode),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: VeynColors.inkSoft,
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6),
                          child: Text('·', style: TextStyle(fontSize: 11, color: VeynColors.inkFaint)),
                        ),
                      ],
                    ),
                    // Direct / transferts
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          trip.transfers == 0
                              ? context.tr('direct')
                              : '${trip.transfers} ${trip.transfers > 1 ? context.tr('transfers_plural') : context.tr('transfer_singular')}',
                          style: TextStyle(
                            fontSize: 11,
                            color: trip.transfers == 0 ? VeynColors.emeraldText : VeynColors.inkMuted,
                            fontWeight: trip.transfers == 0 ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6),
                          child: Text('·', style: TextStyle(fontSize: 11, color: VeynColors.inkFaint)),
                        ),
                      ],
                    ),
                    // Durée
                    Text(
                      '${context.tr('duration_prefix')} ${trip.durationLabel}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: VeynColors.inkMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── 2. Ligne Route : Origine → Destination & Prix ────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 6, 14, 14),
            child: Row(
              textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Expanded(
                  child: Text.rich(
                    TextSpan(children: [
                      TextSpan(
                        text: originName,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: VeynColors.ink),
                      ),
                      TextSpan(
                        text: '  $arrowSymbol  ',
                        style: const TextStyle(fontSize: 13, color: VeynColors.inkFaint, fontWeight: FontWeight.normal),
                      ),
                      TextSpan(
                        text: destName,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: VeynColors.ink),
                      ),
                    ]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                  ),
                ),
                const SizedBox(width: 12),
                // Prix toujours en rouge (accent)
                Text(
                  priceStr,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: VeynColors.accent,
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: VeynColors.line),

          // ── 3. Sélecteur de dates ─────────────────────────────────────────
          if (availableDates.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
              child: Column(
                crossAxisAlignment: isRtl ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Row(
                    textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                        children: [
                          const Icon(LucideIcons.calendar, size: 13, color: VeynColors.accent),
                          const SizedBox(width: 5),
                          Text(
                            context.tr('available_dates'),
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: VeynColors.ink),
                          ),
                        ],
                      ),
                      Text(
                        '${availableDates.length} ${context.tr('dates_count')}',
                        style: const TextStyle(fontSize: 11, color: VeynColors.inkMuted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                      children: availableDates.map((dateStr) {
                        final isSelected = dateStr == _selectedDate;
                        final label = _formatDateLabel(dateStr, lang);
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedDate = dateStr;
                              final updated = _tripsForDate;
                              if (updated.isNotEmpty) _selectedTripId = updated.first.id;
                              _stopsOpen = false;
                            });
                          },
                          child: Container(
                            margin: const EdgeInsetsDirectional.only(end: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: isSelected ? VeynColors.accent : VeynColors.surface,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected ? VeynColors.accent : VeynColors.line,
                                width: isSelected ? 1.5 : 1.0,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: VeynColors.accent.withValues(alpha: 0.25),
                                        blurRadius: 4,
                                        offset: const Offset(0, 1),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Text(
                              label,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                color: isSelected ? Colors.white : VeynColors.inkMuted,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // ── 4. Sélecteur d'horaires ────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
            child: Column(
              crossAxisAlignment: isRtl ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                // En-tête : icône horloge + label + compteur
                Row(
                  textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                      children: [
                        const Icon(LucideIcons.clock, size: 13, color: VeynColors.accent),
                        const SizedBox(width: 5),
                        Text(
                          tripsForDate.length > 1
                              ? context.tr('select_schedule')
                              : context.tr('available_schedule'),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: VeynColors.ink,
                          ),
                        ),
                      ],
                    ),
                    // Badge compteur de départs
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: VeynColors.accentSoft,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: VeynColors.accentBorder),
                      ),
                      child: Text(
                        '${tripsForDate.length} ${context.tr('departures_count')}',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: VeynColors.accent,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Liste des créneaux horaires — chaque créneau sur 2 lignes claires
                ...tripsForDate.map((item) {
                  final isSelected = item.id == _selectedTripId;
                  final seats = item.seatsLeft;
                  final isLow = seats != null && seats <= 3;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _selectedTripId = item.id;
                        _stopsOpen = false;
                      }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        curve: Curves.easeInOut,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? VeynColors.accent.withValues(alpha: 0.08)
                              : VeynColors.surfaceSunken,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected ? VeynColors.accent : VeynColors.line,
                            width: isSelected ? 1.5 : 1.0,
                          ),
                        ),
                        child: Row(
                          textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Puce radio
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 160),
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected ? VeynColors.accent : VeynColors.inkFaint,
                                  width: isSelected ? 2 : 1.5,
                                ),
                                color: isSelected ? VeynColors.accent : Colors.transparent,
                              ),
                              child: isSelected
                                  ? const Icon(Icons.check, size: 11, color: Colors.white)
                                  : null,
                            ),
                            const SizedBox(width: 10),

                            // Contenu du créneau : ligne 1 = horaires, ligne 2 = durée + places
                            Expanded(
                              child: Column(
                                crossAxisAlignment: isRtl
                                    ? CrossAxisAlignment.end
                                    : CrossAxisAlignment.start,
                                children: [
                                  // Ligne 1 : DÉPART → ARRIVÉE
                                  Row(
                                    textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        item.departure,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                          color: isSelected ? VeynColors.accent : VeynColors.ink,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 6),
                                        child: Text(
                                          arrowSymbol,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isSelected
                                                ? VeynColors.accent.withValues(alpha: 0.6)
                                                : VeynColors.inkFaint,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        item.arrival,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                          color: isSelected ? VeynColors.accent : VeynColors.ink,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  // Ligne 2 : durée · places restantes
                                  Row(
                                    textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                                    children: [
                                      Text(
                                        item.durationLabel,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                          color: VeynColors.inkMuted,
                                        ),
                                      ),
                                      if (seats != null) ...[
                                        const Padding(
                                          padding: EdgeInsets.symmetric(horizontal: 5),
                                          child: Text(
                                            '·',
                                            style: TextStyle(fontSize: 11, color: VeynColors.inkFaint),
                                          ),
                                        ),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                                          children: [
                                            Container(
                                              width: 5,
                                              height: 5,
                                              decoration: BoxDecoration(
                                                color: isLow
                                                    ? const Color(0xFFF59E0B)
                                                    : VeynColors.success,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              _seatsLabel(seats, lang),
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                                color: isLow
                                                    ? const Color(0xFF92400E)
                                                    : VeynColors.success,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ] else ...[
                                        const Padding(
                                          padding: EdgeInsets.symmetric(horizontal: 5),
                                          child: Text(
                                            '·',
                                            style: TextStyle(fontSize: 11, color: VeynColors.inkFaint),
                                          ),
                                        ),
                                        Text(
                                          context.tr('seats_available'),
                                          style: const TextStyle(
                                            fontSize: 10,
                                            color: VeynColors.inkFaint,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),

          // ── 5. Arrêts dépliables ───────────────────────────────────────────
          if (stops.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: Container(
                decoration: BoxDecoration(
                  color: VeynColors.surfaceSunken,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: VeynColors.line),
                ),
                child: Column(
                  children: [
                    InkWell(
                      onTap: () => setState(() => _stopsOpen = !_stopsOpen),
                      borderRadius: BorderRadius.circular(10),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        child: Row(
                          textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                          children: [
                            const Icon(LucideIcons.mapPin, size: 14, color: VeynColors.inkMuted),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                intermediate.isEmpty
                                    ? context.tr('direct_trip')
                                    : '${intermediate.length} ${context.tr('stop_points')}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: VeynColors.ink,
                                ),
                              ),
                            ),
                            AnimatedRotation(
                              turns: _stopsOpen ? 0.5 : 0,
                              duration: const Duration(milliseconds: 150),
                              child: const Icon(LucideIcons.chevronDown, size: 15, color: VeynColors.inkFaint),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_stopsOpen) ...[
                      const Divider(height: 1, color: VeynColors.line),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: StopsTimeline(stops: localizedStops),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],

          // ── 6. Pied de carte : Opérateur + Bouton Réserver ───────────────
          Container(
            decoration: const BoxDecoration(
              color: VeynColors.surfaceRaised,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(15),
                bottomRight: Radius.circular(15),
              ),
              border: Border(top: BorderSide(color: VeynColors.line)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Infos opérateur + heure de départ
                Flexible(
                  child: Column(
                    crossAxisAlignment: isRtl ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                    children: [
                      Text.rich(
                        TextSpan(children: [
                          TextSpan(
                            text: '${context.tr('operator')} : ',
                            style: const TextStyle(fontSize: 11, color: VeynColors.inkSoft),
                          ),
                          TextSpan(
                            text: trip.operator,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: VeynColors.ink),
                          ),
                        ]),
                        textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        dateLabel.isNotEmpty
                            ? '${context.tr('departure_at')} ${trip.departure} · $dateLabel'
                            : '${context.tr('departure_at')} ${trip.departure}',
                        style: const TextStyle(fontSize: 10, color: VeynColors.inkMuted),
                        overflow: TextOverflow.ellipsis,
                        textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                // Bouton Réserver
                ElevatedButton(
                  onPressed: () => widget.onBook(
                    trip.copyWith(
                      date: _selectedDate.isNotEmpty ? _selectedDate : trip.date,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: VeynColors.ink,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                    children: [
                      Text(
                        context.tr('book_now'),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(width: 4),
                      Icon(isRtl ? LucideIcons.arrowLeft : LucideIcons.arrowRight, size: 13),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
