import React from 'react'
import { AnimatePresence, motion } from 'framer-motion'
import {
  BusIcon,
  CalendarIcon,
  ClockIcon,
  MapPinIcon,
  MapPinnedIcon,
  SparklesIcon,
  UsersIcon,
  WalletIcon,
  XIcon,
} from 'lucide-react'
import { useTrip } from '../../contexts/TripContext'
import { useLanguage } from '../../contexts/LanguageContext'
import { tripChips } from '../../utils/trip'
import type { TripField } from '../../types/trip'

interface TripChipsProps {
  className?: string
  showHeader?: boolean
}

/**
 * Retourne l'icône représentative correspondant au champ de précision.
 */
export function getFieldIcon(field: TripField) {
  switch (field) {
    case 'origin':
      return MapPinIcon
    case 'destination':
      return MapPinnedIcon
    case 'date':
      return CalendarIcon
    case 'time':
      return ClockIcon
    case 'travelers':
      return UsersIcon
    case 'modes':
      return BusIcon
    case 'budget':
      return WalletIcon
    default:
      return SparklesIcon
  }
}

/**
 * Style de pastille colorée représentative pour l'icône du tag.
 */
export function getFieldColor(field: TripField) {
  switch (field) {
    case 'origin':
      return 'bg-blue-100 text-blue-700 dark:bg-blue-950/60 dark:text-blue-300'
    case 'destination':
      return 'bg-emerald-100 text-emerald-700 dark:bg-emerald-950/60 dark:text-emerald-300'
    case 'date':
      return 'bg-amber-100 text-amber-700 dark:bg-amber-950/60 dark:text-amber-300'
    case 'time':
      return 'bg-purple-100 text-purple-700 dark:bg-purple-950/60 dark:text-purple-300'
    case 'travelers':
      return 'bg-rose-100 text-rose-700 dark:bg-rose-950/60 dark:text-rose-300'
    case 'modes':
      return 'bg-teal-100 text-teal-700 dark:bg-teal-950/60 dark:text-teal-300'
    case 'budget':
      return 'bg-indigo-100 text-indigo-700 dark:bg-indigo-950/60 dark:text-indigo-300'
    default:
      return 'bg-accent/10 text-accent'
  }
}

export function TripChips({ className = '', showHeader = false }: TripChipsProps) {
  const { trip, openPanel, removeField } = useTrip()
  const { t, language } = useLanguage()
  const chips = tripChips(trip, language)

  if (chips.length === 0) return null

  return (
    <div className={`flex flex-wrap items-center gap-1.5 ${className}`} aria-label={t.composer.activeFilters}>
      {showHeader ? (
        <span className="text-[11px] font-semibold text-ink-muted mr-1 flex items-center gap-1">
          {t.composer.openFilters} :
        </span>
      ) : null}

      <AnimatePresence>
        {chips.map((chip) => {
          const Icon = getFieldIcon(chip.field)
          const colorClass = getFieldColor(chip.field)

          return (
            <motion.div
              key={chip.field}
              layout
              initial={{ opacity: 0, scale: 0.85, y: 3 }}
              animate={{ opacity: 1, scale: 1, y: 0 }}
              exit={{ opacity: 0, scale: 0.85, y: -3 }}
              transition={{ duration: 0.16, ease: [0.23, 1, 0.32, 1] }}
              className="group inline-flex items-center gap-1.5 rounded-full border border-line bg-surface py-1 pl-2 pr-1.5 text-xs text-ink shadow-xs transition-all duration-150 hover:border-accent/40 hover:bg-surface-elevated hover:shadow-sm"
            >
              {/* Petite icône représentative élégante */}
              <span
                className={`flex h-5 w-5 shrink-0 items-center justify-center rounded-full ${colorClass}`}
                aria-hidden="true"
              >
                <Icon className="h-3 w-3" />
              </span>

              {/* Libellé cliquable pour modifier directement la précision */}
              <button
                type="button"
                onClick={() => openPanel(chip.field)}
                className="font-medium text-ink-soft transition-colors duration-150 ease-out hover:text-ink cursor-pointer"
                title={chip.label}
              >
                {chip.label}
              </button>

              {/* Bouton de suppression individuelle (×) */}
              <button
                type="button"
                onClick={(e) => {
                  e.stopPropagation()
                  removeField(chip.field)
                }}
                aria-label={`${t.common.cancel} ${chip.label}`}
                title={t.common.cancel}
                className="flex h-4 w-4 shrink-0 items-center justify-center rounded-full text-ink-faint transition-colors duration-150 ease-out hover:bg-rose-100 hover:text-rose-600 dark:hover:bg-rose-950/60 dark:hover:text-rose-400 active:scale-90"
              >
                <XIcon className="h-3 w-3" aria-hidden="true" />
              </button>
            </motion.div>
          )
        })}
      </AnimatePresence>
    </div>
  )
}
