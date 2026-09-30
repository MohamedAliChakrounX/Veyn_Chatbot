import React, { createContext, useCallback, useContext, useEffect, useMemo, useState } from 'react'
import { translations } from '../i18n/translations'
import type { Language, TranslationSchema } from '../i18n/translations'

const STORAGE_KEY = 'veyn_language'

interface LanguageContextValue {
  language: Language
  direction: 'ltr' | 'rtl'
  isRTL: boolean
  setLanguage: (lang: Language) => void
  t: TranslationSchema
}

const LanguageContext = createContext<LanguageContextValue | null>(null)

function getInitialLanguage(): Language {
  if (typeof window === 'undefined') return 'fr'
  try {
    const saved = localStorage.getItem(STORAGE_KEY) as Language | null
    if (saved && (saved === 'fr' || saved === 'ar' || saved === 'en')) {
      return saved
    }
    const browserLang = navigator.language.slice(0, 2).toLowerCase()
    if (browserLang === 'ar') return 'ar'
    if (browserLang === 'en') return 'en'
    return 'fr'
  } catch {
    return 'fr'
  }
}

export function LanguageProvider({ children }: { children: React.ReactNode }) {
  const [language, setLanguageState] = useState<Language>(getInitialLanguage)

  const setLanguage = useCallback((lang: Language) => {
    setLanguageState(lang)
    try {
      localStorage.setItem(STORAGE_KEY, lang)
    } catch (e) {
      console.warn('Failed to save language in localStorage', e)
    }
  }, [])

  const isRTL = language === 'ar'
  const direction: 'ltr' | 'rtl' = isRTL ? 'rtl' : 'ltr'

  useEffect(() => {
    const root = document.documentElement
    const body = document.body
    root.setAttribute('dir', direction)
    root.setAttribute('lang', language)

    if (isRTL) {
      root.classList.add('font-arabic')
      body.classList.add('font-arabic')
    } else {
      root.classList.remove('font-arabic')
      body.classList.remove('font-arabic')
    }
  }, [language, direction, isRTL])

  const t = useMemo(() => translations[language], [language])

  const value = useMemo<LanguageContextValue>(
    () => ({
      language,
      direction,
      isRTL,
      setLanguage,
      t,
    }),
    [language, direction, isRTL, setLanguage, t]
  )

  return <LanguageContext.Provider value={value}>{children}</LanguageContext.Provider>
}

export function useLanguage(): LanguageContextValue {
  const ctx = useContext(LanguageContext)
  if (!ctx) {
    throw new Error('useLanguage must be used within a LanguageProvider')
  }
  return ctx
}
