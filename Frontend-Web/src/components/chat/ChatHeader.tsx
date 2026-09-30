import React, { useState, useEffect } from 'react'
import { HistoryIcon, PlusIcon, Server } from 'lucide-react'
import { LanguageSelector } from '../common/LanguageSelector'
import { useLanguage } from '../../contexts/LanguageContext'
import { apiService } from '../../utils/apiService'
import { ServerConfigModal } from './ServerConfigModal'

interface ChatHeaderProps {
  onOpenHistory: () => void
  onNewConversation: () => void
  historyCount: number
}

export function ChatHeader({ onOpenHistory, onNewConversation, historyCount }: ChatHeaderProps) {
  const { t } = useLanguage()
  const [serverOnline, setServerOnline] = useState<boolean>(true)
  const [configModalOpen, setConfigModalOpen] = useState(false)

  const checkStatus = async () => {
    const ok = await apiService.checkHealth()
    setServerOnline(ok)
  }

  useEffect(() => {
    checkStatus()
    const interval = setInterval(checkStatus, 20000)
    return () => clearInterval(interval)
  }, [])

  return (
    <>
      <header className="flex items-center gap-2 border-b border-line bg-surface/90 px-3 py-2 backdrop-blur sm:gap-3 sm:px-6 sm:py-2.5">
        <button
          type="button"
          onClick={onNewConversation}
          className="flex items-center gap-1.5 focus:outline-none"
        >
          <img
            src="https://cdn.magicpatterns.com/uploads/9bXDdrgnnoL9KwUVE4fnE3/logo_veyn.png"
            alt="veyn"
            className="h-6 w-auto shrink-0 sm:h-7"
            onError={(e) => {
              // Fallback if network image fails
              (e.target as HTMLImageElement).src = 'https://cdn.magicpatterns.com/uploads/1E6qzds7Pp2vm6cTufALvh/logo_veyn.png'
            }}
          />
        </button>

        <div className="hidden h-5 w-px bg-line sm:block" aria-hidden="true" />
        <p className="hidden truncate text-xs text-ink-muted sm:block">
          {t.header.subtitle}
        </p>

        <div className="ms-auto flex shrink-0 items-center gap-1.5 sm:gap-2">
          {/* Server status pill */}
          <button
            type="button"
            onClick={() => setConfigModalOpen(true)}
            title={t.serverConfig.serverConfigTooltip}
            className="flex items-center gap-1.5 rounded-full border border-line bg-surface-sunken px-2.5 py-1.5 text-xs text-ink-muted hover:border-line-strong hover:text-ink transition"
          >
            <span
              className={`h-2 w-2 rounded-full ${
                serverOnline ? 'bg-emerald-500 shadow-xs' : 'bg-rose-500'
              }`}
            />
            <Server className="h-3.5 w-3.5" />
          </button>

          {/* Language Selector */}
          <LanguageSelector />

          {/* New Search Button */}
          <button
            type="button"
            onClick={onNewConversation}
            title={t.header.newSearch}
            className="flex items-center gap-1.5 rounded-full border border-line bg-surface px-2.5 py-1.5 text-xs font-medium text-ink-soft transition-colors duration-150 ease-out hover:border-line-strong hover:text-ink sm:gap-2 sm:px-3 sm:py-2"
          >
            <PlusIcon className="h-3.5 w-3.5" aria-hidden="true" />
            <span className="hidden sm:inline">{t.header.newSearch}</span>
          </button>

          {/* History Button with count badge */}
          <button
            type="button"
            onClick={onOpenHistory}
            aria-label={t.header.history}
            title={t.header.history}
            className="flex items-center gap-1.5 rounded-full border border-line bg-surface px-2.5 py-1.5 text-xs font-medium text-ink-soft transition-colors duration-150 ease-out hover:border-line-strong hover:text-ink sm:gap-2 sm:px-3 sm:py-2"
          >
            <HistoryIcon className="h-3.5 w-3.5" aria-hidden="true" />
            <span className="hidden sm:inline">{t.header.history}</span>
            {historyCount > 0 ? (
              <span className="flex h-4 min-w-[1rem] items-center justify-center rounded-full bg-ink px-1 text-[10px] font-bold tabular-nums text-white">
                {historyCount}
              </span>
            ) : null}
          </button>
        </div>
      </header>

      {/* Server Config Modal */}
      <ServerConfigModal
        open={configModalOpen}
        onClose={() => setConfigModalOpen(false)}
        onSaved={checkStatus}
      />
    </>
  )
}
