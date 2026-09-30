import '../models/trip.dart';

const List<Country> countries = [
  Country(code: CountryCode.tn, name: 'Tunisie', currency: 'DT'),
  Country(code: CountryCode.ly, name: 'Libye', currency: 'LYD'),
  Country(code: CountryCode.dz, name: 'Algérie', currency: 'DA'),
  Country(code: CountryCode.eg, name: 'Égypte', currency: 'EGP'),
];

Country getCountry(CountryCode code) {
  return countries.firstWhere(
    (c) => c.code == code,
    orElse: () => countries[0],
  );
}

String getCountryFlag(CountryCode code) {
  switch (code) {
    case CountryCode.tn:
      return '🇹🇳';
    case CountryCode.ly:
      return '🇱🇾';
    case CountryCode.dz:
      return '🇩🇿';
    case CountryCode.eg:
      return '🇪🇬';
  }
}

String getCountryLocalizedName(CountryCode code, String lang) {
  switch (code) {
    case CountryCode.tn:
      return lang == 'ar' ? 'تونس' : lang == 'en' ? 'Tunisia' : 'Tunisie';
    case CountryCode.ly:
      return lang == 'ar' ? 'ليبيا' : lang == 'en' ? 'Libya' : 'Libye';
    case CountryCode.dz:
      return lang == 'ar' ? 'الجزائر' : lang == 'en' ? 'Algeria' : 'Algérie';
    case CountryCode.eg:
      return lang == 'ar' ? 'مصر' : lang == 'en' ? 'Egypt' : 'Égypte';
  }
}

List<City> getCitiesByCountry(CountryCode code) {
  return initialCities.where((c) => c.country == code).toList();
}

List<City> getPopularCitiesByCountry(CountryCode code) {
  final citiesInCountry = getCitiesByCountry(code);
  final popular = citiesInCountry.where((c) => popularCityIds.contains(c.id)).toList();
  if (popular.isNotEmpty) return popular;
  return citiesInCountry.take(4).toList();
}

const List<String> popularCityIds = [
  'tn-tunis',
  'tn-sfax',
  'tn-sousse',
  'ly-tripoli',
  'dz-alger',
  'tn-djerba',
];

const Map<String, String> borderPosts = {
  'tn-ly': 'Ras Jedir',
  'ly-tn': 'Ras Jedir',
  'tn-dz': 'Bouchebka',
  'dz-tn': 'Bouchebka',
  'ly-eg': 'Musaid',
  'eg-ly': 'Musaid',
};

