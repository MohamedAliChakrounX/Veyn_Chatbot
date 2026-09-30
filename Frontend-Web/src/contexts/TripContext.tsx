import React, { createContext, useCallback, useContext, useMemo, useState } from 'react'
import type { TimePeriod, TransportMode, TripField, TripQuery } from '../types/trip'
import { clearField, emptyTrip } from '../utils/trip'

interface TripContextValue {
  trip: TripQuery
  patchTrip: (patch: Partial<TripQuery>) => void
  /** Remplace l'intégralité de l'état (utilisé par l'historique). */
  replaceTrip: (trip: TripQuery) => void
  removeField: (field: TripField) => void
  resetTrip: () => void
  swapCities: () => void
  toggleDate: (dateStr: string) => void
  setDates: (dates: string[]) => void
  togglePeriod: (period: TimePeriod) => void
  setPeriods: (periods: TimePeriod[]) => void
  toggleMode: (mode: TransportMode) => void
  panelOpen: boolean
  activeField: TripField | null
  openPanel: (field?: TripField) => void
  closePanel: () => void
  toggleField: (field: TripField) => void
  /** Nombre de précisions actuellement actives (pour le badge du dashboard). */
  activePrecisionsCount: number
}

const TripContext = createContext<TripContextValue | null>(null)

export function TripProvider({ children }: { children: React.ReactNode }) {
  const [trip, setTrip] = useState<TripQuery>(emptyTrip)
  const [panelOpen, setPanelOpen] = useState(false)
  const [activeField, setActiveField] = useState<TripField | null>(null)

  const patchTrip = useCallback((patch: Partial<TripQuery>) => {
    setTrip((current) => {
      const next = { ...current, ...patch }
      if (patch.dates !== undefined) {
        next.dates = patch.dates
        next.date = patch.dates.length > 0 ? patch.dates[0] : null
      } else if (patch.date !== undefined && patch.dates === undefined) {
        next.dates = patch.date ? [patch.date] : []
      }
      if (patch.periods !== undefined) {
        next.periods = patch.periods
        next.period = patch.periods.length > 0 ? patch.periods[0] : null
      } else if (patch.period !== undefined && patch.periods === undefined) {
        next.periods = patch.period ? [patch.period] : []
      }
      return next
    })
  }, [])

  const replaceTrip = useCallback((next: TripQuery) => {
    setTrip({ ...emptyTrip(), ...next })
    setActiveField(null)
    setPanelOpen(false)
  }, [])

  const removeField = useCallback((field: TripField) => {
    setTrip((current) => clearField(current, field))
  }, [])

  const resetTrip = useCallback(() => {
    setTrip(emptyTrip())
    setActiveField(null)
  }, [])

  const swapCities = useCallback(() => {
    setTrip((current) => ({
      ...current,
      origin: current.destination,
      destination: current.origin,
    }))
  }, [])

  const toggleDate = useCallback((dateStr: string) => {
    setTrip((current) => {
      const currentDates = current.dates ? [...current.dates] : current.date ? [current.date] : []
      const idx = currentDates.indexOf(dateStr)
      if (idx >= 0) {
        currentDates.splice(idx, 1)
      } else {
        currentDates.push(dateStr)
        currentDates.sort()
      }
      return {
        ...current,
        dates: currentDates,
        date: currentDates.length > 0 ? currentDates[0] : null,
      }
    })
  }, [])

  const setDates = useCallback((dates: string[]) => {
    const sorted = [...dates].sort()
    setTrip((current) => ({
      ...current,
      dates: sorted,
      date: sorted.length > 0 ? sorted[0] : null,
    }))
  }, [])

  const togglePeriod = useCallback((period: TimePeriod) => {
    setTrip((current) => {
      const currentPeriods = current.periods ? [...current.periods] : current.period ? [current.period] : []
      const idx = currentPeriods.indexOf(period)
      if (idx >= 0) {
        currentPeriods.splice(idx, 1)
      } else {
        currentPeriods.push(period)
      }
      return {
        ...current,
        periods: currentPeriods,
        period: currentPeriods.length > 0 ? currentPeriods[0] : null,
      }
    })
  }, [])

  const setPeriods = useCallback((periods: TimePeriod[]) => {
    setTrip((current) => ({
      ...current,
      periods,
      period: periods.length > 0 ? periods[0] : null,
    }))
  }, [])

  const toggleMode = useCallback((mode: TransportMode) => {
    setTrip((current) => {
      const currentModes = [...current.modes]
      const idx = currentModes.indexOf(mode)
      if (idx >= 0) {
        currentModes.splice(idx, 1)
      } else {
        currentModes.push(mode)
      }
      return {
        ...current,
        modes: currentModes,
      }
    })
  }, [])

  const openPanel = useCallback((field?: TripField) => {
    setPanelOpen(true)
    setActiveField(field ?? null)
  }, [])

  const closePanel = useCallback(() => {
    setPanelOpen(false)
    setActiveField(null)
  }, [])

  const toggleField = useCallback((field: TripField) => {
    setActiveField((current) => (current === field ? null : field))
  }, [])

  const activePrecisionsCount = useMemo(() => {
    let count = 0
    if (trip.origin) count++
    if (trip.destination) count++
    if ((trip.dates && trip.dates.length > 0) || trip.date) count++
    if (
      (trip.periods && trip.periods.length > 0) ||
      trip.period ||
      (trip.exactTime && trip.exactTime.trim().length > 0)
    ) {
      count++
    }
    if (
      trip.travelers &&
      (trip.travelers.adults > 0 || trip.travelers.children > 0 || trip.travelers.assisted > 0)
    ) {
      count++
    }
    if (trip.modes && trip.modes.length > 0) count++
    if (trip.budget !== null && trip.budget !== undefined) count++
    if (trip.directOnly) count++
    return count
  }, [trip])

  const value = useMemo<TripContextValue>(
    () => ({
      trip,
      patchTrip,
      replaceTrip,
      removeField,
      resetTrip,
      swapCities,
      toggleDate,
      setDates,
      togglePeriod,
      setPeriods,
      toggleMode,
      panelOpen,
      activeField,
      openPanel,
      closePanel,
      toggleField,
      activePrecisionsCount,
    }),
    [
      trip,
      patchTrip,
      replaceTrip,
      removeField,
      resetTrip,
      swapCities,
      toggleDate,
      setDates,
      togglePeriod,
      setPeriods,
      toggleMode,
      panelOpen,
      activeField,
      openPanel,
      closePanel,
      toggleField,
      activePrecisionsCount,
    ],
  )

  return <TripContext.Provider value={value}>{children}</TripContext.Provider>
}

export function useTrip(): TripContextValue {
  const context = useContext(TripContext)
  if (!context) throw new Error('useTrip doit être utilisé dans un TripProvider')
  return context
}
