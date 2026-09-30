import {
  BusIcon,
  CarTaxiFrontIcon,
  CircleEllipsisIcon,
  PlaneIcon,
  ShipIcon,
  TrainFrontIcon,
} from 'lucide-react'
import type { LucideIcon } from 'lucide-react'
import type { TimePeriod, TransportMode } from '../types/trip'

export interface TransportOption {
  id: TransportMode
  label: string
  icon: LucideIcon
  /** Type de point de montée annoncé dans l'itinéraire. */
  stopWording: string
}

export const TRANSPORT_OPTIONS: TransportOption[] = [
  { id: 'bus', label: 'Bus', icon: BusIcon, stopWording: 'Gare routière' },
  { id: 'shared_taxi', label: 'Taxi collectif / Louage', icon: CarTaxiFrontIcon, stopWording: 'Station de louages' },
  { id: 'train', label: 'Train', icon: TrainFrontIcon, stopWording: 'Gare' },
  { id: 'plane', label: 'Avion', icon: PlaneIcon, stopWording: 'Aéroport' },
  { id: 'ferry', label: 'Ferry', icon: ShipIcon, stopWording: 'Port' },
  { id: 'other', label: 'Autre', icon: CircleEllipsisIcon, stopWording: 'Point de rendez-vous' },
]

export interface PeriodOption {
  id: TimePeriod
  label: string
  range: string
}

export const PERIOD_OPTIONS: PeriodOption[] = [
  { id: 'morning', label: 'Matin', range: '05h – 12h' },
  { id: 'afternoon', label: 'Après-midi', range: '12h – 18h' },
  { id: 'evening', label: 'Soir', range: '18h – 23h' },
  { id: 'exact', label: 'Heure précise', range: 'Choisir' },
]

export interface TravelerCategory {
  id: 'adults' | 'children' | 'assisted'
  label: string
  hint?: string
  min: number
}

export const TRAVELER_CATEGORIES: TravelerCategory[] = [
  { id: 'adults', label: 'Adulte', hint: '12 ans et plus', min: 0 },
  { id: 'children', label: 'Enfant', hint: 'Moins de 6 ans', min: 0 },
  { id: 'assisted', label: 'Personne en situation de handicap', hint: 'Assistance à l’embarquement', min: 0 },
]

export const BUDGET_SUGGESTIONS = [80, 150, 300]

export const START_SUGGESTIONS = [
  'Je veux aller de Tripoli à Tunis demain matin avec 2 adultes.',
  'Je cherche les horaires pour Tunis vers Tripoli pour aujourd’hui.',
  'Quels sont les trajets de Misrata vers Tunis ?',
  'Donne-moi les prix entre Tripoli et Sfax.',
]
