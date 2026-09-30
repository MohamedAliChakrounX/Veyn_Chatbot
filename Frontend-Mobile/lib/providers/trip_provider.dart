import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/locations.dart';
import '../models/trip.dart';

class TripChipItem {
  final String field;
  final String label;

  const TripChipItem({required this.field, required this.label});
}

class TripProvider extends ChangeNotifier {
  TripQuery _trip = const TripQuery();
  bool _panelOpen = false;
  String? _activeField;

  TripQuery get trip => _trip;
  bool get panelOpen => _panelOpen;
  String? get activeField => _activeField;

  void openPanel([String? field]) {
    _panelOpen = true;
    _activeField = field;
    notifyListeners();
  }

  void closePanel() {
    _panelOpen = false;
    _activeField = null;
    notifyListeners();
  }

  void togglePanel([String? field]) {
    if (_panelOpen && (_activeField == field || field == null)) {
      closePanel();
    } else {
      openPanel(field);
    }
  }

  void toggleField(String field) {
    _activeField = (_activeField == field) ? null : field;
    notifyListeners();
  }

  void setTrip(TripQuery newTrip) {
    _trip = newTrip;
    notifyListeners();
  }

  void resetTrip() {
    _trip = const TripQuery();
    _activeField = null;
    notifyListeners();
  }

  /// Permute la ville de départ et la ville d'arrivée
  void swapCities() {
    final orig = _trip.origin;
    final dest = _trip.destination;
    _trip = _trip.copyWith(
      origin: dest,
      destination: orig,
      clearOrigin: dest == null,
      clearDestination: orig == null,
    );
    notifyListeners();
  }

  /// Ajoute ou supprime une date dans la sélection multiple
  void toggleDate(String dateStr) {
    final currentDates = List<String>.from(_trip.dates);
    if (currentDates.contains(dateStr)) {
      currentDates.remove(dateStr);
    } else {
      currentDates.add(dateStr);
      currentDates.sort();
    }
    final primary = currentDates.isNotEmpty ? currentDates.first : null;
    _trip = _trip.copyWith(
      dates: currentDates,
      date: primary,
      clearDate: primary == null,
    );
    notifyListeners();
  }

  void setDates(List<String> newDates) {
    final sorted = List<String>.from(newDates)..sort();
    final primary = sorted.isNotEmpty ? sorted.first : null;
    _trip = _trip.copyWith(
      dates: sorted,
      date: primary,
      clearDate: primary == null,
    );
    notifyListeners();
  }

  /// Ajoute ou supprime un créneau horaire
  void togglePeriod(TimePeriod p) {
    final current = List<TimePeriod>.from(_trip.periods);
    if (current.contains(p)) {
      current.remove(p);
    } else {
      current.add(p);
    }
    final primary = current.isNotEmpty ? current.first : null;
    _trip = _trip.copyWith(
      periods: current,
      period: primary,
      clearPeriod: primary == null,
    );
    notifyListeners();
  }

  void setPeriods(List<TimePeriod> newPeriods) {
    final primary = newPeriods.isNotEmpty ? newPeriods.first : null;
    _trip = _trip.copyWith(
      periods: newPeriods,
      period: primary,
      clearPeriod: primary == null,
    );
    notifyListeners();
  }

  /// Ajoute ou supprime un mode de transport
  void toggleMode(TransportMode m) {
    final current = List<TransportMode>.from(_trip.modes);
    if (current.contains(m)) {
      current.remove(m);
    } else {
      current.add(m);
    }
    _trip = _trip.copyWith(modes: current);
    notifyListeners();
  }

