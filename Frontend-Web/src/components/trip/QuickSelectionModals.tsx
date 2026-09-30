import React, { useState, useEffect } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import {
  Calendar as CalendarIcon,
  Clock,
  Car,
  Bus,
  Train,
  Plane,
  Ship,
  MoreHorizontal,
  Users,
  User,
  Baby,
  Accessibility,
  Plus,
  Minus,
  X,
  ChevronLeft,
  ChevronRight,
  Sunrise,
  Sun,
  Moon,
  Check,
  SlidersHorizontal,
  Route,
  Wallet,
} from 'lucide-react'
import { useTrip } from '../../contexts/TripContext'
import { useLanguage } from '../../contexts/LanguageContext'
import { tripCurrency } from '../../utils/trip'
import { BUDGET_SUGGESTIONS } from '../../data/options'
import type { TimePeriod, TransportMode } from '../../types/trip'
import { ModalPortal } from '../common/ModalPortal'

interface ModalBaseProps {
  open: boolean
  onClose: () => void
}

// ─────────────────────────────────────────────────────────────────────────────
// 1. DATE SELECTION MODAL (MULTI-DATES CALENDAR)
// ─────────────────────────────────────────────────────────────────────────────

export function DateSelectionModal({ open, onClose }: ModalBaseProps) {
  const { trip, toggleDate, removeField } = useTrip()
  const { t, language, isRTL } = useLanguage()

  const [currentMonth, setCurrentMonth] = useState(() => {
    const d = new Date()
    return new Date(d.getFullYear(), d.getMonth(), 1)
  })

  useEffect(() => {
    if (open) {
      const handleKeyDown = (e: KeyboardEvent) => {
        if (e.key === 'Escape') onClose()
      }
      window.addEventListener('keydown', handleKeyDown)
      return () => window.removeEventListener('keydown', handleKeyDown)
    }
  }, [open, onClose])

  const now = new Date()
  const today = new Date(now.getFullYear(), now.getMonth(), now.getDate())

  const year = currentMonth.getFullYear()
  const month = currentMonth.getMonth()

  const firstDayOfMonth = new Date(year, month, 1)
  const lastDayOfMonth = new Date(year, month + 1, 0)
  const daysInMonth = lastDayOfMonth.getDate()

  // Weekday starts Monday (1) to Sunday (7) -> 0 to 6
  let firstWeekday = firstDayOfMonth.getDay() - 1
  if (firstWeekday < 0) firstWeekday = 6

  const monthNamesFr = ['Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin', 'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre']
  const monthNamesEn = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December']
  const monthNamesAr = ['يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو', 'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر']

  const monthTitle = language === 'ar'
    ? `${monthNamesAr[month]} ${year}`
    : language === 'en'
      ? `${monthNamesEn[month]} ${year}`
      : `${monthNamesFr[month]} ${year}`

  const weekdays = language === 'ar'
    ? ['إث', 'ثل', 'أر', 'خم', 'جم', 'سب', 'أح']
    : language === 'en'
      ? ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
      : ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim']

  const canGoPrevious = currentMonth > new Date(now.getFullYear(), now.getMonth(), 1)

  const selectedDates = trip.dates || (trip.date ? [trip.date] : [])

  const handlePrevMonth = () => {
    if (canGoPrevious) {
      setCurrentMonth(new Date(year, month - 1, 1))
    }
  }

  const handleNextMonth = () => {
    setCurrentMonth(new Date(year, month + 1, 1))
  }

  return (
    <ModalPortal>
      <AnimatePresence>
        {open && (
          <div
            className="fixed inset-0 z-[100] flex items-center justify-center p-3 sm:p-5"
            role="dialog"
            aria-modal="true"
          >
            {/* Backdrop */}
            <motion.div
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              onClick={onClose}
              className="absolute inset-0 bg-ink/40 backdrop-blur-xs"
            />

            {/* Modal Dialog */}
            <motion.div
              initial={{ opacity: 0, scale: 0.95, y: 12 }}
              animate={{ opacity: 1, scale: 1, y: 0 }}
              exit={{ opacity: 0, scale: 0.95, y: 12 }}
              transition={{ duration: 0.22, ease: [0.23, 1, 0.32, 1] }}
              className="relative z-10 flex max-h-[85vh] sm:max-h-[80vh] w-full max-w-sm sm:max-w-md flex-col overflow-hidden rounded-2xl border border-line bg-surface shadow-2xl"
            >
              {/* Header */}
              <div className="flex shrink-0 items-center justify-between border-b border-line px-4 py-3 sm:px-5">
                <div className="flex items-center gap-2.5">
                  <div className="flex h-8 w-8 items-center justify-center rounded-full bg-accent-soft text-accent">
                    <CalendarIcon className="h-4 w-4" />
                  </div>
                  <h3 className="text-sm font-bold text-ink">{t.tripDashboard.selectDate}</h3>
                </div>
                <div className="flex items-center gap-1.5">
                  {selectedDates.length > 0 && (
                    <button
                      type="button"
                      onClick={() => removeField('date')}
                      className="rounded-lg px-2 py-1 text-xs font-semibold text-accent hover:bg-accent-soft transition"
                    >
                      {t.tripDashboard.clearFilters}
                    </button>
                  )}
                  <button
                    type="button"
                    onClick={onClose}
                    aria-label={t.common.close}
                    className="flex h-7 w-7 items-center justify-center rounded-full text-ink-muted transition hover:bg-surface-sunken hover:text-ink"
                  >
                    <X className="h-4 w-4" />
                  </button>
                </div>
              </div>

              {/* Scrollable Body */}
              <div className="veyn-scroll flex-1 min-h-0 overflow-y-auto p-4 sm:p-5 overscroll-contain pb-6">
                {/* Month Navigation */}
                <div className="flex items-center justify-between rounded-xl bg-surface-sunken px-3 py-2">
                  <button
                    type="button"
                    onClick={handlePrevMonth}
                    disabled={!canGoPrevious}
                    aria-label="Previous month"
                    className="flex h-8 w-8 items-center justify-center rounded-lg text-ink-soft hover:bg-surface hover:text-ink disabled:opacity-30 transition"
                  >
                    {isRTL ? <ChevronRight className="h-4 w-4" /> : <ChevronLeft className="h-4 w-4" />}
                  </button>
                  <span className="text-xs font-bold text-ink">{monthTitle}</span>
                  <button
                    type="button"
                    onClick={handleNextMonth}
                    aria-label="Next month"
                    className="flex h-8 w-8 items-center justify-center rounded-lg text-ink-soft hover:bg-surface hover:text-ink transition"
                  >
                    {isRTL ? <ChevronLeft className="h-4 w-4" /> : <ChevronRight className="h-4 w-4" />}
                  </button>
                </div>

                {/* Weekdays header */}
                <div className="mt-3.5 grid grid-cols-7 text-center">
                  {weekdays.map((w, idx) => (
                    <span key={idx} className="text-[11px] font-semibold text-ink-muted py-1">
                      {w}
                    </span>
                  ))}
                </div>

                {/* Days grid */}
                <div className="mt-1 grid grid-cols-7 gap-1 text-center">
                  {Array.from({ length: firstWeekday }).map((_, idx) => (
                    <div key={`blank-${idx}`} className="h-9 w-full" />
                  ))}

                  {Array.from({ length: daysInMonth }).map((_, idx) => {
                    const day = idx + 1
                    const dateObj = new Date(year, month, day)
                    const isPast = dateObj < today

                    const yyyy = dateObj.getFullYear()
                    const mm = String(dateObj.getMonth() + 1).padStart(2, '0')
                    const dd = String(dateObj.getDate()).padStart(2, '0')
                    const dateStr = `${yyyy}-${mm}-${dd}`

                    const isSelected = selectedDates.includes(dateStr)
                    const isTodayDate = dateObj.getTime() === today.getTime()

                    return (
                      <button
                        key={dateStr}
                        type="button"
                        disabled={isPast}
                        onClick={() => toggleDate(dateStr)}
                        className={`flex h-9 w-full items-center justify-center rounded-xl text-xs font-semibold transition ${
                          isSelected
                            ? 'bg-accent text-white shadow-xs font-bold'
                            : isTodayDate
                              ? 'border border-accent text-accent hover:bg-accent-soft'
                              : isPast
                                ? 'cursor-not-allowed text-ink-faint/30'
                                : 'text-ink hover:bg-surface-sunken'
                        }`}
                      >
                        {day}
                      </button>
                    )
                  })}
                </div>
              </div>

              {/* Footer */}
              <div className="flex shrink-0 items-center justify-between border-t border-line px-4 py-3 sm:px-5 bg-surface">
                <span className="text-xs text-ink-muted">
                  {selectedDates.length > 0
                    ? `${selectedDates.length} ${t.tripDashboard.precisionsCount}`
                    : t.tripDashboard.allCities}
                </span>
                <button
                  type="button"
                  onClick={onClose}
                  className="rounded-xl bg-accent px-5 py-2 text-xs font-semibold text-white shadow-xs hover:bg-accent-hover transition"
                >
                  {t.common.confirm}
                </button>
              </div>
            </motion.div>
          </div>
        )}
      </AnimatePresence>
    </ModalPortal>
  )
}

