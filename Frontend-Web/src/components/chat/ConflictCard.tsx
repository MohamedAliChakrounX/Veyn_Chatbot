import React from 'react'
import { AlertCircleIcon } from 'lucide-react'
import type { TripConflict } from '../../types/trip'
import { useLanguage } from '../../contexts/LanguageContext'

interface ConflictCardProps {
  conflict: TripConflict
  onResolve: (useProposed: boolean) => void
}

export function ConflictCard({ conflict, onResolve }: ConflictCardProps) {
  const { t } = useLanguage()

  return (
    <div className="rounded-xl border border-accent-border bg-accent-soft p-4">
      <p className="flex items-start gap-2 text-[13px] font-medium text-ink">
        <AlertCircleIcon className="mt-0.5 h-4 w-4 shrink-0 text-accent" aria-hidden="true" />
        {conflict.question}
      </p>
      <div className="mt-3 flex flex-wrap gap-2">
        <button
          type="button"
          onClick={() => onResolve(false)}
          className="rounded-full border border-line bg-surface px-4 py-2 text-xs font-semibold text-ink transition-colors duration-150 ease-out hover:border-line-strong"
        >
          {t.conflicts.keepCurrent} : {conflict.currentLabel}
        </button>
        <button
          type="button"
          onClick={() => onResolve(true)}
          className="rounded-full bg-accent px-4 py-2 text-xs font-semibold text-white transition-colors duration-150 ease-out hover:bg-accent-hover"
        >
          {t.conflicts.updateTo} : {conflict.proposedLabel}
        </button>
      </div>
    </div>
  )
}
