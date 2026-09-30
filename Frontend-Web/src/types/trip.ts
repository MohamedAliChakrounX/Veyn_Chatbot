export type CountryCode = 'TN' | 'DZ' | 'LY' | 'EG'

export interface Country {
  code: CountryCode
  name: string
  currency: string
}

export interface City {
  id: string
  name: string
  country: CountryCode
  /** Variantes sans accents / translittérations utilisées par la recherche. */
  aliases: string[]
  nameAr?: string
  nameFr?: string
  nameEn?: string
}

export type TimePeriod = 'morning' | 'afternoon' | 'evening' | 'exact'

export type TransportMode = 'bus' | 'train' | 'shared_taxi' | 'plane' | 'ferry' | 'other'

export interface Travelers {
  adults: number
  children: number
  assisted: number
}

export interface TripQuery {
  origin: City | null
  destination: City | null
  travelers: Travelers
  /** Date ISO principale (yyyy-mm-dd) pour rétrocompatibilité. */
  date: string | null
  /** Multi-dates ISO sélectionnées (yyyy-mm-dd). */
  dates?: string[]
  period: TimePeriod | null
  /** Multi-périodes sélectionnées (morning, afternoon, evening). */
  periods?: TimePeriod[]
  /** Heure exacte (HH:mm), utilisée quand period === 'exact'. */
  exactTime: string | null
  modes: TransportMode[]
  budget: number | null
  directOnly?: boolean
}

export type TripField =
  | 'origin'
  | 'destination'
  | 'travelers'
  | 'date'
  | 'time'
  | 'modes'
  | 'budget'

export interface TripConflict {
  field: TripField
  question: string
  currentLabel: string
  proposedLabel: string
  /** Valeurs à appliquer si l'utilisateur confirme la proposition. */
  proposed: Partial<TripQuery>
}

export type StopKind = 'origin' | 'stop' | 'border' | 'destination'

export interface TripStop {
  /** Nom du point d'arrêt (ville, gare routière, poste frontière). */
  name: string
  /** Détail du lieu de montée / descente. */
  place: string
  /** Heure de passage (HH:mm). */
  time: string
  kind: StopKind
  /** Durée d'arrêt en minutes, quand elle est connue. */
  waitMinutes?: number
}

export interface TripResult {
  id: string
  departure: string
  arrival: string
  durationLabel: string
  mode: TransportMode
  transfers: number
  price: number
  currency: string
  operator: string
  seatsLeft: number | null
  badge?: string
  date?: string
  /** Itinéraire complet, départ et arrivée inclus. */
  stops: TripStop[]
}

export type MessageRole = 'user' | 'assistant'

export interface QuickReply {
  label: string
  /** Texte envoyé au chatbot quand la réponse rapide est tapée. */
  value: string
}

/** Représente une précision figée (immuable) associée à une question envoyée. */
export interface TripPrecisionItem {
  field: TripField
  label: string
}

export interface ChatMessage {
  id: string
  role: MessageRole
  text: string
  /** Champs reconnus à afficher en puces sous le message. */
  chipFields?: TripField[]
  results?: TripResult[]
  conflict?: TripConflict
  quickReplies?: QuickReply[]
  isError?: boolean
  /** Message de repli affiché quand aucun trajet ne correspond. */
  noResults?: boolean
  /** Récapitulatif d'une réservation confirmée. */
  booking?: BookingSummary
  /** Précisions figées capturées au moment de l'envoi du message. */
  precisions?: TripPrecisionItem[]
  /** Snapshot immuable de TripQuery au moment de l'envoi — utilisé pour les réponses du bot. */
  querySnapshot?: TripQuery
}

export interface AssistantResponse {
  reply: string
  tripPatch?: Partial<TripQuery>
  recognized?: TripField[]
  results?: TripResult[]
  conflict?: TripConflict
  missing?: TripField[]
  quickReplies?: QuickReply[]
  noResults?: boolean
}

export interface BookingSummary {
  reference: string
  result: TripResult
  travelers: number
  travelersDetail?: Travelers
  travelersLabel?: string
  total: number
  currency: string
  boardingStop: TripStop
  routeLabel: string
  paymentMethod?: string
  cardType?: string
  cardLast4?: string
}

export interface Conversation {
  id: string
  title: string
  routeLabel: string | null
  /** Horodatage ISO de la dernière activité. */
  updatedAt: string
  messages: ChatMessage[]
  trip: TripQuery
  resultCount: number
  bookingCount: number
}
