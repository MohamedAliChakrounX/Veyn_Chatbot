import React, { useEffect, useMemo, useState } from 'react'
import { AnimatePresence, motion } from 'framer-motion'
import { ArrowRightIcon, CalendarIcon, ChevronDownIcon, ClockIcon, MapPinnedIcon } from 'lucide-react'
import { formatCurrency, localizeCityName, localizeDuration, localizeTransportMode } from '../../data/locations'
import { TRANSPORT_OPTIONS } from '../../data/options'
import { useTrip } from '../../contexts/TripContext'
import { useLanguage } from '../../contexts/LanguageContext'
import { dateLabel } from '../../utils/trip'
import type { TripResult } from '../../types/trip'
import { StopsTimeline } from './StopsTimeline'

export interface TripGroup {
  key: string
  trips: TripResult[]
}

/**
 * Regroupe les trajets qui partagent exactement la même combinaison de points d'arrêt
 * (même origine, mêmes étapes intermédiaires, même destination).
 */
export function groupTripsByStops(results: TripResult[]): TripGroup[] {
  const groupsMap = new Map<string, TripResult[]>()

  for (const trip of results) {
    let key = `${trip.mode}::`
    if (trip.stops && trip.stops.length > 0) {
      key += trip.stops.map((s) => s.name.trim().toLowerCase()).join(' > ')
    } else {
      key += `${trip.operator}::${trip.departure}::${trip.arrival}`
    }

    const existing = groupsMap.get(key)
    if (existing) {
      existing.push(trip)
    } else {
      groupsMap.set(key, [trip])
    }
  }

  return Array.from(groupsMap.entries()).map(([key, trips]) => ({
    key,
    trips,
  }))
}

export interface ResultCardProps {
  /** Trajet individuel (pour compatibilité ascendante) */
  result?: TripResult
  /** Liste complète des trajets partageant les mêmes points d'arrêt */
  trips?: TripResult[]
  featured?: boolean
  onBook: (result: TripResult) => void
}

