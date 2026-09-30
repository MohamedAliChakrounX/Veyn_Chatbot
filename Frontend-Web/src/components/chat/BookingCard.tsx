import React, { useState } from 'react'
import { AnimatePresence, motion } from 'framer-motion'
import { CalendarIcon, CheckCircle2Icon, ChevronDownIcon, MapPinnedIcon, UsersIcon } from 'lucide-react'
import { TRANSPORT_OPTIONS } from '../../data/options'
import { dateLabel } from '../../utils/trip'
import type { BookingSummary, Travelers } from '../../types/trip'
import { StopsTimeline } from './StopsTimeline'
import { useLanguage } from '../../contexts/LanguageContext'

function formatTravelersBreakdown(
  t: import('../../i18n/translations').TranslationSchema,
  detail?: Travelers,
  label?: string,
  totalCount?: number,
): string {
  if (label) {
    if (totalCount && totalCount > 1) {
      return `${totalCount} ${t.booking.summaryTravelers.toLowerCase()} (${label})`
    }
    return label
  }

  if (detail) {
    const parts: string[] = []
    if (detail.adults > 0)
      parts.push(`${detail.adults} ${detail.adults > 1 ? t.travelers.adults : t.travelers.adult}`)
    if (detail.children > 0)
      parts.push(`${detail.children} ${detail.children > 1 ? t.travelers.children : t.travelers.child}`)
    if (detail.assisted > 0)
      parts.push(`${detail.assisted} ${detail.assisted > 1 ? t.travelers.assisteds : t.travelers.assisted}`)
    const str = parts.join(', ')
    if (totalCount && totalCount > 1) {
      return `${totalCount} ${t.booking.summaryTravelers.toLowerCase()} (${str})`
    }
    return str || `${totalCount || 1} ${t.travelers.adult}`
  }

  return totalCount
    ? `${totalCount} ${totalCount > 1 ? t.travelers.adults : t.travelers.adult}`
    : t.travelers.defaultOne
}