// ─────────────────────────────────────────────────────────────────────────────
// 2. TIME SELECTION MODAL (PERIODS & EXACT TIME)
// ─────────────────────────────────────────────────────────────────────────────

export function TimeSelectionModal({ open, onClose }: ModalBaseProps) {
  const { trip, togglePeriod, patchTrip, removeField } = useTrip()
  const { t } = useLanguage()

  useEffect(() => {
    if (open) {
      const handleKeyDown = (e: KeyboardEvent) => {
        if (e.key === 'Escape') onClose()
      }
      window.addEventListener('keydown', handleKeyDown)
      return () => window.removeEventListener('keydown', handleKeyDown)
    }
  }, [open, onClose])

  const periods = trip.periods || (trip.period ? [trip.period] : [])
  const exactTime = trip.exactTime || ''

  const periodOptions = [
    {
      id: 'morning' as TimePeriod,
      label: t.trip.morning,
      range: t.trip.morningRange,
      icon: Sunrise,
    },
    {
      id: 'afternoon' as TimePeriod,
      label: t.trip.afternoon,
      range: t.trip.afternoonRange,
      icon: Sun,
    },
    {
      id: 'evening' as TimePeriod,
      label: t.trip.evening,
      range: t.trip.eveningRange,
      icon: Moon,
    },
  ]

  const hasSelections = periods.length > 0 || Boolean(exactTime)

  return (
    <ModalPortal>
      <AnimatePresence>
        {open && (
          <div
            className="fixed inset-0 z-[100] flex items-center justify-center p-3 sm:p-5"
            role="dialog"
            aria-modal="true"
          >
            {/* Backdrop */}
            <motion.div
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              onClick={onClose}
              className="absolute inset-0 bg-ink/40 backdrop-blur-xs"
            />

            {/* Modal Dialog */}
            <motion.div
              initial={{ opacity: 0, scale: 0.95, y: 12 }}
              animate={{ opacity: 1, scale: 1, y: 0 }}
              exit={{ opacity: 0, scale: 0.95, y: 12 }}
              transition={{ duration: 0.22, ease: [0.23, 1, 0.32, 1] }}
              className="relative z-10 flex max-h-[85vh] sm:max-h-[80vh] w-full max-w-sm sm:max-w-md flex-col overflow-hidden rounded-2xl border border-line bg-surface shadow-2xl"
            >
              {/* Header */}
              <div className="flex shrink-0 items-center justify-between border-b border-line px-4 py-3 sm:px-5">
                <div className="flex items-center gap-2.5">
                  <div className="flex h-8 w-8 items-center justify-center rounded-full bg-accent-soft text-accent">
                    <Clock className="h-4 w-4" />
                  </div>
                  <h3 className="text-sm font-bold text-ink">{t.tripDashboard.selectTime}</h3>
                </div>
                <div className="flex items-center gap-1.5">
                  {hasSelections && (
                    <button
                      type="button"
                      onClick={() => removeField('time')}
                      className="rounded-lg px-2 py-1 text-xs font-semibold text-accent hover:bg-accent-soft transition"
                    >
                      {t.tripDashboard.clearFilters}
                    </button>
                  )}
                  <button
                    type="button"
                    onClick={onClose}
                    aria-label={t.common.close}
                    className="flex h-7 w-7 items-center justify-center rounded-full text-ink-muted transition hover:bg-surface-sunken hover:text-ink"
                  >
                    <X className="h-4 w-4" />
                  </button>
                </div>
              </div>

              {/* Scrollable Body */}
              <div className="veyn-scroll flex-1 min-h-0 overflow-y-auto p-4 sm:p-5 space-y-3.5 overscroll-contain pb-6">
                {/* Time periods options */}
                <div className="space-y-2">
                  {periodOptions.map((opt) => {
                    const isSelected = periods.includes(opt.id)
                    const Icon = opt.icon

                    return (
                      <button
                        key={opt.id}
                        type="button"
                        onClick={() => togglePeriod(opt.id)}
                        className={`flex w-full items-center justify-between rounded-xl border p-3 text-left transition ${
                          isSelected
                            ? 'border-accent bg-accent-soft text-accent font-semibold ring-1 ring-accent/30'
                            : 'border-line/70 bg-surface-sunken hover:bg-surface hover:border-line-strong text-ink'
                        }`}
                      >
                        <div className="flex items-center gap-3">
                          <div className={`flex h-8 w-8 items-center justify-center rounded-lg ${isSelected ? 'bg-accent text-white shadow-xs' : 'bg-surface text-ink-muted border border-line'}`}>
                            <Icon className="h-4 w-4" />
                          </div>
                          <div>
                            <p className="text-xs font-bold text-ink">{opt.label}</p>
                            <p className="text-[11px] text-ink-muted">{opt.range}</p>
                          </div>
                        </div>
                        <div className={`flex h-5 w-5 items-center justify-center rounded-full border ${isSelected ? 'border-accent bg-accent text-white' : 'border-line bg-surface'}`}>
                          {isSelected && <Check className="h-3 w-3 stroke-[3]" />}
                        </div>
                      </button>
                    )
                  })}
                </div>

                {/* Exact Time Input */}
                <div className="rounded-xl border border-line bg-surface-sunken/60 p-3">
                  <label className="block text-[11px] font-semibold text-ink-soft mb-1.5">
                    {t.trip.exactTime}
                  </label>
                  <div className="flex items-center gap-2">
                    <input
                      type="time"
                      value={exactTime}
                      onChange={(e) => patchTrip({ exactTime: e.target.value })}
                      className="w-full rounded-xl border border-line bg-surface px-3 py-2 text-xs font-bold text-ink focus:border-accent focus:outline-none focus:ring-1 focus:ring-accent"
                    />
                    {exactTime && (
                      <button
                        type="button"
                        onClick={() => patchTrip({ exactTime: null })}
                        aria-label={t.common.cancel}
                        className="rounded-xl border border-line bg-surface p-2 text-ink-muted hover:text-ink transition"
                      >
                        <X className="h-4 w-4" />
                      </button>
                    )}
                  </div>
                </div>
              </div>

              {/* Footer */}
              <div className="flex shrink-0 items-center justify-end border-t border-line px-4 py-3 sm:px-5 bg-surface">
                <button
                  type="button"
                  onClick={onClose}
                  className="rounded-xl bg-accent px-5 py-2 text-xs font-semibold text-white shadow-xs hover:bg-accent-hover transition"
                >
                  {t.common.confirm}
                </button>
              </div>
            </motion.div>
          </div>
        )}
      </AnimatePresence>
    </ModalPortal>
  )
}

