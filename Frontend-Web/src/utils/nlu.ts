import { addDays, setMonth, setDate as setDayOfMonth, startOfToday, isBefore, addYears } from 'date-fns'
import { CITIES, normalize } from '../data/locations'
import { TRANSPORT_OPTIONS } from '../data/options'
import type { City, TransportMode, TripField, TripQuery } from '../types/trip'
import { toISODate } from './trip'

export interface Extraction {
  patch: Partial<TripQuery>
  recognized: TripField[]
}

const NUMBER_WORDS: Record<string, number> = {
  un: 1,
  une: 1,
  deux: 2,
  trois: 3,
  quatre: 4,
  cinq: 5,
  six: 6,
  sept: 7,
  huit: 8,
  neuf: 9,
  dix: 10,
  واحد: 1,
  اثنين: 2,
  اثنان: 2,
  ثلاثة: 3,
  اربعة: 4,
  خمسة: 5,
}

const MONTHS = [
  'janvier',
  'fevrier',
  'mars',
  'avril',
  'mai',
  'juin',
  'juillet',
  'aout',
  'septembre',
  'octobre',
  'novembre',
  'decembre',
]

function matchCity(text: string, from = 0): { city: City; index: number } | null {
  let best: { city: City; index: number } | null = null
  for (const city of CITIES) {
    for (const candidate of [city.name, ...city.aliases]) {
      const needle = normalize(candidate)
      const index = text.indexOf(needle, from)
      if (index === -1) continue
      const before = text[index - 1]
      const after = text[index + needle.length]
      const isolated = (before === undefined || before === ' ') && (after === undefined || after === ' ')
      if (!isolated) continue
      if (!best || index < best.index) best = { city, index }
    }
  }
  return best
}

function extractPlaces(text: string, currentTrip?: TripQuery): { origin?: City; destination?: City } {
  const result: { origin?: City; destination?: City } = {}
  const originMarkers = [' de ', ' depuis ', ' d ', ' partir de ', ' من ']
  const destinationMarkers = [' a ', ' vers ', ' jusqu a ', ' pour ', ' direction ', ' الى ', ' إلي ', ' نحو ']

  for (const marker of originMarkers) {
    const at = text.indexOf(marker)
    if (at === -1) continue
    const found = matchCity(text, at)
    if (found && found.index <= at + marker.length + 4) {
      result.origin = found.city
      break
    }
  }

  for (const marker of destinationMarkers) {
    let searchFrom = 0
    while (true) {
      const at = text.indexOf(marker, searchFrom)
      if (at === -1) break
      const found = matchCity(text, at)
      if (found && found.index <= at + marker.length + 4 && found.city.id !== result.origin?.id) {
        result.destination = found.city
        break
      }
      searchFrom = at + marker.length
    }
    if (result.destination) break
  }

  if (!result.origin && !result.destination) {
    const first = matchCity(text)
    if (first) {
      const second = matchCity(text, first.index + 1)
      if (second && second.city.id !== first.city.id) {
        result.origin = first.city
        result.destination = second.city
      } else {
        // Déduction intelligente si l'un des deux est déjà renseigné dans le panneau (+)
        if (currentTrip?.destination && !currentTrip?.origin && currentTrip.destination.id !== first.city.id) {
          result.origin = first.city
        } else if (currentTrip?.origin && !currentTrip?.destination && currentTrip.origin.id !== first.city.id) {
          result.destination = first.city
        } else if (currentTrip?.origin?.id === first.city.id) {
          result.origin = first.city
        } else if (currentTrip?.destination?.id === first.city.id) {
          result.destination = first.city
        } else {
          result.destination = first.city
        }
      }
    }
  }
  return result
}

function extractDate(text: string): string | null {
  const today = startOfToday()
  if (/\bapres demain\b|\baprès demain\b|\bبعد غد\b/.test(text)) return toISODate(addDays(today, 2))
  if (/\bdemain\b|\bغدا\b|\bغدوة\b/.test(text)) return toISODate(addDays(today, 1))
  if (/\baujourd hui\b|\bce soir\b|\bmaintenant\b|\bاليوم\b/.test(text)) return toISODate(today)
  if (/\bsemaine prochaine\b|\bالاسبوع القادم\b/.test(text)) return toISODate(addDays(today, 7))

  const isAfter = /\b(apres|après|بعد)\b/i.test(text)

  const written = text.match(/\b(\d{1,2})\s+(janvier|fevrier|mars|avril|mai|juin|juillet|aout|septembre|octobre|novembre|decembre)\b/)
  if (written) {
    const day = Number(written[1])
    const month = MONTHS.indexOf(written[2])
    let candidate = setDayOfMonth(setMonth(today, month), day)
    if (isBefore(candidate, today)) candidate = addYears(candidate, 1)
    if (isAfter) candidate = addDays(candidate, 1)
    return toISODate(candidate)
  }

  const numeric = text.match(/\b(\d{4})[\/\-](\d{1,2})[\/\-](\d{1,2})\b/)
  if (numeric) {
    let candidate = new Date(Number(numeric[1]), Number(numeric[2]) - 1, Number(numeric[3]))
    if (isAfter) candidate = addDays(candidate, 1)
    return toISODate(candidate)
  }

  const numericShort = text.match(/\b(\d{1,2})[\/\-](\d{1,2})(?:[\/\-](\d{2,4}))?\b/)
  if (numericShort) {
    const day = Number(numericShort[1])
    const month = Number(numericShort[2]) - 1
    let candidate = setDayOfMonth(setMonth(today, month), day)
    if (isBefore(candidate, today)) candidate = addYears(candidate, 1)
    if (isAfter) candidate = addDays(candidate, 1)
    return toISODate(candidate)
  }
  return null
}

