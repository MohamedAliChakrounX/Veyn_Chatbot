import React from 'react'
import { BUDGET_SUGGESTIONS } from '../../data/options'
import { useLanguage } from '../../contexts/LanguageContext'

interface BudgetFieldProps {
  budget: number | null
  currency: string
  onChange: (budget: number | null) => void
}

export function BudgetField({ budget, currency, onChange }: BudgetFieldProps) {
  const { t } = useLanguage()

  return (
    <div className="space-y-3">
      <label className="flex items-center gap-3 rounded-lg border border-line bg-surface px-3 py-2">
        <span className="text-[13px] text-ink-soft">{t.trip.budgetMax}</span>
        <input
          type="number"
          inputMode="numeric"
          min={0}
          value={budget ?? ''}
          placeholder="—"
          onChange={(event) => {
            const raw = event.target.value
            onChange(raw === '' ? null : Math.max(0, Number(raw)))
          }}
          className="ml-auto w-24 rounded-md border border-line px-2 py-1 text-right text-[13px] tabular-nums text-ink placeholder:text-ink-faint focus:border-ink/30 focus:outline-none focus-visible:ring-2 focus-visible:ring-ink/10"
        />
        <span className="text-[13px] font-medium text-ink-muted">{currency}</span>
      </label>
      <div className="flex flex-wrap gap-1.5">
        {BUDGET_SUGGESTIONS.map((amount) => {
          const active = budget === amount
          return (
            <button
              key={amount}
              type="button"
              aria-pressed={active}
              onClick={() => onChange(active ? null : amount)}
              className={`rounded-full border px-3 py-1.5 text-xs font-medium tabular-nums transition-colors duration-150 ease-out ${
                active
                  ? 'border-ink bg-ink text-white'
                  : 'border-line bg-surface text-ink-muted hover:border-line-strong hover:text-ink'
              }`}
            >
              {amount} {currency}
            </button>
          )
        })}
      </div>
    </div>
  )
}