final List<City> initialCities = [
  // Tunisie
  const City(id: 'tn-tunis', name: 'Tunis', nameAr: 'تونس', nameFr: 'Tunis', nameEn: 'Tunis', country: CountryCode.tn, aliases: ['tunis', 'tounes', 'تونس', 'تنس', 'تونس العاصمة', 'تونس العاصمه']),
  const City(id: 'tn-sfax', name: 'Sfax', nameAr: 'صفاقس', nameFr: 'Sfax', nameEn: 'Sfax', country: CountryCode.tn, aliases: ['sfax', 'safaqis', 'صفاقس', 'صافاقص', 'صفاقص', 'سفاكس', 'سفكس', 'safaqes', 'sfaks']),
  const City(id: 'tn-sousse', name: 'Sousse', nameAr: 'سوسة', nameFr: 'Sousse', nameEn: 'Sousse', country: CountryCode.tn, aliases: ['sousse', 'susa', 'سوسة', 'سوسه', 'صوسة', 'صوسه', 'souse', 'souss']),
  const City(id: 'tn-hammamet', name: 'Hammamet', nameAr: 'الحمامات', nameFr: 'Hammamet', nameEn: 'Hammamet', country: CountryCode.tn, aliases: ['hammamet', 'الحمامات', 'حمامات']),
  const City(id: 'tn-djerba', name: 'Djerba', nameAr: 'جربة', nameFr: 'Djerba', nameEn: 'Djerba', country: CountryCode.tn, aliases: ['djerba', 'jerba', 'houmt souk', 'جربة', 'جربه']),
  const City(id: 'tn-zarzis', name: 'Zarzis', nameAr: 'جرجيس', nameFr: 'Zarzis', nameEn: 'Zarzis', country: CountryCode.tn, aliases: ['zarzis', 'جرجيس', 'jarjis']),
  const City(id: 'tn-bizerte', name: 'Bizerte', nameAr: 'بنزرت', nameFr: 'Bizerte', nameEn: 'Bizerte', country: CountryCode.tn, aliases: ['bizerte', 'بنزرت', 'banzart']),
  const City(id: 'tn-gabes', name: 'Gabès', nameAr: 'قابس', nameFr: 'Gabès', nameEn: 'Gabes', country: CountryCode.tn, aliases: ['gabes', 'gabès', 'قابس', 'قابص', 'qabis']),
  const City(id: 'tn-nabeul', name: 'Nabeul', nameAr: 'نابل', nameFr: 'Nabeul', nameEn: 'Nabeul', country: CountryCode.tn, aliases: ['nabeul', 'نابل', 'nabul']),
  const City(id: 'tn-kairouan', name: 'Kairouan', nameAr: 'القيروان', nameFr: 'Kairouan', nameEn: 'Kairouan', country: CountryCode.tn, aliases: ['kairouan', 'القيروان', 'qairawan', 'kairwan']),
  const City(id: 'tn-monastir', name: 'Monastir', nameAr: 'المنستير', nameFr: 'Monastir', nameEn: 'Monastir', country: CountryCode.tn, aliases: ['monastir', 'المنستير']),
  const City(id: 'tn-mahdia', name: 'Mahdia', nameAr: 'المهدية', nameFr: 'Mahdia', nameEn: 'Mahdia', country: CountryCode.tn, aliases: ['mahdia', 'المهدية', 'mehdia']),
  const City(id: 'tn-gafsa', name: 'Gafsa', nameAr: 'قفصة', nameFr: 'Gafsa', nameEn: 'Gafsa', country: CountryCode.tn, aliases: ['gafsa', 'قفصة', 'qafsa']),
  const City(id: 'tn-tozeur', name: 'Tozeur', nameAr: 'توزر', nameFr: 'Tozeur', nameEn: 'Tozeur', country: CountryCode.tn, aliases: ['tozeur', 'توزر', 'touzeur']),
  const City(id: 'tn-tataouine', name: 'Tataouine', nameAr: 'تطاوين', nameFr: 'Tataouine', nameEn: 'Tataouine', country: CountryCode.tn, aliases: ['tataouine', 'تطاوين', 'tatawin']),
  const City(id: 'tn-medenine', name: 'Médenine', nameAr: 'مدنين', nameFr: 'Médenine', nameEn: 'Medenine', country: CountryCode.tn, aliases: ['medenine', 'médenine', 'مدنين']),
  const City(id: 'tn-bengardane', name: 'Ben Gardane', nameAr: 'بن قردان', nameFr: 'Ben Gardane', nameEn: 'Ben Gardane', country: CountryCode.tn, aliases: ['ben gardane', 'bengardane', 'بن قردان']),
  const City(id: 'tn-rasjedir', name: 'Ras Ajdir', nameAr: 'رأس جدير', nameFr: 'Ras Ajdir', nameEn: 'Ras Ajdir', country: CountryCode.tn, aliases: ['ras jedir', 'ras ajdir', 'رأس جدير', 'راس جدير']),
  const City(id: 'tn-beja', name: 'Béja', nameAr: 'باجة', nameFr: 'Béja', nameEn: 'Beja', country: CountryCode.tn, aliases: ['beja', 'béja', 'باجة']),
  const City(id: 'tn-jendouba', name: 'Jendouba', nameAr: 'جندوبة', nameFr: 'Jendouba', nameEn: 'Jendouba', country: CountryCode.tn, aliases: ['jendouba', 'جندوبة']),
  const City(id: 'tn-kef', name: 'Le Kef', nameAr: 'الكاف', nameFr: 'Le Kef', nameEn: 'Le Kef', country: CountryCode.tn, aliases: ['le kef', 'kef', 'الكاف']),
  const City(id: 'tn-kasserine', name: 'Kasserine', nameAr: 'القصرين', nameFr: 'Kasserine', nameEn: 'Kasserine', country: CountryCode.tn, aliases: ['kasserine', 'القصرين']),
  const City(id: 'tn-siliana', name: 'Siliana', nameAr: 'سليانة', nameFr: 'Siliana', nameEn: 'Siliana', country: CountryCode.tn, aliases: ['siliana', 'سليانة']),
  const City(id: 'tn-zaghouan', name: 'Zaghouan', nameAr: 'زغوان', nameFr: 'Zaghouan', nameEn: 'Zaghouan', country: CountryCode.tn, aliases: ['zaghouan', 'زغوان']),
  const City(id: 'tn-kebili', name: 'Kébili', nameAr: 'قبلي', nameFr: 'Kébili', nameEn: 'Kebili', country: CountryCode.tn, aliases: ['kebili', 'kébili', 'قبلي']),

  // Libye
  const City(id: 'ly-tripoli', name: 'Tripoli', nameAr: 'طرابلس', nameFr: 'Tripoli', nameEn: 'Tripoli', country: CountryCode.ly, aliases: ['tripoli', 'tarabulus', 'طرابلس', 'طربلس', 'ترابلس', 'trablus']),
  const City(id: 'ly-misrata', name: 'Misrata', nameAr: 'مصراتة', nameFr: 'Misrata', nameEn: 'Misrata', country: CountryCode.ly, aliases: ['misrata', 'misurata', 'مصراتة', 'مصراته', 'مسراتة', 'مسراته']),
  const City(id: 'ly-benghazi', name: 'Benghazi', nameAr: 'بنغازي', nameFr: 'Benghazi', nameEn: 'Benghazi', country: CountryCode.ly, aliases: ['benghazi', 'bengasi', 'بنغازي', 'بن غازي', 'بنغازى']),
  const City(id: 'ly-sabha', name: 'Sabha', nameAr: 'سبها', nameFr: 'Sabha', nameEn: 'Sabha', country: CountryCode.ly, aliases: ['sabha', 'sebha', 'سبها']),
  const City(id: 'ly-sirte', name: 'Sirte', nameAr: 'سرت', nameFr: 'Sirte', nameEn: 'Sirte', country: CountryCode.ly, aliases: ['sirte', 'syrte', 'سرت']),
  const City(id: 'ly-tobrouk', name: 'Tobrouk', nameAr: 'طبرق', nameFr: 'Tobrouk', nameEn: 'Tobruk', country: CountryCode.ly, aliases: ['tobrouk', 'tobruk', 'طبرق']),
  const City(id: 'ly-zawiya', name: 'Zawiya', nameAr: 'الزاوية', nameFr: 'Zawiya', nameEn: 'Zawiya', country: CountryCode.ly, aliases: ['zawiya', 'zaouia', 'الزاوية']),
  const City(id: 'ly-zliten', name: 'Zliten', nameAr: 'زليتن', nameFr: 'Zliten', nameEn: 'Zliten', country: CountryCode.ly, aliases: ['zliten', 'زليتن']),
  const City(id: 'ly-derna', name: 'Derna', nameAr: 'درنة', nameFr: 'Derna', nameEn: 'Derna', country: CountryCode.ly, aliases: ['derna', 'درنة']),
  const City(id: 'ly-ajdabiya', name: 'Ajdabiya', nameAr: 'أجدابيا', nameFr: 'Ajdabiya', nameEn: 'Ajdabiya', country: CountryCode.ly, aliases: ['ajdabiya', 'اجدابيا', 'أجدابيا']),
  const City(id: 'ly-khoms', name: 'Khoms', nameAr: 'الخمس', nameFr: 'Khoms', nameEn: 'Khoms', country: CountryCode.ly, aliases: ['al khums', 'khoms', 'الخمس', 'خمس']),
  const City(id: 'ly-zouara', name: 'Zouara', nameAr: 'زوارة', nameFr: 'Zouara', nameEn: 'Zuwara', country: CountryCode.ly, aliases: ['zouara', 'zuwara', 'زوارة', 'زواره']),
  const City(id: 'ly-jufra', name: 'Jufra', nameAr: 'الجفرة', nameFr: 'Jufra', nameEn: 'Jufra', country: CountryCode.ly, aliases: ['jufra', 'joufra', 'الجفرة']),

  // Algérie
  const City(id: 'dz-alger', name: 'Alger', nameAr: 'الجزائر', nameFr: 'Alger', nameEn: 'Algiers', country: CountryCode.dz, aliases: ['alger', 'algiers', 'الجزائر']),
  const City(id: 'dz-oran', name: 'Oran', nameAr: 'وهران', nameFr: 'Oran', nameEn: 'Oran', country: CountryCode.dz, aliases: ['oran', 'wahran', 'وهران']),
  const City(id: 'dz-constantine', name: 'Constantine', nameAr: 'قسنطينة', nameFr: 'Constantine', nameEn: 'Constantine', country: CountryCode.dz, aliases: ['constantine', 'قسنطينة']),
  const City(id: 'dz-annaba', name: 'Annaba', nameAr: 'عنابة', nameFr: 'Annaba', nameEn: 'Annaba', country: CountryCode.dz, aliases: ['annaba', 'عنابة']),
  const City(id: 'dz-setif', name: 'Sétif', nameAr: 'سطيف', nameFr: 'Sétif', nameEn: 'Setif', country: CountryCode.dz, aliases: ['setif', 'sétif', 'سطيف']),
  const City(id: 'dz-batna', name: 'Batna', nameAr: 'باتنة', nameFr: 'Batna', nameEn: 'Batna', country: CountryCode.dz, aliases: ['batna', 'باتنة']),

  // Égypte
  const City(id: 'eg-caire', name: 'Le Caire', nameAr: 'القاهرة', nameFr: 'Le Caire', nameEn: 'Cairo', country: CountryCode.eg, aliases: ['le caire', 'caire', 'cairo', 'القاهرة', 'القاهره']),
  const City(id: 'eg-alexandrie', name: 'Alexandrie', nameAr: 'الإسكندرية', nameFr: 'Alexandrie', nameEn: 'Alexandria', country: CountryCode.eg, aliases: ['alexandrie', 'alexandria', 'الإسكندرية', 'الاسكندرية']),
];

