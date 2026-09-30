import React, { useState } from 'react'
import { AnimatePresence } from 'framer-motion'
import { useChat } from '../hooks/useChat'
import { useHistory } from '../contexts/HistoryContext'
import { useTrip } from '../contexts/TripContext'
import { useLanguage } from '../contexts/LanguageContext'
import { localizeCityName } from '../data/locations'
import { ChatHeader } from '../components/chat/ChatHeader'
import { Thread } from '../components/chat/Thread'
import { Composer } from '../components/chat/Composer'
import { HistoryDrawer } from '../components/chat/HistoryDrawer'
import { BookingDialog } from '../components/chat/BookingDialog'
import type { TripResult } from '../types/trip'

export function Chat() {
  const {
    messages,
    status,
    conversationId,
    send,
    retry,
    resolveConflict,
    confirmBooking,
    startNewConversation,
    openConversation,
  } = useChat()
  const { trip } = useTrip()
  const { language } = useLanguage()
  const { conversations } = useHistory()
  const [historyOpen, setHistoryOpen] = useState(false)
  const [bookingTarget, setBookingTarget] = useState<TripResult | null>(null)

  const handleDashboardSearch = () => {
    const orig = trip.origin ? localizeCityName(trip.origin.name, language) : ''
    const dest = trip.destination ? localizeCityName(trip.destination.name, language) : ''
    const searchPrompt =
      language === 'ar'
        ? `ابحث عن رحلات من ${orig} إلى ${dest}`
        : language === 'en'
          ? `Search trips from ${orig} to ${dest}`
          : `Recherche de trajets de ${orig} à ${dest}`
    send(searchPrompt)
  }

  return (
    <main className="flex h-full min-h-full w-full flex-col bg-surface-sunken">
      <ChatHeader
        onOpenHistory={() => setHistoryOpen(true)}
        onNewConversation={startNewConversation}
        historyCount={conversations.length}
      />
      <Thread
        messages={messages}
        status={status}
        onSend={send}
        onRetry={retry}
        onResolveConflict={resolveConflict}
        onBook={setBookingTarget}
      />
      <Composer
        onSend={send}
        onDashboardSearch={handleDashboardSearch}
        busy={status !== 'idle'}
      />
      <HistoryDrawer
        open={historyOpen}
        currentConversationId={conversationId}
        onClose={() => setHistoryOpen(false)}
        onOpenConversation={openConversation}
        onNewConversation={startNewConversation}
      />
      <AnimatePresence>
        {bookingTarget ? (
          <BookingDialog
            result={bookingTarget}
            onClose={() => setBookingTarget(null)}
            onConfirm={confirmBooking}
          />
        ) : null}
      </AnimatePresence>
    </main>
  )
}
export default Chat
