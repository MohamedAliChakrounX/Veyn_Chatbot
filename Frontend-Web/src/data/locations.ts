import type { Language } from '../i18n/translations'
import type { City, Country, CountryCode } from '../types/trip'

export const COUNTRIES: Country[] = [
  { code: 'TN', name: 'Tunisie', currency: 'DT' },
  { code: 'LY', name: 'Libye', currency: 'LYD' },
  { code: 'DZ', name: 'Algérie', currency: 'DA' },
  { code: 'EG', name: 'Égypte', currency: 'EGP' },
]

/**
 * Référentiel des villes et arrêts desservis (aligné avec la base de données réelle).
 */
export const CITIES: City[] = [
  // Libye
  { id: 'ly-tripoli', name: 'Tripoli', nameAr: 'طرابلس', nameFr: 'Tripoli', nameEn: 'Tripoli', country: 'LY', aliases: ['طرابلس', 'طربلس', 'ترابلس', 'trablus', 'tarabulus', 'tripolis', 'tripoli', 'tripolie'] },
  { id: 'ly-misrata', name: 'Misrata', nameAr: 'مصراتة', nameFr: 'Misrata', nameEn: 'Misrata', country: 'LY', aliases: ['مصراتة', 'مصراته', 'مسراتة', 'مسراته', 'misurata', 'misrata'] },
  { id: 'ly-benghazi', name: 'Benghazi', nameAr: 'بنغازي', nameFr: 'Benghazi', nameEn: 'Benghazi', country: 'LY', aliases: ['بنغازي', 'بن غازي', 'بنغازى', 'bengazi', 'benghazy'] },
  { id: 'ly-jufra', name: 'Jufra', nameAr: 'الجفرة', nameFr: 'Jufra', nameEn: 'Jufra', country: 'LY', aliases: ['الجفرة', 'jufrah', 'joufra', 'al jofra'] },
  { id: 'ly-sabha', name: 'Sabha', nameAr: 'سبها', nameFr: 'Sabha', nameEn: 'Sabha', country: 'LY', aliases: ['سبها', 'sebha'] },
  { id: 'ly-sirte', name: 'Sirte', nameAr: 'سرت', nameFr: 'Sirte', nameEn: 'Sirte', country: 'LY', aliases: ['سرت', 'surt'] },
  { id: 'ly-tobrouk', name: 'Tobrouk', nameAr: 'طبرق', nameFr: 'Tobrouk', nameEn: 'Tobruk', country: 'LY', aliases: ['طبرق', 'tobruk', 'tubruq'] },
  { id: 'ly-zuwara', name: 'Zuwara', nameAr: 'زوارة', nameFr: 'Zuwara', nameEn: 'Zuwara', country: 'LY', aliases: ['زوارة', 'زواره', 'zouara', 'zuwarah'] },
  { id: 'ly-khoms', name: 'Khoms', nameAr: 'الخمس', nameFr: 'Khoms', nameEn: 'Khoms', country: 'LY', aliases: ['الخمس', 'خمس', 'al khums', 'khoms', 'alkhums'] },
  { id: 'ly-zliten', name: 'Zliten', nameAr: 'زليتن', nameFr: 'Zliten', nameEn: 'Zliten', country: 'LY', aliases: ['زليتن', 'ًزليتن', 'zlitan'] },
  { id: 'ly-ajdabiya', name: 'Ajdabiya', nameAr: 'أجدابيا', nameFr: 'Ajdabiya', nameEn: 'Ajdabiya', country: 'LY', aliases: ['اجدابيا', 'أجدابيا', 'ajdabiyah', 'egedabia'] },
  { id: 'ly-derna', name: 'Derna', nameAr: 'درنة', nameFr: 'Derna', nameEn: 'Derna', country: 'LY', aliases: ['درنة', 'درنه', 'darnah'] },
  { id: 'ly-al-bayda', name: 'Al Bayda', nameAr: 'البيضاء', nameFr: 'Al Bayda', nameEn: 'Al Bayda', country: 'LY', aliases: ['البيضاء', 'بيضاء', 'el bayda', 'beida'] },
  { id: 'ly-bin-jawad', name: 'Bin Jawad', nameAr: 'بن جواد', nameFr: 'Bin Jawad', nameEn: 'Bin Jawad', country: 'LY', aliases: ['بن جواد', 'bin jawad'] },
  { id: 'ly-ras-lanouf', name: 'Ras Lanouf', nameAr: 'رأس لانوف', nameFr: 'Ras Lanouf', nameEn: 'Ras Lanouf', country: 'LY', aliases: ['راس لانوف', 'ras lanuf'] },
  { id: 'ly-el-brega', name: 'El Brega', nameAr: 'البريقة', nameFr: 'El Brega', nameEn: 'El Brega', country: 'LY', aliases: ['البريقة', 'بريقه', 'marsa el brega'] },
  { id: 'ly-janzour', name: 'Janzour', nameAr: 'جنزور', nameFr: 'Janzour', nameEn: 'Janzour', country: 'LY', aliases: ['جنزور', 'janzur'] },

  // Tunisie
  { id: 'tn-tunis', name: 'Tunis', nameAr: 'تونس', nameFr: 'Tunis', nameEn: 'Tunis', country: 'TN', aliases: ['تونس', 'تنس', 'tounes', 'tunisia', 'tunis', 'تونس العاصمة', 'تونس العاصمه'] },
  { id: 'tn-sfax', name: 'Sfax', nameAr: 'صفاقس', nameFr: 'Sfax', nameEn: 'Sfax', country: 'TN', aliases: ['صفاقس', 'صافاقص', 'صفاقص', 'سفاكس', 'سفكس', 'safaqis', 'safaqes', 'sfaks', 'sakiet ezzit', 'sfaxe'] },
  { id: 'tn-sousse', name: 'Sousse', nameAr: 'سوسة', nameFr: 'Sousse', nameEn: 'Sousse', country: 'TN', aliases: ['سوسة', 'سوسه', 'صوسة', 'صوسه', 'susa', 'suse', 'sousse', 'souse', 'souss', 'soussa'] },
  { id: 'tn-hammamet', name: 'Hammamet', nameAr: 'الحمامات', nameFr: 'Hammamet', nameEn: 'Hammamet', country: 'TN', aliases: ['الحمامات', 'حمامات', 'hamamet', 'hammamet'] },
  { id: 'tn-djerba', name: 'Djerba', nameAr: 'جربة', nameFr: 'Djerba', nameEn: 'Djerba', country: 'TN', aliases: ['جربة', 'جربه', 'jerba', 'houmt souk', 'djerba'] },
  { id: 'tn-zarzis', name: 'Zarzis', nameAr: 'جرجيس', nameFr: 'Zarzis', nameEn: 'Zarzis', country: 'TN', aliases: ['جرجيس', 'jarjis', 'zarzis'] },
  { id: 'tn-koutine', name: 'Koutine', nameAr: 'كوتين', nameFr: 'Koutine', nameEn: 'Koutine', country: 'TN', aliases: ['كوتين', 'koutine', 'medenine'] },
  { id: 'tn-ras-jedir', name: 'Ras Ajdir', nameAr: 'رأس جدير', nameFr: 'Ras Ajdir', nameEn: 'Ras Ajdir', country: 'TN', aliases: ['رأس جدير', 'راس جدير', 'راس جادير', 'ras ajdir', 'ras jedir'] },
  { id: 'tn-kairouan', name: 'Kairouan', nameAr: 'القيروان', nameFr: 'Kairouan', nameEn: 'Kairouan', country: 'TN', aliases: ['القيروان', 'قيروان', 'qairawan', 'kairwan'] },
  { id: 'tn-bizerte', name: 'Bizerte', nameAr: 'بنزرت', nameFr: 'Bizerte', nameEn: 'Bizerte', country: 'TN', aliases: ['بنزرت', 'banzart', 'bizerte'] },
  { id: 'tn-gabes', name: 'Gabès', nameAr: 'قابس', nameFr: 'Gabès', nameEn: 'Gabes', country: 'TN', aliases: ['قابس', 'قابص', 'gabes', 'gabès', 'qabis'] },
  { id: 'tn-nabeul', name: 'Nabeul', nameAr: 'نابل', nameFr: 'Nabeul', nameEn: 'Nabeul', country: 'TN', aliases: ['نابل', 'nabul', 'nabeul'] },
  { id: 'tn-monastir', name: 'Monastir', nameAr: 'المنستير', nameFr: 'Monastir', nameEn: 'Monastir', country: 'TN', aliases: ['المنستير', 'monastir'] },
  { id: 'tn-mahdia', name: 'Mahdia', nameAr: 'المهدية', nameFr: 'Mahdia', nameEn: 'Mahdia', country: 'TN', aliases: ['المهدية', 'mehdia'] },
  { id: 'tn-gafsa', name: 'Gafsa', nameAr: 'قفصة', nameFr: 'Gafsa', nameEn: 'Gafsa', country: 'TN', aliases: ['قفصة', 'qafsa'] },
  { id: 'tn-tozeur', name: 'Tozeur', nameAr: 'توزر', nameFr: 'Tozeur', nameEn: 'Tozeur', country: 'TN', aliases: ['توزر', 'touzeur'] },
  { id: 'tn-tataouine', name: 'Tataouine', nameAr: 'تطاوين', nameFr: 'Tataouine', nameEn: 'Tataouine', country: 'TN', aliases: ['تطاوين', 'tatawin'] },

  // Algérie
  { id: 'dz-alger', name: 'Alger', nameAr: 'الجزائر', nameFr: 'Alger', nameEn: 'Algiers', country: 'DZ', aliases: ['الجزائر', 'algiers', 'el djazair'] },
  { id: 'dz-oran', name: 'Oran', nameAr: 'وهران', nameFr: 'Oran', nameEn: 'Oran', country: 'DZ', aliases: ['وهران', 'wahran'] },
  { id: 'dz-constantine', name: 'Constantine', nameAr: 'قسنطينة', nameFr: 'Constantine', nameEn: 'Constantine', country: 'DZ', aliases: ['قسنطينة', 'qacentina'] },
  { id: 'dz-annaba', name: 'Annaba', nameAr: 'عنابة', nameFr: 'Annaba', nameEn: 'Annaba', country: 'DZ', aliases: ['عنابة', 'anaba'] },
  { id: 'dz-setif', name: 'Sétif', nameAr: 'سطيف', nameFr: 'Sétif', nameEn: 'Setif', country: 'DZ', aliases: ['سطيف', 'setif'] },
  { id: 'dz-batna', name: 'Batna', nameAr: 'باتنة', nameFr: 'Batna', nameEn: 'Batna', country: 'DZ', aliases: ['باتنة', 'batna'] },

  // Égypte
  { id: 'eg-cairo', name: 'Le Caire', nameAr: 'القاهرة', nameFr: 'Le Caire', nameEn: 'Cairo', country: 'EG', aliases: ['القاهرة', 'cairo', 'le caire'] },
  { id: 'eg-alexandria', name: 'Alexandrie', nameAr: 'الإسكندرية', nameFr: 'Alexandrie', nameEn: 'Alexandria', country: 'EG', aliases: ['الاسكندرية', 'alexandria', 'alexandrie'] },
]

