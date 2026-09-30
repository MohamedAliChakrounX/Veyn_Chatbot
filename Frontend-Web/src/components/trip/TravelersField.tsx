import React from 'react'
import { MinusIcon, PlusIcon } from 'lucide-react'
import { useLanguage } from '../../contexts/LanguageContext'
import type { Travelers } from '../../types/trip'

interface TravelersFieldProps {
  travelers: Travelers
  onChange: (travelers: Travelers) => void
}

export function TravelersField({ travelers, onChange }: TravelersFieldProps) {
  const { t } = useLanguage()

  const categories = [
    { id: 'adults' as const, label: t.trip.adults, hint: t.trip.adultsHint, min: 0 },
    { id: 'children' as const, label: t.trip.children, hint: t.trip.childrenHint, min: 0 },
    { id: 'assisted' as const, label: t.trip.assisted, hint: t.trip.assistedHint, min: 0 },
  ]

  return (
    <ul className="space-y-1">
      {categories.map((category) => {
        const count = travelers[category.id]
        return (
          <li key={category.id} className="flex items-center gap-3 py-1.5">
            <div className="min-w-0">
              <p className="truncate text-[13px] font-medium text-ink">{category.label}</p>
              {category.hint ? <p className="text-xs text-ink-muted">{category.hint}</p> : null}
            </div>
            <div className="ml-auto flex shrink-0 items-center gap-1">
              <button
                type="button"
                onClick={() => onChange({ ...travelers, [category.id]: Math.max(category.min, count - 1) })}
                disabled={count <= category.min}
                aria-label={`Retirer un ${category.label}`}
                className="flex h-9 w-9 items-center justify-center rounded-full border border-line text-ink-soft transition-colors duration-150 ease-out hover:border-line-strong hover:text-ink disabled:cursor-not-allowed disabled:border-line disabled:text-ink-faint/60"
              >
                <MinusIcon className="h-4 w-4" aria-hidden="true" />
              </button>
              <span
                aria-live="polite"
                className="w-7 text-center text-[13px] font-semibold tabular-nums text-ink"
              >
                {count}
              </span>
              <button
                type="button"
                onClick={() => onChange({ ...travelers, [category.id]: Math.min(9, count + 1) })}
                aria-label={`Ajouter un ${category.label}`}
                className="flex h-9 w-9 items-center justify-center rounded-full border border-line text-ink-soft transition-colors duration-150 ease-out hover:border-line-strong hover:text-ink"
              >
                <PlusIcon className="h-4 w-4" aria-hidden="true" />
              </button>
            </div>
          </li>
        )
      })}
    </ul>
  )
}
