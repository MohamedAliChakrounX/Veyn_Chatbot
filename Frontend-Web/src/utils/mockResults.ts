import { BORDER_CROSSINGS, CITIES } from '../data/locations'
import { TRANSPORT_OPTIONS } from '../data/options'
import type { City, TransportMode, TripQuery, TripResult, TripStop } from '../types/trip'
import { travelersTotal, tripCurrency } from './trip'

const OPERATORS: Record<TransportMode, string[]> = {
  bus: ['SNTRI', 'Rawahel', 'Transtu', 'Sahara Voyages'],
  train: ['SNCFT', 'SNTF'],
  shared_taxi: ['Louage Bab Alioua', 'Station Sud'],
  plane: ['Tunisair', 'Air Algérie', 'Libyan Wings'],
  ferry: ['CTN', 'Grandi Navi'],
  other: ['Opérateur partenaire'],
}

const MODE_PROFILE: Record<TransportMode, { base: number; hours: number; maxStops: number }> = {
  bus: { base: 80, hours: 8, maxStops: 4 },
  train: { base: 64, hours: 7, maxStops: 3 },
  shared_taxi: { base: 95, hours: 6, maxStops: 2 },
  plane: { base: 420, hours: 2, maxStops: 1 },
  ferry: { base: 180, hours: 12, maxStops: 1 },
  other: { base: 110, hours: 8, maxStops: 2 },
}

function seedFrom(value: string): number {
  let seed = 0
  for (let index = 0; index < value.length; index += 1) {
    seed = (seed * 31 + value.charCodeAt(index)) % 9973
  }
  return seed
}

function periodStartHour(trip: TripQuery): number {
  if (trip.period === 'exact' && trip.exactTime) return Number(trip.exactTime.split(':')[0])
  if (trip.period === 'afternoon') return 13
  if (trip.period === 'evening') return 18
  return 6
}

function formatClock(totalMinutes: number): string {
  const normalized = ((Math.round(totalMinutes) % 1440) + 1440) % 1440
  const hours = Math.floor(normalized / 60)
  const minutes = normalized % 60
  return `${String(hours).padStart(2, '0')}:${String(minutes).padStart(2, '0')}`
}

function stopPlace(mode: TransportMode, cityName: string): string {
  const wording = TRANSPORT_OPTIONS.find((option) => option.id === mode)?.stopWording ?? 'Arrêt'
  return `${wording} de ${cityName}`
}

function intermediateCities(origin: City, destination: City, seed: number, count: number): City[] {
  if (count <= 0) return []
  const pool = CITIES.filter(
    (city) =>
      city.id !== origin.id &&
      city.id !== destination.id &&
      (city.country === origin.country || city.country === destination.country),
  )
  if (pool.length === 0) return []
  const picked: City[] = []
  for (let step = 0; step < count; step += 1) {
    const candidate = pool[(seed + step * 7 + step * step) % pool.length]
    if (!picked.some((city) => city.id === candidate.id)) picked.push(candidate)
  }
  return picked
}

function buildStops(
  trip: TripQuery,
  mode: TransportMode,
  departureMinutes: number,
  durationMinutes: number,
  seed: number,
  index: number,
): TripStop[] {
  const origin = trip.origin
  const destination = trip.destination
  if (!origin || !destination) return []
  const profile = MODE_PROFILE[mode] || MODE_PROFILE.bus
  const crossBorder = origin.country !== destination.country
  const intermediateCount = Math.min(profile.maxStops, ((seed + index) % profile.maxStops) + 1)
  const cities = intermediateCities(origin, destination, seed + index * 13, intermediateCount)
  const stops: TripStop[] = [
    {
      name: origin.name,
      place: stopPlace(mode, origin.name),
      time: formatClock(departureMinutes),
      kind: 'origin',
    },
  ]
  const middle: TripStop[] = cities.map((city, position) => {
    const ratio = (position + 1) / (cities.length + (crossBorder ? 2 : 1))
    return {
      name: city.name,
      place: stopPlace(mode, city.name),
      time: formatClock(departureMinutes + durationMinutes * ratio),
      kind: 'stop' as const,
      waitMinutes: 5 + ((seed + position * 5) % 4) * 5,
    }
  })
  if (crossBorder) {
    const key = `${origin.country}-${destination.country}`
    middle.push({
      name: BORDER_CROSSINGS[key] ?? 'Poste frontière',
      place: 'Contrôle des passeports et des bagages',
      time: formatClock(departureMinutes + durationMinutes * 0.72),
      kind: 'border',
      waitMinutes: 45 + ((seed + index) % 4) * 15,
    })
  }
  middle.sort((a, b) => a.time.localeCompare(b.time))
  stops.push(...middle)
  stops.push({
    name: destination.name,
    place: stopPlace(mode, destination.name),
    time: formatClock(departureMinutes + durationMinutes),
    kind: 'destination',
  })
  return stops
}