String normalizeText(String text) {
  return text
      .toLowerCase()
      .replaceAll(RegExp(r'[éèêë]'), 'e')
      .replaceAll(RegExp(r'[àâä]'), 'a')
      .replaceAll(RegExp(r'[îï]'), 'i')
      .replaceAll(RegExp(r'[ôö]'), 'o')
      .replaceAll(RegExp(r'[ûüù]'), 'u')
      .replaceAll(RegExp(r'[ç]'), 'c')
      .replaceAll(RegExp(r'[\u064B-\u0652\u0640]'), '')
      .replaceAll(RegExp(r'[إأآٱء]'), 'ا')
      .replaceAll('ة', 'ه')
      .replaceAll('ى', 'ي')
      .replaceAll(RegExp(r'[\s\-_]+'), ' ')
      .trim();
}

City? findCity(String query) {
  final norm = normalizeText(query);
  if (norm.isEmpty) return null;
  for (final city in initialCities) {
    if (normalizeText(city.name) == norm) return city;
    for (final alias in city.aliases) {
      if (normalizeText(alias) == norm) return city;
    }
  }
  return null;
}

List<City> searchCities(String query, {CountryCode? country, String? excludeId}) {
  final q = normalizeText(query);
  return initialCities.where((city) {
    if (excludeId != null && city.id == excludeId) return false;
    if (country != null && city.country != country) return false;
    if (q.isEmpty) return true;
    return normalizeText(city.name).contains(q) ||
        city.aliases.any((alias) => normalizeText(alias).contains(q));
  }).toList();
}