/** Postes frontières utilisés pour les trajets internationaux. */
export const BORDER_CROSSINGS: Record<string, string> = {
  'TN-LY': 'Poste frontière de Ras Ajdir (رأس جدير)',
  'LY-TN': 'Poste frontière de Ras Ajdir (رأس جدير)',
  'TN-DZ': 'Poste frontière de Bouchebka',
  'DZ-TN': 'Poste frontière de Bouchebka',
  'DZ-LY': 'Poste frontière de Debdeb',
  'LY-DZ': 'Poste frontière de Debdeb',
  'LY-EG': 'Poste frontière de Musaid / Salum (منفذ السلوم)',
  'EG-LY': 'Poste frontière de Salum / Musaid (منفذ السلوم)',
}

export function normalize(value: string): string {
  if (!value) return ''
  return value
    .toLowerCase()
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .replace(/[\u064B-\u0652\u0640]/g, '')
    .replace(/[إأآٱء]/g, 'ا')
    .replace(/ة/g, 'ه')
    .replace(/ى/g, 'ي')
    .replace(/[^a-z0-9\u0600-\u06FF\s]/g, ' ')
    .replace(/\s+/g, ' ')
    .trim()
}

export function getCountryFlag(code: CountryCode): string {
  switch (code) {
    case 'TN': return '🇹🇳'
    case 'LY': return '🇱🇾'
    case 'DZ': return '🇩🇿'
    case 'EG': return '🇪🇬'
    default: return '📍'
  }
}

