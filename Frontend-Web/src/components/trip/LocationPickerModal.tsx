import React, { useMemo, useState, useEffect, useRef } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { MapPin, Navigation, Search, X, Check, Globe } from 'lucide-react'
import { CITIES, COUNTRIES, getCountryFlag, getCountryName, localizeCityName, normalize } from '../../data/locations'
import type { City, CountryCode } from '../../types/trip'
import { useLanguage } from '../../contexts/LanguageContext'
import { ModalPortal } from '../common/ModalPortal'

interface LocationPickerModalProps {
  open: boolean
  isOrigin: boolean
  currentCity: City | null
  excludeCityId?: string | null
  onSelectCity: (city: City) => void
  onClose: () => void
}

export function LocationPickerModal({
  open,
  isOrigin,
  currentCity,
  excludeCityId,
  onSelectCity,
  onClose,
}: LocationPickerModalProps) {
  const { t, language, isRTL } = useLanguage()
  const [selectedCountry, setSelectedCountry] = useState<CountryCode | 'ALL'>('ALL')
  const [searchQuery, setSearchQuery] = useState('')
  const inputRef = useRef<HTMLInputElement>(null)

  useEffect(() => {
    if (open) {
      if (currentCity) {
        setSelectedCountry(currentCity.country)
      } else {
        setSelectedCountry('ALL')
      }
      setSearchQuery('')
      setTimeout(() => inputRef.current?.focus(), 80)

      const handleKeyDown = (e: KeyboardEvent) => {
        if (e.key === 'Escape') {
          onClose()
        }
      }
      window.addEventListener('keydown', handleKeyDown)
      return () => window.removeEventListener('keydown', handleKeyDown)
    }
  }, [open, currentCity, onClose])

  const filteredCities = useMemo(() => {
    const term = normalize(searchQuery)
    return CITIES.filter((city) => {
      if (excludeCityId && city.id === excludeCityId) return false
      if (selectedCountry !== 'ALL' && city.country !== selectedCountry) return false
      if (!term) return true

      const haystack = [
        city.name,
        city.nameAr || '',
        city.nameFr || '',
        city.nameEn || '',
        ...(city.aliases || []),
      ].map(normalize)

      return haystack.some((alias) => alias.includes(term))
    })
  }, [searchQuery, selectedCountry, excludeCityId])

  const title = isOrigin
    ? t.tripDashboard.chooseDeparturePoint
    : t.tripDashboard.chooseArrivalPoint
  const Icon = isOrigin ? MapPin : Navigation

  return (
    <ModalPortal>
      <AnimatePresence>
        {open && (
          <div
            className="fixed inset-0 z-[100] flex items-center justify-center p-3 sm:p-5"
            role="dialog"
            aria-modal="true"
          >
            {/* Backdrop plein écran */}
            <motion.div
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              onClick={onClose}
              className="absolute inset-0 bg-ink/40 backdrop-blur-xs"
            />

            {/* Modal Container */}
            <motion.div
              initial={{ opacity: 0, scale: 0.95, y: 12 }}
              animate={{ opacity: 1, scale: 1, y: 0 }}
              exit={{ opacity: 0, scale: 0.95, y: 12 }}
              transition={{ duration: 0.22, ease: [0.23, 1, 0.32, 1] }}
              className="relative z-10 flex max-h-[85vh] w-full max-w-lg flex-col overflow-hidden rounded-2xl border border-line bg-surface shadow-2xl"
            >
              {/* Header */}
              <div className="flex shrink-0 items-center justify-between border-b border-line px-4 py-3 sm:px-5">
                <div className="flex items-center gap-2.5">
                  <div className="flex h-8 w-8 items-center justify-center rounded-full bg-accent-soft text-accent">
                    <Icon className="h-4 w-4" />
                  </div>
                  <h3 className="text-sm font-bold text-ink">{title}</h3>
                </div>
                <button
                  type="button"
                  onClick={onClose}
                  aria-label={t.common.close}
                  className="flex h-7 w-7 items-center justify-center rounded-full text-ink-muted transition hover:bg-surface-sunken hover:text-ink"
                >
                  <X className="h-4 w-4" />
                </button>
              </div>

              {/* Country Selector Tabs */}
              <div className="flex shrink-0 gap-1.5 overflow-x-auto border-b border-line px-4 py-2.5 scrollbar-none sm:px-5">
                <button
                  type="button"
                  onClick={() => setSelectedCountry('ALL')}
                  className={`flex shrink-0 items-center gap-1.5 rounded-full px-3 py-1.5 text-xs font-semibold transition ${
                    selectedCountry === 'ALL'
                      ? 'bg-accent text-white shadow-xs'
                      : 'border border-line bg-surface-sunken text-ink-muted hover:border-line-strong hover:text-ink'
                  }`}
                >
                  <Globe className="h-3.5 w-3.5" />
                  <span>{t.tripDashboard.allCities}</span>
                </button>
                {COUNTRIES.map((c) => {
                  const isSelected = selectedCountry === c.code
                  return (
                    <button
                      key={c.code}
                      type="button"
                      onClick={() => setSelectedCountry(c.code)}
                      className={`flex shrink-0 items-center gap-1.5 rounded-full px-3 py-1.5 text-xs font-semibold transition ${
                        isSelected
                          ? 'bg-accent text-white shadow-xs'
                          : 'border border-line bg-surface-sunken text-ink-muted hover:border-line-strong hover:text-ink'
                      }`}
                    >
                      <span className="text-sm">{getCountryFlag(c.code)}</span>
                      <span>{getCountryName(c.code, language)}</span>
                    </button>
                  )
                })}
              </div>

              {/* Search Input */}
              <div className="shrink-0 border-b border-line p-3 sm:px-5">
                <div className="relative">
                  <Search className={`pointer-events-none absolute top-1/2 h-4 w-4 -translate-y-1/2 text-ink-muted ${isRTL ? 'right-3' : 'left-3'}`} />
                  <input
                    ref={inputRef}
                    type="text"
                    value={searchQuery}
                    onChange={(e) => setSearchQuery(e.target.value)}
                    placeholder={t.trip.searchCity}
                    className={`w-full rounded-xl border border-line bg-surface-sunken py-2 text-xs text-ink placeholder:text-ink-faint focus:border-accent focus:outline-none focus:ring-1 focus:ring-accent ${
                      isRTL ? 'pr-9 pl-8' : 'pl-9 pr-8'
                    }`}
                  />
                  {searchQuery && (
                    <button
                      type="button"
                      onClick={() => setSearchQuery('')}
                      aria-label={t.common.cancel}
                      className={`absolute top-1/2 -translate-y-1/2 text-ink-muted hover:text-ink ${isRTL ? 'left-3' : 'right-3'}`}
                    >
                      <X className="h-3.5 w-3.5" />
                    </button>
                  )}
                </div>
              </div>

              {/* City List */}
              <div className="veyn-scroll flex-1 min-h-0 overflow-y-auto p-3 sm:p-4 overscroll-contain pb-6">
                {filteredCities.length === 0 ? (
                  <div className="py-12 text-center text-xs text-ink-muted">
                    {t.tripPanel.noCityMatches} « {searchQuery} »
                  </div>
                ) : (
                  <div className="grid grid-cols-1 gap-1.5 sm:grid-cols-2">
                    {filteredCities.map((city) => {
                      const isCurrent = currentCity?.id === city.id
                      const flag = getCountryFlag(city.country)
                      const cityName = localizeCityName(city.name, language)
                      const countryName = getCountryName(city.country, language)

                      return (
                        <button
                          key={city.id}
                          type="button"
                          onClick={() => {
                            onSelectCity(city)
                            onClose()
                          }}
                          className={`flex items-center gap-3 rounded-xl p-2.5 text-left transition ${
                            isCurrent
                              ? 'border border-accent/50 bg-accent-soft text-accent font-bold ring-1 ring-accent/30'
                              : 'border border-line/60 bg-surface hover:border-accent/40 hover:bg-surface-sunken text-ink'
                          }`}
                        >
                          <span className="flex h-8 w-8 shrink-0 items-center justify-center rounded-lg bg-surface text-base shadow-xs border border-line">
                            {flag}
                          </span>
                          <div className="min-w-0 flex-1">
                            <p className="truncate text-xs font-semibold" title={cityName}>{cityName}</p>
                            <p className="truncate text-[10px] text-ink-muted">{countryName}</p>
                          </div>
                          {isCurrent && <Check className="h-4 w-4 shrink-0 text-accent" />}
                        </button>
                      )
                    })}
                  </div>
                )}
              </div>
            </motion.div>
          </div>
        )}
      </AnimatePresence>
    </ModalPortal>
  )
}