/// Postes frontières et repères connus avec traductions multilingues
const Map<String, Map<String, String>> specialLandmarks = {
  'ras jedir': {'ar': 'رأس جدير', 'fr': 'Ras Ajdir', 'en': 'Ras Ajdir'},
  'ras ajdir': {'ar': 'رأس جدير', 'fr': 'Ras Ajdir', 'en': 'Ras Ajdir'},
  'bouchebka': {'ar': 'بوشبكة', 'fr': 'Bouchebka', 'en': 'Bouchebka'},
  'debdeb': {'ar': 'الدبداب', 'fr': 'Debdeb', 'en': 'Debdeb'},
  'dehiba': {'ar': 'الذهيبة', 'fr': 'Dehiba', 'en': 'Dehiba'},
  'wazen': {'ar': 'وازن', 'fr': 'Wazen', 'en': 'Wazen'},
  'musaid': {'ar': 'منفذ السلوم / مساعد', 'fr': 'Musaid / Salum', 'en': 'Musaid / Salum'},
  'salum': {'ar': 'السلوم', 'fr': 'Salum', 'en': 'Salum'},
  'salloum': {'ar': 'السلوم', 'fr': 'Salloum', 'en': 'Salloum'},
  'bab alioua': {'ar': 'باب عليوة', 'fr': 'Bab Alioua', 'en': 'Bab Alioua'},
  'station sud': {'ar': 'محطة الجنوب', 'fr': 'Station Sud', 'en': 'South Station'},
  'poste frontiere': {'ar': 'نقطة حدودية', 'fr': 'Poste frontière', 'en': 'Border crossing'},
};

