import React, { useState } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { Server, Activity, Check, X, Loader2 } from 'lucide-react'
import { apiService } from '../../utils/apiService'
import { useLanguage } from '../../contexts/LanguageContext'

interface ServerConfigModalProps {
  open: boolean
  onClose: () => void
  onSaved?: () => void
}

export function ServerConfigModal({ open, onClose, onSaved }: ServerConfigModalProps) {
  const { t, isRTL } = useLanguage()
  const [url, setUrl] = useState(() => apiService.baseUrl)
  const [isChecking, setIsChecking] = useState(false)
  const [testResult, setTestResult] = useState<{ ok: boolean; message: string } | null>(null)

  const handleTest = async () => {
    setIsChecking(true)
    setTestResult(null)
    const ok = await apiService.checkHealth(url)
    setIsChecking(false)
    setTestResult({
      ok,
      message: ok ? t.serverConfig.serverOnline : t.serverConfig.serverOffline,
    })
  }

  const handleSave = () => {
    apiService.baseUrl = url
    if (onSaved) onSaved()
    onClose()
  }

  return (
    <AnimatePresence>
      {open && (
        <div
          className="fixed inset-0 z-50 flex items-center justify-center p-4"
          role="dialog"
          aria-modal="true"
        >
          {/* Backdrop */}
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            onClick={onClose}
            className="absolute inset-0 bg-ink/30 backdrop-blur-xs"
          />

          {/* Modal Card */}
          <motion.div
            initial={{ opacity: 0, scale: 0.95, y: 10 }}
            animate={{ opacity: 1, scale: 1, y: 0 }}
            exit={{ opacity: 0, scale: 0.95, y: 10 }}
            transition={{ duration: 0.2, ease: [0.23, 1, 0.32, 1] }}
            className="relative z-10 w-full max-w-md overflow-hidden rounded-2xl border border-line bg-surface p-5 shadow-2xl"
          >
            {/* Header */}
            <div className="flex items-center justify-between border-b border-line pb-3">
              <div className="flex items-center gap-2.5">
                <div className="flex h-8 w-8 items-center justify-center rounded-lg bg-accent-soft text-accent">
                  <Server className="h-4 w-4" />
                </div>
                <h3 className="text-sm font-bold text-ink">{t.serverConfig.serverConfig}</h3>
              </div>
              <button
                type="button"
                onClick={onClose}
                className="flex h-7 w-7 items-center justify-center rounded-full text-ink-muted transition hover:bg-surface-sunken hover:text-ink"
              >
                <X className="h-4 w-4" />
              </button>
            </div>

            {/* Content */}
            <div className="space-y-3.5 py-4">
              <div>
                <label className="block text-xs font-semibold text-ink-soft mb-1.5">
                  {t.serverConfig.apiUrlLabel}
                </label>
                <input
                  type="text"
                  dir="ltr"
                  value={url}
                  onChange={(e) => {
                    setUrl(e.target.value)
                    setTestResult(null)
                  }}
                  placeholder="http://127.0.0.1:8000"
                  className="w-full rounded-xl border border-line bg-surface-sunken px-3.5 py-2 font-mono text-xs text-ink focus:border-accent focus:outline-none focus:ring-1 focus:ring-accent"
                />
              </div>

              {/* Presets chips */}
              <div className="flex flex-wrap gap-1.5">
                <button
                  type="button"
                  onClick={() => setUrl('http://localhost:8000')}
                  className="rounded-lg border border-line bg-surface px-2.5 py-1 text-[11px] font-medium text-ink-muted hover:border-accent hover:text-accent transition"
                >
                  Localhost (8000)
                </button>
                <button
                  type="button"
                  onClick={() => setUrl('http://127.0.0.1:8000')}
                  className="rounded-lg border border-line bg-surface px-2.5 py-1 text-[11px] font-medium text-ink-muted hover:border-accent hover:text-accent transition"
                >
                  {t.serverConfig.usbAdbPreset}
                </button>
                <button
                  type="button"
                  onClick={() => setUrl('http://192.168.100.15:8000')}
                  className="rounded-lg border border-line bg-surface px-2.5 py-1 text-[11px] font-medium text-ink-muted hover:border-accent hover:text-accent transition"
                >
                  {t.serverConfig.wifiPreset}
                </button>
                <button
                  type="button"
                  onClick={() => setUrl('http://10.0.2.2:8000')}
                  className="rounded-lg border border-line bg-surface px-2.5 py-1 text-[11px] font-medium text-ink-muted hover:border-accent hover:text-accent transition"
                >
                  {t.serverConfig.emulatorPreset}
                </button>
              </div>

              {/* Test connection button */}
              <button
                type="button"
                onClick={handleTest}
                disabled={isChecking}
                className="flex w-full items-center justify-center gap-2 rounded-xl border border-line bg-surface-sunken px-3 py-2 text-xs font-semibold text-ink-soft hover:bg-surface-elevated hover:text-ink transition disabled:opacity-50"
              >
                {isChecking ? (
                  <>
                    <Loader2 className="h-3.5 w-3.5 animate-spin text-accent" />
                    <span>{t.serverConfig.testing}</span>
                  </>
                ) : (
                  <>
                    <Activity className="h-3.5 w-3.5 text-accent" />
                    <span>{t.serverConfig.testConnection}</span>
                  </>
                )}
              </button>

              {/* Test result status notice */}
              {testResult && (
                <div
                  className={`flex items-center justify-center gap-2 rounded-xl p-2.5 text-xs font-semibold ${
                    testResult.ok
                      ? 'bg-emerald-50 text-emerald-700 dark:bg-emerald-950/40 dark:text-emerald-300'
                      : 'bg-rose-50 text-rose-700 dark:bg-rose-950/40 dark:text-rose-300'
                  }`}
                >
                  {testResult.ok ? (
                    <Check className="h-4 w-4 shrink-0 text-emerald-600" />
                  ) : (
                    <X className="h-4 w-4 shrink-0 text-rose-600" />
                  )}
                  <span>{testResult.message}</span>
                </div>
              )}
            </div>

            {/* Footer */}
            <div className="flex items-center justify-end gap-2 border-t border-line pt-3">
              <button
                type="button"
                onClick={onClose}
                className="rounded-xl px-4 py-2 text-xs font-medium text-ink-muted hover:bg-surface-sunken hover:text-ink transition"
              >
                {t.common.cancel}
              </button>
              <button
                type="button"
                onClick={handleSave}
                className="rounded-xl bg-accent px-4 py-2 text-xs font-semibold text-white shadow-sm hover:bg-accent-hover transition"
              >
                {t.common.save}
              </button>
            </div>
          </motion.div>
        </div>
      )}
    </AnimatePresence>
  )
}
