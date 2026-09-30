import { useCallback, useEffect, useRef, useState } from 'react'
import { useTrip } from '../contexts/TripContext'
import { useHistory } from '../contexts/HistoryContext'
import { useLanguage } from '../contexts/LanguageContext'
import { sendToAssistant } from '../utils/assistant'
import { apiService } from '../utils/apiService'
import { isTripEmpty, routeLabel, tripChips } from '../utils/trip'
import type { Language } from '../i18n/translations'
import type {
  BookingSummary,
  ChatMessage,
  Conversation,
  TripConflict,
  TripPrecisionItem,
  TripQuery,
} from '../types/trip'

export type ChatStatus = 'idle' | 'thinking' | 'searching'

function makeWelcomeMessage(lang: Language): ChatMessage {
  let text = 'Bonjour 👋 Je suis l’assistant Veyn connecté en temps réel aux trajets et tarifs réels (Tunisie, Algérie, Libye, Égypte). Décrivez votre voyage ou utilisez le bouton « + » pour affiner vos critères.'
  if (lang === 'ar') {
    text = 'مرحباً بك 👋 أنا المساعد الذكي لشبكة Veyn للنقل، متصل لحظياً ببيانات الرحلات والأسعار الحية (تونس، الجزائر، ليبيا، مصر). تفضل بكتابة تفاصيل رحلتك أو اضغط على « + » لتحديد خياراتك.'
  } else if (lang === 'en') {
    text = 'Hello 👋 I am the Veyn transport assistant connected in real time to live schedules and fares (Tunisia, Algeria, Libya, Egypt). Describe your trip or click "+" to set your criteria.'
  }
  return {
    id: 'welcome',
    role: 'assistant',
    text,
  }
}

let counter = 0
function nextId(prefix: string): string {
  counter += 1
  return `${prefix}-${Date.now().toString(36)}-${counter}`
}

function conversationTitle(messages: ChatMessage[], lang: Language = 'fr'): string {
  const firstUser = messages.find((message) => message.role === 'user')
  if (!firstUser) {
    return lang === 'ar' ? 'بحث جديد' : lang === 'en' ? 'New search' : 'Nouvelle recherche'
  }
  return firstUser.text.length > 72 ? `${firstUser.text.slice(0, 72)}…` : firstUser.text
}

