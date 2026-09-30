import React, { createContext, useCallback, useContext, useEffect, useMemo, useState } from 'react'
import type { Conversation } from '../types/trip'

const STORAGE_KEY = 'veyn-history-v1'

interface HistoryContextValue {
  conversations: Conversation[]
  /** Crée ou met à jour une conversation dans l'historique. */
  saveConversation: (conversation: Conversation) => void
  removeConversation: (id: string) => void
  clearHistory: () => void
}

const HistoryContext = createContext<HistoryContextValue | null>(null)

function readStorage(): Conversation[] {
  if (typeof window === 'undefined') return []
  try {
    const raw = window.localStorage.getItem(STORAGE_KEY)
    if (!raw) return []
    const parsed = JSON.parse(raw) as Conversation[]
    return Array.isArray(parsed) ? parsed : []
  } catch {
    return []
  }
}

export function HistoryProvider({ children }: { children: React.ReactNode }) {
  const [conversations, setConversations] = useState<Conversation[]>(readStorage)

  useEffect(() => {
    try {
      window.localStorage.setItem(STORAGE_KEY, JSON.stringify(conversations.slice(0, 40)))
    } catch {
      /* stockage indisponible : l'historique reste en mémoire */
    }
  }, [conversations])

  const saveConversation = useCallback((conversation: Conversation) => {
    setConversations((current) => {
      const others = current.filter((entry) => entry.id !== conversation.id)
      return [conversation, ...others].sort((a, b) => b.updatedAt.localeCompare(a.updatedAt))
    })
  }, [])

  const removeConversation = useCallback((id: string) => {
    setConversations((current) => current.filter((entry) => entry.id !== id))
  }, [])

  const clearHistory = useCallback(() => setConversations([]), [])

  const value = useMemo<HistoryContextValue>(
    () => ({ conversations, saveConversation, removeConversation, clearHistory }),
    [conversations, saveConversation, removeConversation, clearHistory],
  )

  return <HistoryContext.Provider value={value}>{children}</HistoryContext.Provider>
}

export function useHistory(): HistoryContextValue {
  const context = useContext(HistoryContext)
  if (!context) throw new Error('useHistory doit être utilisé dans un HistoryProvider')
  return context
}
