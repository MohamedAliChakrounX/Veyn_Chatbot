import 'dart:math';
import 'package:intl/intl.dart';
import '../data/locations.dart';
import '../models/chat_message.dart';
import '../models/trip.dart';

class NluFallback {
  static final Random _rand = Random();

  static AssistantResponse processMessage(String text, TripQuery currentTrip) {
    final norm = normalizeText(text);
    City? origin = currentTrip.origin;
    City? destination = currentTrip.destination;
    String? date = currentTrip.date;
    TimePeriod? period = currentTrip.period;

    // Détection de villes
    for (final city in initialCities) {
      final cityNorm = normalizeText(city.name);
      if (norm.contains(cityNorm)) {
        if (norm.contains('vers $cityNorm') ||
            norm.contains('a $cityNorm') ||
            norm.contains('pour $cityNorm')) {
          destination ??= city;
        } else if (norm.contains('de $cityNorm') ||
            norm.contains('depuis $cityNorm')) {
          origin ??= city;
        } else if (origin == null) {
          origin = city;
        } else if (destination == null && city.id != origin.id) {
          destination = city;
        }
      }
    }

    // Détection de dates
    if (norm.contains('demain')) {
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      date = DateFormat('yyyy-MM-dd').format(tomorrow);
    } else if (norm.contains('aujourd') || norm.contains('ce jour')) {
      date = DateFormat('yyyy-MM-dd').format(DateTime.now());
    }

    // Détection de période
    if (norm.contains('matin') || norm.contains('matinee')) {
      period = TimePeriod.morning;
    } else if (norm.contains('apres midi') || norm.contains('midi')) {
      period = TimePeriod.afternoon;
    } else if (norm.contains('soir') || norm.contains('nuit')) {
      period = TimePeriod.evening;
    }

    final patch = <String, dynamic>{};
    final recognized = <String>[];
    if (origin != null) {
      patch['origin'] = origin.toJson();
      recognized.add('origin');
    }
    if (destination != null) {
      patch['destination'] = destination.toJson();
      recognized.add('destination');
    }
    if (date != null) {
      patch['date'] = date;
      recognized.add('date');
    }
    if (period != null) {
      patch['period'] = timePeriodToString(period);
      recognized.add('time');
    }

    // Si origine ou destination manquante
    if (origin == null || destination == null) {
      final missing = <String>[];
      if (origin == null) missing.add('origin');
      if (destination == null) missing.add('destination');

      final quickReplies = <QuickReply>[];
      if (origin == null) {
        quickReplies.addAll([
          const QuickReply(label: 'Départ : Tripoli', value: 'Départ depuis Tripoli'),
          const QuickReply(label: 'Départ : Tunis', value: 'Départ depuis Tunis'),
          const QuickReply(label: 'Départ : Misrata', value: 'Départ depuis Misrata'),
        ]);
      } else {
        quickReplies.addAll([
          const QuickReply(label: 'Vers Tunis', value: 'Direction Tunis'),
          const QuickReply(label: 'Vers Tripoli', value: 'Direction Tripoli'),
          const QuickReply(label: 'Vers Sousse', value: 'Direction Sousse'),
        ]);
      }

      return AssistantResponse(
        reply: origin == null
            ? 'D’où souhaitez-vous partir ? Précisez votre ville de départ.'
            : 'Quelle est votre destination pour ce voyage au départ de ${origin.name} ?',
        tripPatch: patch,
        recognized: recognized,
        missing: missing,
        quickReplies: quickReplies,
      );
    }

    // Génération de trajets simulés
    final results = generateTrips(origin, destination, date, period);

    return AssistantResponse(
      reply:
          'J’ai trouvé ${results.length} trajets disponibles pour ${origin.name} → ${destination.name}. Vous pouvez réserver directement ou affiner vos critères.',
      tripPatch: patch,
      recognized: recognized,
      results: results,
      quickReplies: [
        const QuickReply(label: 'Départs le matin', value: 'Uniquement les départs du matin'),
        const QuickReply(label: 'Moins chers', value: 'Trier par prix le plus bas'),
      ],
    );
  }