// ─────────────────────────────────────────────────────────────────────────────
// 3. TRANSPORT SELECTION MODAL (MULTI-MODES)
// ─────────────────────────────────────────────────────────────────────────────

export function TransportSelectionModal({ open, onClose }: ModalBaseProps) {
  const { trip, toggleMode, removeField } = useTrip()
  const { t } = useLanguage()

  useEffect(() => {
    if (open) {
      const handleKeyDown = (e: KeyboardEvent) => {
        if (e.key === 'Escape') onClose()
      }
      window.addEventListener('keydown', handleKeyDown)
      return () => window.removeEventListener('keydown', handleKeyDown)
    }
  }, [open, onClose])

  const modes = trip.modes || []

  const transportOptions = [
    {
      id: 'shared_taxi' as TransportMode,
      label: t.trip.sharedTaxi,
      icon: Car,
    },
    {
      id: 'bus' as TransportMode,
      label: t.trip.bus,
      icon: Bus,
    },
    {
      id: 'train' as TransportMode,
      label: t.trip.train,
      icon: Train,
    },
    {
      id: 'plane' as TransportMode,
      label: t.trip.plane,
      icon: Plane,
    },
    {
      id: 'ferry' as TransportMode,
      label: t.trip.ferry,
      icon: Ship,
    },
    {
      id: 'other' as TransportMode,
      label: t.trip.other,
      icon: MoreHorizontal,
    },
  ]

  return (
    <ModalPortal>
      <AnimatePresence>
        {open && (
          <div
            className="fixed inset-0 z-[100] flex items-center justify-center p-3 sm:p-5"
            role="dialog"
            aria-modal="true"
          >
            {/* Backdrop */}
            <motion.div
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              onClick={onClose}
              className="absolute inset-0 bg-ink/40 backdrop-blur-xs"
            />

            {/* Modal Dialog */}
            <motion.div
              initial={{ opacity: 0, scale: 0.95, y: 12 }}
              animate={{ opacity: 1, scale: 1, y: 0 }}
              exit={{ opacity: 0, scale: 0.95, y: 12 }}
              transition={{ duration: 0.22, ease: [0.23, 1, 0.32, 1] }}
              className="relative z-10 flex max-h-[85vh] sm:max-h-[80vh] w-full max-w-sm sm:max-w-md flex-col overflow-hidden rounded-2xl border border-line bg-surface shadow-2xl"
            >
              {/* Header */}
              <div className="flex shrink-0 items-center justify-between border-b border-line px-4 py-3 sm:px-5">
                <div className="flex items-center gap-2.5">
                  <div className="flex h-8 w-8 items-center justify-center rounded-full bg-accent-soft text-accent">
                    <Car className="h-4 w-4" />
                  </div>
                  <h3 className="text-sm font-bold text-ink">{t.tripDashboard.selectTransport}</h3>
                </div>
                <div className="flex items-center gap-1.5">
                  {modes.length > 0 && (
                    <button
                      type="button"
                      onClick={() => removeField('modes')}
                      className="rounded-lg px-2 py-1 text-xs font-semibold text-accent hover:bg-accent-soft transition"
                    >
                      {t.tripDashboard.clearFilters}
                    </button>
                  )}
                  <button
                    type="button"
                    onClick={onClose}
                    aria-label={t.common.close}
                    className="flex h-7 w-7 items-center justify-center rounded-full text-ink-muted transition hover:bg-surface-sunken hover:text-ink"
                  >
                    <X className="h-4 w-4" />
                  </button>
                </div>
              </div>

              {/* Scrollable Body */}
              <div className="veyn-scroll flex-1 min-h-0 overflow-y-auto p-4 sm:p-5 overscroll-contain pb-6">
                <div className="grid grid-cols-2 gap-2.5">
                  {transportOptions.map((opt) => {
                    const isSelected = modes.includes(opt.id)
                    const Icon = opt.icon

                    return (
                      <button
                        key={opt.id}
                        type="button"
                        onClick={() => toggleMode(opt.id)}
                        className={`flex flex-col items-center justify-center gap-2 rounded-xl border p-3.5 transition ${
                          isSelected
                            ? 'border-accent bg-accent-soft text-accent font-bold ring-1 ring-accent/30'
                            : 'border-line/70 bg-surface-sunken hover:bg-surface hover:border-line-strong text-ink'
                        }`}
                      >
                        <div className={`flex h-10 w-10 items-center justify-center rounded-xl ${isSelected ? 'bg-accent text-white shadow-xs' : 'bg-surface text-ink-muted border border-line'}`}>
                          <Icon className="h-5 w-5" />
                        </div>
                        <span className="text-xs font-semibold text-center">{opt.label}</span>
                      </button>
                    )
                  })}
                </div>
              </div>

              {/* Footer */}
              <div className="flex shrink-0 items-center justify-end border-t border-line px-4 py-3 sm:px-5 bg-surface">
                <button
                  type="button"
                  onClick={onClose}
                  className="rounded-xl bg-accent px-5 py-2 text-xs font-semibold text-white shadow-xs hover:bg-accent-hover transition"
                >
                  {t.common.confirm}
                </button>
              </div>
            </motion.div>
          </div>
        )}
      </AnimatePresence>
    </ModalPortal>
  )
}

