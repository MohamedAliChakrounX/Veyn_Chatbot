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

class TripPanel extends StatelessWidget {
  const TripPanel({super.key});

  /// Ouvre le panneau de précisions en tant que Bottom Sheet modal moderne
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const TripPanelModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const TripPanelModal(isInline: true);
  }
}

class TripPanelModal extends StatefulWidget {
  final bool isInline;
  const TripPanelModal({super.key, this.isInline = false});

  @override
  State<TripPanelModal> createState() => _TripPanelModalState();
}

class _TripPanelModalState extends State<TripPanelModal> {
  int _activeTab = 0; // 0: Trajet, 1: Dates & Heures, 2: Transport & Budget

  @override
  Widget build(BuildContext context) {
    final tripProvider = context.watch<TripProvider>();
    final lang = context.watch<LanguageProvider>().languageCode;
    final isRtl = context.isRtl;
    final trip = tripProvider.trip;
    final activeCount = tripProvider.chipsFor(lang).length;

    final content = Container(
      decoration: BoxDecoration(
        color: VeynColors.surface,
        borderRadius: widget.isInline
            ? BorderRadius.circular(16)
            : const BorderRadius.vertical(top: Radius.circular(24)),
        border: widget.isInline ? Border.all(color: VeynColors.line) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      constraints: BoxConstraints(
        maxHeight: widget.isInline
            ? 340
            : MediaQuery.of(context).size.height * 0.85,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Poignée de glissement (si Bottom Sheet)
          if (!widget.isInline)
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 10, bottom: 6),
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: VeynColors.line,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

          // En-tête
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
              children: [
                Icon(LucideIcons.sliders, size: 18, color: VeynColors.accent),
                const SizedBox(width: 8),
                Text(
                  context.tr('refine_trip'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: VeynColors.ink,
                  ),
                ),
                if (activeCount > 0) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: VeynColors.accentSoft,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$activeCount',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: VeynColors.accent,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                if (!trip.isEmpty)
                  TextButton(
                    onPressed: () => tripProvider.resetTrip(),
                    style: TextButton.styleFrom(
                      foregroundColor: VeynColors.inkMuted,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      visualDensity: VisualDensity.compact,
                    ),
                    child: Text(
                      context.tr('reset'),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                IconButton(
                  onPressed: () {
                    if (widget.isInline) {
                      tripProvider.closePanel();
                    } else {
                      Navigator.of(context).pop();
                    }
                  },
                  icon: const Icon(LucideIcons.x, size: 18),
                  style: IconButton.styleFrom(visualDensity: VisualDensity.compact),
                ),
              ],
            ),
          ),

          // Onglets de navigation compacts
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
              children: [
                _buildTabButton(0, context.tr('tab_route'), LucideIcons.mapPin, isRtl),
                const SizedBox(width: 8),
                _buildTabButton(1, context.tr('tab_dates_time'), LucideIcons.calendar, isRtl),
                const SizedBox(width: 8),
                _buildTabButton(2, context.tr('tab_options'), LucideIcons.sliders, isRtl),
              ],
            ),
          ),

          const Divider(height: 12),

          // Contenu déroulant
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: _buildActiveTabContent(context, tripProvider, lang, isRtl),
            ),
          ),

          // Bouton d'application inférieur
          Container(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 10,
              bottom: MediaQuery.of(context).padding.bottom + 10,
            ),
            decoration: const BoxDecoration(
              color: VeynColors.surfaceSunken,
              border: Border(top: BorderSide(color: VeynColors.line)),
            ),
            child: Row(
              textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      if (widget.isInline) {
                        tripProvider.closePanel();
                      } else {
                        Navigator.of(context).pop();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: VeynColors.accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: Text(
                      activeCount > 0
                          ? '${context.tr('apply')} ($activeCount)'
                          : context.tr('apply'),
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return widget.isInline
        ? content
        : Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: content,
          );
  }

  Widget _buildTabButton(int index, String title, IconData icon, bool isRtl) {
    final isSelected = _activeTab == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _activeTab = index),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: isSelected ? VeynColors.accentSoft : VeynColors.surfaceSunken,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? VeynColors.accentBorder : VeynColors.line,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
            children: [
              Icon(
                icon,
                size: 13,
                color: isSelected ? VeynColors.accent : VeynColors.inkMuted,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? VeynColors.accent : VeynColors.inkMuted,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveTabContent(
    BuildContext context,
    TripProvider tripProvider,
    String lang,
    bool isRtl,
  ) {
    switch (_activeTab) {
      case 0:
        return _buildRouteSection(context, tripProvider, lang, isRtl);
      case 1:
        return _buildDateTimeSection(context, tripProvider, lang, isRtl);
      case 2:
      default:
        return _buildOptionsSection(context, tripProvider, lang, isRtl);
    }
  }

  // --- SECTION 1 : VILLES & TRAJET ---
  Widget _buildRouteSection(
    BuildContext context,
    TripProvider tripProvider,
    String lang,
    bool isRtl,
  ) {
    final trip = tripProvider.trip;
    final originName = trip.origin != null ? localizeCityName(trip.origin!.name, lang) : '';
    final destName = trip.destination != null ? localizeCityName(trip.destination!.name, lang) : '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Champ Ville de départ
        _buildCitySelector(
          context: context,
          label: context.tr('from'),
          value: originName,
          hint: context.tr('search_city_placeholder'),
          icon: LucideIcons.mapPin,
          isRtl: isRtl,
          onTap: () => _openCityPicker(context, true, lang, tripProvider),
          onClear: trip.origin != null ? () => tripProvider.removeField('origin') : null,
        ),

        const SizedBox(height: 8),

        // Bouton Permuter les villes
        Center(
          child: IconButton(
            onPressed: (trip.origin != null || trip.destination != null)
                ? () => tripProvider.swapCities()
                : null,
            icon: const Icon(LucideIcons.arrowDownUp, size: 18),
            style: IconButton.styleFrom(
              backgroundColor: VeynColors.surfaceSunken,
              side: const BorderSide(color: VeynColors.line),
              padding: const EdgeInsets.all(8),
            ),
            tooltip: context.tr('swap_cities'),
          ),
        ),

        const SizedBox(height: 8),

        // Champ Ville d'arrivée
        _buildCitySelector(
          context: context,
          label: context.tr('to'),
          value: destName,
          hint: context.tr('search_city_placeholder'),
          icon: LucideIcons.navigation,
          isRtl: isRtl,
          onTap: () => _openCityPicker(context, false, lang, tripProvider),
          onClear: trip.destination != null ? () => tripProvider.removeField('destination') : null,
        ),

        const SizedBox(height: 16),

        // Villes populaires rapides
        Text(
          context.tr('popular_destinations'),
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: VeynColors.inkMuted),
          textAlign: isRtl ? TextAlign.right : TextAlign.left,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
          children: popularCityIds.map((id) {
            final city = initialCities.firstWhere((c) => c.id == id, orElse: () => initialCities.first);
            final localized = localizeCityName(city.name, lang);
            return ActionChip(
              label: Text(localized, style: const TextStyle(fontSize: 12)),
              backgroundColor: VeynColors.surfaceSunken,
              side: const BorderSide(color: VeynColors.line),
              onPressed: () {
                if (trip.origin == null) {
                  tripProvider.patchTrip({'origin': city});
                } else if (trip.destination == null) {
                  tripProvider.patchTrip({'destination': city});
                } else {
                  tripProvider.patchTrip({'destination': city});
                }
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCitySelector({
    required BuildContext context,
    required String label,
    required String value,
    required String hint,
    required IconData icon,
    required bool isRtl,
    required VoidCallback onTap,
    VoidCallback? onClear,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: VeynColors.surfaceSunken,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: value.isNotEmpty ? VeynColors.accent : VeynColors.line),
        ),
        child: Row(
          textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
          children: [
            Icon(icon, size: 18, color: value.isNotEmpty ? VeynColors.accent : VeynColors.inkMuted),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: isRtl ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(fontSize: 10, color: VeynColors.inkMuted, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value.isNotEmpty ? value : hint,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: value.isNotEmpty ? FontWeight.w700 : FontWeight.normal,
                      color: value.isNotEmpty ? VeynColors.ink : VeynColors.inkFaint,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (value.isNotEmpty && onClear != null)
              IconButton(
                onPressed: onClear,
                icon: const Icon(LucideIcons.x, size: 16),
                style: IconButton.styleFrom(visualDensity: VisualDensity.compact),
              )
            else
              const Icon(LucideIcons.chevronRight, size: 16, color: VeynColors.inkMuted),
          ],
        ),
      ),
    );
  }

  void _openCityPicker(BuildContext context, bool isOrigin, String lang, TripProvider tripProvider) {
    final trip = tripProvider.trip;
    LocationPickerSheet.show(
      context: context,
      isOrigin: isOrigin,
      currentCity: isOrigin ? trip.origin : trip.destination,
      excludeCityId: isOrigin ? trip.destination?.id : trip.origin?.id,
      lang: lang,
      onSelectCity: (city) {
        if (isOrigin) {
          tripProvider.patchTrip({'origin': city});
        } else {
          tripProvider.patchTrip({'destination': city});
        }
      },
    );
  }

  // --- SECTION 2 : DATES & HEURES (MULTI-SÉLECTION) ---
  Widget _buildDateTimeSection(
    BuildContext context,
    TripProvider tripProvider,
    String lang,
    bool isRtl,
  ) {
    final trip = tripProvider.trip;
    final now = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);
    final tomorrowStr = DateFormat('yyyy-MM-dd').format(now.add(const Duration(days: 1)));
    final afterTomorrowStr = DateFormat('yyyy-MM-dd').format(now.add(const Duration(days: 2)));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Multi-sélection des dates
        Row(
          textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
          children: [
            const Icon(LucideIcons.calendar, size: 16, color: VeynColors.accent),
            const SizedBox(width: 6),
            Text(
              context.tr('date_label'),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: VeynColors.ink),
            ),
            const Spacer(),
            Text(
              isRtl ? 'اختيار متعدد متاح' : 'Multi-sélection possible',
              style: const TextStyle(fontSize: 10, color: VeynColors.inkMuted),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Puces rapides : Aujourd'hui / Demain / Après-demain
        Wrap(
          spacing: 8,
          runSpacing: 8,
          textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
          children: [
            _buildMultiDateChip(
              label: context.tr('today'),
              dateVal: todayStr,
              isSelected: trip.dates.contains(todayStr) || trip.date == todayStr,
              onTap: () => tripProvider.toggleDate(todayStr),
            ),
            _buildMultiDateChip(
              label: context.tr('tomorrow'),
              dateVal: tomorrowStr,
              isSelected: trip.dates.contains(tomorrowStr) || trip.date == tomorrowStr,
              onTap: () => tripProvider.toggleDate(tomorrowStr),
            ),
            _buildMultiDateChip(
              label: isRtl ? 'بعد غد' : 'Après-demain',
              dateVal: afterTomorrowStr,
              isSelected: trip.dates.contains(afterTomorrowStr) || trip.date == afterTomorrowStr,
              onTap: () => tripProvider.toggleDate(afterTomorrowStr),
            ),
          ],
        ),

        const SizedBox(height: 10),

        // Bouton Choisir une autre date au calendrier
        OutlinedButton.icon(
          onPressed: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: now,
              firstDate: now,
              lastDate: now.add(const Duration(days: 90)),
            );
            if (picked != null) {
              final formatted = DateFormat('yyyy-MM-dd').format(picked);
              tripProvider.toggleDate(formatted);
            }
          },
          icon: const Icon(LucideIcons.calendarPlus, size: 14),
          label: Text(
            isRtl ? 'اختيار تاريخ من التقويم' : 'Autre date du calendrier...',
            style: const TextStyle(fontSize: 12),
          ),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: VeynColors.line),
            padding: const EdgeInsets.symmetric(vertical: 8),
          ),
        ),

        const SizedBox(height: 20),

        // Multi-sélection des Créneaux horaires
        Row(
          textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
          children: [
            const Icon(LucideIcons.clock, size: 16, color: VeynColors.accent),
            const SizedBox(width: 6),
            Text(
              context.tr('time_label'),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: VeynColors.ink),
            ),
          ],
        ),
        const SizedBox(height: 8),

        Wrap(
          spacing: 8,
          runSpacing: 8,
          textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
          children: [
            _buildPeriodChip(
              period: TimePeriod.morning,
              label: context.tr('morning'),
              subtitle: '06h - 12h',
              icon: LucideIcons.sunrise,
              isSelected: trip.periods.contains(TimePeriod.morning) || trip.period == TimePeriod.morning,
              onTap: () => tripProvider.togglePeriod(TimePeriod.morning),
            ),
            _buildPeriodChip(
              period: TimePeriod.afternoon,
              label: context.tr('afternoon'),
              subtitle: '12h - 18h',
              icon: LucideIcons.sun,
              isSelected: trip.periods.contains(TimePeriod.afternoon) || trip.period == TimePeriod.afternoon,
              onTap: () => tripProvider.togglePeriod(TimePeriod.afternoon),
            ),
            _buildPeriodChip(
              period: TimePeriod.evening,
              label: context.tr('evening'),
              subtitle: '18h - 00h',
              icon: LucideIcons.moon,
              isSelected: trip.periods.contains(TimePeriod.evening) || trip.period == TimePeriod.evening,
              onTap: () => tripProvider.togglePeriod(TimePeriod.evening),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMultiDateChip({
    required String label,
    required String dateVal,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return FilterChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: VeynColors.accentSoft,
      checkmarkColor: VeynColors.accent,
      side: BorderSide(color: isSelected ? VeynColors.accent : VeynColors.line),
    );
  }

  Widget _buildPeriodChip({
    required TimePeriod period,
    required String label,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? VeynColors.accentSoft : VeynColors.surfaceSunken,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? VeynColors.accent : VeynColors.line),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: isSelected ? VeynColors.accent : VeynColors.inkMuted),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? VeynColors.accent : VeynColors.ink,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 9, color: VeynColors.inkMuted),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- SECTION 3 : OPTIONS, TRANSPORTS & BUDGET ---
  Widget _buildOptionsSection(
    BuildContext context,
    TripProvider tripProvider,
    String lang,
    bool isRtl,
  ) {
    final trip = tripProvider.trip;
    final modes = [
      {'mode': TransportMode.bus, 'label': context.tr('bus'), 'icon': LucideIcons.bus},
      {'mode': TransportMode.sharedTaxi, 'label': context.tr('shared_taxi'), 'icon': LucideIcons.car},
      {'mode': TransportMode.train, 'label': context.tr('train'), 'icon': LucideIcons.train},
      {'mode': TransportMode.plane, 'label': context.tr('plane'), 'icon': LucideIcons.plane},
      {'mode': TransportMode.ferry, 'label': context.tr('ferry'), 'icon': LucideIcons.ship},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Modes de transport multi-sélection
        Row(
          textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
          children: [
            const Icon(LucideIcons.bus, size: 16, color: VeynColors.accent),
            const SizedBox(width: 6),
            Text(
              context.tr('transport_mode'),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: VeynColors.ink),
            ),
          ],
        ),
        const SizedBox(height: 8),

        Wrap(
          spacing: 8,
          runSpacing: 8,
          textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
          children: modes.map((m) {
            final mode = m['mode'] as TransportMode;
            final label = m['label'] as String;
            final icon = m['icon'] as IconData;
            final isSelected = trip.modes.contains(mode);

            return FilterChip(
              avatar: Icon(icon, size: 14, color: isSelected ? VeynColors.accent : VeynColors.inkMuted),
              label: Text(label, style: const TextStyle(fontSize: 12)),
              selected: isSelected,
              onSelected: (_) => tripProvider.toggleMode(mode),
              selectedColor: VeynColors.accentSoft,
              checkmarkColor: VeynColors.accent,
              side: BorderSide(color: isSelected ? VeynColors.accent : VeynColors.line),
            );
          }).toList(),
        ),

        const SizedBox(height: 20),

        // Nombre de voyageurs
        Row(
          textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
          children: [
            const Icon(LucideIcons.users, size: 16, color: VeynColors.accent),
            const SizedBox(width: 6),
            Text(
              context.tr('travelers'),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: VeynColors.ink),
            ),
          ],
        ),
        const SizedBox(height: 8),

        Row(
          textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
          children: [
            _buildCounter(
              label: context.tr('adults'),
              count: trip.travelers.adults,
              onChanged: (val) {
                tripProvider.patchTrip({
                  'travelers': trip.travelers.copyWith(adults: val),
                });
              },
            ),
            const SizedBox(width: 12),
            _buildCounter(
              label: context.tr('children'),
              count: trip.travelers.children,
              onChanged: (val) {
                tripProvider.patchTrip({
                  'travelers': trip.travelers.copyWith(children: val),
                });
              },
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Budget maximum
        Row(
          textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
          children: [
            const Icon(LucideIcons.wallet, size: 16, color: VeynColors.accent),
            const SizedBox(width: 6),
            Text(
              context.tr('budget_max'),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: VeynColors.ink),
            ),
            const Spacer(),
            if (trip.budget != null)
              Text(
                '${trip.budget!.toInt()} ${tripProvider.localizedCurrency(lang)}',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: VeynColors.accent),
              ),
          ],
        ),
        Slider(
          value: (trip.budget ?? 150).clamp(10, 300),
          min: 10,
          max: 300,
          divisions: 29,
          activeColor: VeynColors.accent,
          onChanged: (val) {
            tripProvider.patchTrip({'budget': val});
          },
        ),
      ],
    );
  }

  Widget _buildCounter({
    required String label,
    required int count,
    required Function(int) onChanged,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: VeynColors.surfaceSunken,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: VeynColors.line),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
            Row(
              children: [
                IconButton(
                  onPressed: count > 0 ? () => onChanged(count - 1) : null,
                  icon: const Icon(LucideIcons.minus, size: 12),
                  style: IconButton.styleFrom(
                    padding: const EdgeInsets.all(4),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                Text('$count', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                IconButton(
                  onPressed: () => onChanged(count + 1),
                  icon: const Icon(LucideIcons.plus, size: 12),
                  style: IconButton.styleFrom(
                    padding: const EdgeInsets.all(4),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
