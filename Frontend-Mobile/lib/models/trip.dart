enum CountryCode { tn, dz, ly, eg }

CountryCode countryCodeFromString(String code) {
  switch (code.toUpperCase()) {
    case 'TN':
      return CountryCode.tn;
    case 'DZ':
      return CountryCode.dz;
    case 'LY':
      return CountryCode.ly;
    case 'EG':
      return CountryCode.eg;
    default:
      return CountryCode.tn;
  }
}

String countryCodeToString(CountryCode code) {
  switch (code) {
    case CountryCode.tn:
      return 'TN';
    case CountryCode.dz:
      return 'DZ';
    case CountryCode.ly:
      return 'LY';
    case CountryCode.eg:
      return 'EG';
  }
}

class Country {
  final CountryCode code;
  final String name;
  final String currency;

  const Country({
    required this.code,
    required this.name,
    required this.currency,
  });

  Map<String, dynamic> toJson() => {
        'code': countryCodeToString(code),
        'name': name,
        'currency': currency,
      };

  factory Country.fromJson(Map<String, dynamic> json) => Country(
        code: countryCodeFromString(json['code'] as String? ?? 'TN'),
        name: json['name'] as String? ?? '',
        currency: json['currency'] as String? ?? 'DT',
      );
}

class City {
  final String id;
  final String name;
  final CountryCode country;
  final List<String> aliases;
  final String? nameAr;
  final String? nameFr;
  final String? nameEn;