function extractCount(text: string, keywords: string[]): number | null {
  for (const keyword of keywords) {
    const pattern = new RegExp(`(\\d{1,2}|${Object.keys(NUMBER_WORDS).join('|')})\\s+${keyword}`)
    const match = text.match(pattern)
    if (match) {
      const raw = match[1]
      const value = /\d/.test(raw) ? Number(raw) : NUMBER_WORDS[raw]
      if (Number.isFinite(value)) return value
    }
  }
  return null
}

function extractModes(text: string): TransportMode[] {
  const dictionary: Record<TransportMode, string[]> = {
    bus: ['bus', 'autocar', 'car', 'حافلة', 'باص'],
    train: ['train', 'sncft', 'قطار'],
    shared_taxi: ['taxi collectif', 'louage', 'taxi', 'لواج', 'سيارة اجرة'],
    plane: ['avion', 'vol', 'طائرة', 'طيارة'],
    ferry: ['ferry', 'bateau', 'traversee', 'باخرة', 'سفينة'],
    other: [],
  }
  const found: TransportMode[] = []
  for (const option of TRANSPORT_OPTIONS) {
    const words = dictionary[option.id]
    if (words && words.some((word) => text.includes(word))) found.push(option.id)
  }
  return found
}

export function extractFromText(text: string, currentTrip?: TripQuery): Extraction {
  const normalized = ` ${normalize(text)} `
  const patch: Partial<TripQuery> = {}
  const recognized: TripField[] = []

  const places = extractPlaces(normalized, currentTrip)
  if (places.origin) {
    patch.origin = places.origin
    recognized.push('origin')
  }
  if (places.destination) {
    patch.destination = places.destination
    recognized.push('destination')
  }

  const date = extractDate(normalized)
  if (date) {
    patch.date = date
    recognized.push('date')
  }

  if (/\bmatin\b|\bmatinee\b|\bصباح\b|\bصباحا\b/.test(normalized)) {
    patch.period = 'morning'
    recognized.push('time')
  } else if (/\bapres midi\b|\bmidi\b|\bمساء\b|\bظهرا\b/.test(normalized)) {
    patch.period = 'afternoon'
    recognized.push('time')
  } else if (/\bsoir\b|\bsoiree\b|\bnuit\b|\bليلا\b/.test(normalized)) {
    patch.period = 'evening'
    recognized.push('time')
  } else {
    const exact = normalized.match(/\b(\d{1,2})\s?(?:h|:)\s?(\d{2})?\b/)
    if (exact) {
      const hours = String(Math.min(23, Number(exact[1]))).padStart(2, '0')
      const minutes = (exact[2] ?? '00').padStart(2, '0')
      patch.period = 'exact'
      patch.exactTime = `${hours}:${minutes}`
      recognized.push('time')
    }
  }

  const adults = extractCount(normalized, ['adulte', 'adultes', 'personne', 'personnes', 'voyageur', 'voyageurs', 'شخص', 'بالغ', 'اشخاص', 'مسافرين'])
  const children = extractCount(normalized, ['enfant', 'enfants', 'bebe', 'bebes', 'طفل', 'اطفال', 'صغار'])
  const assisted = extractCount(normalized, ['handicape', 'handicapes', 'pmr', 'fauteuil', 'ذوي الاحتياجات'])

  if (adults !== null || children !== null || assisted !== null) {
    patch.travelers = {
      adults: adults ?? 0,
      children: children ?? 0,
      assisted: assisted ?? 0,
    }
    recognized.push('travelers')
  }

  const modes = extractModes(normalized)
  if (modes.length > 0) {
    patch.modes = modes
    recognized.push('modes')
  }

  const budget =
    normalized.match(/\b(?:budget|maximum|max|moins de|pas plus de)\D{0,12}(\d{2,5})\b/) ??
    normalized.match(/\b(\d{2,5})\s?(?:dt|dinars?|da|lyd|دينار)\b/)
  if (budget) {
    patch.budget = Number(budget[1])
    recognized.push('budget')
  }

  return { patch, recognized }
}