export function ResultCard({ result, trips: rawTrips, featured, onBook }: ResultCardProps) {
  const { trip } = useTrip()
  const { t, language, isRTL } = useLanguage()
  const [stopsOpen, setStopsOpen] = useState(false)

  // Normalisation de la liste des trajets regroupés
  const allTrips = useMemo(() => {
    if (rawTrips && rawTrips.length > 0) return rawTrips
    if (result) return [result]
    return []
  }, [rawTrips, result])

  // Extraction et tri des dates uniques disponibles pour ce trajet (avec horizon de 5 jours si peu de dates)
  const availableDates = useMemo(() => {
    const datesSet = new Set<string>()
    for (const item of allTrips) {
      const d = item.date || trip.date
      if (d) datesSet.add(d)
    }
    const result = Array.from(datesSet)
    if (result.length < 2) {
      let baseDate = new Date()
      if (result.length > 0) {
        try {
          const parts = result[0].split('-')
          if (parts.length === 3) {
            baseDate = new Date(parseInt(parts[0], 10), parseInt(parts[1], 10) - 1, parseInt(parts[2], 10))
          }
        } catch {}
      }
      for (let i = 0; i < 5; i++) {
        const nextDay = new Date(baseDate)
        nextDay.setDate(baseDate.getDate() + i)
        const yyyy = nextDay.getFullYear()
        const mm = String(nextDay.getMonth() + 1).padStart(2, '0')
        const dd = String(nextDay.getDate()).padStart(2, '0')
        datesSet.add(`${yyyy}-${mm}-${dd}`)
      }
    }
    return Array.from(datesSet).sort((a, b) => a.localeCompare(b))
  }, [allTrips, trip.date])

  // Date sélectionnée : priorité à la date du contexte si elle existe dans les dates disponibles
  const [selectedDate, setSelectedDate] = useState<string>(() => {
    if (trip.date && availableDates.includes(trip.date)) {
      return trip.date
    }
    return availableDates[0] || trip.date || ''
  })

  // Synchronisation si la liste des dates disponibles change
  useEffect(() => {
    if (availableDates.length > 0 && !availableDates.includes(selectedDate)) {
      if (trip.date && availableDates.includes(trip.date)) {
        setSelectedDate(trip.date)
      } else {
        setSelectedDate(availableDates[0])
      }
    }
  }, [availableDates, selectedDate, trip.date])

  // Filtrage des trajets correspondant à la date sélectionnée (ou projection sur la date choisie)
  const tripsForDate = useMemo(() => {
    if (!selectedDate) return allTrips
    const filtered = allTrips.filter((item) => (item.date || trip.date) === selectedDate)
    const list = filtered.length > 0 ? filtered : allTrips.map((t) => ({ ...t, date: selectedDate }))
    return [...list].sort((a, b) => a.departure.localeCompare(b.departure))
  }, [allTrips, selectedDate, trip.date])

  // Horaire / Trajet sélectionné
  const [selectedTripId, setSelectedTripId] = useState<string>(() => tripsForDate[0]?.id || '')

  // Mise à jour de l'horaire sélectionné lors d'un changement de date
  useEffect(() => {
    if (tripsForDate.length > 0) {
      const exists = tripsForDate.some((item) => item.id === selectedTripId)
      if (!exists) {
        setSelectedTripId(tripsForDate[0].id)
      }
    }
  }, [tripsForDate, selectedTripId])

  // Trajet actif affiché
  const currentTrip = useMemo(() => {
    return tripsForDate.find((item) => item.id === selectedTripId) || tripsForDate[0] || allTrips[0]
  }, [tripsForDate, selectedTripId, allTrips])

  const badgeText = useMemo(() => {
    if (!currentTrip?.badge) return null
    const lower = currentTrip.badge.toLowerCase()
    if (lower.includes('meilleur tarif') || lower.includes('best') || lower.includes('أفضل')) {
      return t.results.bestRateReal
    }
    return currentTrip.badge
  }, [currentTrip?.badge, t.results.bestRateReal])

  if (!currentTrip) return null

  const option = TRANSPORT_OPTIONS.find((entry) => entry.id === currentTrip.mode)
  const Icon = option?.icon
  const stops = currentTrip.stops ?? []
  const intermediate = stops.filter((stop) => stop.kind === 'stop' || stop.kind === 'border')

  const originName = localizeCityName(stops[0]?.name || trip.origin?.name || t.trip.departure, language)
  const destName = localizeCityName(stops[stops.length - 1]?.name || trip.destination?.name || t.trip.arrival, language)

  const formattedSelectedDate = dateLabel(selectedDate, language) || selectedDate
  const arrowSymbol = isRTL ? '←' : '→'

  return (
    <article
      className={`relative flex h-full flex-col rounded-xl border bg-surface p-4 shadow-card transition-all duration-150 ${
        featured ? 'border-accent-border shadow-md' : 'border-line'
      }`}
    >
      {/* En-tête : Badge éventuel & mode de transport */}
      <div className="mb-2.5 flex flex-wrap items-center justify-between gap-2">
        {badgeText ? (
          <span
            className={`inline-flex items-center rounded-full px-2.5 py-0.5 text-[10px] font-bold uppercase tracking-wider ${
              featured ? 'bg-accent text-white' : 'bg-surface-sunken text-ink-muted'
            }`}
          >
            {badgeText}
          </span>
        ) : (
          <span />
        )}

        <div className="flex items-center gap-1.5 text-xs text-ink-muted">
          {Icon ? <Icon className="h-3.5 w-3.5 text-accent" aria-hidden="true" /> : null}
          <span className="font-medium text-ink-soft">{localizeTransportMode(currentTrip.mode, language)}</span>
          <span aria-hidden="true">·</span>
          <span>{currentTrip.transfers === 0 ? t.results.direct : `${currentTrip.transfers} ${t.results.transfersCount}`}</span>
          <span aria-hidden="true">·</span>
          <span className="tabular-nums font-medium">{t.results.durationPrefix} {localizeDuration(currentTrip.durationLabel, language)}</span>
        </div>
      </div>

      {/* Ligne principale du trajet : Origine → Destination & Prix */}
      <div className="mb-3 flex flex-wrap items-baseline justify-between gap-x-3 gap-y-1">
        <div className="flex items-center gap-1.5">
          <p className="text-base font-bold text-ink">
            {originName} <span className="font-normal text-ink-faint">{arrowSymbol}</span> {destName}
          </p>
        </div>
        <p className={`text-xl font-extrabold tabular-nums ${featured ? 'text-accent' : 'text-ink'}`}>
          {currentTrip.price} {formatCurrency(currentTrip.currency, language)}
        </p>
      </div>

      {/* 1. Sélection de la date (si plusieurs dates sont disponibles) */}
      {availableDates.length > 1 ? (
        <div className="mb-3 rounded-lg border border-line/70 bg-surface-sunken/40 p-2.5">
          <div className="mb-2 flex items-center justify-between">
            <span className="flex items-center gap-1.5 text-xs font-semibold text-ink">
              <CalendarIcon className="h-3.5 w-3.5 text-accent" aria-hidden="true" />
              <span>{t.results.availableDates}</span>
            </span>
            <span className="text-[11px] text-ink-muted">
              {availableDates.length} {t.results.datesCount}
            </span>
          </div>
          <div className="flex flex-wrap gap-1.5">
            {availableDates.map((dateStr) => {
              const isSelected = dateStr === selectedDate
              const label = dateLabel(dateStr, language) || dateStr
              return (
                <button
                  key={dateStr}
                  type="button"
                  onClick={() => setSelectedDate(dateStr)}
                  className={`rounded-lg px-2.5 py-1 text-xs font-medium capitalize transition-all duration-150 ${
                    isSelected
                      ? 'bg-accent text-white shadow-xs font-semibold ring-2 ring-accent/30'
                      : 'bg-surface text-ink-muted hover:bg-surface-elevated hover:text-ink border border-line'
                  }`}
                >
                  {label}
                </button>
              )
            })}
          </div>
        </div>
      ) : formattedSelectedDate ? (
        <div className="mb-3 flex items-center gap-2">
          <span className="flex items-center gap-1.5 rounded-md bg-surface-sunken px-2.5 py-1 text-xs font-semibold text-ink capitalize">
            <CalendarIcon className="h-3.5 w-3.5 text-accent" aria-hidden="true" />
            <span>{formattedSelectedDate}</span>
          </span>
        </div>
      ) : null}

      {/* 2. Horaires disponibles pour la date sélectionnée avec nombre de places restantes */}
      <div className="mb-3 rounded-lg border border-line bg-surface-sunken/60 p-2.5">
        <div className="mb-2 flex items-center justify-between">
          <span className="flex items-center gap-1.5 text-xs font-semibold text-ink">
            <ClockIcon className="h-3.5 w-3.5 text-accent" aria-hidden="true" />
            <span>
              {tripsForDate.length > 1 ? t.results.selectSchedule : t.results.availableSchedule}
            </span>
          </span>
          <span className="text-[11px] text-ink-muted">
            {tripsForDate.length} {t.results.departuresCount}
          </span>
        </div>

        <div
          className={`grid gap-2 ${
            tripsForDate.length > 1 ? 'grid-cols-1 sm:grid-cols-2' : 'grid-cols-1'
          }`}
        >
          {tripsForDate.map((item) => {
            const isSelected = item.id === currentTrip.id
            const seats = item.seatsLeft
            const isLowSeats = seats !== null && seats <= 3

            return (
              <button
                key={item.id}
                type="button"
                onClick={() => setSelectedTripId(item.id)}
                className={`flex items-center justify-between rounded-lg p-2.5 text-left transition-all duration-150 border ${
                  isSelected
                    ? 'border-accent bg-accent/10 ring-2 ring-accent/40 shadow-xs'
                    : 'border-line bg-surface hover:border-ink/20 hover:bg-surface-elevated'
                }`}
              >
                <div className="flex flex-col">
                  <span className="text-sm font-bold tabular-nums text-ink">
                    {item.departure} <span className="font-normal text-ink-faint">{arrowSymbol}</span> {item.arrival}
                  </span>
                  <span className="text-[11px] text-ink-muted">{t.results.durationPrefix} {localizeDuration(item.durationLabel, language)}</span>
                </div>

                <div className="text-right">
                  {seats !== null ? (
                    <span
                      className={`inline-flex items-center gap-1 rounded-full px-2 py-0.5 text-[10px] font-semibold ${
                        isLowSeats
                          ? 'bg-amber-100 text-amber-900 border border-amber-300'
                          : 'bg-emerald-50 text-emerald-800 border border-emerald-200'
                      }`}
                    >
                      <span
                        className={`h-1.5 w-1.5 rounded-full ${
                          isLowSeats ? 'bg-amber-500' : 'bg-emerald-500'
                        }`}
                        aria-hidden="true"
                      />
                      {seats} {t.results.seatsRemaining}
                    </span>
                  ) : (
                    <span className="text-[10px] text-ink-faint">{t.results.availableSeats}</span>
                  )}
                </div>
              </button>
            )
          })}
        </div>
      </div>

      {/* 3. Déroulant des points d'arrêt (affiché une seule fois pour ce trajet) */}
      {stops.length > 0 ? (
        <div className="mb-3 rounded-lg border border-line bg-surface-sunken/60">
          <button
            type="button"
            onClick={() => setStopsOpen((open) => !open)}
            aria-expanded={stopsOpen}
            className="flex w-full items-center gap-2 rounded-lg px-3 py-2 text-left transition-colors duration-150 ease-out hover:bg-surface-sunken/80"
          >
            <MapPinnedIcon className="h-4 w-4 shrink-0 text-ink-muted" aria-hidden="true" />
            <span className="text-xs font-semibold text-ink">
              {intermediate.length === 0
                ? t.results.directTrip
                : `${intermediate.length} ${t.results.stopPoints}`}
            </span>
            <ChevronDownIcon
              className={`ml-auto h-4 w-4 shrink-0 text-ink-faint transition-transform duration-150 ease-out ${
                stopsOpen ? 'rotate-180' : ''
              }`}
              aria-hidden="true"
            />
          </button>
          <AnimatePresence initial={false}>
            {stopsOpen ? (
              <motion.div
                initial={{ height: 0, opacity: 0 }}
                animate={{ height: 'auto', opacity: 1 }}
                exit={{ height: 0, opacity: 0 }}
                transition={{ duration: 0.18, ease: [0.23, 1, 0.32, 1] }}
                className="overflow-hidden"
              >
                <div className="veyn-scroll max-h-64 overflow-y-auto overscroll-contain border-t border-line px-3 py-3">
                  <StopsTimeline stops={currentTrip.stops} />
                </div>
              </motion.div>
            ) : null}
          </AnimatePresence>
        </div>
      ) : null}

      {/* 4. Pied de carte : Opérateur, récapitulatif & Bouton Réserver */}
      <div className="mt-auto flex flex-wrap items-center justify-between gap-3 border-t border-line/70 pt-3">
        <div className="flex flex-col text-xs">
          <p className="font-medium text-ink-soft">
            {t.results.operator} : <bdi className="font-semibold text-ink">{currentTrip.operator}</bdi>
          </p>
          <p className="text-[11px] text-ink-muted">
            {t.results.departureAt} <span className="tabular-nums">{currentTrip.departure}</span>
            {formattedSelectedDate ? ` · ${formattedSelectedDate}` : ''}
          </p>
        </div>

        <button
          type="button"
          onClick={() => onBook({ ...currentTrip, date: currentTrip.date || selectedDate })}
          className="ms-auto flex items-center gap-1.5 rounded-full bg-ink px-4 py-2 text-xs font-semibold text-white transition-all duration-150 ease-out hover:bg-ink-soft hover:shadow active:scale-[0.98]"
        >
          {t.results.bookNow}
          <ArrowRightIcon className={`h-3.5 w-3.5 ${isRTL ? 'rotate-180' : ''}`} aria-hidden="true" />
        </button>
      </div>
    </article>
  )
}

