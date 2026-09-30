import React, { useRef, useState, useEffect } from 'react'
import { AnimatePresence, motion } from 'framer-motion'
import { ArrowUpIcon, Mic, Trash2, Loader2, Check, Plus } from 'lucide-react'
import { useTrip } from '../../contexts/TripContext'
import { useLanguage } from '../../contexts/LanguageContext'
import { isTripEmpty } from '../../utils/trip'
import { useAudioRecorder } from '../../hooks/useAudioRecorder'
import { TripDashboard } from '../trip/TripDashboard'

interface ComposerProps {
  onSend: (value: string) => void
  onDashboardSearch?: () => void
  busy: boolean
}

function formatTime(seconds: number): string {
  const m = Math.floor(seconds / 60)
  const s = seconds % 60
  return `${m.toString().padStart(2, '0')}:${s.toString().padStart(2, '0')}`
}

export function Composer({ onSend, onDashboardSearch, busy }: ComposerProps) {
  const [value, setValue] = useState('')
  const [dashboardOpen, setDashboardOpen] = useState(false)
  const { trip, closePanel, activePrecisionsCount } = useTrip()
  const { t, isRTL } = useLanguage()
  const inputRef = useRef<HTMLTextAreaElement>(null)
  const menuRef = useRef<HTMLDivElement>(null)
  const buttonRef = useRef<HTMLButtonElement>(null)

  const {
    isRecording,
    recordingTime,
    isTranscribing,
    error: recorderError,
    startRecording,
    stopAndTranscribe,
    cancelRecording,
  } = useAudioRecorder()

  // Fermer le menu lors d'un clic à l'extérieur ou via Échap (sauf si une sous-modale est ouverte)
  useEffect(() => {
    function handleClickOutside(event: MouseEvent) {
      if (
        dashboardOpen &&
        menuRef.current &&
        !menuRef.current.contains(event.target as Node) &&
        buttonRef.current &&
        !buttonRef.current.contains(event.target as Node)
      ) {
        const targetEl = event.target as Element | null
        const isModalClick = targetEl?.closest?.('[role="dialog"]') !== null
        const isSubModalOpen = document.querySelector('[role="dialog"]') !== null
        if (!isSubModalOpen && !isModalClick) {
          setDashboardOpen(false)
        }
      }
    }

    function handleKeyDown(event: KeyboardEvent) {
      if (event.key === 'Escape' && dashboardOpen) {
        const isSubModalOpen = document.querySelector('[role="dialog"]') !== null
        if (!isSubModalOpen) {
          setDashboardOpen(false)
        }
      }
    }

    if (dashboardOpen) {
      document.addEventListener('mousedown', handleClickOutside)
      window.addEventListener('keydown', handleKeyDown)
    }
    return () => {
      document.removeEventListener('mousedown', handleClickOutside)
      window.removeEventListener('keydown', handleKeyDown)
    }
  }, [dashboardOpen])

  const canSend = !busy && !isRecording && !isTranscribing && (value.trim().length > 0 || !isTripEmpty(trip))

  const submit = () => {
    if (!canSend) return
    setDashboardOpen(false)
    onSend(value)
    setValue('')
    closePanel()
    inputRef.current?.focus()
  }

  const handleStopAndSendAudio = async () => {
    setDashboardOpen(false)
    const text = await stopAndTranscribe()
    if (text && text.trim().length > 0) {
      onSend(text.trim())
      closePanel()
    }
  }

  const handleStartRecording = () => {
    setDashboardOpen(false)
    startRecording()
  }

  return (
    <div className="border-t border-line bg-surface-sunken/80 px-4 pb-4 pt-3 backdrop-blur sm:px-6">
      <div className="relative mx-auto w-full max-w-3xl">
        {/* Menu flottant du tableau de bord intégré */}
        <AnimatePresence>
          {dashboardOpen && (
            <motion.div
              ref={menuRef}
              initial={{ opacity: 0, y: 10, scale: 0.98 }}
              animate={{ opacity: 1, y: 0, scale: 1 }}
              exit={{ opacity: 0, y: 10, scale: 0.98 }}
              transition={{ duration: 0.2, ease: [0.16, 1, 0.3, 1] }}
              className="absolute bottom-full left-0 right-0 mb-2 z-30 max-h-[75vh] overflow-y-auto rounded-2xl border border-line bg-surface shadow-2xl backdrop-blur-md"
            >
              <TripDashboard
                isMenu
                onSearch={() => {
                  setDashboardOpen(false)
                  onDashboardSearch?.()
                }}
                onClose={() => setDashboardOpen(false)}
              />
            </motion.div>
          )}
        </AnimatePresence>
        {/* Message d'erreur éventuel du microphone */}
        {recorderError && (
          <div className="mb-2 rounded-lg bg-red-500/10 px-3 py-1.5 text-xs text-red-600 dark:text-red-400">
            {recorderError}
          </div>
        )}

        <div className="relative rounded-2xl border border-line bg-surface p-2 shadow-card focus-within:border-ink/20">
          <AnimatePresence mode="wait">
            {isRecording ? (
              /* Interface d'enregistrement vocal */
              <motion.div
                key="recording-ui"
                initial={{ opacity: 0, y: 5 }}
                animate={{ opacity: 1, y: 0 }}
                exit={{ opacity: 0, y: -5 }}
                className="flex min-h-[44px] items-center justify-between px-2"
              >
                <div className="flex items-center gap-3">
                  <span className="relative flex h-3 w-3">
                    <span className="absolute inline-flex h-full w-full animate-ping rounded-full bg-red-400 opacity-75"></span>
                    <span className="relative inline-flex h-3 w-3 rounded-full bg-red-500"></span>
                  </span>
                  <div className="flex items-center gap-2">
                    <span className="text-[13px] font-semibold text-ink">
                      {t.composer.recording}
                    </span>
                    <span className="rounded bg-surface-sunken px-2 py-0.5 font-mono text-[12px] font-medium text-ink-soft">
                      {formatTime(recordingTime)}
                    </span>
                  </div>
                </div>

                <div className="flex items-center gap-2">
                  <button
                    type="button"
                    onClick={cancelRecording}
                    title={t.common.cancel}
                    aria-label={t.common.cancel}
                    className="flex h-10 w-10 items-center justify-center rounded-full text-ink-soft transition hover:bg-surface-sunken hover:text-red-500"
                  >
                    <Trash2 className="h-5 w-5" />
                  </button>
                  <button
                    type="button"
                    onClick={handleStopAndSendAudio}
                    title={t.composer.sendTooltip}
                    aria-label={t.composer.sendTooltip}
                    className="flex h-10 w-10 items-center justify-center rounded-full bg-accent text-white shadow-sm transition hover:bg-accent-hover"
                  >
                    <Check className="h-5 w-5" />
                  </button>
                </div>
              </motion.div>
            ) : isTranscribing ? (
              /* Indicateur de transcription Groq Whisper */
              <motion.div
                key="transcribing-ui"
                initial={{ opacity: 0 }}
                animate={{ opacity: 1 }}
                exit={{ opacity: 0 }}
                className="flex min-h-[44px] items-center justify-center gap-2.5 px-4 text-[13px] text-ink-soft"
              >
                <Loader2 className="h-4 w-4 animate-spin text-accent" />
                <span>{t.composer.transcribing}</span>
              </motion.div>
            ) : (
              /* Interface classique avec saisie texte + bouton micro + bouton envoi */
              <motion.form
                key="standard-ui"
                initial={{ opacity: 0 }}
                animate={{ opacity: 1 }}
                exit={{ opacity: 0 }}
                onSubmit={(event) => {
                  event.preventDefault()
                  submit()
                }}
                className="flex items-end gap-2"
              >
                {/* Bouton "+" pour ouvrir les options et paramètres du tableau de bord */}
                <button
                  ref={buttonRef}
                  type="button"
                  onClick={() => setDashboardOpen((prev) => !prev)}
                  title={t.tripDashboard.tripDashboard}
                  aria-label={t.tripDashboard.tripDashboard}
                  aria-expanded={dashboardOpen}
                  className={`relative flex h-11 w-11 shrink-0 items-center justify-center rounded-full border transition-all duration-150 ease-out ${
                    dashboardOpen || activePrecisionsCount > 0
                      ? 'border-accent bg-accent-soft/40 text-accent'
                      : 'border-line text-ink-soft hover:border-line-strong hover:bg-surface-sunken hover:text-accent'
                  }`}
                >
                  <Plus
                    className={`h-5 w-5 transition-transform duration-200 ${
                      dashboardOpen ? 'rotate-45' : ''
                    }`}
                  />
                  {activePrecisionsCount > 0 && !dashboardOpen && (
                    <span className="absolute -top-1 -right-1 flex h-4 min-w-[16px] items-center justify-center rounded-full bg-accent px-1 text-[10px] font-bold text-white shadow-xs">
                      {activePrecisionsCount}
                    </span>
                  )}
                </button>

                <label className="sr-only" htmlFor="veyn-composer">
                  {t.composer.placeholder}
                </label>
                <textarea
                  id="veyn-composer"
                  ref={inputRef}
                  rows={1}
                  value={value}
                  onChange={(event) => setValue(event.target.value)}
                  onKeyDown={(event) => {
                    if (event.key === 'Enter' && !event.shiftKey) {
                      event.preventDefault()
                      submit()
                    }
                  }}
                  placeholder={t.composer.placeholder}
                  className="max-h-32 min-h-[44px] flex-1 resize-none bg-transparent py-3 text-[14px] text-ink placeholder:text-ink-faint focus:outline-none"
                />

                {/* Bouton Message Vocal (Microphone) */}
                <button
                  type="button"
                  onClick={handleStartRecording}
                  disabled={busy}
                  title={t.composer.speechTooltip}
                  aria-label={t.composer.speechTooltip}
                  className="flex h-11 w-11 shrink-0 items-center justify-center rounded-full border border-line text-ink-soft transition-colors duration-150 ease-out hover:border-line-strong hover:bg-surface-sunken hover:text-accent disabled:cursor-not-allowed disabled:opacity-40"
                >
                  <Mic className="h-5 w-5" aria-hidden="true" />
                </button>

                {/* Bouton Envoi */}
                <button
                  type="submit"
                  disabled={!canSend}
                  aria-label={t.composer.sendTooltip}
                  className="flex h-11 w-11 shrink-0 items-center justify-center rounded-full bg-accent text-white transition-colors duration-150 ease-out hover:bg-accent-hover disabled:cursor-not-allowed disabled:bg-line-strong"
                >
                  <ArrowUpIcon className={`h-5 w-5 ${isRTL ? '-scale-x-100' : ''}`} aria-hidden="true" />
                </button>
              </motion.form>
            )}
          </AnimatePresence>
        </div>

        <p className="mt-2 px-1 text-[11px] text-ink-faint">
          {t.paymentLabels.composerHint}
        </p>
      </div>
    </div>
  )
}