  const City({
    required this.id,
    required this.name,
    required this.country,
    this.aliases = const [],
    this.nameAr,
    this.nameFr,
    this.nameEn,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'country': countryCodeToString(country),
        'aliases': aliases,
        if (nameAr != null) 'nameAr': nameAr,
        if (nameFr != null) 'nameFr': nameFr,
        if (nameEn != null) 'nameEn': nameEn,
      };

  factory City.fromJson(Map<String, dynamic> json) => City(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        country: countryCodeFromString(json['country'] as String? ?? 'TN'),
        aliases: (json['aliases'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
        nameAr: json['nameAr'] as String?,
        nameFr: json['nameFr'] as String?,
        nameEn: json['nameEn'] as String?,
      );
}

enum TimePeriod { morning, afternoon, evening, exact }

TimePeriod? timePeriodFromString(String? period) {
  if (period == null) return null;
  switch (period.toLowerCase()) {
    case 'morning':
      return TimePeriod.morning;
    case 'afternoon':
      return TimePeriod.afternoon;
    case 'evening':
      return TimePeriod.evening;
    case 'exact':
      return TimePeriod.exact;
    default:
      return null;
  }
}

String? timePeriodToString(TimePeriod? period) {
  if (period == null) return null;
  switch (period) {
    case TimePeriod.morning:
      return 'morning';
    case TimePeriod.afternoon:
      return 'afternoon';
    case TimePeriod.evening:
      return 'evening';
    case TimePeriod.exact:
      return 'exact';
  }
}

enum TransportMode { bus, train, sharedTaxi, plane, ferry, other }

TransportMode transportModeFromString(String mode) {
  switch (mode.toLowerCase()) {
    case 'bus':
      return TransportMode.bus;
    case 'train':
      return TransportMode.train;
    case 'shared_taxi':
    case 'louage':
    case 'taxi':
      return TransportMode.sharedTaxi;
    case 'plane':
    case 'avion':
      return TransportMode.plane;
    case 'ferry':
    case 'bateau':
      return TransportMode.ferry;
    default:
      return TransportMode.other;
  }
}

String transportModeToString(TransportMode mode) {
  switch (mode) {
    case TransportMode.bus:
      return 'bus';
    case TransportMode.train:
      return 'train';
    case TransportMode.sharedTaxi:
      return 'shared_taxi';
    case TransportMode.plane:
      return 'plane';
    case TransportMode.ferry:
      return 'ferry';
    case TransportMode.other:
      return 'other';
  }
}

class Travelers {
  final int adults;
  final int children;
  final int assisted;

  const Travelers({
    this.adults = 0,
    this.children = 0,
    this.assisted = 0,
  });

  int get total => adults + children + assisted;

  Travelers copyWith({int? adults, int? children, int? assisted}) {
    return Travelers(
      adults: adults ?? this.adults,
      children: children ?? this.children,
      assisted: assisted ?? this.assisted,
    );
  }

  Map<String, dynamic> toJson() => {
        'adults': adults,
        'children': children,
        'assisted': assisted,
      };

  factory Travelers.fromJson(Map<String, dynamic> json) => Travelers(
        adults: (json['adults'] as num?)?.toInt() ?? 0,
        children: (json['children'] as num?)?.toInt() ?? 0,
        assisted: (json['assisted'] as num?)?.toInt() ?? 0,
      );
}

class TripQuery {
  final City? origin;
  final City? destination;
  final Travelers travelers;
  final String? date; // yyyy-MM-dd
  final List<String> dates; // multi-dates
  final TimePeriod? period;
  final List<TimePeriod> periods; // multi-périodes
  final String? exactTime; // HH:mm
  final List<TransportMode> modes;
  final double? budget;

  const TripQuery({
    this.origin,
    this.destination,
    this.travelers = const Travelers(),
    this.date,
    this.dates = const [],
    this.period,
    this.periods = const [],
    this.exactTime,
    this.modes = const [],
    this.budget,
  });

  bool get isEmpty =>
      origin == null &&
      destination == null &&
      travelers.total == 0 &&
      date == null &&
      dates.isEmpty &&
      period == null &&
      periods.isEmpty &&
      exactTime == null &&
      modes.isEmpty &&
      budget == null;

  TripQuery copyWith({
    City? origin,
    City? destination,
    Travelers? travelers,
    String? date,
    List<String>? dates,
    TimePeriod? period,
    List<TimePeriod>? periods,
    String? exactTime,
    List<TransportMode>? modes,
    double? budget,
    bool clearOrigin = false,
    bool clearDestination = false,
    bool clearDate = false,
    bool clearDates = false,
    bool clearPeriod = false,
    bool clearPeriods = false,
    bool clearExactTime = false,
    bool clearBudget = false,
  }) {
    final newDates = clearDates ? <String>[] : (dates ?? this.dates);
    final newDate = clearDate
        ? null
        : (date ?? (newDates.isNotEmpty ? newDates.first : this.date));
    final newPeriods = clearPeriods ? <TimePeriod>[] : (periods ?? this.periods);
    final newPeriod = clearPeriod
        ? null
        : (period ?? (newPeriods.isNotEmpty ? newPeriods.first : this.period));

    return TripQuery(
      origin: clearOrigin ? null : (origin ?? this.origin),
      destination: clearDestination ? null : (destination ?? this.destination),
      travelers: travelers ?? this.travelers,
      date: newDate,
      dates: newDates,
      period: newPeriod,
      periods: newPeriods,
      exactTime: clearExactTime ? null : (exactTime ?? this.exactTime),
      modes: modes ?? this.modes,
      budget: clearBudget ? null : (budget ?? this.budget),
    );
  }

  Map<String, dynamic> toJson() => {
        if (origin != null) 'origin': origin!.toJson(),
        if (destination != null) 'destination': destination!.toJson(),
        'travelers': travelers.toJson(),
        if (date != null) 'date': date,
        if (dates.isNotEmpty) 'dates': dates,
        if (period != null) 'period': timePeriodToString(period),
        if (periods.isNotEmpty)
          'periods': periods.map((p) => timePeriodToString(p)!).toList(),
        if (exactTime != null) 'exactTime': exactTime,
        'modes': modes.map(transportModeToString).toList(),
        if (budget != null) 'budget': budget,
      };

  factory TripQuery.fromJson(Map<String, dynamic> json) {
    final rawDates = (json['dates'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];
    final singleDate = json['date'] as String?;
    final combinedDates = rawDates.isNotEmpty
        ? rawDates
        : (singleDate != null ? [singleDate] : <String>[]);

    final rawPeriods = (json['periods'] as List<dynamic>?)
            ?.map((e) => timePeriodFromString(e.toString()))
            .whereType<TimePeriod>()
            .toList() ??
        [];
    final singlePeriod = timePeriodFromString(json['period'] as String?);
    final combinedPeriods = rawPeriods.isNotEmpty
        ? rawPeriods
        : (singlePeriod != null ? [singlePeriod] : <TimePeriod>[]);

    return TripQuery(
      origin: json['origin'] != null
          ? City.fromJson(json['origin'] as Map<String, dynamic>)
          : null,
      destination: json['destination'] != null
          ? City.fromJson(json['destination'] as Map<String, dynamic>)
          : null,
      travelers: json['travelers'] != null
          ? Travelers.fromJson(json['travelers'] as Map<String, dynamic>)
          : const Travelers(),
      date: singleDate ?? (combinedDates.isNotEmpty ? combinedDates.first : null),
      dates: combinedDates,
      period: singlePeriod ?? (combinedPeriods.isNotEmpty ? combinedPeriods.first : null),
      periods: combinedPeriods,
      exactTime: json['exactTime'] as String?,
      modes: (json['modes'] as List<dynamic>?)
              ?.map((e) => transportModeFromString(e.toString()))
              .toList() ??
          [],
      budget: (json['budget'] as num?)?.toDouble(),
    );
  }
}

enum StopKind { origin, stop, border, destination }

StopKind stopKindFromString(String kind) {
  switch (kind.toLowerCase()) {
    case 'origin':
      return StopKind.origin;
    case 'border':
      return StopKind.border;
    case 'destination':
      return StopKind.destination;
    default:
      return StopKind.stop;
  }
}

String stopKindToString(StopKind kind) {
  switch (kind) {
    case StopKind.origin:
      return 'origin';
    case StopKind.border:
      return 'border';
    case StopKind.destination:
      return 'destination';
    case StopKind.stop:
      return 'stop';
  }
}

class TripStop {
  final String name;
  final String place;
  final String time;
  final StopKind kind;
  final int? waitMinutes;

  const TripStop({
    required this.name,
    required this.place,
    required this.time,
    required this.kind,
    this.waitMinutes,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'place': place,
        'time': time,
        'kind': stopKindToString(kind),
        if (waitMinutes != null) 'waitMinutes': waitMinutes,
      };

  factory TripStop.fromJson(Map<String, dynamic> json) => TripStop(
        name: json['name'] as String? ?? '',
        place: json['place'] as String? ?? '',
        time: json['time'] as String? ?? '',
        kind: stopKindFromString(json['kind'] as String? ?? 'stop'),
        waitMinutes: (json['waitMinutes'] as num?)?.toInt(),
      );
}

class TripResult {
  final String id;
  final String departure;
  final String arrival;
  final String durationLabel;
  final TransportMode mode;
  final int transfers;
  final double price;
  final String currency;
  final String operator;
  final int? seatsLeft;
  final String? badge;
  final String? date;
  final List<TripStop> stops;

  const TripResult({
    required this.id,
    required this.departure,
    required this.arrival,
    required this.durationLabel,
    required this.mode,
    required this.transfers,
    required this.price,
    required this.currency,
    required this.operator,
    this.seatsLeft,
    this.badge,
    this.date,
    this.stops = const [],
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'departure': departure,
        'arrival': arrival,
        'durationLabel': durationLabel,
        'mode': transportModeToString(mode),
        'transfers': transfers,
        'price': price,
        'currency': currency,
        'operator': operator,
        if (seatsLeft != null) 'seatsLeft': seatsLeft,
        if (badge != null) 'badge': badge,
        if (date != null) 'date': date,
        'stops': stops.map((s) => s.toJson()).toList(),
      };

  factory TripResult.fromJson(Map<String, dynamic> json) => TripResult(
        id: json['id'] as String? ?? '',
        departure: json['departure'] as String? ?? '',
        arrival: json['arrival'] as String? ?? '',
        durationLabel: json['durationLabel'] as String? ?? '',
        mode: transportModeFromString(json['mode'] as String? ?? 'bus'),
        transfers: (json['transfers'] as num?)?.toInt() ?? 0,
        price: (json['price'] as num?)?.toDouble() ?? 0.0,
        currency: json['currency'] as String? ?? 'DT',
        operator: json['operator'] as String? ?? '',
        seatsLeft: (json['seatsLeft'] as num?)?.toInt(),
        badge: json['badge'] as String?,
        date: json['date'] as String?,
        stops: (json['stops'] as List<dynamic>?)
                ?.map((e) => TripStop.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );

  TripResult copyWith({
    String? id,
    String? departure,
    String? arrival,
    String? durationLabel,
    TransportMode? mode,
    int? transfers,
    double? price,
    String? currency,
    String? operator,
    int? seatsLeft,
    String? badge,
    String? date,
    List<TripStop>? stops,
  }) {
    return TripResult(
      id: id ?? this.id,
      departure: departure ?? this.departure,
      arrival: arrival ?? this.arrival,
      durationLabel: durationLabel ?? this.durationLabel,
      mode: mode ?? this.mode,
      transfers: transfers ?? this.transfers,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      operator: operator ?? this.operator,
      seatsLeft: seatsLeft ?? this.seatsLeft,
      badge: badge ?? this.badge,
      date: date ?? this.date,
      stops: stops ?? this.stops,
    );
  }
}