// ─────────────────────────────────────────────────────────────────────────────
// 4. TRAVELERS SELECTION MODAL (ADULTS, CHILDREN, ASSISTED)
// ─────────────────────────────────────────────────────────────────────────────

export function TravelersSelectionModal({ open, onClose }: ModalBaseProps) {
  const { trip, patchTrip } = useTrip()
  const { t } = useLanguage()

  useEffect(() => {
    if (open) {
      const handleKeyDown = (e: KeyboardEvent) => {
        if (e.key === 'Escape') onClose()
      }
      window.addEventListener('keydown', handleKeyDown)
      return () => window.removeEventListener('keydown', handleKeyDown)
    }
  }, [open, onClose])

  const travelers = trip.travelers || { adults: 1, children: 0, assisted: 0 }

  const handleUpdate = (field: 'adults' | 'children' | 'assisted', delta: number) => {
    const currentVal = travelers[field]
    let min = 0
    if (field === 'adults') min = 1
    const nextVal = Math.max(min, currentVal + delta)

    patchTrip({
      travelers: {
        ...travelers,
        [field]: nextVal,
      },
    })
  }

  const hasExtraTravelers = travelers.adults !== 1 || travelers.children > 0 || travelers.assisted > 0

  return (
    <ModalPortal>
      <AnimatePresence>
        {open && (
          <div
            className="fixed inset-0 z-[100] flex items-center justify-center p-3 sm:p-5"
            role="dialog"
            aria-modal="true"
          >
            {/* Backdrop */}
            <motion.div
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              onClick={onClose}
              className="absolute inset-0 bg-ink/40 backdrop-blur-xs"
            />

            {/* Modal Dialog */}
            <motion.div
              initial={{ opacity: 0, scale: 0.95, y: 12 }}
              animate={{ opacity: 1, scale: 1, y: 0 }}
              exit={{ opacity: 0, scale: 0.95, y: 12 }}
              transition={{ duration: 0.22, ease: [0.23, 1, 0.32, 1] }}
              className="relative z-10 flex max-h-[85vh] sm:max-h-[80vh] w-full max-w-sm sm:max-w-md flex-col overflow-hidden rounded-2xl border border-line bg-surface shadow-2xl"
            >
              {/* Header */}
              <div className="flex shrink-0 items-center justify-between border-b border-line px-4 py-3 sm:px-5">
                <div className="flex items-center gap-2.5">
                  <div className="flex h-8 w-8 items-center justify-center rounded-full bg-accent-soft text-accent">
                    <Users className="h-4 w-4" />
                  </div>
                  <h3 className="text-sm font-bold text-ink">{t.tripDashboard.selectTravelers}</h3>
                </div>
                <div className="flex items-center gap-1.5">
                  {hasExtraTravelers && (
                    <button
                      type="button"
                      onClick={() => patchTrip({ travelers: { adults: 1, children: 0, assisted: 0 } })}
                      className="rounded-lg px-2 py-1 text-xs font-semibold text-accent hover:bg-accent-soft transition"
                    >
                      {t.tripDashboard.clearFilters}
                    </button>
                  )}
                  <button
                    type="button"
                    onClick={onClose}
                    aria-label={t.common.close}
                    className="flex h-7 w-7 items-center justify-center rounded-full text-ink-muted transition hover:bg-surface-sunken hover:text-ink"
                  >
                    <X className="h-4 w-4" />
                  </button>
                </div>
              </div>

              {/* Scrollable Body */}
              <div className="veyn-scroll flex-1 min-h-0 overflow-y-auto p-4 sm:p-5 space-y-3 overscroll-contain pb-6">
                {/* Adults */}
                <div className="flex items-center justify-between rounded-xl border border-line bg-surface-sunken p-3">
                  <div className="flex items-center gap-3">
                    <div className="flex h-8 w-8 items-center justify-center rounded-lg bg-surface text-ink-soft border border-line">
                      <User className="h-4 w-4" />
                    </div>
                    <div>
                      <p className="text-xs font-bold text-ink">{t.trip.adults}</p>
                      <p className="text-[10px] text-ink-muted">{t.trip.adultsHint}</p>
                    </div>
                  </div>
                  <div className="flex items-center gap-2">
                    <button
                      type="button"
                      onClick={() => handleUpdate('adults', -1)}
                      disabled={travelers.adults <= 1}
                      aria-label="Decrease adults"
                      className="flex h-7 w-7 items-center justify-center rounded-lg border border-line bg-surface text-ink hover:bg-surface-elevated disabled:opacity-30 transition"
                    >
                      <Minus className="h-3.5 w-3.5" />
                    </button>
                    <span className="w-5 text-center text-xs font-bold text-ink">{travelers.adults}</span>
                    <button
                      type="button"
                      onClick={() => handleUpdate('adults', 1)}
                      aria-label="Increase adults"
                      className="flex h-7 w-7 items-center justify-center rounded-lg border border-line bg-surface text-ink hover:bg-surface-elevated transition"
                    >
                      <Plus className="h-3.5 w-3.5" />
                    </button>
                  </div>
                </div>

                {/* Children */}
                <div className="flex items-center justify-between rounded-xl border border-line bg-surface-sunken p-3">
                  <div className="flex items-center gap-3">
                    <div className="flex h-8 w-8 items-center justify-center rounded-lg bg-surface text-ink-soft border border-line">
                      <Baby className="h-4 w-4" />
                    </div>
                    <div>
                      <p className="text-xs font-bold text-ink">{t.trip.children}</p>
                      <p className="text-[10px] text-ink-muted">{t.trip.childrenHint}</p>
                    </div>
                  </div>
                  <div className="flex items-center gap-2">
                    <button
                      type="button"
                      onClick={() => handleUpdate('children', -1)}
                      disabled={travelers.children <= 0}
                      aria-label="Decrease children"
                      className="flex h-7 w-7 items-center justify-center rounded-lg border border-line bg-surface text-ink hover:bg-surface-elevated disabled:opacity-30 transition"
                    >
                      <Minus className="h-3.5 w-3.5" />
                    </button>
                    <span className="w-5 text-center text-xs font-bold text-ink">{travelers.children}</span>
                    <button
                      type="button"
                      onClick={() => handleUpdate('children', 1)}
                      aria-label="Increase children"
                      className="flex h-7 w-7 items-center justify-center rounded-lg border border-line bg-surface text-ink hover:bg-surface-elevated transition"
                    >
                      <Plus className="h-3.5 w-3.5" />
                    </button>
                  </div>
                </div>

                {/* Assisted / PRM */}
                <div className="flex items-center justify-between rounded-xl border border-line bg-surface-sunken p-3">
                  <div className="flex items-center gap-3">
                    <div className="flex h-8 w-8 items-center justify-center rounded-lg bg-surface text-ink-soft border border-line">
                      <Accessibility className="h-4 w-4" />
                    </div>
                    <div>
                      <p className="text-xs font-bold text-ink">{t.trip.assisted}</p>
                      <p className="text-[10px] text-ink-muted">{t.trip.assistedHint}</p>
                    </div>
                  </div>
                  <div className="flex items-center gap-2">
                    <button
                      type="button"
                      onClick={() => handleUpdate('assisted', -1)}
                      disabled={travelers.assisted <= 0}
                      aria-label="Decrease assisted"
                      className="flex h-7 w-7 items-center justify-center rounded-lg border border-line bg-surface text-ink hover:bg-surface-elevated disabled:opacity-30 transition"
                    >
                      <Minus className="h-3.5 w-3.5" />
                    </button>
                    <span className="w-5 text-center text-xs font-bold text-ink">{travelers.assisted}</span>
                    <button
                      type="button"
                      onClick={() => handleUpdate('assisted', 1)}
                      aria-label="Increase assisted"
                      className="flex h-7 w-7 items-center justify-center rounded-lg border border-line bg-surface text-ink hover:bg-surface-elevated transition"
                    >
                      <Plus className="h-3.5 w-3.5" />
                    </button>
                  </div>
                </div>
              </div>

              {/* Footer */}
              <div className="flex shrink-0 items-center justify-end border-t border-line px-4 py-3 sm:px-5 bg-surface">
                <button
                  type="button"
                  onClick={onClose}
                  className="rounded-xl bg-accent px-5 py-2 text-xs font-semibold text-white shadow-xs hover:bg-accent-hover transition"
                >
                  {t.common.confirm}
                </button>
              </div>
            </motion.div>
          </div>
        )}
      </AnimatePresence>
    </ModalPortal>
  )
}