export function getCountry(code: CountryCode): Country {
  return COUNTRIES.find((country) => country.code === code) ?? COUNTRIES[0]
}

export function getCountryLocalizedName(code: CountryCode, lang: Language = 'fr'): string {
  return getCountryName(code, lang)
}

export function getCountryName(code: CountryCode, lang: Language = 'fr'): string {
  if (lang === 'ar') {
    switch (code) {
      case 'TN': return 'تونس'
      case 'LY': return 'ليبيا'
      case 'DZ': return 'الجزائر'
      case 'EG': return 'مصر'
    }
  } else if (lang === 'en') {
    switch (code) {
      case 'TN': return 'Tunisia'
      case 'LY': return 'Libya'
      case 'DZ': return 'Algeria'
      case 'EG': return 'Egypt'
    }
  }
  switch (code) {
    case 'TN': return 'Tunisie'
    case 'LY': return 'Libye'
    case 'DZ': return 'Algérie'
    case 'EG': return 'Égypte'
  }
}

export function formatCurrency(currency: string, lang: Language = 'fr'): string {
  if (!currency) return ''
  const c = currency.trim().toUpperCase()
  if (lang === 'ar') {
    if (c === 'DT' || c === 'TND') return 'د.ت'
    if (c === 'LD' || c === 'LYD') return 'د.ل'
    if (c === 'DA' || c === 'DZD') return 'د.ج'
    if (c === 'EGP') return 'ج.م'
    return c
  }
  if (lang === 'en') {
    if (c === 'DT') return 'TND'
    if (c === 'LD') return 'LYD'
    if (c === 'DA') return 'DZD'
    return c
  }
  if (c === 'TND') return 'DT'
  if (c === 'LD') return 'LYD'
  if (c === 'DZD') return 'DA'
  return c
}