export function buildResults(trip: TripQuery): TripResult[] {
  const modes: TransportMode[] =
    trip.modes.length > 0 ? trip.modes : (['bus', 'shared_taxi'] as TransportMode[])
  const seed = seedFrom(`${trip.origin?.id ?? ''}${trip.destination?.id ?? ''}${trip.date ?? ''}`)
  const currency = tripCurrency(trip)
  const seats = Math.max(1, travelersTotal(trip))
  const startHour = periodStartHour(trip)
  const results: TripResult[] = modes.slice(0, 4).map((mode, index) => {
    const profile = MODE_PROFILE[mode] || MODE_PROFILE.bus
    const jitter = ((seed + index * 137) % 23) - 8
    const price = Math.max(24, profile.base + jitter * 3)
    const departureMinutes = (startHour + index) * 60 + ((seed + index * 17) % 4) * 15
    const durationHours = profile.hours + (index % 2)
    const durationExtra = ((seed + index * 7) % 4) * 15
    const totalDuration = durationHours * 60 + durationExtra
    const operators = OPERATORS[mode] || ['Veyn']
    const stops = buildStops(trip, mode, departureMinutes, totalDuration, seed, index)
    return {
      id: `${mode}-${index}`,
      departure: formatClock(departureMinutes),
      arrival: formatClock(departureMinutes + totalDuration),
      durationLabel: `${durationHours}h${durationExtra === 0 ? '' : String(durationExtra).padStart(2, '0')}`,
      mode,
      transfers: index === 0 ? 0 : index % 2,
      price,
      currency,
      operator: operators[(seed + index) % operators.length],
      seatsLeft: index === 0 ? Math.max(seats, 2 + (seed % 5)) : null,
      date: trip.date ?? undefined,
      stops,
    }
  })
  const filtered = trip.budget === null ? results : results.filter((result) => result.price <= trip.budget!)
  if (filtered.length === 0) return []
  const sorted = [...filtered].sort((a, b) => a.price - b.price)
  const cheapest = sorted[0]
  const fastest = [...filtered].sort((a, b) => a.durationLabel.localeCompare(b.durationLabel))[0]
  return sorted.map((result) => ({
    ...result,
    badge:
      result.id === cheapest.id
        ? 'Meilleur choix · moins cher'
        : result.id === fastest.id
          ? 'Le plus rapide'
          : undefined,
  }))
}

export function resultsSummary(
  count: number,
  currency: string,
  budget: number | null,
  lang: 'fr' | 'ar' | 'en' = 'fr',
): string {
  if (count === 0) return ''
  if (lang === 'ar') {
    const base = `${count} ${count > 2 && count <= 10 ? 'رحلات متوفرة' : 'رحلة متوفرة'}`
    const scope = budget === null ? `${base}.` : `${base} بأقل من ${budget} ${currency}.`
    return `${scope} تفاصيل الرحلات ومواعيد التوقف موضحة أدناه.`
  }
  if (lang === 'en') {
    const base = `${count} option${count > 1 ? 's' : ''} found`
    const scope = budget === null ? `${base}.` : `${base} under ${budget} ${currency}.`
    return `${scope} Each proposal details its scheduled stops and times.`
  }
  const base = `${count} solution${count > 1 ? 's' : ''} trouvée${count > 1 ? 's' : ''}`
  const scope = budget === null ? `${base}.` : `${base} sous ${budget} ${currency}.`
  return `${scope} Chaque proposition détaille ses points d’arrêt réels et horaires de passage.`
}
