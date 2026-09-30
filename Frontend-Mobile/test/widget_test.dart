import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:veyn_mobile/main.dart';
import 'package:veyn_mobile/models/trip.dart';
import 'package:veyn_mobile/data/locations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('VeynApp launches with chat header and input', (WidgetTester tester) async {
    await tester.pumpWidget(const VeynApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Vérifie la présence des éléments de l'en-tête
    expect(find.byTooltip('Nouveau'), findsOneWidget);
    expect(find.byTooltip('Historique'), findsOneWidget);

    // Vérifie le message de bienvenue de l'assistant
    expect(find.textContaining('Où souhaitez-vous voyager', findRichText: true), findsOneWidget);
  });

  test('TripQuery JSON serialization and copyWith works', () {
    const city = City(id: 'tn-tunis', name: 'Tunis', country: CountryCode.tn);
    const query = TripQuery(
      origin: city,
      travelers: Travelers(adults: 2, children: 1),
    );

    expect(query.origin?.name, 'Tunis');
    expect(query.travelers.total, 3);

    final json = query.toJson();
    expect(json['origin']['name'], 'Tunis');
    expect(json['travelers']['adults'], 2);

    final recreated = TripQuery.fromJson(json);
    expect(recreated.origin?.name, 'Tunis');
    expect(recreated.travelers.adults, 2);
    expect(recreated.travelers.children, 1);
  });

  test('localizeCityName and localizePlaceName provide clean Arabic without French', () {
    expect(localizeCityName('Ras Ajdir (رأس جدير)', 'ar'), 'رأس جدير');
    expect(localizeCityName('Ras Ajdir (رأس جدير)', 'fr'), 'Ras Ajdir');
    expect(localizePlaceName('Gare centrale / Station de départ', 'ar'), 'المحطة المركزية / محطة الانطلاق');
    expect(localizePlaceName('Terminus / Gare d’arrivée', 'ar'), 'المحطة النهائية / محطة الوصول');
    expect(localizePlaceName('Aire de repos & embarquement rapide', 'ar'), 'استراحة ومحطة ركاب');
    expect(localizePlaceName('Contrôle des passeports et douanes', 'ar'), 'مراقبة الجوازات والجمارك');
  });

  test('TripResult.copyWith updates date and schedule accurately', () {
    const trip = TripResult(
      id: 't-1',
      departure: '08:00',
      arrival: '15:00',
      durationLabel: '7h 00',
      mode: TransportMode.bus,
      transfers: 0,
      price: 80.0,
      currency: 'DT',
      operator: 'Veyn Express',
      date: '2026-09-25',
    );

    final modified = trip.copyWith(date: '2026-09-28', departure: '09:30');
    expect(modified.date, '2026-09-28');
    expect(modified.departure, '09:30');
    expect(modified.operator, 'Veyn Express');
  });
}