// ─────────────────────────────────────────────────────────────────────────────
// 5. PRECISIONS & STOPS MODAL (STOPS PREFERENCE & MAXIMUM BUDGET)
// ─────────────────────────────────────────────────────────────────────────────

export function PrecisionsSelectionModal({ open, onClose }: ModalBaseProps) {
  const { trip, patchTrip, removeField } = useTrip()
  const { t, language } = useLanguage()

  useEffect(() => {
    if (open) {
      const handleKeyDown = (e: KeyboardEvent) => {
        if (e.key === 'Escape') onClose()
      }
      window.addEventListener('keydown', handleKeyDown)
      return () => window.removeEventListener('keydown', handleKeyDown)
    }
  }, [open, onClose])

  const currency = tripCurrency(trip, language)
  const hasActivePrecisions = trip.directOnly !== undefined || (trip.budget !== null && trip.budget !== undefined)

  return (
    <ModalPortal>
      <AnimatePresence>
        {open && (
          <div
            className="fixed inset-0 z-[100] flex items-center justify-center p-3 sm:p-5"
            role="dialog"
            aria-modal="true"
          >
            {/* Backdrop */}
            <motion.div
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              onClick={onClose}
              className="absolute inset-0 bg-ink/40 backdrop-blur-xs"
            />

            {/* Modal Dialog */}
            <motion.div
              initial={{ opacity: 0, scale: 0.95, y: 12 }}
              animate={{ opacity: 1, scale: 1, y: 0 }}
              exit={{ opacity: 0, scale: 0.95, y: 12 }}
              transition={{ duration: 0.22, ease: [0.23, 1, 0.32, 1] }}
              className="relative z-10 flex max-h-[85vh] sm:max-h-[80vh] w-full max-w-sm sm:max-w-md flex-col overflow-hidden rounded-2xl border border-line bg-surface shadow-2xl"
            >
              {/* Header */}
              <div className="flex shrink-0 items-center justify-between border-b border-line px-4 py-3 sm:px-5">
                <div className="flex items-center gap-2.5">
                  <div className="flex h-8 w-8 items-center justify-center rounded-full bg-accent-soft text-accent">
                    <SlidersHorizontal className="h-4 w-4" />
                  </div>
                  <h3 className="text-sm font-bold text-ink">{t.tripDashboard.selectPrecisions}</h3>
                </div>
                <div className="flex items-center gap-1.5">
                  {hasActivePrecisions && (
                    <button
                      type="button"
                      onClick={() => {
                        patchTrip({ directOnly: false, budget: null })
                        removeField('budget')
                      }}
                      className="rounded-lg px-2 py-1 text-xs font-semibold text-accent hover:bg-accent-soft transition"
                    >
                      {t.tripDashboard.clearFilters}
                    </button>
                  )}
                  <button
                    type="button"
                    onClick={onClose}
                    aria-label={t.common.close}
                    className="flex h-7 w-7 items-center justify-center rounded-full text-ink-muted transition hover:bg-surface-sunken hover:text-ink"
                  >
                    <X className="h-4 w-4" />
                  </button>
                </div>
              </div>

              {/* Scrollable Body */}
              <div className="veyn-scroll flex-1 min-h-0 overflow-y-auto p-4 sm:p-5 space-y-4 overscroll-contain pb-6">
                {/* 1. Préférence des points d'arrêt */}
                <div className="space-y-2">
                  <div className="flex items-center gap-2">
                    <Route className="h-4 w-4 text-accent" />
                    <span className="text-xs font-bold text-ink">{t.tripDashboard.stopsPreference}</span>
                  </div>

                  <div className="grid grid-cols-1 gap-2">
                    <button
                      type="button"
                      onClick={() => patchTrip({ directOnly: false })}
                      className={`flex items-center justify-between rounded-xl border p-3 text-left transition ${
                        !trip.directOnly
                          ? 'border-accent bg-accent-soft text-accent font-semibold ring-1 ring-accent/30'
                          : 'border-line/70 bg-surface-sunken hover:bg-surface text-ink'
                      }`}
                    >
                      <span className="text-xs">{t.tripDashboard.allTrips}</span>
                      <div className={`flex h-4 w-4 items-center justify-center rounded-full border ${!trip.directOnly ? 'border-accent bg-accent text-white' : 'border-line bg-surface'}`}>
                        {!trip.directOnly && <Check className="h-2.5 w-2.5 stroke-[3]" />}
                      </div>
                    </button>

                    <button
                      type="button"
                      onClick={() => patchTrip({ directOnly: true })}
                      className={`flex items-center justify-between rounded-xl border p-3 text-left transition ${
                        trip.directOnly
                          ? 'border-accent bg-accent-soft text-accent font-semibold ring-1 ring-accent/30'
                          : 'border-line/70 bg-surface-sunken hover:bg-surface text-ink'
                      }`}
                    >
                      <span className="text-xs">{t.tripDashboard.directOnly}</span>
                      <div className={`flex h-4 w-4 items-center justify-center rounded-full border ${trip.directOnly ? 'border-accent bg-accent text-white' : 'border-line bg-surface'}`}>
                        {trip.directOnly && <Check className="h-2.5 w-2.5 stroke-[3]" />}
                      </div>
                    </button>
                  </div>
                </div>

                {/* 2. Budget maximum */}
                <div className="space-y-2 border-t border-line/70 pt-3.5">
                  <div className="flex items-center gap-2">
                    <Wallet className="h-4 w-4 text-accent" />
                    <span className="text-xs font-bold text-ink">{t.tripDashboard.budgetMax}</span>
                  </div>

                  <div className="flex items-center gap-2">
                    <div className="relative flex-1">
                      <input
                        type="number"
                        min="0"
                        value={trip.budget ?? ''}
                        placeholder={t.tripPanel.optional}
                        onChange={(e) => {
                          const val = e.target.value
                          patchTrip({ budget: val === '' ? null : Math.max(0, Number(val)) })
                        }}
                        className="w-full rounded-xl border border-line bg-surface-sunken px-3 py-2 text-xs font-bold text-ink focus:border-accent focus:outline-none focus:ring-1 focus:ring-accent"
                      />
                    </div>
                    <span className="rounded-xl border border-line bg-surface px-3 py-2 text-xs font-bold text-ink-muted">
                      {currency}
                    </span>
                    {trip.budget !== null && trip.budget !== undefined && (
                      <button
                        type="button"
                        onClick={() => patchTrip({ budget: null })}
                        aria-label={t.common.cancel}
                        className="rounded-xl border border-line bg-surface-sunken p-2 text-ink-muted hover:text-ink transition"
                      >
                        <X className="h-4 w-4" />
                      </button>
                    )}
                  </div>

                  {/* Suggestions rapides */}
                  <div className="flex flex-wrap gap-1.5 pt-1">
                    {BUDGET_SUGGESTIONS.map((amount) => {
                      const isActive = trip.budget === amount
                      return (
                        <button
                          key={amount}
                          type="button"
                          onClick={() => patchTrip({ budget: isActive ? null : amount })}
                          className={`rounded-full border px-2.5 py-1 text-xs font-semibold transition ${
                            isActive
                              ? 'border-accent bg-accent text-white shadow-xs'
                              : 'border-line bg-surface-sunken text-ink-muted hover:border-line-strong hover:text-ink'
                          }`}
                        >
                          {amount} {currency}
                        </button>
                      )
                    })}
                  </div>
                </div>
              </div>

              {/* Footer */}
              <div className="flex shrink-0 items-center justify-end border-t border-line px-4 py-3 sm:px-5 bg-surface">
                <button
                  type="button"
                  onClick={onClose}
                  className="rounded-xl bg-accent px-5 py-2 text-xs font-semibold text-white shadow-xs hover:bg-accent-hover transition"
                >
                  {t.common.confirm}
                </button>
              </div>
            </motion.div>
          </div>
        )}
      </AnimatePresence>
    </ModalPortal>
  )
}
