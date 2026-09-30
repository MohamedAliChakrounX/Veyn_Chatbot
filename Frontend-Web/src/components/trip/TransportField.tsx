import React from 'react'
import {
  BusIcon,
  CarTaxiFrontIcon,
  CircleEllipsisIcon,
  PlaneIcon,
  ShipIcon,
  TrainFrontIcon,
} from 'lucide-react'
import type { TransportMode } from '../../types/trip'
import { useLanguage } from '../../contexts/LanguageContext'

interface TransportFieldProps {
  modes: TransportMode[]
  onChange: (modes: TransportMode[]) => void
}

export function TransportField({ modes, onChange }: TransportFieldProps) {
  const { t } = useLanguage()

  const transportOptions = [
    { id: 'bus' as TransportMode, label: t.trip.bus, icon: BusIcon },
    { id: 'shared_taxi' as TransportMode, label: t.trip.sharedTaxi, icon: CarTaxiFrontIcon },
    { id: 'train' as TransportMode, label: t.trip.train, icon: TrainFrontIcon },
    { id: 'plane' as TransportMode, label: t.trip.plane, icon: PlaneIcon },
    { id: 'ferry' as TransportMode, label: t.trip.ferry, icon: ShipIcon },
    { id: 'other' as TransportMode, label: t.trip.other, icon: CircleEllipsisIcon },
  ]

  const toggle = (mode: TransportMode) => {
    onChange(modes.includes(mode) ? modes.filter((entry) => entry !== mode) : [...modes, mode])
  }

  return (
    <div className="flex flex-wrap gap-1.5">
      {transportOptions.map((option) => {
        const active = modes.includes(option.id)
        const Icon = option.icon
        return (
          <button
            key={option.id}
            type="button"
            aria-pressed={active}
            onClick={() => toggle(option.id)}
            className={`flex items-center gap-2 rounded-full border px-3 py-2 text-[13px] font-medium transition-colors duration-150 ease-out ${
              active
                ? 'border-ink bg-ink text-white'
                : 'border-line bg-surface text-ink-soft hover:border-line-strong hover:text-ink'
            }`}
          >
            <Icon className="h-4 w-4" aria-hidden="true" />
            {option.label}
          </button>
        )
      })}
    </div>
  )
}
