import React, { useEffect, useMemo, useState } from 'react'
import { AnimatePresence, motion } from 'framer-motion'
import { format, isToday, isYesterday, parseISO } from 'date-fns'
import { ar, enUS, fr } from 'date-fns/locale'
import {
  CheckCircle2Icon,
  PlusIcon,
  SearchIcon,
  Trash2Icon,
  XIcon,
  Bus,
  Car,
  Train,
  Plane,
  Ship,
  Compass,
} from 'lucide-react'
import { useHistory } from '../../contexts/HistoryContext'
import { useLanguage } from '../../contexts/LanguageContext'
import { normalize } from '../../data/locations'
import type { Conversation, TransportMode } from '../../types/trip'

interface HistoryDrawerProps {
  open: boolean
  currentConversationId: string
  onClose: () => void
  onOpenConversation: (conversation: Conversation) => void
  onNewConversation: () => void
}

export function HistoryDrawer({
  open,
  currentConversationId,
  onClose,
  onOpenConversation,
  onNewConversation,
}: HistoryDrawerProps) {
  const { conversations, removeConversation, clearHistory } = useHistory()
  const { t, language, isRTL } = useLanguage()
  const [query, setQuery] = useState('')
  const [confirmClearOpen, setConfirmClearOpen] = useState(false)

  useEffect(() => {
    if (!open) return
    const onKeyDown = (event: KeyboardEvent) => {
      if (event.key === 'Escape') {
        if (confirmClearOpen) {
          setConfirmClearOpen(false)
        } else {
          onClose()
        }
      }
    }
    document.addEventListener('keydown', onKeyDown)
    return () => document.removeEventListener('keydown', onKeyDown)
  }, [open, onClose, confirmClearOpen])

  const dateLocale = language === 'ar' ? ar : language === 'en' ? enUS : fr

  const getGroupLabel = (iso: string): string => {
    try {
      const date = parseISO(iso)
      if (isToday(date)) return t.history.today
      if (isYesterday(date)) return t.history.yesterday
      return format(date, 'd MMMM yyyy', { locale: dateLocale })
    } catch {
      return t.history.older
    }
  }

  const detectTransportMode = (conv: Conversation): TransportMode | null => {
    if (conv.trip.modes && conv.trip.modes.length > 0) return conv.trip.modes[0]
    for (const m of conv.messages) {
      if (m.booking?.result?.mode) return m.booking.result.mode
      if (m.results && m.results.length > 0) return m.results[0].mode
    }
    const text = `${conv.title} ${conv.routeLabel ?? ''}`.toLowerCase()
    if (text.includes('louage') || text.includes('taxi') || text.includes('shared')) return 'shared_taxi'
    if (text.includes('bus') || text.includes('حافلة')) return 'bus'
    if (text.includes('train') || text.includes('قطار')) return 'train'
    if (text.includes('avion') || text.includes('vol') || text.includes('flight') || text.includes('طائرة')) return 'plane'
    if (text.includes('ferry') || text.includes('bateau') || text.includes('عبارة')) return 'ferry'
    return null
  }

  const getModeIcon = (mode: TransportMode | null) => {
    switch (mode) {
      case 'bus':
        return Bus
      case 'shared_taxi':
        return Car
      case 'train':
        return Train
      case 'plane':
        return Plane
      case 'ferry':
        return Ship
      default:
        return Compass
    }
  }

  const detectPrice = (conv: Conversation): string | null => {
    for (const m of conv.messages) {
      if (m.booking?.result) {
        return `${m.booking.result.price} ${m.booking.result.currency}`
      }
      if (m.results && m.results.length > 0) {
        return `${m.results[0].price} ${m.results[0].currency}`
      }
    }
    if (conv.trip.budget !== null && conv.trip.budget !== undefined) {
      return `≤ ${conv.trip.budget} DT`
    }
    return null
  }

  const groups = useMemo(() => {
    const term = normalize(query)
    const filtered = term
      ? conversations.filter((entry) =>
          normalize(`${entry.title} ${entry.routeLabel ?? ''}`).includes(term),
        )
      : conversations
    const buckets = new Map<string, Conversation[]>()
    for (const entry of filtered) {
      const label = getGroupLabel(entry.updatedAt)
      buckets.set(label, [...(buckets.get(label) ?? []), entry])
    }
    return [...buckets.entries()]
  }, [conversations, query, t, language])

  const initialX = isRTL ? -32 : 32

  return (
    <AnimatePresence>
      {open ? (
        <div
          className={`fixed inset-0 z-40 flex ${isRTL ? 'justify-start' : 'justify-end'}`}
          role="dialog"
          aria-label={t.history.title}
        >
          <motion.button
            type="button"
            aria-label={t.common.close}
            onClick={onClose}
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            transition={{ duration: 0.2, ease: [0.23, 1, 0.32, 1] }}
            className="absolute inset-0 cursor-default bg-ink/25 backdrop-blur-xs"
          />
          <motion.aside
            initial={{ x: initialX, opacity: 0 }}
            animate={{ x: 0, opacity: 1 }}
            exit={{ x: initialX, opacity: 0 }}
            transition={{ duration: 0.24, ease: [0.23, 1, 0.32, 1] }}
            className={`relative flex h-full w-full max-w-sm flex-col bg-surface shadow-drawer ${
              isRTL ? 'border-e border-line' : 'border-s border-line'
            }`}
          >
            {/* Header */}
            <div className="flex items-center gap-3 border-b border-line px-4 py-3">
              <h2 className="text-sm font-semibold text-ink">{t.history.title}</h2>
              <span className="text-xs text-ink-faint tabular-nums">{conversations.length}</span>
              <button
                type="button"
                onClick={onClose}
                aria-label={t.common.close}
                className="ms-auto flex h-8 w-8 items-center justify-center rounded-full text-ink-muted transition-colors duration-150 ease-out hover:bg-surface-sunken hover:text-ink"
              >
                <XIcon className="h-4 w-4" aria-hidden="true" />
              </button>
            </div>

            {/* Actions: New Search + Search filter */}
            <div className="space-y-2 border-b border-line px-4 py-3">
              <button
                type="button"
                onClick={() => {
                  onNewConversation()
                  onClose()
                }}
                className="flex w-full items-center justify-center gap-2 rounded-full bg-accent px-4 py-2.5 text-xs font-semibold text-white transition-colors duration-150 ease-out hover:bg-accent-hover shadow-xs"
              >
                <PlusIcon className="h-4 w-4" aria-hidden="true" />
                {t.header.newSearch}
              </button>
              <div className="relative">
                <SearchIcon
                  className={`pointer-events-none absolute top-1/2 h-4 w-4 -translate-y-1/2 text-ink-faint ${isRTL ? 'right-3' : 'left-3'}`}
                  aria-hidden="true"
                />
                <input
                  type="search"
                  value={query}
                  onChange={(event) => setQuery(event.target.value)}
                  placeholder={t.history.searchPlaceholder}
                  aria-label={t.history.searchPlaceholder}
                  className={`w-full rounded-xl border border-line bg-surface-sunken py-2 text-xs text-ink placeholder:text-ink-faint focus:border-accent focus:outline-none focus:ring-1 focus:ring-accent ${
                    isRTL ? 'pr-9 pl-3' : 'pl-9 pr-3'
                  }`}
                />
              </div>
            </div>

            {/* Conversations list */}
            <div className="veyn-scroll flex-1 overflow-y-auto px-4 py-3">
              {conversations.length === 0 ? (
                <div className="px-1 py-8 text-start">
                  <p className="text-xs font-semibold text-ink">{t.history.empty}</p>
                  <p className="mt-1 text-[11px] leading-relaxed text-ink-muted">{t.history.emptyDesc}</p>
                </div>
              ) : groups.length === 0 ? (
                <p className="px-1 py-6 text-start text-xs text-ink-muted">
                  {`${t.history.noResultsFor} « ${query} »`}
                </p>
              ) : (
                <div className="space-y-5">
                  {groups.map(([label, entries]) => (
                    <section key={label}>
                      <h3 className="px-1 pb-2 text-[11px] font-bold text-ink-faint text-start">{label}</h3>
                      <ul className="space-y-1.5">
                        {entries.map((entry) => {
                          const active = entry.id === currentConversationId
                          const mode = detectTransportMode(entry)
                          const ModeIcon = getModeIcon(mode)
                          const priceStr = detectPrice(entry)

                          return (
                            <li key={entry.id}>
                              <div
                                className={`group flex items-start gap-2 rounded-xl border px-3 py-2.5 transition-colors duration-150 ease-out ${
                                  active
                                    ? 'border-accent/40 bg-accent-soft/30'
                                    : 'border-line bg-surface hover:border-line-strong'
                                }`}
                              >
                                <button
                                  type="button"
                                  onClick={() => {
                                    onOpenConversation(entry)
                                    onClose()
                                  }}
                                  className="min-w-0 flex-1 text-start"
                                >
                                  <div className="flex items-center gap-1.5">
                                    <div className="flex h-5 w-5 shrink-0 items-center justify-center rounded-md bg-surface-sunken text-accent">
                                      <ModeIcon className="h-3 w-3" />
                                    </div>
                                    {entry.routeLabel ? (
                                      <p className="truncate text-xs font-bold text-ink">
                                        {entry.routeLabel}
                                      </p>
                                    ) : null}
                                  </div>

                                  <p
                                    className={`line-clamp-2 text-xs ${
                                      entry.routeLabel ? 'mt-1 text-ink-muted' : 'font-semibold text-ink'
                                    }`}
                                  >
                                    {entry.title}
                                  </p>

                                  <div className="mt-1.5 flex flex-wrap items-center gap-2 text-[10px] text-ink-faint">
                                    <span className="tabular-nums">
                                      {format(parseISO(entry.updatedAt), 'HH:mm')}
                                    </span>
                                    {entry.resultCount > 0 ? (
                                      <span className="tabular-nums font-medium">
                                        {entry.resultCount} {t.history.tripsLabel}
                                      </span>
                                    ) : null}
                                    {priceStr && (
                                      <span className="rounded bg-surface-sunken px-1.5 py-0.5 font-bold text-ink-soft">
                                        {priceStr}
                                      </span>
                                    )}
                                    {entry.bookingCount > 0 ? (
                                      <span className="flex items-center gap-1 font-bold text-emerald-600">
                                        <CheckCircle2Icon className="h-3 w-3" aria-hidden="true" />
                                        {t.history.bookedLabel}
                                      </span>
                                    ) : null}
                                  </div>
                                </button>
                                <button
                                  type="button"
                                  onClick={() => removeConversation(entry.id)}
                                  aria-label={`${t.history.deletePrompt} ${entry.title}`}
                                  className="flex h-7 w-7 shrink-0 items-center justify-center rounded-lg text-ink-faint transition-colors duration-150 ease-out hover:bg-rose-50 hover:text-rose-600"
                                >
                                  <Trash2Icon className="h-3.5 w-3.5" aria-hidden="true" />
                                </button>
                              </div>
                            </li>
                          )
                        })}
                      </ul>
                    </section>
                  ))}
                </div>
              )}
            </div>

            {/* Clear All Footer */}
            {conversations.length > 0 ? (
              <div className="border-t border-line px-4 py-3">
                <button
                  type="button"
                  onClick={() => setConfirmClearOpen(true)}
                  className="text-xs font-semibold text-ink-muted transition-colors duration-150 ease-out hover:text-rose-600"
                >
                  {t.history.clearAll}
                </button>
              </div>
            ) : null}

            {/* Confirmation Dialog for Clear All */}
            <AnimatePresence>
              {confirmClearOpen && (
                <div className="absolute inset-0 z-50 flex items-center justify-center p-4 bg-ink/40 backdrop-blur-xs">
                  <motion.div
                    initial={{ opacity: 0, scale: 0.95 }}
                    animate={{ opacity: 1, scale: 1 }}
                    exit={{ opacity: 0, scale: 0.95 }}
                    className="w-full max-w-xs rounded-2xl border border-line bg-surface p-4 shadow-xl"
                  >
                    <h4 className="text-xs font-bold text-ink">{t.history.clearAll}</h4>
                    <p className="mt-2 text-xs leading-relaxed text-ink-muted">
                      {t.history.clearHistoryConfirm}
                    </p>
                    <div className="mt-4 flex items-center justify-end gap-2">
                      <button
                        type="button"
                        onClick={() => setConfirmClearOpen(false)}
                        className="rounded-xl px-3 py-1.5 text-xs font-medium text-ink-muted hover:bg-surface-sunken hover:text-ink"
                      >
                        {t.common.cancel}
                      </button>
                      <button
                        type="button"
                        onClick={() => {
                          clearHistory()
                          setConfirmClearOpen(false)
                        }}
                        className="rounded-xl bg-rose-600 px-3.5 py-1.5 text-xs font-semibold text-white shadow-xs hover:bg-rose-700"
                      >
                        {t.history.clearAll}
                      </button>
                    </div>
                  </motion.div>
                </div>
              )}
            </AnimatePresence>
          </motion.aside>
        </div>
      ) : null}
    </AnimatePresence>
  )
}
