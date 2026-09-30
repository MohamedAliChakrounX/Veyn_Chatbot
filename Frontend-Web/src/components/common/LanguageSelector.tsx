import React, { useEffect, useRef, useState } from 'react'
import { CheckIcon, ChevronDownIcon, GlobeIcon } from 'lucide-react'
import { motion, AnimatePresence } from 'framer-motion'
import { useLanguage } from '../../contexts/LanguageContext'
import type { Language } from '../../i18n/translations'

interface LanguageOption {
  code: Language
  flag: string
  label: string
  nativeName: string
}

const LANGUAGES: LanguageOption[] = [
  { code: 'fr', flag: '🇫🇷', label: 'Français', nativeName: 'Français' },
  { code: 'ar', flag: '🇸🇦', label: 'العربية', nativeName: 'العربية' },
  { code: 'en', flag: '🇬🇧', label: 'English', nativeName: 'English' },
]

export function LanguageSelector() {
  const { language, setLanguage, isRTL } = useLanguage()
  const [isOpen, setIsOpen] = useState(false)
  const containerRef = useRef<HTMLDivElement>(null)

  const currentOption = LANGUAGES.find((l) => l.code === language) || LANGUAGES[0]

  useEffect(() => {
    function handleClickOutside(event: MouseEvent) {
      if (containerRef.current && !containerRef.current.contains(event.target as Node)) {
        setIsOpen(false)
      }
    }
    if (isOpen) {
      document.addEventListener('mousedown', handleClickOutside)
    }
    return () => {
      document.removeEventListener('mousedown', handleClickOutside)
    }
  }, [isOpen])

  return (
    <div className="relative inline-block text-start" ref={containerRef}>
      <button
        type="button"
        onClick={() => setIsOpen(!isOpen)}
        aria-label="Choisir la langue / Select language / تغيير اللغة"
        aria-expanded={isOpen}
        className={`flex items-center gap-1.5 rounded-full border px-2.5 py-1.5 text-xs font-semibold transition-all duration-200 ${
          isOpen
            ? 'border-accent bg-accent/10 text-accent shadow-sm'
            : 'border-line bg-surface text-ink hover:border-line-strong hover:bg-surface-elevated'
        }`}
      >
        <span className="text-sm leading-none" aria-hidden="true">
          {currentOption.flag}
        </span>
        <span className="hidden text-xs sm:inline">{currentOption.nativeName}</span>
        <ChevronDownIcon
          className={`h-3 w-3 text-ink-muted transition-transform duration-200 ${isOpen ? 'rotate-180' : ''}`}
          aria-hidden="true"
        />
      </button>

      <AnimatePresence>
        {isOpen && (
          <motion.div
            initial={{ opacity: 0, y: 6, scale: 0.96 }}
            animate={{ opacity: 1, y: 0, scale: 1 }}
            exit={{ opacity: 0, y: 4, scale: 0.96 }}
            transition={{ duration: 0.15, ease: 'easeOut' }}
            className={`absolute top-full z-50 mt-2 min-w-[150px] overflow-hidden rounded-2xl border border-line bg-surface p-1.5 shadow-xl backdrop-blur-md ${
              isRTL ? 'left-0 origin-top-left' : 'right-0 origin-top-right'
            }`}
          >
            <div className="space-y-1">
              {LANGUAGES.map((option) => {
                const isSelected = option.code === language
                return (
                  <button
                    key={option.code}
                    type="button"
                    onClick={() => {
                      setLanguage(option.code)
                      setIsOpen(false)
                    }}
                    className={`flex w-full items-center justify-between gap-3 rounded-xl px-3 py-2 text-start text-xs font-medium transition-colors ${
                      isSelected
                        ? 'bg-accent/10 font-bold text-accent'
                        : 'text-ink hover:bg-surface-sunken'
                    }`}
                  >
                    <div className="flex items-center gap-2.5">
                      <span className="text-base leading-none" aria-hidden="true">
                        {option.flag}
                      </span>
                      <span>{option.nativeName}</span>
                    </div>
                    {isSelected && (
                      <CheckIcon className="h-3.5 w-3.5 text-accent shrink-0" aria-hidden="true" />
                    )}
                  </button>
                )
              })}
            </div>
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  )
}
