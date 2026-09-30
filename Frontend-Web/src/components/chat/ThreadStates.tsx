import React from 'react'
import { RefreshCwIcon } from 'lucide-react'
import { useTrip } from '../../contexts/TripContext'
import { useLanguage } from '../../contexts/LanguageContext'
import type { QuickReply } from '../../types/trip'

export function TypingIndicator() {
  const { t } = useLanguage()
  return (
    <div
      className="flex w-fit items-center gap-1.5 rounded-2xl rounded-bl-md border border-line bg-surface px-4 py-3"
      role="status"
      aria-label={t.errorNotice.message}
    >
      {[0, 1, 2].map((index) => (
        <span
          key={index}
          className="veyn-dot h-1.5 w-1.5 rounded-full bg-ink-faint"
          style={{ animationDelay: `${index * 0.15}s` }}
        />
      ))}
    </div>
  )
}

export function ResultSkeletons() {
  return (
    <div className="space-y-2" role="status" aria-hidden="true">
      {[0, 1, 2].map((index) => (
        <div key={index} className="rounded-xl border border-line bg-surface p-4">
          <div className="flex items-center gap-3">
            <div className="h-4 w-32 animate-pulse rounded bg-surface-sunken" />
            <div className="h-3 w-24 animate-pulse rounded bg-surface-sunken" />
            <div className="ml-auto h-5 w-16 animate-pulse rounded bg-surface-sunken" />
          </div>
          <div className="mt-3 h-3 w-40 animate-pulse rounded bg-surface-sunken" />
        </div>
      ))}
    </div>
  )
}

export function QuickReplyRow({
  replies,
  onPick,
}: {
  replies: QuickReply[]
  onPick: (value: string) => void
}) {
  if (replies.length === 0) return null

  return (
    <div className="flex flex-wrap gap-1.5">
      {replies.map((reply) => (
        <button
          key={reply.label}
          type="button"
          onClick={() => onPick(reply.value)}
          className="rounded-full border border-line bg-surface px-3.5 py-2 text-xs font-medium text-ink-soft transition-colors duration-150 ease-out hover:border-ink/30 hover:text-ink"
        >
          {reply.label}
        </button>
      ))}
    </div>
  )
}

export function NoResultsActions({ onPick }: { onPick: (value: string) => void }) {
  const { openPanel } = useTrip()
  const { t } = useLanguage()

  return (
    <div className="flex flex-wrap gap-1.5">
      <button
        type="button"
        onClick={() => openPanel('date')}
        className="rounded-full border border-line bg-surface px-3.5 py-2 text-xs font-medium text-ink-soft transition-colors duration-150 ease-out hover:border-ink/30 hover:text-ink"
      >
        {t.noResults.tryTomorrow}
      </button>
      <button
        type="button"
        onClick={() => openPanel('budget')}
        className="rounded-full border border-line bg-surface px-3.5 py-2 text-xs font-medium text-ink-soft transition-colors duration-150 ease-out hover:border-ink/30 hover:text-ink"
      >
        {t.noResults.removeBudget}
      </button>
      <button
        type="button"
        onClick={() => onPick(t.noResults.removeAllModesMsg)}
        className="rounded-full border border-line bg-surface px-3.5 py-2 text-xs font-medium text-ink-soft transition-colors duration-150 ease-out hover:border-ink/30 hover:text-ink"
      >
        {t.noResults.removeMode}
      </button>
    </div>
  )
}

export function ErrorNotice({ onRetry }: { onRetry: () => void }) {
  const { t } = useLanguage()
  return (
    <button
      type="button"
      onClick={onRetry}
      className="flex items-center gap-2 rounded-full border border-accent-border bg-accent-soft px-3.5 py-2 text-xs font-semibold text-accent transition-colors duration-150 ease-out hover:bg-accent-border/40"
    >
      <RefreshCwIcon className="h-3.5 w-3.5" aria-hidden="true" />
      {t.errorNotice.retry}
    </button>
  )
}