  void patchTrip(Map<String, dynamic> patch) {
    City? newOrigin = _trip.origin;
    if (patch.containsKey('origin')) {
      final val = patch['origin'];
      if (val is Map<String, dynamic>) {
        newOrigin = City.fromJson(val);
      } else if (val is City) {
        newOrigin = val;
      } else if (val == null) {
        newOrigin = null;
      }
    }

    City? newDest = _trip.destination;
    if (patch.containsKey('destination')) {
      final val = patch['destination'];
      if (val is Map<String, dynamic>) {
        newDest = City.fromJson(val);
      } else if (val is City) {
        newDest = val;
      } else if (val == null) {
        newDest = null;
      }
    }

    Travelers newTravelers = _trip.travelers;
    if (patch.containsKey('travelers')) {
      final val = patch['travelers'];
      if (val is Map<String, dynamic>) {
        newTravelers = Travelers.fromJson(val);
      } else if (val is Travelers) {
        newTravelers = val;
      }
    }

    List<String> newDates = List<String>.from(_trip.dates);
    String? newDate = _trip.date;
    if (patch.containsKey('dates') && patch['dates'] is List) {
      newDates = (patch['dates'] as List).map((e) => e.toString()).toList()..sort();
      newDate = newDates.isNotEmpty ? newDates.first : null;
    } else if (patch.containsKey('date')) {
      newDate = patch['date'] as String?;
      newDates = newDate != null ? [newDate] : [];
    }

    List<TimePeriod> newPeriods = List<TimePeriod>.from(_trip.periods);
    TimePeriod? newPeriod = _trip.period;
    if (patch.containsKey('periods') && patch['periods'] is List) {
      newPeriods = (patch['periods'] as List)
          .map((e) => timePeriodFromString(e.toString()))
          .whereType<TimePeriod>()
          .toList();
      newPeriod = newPeriods.isNotEmpty ? newPeriods.first : null;
    } else if (patch.containsKey('period')) {
      newPeriod = timePeriodFromString(patch['period'] as String?);
      newPeriods = newPeriod != null ? [newPeriod] : [];
    }

    String? newExactTime = _trip.exactTime;
    if (patch.containsKey('exactTime')) {
      newExactTime = patch['exactTime'] as String?;
    }

    List<TransportMode> newModes = _trip.modes;
    if (patch.containsKey('modes')) {
      final val = patch['modes'];
      if (val is List) {
        newModes = val.map((e) => transportModeFromString(e.toString())).toList();
      }
    }

    double? newBudget = _trip.budget;
    if (patch.containsKey('budget')) {
      final val = patch['budget'];
      if (val is num) {
        newBudget = val.toDouble();
      } else if (val == null) {
        newBudget = null;
      }
    }

    _trip = _trip.copyWith(
      origin: newOrigin,
      destination: newDest,
      travelers: newTravelers,
      date: newDate,
      dates: newDates,
      period: newPeriod,
      periods: newPeriods,
      exactTime: newExactTime,
      modes: newModes,
      budget: newBudget,
      clearOrigin: patch.containsKey('origin') && patch['origin'] == null,
      clearDestination: patch.containsKey('destination') && patch['destination'] == null,
      clearDate: (patch.containsKey('date') && patch['date'] == null) ||
                 (patch.containsKey('dates') && (patch['dates'] as List).isEmpty),
      clearPeriod: (patch.containsKey('period') && patch['period'] == null) ||
                   (patch.containsKey('periods') && (patch['periods'] as List).isEmpty),
      clearExactTime: patch.containsKey('exactTime') && patch['exactTime'] == null,
      clearBudget: patch.containsKey('budget') && patch['budget'] == null,
    );

    notifyListeners();
  }

  void removeField(String field) {
    switch (field) {
      case 'origin':
        _trip = _trip.copyWith(clearOrigin: true);
        break;
      case 'destination':
        _trip = _trip.copyWith(clearDestination: true);
        break;
      case 'date':
        _trip = _trip.copyWith(clearDate: true, clearDates: true);
        break;
      case 'time':
        _trip = _trip.copyWith(clearPeriod: true, clearPeriods: true, clearExactTime: true);
        break;
      case 'travelers':
        _trip = _trip.copyWith(travelers: const Travelers());
        break;
      case 'modes':
        _trip = _trip.copyWith(modes: []);
        break;
      case 'budget':
        _trip = _trip.copyWith(clearBudget: true);
        break;
    }
    notifyListeners();
  }

  String get currency {
    if (_trip.origin != null) {
      return getCountry(_trip.origin!.country).currency;
    }
    if (_trip.destination != null) {
      return getCountry(_trip.destination!.country).currency;
    }
    return 'DT';
  }

  String localizedCurrency(String lang) => formatCurrency(currency, lang);

  String? get routeLabel => getRouteLabel('fr');

