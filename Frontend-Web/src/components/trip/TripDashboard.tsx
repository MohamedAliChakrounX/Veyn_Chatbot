import React, { useState } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import {
  SlidersHorizontal,
  ChevronUp,
  MapPin,
  Navigation,
  ArrowRight,
  ArrowLeft,
  Calendar,
  Clock,
  Car,
  Bus,
  Train,
  Plane,
  Ship,
  MoreHorizontal,
  Users,
  Search,
  RotateCcw,
  Sunrise,
  Sun,
  Moon,
  X,
  Route,
  Wallet,
} from 'lucide-react'
import { useTrip } from '../../contexts/TripContext'
import { useLanguage } from '../../contexts/LanguageContext'
import { getCountryFlag, getCountryName, localizeCityName } from '../../data/locations'
import { tripCurrency } from '../../utils/trip'
import type { City, TransportMode } from '../../types/trip'
import { LocationPickerModal } from './LocationPickerModal'
import {
  DateSelectionModal,
  TimeSelectionModal,
  TransportSelectionModal,
  TravelersSelectionModal,
  PrecisionsSelectionModal,
} from './QuickSelectionModals'

interface TripDashboardProps {
  onSearch: () => void
  onClose?: () => void
  isMenu?: boolean
}

export function TripDashboard({ onSearch, onClose, isMenu = false }: TripDashboardProps) {
  const {
    trip,
    patchTrip,
    resetTrip,
    swapCities,
    activePrecisionsCount,
  } = useTrip()
  const { t, language, isRTL } = useLanguage()

  const [isExpanded, setIsExpanded] = useState(true)

  // State for modals
  const [locationModalState, setLocationModalState] = useState<{
    open: boolean
    isOrigin: boolean
  }>({ open: false, isOrigin: true })
  const [dateModalOpen, setDateModalOpen] = useState(false)
  const [timeModalOpen, setTimeModalOpen] = useState(false)
  const [transportModalOpen, setTransportModalOpen] = useState(false)
  const [travelersModalOpen, setTravelersModalOpen] = useState(false)
  const [precisionsModalOpen, setPrecisionsModalOpen] = useState(false)

  const hasRoute = Boolean(trip.origin || trip.destination)
  const canSearch = Boolean(trip.origin && trip.destination)
  const isTripNotEmpty =
    Boolean(trip.origin) ||
    Boolean(trip.destination) ||
    Boolean(trip.date) ||
    (trip.dates && trip.dates.length > 0) ||
    Boolean(trip.period) ||
    (trip.periods && trip.periods.length > 0) ||
    Boolean(trip.exactTime) ||
    (trip.modes && trip.modes.length > 0) ||
    Boolean(trip.directOnly) ||
    (trip.budget !== null && trip.budget !== undefined) ||
    (trip.travelers && (trip.travelers.adults > 1 || trip.travelers.children > 0 || trip.travelers.assisted > 0))

  // Helper for formatting date box text
  const formatDateBoxText = (): string => {
    const dates = trip.dates && trip.dates.length > 0 ? trip.dates : trip.date ? [trip.date] : []
    if (dates.length === 0) return t.trip.date

    const formatSingle = (dateStr: string) => {
      try {
        const parts = dateStr.split('-')
        if (parts.length !== 3) return dateStr
        const parsed = new Date(parseInt(parts[0], 10), parseInt(parts[1], 10) - 1, parseInt(parts[2], 10))
        const now = new Date()
        const today = new Date(now.getFullYear(), now.getMonth(), now.getDate())
        const target = new Date(parsed.getFullYear(), parsed.getMonth(), parsed.getDate())
        const diff = Math.round((target.getTime() - today.getTime()) / (1000 * 60 * 60 * 24))

        if (diff === 0) return t.trip.today
        if (diff === 1) return t.trip.tomorrow

        const monthsFr = ['janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin', 'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.']
        const monthsEn = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']
        const monthsAr = ['يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو', 'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر']

        const m = parsed.getMonth()
        const d = parsed.getDate()
        if (language === 'ar') return `${d} ${monthsAr[m]}`
        if (language === 'en') return `${monthsEn[m]} ${d}`
        return `${d} ${monthsFr[m]}`
      } catch {
        return dateStr
      }
    }

    if (dates.length === 1) {
      return formatSingle(dates[0])
    }
    return dates.map(formatSingle).join(' • ')
  }

  const getModeIcon = (mode: TransportMode) => {
    switch (mode) {
      case 'shared_taxi':
        return Car
      case 'bus':
        return Bus
      case 'train':
        return Train
      case 'plane':
        return Plane
      case 'ferry':
        return Ship
      default:
        return MoreHorizontal
    }
  }

  const activePeriods = trip.periods && trip.periods.length > 0 ? trip.periods : trip.period ? [trip.period] : []
  const hasExactTime = Boolean(trip.exactTime && trip.exactTime.trim().length > 0)
  const isTimeActive = activePeriods.length > 0 || hasExactTime

  const hasTransport = trip.modes && trip.modes.length > 0

  const travelers = trip.travelers || { adults: 1, children: 0, assisted: 0 }
  const hasTravelersActive = travelers.adults > 1 || travelers.children > 0 || travelers.assisted > 0

  const hasPrecisionsActive = Boolean(trip.directOnly) || (trip.budget !== null && trip.budget !== undefined)
  const currency = tripCurrency(trip, language)

  const handleSearchClick = () => {
    onSearch()
    if (onClose) onClose()
  }

  // Formatting helpers for full label visibility in fields
  const formatTimeBoxContent = () => {
    if (!isTimeActive) {
      return (
        <div className="flex items-center gap-1.5 w-full min-w-0">
          <Clock className="h-3.5 w-3.5 shrink-0 text-ink-muted" />
          <span className="truncate text-xs font-semibold text-ink-muted">{t.trip.time}</span>
        </div>
      )
    }

    const labels: string[] = []
    if (activePeriods.includes('morning')) labels.push(t.trip.morning)
    if (activePeriods.includes('afternoon')) labels.push(t.trip.afternoon)
    if (activePeriods.includes('evening')) labels.push(t.trip.evening)
    if (hasExactTime) labels.push(trip.exactTime!)

    const fullText = labels.join(', ')

    return (
      <div className="flex items-center gap-1.5 w-full min-w-0" title={fullText}>
        <div className="flex items-center gap-1 shrink-0">
          {activePeriods.includes('morning') && <Sunrise className="h-3.5 w-3.5 text-accent" />}
          {activePeriods.includes('afternoon') && <Sun className="h-3.5 w-3.5 text-accent" />}
          {activePeriods.includes('evening') && <Moon className="h-3.5 w-3.5 text-accent" />}
          {hasExactTime && <Clock className="h-3.5 w-3.5 text-accent" />}
        </div>
        <span className="truncate text-xs font-bold text-accent">{fullText}</span>
      </div>
    )
  }

  const formatTransportContent = () => {
    if (!hasTransport) {
      return (
        <div className="flex items-center gap-1.5 w-full min-w-0">
          <Car className="h-3.5 w-3.5 shrink-0 text-ink-muted" />
          <span className="truncate text-xs font-semibold text-ink-muted">{t.tripDashboard.selectTransport}</span>
        </div>
      )
    }

    const transportLabels: Record<TransportMode, string> = {
      shared_taxi: t.trip.sharedTaxi,
      bus: t.trip.bus,
      train: t.trip.train,
      plane: t.trip.plane,
      ferry: t.trip.ferry,
      other: t.trip.other,
    }

    const names = trip.modes.map((m) => transportLabels[m] || m).join(', ')

    return (
      <div className="flex items-center gap-1.5 w-full min-w-0" title={names}>
        <div className="flex items-center gap-1 shrink-0">
          {trip.modes.slice(0, 2).map((mode) => {
            const Icon = getModeIcon(mode)
            return <Icon key={mode} className="h-3.5 w-3.5 text-accent" />
          })}
          {trip.modes.length > 2 && (
            <span className="text-[10px] font-bold text-accent">+{trip.modes.length - 2}</span>
          )}
        </div>
        <span className="truncate text-xs font-bold text-accent">{names}</span>
      </div>
    )
  }

  const formatTravelersContent = () => {
    const parts: string[] = []
    if (travelers.adults > 0) {
      parts.push(`${travelers.adults} ${travelers.adults > 1 ? t.travelers.adults : t.travelers.adult}`)
    }
    if (travelers.children > 0) {
      parts.push(`${travelers.children} ${travelers.children > 1 ? t.travelers.children : t.travelers.child}`)
    }
    if (travelers.assisted > 0) {
      parts.push(`${travelers.assisted} ${travelers.assisted > 1 ? t.travelers.assisteds : t.travelers.assisted}`)
    }

    const fullText = parts.join(', ')

    return (
      <div className="flex items-center gap-1.5 w-full min-w-0" title={fullText}>
        <Users className={`h-3.5 w-3.5 shrink-0 ${hasTravelersActive ? 'text-accent' : 'text-ink-muted'}`} />
        <span className={`truncate text-xs font-semibold ${hasTravelersActive ? 'font-bold text-accent' : 'text-ink-muted'}`}>
          {fullText || t.trip.travelers}
        </span>
      </div>
    )
  }

  const formatPrecisionsSummary = () => {
    if (!hasPrecisionsActive) {
      return t.tripDashboard.selectPrecisions
    }
    const parts: string[] = []
    if (trip.directOnly) {
      parts.push(t.tripDashboard.directOnly)
    }
    if (trip.budget !== null && trip.budget !== undefined) {
      parts.push(`≤ ${trip.budget} ${currency}`)
    }
    return parts.join(' • ')
  }

  const originCityName = trip.origin ? localizeCityName(trip.origin.name, language) : ''
  const destinationCityName = trip.destination ? localizeCityName(trip.destination.name, language) : ''

  const content = (
    <div className="space-y-2">
      {/* ROW 1: DEPARTURE ➔ DESTINATION */}
      <div className="flex items-center gap-1.5 sm:gap-2">
        {/* Origin Box */}
        <button
          type="button"
          onClick={() => setLocationModalState({ open: true, isOrigin: true })}
          className={`flex h-11 flex-1 items-center gap-2 rounded-xl border px-2.5 text-left transition min-w-0 ${
            trip.origin
              ? 'border-accent/40 bg-accent-soft/40 text-ink shadow-2xs'
              : 'border-line bg-surface-sunken text-ink-muted hover:border-line-strong'
          }`}
          title={trip.origin ? `${originCityName} (${getCountryName(trip.origin.country, language)})` : t.trip.departure}
        >
          <div className="flex h-7 w-7 shrink-0 items-center justify-center rounded-lg bg-surface text-accent shadow-xs border border-line">
            {trip.origin ? (
              <span className="text-sm">{getCountryFlag(trip.origin.country)}</span>
            ) : (
              <MapPin className="h-3.5 w-3.5" />
            )}
          </div>
          <div className="min-w-0 flex-1">
            <span className={`block truncate text-xs ${trip.origin ? 'font-bold text-ink' : 'font-semibold text-ink-muted'}`}>
              {trip.origin ? originCityName : t.trip.departure}
            </span>
          </div>
        </button>

        {/* Swap Button */}
        <button
          type="button"
          onClick={swapCities}
          disabled={!hasRoute}
          title={t.tripDashboard.swapCities}
          aria-label={t.tripDashboard.swapCities}
          className="flex h-8 w-8 shrink-0 items-center justify-center rounded-full border border-line bg-surface text-ink-muted hover:bg-surface-sunken hover:text-ink disabled:opacity-30 transition"
        >
          {isRTL ? <ArrowLeft className="h-3.5 w-3.5" /> : <ArrowRight className="h-3.5 w-3.5" />}
        </button>

        {/* Destination Box */}
        <button
          type="button"
          onClick={() => setLocationModalState({ open: true, isOrigin: false })}
          className={`flex h-11 flex-1 items-center gap-2 rounded-xl border px-2.5 text-left transition min-w-0 ${
            trip.destination
              ? 'border-accent/40 bg-accent-soft/40 text-ink shadow-2xs'
              : 'border-line bg-surface-sunken text-ink-muted hover:border-line-strong'
          }`}
          title={trip.destination ? `${destinationCityName} (${getCountryName(trip.destination.country, language)})` : t.trip.arrival}
        >
          <div className="flex h-7 w-7 shrink-0 items-center justify-center rounded-lg bg-surface text-accent shadow-xs border border-line">
            {trip.destination ? (
              <span className="text-sm">{getCountryFlag(trip.destination.country)}</span>
            ) : (
              <Navigation className="h-3.5 w-3.5" />
            )}
          </div>
          <div className="min-w-0 flex-1">
            <span className={`block truncate text-xs ${trip.destination ? 'font-bold text-ink' : 'font-semibold text-ink-muted'}`}>
              {trip.destination ? destinationCityName : t.trip.arrival}
            </span>
          </div>
        </button>
      </div>

      {/* ROW 2: DATE & TIME */}
      <div className="grid grid-cols-2 gap-2">
        {/* Date Box */}
        <button
          type="button"
          onClick={() => setDateModalOpen(true)}
          title={formatDateBoxText()}
          className={`flex h-10 items-center gap-2 rounded-xl border px-2.5 text-left transition min-w-0 ${
            trip.date || (trip.dates && trip.dates.length > 0)
              ? 'border-accent/40 bg-accent-soft/40 text-accent font-bold shadow-2xs'
              : 'border-line bg-surface-sunken text-ink-muted hover:border-line-strong'
          }`}
        >
          <Calendar className="h-3.5 w-3.5 shrink-0" />
          <span className="truncate text-xs font-semibold">{formatDateBoxText()}</span>
        </button>

        {/* Time Box */}
        <button
          type="button"
          onClick={() => setTimeModalOpen(true)}
          className={`flex h-10 items-center justify-center gap-1.5 rounded-xl border px-2.5 text-left transition min-w-0 ${
            isTimeActive
              ? 'border-accent/40 bg-accent-soft/40 text-accent font-bold shadow-2xs'
              : 'border-line bg-surface-sunken text-ink-muted hover:border-line-strong'
          }`}
        >
          {formatTimeBoxContent()}
        </button>
      </div>

      {/* ROW 3: TRANSPORTS & TRAVELERS */}
      <div className="grid grid-cols-2 gap-2">
        {/* Transport Box */}
        <button
          type="button"
          onClick={() => setTransportModalOpen(true)}
          className={`flex h-10 items-center justify-center gap-1.5 rounded-xl border px-2.5 text-left transition min-w-0 ${
            hasTransport
              ? 'border-accent/40 bg-accent-soft/40 text-accent font-bold shadow-2xs'
              : 'border-line bg-surface-sunken text-ink-muted hover:border-line-strong'
          }`}
        >
          {formatTransportContent()}
        </button>

        {/* Travelers Box */}
        <button
          type="button"
          onClick={() => setTravelersModalOpen(true)}
          className={`flex h-10 items-center justify-center gap-1.5 rounded-xl border px-2.5 text-left transition min-w-0 ${
            hasTravelersActive
              ? 'border-accent/40 bg-accent-soft/40 text-accent font-bold shadow-2xs'
              : 'border-line bg-surface-sunken text-ink-muted hover:border-line-strong'
          }`}
        >
          {formatTravelersContent()}
        </button>
      </div>

      {/* ROW 4: POINTS D'ARRÊT & PRÉCISIONS */}
      <button
        type="button"
        onClick={() => setPrecisionsModalOpen(true)}
        title={formatPrecisionsSummary()}
        className={`flex h-9 w-full items-center justify-between rounded-xl border px-3 text-left transition min-w-0 ${
          hasPrecisionsActive
            ? 'border-accent/40 bg-accent-soft/40 text-accent font-bold shadow-2xs'
            : 'border-line/70 bg-surface-sunken text-ink-muted hover:border-line-strong'
        }`}
      >
        <div className="flex items-center gap-2 min-w-0">
          <Route className={`h-3.5 w-3.5 shrink-0 ${hasPrecisionsActive ? 'text-accent' : 'text-ink-muted'}`} />
          <span className="truncate text-xs font-semibold">
            {formatPrecisionsSummary()}
          </span>
        </div>
        {hasPrecisionsActive && (
          <span className="rounded-full bg-accent px-2 py-0.5 text-[10px] font-bold text-white shadow-xs shrink-0">
            {trip.directOnly && trip.budget ? '2' : '1'}
          </span>
        )}
      </button>

      {/* ACTION ROW: SEARCH & RESET */}
      <div className="flex items-center gap-2 pt-1">
        <button
          type="button"
          onClick={handleSearchClick}
          disabled={!canSearch}
          className="flex h-9 flex-1 items-center justify-center gap-2 rounded-xl bg-accent px-4 text-xs font-bold text-white shadow-sm hover:bg-accent-hover disabled:opacity-40 disabled:cursor-not-allowed transition"
        >
          <Search className="h-3.5 w-3.5" />
          <span>{t.tripDashboard.searchTripsBtn}</span>
        </button>

        {isTripNotEmpty && (
          <button
            type="button"
            onClick={resetTrip}
            title={t.trip.reset}
            aria-label={t.trip.reset}
            className="flex h-9 w-9 shrink-0 items-center justify-center rounded-xl border border-line bg-surface-sunken text-ink-muted hover:bg-surface-elevated hover:text-ink transition"
          >
            <RotateCcw className="h-3.5 w-3.5" />
          </button>
        )}
      </div>
    </div>
  )

  return (
    <>
      {isMenu ? (
        /* MENU INTEGRATED IN COMPOSER */
        <div className="p-3 sm:p-4">
          {/* Menu Header with title, precisions count badge, reset & close button */}
          <div className="flex items-center justify-between border-b border-line pb-2.5 mb-3">
            <div className="flex items-center gap-2">
              <SlidersHorizontal className="h-3.5 w-3.5 text-accent" />
              <span className="text-xs font-bold text-ink">
                {t.tripDashboard.tripDashboard}
              </span>
              <span
                className={`rounded-full px-2 py-0.5 text-[11px] font-bold ${
                  activePrecisionsCount > 0
                    ? 'bg-accent text-white shadow-xs'
                    : 'bg-line-strong text-white'
                }`}
              >
                {activePrecisionsCount}
              </span>
            </div>

            <div className="flex items-center gap-1.5">
              {isTripNotEmpty && (
                <button
                  type="button"
                  onClick={resetTrip}
                  className="rounded-lg px-2 py-1 text-xs font-semibold text-accent hover:bg-accent-soft transition"
                >
                  {t.trip.reset}
                </button>
              )}
              {onClose && (
                <button
                  type="button"
                  onClick={onClose}
                  aria-label={t.common.close}
                  className="flex h-7 w-7 items-center justify-center rounded-full text-ink-muted hover:bg-surface-sunken hover:text-ink transition"
                >
                  <X className="h-4 w-4" />
                </button>
              )}
            </div>
          </div>

          {content}
        </div>
      ) : (
        /* STANDALONE DASHBOARD */
        <div className="mx-auto w-full max-w-3xl px-3 pt-2 pb-1 sm:px-6">
          <div className="overflow-hidden rounded-2xl border border-line bg-surface shadow-card transition-all">
            {/* Header Bar */}
            <button
              type="button"
              onClick={() => setIsExpanded(!isExpanded)}
              className="flex w-full items-center justify-between px-3.5 py-2.5 sm:px-4 text-left hover:bg-surface-sunken/40 transition"
            >
              <div className="flex items-center gap-2">
                <SlidersHorizontal className={`h-3.5 w-3.5 ${hasRoute ? 'text-ink' : 'text-ink-muted'}`} />
                <span className={`text-xs font-bold ${hasRoute ? 'text-ink' : 'text-ink-muted'}`}>
                  {t.tripDashboard.tripDashboard}
                </span>
              </div>

              <div className="flex items-center gap-2">
                <span
                  className={`rounded-full px-2 py-0.5 text-[11px] font-bold transition ${
                    activePrecisionsCount > 0
                      ? 'bg-accent text-white shadow-xs'
                      : 'bg-line-strong text-white'
                  }`}
                >
                  {activePrecisionsCount}
                </span>

                <motion.div
                  animate={{ rotate: isExpanded ? 0 : 180 }}
                  transition={{ duration: 0.2 }}
                  className="text-ink-muted"
                >
                  <ChevronUp className="h-4 w-4" />
                </motion.div>
              </div>
            </button>

            {/* Collapsible Body */}
            <AnimatePresence initial={false}>
              {isExpanded && (
                <motion.div
                  initial={{ height: 0, opacity: 0 }}
                  animate={{ height: 'auto', opacity: 1 }}
                  exit={{ height: 0, opacity: 0 }}
                  transition={{ duration: 0.24, ease: [0.23, 1, 0.32, 1] }}
                  className="overflow-hidden border-t border-line px-3 pb-3 pt-2.5 sm:px-4"
                >
                  {content}
                </motion.div>
              )}
            </AnimatePresence>
          </div>
        </div>
      )}

      {/* Modals Portalled to document.body */}
      <LocationPickerModal
        open={locationModalState.open}
        isOrigin={locationModalState.isOrigin}
        currentCity={locationModalState.isOrigin ? trip.origin : trip.destination}
        excludeCityId={locationModalState.isOrigin ? trip.destination?.id : trip.origin?.id}
        onSelectCity={(city: City) => {
          if (locationModalState.isOrigin) {
            patchTrip({ origin: city })
          } else {
            patchTrip({ destination: city })
          }
        }}
        onClose={() => setLocationModalState({ open: false, isOrigin: true })}
      />

      <DateSelectionModal open={dateModalOpen} onClose={() => setDateModalOpen(false)} />
      <TimeSelectionModal open={timeModalOpen} onClose={() => setTimeModalOpen(false)} />
      <TransportSelectionModal open={transportModalOpen} onClose={() => setTransportModalOpen(false)} />
      <TravelersSelectionModal open={travelersModalOpen} onClose={() => setTravelersModalOpen(false)} />
      <PrecisionsSelectionModal open={precisionsModalOpen} onClose={() => setPrecisionsModalOpen(false)} />
    </>
  )
}
