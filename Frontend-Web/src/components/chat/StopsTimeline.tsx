import React from 'react'
import { useLanguage } from '../../contexts/LanguageContext'
import { localizeCityName, localizePlaceName } from '../../data/locations'
import type { TripStop } from '../../types/trip'

interface StopsTimelineProps {
  stops: TripStop[]
  /** Point de montée retenu, mis en avant dans la liste. */
  boardingName?: string
}

export function StopsTimeline({ stops, boardingName }: StopsTimelineProps) {
  const { t, language, isRTL } = useLanguage()

  if (!stops || stops.length === 0) return null

  const formatWait = (minutes: number) => {
    if (minutes < 60) return `${minutes} ${t.results.waitMinutes}`
    const hours = Math.floor(minutes / 60)
    const rest = minutes % 60
    if (rest === 0) return `${hours} ${t.results.waitHours}`
    if (language === 'ar') return `${hours} س و${rest} دق توقف`
    return `${hours}h${String(rest).padStart(2, '0')} ${t.results.waitMinutes}`
  }

  return (
    <ol className={`relative space-y-3 ${isRTL ? 'pr-4' : 'pl-4'}`}>
      <span
        className={`absolute top-2 bottom-2 w-px bg-line ${isRTL ? 'right-[3px]' : 'left-[3px]'}`}
        aria-hidden="true"
      />
      {stops.map((stop) => {
        const isEdge = stop.kind === 'origin' || stop.kind === 'destination'
        const isBorder = stop.kind === 'border'
        const isBoarding = boardingName !== undefined && (stop.name === boardingName || localizeCityName(stop.name, language) === boardingName)
        const displayName = localizeCityName(stop.name, language)
        const displayPlace = localizePlaceName(stop.place, language)

        return (
          <li key={`${stop.name}-${stop.time}`} className="relative">
            <span
              className={`absolute top-1.5 h-[7px] w-[7px] rounded-full ${
                isRTL ? '-right-4' : '-left-4'
              } ${
                isBorder ? 'bg-accent' : isEdge ? 'bg-ink' : 'bg-line-strong'
              }`}
              aria-hidden="true"
            />
            <div className="flex flex-wrap items-baseline gap-x-2 gap-y-0.5">
              <span className="text-xs font-semibold tabular-nums text-ink-muted">{stop.time}</span>
              <span className={`text-[13px] ${isEdge ? 'font-semibold text-ink' : 'font-medium text-ink-soft'}`}>
                {displayName}
              </span>
              {isBoarding ? (
                <span className="rounded-full bg-ink px-2 py-0.5 text-[10px] font-semibold text-white">
                  {t.results.yourBoarding}
                </span>
              ) : null}
              {stop.waitMinutes ? (
                <span className={`text-[11px] ${isBorder ? 'text-accent' : 'text-ink-faint'}`}>
                  {formatWait(stop.waitMinutes)}
                </span>
              ) : null}
            </div>
            {displayPlace ? (
              <p className="text-[11px] text-ink-faint">{displayPlace}</p>
            ) : null}
          </li>
        )
      })}
    </ol>
  )
}
