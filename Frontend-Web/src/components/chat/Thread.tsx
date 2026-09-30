import React, { useEffect, useRef } from 'react'
import { motion } from 'framer-motion'
import { useLanguage } from '../../contexts/LanguageContext'
import type { ChatMessage, TripConflict, TripPrecisionItem, TripResult } from '../../types/trip'
import type { ChatStatus } from '../../hooks/useChat'
import { MessageBubble } from './MessageBubble'
import { FrozenPrecisionsChips } from './FrozenPrecisionsChips'
import { ResultCard, groupTripsByStops } from './ResultCard'
import { ConflictCard } from './ConflictCard'
import { BookingCard } from './BookingCard'
import {
  ErrorNotice,
  NoResultsActions,
  QuickReplyRow,
  ResultSkeletons,
  TypingIndicator,
} from './ThreadStates'

interface ThreadProps {
  messages: ChatMessage[]
  status: ChatStatus
  onSend: (value: string) => void
  onRetry: () => void
  onResolveConflict: (messageId: string, conflict: TripConflict, useProposed: boolean) => void
  onBook: (result: TripResult) => void
}

export function Thread({
  messages,
  status,
  onSend,
  onRetry,
  onResolveConflict,
  onBook,
}: ThreadProps) {
  const endRef = useRef<HTMLDivElement>(null)
  const { t, language, isRTL } = useLanguage()

  useEffect(() => {
    endRef.current?.scrollIntoView({ behavior: 'smooth', block: 'end' })
  }, [messages, status])

  const showSuggestions = messages.length === 1 && status === 'idle'

  const suggestions = [
    t.suggestions.q1,
    t.suggestions.q2,
    t.suggestions.q3,
    t.suggestions.q4,
  ]

  const getMessageText = (message: ChatMessage) => {
    if (message.id === 'welcome' || message.id === 'msg-welcome') {
      if (language === 'ar') {
        return 'مرحباً بك ! إلى أين ترغب في السفر اليوم؟'
      }
      if (language === 'en') {
        return 'Hello! Where would you like to travel today?'
      }
      return 'Bonjour ! Où souhaitez-vous voyager aujourd’hui ?'
    }
    return message.text
  }

  return (
    <div className="veyn-scroll flex-1 overflow-y-auto px-3 py-4 sm:px-6 sm:py-6">
      <div className="mx-auto flex w-full max-w-3xl flex-col gap-3">
        {messages.map((message, index) => {
          // Bulle de message — masquée si le message assistant contient des cartes
          // (les cartes suffisent comme réponse, le texte répèterait les mêmes infos)
          const hideBubble =
            message.booking != null ||
            (message.role === 'assistant' && message.results && message.results.length > 0)

          // Résolution des précisions à afficher juste avant les cartes de résultats :
          // Priorité 1 : précisions dans le message assistant
          // Priorité 2 : précisions dans le message utilisateur précédent
          let precisionsBeforeResults: TripPrecisionItem[] = []
          if (message.results && message.results.length > 0) {
            if (message.precisions && message.precisions.length > 0) {
              precisionsBeforeResults = message.precisions
            } else if (
              index > 0 &&
              messages[index - 1].role === 'user' &&
              messages[index - 1].precisions &&
              messages[index - 1].precisions!.length > 0
            ) {
              precisionsBeforeResults = messages[index - 1].precisions!
            }
          }

          return (
            <React.Fragment key={message.id}>
              {!hideBubble && (
                <MessageBubble role={message.role}>{getMessageText(message)}</MessageBubble>
              )}

              {/* Résolution de conflit */}
              {message.conflict ? (
                <div className="w-full max-w-[85%] self-start sm:max-w-[70%]">
                  <ConflictCard
                    conflict={message.conflict}
                    onResolve={(useProposed) =>
                      onResolveConflict(message.id, message.conflict as TripConflict, useProposed)
                    }
                  />
                </div>
              ) : null}

              {/* Réponses rapides */}
              {message.quickReplies && message.quickReplies.length > 0 ? (
                <div className="self-start">
                  <QuickReplyRow replies={message.quickReplies} onPick={onSend} />
                </div>
              ) : null}

              {/* Aucun résultat */}
              {message.noResults ? (
                <div className="self-start">
                  <NoResultsActions onPick={onSend} />
                </div>
              ) : null}

              {/* Notification d'erreur */}
              {message.isError ? (
                <div className="self-start">
                  <ErrorNotice onRetry={onRetry} />
                </div>
              ) : null}

              {/* Carte de réservation confirmée */}
              {message.booking ? (
                <div className="w-full self-start sm:w-[85%]">
                  <BookingCard booking={message.booking} />
                </div>
              ) : null}

              {/* Cartes de trajets — avec précisions figées ambrées juste avant */}
              {message.results && message.results.length > 0 ? (
                <div className="w-full space-y-2.5 self-start sm:w-[85%]">
                  {precisionsBeforeResults.length > 0 && (
                    <div className="pb-1">
                      <FrozenPrecisionsChips precisions={precisionsBeforeResults} />
                    </div>
                  )}

                  <ul className="w-full space-y-3">
                    {groupTripsByStops(message.results).map((group, groupIdx) => (
                      <motion.li
                        key={group.key}
                        initial={{ opacity: 0, y: 8 }}
                        animate={{ opacity: 1, y: 0 }}
                        transition={{
                          duration: 0.2,
                          delay: Math.min(groupIdx * 0.04, 0.16),
                          ease: [0.23, 1, 0.32, 1],
                        }}
                      >
                        <ResultCard trips={group.trips} featured={groupIdx === 0} onBook={onBook} />
                      </motion.li>
                    ))}
                  </ul>
                </div>
              ) : null}
            </React.Fragment>
          )
        })}

        {/* Suggestions initiales */}
        {showSuggestions ? (
          <ul className="flex flex-col gap-1.5 self-start sm:flex-row sm:flex-wrap">
            {suggestions.map((suggestion) => (
              <li key={suggestion}>
                <button
                  type="button"
                  onClick={() => onSend(suggestion)}
                  className="w-full rounded-xl border border-line bg-surface px-3.5 py-2.5 text-start text-xs font-medium text-ink-soft transition-colors duration-150 ease-out hover:border-ink/30 hover:text-ink sm:w-auto sm:max-w-xs"
                >
                  {suggestion}
                </button>
              </li>
            ))}
          </ul>
        ) : null}

        {/* Indicateurs d'état */}
        {status === 'thinking' ? <TypingIndicator /> : null}
        {status === 'searching' ? (
          <div className="w-full self-start sm:w-[85%]">
            <ResultSkeletons />
          </div>
        ) : null}
        <div ref={endRef} />
      </div>
    </div>
  )
}