export function BookingCard({ booking }: { booking: BookingSummary }) {
  const { t, language } = useLanguage()
  const [stopsOpen, setStopsOpen] = useState(false)
  const option = TRANSPORT_OPTIONS.find((entry) => entry.id === booking.result.mode)
  const formattedDate = dateLabel(booking.result.date ?? null, language) || booking.result.date || t.trip.today
  const travelersDisplay = formatTravelersBreakdown(
    t,
    booking.travelersDetail,
    booking.travelersLabel,
    booking.travelers,
  )

  const stops = booking.result.stops ?? []
  const intermediate = stops.filter((stop) => stop.kind === 'stop' || stop.kind === 'border')

  return (
    <article
      role="status"
      className="overflow-hidden rounded-2xl border border-emerald-200 bg-emerald-50/60 shadow-card"
    >
      {/* En-tête vert avec statut et prix total */}
      <header className="flex flex-wrap items-center gap-x-3 gap-y-1 border-b border-emerald-200 bg-emerald-600 px-4 py-3">
        <p className="flex items-center gap-2 text-[13px] font-semibold text-white">
          <CheckCircle2Icon className="h-4 w-4 shrink-0" aria-hidden="true" />
          {t.bookingCard.successHeader}
        </p>
        <p className="ml-auto text-sm font-bold tabular-nums text-white">
          {booking.total} {booking.currency}
        </p>
      </header>

      <div className="bg-surface p-4">
        {/* Ligne Trajet & Référence */}
        <div className="flex flex-wrap items-baseline justify-between gap-2">
          <h3 className="text-base font-bold text-ink">{booking.routeLabel}</h3>
          <span className="rounded-md bg-emerald-100 px-2 py-0.5 text-xs font-bold text-emerald-800">
            {t.bookingCard.refPrefix} {booking.reference}
          </span>
        </div>

        {/* Blocs Date et Voyageurs clairement mis en avant */}
        <div className="mt-3 grid grid-cols-1 gap-2 sm:grid-cols-2">
          {/* Date du voyage */}
          <div className="flex items-center gap-2.5 rounded-xl border border-line bg-surface-sunken/50 p-2.5">
            <div className="flex h-8 w-8 shrink-0 items-center justify-center rounded-lg bg-emerald-100 text-emerald-700">
              <CalendarIcon className="h-4 w-4" aria-hidden="true" />
            </div>
            <div className="min-w-0">
              <span className="block text-[10px] font-semibold uppercase tracking-wide text-ink-faint">
                {t.bookingCard.travelDate}
              </span>
              <span className="block text-xs font-bold capitalize text-ink">
                {formattedDate}
              </span>
            </div>
          </div>

          {/* Détail des voyageurs */}
          <div className="flex items-center gap-2.5 rounded-xl border border-line bg-surface-sunken/50 p-2.5">
            <div className="flex h-8 w-8 shrink-0 items-center justify-center rounded-lg bg-emerald-100 text-emerald-700">
              <UsersIcon className="h-4 w-4" aria-hidden="true" />
            </div>
            <div className="min-w-0">
              <span className="block text-[10px] font-semibold uppercase tracking-wide text-ink-faint">
                {t.bookingCard.travelers}
              </span>
              <span className="block truncate text-xs font-bold text-ink" title={travelersDisplay}>
                {travelersDisplay}
              </span>
            </div>
          </div>
        </div>

        {/* Détails du transport (Opérateur, mode, durée) */}
        <div className="mt-2.5 flex flex-wrap items-center gap-2 text-xs text-ink-muted">
          {option?.icon ? <option.icon className="h-3.5 w-3.5 text-emerald-600" aria-hidden="true" /> : null}
          <span className="font-medium text-ink-soft">{option?.label ?? booking.result.mode}</span>
          <span aria-hidden="true">·</span>
          <span>{booking.result.operator}</span>
          <span aria-hidden="true">·</span>
          <span className="tabular-nums">{t.bookingCard.durationPrefix} {booking.result.durationLabel}</span>
        </div>

        {/* Lieu et heure de montée */}
        <div className="mt-3 rounded-xl border border-emerald-200 bg-emerald-50/80 px-3 py-2 text-xs text-emerald-950">
          {t.bookingCard.boardingAt} <span className="font-bold">{booking.boardingStop.place}</span>{' '}
          {t.bookingCard.atTime}{' '}
          <span className="font-bold tabular-nums">{booking.boardingStop.time}</span>
        </div>

        {/* Mode de paiement utilisé */}
        {booking.paymentMethod || booking.cardType ? (
          <div className="mt-2 flex items-center justify-between rounded-lg bg-surface-sunken/60 px-3 py-1.5 text-[11px] text-ink-muted">
            <span className="font-medium">{t.bookingCard.paymentMethodLabel}</span>
            <span className="font-bold text-ink">
              {booking.cardType ? `${booking.cardType} •••• ${booking.cardLast4 || '****'}` : booking.paymentMethod}
            </span>
          </div>
        ) : null}

        {/* Points d'arrêt : s'affichent uniquement au clic sur la flèche */}
        {stops.length > 0 ? (
          <div className="mt-3 rounded-xl border border-line bg-surface-sunken/40">
            <button
              type="button"
              onClick={() => setStopsOpen((open) => !open)}
              aria-expanded={stopsOpen}
              className="flex w-full items-center gap-2 rounded-xl px-3.5 py-2.5 text-left transition-colors duration-150 ease-out hover:bg-surface-sunken/80"
            >
              <MapPinnedIcon className="h-4 w-4 shrink-0 text-emerald-600" aria-hidden="true" />
              <span className="text-xs font-semibold text-ink">
                {intermediate.length === 0
                  ? t.bookingCard.directTrip
                  : `${intermediate.length} ${t.bookingCard.stopsCount}`}
              </span>
              <span className="text-[11px] text-ink-muted">
                ({stops.length} {t.bookingCard.totalStops})
              </span>
              <ChevronDownIcon
                className={`ml-auto h-4 w-4 shrink-0 text-ink-faint transition-transform duration-150 ease-out ${
                  stopsOpen ? 'rotate-180 text-ink' : ''
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
                  <div className="border-t border-line px-3.5 py-3">
                    <StopsTimeline stops={stops} boardingName={booking.boardingStop.name} />
                  </div>
                </motion.div>
              ) : null}
            </AnimatePresence>
          </div>
        ) : null}
      </div>
    </article>
  )
}
