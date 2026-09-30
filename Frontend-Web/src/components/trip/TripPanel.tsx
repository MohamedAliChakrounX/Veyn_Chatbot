import React, { useEffect, useRef } from 'react'
import { motion } from 'framer-motion'
import {
  BanknoteIcon,
  CalendarIcon,
  ClockIcon,
  MapPinIcon,
  NavigationIcon,
  RouteIcon,
  UsersIcon,
  XIcon,
} from 'lucide-react'
import { cityLabel } from '../../data/locations'
import { useTrip } from '../../contexts/TripContext'
import { useLanguage } from '../../contexts/LanguageContext'
import { datesLabel, isTripEmpty, modesLabel, timeLabel, travelersLabel, tripCurrency } from '../../utils/trip'
import { PanelRow } from './PanelRow'
import { LocationField } from './LocationField'
import { TravelersField } from './TravelersField'
import { DateField } from './DateField'
import { TimeField } from './TimeField'
import { TransportField } from './TransportField'
import { BudgetField } from './BudgetField'

function capitalize(value: string | null): string | null {
  if (!value) return null
  return value.charAt(0).toUpperCase() + value.slice(1)
}

interface TripPanelProps {
  onApply?: () => void
}

export function TripPanel({ onApply }: TripPanelProps) {
  const { trip, patchTrip, resetTrip, closePanel, activeField, toggleField } = useTrip()
  const { t, language } = useLanguage()
  const containerRef = useRef<HTMLDivElement>(null)
  const currency = tripCurrency(trip, language)

  useEffect(() => {
    const onKeyDown = (event: KeyboardEvent) => {
      if (event.key === 'Escape') closePanel()
    }
    const onPointerDown = (event: MouseEvent) => {
      if (containerRef.current && !containerRef.current.contains(event.target as Node)) {
        closePanel()
      }
    }
    document.addEventListener('keydown', onKeyDown)
    document.addEventListener('mousedown', onPointerDown)
    return () => {
      document.removeEventListener('keydown', onKeyDown)
      document.removeEventListener('mousedown', onPointerDown)
    }
  }, [closePanel])

  const handleApply = () => {
    closePanel()
    if (onApply) {
      onApply()
    }
  }

  return (
    <motion.div
      ref={containerRef}
      role="dialog"
      aria-label={t.tripPanel.refineTrip}
      initial={{ opacity: 0, y: 12 }}
      animate={{ opacity: 1, y: 0 }}
      exit={{ opacity: 0, y: 12 }}
      transition={{ duration: 0.2, ease: [0.23, 1, 0.32, 1] }}
      className="absolute bottom-full left-0 right-0 z-20 mb-2 overflow-hidden rounded-2xl border border-line bg-surface shadow-panel"
    >
      <div className="flex items-center gap-3 border-b border-line px-4 py-3">
        <h2 className="text-[13px] font-semibold text-ink">{t.tripPanel.refineTrip}</h2>
        <span className="text-xs text-ink-faint">{t.tripPanel.allOptional}</span>
        <div className="ml-auto flex items-center gap-1">
          {!isTripEmpty(trip) ? (
            <button
              type="button"
              onClick={resetTrip}
              className="rounded-full px-2.5 py-1.5 text-xs font-medium text-accent transition-colors duration-150 ease-out hover:bg-accent-soft"
            >
              {t.tripPanel.reset}
            </button>
          ) : null}
          <button
            type="button"
            onClick={closePanel}
            aria-label={t.common.close}
            className="flex h-8 w-8 items-center justify-center rounded-full text-ink-muted transition-colors duration-150 ease-out hover:bg-surface-sunken hover:text-ink"
          >
            <XIcon className="h-4 w-4" aria-hidden="true" />
          </button>
        </div>
      </div>
      <div className="veyn-scroll max-h-[min(62vh,26rem)] space-y-1.5 overflow-y-auto p-3">
        <PanelRow
          id="origin"
          label={t.tripPanel.departure}
          icon={MapPinIcon}
          value={trip.origin ? cityLabel(trip.origin, language) : null}
          open={activeField === 'origin'}
          onToggle={() => toggleField('origin')}
        >
          <LocationField
            selected={trip.origin}
            excludeId={trip.destination?.id}
            placeholder={t.tripPanel.departurePlaceholder}
            onSelect={(city) => {
              patchTrip({ origin: city })
              toggleField('origin')
            }}
          />
        </PanelRow>
        <PanelRow
          id="destination"
          label={t.tripPanel.destination}
          icon={NavigationIcon}
          value={trip.destination ? cityLabel(trip.destination, language) : null}
          open={activeField === 'destination'}
          onToggle={() => toggleField('destination')}
        >
          <LocationField
            selected={trip.destination}
            excludeId={trip.origin?.id}
            placeholder={t.tripPanel.arrivalPlaceholder}
            onSelect={(city) => {
              patchTrip({ destination: city })
              toggleField('destination')
            }}
          />
        </PanelRow>
        <PanelRow
          id="travelers"
          label={t.tripPanel.travelers}
          icon={UsersIcon}
          value={travelersLabel(trip, language)}
          open={activeField === 'travelers'}
          onToggle={() => toggleField('travelers')}
        >
          <TravelersField travelers={trip.travelers} onChange={(travelers) => patchTrip({ travelers })} />
        </PanelRow>
        <PanelRow
          id="date"
          label={t.tripPanel.date}
          icon={CalendarIcon}
          value={capitalize(datesLabel(trip, language))}
          open={activeField === 'date'}
          onToggle={() => toggleField('date')}
        >
          <DateField
            value={trip.date}
            dates={trip.dates}
            onChange={(dates) => patchTrip({ dates, date: dates[0] ?? null })}
          />
        </PanelRow>
        <PanelRow
          id="time"
          label={t.tripPanel.time}
          icon={ClockIcon}
          value={capitalize(timeLabel(trip, language))}
          open={activeField === 'time'}
          onToggle={() => toggleField('time')}
        >
          <TimeField
            period={trip.period}
            periods={trip.periods}
            exactTime={trip.exactTime}
            onChange={(periods, exactTime) => {
              const isExact = periods.includes('exact')
              patchTrip({
                periods: isExact ? [] : periods,
                period: isExact ? 'exact' : (periods[0] ?? null),
                exactTime,
              })
            }}
          />
        </PanelRow>
        <PanelRow
          id="modes"
          label={t.tripPanel.transport}
          icon={RouteIcon}
          value={modesLabel(trip, language)}
          open={activeField === 'modes'}
          onToggle={() => toggleField('modes')}
        >
          <TransportField modes={trip.modes} onChange={(modes) => patchTrip({ modes })} />
        </PanelRow>
        <PanelRow
          id="budget"
          label={t.tripPanel.budgetMax}
          icon={BanknoteIcon}
          value={trip.budget === null ? null : `${trip.budget} ${currency}`}
          open={activeField === 'budget'}
          onToggle={() => toggleField('budget')}
        >
          <BudgetField budget={trip.budget} currency={currency} onChange={(budget) => patchTrip({ budget })} />
        </PanelRow>
      </div>

      <div className="border-t border-line bg-surface-sunken/50 p-2.5 flex items-center justify-end gap-2">
        <button
          type="button"
          onClick={closePanel}
          className="rounded-full px-3.5 py-1.5 text-xs font-medium text-ink-soft transition-colors duration-150 ease-out hover:bg-surface-sunken hover:text-ink"
        >
          {t.common.cancel}
        </button>
        <button
          type="button"
          onClick={handleApply}
          className="rounded-full bg-accent px-4 py-1.5 text-xs font-semibold text-white shadow-xs transition-colors duration-150 ease-out hover:bg-accent-hover"
        >
          {language === 'ar' ? 'تطبيق والبحث' : language === 'en' ? 'Apply & Search' : 'Appliquer et rechercher'}
        </button>
      </div>
    </motion.div>
  )
}