/// Retourne le nom de la ville ou du point d'arrêt adapté à la langue choisie ('fr', 'en', 'ar')
String localizeCityName(String raw, String lang) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return '';

  // 1. Recherche dans les villes connues
  final found = findCity(trimmed);
  if (found != null) {
    if (lang == 'ar' && found.nameAr != null && found.nameAr!.isNotEmpty) {
      return found.nameAr!;
    }
    if (lang == 'en' && found.nameEn != null && found.nameEn!.isNotEmpty) {
      return found.nameEn!;
    }
    if (lang == 'fr' && found.nameFr != null && found.nameFr!.isNotEmpty) {
      return found.nameFr!;
    }
    if (lang == 'ar') {
      final arAlias = found.aliases.firstWhere(
        (a) => RegExp(r'[\u0600-\u06FF]').hasMatch(a),
        orElse: () => found.name,
      );
      return arAlias;
    }
    return found.name;
  }

  // 2. Recherche dans les repères / postes frontières connus
  final lower = trimmed.toLowerCase();
  for (final entry in specialLandmarks.entries) {
    if (lower.contains(entry.key)) {
      final trans = entry.value[lang];
      if (trans != null && trans.isNotEmpty) return trans;
    }
  }

  // 3. Traitement des chaînes mixtes Arabe/Latin (ex: "Ras Ajdir (رأس جدير)")
  final hasArabic = RegExp(r'[\u0600-\u06FF]').hasMatch(trimmed);
  final hasLatin = RegExp(r'[a-zA-Z]').hasMatch(trimmed);

  if (hasArabic && hasLatin) {
    if (lang == 'ar') {
      // Extraire le texte en arabe pur
      final arMatches = RegExp(r'[\u0600-\u06FF\s/]+').allMatches(trimmed);
      final arPart = arMatches.map((m) => m.group(0)!).join(' ').trim();
      if (arPart.isNotEmpty) return arPart;
    } else {
      // Retirer la partie arabe et les parenthèses
      final cleaned = trimmed
          .replaceAll(RegExp(r'[\u0600-\u06FF\u064B-\u0652\u0640]+'), '')
          .replaceAll(RegExp(r'[\(\)\[\]]'), '')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
      if (cleaned.isNotEmpty) return cleaned;
    }
  }

  // 4. Si la langue est arabe et que la chaîne est en latin pur, chercher une ville correspondante
  if (lang == 'ar' && !hasArabic && hasLatin) {
    for (final city in initialCities) {
      if (city.name.toLowerCase() == lower || city.nameEn?.toLowerCase() == lower) {
        if (city.nameAr != null && city.nameAr!.isNotEmpty) return city.nameAr!;
      }
    }
  }

  return trimmed;
}

