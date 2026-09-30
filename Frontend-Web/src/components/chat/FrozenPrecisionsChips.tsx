import React from 'react'
import {
  MapPin,
  Navigation,
  Calendar,
  Clock,
  Users,
  User,
  Baby,
  Accessibility,
  Bus,
  Train,
  Car,
  Plane,
  Ship,
  Wallet,
  Sparkles,
} from 'lucide-react'
import type { TripPrecisionItem } from '../../types/trip'
import { useLanguage } from '../../contexts/LanguageContext'

interface FrozenPrecisionsChipsProps {
  precisions: TripPrecisionItem[]
  className?: string
}

export function FrozenPrecisionsChips({ precisions, className = '' }: FrozenPrecisionsChipsProps) {
  const { isRTL } = useLanguage()

  if (!precisions || precisions.length === 0) return null

  const getFieldIcon = (field: string) => {
    switch (field) {
      case 'origin':
        return MapPin
      case 'destination':
        return Navigation
      case 'date':
        return Calendar
      case 'time':
        return Clock
      case 'travelers':
        return Users
      case 'modes':
        return Bus
      case 'budget':
        return Wallet
      default:
        return Sparkles
    }
  }

  const getModeIcon = (modeName: string) => {
    const lower = modeName.toLowerCase()
    if (lower.includes('bus') || lower.includes('حافلة')) return Bus
    if (lower.includes('train') || lower.includes('قطار')) return Train
    if (
      lower.includes('taxi') ||
      lower.includes('louage') ||
      lower.includes('car') ||
      lower.includes('voiture') ||
      lower.includes('لواج')
    ) {
      return Car
    }
    if (lower.includes('avion') || lower.includes('plane') || lower.includes('vol') || lower.includes('طيران')) return Plane
    if (lower.includes('ferry') || lower.includes('bateau') || lower.includes('ship') || lower.includes('عبّارة')) return Ship
    return Bus
  }

  // Decompose modes chip with '+' separators
  const renderModeChip = (label: string) => {
    const hasCountOnly = /^\d+\s/.test(label)
    const parts = hasCountOnly
      ? []
      : label.split(/[·,/+]/).map((e) => e.trim()).filter((e) => e.length > 0)

    if (parts.length === 0) {
      return (
        <div className="inline-flex items-center gap-1.5 rounded-full border border-amber-400/40 bg-amber-100/80 px-2.5 py-1 text-xs font-semibold text-amber-900 shadow-xs dark:bg-amber-950/60 dark:text-amber-200 dark:border-amber-700/50">
          <Bus className="h-3.5 w-3.5 text-amber-700 dark:text-amber-400" />
          <span>{label}</span>
        </div>
      )
    }

    return (
      <div className="inline-flex items-center gap-1.5 rounded-full border border-amber-400/40 bg-amber-100/80 px-2.5 py-1 text-xs font-semibold text-amber-900 shadow-xs dark:bg-amber-950/60 dark:text-amber-200 dark:border-amber-700/50">
        {parts.map((part, idx) => {
          const Icon = getModeIcon(part)
          return (
            <React.Fragment key={idx}>
              {idx > 0 && <span className="text-[10px] font-bold text-amber-700 dark:text-amber-400">+</span>}
              <Icon className="h-3.5 w-3.5 text-amber-700 dark:text-amber-400" />
              <span>{part}</span>
            </React.Fragment>
          )
        })}
      </div>
    )
  }

  // Decompose travelers chip with icons (adult, baby, accessibility)
  const renderTravelersChip = (label: string) => {
    const adultMatch = /(\d+)\s*(?:ad(?:ulte?s?)?|adult[se]?|بالغ(?:ين)?)\b/i.exec(label)
    const childMatch = /(\d+)\s*(?:enf(?:ant[se]?)?|child(?:ren)?|أطفال|طفل)\b/i.exec(label)
    const assistMatch = /(\d+)\s*(?:pmr|assist(?:ed)?|handicap|احتياجات|مرافق)\b/i.exec(label)

    const items: { icon: React.ElementType; count: number }[] = []
    if (adultMatch) items.push({ icon: User, count: parseInt(adultMatch[1], 10) })
    if (childMatch) items.push({ icon: Baby, count: parseInt(childMatch[1], 10) })
    if (assistMatch) items.push({ icon: Accessibility, count: parseInt(assistMatch[1], 10) })

    if (items.length === 0) {
      return (
        <div className="inline-flex items-center gap-1.5 rounded-full border border-amber-400/40 bg-amber-100/80 px-2.5 py-1 text-xs font-semibold text-amber-900 shadow-xs dark:bg-amber-950/60 dark:text-amber-200 dark:border-amber-700/50">
          <Users className="h-3.5 w-3.5 text-amber-700 dark:text-amber-400" />
          <span>{label}</span>
        </div>
      )
    }

    return (
      <div className="inline-flex items-center gap-2 rounded-full border border-amber-400/40 bg-amber-100/80 px-2.5 py-1 text-xs font-semibold text-amber-900 shadow-xs dark:bg-amber-950/60 dark:text-amber-200 dark:border-amber-700/50">
        {items.map((item, idx) => {
          const Icon = item.icon
          return (
            <React.Fragment key={idx}>
              {idx > 0 && <span className="text-[10px] text-amber-600 dark:text-amber-400">·</span>}
              <div className="flex items-center gap-0.5">
                <span>{item.count}</span>
                <Icon className="h-3.5 w-3.5 text-amber-700 dark:text-amber-400" />
              </div>
            </React.Fragment>
          )
        })}
      </div>
    )
  }

  return (
    <div
      className={`flex flex-wrap items-center gap-1.5 overflow-x-auto py-1 scrollbar-none ${className}`}
      dir={isRTL ? 'rtl' : 'ltr'}
    >
      {precisions.map((p, index) => {
        if (p.field === 'modes') {
          return <React.Fragment key={index}>{renderModeChip(p.label)}</React.Fragment>
        }
        if (p.field === 'travelers') {
          return <React.Fragment key={index}>{renderTravelersChip(p.label)}</React.Fragment>
        }

        const Icon = getFieldIcon(p.field)
        return (
          <div
            key={index}
            className="inline-flex items-center gap-1.5 rounded-full border border-amber-400/40 bg-amber-100/80 px-2.5 py-1 text-xs font-semibold text-amber-900 shadow-xs dark:bg-amber-950/60 dark:text-amber-200 dark:border-amber-700/50"
          >
            <Icon className="h-3.5 w-3.5 text-amber-700 dark:text-amber-400" />
            <span>{p.label}</span>
          </div>
        )
      })}
    </div>
  )
}
