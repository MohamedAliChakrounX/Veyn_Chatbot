import React, { useState } from 'react'
import {
  addDays,
  addMonths,
  eachDayOfInterval,
  endOfMonth,
  format,
  getDay,
  isBefore,
  isSameMonth,
  startOfMonth,
  startOfToday,
  subMonths,
} from 'date-fns'
import { ar, enUS, fr } from 'date-fns/locale'
import { ChevronLeftIcon, ChevronRightIcon } from 'lucide-react'
import { useLanguage } from '../../contexts/LanguageContext'
import { parseISODate, toISODate } from '../../utils/trip'

interface DateFieldProps {
  value?: string | null
  dates?: string[]
  onChange: (dates: string[]) => void
}

export function DateField({ value, dates, onChange }: DateFieldProps) {
  const { t, language } = useLanguage()
  const today = startOfToday()
  const selectedDates = (dates && dates.length > 0) ? dates : (value ? [value] : [])
  const firstSelected = selectedDates[0] ? parseISODate(selectedDates[0]) : null
  const [month, setMonth] = useState<Date>(startOfMonth(firstSelected ?? today))
  const days = eachDayOfInterval({ start: startOfMonth(month), end: endOfMonth(month) })
  const leadingBlanks = (getDay(startOfMonth(month)) + 6) % 7

  const locale = language === 'ar' ? ar : language === 'en' ? enUS : fr
  const weekdays =
    language === 'ar'
      ? ['ن', 'ث', 'ر', 'خ', 'ج', 'س', 'ح']
      : language === 'en'
      ? ['M', 'T', 'W', 'T', 'F', 'S', 'S']
      : ['L', 'M', 'M', 'J', 'V', 'S', 'D']

  const shortcuts = [
    { label: t.trip.today, date: today },
    { label: t.trip.tomorrow, date: addDays(today, 1) },
  ]

  const toggleDate = (iso: string) => {
    if (selectedDates.includes(iso)) {
      onChange(selectedDates.filter((d) => d !== iso))
    } else {
      onChange([...selectedDates, iso].sort())
    }
  }

  return (
    <div className="space-y-3">
      <div className="flex items-center justify-between flex-wrap gap-1.5">
        <div className="flex gap-1.5">
          {shortcuts.map((shortcut) => {
            const iso = toISODate(shortcut.date)
            const active = selectedDates.includes(iso)
            return (
              <button
                key={shortcut.label}
                type="button"
                onClick={() => {
                  toggleDate(iso)
                  setMonth(startOfMonth(shortcut.date))
                }}
                className={`rounded-full border px-3 py-1.5 text-xs font-medium transition-colors duration-150 ease-out ${
                  active
                    ? 'border-ink bg-ink text-white'
                    : 'border-line bg-surface text-ink-muted hover:border-line-strong hover:text-ink'
                }`}
              >
                {shortcut.label}
              </button>
            )
          })}
        </div>

        {selectedDates.length > 0 && (
          <button
            type="button"
            onClick={() => onChange([])}
            className="text-[11px] font-medium text-rose-600 hover:text-rose-700 transition-colors"
          >
            {language === 'ar' ? 'إلغاء التحديد' : language === 'en' ? 'Clear dates' : 'Effacer les dates'}
          </button>
        )}
      </div>

      {selectedDates.length > 1 && (
        <div className="rounded-lg bg-amber-500/10 px-2.5 py-1 text-[11px] font-medium text-amber-700 dark:text-amber-300">
          {language === 'ar'
            ? `✓ تم تحديد ${selectedDates.length} تواريخ (البحث يشمل أي منها)`
            : language === 'en'
            ? `✓ ${selectedDates.length} dates selected (matching any of them)`
            : `✓ ${selectedDates.length} dates sélectionnées (recherche sur l'une d'entre elles)`}
        </div>
      )}

      <div className="flex items-center justify-between">
        <button
          type="button"
          onClick={() => setMonth(subMonths(month, 1))}
          disabled={isSameMonth(month, today)}
          aria-label={t.common.back}
          className="flex h-8 w-8 items-center justify-center rounded-full text-ink-soft transition-colors duration-150 ease-out hover:bg-surface-sunken disabled:text-ink-faint/50 disabled:hover:bg-transparent"
        >
          <ChevronLeftIcon className="h-4 w-4" aria-hidden="true" />
        </button>
        <p className="text-[13px] font-semibold capitalize text-ink" aria-live="polite">
          {format(month, 'MMMM yyyy', { locale })}
        </p>
        <button
          type="button"
          onClick={() => setMonth(addMonths(month, 1))}
          aria-label={t.common.next}
          className="flex h-8 w-8 items-center justify-center rounded-full text-ink-soft transition-colors duration-150 ease-out hover:bg-surface-sunken"
        >
          <ChevronRightIcon className="h-4 w-4" aria-hidden="true" />
        </button>
      </div>
      <div className="grid grid-cols-7 gap-1">
        {weekdays.map((day, index) => (
          <div key={`${day}-${index}`} className="pb-1 text-center text-[11px] font-medium text-ink-faint">
            {day}
          </div>
        ))}
        {Array.from({ length: leadingBlanks }).map((_, index) => (
          <div key={`blank-${index}`} aria-hidden="true" />
        ))}
        {days.map((day) => {
          const iso = toISODate(day)
          const disabled = isBefore(day, today)
          const active = selectedDates.includes(iso)
          return (
            <button
              key={iso}
              type="button"
              disabled={disabled}
              onClick={() => toggleDate(iso)}
              aria-label={format(day, 'EEEE d MMMM', { locale })}
              aria-pressed={active}
              className={`flex h-9 items-center justify-center rounded-lg text-[13px] tabular-nums transition-colors duration-150 ease-out ${
                active
                  ? 'bg-ink font-semibold text-white shadow-xs'
                  : disabled
                    ? 'cursor-not-allowed text-ink-faint/50'
                    : 'text-ink-soft hover:bg-surface-sunken'
              }`}
            >
              {format(day, 'd')}
            </button>
          )
        })}
      </div>
    </div>
  )
}
