import { addDays, format, isValid, parseISO, startOfToday } from 'date-fns'
import { ar, enUS, fr } from 'date-fns/locale'
import { cityShortLabel, getCountry } from '../data/locations'
import { PERIOD_OPTIONS, TRANSPORT_OPTIONS } from '../data/options'
import type { TripField, TripQuery } from '../types/trip'

export function emptyTrip(): TripQuery {
  return {
    origin: null,
    destination: null,
    travelers: { adults: 0, children: 0, assisted: 0 },
    date: null,
    dates: [],
    period: null,
    periods: [],
    exactTime: null,
    modes: [],
    budget: null,
  }
}

export function toISODate(date: Date): string {
  return format(date, 'yyyy-MM-dd')
}

export function parseISODate(value: string): Date | null {
  const parsed = parseISO(value)
  return isValid(parsed) ? parsed : null
}

export function travelersTotal(trip: TripQuery): number {
  const { adults, children, assisted } = trip.travelers
  return adults + children + assisted
}

export function travelersLabel(trip: TripQuery, lang: 'fr' | 'ar' | 'en' = 'fr'): string | null {
  const { adults, children, assisted } = trip.travelers
  const parts: string[] = []
  if (lang === 'ar') {
    if (adults > 0) parts.push(`${adults} بالغ`)
    if (children > 0) parts.push(`${children} طفل`)
    if (assisted > 0) parts.push(`${assisted} ذوو احتياجات`)
  } else if (lang === 'en') {
    if (adults > 0) parts.push(`${adults} adult${adults > 1 ? 's' : ''}`)
    if (children > 0) parts.push(`${children} child${children > 1 ? 'ren' : ''}`)
    if (assisted > 0) parts.push(`${assisted} PRM`)
  } else {
    if (adults > 0) parts.push(`${adults} adulte${adults > 1 ? 's' : ''}`)
    if (children > 0) parts.push(`${children} enfant${children > 1 ? 's' : ''}`)
    if (assisted > 0) parts.push(`${assisted} PMR`)
  }
  return parts.length > 0 ? parts.join(' · ') : null
}

import { formatCurrency, localizeTransportMode } from '../data/locations'
import type { Language } from '../i18n/translations'

export function dateLabel(iso: string | null, lang: Language = 'fr'): string | null {
  if (!iso) return null
  const date = parseISODate(iso)
  if (!date) return null
  const today = startOfToday()
  const dateLocale = lang === 'ar' ? ar : lang === 'en' ? enUS : fr
  if (toISODate(today) === iso) {
    return lang === 'ar' ? 'اليوم' : lang === 'en' ? 'Today' : "Aujourd'hui"
  }
  if (toISODate(addDays(today, 1)) === iso) {
    return lang === 'ar' ? 'غداً' : lang === 'en' ? 'Tomorrow' : 'Demain'
  }
  return format(date, lang === 'en' ? 'EEE, MMM d' : lang === 'ar' ? 'EEEE d MMMM' : 'EEE d MMM', { locale: dateLocale })
}

export function datesLabel(trip: TripQuery, lang: Language = 'fr'): string | null {
  const dates = (trip.dates && trip.dates.length > 0) ? trip.dates : (trip.date ? [trip.date] : [])
  if (dates.length === 0) return null
  if (dates.length === 1) return dateLabel(dates[0], lang)

  const orWord = lang === 'ar' ? ' أو ' : lang === 'en' ? ' or ' : ' ou '
  const comma = lang === 'ar' ? '، ' : ', '

  if (dates.length <= 3) {
    const formatted = dates.map((d) => dateLabel(d, lang) || d)
    if (formatted.length === 2) {
      return formatted.join(orWord)
    }
    return `${formatted.slice(0, -1).join(comma)}${orWord}${formatted[formatted.length - 1]}`
  }

  if (lang === 'ar') return `${dates.length} تواريخ محددة`
  if (lang === 'en') return `${dates.length} selected dates`
  return `${dates.length} dates sélectionnées`
}

export function timeLabel(trip: TripQuery, lang: Language = 'fr'): string | null {
  const periods = (trip.periods && trip.periods.length > 0) ? trip.periods : (trip.period ? [trip.period] : [])
  if (periods.length === 0 && !trip.exactTime) return null

  if (trip.period === 'exact' || (periods.includes('exact') && trip.exactTime)) {
    if (lang === 'ar') return trip.exactTime ? `عند ${trip.exactTime}` : 'وقت محدد'
    if (lang === 'en') return trip.exactTime ? `at ${trip.exactTime}` : 'Exact time'
    return trip.exactTime ? `à ${trip.exactTime}` : 'Heure précise'
  }

  const periodLabels: Record<string, { ar: string; fr: string; en: string }> = {
    morning: { ar: 'صباحاً', fr: 'Matin', en: 'Morning' },
    afternoon: { ar: 'ظهراً', fr: 'Après-midi', en: 'Afternoon' },
    evening: { ar: 'مساءً', fr: 'Soir', en: 'Evening' },
  }

  const validPeriods = periods.filter((p) => p !== 'exact' && periodLabels[p])
  if (validPeriods.length === 0) return null

  const orWord = lang === 'ar' ? ' أو ' : lang === 'en' ? ' or ' : ' ou '
  const labels = validPeriods.map((p) => periodLabels[p][lang] || periodLabels[p]['fr'])
  return labels.join(orWord)
}

