import React, { useMemo, useState } from 'react'
import { CheckIcon, MapPinIcon, SearchIcon } from 'lucide-react'
import { COUNTRIES, getCitiesByCountry, getCountryName, localizeCityName, searchCities } from '../../data/locations'
import { useLanguage } from '../../contexts/LanguageContext'
import type { City, CountryCode } from '../../types/trip'

interface LocationFieldProps {
  selected: City | null
  onSelect: (city: City) => void
  excludeId?: string
  placeholder: string
}

export function LocationField({ selected, onSelect, excludeId, placeholder }: LocationFieldProps) {
  const { t, language } = useLanguage()
  const [query, setQuery] = useState('')
  const [country, setCountry] = useState<CountryCode>(selected?.country ?? 'LY')

  const cities = useMemo(() => {
    const list = query.trim().length > 0 ? searchCities(query, 16) : getCitiesByCountry(country)
    return list.filter((city) => city.id !== excludeId)
  }, [query, country, excludeId])

  return (
    <div className="space-y-3">
      <div className="relative">
        <SearchIcon
          className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-ink-faint"
          aria-hidden="true"
        />
        <input
          type="search"
          value={query}
          onChange={(event) => setQuery(event.target.value)}
          placeholder={placeholder}
          aria-label={placeholder}
          className="w-full rounded-lg border border-line bg-surface py-2.5 pl-9 pr-3 text-[13px] text-ink placeholder:text-ink-faint focus:border-ink/30 focus:outline-none focus-visible:ring-2 focus-visible:ring-ink/10"
        />
      </div>

      {query.trim().length === 0 ? (
        <div className="flex flex-wrap gap-1.5" role="tablist" aria-label="Pays">
          {COUNTRIES.map((entry) => {
            const active = entry.code === country
            return (
              <button
                key={entry.code}
                type="button"
                role="tab"
                aria-selected={active}
                onClick={() => setCountry(entry.code)}
                className={`rounded-full border px-3 py-1.5 text-xs font-medium transition-colors duration-150 ease-out ${
                  active
                    ? 'border-ink bg-ink text-white'
                    : 'border-line bg-surface text-ink-muted hover:border-line-strong hover:text-ink'
                }`}
              >
                {getCountryName(entry.code, language)}
              </button>
            )
          })}
        </div>
      ) : null}

      <ul className="veyn-scroll max-h-56 space-y-1 overflow-y-auto overscroll-contain pr-1 pb-2">
        {cities.length === 0 ? (
          <li className="px-2 py-3 text-[13px] text-ink-muted">{t.tripPanel.noCityMatches} « {query} ».</li>
        ) : (
          cities.map((city) => {
            const active = selected?.id === city.id
            return (
              <li key={city.id}>
                <button
                  type="button"
                  onClick={() => onSelect(city)}
                  className={`flex w-full items-center gap-2 rounded-lg px-2.5 py-2 text-left transition-colors duration-150 ease-out ${
                    active ? 'bg-ink text-white' : 'hover:bg-surface-sunken'
                  }`}
                >
                  <MapPinIcon
                    className={`h-3.5 w-3.5 shrink-0 ${active ? 'text-white/70' : 'text-ink-faint'}`}
                    aria-hidden="true"
                  />
                  <span className="text-[13px] font-medium">{localizeCityName(city.name, language)}</span>
                  <span className={`text-xs ${active ? 'text-white/70' : 'text-ink-muted'}`}>
                    {getCountryName(city.country, language)}
                  </span>
                  {active ? <CheckIcon className="ml-auto h-3.5 w-3.5" aria-hidden="true" /> : null}
                </button>
              </li>
            )
          })
        )}
      </ul>
    </div>
  )
}