  String? getRouteLabel(String lang) {
    if (_trip.origin != null && _trip.destination != null) {
      final orig = localizeCityName(_trip.origin!.name, lang);
      final dest = localizeCityName(_trip.destination!.name, lang);
      return '$orig → $dest';
    }
    if (_trip.destination != null) {
      final dest = localizeCityName(_trip.destination!.name, lang);
      return '→ $dest';
    }
    if (_trip.origin != null) {
      final orig = localizeCityName(_trip.origin!.name, lang);
      return '$orig →';
    }
    return null;
  }

  /// Nombre de paramètres/précisions actuellement actifs dans le tableau de bord
  int get activePrecisionsCount => countPrecisionsForTrip(_trip);

  /// Calcule le nombre de précisions définies pour une requête donnée
  static int countPrecisionsForTrip(TripQuery query) {
    int count = 0;
    if (query.origin != null) count++;
    if (query.destination != null) count++;
    if (query.dates.isNotEmpty || query.date != null) count++;
    if (query.periods.isNotEmpty ||
        query.period != null ||
        (query.exactTime != null && query.exactTime!.isNotEmpty)) {
      count++;
    }
    if (query.travelers.total > 0) count++;
    if (query.modes.isNotEmpty) count++;
    if (query.budget != null) count++;
    return count;
  }

  /// Retourne les puces de résumé localisées pour la requête active.
  List<TripChipItem> chipsFor(String lang) {
    return chipsForTrip(_trip, lang);
  }

  /// Retourne les puces de résumé localisées pour n'importe quelle requête (ex: snapshot immuable d'un message).
  List<TripChipItem> chipsForTrip(TripQuery query, String lang) {
    final list = <TripChipItem>[];
    final labels = _chipLabels[lang] ?? _chipLabels['fr']!;

    if (query.origin != null) {
      final cityName = localizeCityName(query.origin!.name, lang);
      list.add(TripChipItem(
        field: 'origin',
        label: '${labels['origin']!} $cityName',
      ));
    }
    if (query.destination != null) {
      final cityName = localizeCityName(query.destination!.name, lang);
      list.add(TripChipItem(
        field: 'destination',
        label: '${labels['destination']!} $cityName',
      ));
    }

    // Gestion multi-dates
    if (query.dates.isNotEmpty) {
      if (query.dates.length == 1) {
        list.add(TripChipItem(
          field: 'date',
          label: _formatDate(query.dates.first, lang),
        ));
      } else {
        final formattedDates = query.dates.map((d) => _formatDate(d, lang)).join(', ');
        list.add(TripChipItem(
          field: 'date',
          label: formattedDates,
        ));
      }
    } else if (query.date != null) {
      list.add(TripChipItem(
        field: 'date',
        label: _formatDate(query.date!, lang),
      ));
    }

    // Gestion horaires et périodes (détection exacte ou créneaux)
    final hasExactTime = query.exactTime != null && query.exactTime!.trim().isNotEmpty;
    final hasPeriods = query.periods.isNotEmpty;
    final hasPeriod = query.period != null;

    if (hasExactTime && hasPeriods) {
      final periodLabels = query.periods.map((p) => _periodName(p, lang)).join(' + ');
      list.add(TripChipItem(
        field: 'time',
        label: '${query.exactTime!} ($periodLabels)',
      ));
    } else if (hasExactTime) {
      list.add(TripChipItem(
        field: 'time',
        label: '${labels['at']!} ${query.exactTime!}',
      ));
    } else if (hasPeriods) {
      final periodLabels = query.periods.map((p) => _periodName(p, lang)).join(' + ');
      list.add(TripChipItem(
        field: 'time',
        label: periodLabels,
      ));
    } else if (hasPeriod) {
      list.add(TripChipItem(
        field: 'time',
        label: _periodName(query.period!, lang),
      ));
    }

    if (query.travelers.total > 0) {
      final t = query.travelers;
      final parts = <String>[];
      if (t.adults > 0) parts.add('${t.adults} ${labels['ad']!}');
      if (t.children > 0) parts.add('${t.children} ${labels['enf']!}');
      if (t.assisted > 0) parts.add('${t.assisted} ${labels['pmr']!}');
      list.add(TripChipItem(
        field: 'travelers',
        label: parts.join(' · '),
      ));
    }

    if (query.modes.isNotEmpty) {
      final modeLabel = query.modes.length == 1
          ? _modeLabel(query.modes.first, lang)
          : query.modes.map((m) => _modeLabel(m, lang)).join(' + ');
      list.add(TripChipItem(
        field: 'modes',
        label: modeLabel,
      ));
    }

    if (query.budget != null) {
      final curr = localizedCurrency(lang);
      final budgetLabel = lang == 'ar'
          ? 'أقصى ${query.budget!.toInt()} $curr'
          : '≤ ${query.budget!.toInt()} $curr';
      list.add(TripChipItem(
        field: 'budget',
        label: budgetLabel,
      ));
    }
    return list;
  }