export function modesLabel(trip: TripQuery, lang: Language = 'fr'): string | null {
  if (!trip.modes || trip.modes.length === 0) return null
  return trip.modes.map((mode) => localizeTransportMode(mode, lang)).join(' · ')
}

export function tripCurrency(trip: TripQuery, lang: Language = 'fr'): string {
  let curr = 'DT'
  if (trip.origin) curr = getCountry(trip.origin.country).currency
  else if (trip.destination) curr = getCountry(trip.destination.country).currency
  return formatCurrency(curr, lang)
}

export function budgetLabel(trip: TripQuery, lang: Language = 'fr'): string | null {
  if (trip.budget === null) return null
  const curr = tripCurrency(trip, lang)
  if (lang === 'ar') return `أقصى حد ${trip.budget} ${curr}`
  if (lang === 'en') return `max ${trip.budget} ${curr}`
  return `max ${trip.budget} ${curr}`
}

export function routeLabel(trip: TripQuery, lang: Language = 'fr'): string | null {
  const arrow = lang === 'ar' ? ' ← ' : ' → '
  if (trip.origin && trip.destination) {
    return `${cityShortLabel(trip.origin, lang)}${arrow}${cityShortLabel(trip.destination, lang)}`
  }
  if (trip.destination) return `${arrow}${cityShortLabel(trip.destination, lang)}`
  if (trip.origin) return `${cityShortLabel(trip.origin, lang)}${arrow}`
  return null
}

export interface TripChip {
  field: TripField
  label: string
}

export function tripChips(trip: TripQuery, lang: Language = 'fr'): TripChip[] {
  const chips: TripChip[] = []
  if (trip.origin) {
    const prefix = lang === 'ar' ? 'الانطلاق : ' : lang === 'en' ? 'From: ' : 'Départ : '
    chips.push({ field: 'origin', label: `${prefix}${cityShortLabel(trip.origin, lang)}` })
  }
  if (trip.destination) {
    const prefix = lang === 'ar' ? 'الوصول : ' : lang === 'en' ? 'To: ' : 'Arrivée : '
    chips.push({ field: 'destination', label: `${prefix}${cityShortLabel(trip.destination, lang)}` })
  }
  const dateText = datesLabel(trip, lang)
  if (dateText) {
    const dates = (trip.dates && trip.dates.length > 0) ? trip.dates : (trip.date ? [trip.date] : [])
    const prefix = dates.length > 1
      ? (lang === 'ar' ? 'التواريخ : ' : lang === 'en' ? 'Dates: ' : 'Dates : ')
      : (lang === 'ar' ? 'التاريخ : ' : lang === 'en' ? 'Date: ' : 'Date : ')
    chips.push({ field: 'date', label: `${prefix}${dateText}` })
  }
  const time = timeLabel(trip, lang)
  if (time) {
    const periods = (trip.periods && trip.periods.length > 0) ? trip.periods : (trip.period ? [trip.period] : [])
    const prefix = periods.length > 1
      ? (lang === 'ar' ? 'الفترات : ' : lang === 'en' ? 'Periods: ' : 'Périodes : ')
      : (lang === 'ar' ? 'الوقت : ' : lang === 'en' ? 'Time: ' : 'Horaire : ')
    chips.push({ field: 'time', label: `${prefix}${time}` })
  }
  const travelers = travelersLabel(trip, lang)
  if (travelers) {
    const prefix = lang === 'ar' ? 'المسافرون : ' : lang === 'en' ? 'Travelers: ' : 'Voyageurs : '
    chips.push({ field: 'travelers', label: `${prefix}${travelers}` })
  }
  const modes = modesLabel(trip, lang)
  if (modes) {
    const prefix = lang === 'ar' ? 'الوسيلة : ' : lang === 'en' ? 'Mode: ' : 'Mode : '
    chips.push({ field: 'modes', label: `${prefix}${modes}` })
  }
  const budget = budgetLabel(trip, lang)
  if (budget) {
    const prefix = lang === 'ar' ? 'الميزانية : ' : lang === 'en' ? 'Budget: ' : 'Budget : '
    chips.push({ field: 'budget', label: `${prefix}${budget}` })
  }
  return chips
}

export function clearField(trip: TripQuery, field: TripField): TripQuery {
  switch (field) {
    case 'origin':
      return { ...trip, origin: null }
    case 'destination':
      return { ...trip, destination: null }
    case 'travelers':
      return { ...trip, travelers: { adults: 0, children: 0, assisted: 0 } }
    case 'date':
      return { ...trip, date: null, dates: [] }
    case 'time':
      return { ...trip, period: null, periods: [], exactTime: null }
    case 'modes':
      return { ...trip, modes: [] }
    case 'budget':
      return { ...trip, budget: null }
    default:
      return trip
  }
}

export function isFieldFilled(trip: TripQuery, field: TripField): boolean {
  switch (field) {
    case 'origin':
      return trip.origin !== null
    case 'destination':
      return trip.destination !== null
    case 'travelers':
      return travelersTotal(trip) > 0
    case 'date':
      return Boolean(trip.date || (trip.dates && trip.dates.length > 0))
    case 'time':
      return Boolean(trip.period || (trip.periods && trip.periods.length > 0) || trip.exactTime)
    case 'modes':
      return trip.modes.length > 0
    case 'budget':
      return trip.budget !== null
    default:
      return false
  }
}

export function isTripEmpty(trip: TripQuery): boolean {
  return (
    ['origin', 'destination', 'travelers', 'date', 'time', 'modes', 'budget'] as TripField[]
  ).every((field) => !isFieldFilled(trip, field))
}
