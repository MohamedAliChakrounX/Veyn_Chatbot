import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../l10n/translations.dart';
import '../models/trip.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Options de transport (dynamiques selon la langue)
// ─────────────────────────────────────────────────────────────────────────────

class TransportOption {
  final TransportMode id;
  final String label;
  final IconData icon;
  final String hint;

  const TransportOption({
    required this.id,
    required this.label,
    required this.icon,
    required this.hint,
  });
}

List<TransportOption> getTransportOptions(BuildContext context) => [
      TransportOption(
        id: TransportMode.bus,
        label: context.tr('bus'),
        icon: LucideIcons.bus,
        hint: context.tr('bus_hint'),
      ),
      TransportOption(
        id: TransportMode.sharedTaxi,
        label: context.tr('shared_taxi'),
        icon: LucideIcons.car,
        hint: context.tr('taxi_hint'),
      ),
      TransportOption(
        id: TransportMode.train,
        label: context.tr('train'),
        icon: LucideIcons.train,
        hint: context.tr('train_hint'),
      ),
      TransportOption(
        id: TransportMode.plane,
        label: context.tr('plane'),
        icon: LucideIcons.plane,
        hint: context.tr('plane_hint'),
      ),
      TransportOption(
        id: TransportMode.ferry,
        label: context.tr('ferry'),
        icon: LucideIcons.ship,
        hint: context.tr('ferry_hint'),
      ),
      TransportOption(
        id: TransportMode.other,
        label: context.tr('other'),
        icon: LucideIcons.moreHorizontal,
        hint: context.tr('other_hint'),
      ),
    ];

// Fallback statique (uniquement pour compatibilité)
const List<TransportOption> transportOptions = [];

// ─────────────────────────────────────────────────────────────────────────────
// Options de période (dynamiques selon la langue)
// ─────────────────────────────────────────────────────────────────────────────

class PeriodOption {
  final TimePeriod id;
  final String label;
  final String range;

  const PeriodOption({
    required this.id,
    required this.label,
    required this.range,
  });
}

List<PeriodOption> getPeriodOptions(BuildContext context) => [
      PeriodOption(
        id: TimePeriod.morning,
        label: context.tr('morning'),
        range: context.tr('morning_range'),
      ),
      PeriodOption(
        id: TimePeriod.afternoon,
        label: context.tr('afternoon'),
        range: context.tr('afternoon_range'),
      ),
      PeriodOption(
        id: TimePeriod.evening,
        label: context.tr('evening'),
        range: context.tr('evening_range'),
      ),
      PeriodOption(
        id: TimePeriod.exact,
        label: context.tr('exact_time'),
        range: context.tr('choose_time'),
      ),
    ];

// Fallback statique (uniquement pour compatibilité)
const List<PeriodOption> periodOptions = [];

// ─────────────────────────────────────────────────────────────────────────────
// Catégories de voyageurs (dynamiques selon la langue)
// ─────────────────────────────────────────────────────────────────────────────

class TravelerCategory {
  final String id;
  final String label;
  final String hint;
  final int min;

  const TravelerCategory({
    required this.id,
    required this.label,
    required this.hint,
    required this.min,
  });
}

List<TravelerCategory> getTravelerCategories(BuildContext context) => [
      TravelerCategory(
        id: 'adults',
        label: context.tr('adults'),
        hint: context.tr('adults_hint'),
        min: 0,
      ),
      TravelerCategory(
        id: 'children',
        label: context.tr('children'),
        hint: context.tr('children_hint'),
        min: 0,
      ),
      TravelerCategory(
        id: 'assisted',
        label: context.tr('assisted'),
        hint: context.tr('assisted_hint'),
        min: 0,
      ),
    ];

// Fallback statique (uniquement pour compatibilité)
const List<TravelerCategory> travelerCategories = [];

// ─────────────────────────────────────────────────────────────────────────────
// Budget
// ─────────────────────────────────────────────────────────────────────────────

const List<double> budgetPresets = [30.0, 60.0, 120.0, 250.0];
const List<double> budgetSuggestions = budgetPresets;

// ─────────────────────────────────────────────────────────────────────────────
// Fournisseurs paiement mobile (dynamiques selon la langue)
// ─────────────────────────────────────────────────────────────────────────────

class MobileProvider {
  final String id;
  final String name;
  final CountryCode country;
  final String descriptionKey;
  final Color color;

  const MobileProvider({
    required this.id,
    required this.name,
    required this.country,
    required this.descriptionKey,
    required this.color,
  });

  String getDescription(BuildContext context) => context.tr(descriptionKey);
}

const List<MobileProvider> mobileProviders = [
  MobileProvider(
    id: 'flouci',
    name: 'Flouci',
    country: CountryCode.tn,
    descriptionKey: 'flouci_desc',
    color: Color(0xFF0B5FFF),
  ),
  MobileProvider(
    id: 'd17',
    name: 'D17',
    country: CountryCode.tn,
    descriptionKey: 'd17_desc',
    color: Color(0xFFF5A623),
  ),
  MobileProvider(
    id: 'sadad',
    name: 'Sadad',
    country: CountryCode.ly,
    descriptionKey: 'sadad_desc',
    color: Color(0xFF0E7A5F),
  ),
  MobileProvider(
    id: 'moamalat',
    name: 'Moamalat',
    country: CountryCode.ly,
    descriptionKey: 'moamalat_desc',
    color: Color(0xFF1F3C88),
  ),
  MobileProvider(
    id: 'baridimob',
    name: 'BaridiMob',
    country: CountryCode.dz,
    descriptionKey: 'baridimob_desc',
    color: Color(0xFF00834A),
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// Cartes bancaires (dynamiques selon la langue)
// ─────────────────────────────────────────────────────────────────────────────

class CardBrandOption {
  final String value;
  final String label;
  final Color surface;
  final Color text;
  final String noteKey;

  const CardBrandOption({
    required this.value,
    required this.label,
    required this.surface,
    required this.text,
    required this.noteKey,
  });

  String getNote(BuildContext context) => context.tr(noteKey);
}

const List<CardBrandOption> cardBrands = [
  CardBrandOption(
    value: 'visa',
    label: 'Visa',
    surface: Color(0xFF1A1F71),
    text: Colors.white,
    noteKey: 'visa_note',
  ),
  CardBrandOption(
    value: 'mastercard',
    label: 'Mastercard',
    surface: Color(0xFF1C1C22),
    text: Colors.white,
    noteKey: 'mastercard_note',
  ),
  CardBrandOption(
    value: 'cib',
    label: 'CIB',
    surface: Color(0xFF046B4A),
    text: Colors.white,
    noteKey: 'cib_note',
  ),
  CardBrandOption(
    value: 'edinar',
    label: 'e-Dinar',
    surface: Color(0xFF5B2AA5),
    text: Colors.white,
    noteKey: 'edinar_note',
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// Suggestions de départ (dynamiques selon la langue)
// ─────────────────────────────────────────────────────────────────────────────

List<String> getStartSuggestions(BuildContext context) => [
      context.tr('start_q1'),
      context.tr('start_q2'),
      context.tr('start_q3'),
      context.tr('start_q4'),
    ];

// Fallback statique (uniquement pour compatibilité)
const List<String> startSuggestions = [];

// ─────────────────────────────────────────────────────────────────────────────
// Enum CountryCode (aussi défini dans locations.dart — éviter la duplication)
// ─────────────────────────────────────────────────────────────────────────────
// Note: CountryCode est défini dans models/trip.dart via locations.dart