  List<TripChipItem> get chips => chipsFor('fr');

  String _formatDate(String dateStr, String lang) {
    try {
      final parsed = DateTime.parse(dateStr);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final target = DateTime(parsed.year, parsed.month, parsed.day);
      final diff = target.difference(today).inDays;

      if (diff == 0) {
        return lang == 'ar' ? 'اليوم' : lang == 'en' ? 'Today' : "Aujourd'hui";
      }
      if (diff == 1) {
        return lang == 'ar' ? 'غداً' : lang == 'en' ? 'Tomorrow' : 'Demain';
      }
      if (diff == 2) {
        return lang == 'ar' ? 'بعد غد' : lang == 'en' ? 'In 2 days' : 'Après-demain';
      }
      final locale = lang == 'ar' ? 'ar' : lang == 'en' ? 'en_US' : 'fr_FR';
      return DateFormat('EEE d MMM', locale).format(parsed);
    } catch (_) {
      return dateStr;
    }
  }

  String _periodName(TimePeriod period, String lang) {
    final labels = _chipLabels[lang] ?? _chipLabels['fr']!;
    switch (period) {
      case TimePeriod.morning:
        return labels['morning']!;
      case TimePeriod.afternoon:
        return labels['afternoon']!;
      case TimePeriod.evening:
        return labels['evening']!;
      case TimePeriod.exact:
        return labels['time']!;
    }
  }

  String _modeLabel(TransportMode mode, String lang) {
    const labels = {
      'fr': {
        'bus': 'Bus',
        'train': 'Train',
        'shared_taxi': 'Louage',
        'plane': 'Avion',
        'ferry': 'Ferry',
        'other': 'Autre',
      },
      'en': {
        'bus': 'Bus',
        'train': 'Train',
        'shared_taxi': 'Shared taxi',
        'plane': 'Plane',
        'ferry': 'Ferry',
        'other': 'Other',
      },
      'ar': {
        'bus': 'حافلة',
        'train': 'قطار',
        'shared_taxi': 'لواج',
        'plane': 'طيران',
        'ferry': 'عبّارة',
        'other': 'أخرى',
      },
    };
    final key = transportModeToString(mode);
    return labels[lang]?[key] ?? labels['fr']![key]!;
  }

  static const _chipLabels = <String, Map<String, String>>{
    'fr': {
      'origin': 'Départ :',
      'destination': 'Arrivée :',
      'time': 'Heure',
      'at': 'à',
      'morning': 'Matin',
      'afternoon': 'Après-midi',
      'evening': 'Soir',
      'ad': 'ad.',
      'enf': 'enf.',
      'pmr': 'PMR',
      'modes': 'modes',
    },
    'en': {
      'origin': 'From:',
      'destination': 'To:',
      'time': 'Time',
      'at': 'at',
      'morning': 'Morning',
      'afternoon': 'Afternoon',
      'evening': 'Evening',
      'ad': 'adult(s)',
      'enf': 'child(ren)',
      'pmr': 'assisted',
      'modes': 'modes',
    },
    'ar': {
      'origin': 'من:',
      'destination': 'إلى:',
      'time': 'الوقت',
      'at': 'في',
      'morning': 'صباحاً',
      'afternoon': 'ظهراً',
      'evening': 'مساءً',
      'ad': 'بالغ',
      'enf': 'طفل',
      'pmr': 'ذوو احتياجات',
      'modes': 'وسائل',
    },
  };
}