export function useChat() {
  const { trip, patchTrip, replaceTrip, resetTrip } = useTrip()
  const { saveConversation } = useHistory()
  const { language } = useLanguage()
  const [messages, setMessages] = useState<ChatMessage[]>(() => [makeWelcomeMessage(language)])
  const [status, setStatus] = useState<ChatStatus>('idle')
  const [conversationId, setConversationId] = useState<string>(() => nextId('conv'))
  const tripRef = useRef<TripQuery>(trip)
  tripRef.current = trip

  // Si la seule conversation est le message de bienvenue, actualiser sa langue lors du switch
  useEffect(() => {
    setMessages((current) => {
      if (current.length === 1 && current[0].id === 'welcome') {
        return [makeWelcomeMessage(language)]
      }
      return current
    })
  }, [language])

  /** Sauvegarde automatique dès qu'un échange existe. */
  useEffect(() => {
    if (messages.length <= 1) return
    const conversation: Conversation = {
      id: conversationId,
      title: conversationTitle(messages, language),
      routeLabel: routeLabel(trip, language),
      updatedAt: new Date().toISOString(),
      messages,
      trip,
      resultCount: messages.reduce((total, message) => total + (message.results?.length ?? 0), 0),
      bookingCount: messages.filter((message) => message.booking).length,
    }
    saveConversation(conversation)
  }, [messages, trip, conversationId, saveConversation, language])

  const run = useCallback(
    async (history: ChatMessage[], userMessageId: string) => {
      setStatus('thinking')
      try {
        const response = await sendToAssistant(history, tripRef.current, {
          onSearching: () => setStatus('searching'),
          language,
        })

        if (response.tripPatch) patchTrip(response.tripPatch)

        const assistantMessage: ChatMessage = {
          id: nextId('assistant'),
          role: 'assistant',
          text: response.reply,
          results: response.results,
          conflict: response.conflict,
          quickReplies: response.quickReplies,
          noResults: response.noResults,
        }

        setMessages((current) => [
          ...current.map((message) =>
            message.id === userMessageId && (response.recognized?.length ?? 0) > 0
              ? { ...message, chipFields: response.recognized }
              : message,
          ),
          assistantMessage,
        ])
      } catch (err) {
        console.error('Chat error:', err)
        const errorText =
          language === 'ar'
            ? 'حدث خطأ أثناء الاتصال بالمساعد. تم الاحتفاظ بجميع خيارات رحلتكم.'
            : language === 'en'
              ? 'A connection issue occurred with the assistant. Your selections have been saved.'
              : 'La connexion à l’assistant a rencontré une difficulté. Vos critères sont conservés.'
        setMessages((current) => [
          ...current,
          {
            id: nextId('error'),
            role: 'assistant',
            text: errorText,
            isError: true,
          },
        ])
      } finally {
        setStatus('idle')
      }
    },
    [patchTrip, language],
  )

  const send = useCallback(
    (raw: string) => {
      const defaultSearchPrompt =
        language === 'ar'
          ? 'البحث بهذه المعلومات.'
          : language === 'en'
            ? 'Search with this information.'
            : 'Rechercher avec ces informations.'
      const text = raw.trim() || (isTripEmpty(tripRef.current) ? '' : defaultSearchPrompt)
      if (!text || status !== 'idle') return

      // Capturer un snapshot immuable de l'état du trajet au moment de l'envoi
      const querySnapshot: TripQuery = { ...tripRef.current }
      const precisions: TripPrecisionItem[] = tripChips(querySnapshot, language).map((c) => ({
        field: c.field,
        label: c.label,
      }))

      const userMessage: ChatMessage = {
        id: nextId('user'),
        role: 'user',
        text,
        precisions,
        querySnapshot,
      }
      const history = [...messages, userMessage]
      setMessages(history)
      void run(history, userMessage.id)
    },
    [messages, run, status, language],
  )

  const retry = useCallback(() => {
    if (status !== 'idle') return
    const withoutError = messages.filter((message) => !message.isError)
    const lastUser = [...withoutError].reverse().find((message) => message.role === 'user')
    if (!lastUser) return
    setMessages(withoutError)
    void run(withoutError, lastUser.id)
  }, [messages, run, status])

  const resolveConflict = useCallback(
    (messageId: string, conflict: TripConflict, useProposed: boolean) => {
      if (useProposed) patchTrip(conflict.proposed)
      const arrow = language === 'ar' ? ' ← ' : ' → '
      const chosenLabel = useProposed ? conflict.proposedLabel : conflict.currentLabel
      const suffix =
        language === 'ar'
          ? `تم اعتماد ${chosenLabel}.`
          : language === 'en'
            ? `${chosenLabel} retained.`
            : `${chosenLabel} retenu.`

      setMessages((current) =>
        current.map((message) =>
          message.id === messageId
            ? {
                ...message,
                conflict: undefined,
                text: `${message.text}${arrow}${suffix}`,
              }
            : message,
        ),
      )
    },
    [patchTrip, language],
  )

  /** Ajoute le récapitulatif de réservation au fil de discussion et vide les précisions. */
  const confirmBooking = useCallback(
    (booking: BookingSummary) => {
      void apiService.bookTrip(booking)
      resetTrip()
      const text =
        language === 'ar'
          ? `تم تأكيد الحجز بنجاح · رقم الحجز ${booking.reference} · ${booking.routeLabel}.`
          : language === 'en'
            ? `Booking confirmed successfully · reference ${booking.reference} · ${booking.routeLabel}.`
            : `Réservation effectuée avec succès · référence ${booking.reference} · ${booking.routeLabel}.`

      setMessages((current) => [
        ...current,
        {
          id: nextId('booking'),
          role: 'assistant',
          text,
          booking,
        },
      ])
    },
    [resetTrip, language],
  )

  const startNewConversation = useCallback(() => {
    setMessages([makeWelcomeMessage(language)])
    setStatus('idle')
    setConversationId(nextId('conv'))
    resetTrip()
  }, [resetTrip, language])

  const openConversation = useCallback(
    (conversation: Conversation) => {
      setStatus('idle')
      setConversationId(conversation.id)
      setMessages(conversation.messages.length > 0 ? conversation.messages : [makeWelcomeMessage(language)])
      replaceTrip(conversation.trip)
    },
    [replaceTrip, language],
  )

  return {
    messages,
    status,
    conversationId,
    send,
    retry,
    resolveConflict,
    confirmBooking,
    startNewConversation,
    openConversation,
  }
}