/// Traduit l'intitulé de lieu ou de station associé à un arrêt
String localizePlaceName(String rawPlace, String lang) {
  final trimmed = rawPlace.trim();
  if (trimmed.isEmpty) return '';

  final lower = trimmed.toLowerCase();

  if (lang == 'ar') {
    if (lower.contains('gare centrale') || lower.contains('station de départ')) {
      return 'المحطة المركزية / محطة الانطلاق';
    }
    if (lower.contains('terminus') || lower.contains("d'arrivée") || lower.contains('d’arrivée')) {
      return 'المحطة النهائية / محطة الوصول';
    }
    if (lower.contains('passeport') || lower.contains('douane') || lower.contains('formalités')) {
      return 'مراقبة الجوازات والجمارك';
    }
    if (lower.contains('aire de repos')) {
      return 'استراحة ومحطة ركاب';
    }
    if (lower.contains('arrêt intermédiaire')) {
      return 'نقطة توقف وسيطة';
    }
    if (lower.startsWith('station de ') || lower.startsWith('arrêt de ')) {
      final cityPart = trimmed.substring(trimmed.indexOf('de ') + 3).trim();
      return 'محطة ${localizeCityName(cityPart, 'ar')}';
    }
    if (lower.startsWith('gare routière')) {
      final cityPart = trimmed.substring(13).trim().replaceFirst(RegExp(r'^de\s+', caseSensitive: false), '');
      return 'محطة حافلات ${localizeCityName(cityPart, 'ar')}';
    }
    // Si la chaîne contient déjà de l'arabe et du français, extraire l'arabe
    if (RegExp(r'[\u0600-\u06FF]').hasMatch(trimmed) && RegExp(r'[a-zA-Z]').hasMatch(trimmed)) {
      final arMatches = RegExp(r'[\u0600-\u06FF\s/]+').allMatches(trimmed);
      final arPart = arMatches.map((m) => m.group(0)!).join(' ').trim();
      if (arPart.isNotEmpty) return arPart;
    }
    return trimmed;
  } else if (lang == 'en') {
    if (lower.contains('gare centrale') || lower.contains('station de départ')) {
      return 'Central Station / Departure';
    }
    if (lower.contains('terminus') || lower.contains("d'arrivée") || lower.contains('d’arrivée')) {
      return 'Terminus / Arrival Station';
    }
    if (lower.contains('passeport') || lower.contains('douane') || lower.contains('formalités')) {
      return 'Customs & Passport Control';
    }
    if (lower.contains('aire de repos')) {
      return 'Rest area & boarding';
    }
    if (lower.contains('arrêt intermédiaire')) {
      return 'Intermediate stop';
    }
    if (lower.startsWith('station de ') || lower.startsWith('arrêt de ')) {
      final cityPart = trimmed.substring(trimmed.indexOf('de ') + 3).trim();
      return '${localizeCityName(cityPart, 'en')} Station';
    }
    return trimmed;
  }

  // Version française par défaut : nettoyer les parenthèses arabes si présentes
  return trimmed.replaceAll(RegExp(r'\s*\([\u0600-\u06FF\s]+\)'), '').trim();
}

/// Localise un libellé de durée (ex: "7h 15" ou "8h 00")
String localizeDuration(String durationLabel, String lang) {
  if (durationLabel.trim().isEmpty) return '';
  final match = RegExp(r'(\d+)\s*h\s*(\d*)', caseSensitive: false).firstMatch(durationLabel);
  if (match == null) return durationLabel;

  final hours = int.tryParse(match.group(1) ?? '0') ?? 0;
  final mins = int.tryParse(match.group(2) ?? '0') ?? 0;

  if (lang == 'ar') {
    if (mins > 0) return '$hours س $mins د';
    return '$hours ساعات';
  }
  if (lang == 'en') {
    if (mins > 0) return '${hours}h ${mins}m';
    return '${hours}h';
  }
  return mins > 0 ? '${hours}h${mins.toString().padLeft(2, '0')}' : '${hours}h00';
}

/// Formate la devise selon la langue
String formatCurrency(String currency, String lang) {
  if (currency.trim().isEmpty) return '';
  final c = currency.trim().toUpperCase();
  if (lang == 'ar') {
    if (c == 'DT' || c == 'TND') return 'د.ت';
    if (c == 'LD' || c == 'LYD') return 'د.ل';
    if (c == 'DA' || c == 'DZD') return 'د.ج';
    if (c == 'EGP') return 'ج.م';
    return c;
  }
  if (lang == 'en') {
    if (c == 'DT') return 'TND';
    if (c == 'LD') return 'LYD';
    if (c == 'DA') return 'DZD';
    return c;
  }
  if (c == 'TND') return 'DT';
  if (c == 'LD') return 'LYD';
  if (c == 'DZD') return 'DA';
  return c;
}