  static List<TripResult> generateTrips(
    City origin,
    City destination,
    String? date,
    TimePeriod? period,
  ) {
    final currency = origin.country == CountryCode.ly ? 'LYD' : 'DT';
    final isCrossBorder = origin.country != destination.country;
    final basePrice = isCrossBorder ? 120.0 : 45.0;

    final morningSchedules = [
      {'dep': '06:30', 'arr': '14:30', 'dur': '8h 00', 'mode': TransportMode.bus, 'op': 'Veyn Express', 'opCode': 'VX-101'},
      {'dep': '08:00', 'arr': '15:15', 'dur': '7h 15', 'mode': TransportMode.sharedTaxi, 'op': 'Louage Maghreb', 'opCode': 'LM-304'},
    ];

    final afternoonSchedules = [
      {'dep': '13:00', 'arr': '20:30', 'dur': '7h 30', 'mode': TransportMode.bus, 'op': 'SNTRI Inter-États', 'opCode': 'SN-808'},
      {'dep': '15:30', 'arr': '22:45', 'dur': '7h 15', 'mode': TransportMode.sharedTaxi, 'op': 'Louage Direct', 'opCode': 'LD-202'},
    ];

    final selectedList = period == TimePeriod.afternoon
        ? afternoonSchedules
        : period == TimePeriod.evening
            ? [afternoonSchedules.last]
            : morningSchedules;

    final results = <TripResult>[];
    DateTime baseDate = DateTime.now();
    if (date != null && date.isNotEmpty) {
      try {
        baseDate = DateTime.parse(date);
      } catch (_) {}
    }

    // Générer les trajets sur 5 jours consécutifs
    for (int dayOffset = 0; dayOffset < 5; dayOffset++) {
      final currentDay = baseDate.add(Duration(days: dayOffset));
      final yyyy = currentDay.year.toString();
      final mm = currentDay.month.toString().padLeft(2, '0');
      final dd = currentDay.day.toString().padLeft(2, '0');
      final dayStr = '$yyyy-$mm-$dd';

      for (var i = 0; i < selectedList.length; i++) {
        final item = selectedList[i];
        final stops = <TripStop>[
          TripStop(
            name: origin.name,
            place: 'Gare centrale / Station de départ',
            time: item['dep'] as String,
            kind: StopKind.origin,
          ),
        ];

        if (isCrossBorder) {
          stops.add(const TripStop(
            name: 'Ras Ajdir (رأس جدير)',
            place: 'Poste frontière et formalités douanières',
            time: '10:30',
            kind: StopKind.border,
            waitMinutes: 45,
          ));
        } else {
          stops.add(const TripStop(
            name: 'Arrêt intermédiaire',
            place: 'Aire de repos & embarquement rapide',
            time: '11:00',
            kind: StopKind.stop,
            waitMinutes: 15,
          ));
        }

        stops.add(TripStop(
          name: destination.name,
          place: 'Terminus / Gare d’arrivée',
          time: item['arr'] as String,
          kind: StopKind.destination,
        ));

        results.add(TripResult(
          id: 'mock-${item['opCode']}-$dayOffset-$i',
          departure: item['dep'] as String,
          arrival: item['arr'] as String,
          durationLabel: item['dur'] as String,
          mode: item['mode'] as TransportMode,
          transfers: isCrossBorder ? 1 : 0,
          price: basePrice + (i * 15.0),
          currency: currency,
          operator: item['op'] as String,
          seatsLeft: _rand.nextInt(12) + 2,
          badge: i == 0 ? 'Le plus rapide' : 'Meilleur prix',
          date: dayStr,
          stops: stops,
        ));
      }
    }

    return results;
  }
}
