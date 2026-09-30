import React from 'react'
import type { TimePeriod } from '../../types/trip'
import { useLanguage } from '../../contexts/LanguageContext'

interface TimeFieldProps {
  period: TimePeriod | null
  periods?: TimePeriod[]
  exactTime: string | null
  onChange: (periods: TimePeriod[], exactTime: string | null) => void
}

export function TimeField({ period, periods, exactTime, onChange }: TimeFieldProps) {
  const { t, language } = useLanguage()

  const selectedPeriods = (periods && periods.length > 0)
    ? periods
    : (period && period !== 'exact' ? [period] : [])
  const isExact = period === 'exact'

  const periodOptions = [
    { id: 'morning' as TimePeriod, label: t.trip.morning, range: t.trip.morningRange },
    { id: 'afternoon' as TimePeriod, label: t.trip.afternoon, range: t.trip.afternoonRange },
    { id: 'evening' as TimePeriod, label: t.trip.evening, range: t.trip.eveningRange },
    { id: 'exact' as TimePeriod, label: t.trip.exactTime, range: '—' },
  ]

  const togglePeriod = (optionId: TimePeriod) => {
    if (optionId === 'exact') {
      onChange(['exact'], exactTime ?? '08:00')
      return
    }

    const currentWithoutExact = selectedPeriods.filter((p) => p !== 'exact')
    let next: TimePeriod[]
    if (currentWithoutExact.includes(optionId)) {
      next = currentWithoutExact.filter((p) => p !== optionId)
    } else {
      next = [...currentWithoutExact, optionId]
    }
    onChange(next, null)
  }

  return (
    <div className="space-y-3">
      {selectedPeriods.length > 1 && !isExact && (
        <div className="rounded-lg bg-purple-500/10 px-2.5 py-1 text-[11px] font-medium text-purple-700 dark:text-purple-300">
          {language === 'ar'
            ? `✓ تم تحديد ${selectedPeriods.length} فترات زمنية (البحث يشمل أي منها)`
            : language === 'en'
            ? `✓ ${selectedPeriods.length} time periods selected (matching any)`
            : `✓ ${selectedPeriods.length} créneaux sélectionnés (recherche combinée)`}
        </div>
      )}

      <div className="grid grid-cols-2 gap-1.5">
        {periodOptions.map((option) => {
          const active = option.id === 'exact' ? isExact : selectedPeriods.includes(option.id)
          return (
            <button
              key={option.id}
              type="button"
              aria-pressed={active}
              onClick={() => togglePeriod(option.id)}
              className={`rounded-lg border px-3 py-2 text-left transition-colors duration-150 ease-out ${
                active ? 'border-ink bg-ink text-white shadow-xs' : 'border-line bg-surface hover:border-line-strong'
              }`}
            >
              <span className="block text-[13px] font-medium">{option.label}</span>
              <span className={`block text-[11px] ${active ? 'text-white/70' : 'text-ink-muted'}`}>
                {option.range}
              </span>
            </button>
          )
        })}
      </div>

      {isExact ? (
        <label className="flex items-center gap-3 rounded-lg border border-line bg-surface px-3 py-2">
          <span className="text-[13px] text-ink-soft">{t.tripPanel.departureTime}</span>
          <input
            type="time"
            value={exactTime ?? '08:00'}
            onChange={(event) => onChange(['exact'], event.target.value)}
            className="ml-auto rounded-md border border-line px-2 py-1 text-[13px] tabular-nums text-ink focus:border-ink/30 focus:outline-none focus-visible:ring-2 focus-visible:ring-ink/10"
          />
        </label>
      ) : null}

      {(selectedPeriods.length > 0 || isExact) && (
        <div className="flex justify-end">
          <button
            type="button"
            onClick={() => onChange([], null)}
            className="text-[11px] font-medium text-rose-600 hover:text-rose-700 transition-colors"
          >
            {language === 'ar' ? 'إلغاء تحديد الوقت' : language === 'en' ? 'Clear time' : "Effacer l'horaire"}
          </button>
        </div>
      )}
    </div>
  )
}