export function localizeCityName(raw: string, lang: Language = 'fr'): string {
  if (!raw) return ''
  const trimmed = raw.trim()

  const found = findCityByName(trimmed)
  if (found) {
    if (lang === 'ar' && found.nameAr) return found.nameAr
    if (lang === 'en' && found.nameEn) return found.nameEn
    if (lang === 'fr' && found.nameFr) return found.nameFr
    if (lang === 'ar') {
      const arAlias = found.aliases.find((a) => /[\u0600-\u06FF]/.test(a))
      if (arAlias) return arAlias
    }
  }

  const hasArabic = /[\u0600-\u06FF]/.test(trimmed)
  const hasLatin = /[a-zA-Z]/.test(trimmed)

  if (hasArabic && hasLatin) {
    if (lang === 'ar') {
      let cleaned = trimmed
        .replace(/[a-zA-Z0-9+']+/g, '')
        .replace(/[,;/-]/g, ' ')
        .replace(/\s+/g, ' ')
        .trim()
      return cleaned || trimmed
    } else {
      let cleaned = trimmed
        .replace(/[\u0600-\u06FF\u064B-\u0652\u0640]+/g, '')
        .replace(/[,;،/-]/g, ' ')
        .replace(/\s+/g, ' ')
        .trim()
      return cleaned || trimmed
    }
  }

  if (hasArabic && !hasLatin && lang !== 'ar') {
    if (found) return lang === 'en' ? (found.nameEn || found.name) : (found.nameFr || found.name)
  }

  if (!hasArabic && hasLatin && lang === 'ar') {
    if (found) {
      return found.nameAr || found.aliases.find((a) => /[\u0600-\u06FF]/.test(a)) || trimmed
    }
  }

  return trimmed
}

export function localizePlaceName(rawPlace: string, lang: Language = 'fr'): string {
  if (!rawPlace) return ''
  const trimmed = rawPlace.trim()

  const parts = trimmed.split(/[,،]/).map((p) => p.trim()).filter(Boolean)
  if (parts.length === 0) return trimmed

  const localizedParts = parts.map((part) => {
    const lower = part.toLowerCase()
    if (lower === 'tunisie' || lower === 'tunisia' || lower === 'تونس' || lower === 'tn') {
      return getCountryName('TN', lang)
    }
    if (lower === 'libye' || lower === 'libya' || lower === 'ليبيا' || lower === 'ly') {
      return getCountryName('LY', lang)
    }
    if (lower === 'algérie' || lower === 'algeria' || lower === 'algerie' || lower === 'الجزائر' || lower === 'dz') {
      return getCountryName('DZ', lang)
    }
    if (lower === 'égypte' || lower === 'egypt' || lower === 'egypte' || lower === 'مصر' || lower === 'eg') {
      return getCountryName('EG', lang)
    }
    if (/^[A-Z0-9]{4,8}\+[A-Z0-9]{2,4}$/i.test(part)) {
      return part
    }
    return localizeCityName(part, lang)
  })

  const separator = lang === 'ar' ? '، ' : ', '
  return localizedParts.join(separator)
}

export function localizeDuration(durationLabel: string, lang: Language = 'fr'): string {
  if (!durationLabel) return ''
  const match = durationLabel.match(/(\d+)\s*h\s*(\d*)/i)
  if (!match) return durationLabel
  const hours = parseInt(match[1], 10)
  const mins = match[2] ? parseInt(match[2], 10) : 0

  if (lang === 'ar') {
    if (mins > 0) {
      return `${hours} س ${mins} د`
    }
    return `${hours} ساعات`
  }
  if (lang === 'en') {
    if (mins > 0) {
      return `${hours}h ${mins}m`
    }
    return `${hours}h`
  }
  return mins > 0 ? `${hours}h${String(mins).padStart(2, '0')}` : `${hours}h00`
}

export function getCitiesByCountry(code: CountryCode): City[] {
  return CITIES.filter((city) => city.country === code)
}

export function findCityById(id: string): City | null {
  return CITIES.find((city) => city.id === id) ?? null
}

export function findCityByName(name: string): City | null {
  const term = normalize(name)
  if (!term) return null
  for (const city of CITIES) {
    const list = [city.name, ...(city.nameAr ? [city.nameAr] : []), ...(city.nameFr ? [city.nameFr] : []), ...(city.nameEn ? [city.nameEn] : []), ...city.aliases].map(normalize)
    if (list.some((alias) => alias.includes(term) || term.includes(alias))) {
      return city
    }
  }
  return null
}

export function searchCities(query: string, limit = 8): City[] {
  const term = normalize(query)
  if (!term) return []
  const scored = CITIES.map((city) => {
    const haystack = [city.name, ...(city.nameAr ? [city.nameAr] : []), ...(city.nameFr ? [city.nameFr] : []), ...(city.nameEn ? [city.nameEn] : []), ...city.aliases].map(normalize)
    const startsWith = haystack.some((entry) => entry.startsWith(term))
    const includes = haystack.some((entry) => entry.includes(term))
    if (startsWith) return { city, score: 0 }
    if (includes) return { city, score: 1 }
    return { city, score: 2 }
  }).filter((entry) => entry.score < 2)
  return scored.sort((a, b) => a.score - b.score).slice(0, limit).map((entry) => entry.city)
}

export function cityLabel(city: City, lang: Language = 'fr'): string {
  if (!city) return ''
  const cityName = localizeCityName(city.name, lang)
  if (!city.country) return cityName
  const countryName = getCountryName(city.country, lang)
  const sep = lang === 'ar' ? '، ' : ', '
  return `${cityName}${sep}${countryName}`
}

export function cityShortLabel(city: City, lang: Language = 'fr'): string {
  if (!city) return ''
  return localizeCityName(city.name, lang)
}

export function localizeTransportMode(mode: string, lang: Language = 'fr'): string {
  const labels: Record<string, Record<string, string>> = {
    bus: { fr: 'Bus', ar: 'حافلة', en: 'Bus' },
    shared_taxi: { fr: 'Louage', ar: 'لواج', en: 'Shared Taxi' },
    train: { fr: 'Train', ar: 'قطار', en: 'Train' },
    plane: { fr: 'Avion', ar: 'طيران', en: 'Flight' },
    ferry: { fr: 'Ferry', ar: 'عبّارة', en: 'Ferry' },
    other: { fr: 'Autre', ar: 'أخرى', en: 'Other' },
  }
  return labels[mode]?.[lang] ?? mode
}
