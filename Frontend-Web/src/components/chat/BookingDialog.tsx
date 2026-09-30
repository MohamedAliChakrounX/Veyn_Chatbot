import React, { useCallback, useEffect, useMemo, useRef, useState } from 'react'
import { AnimatePresence, motion } from 'framer-motion'
import {
  AlertCircleIcon,
  AlertTriangleIcon,
  ArrowLeftIcon,
  BadgeCheckIcon,
  BanknoteIcon,
  CalendarIcon,
  CheckCircle2Icon,
  ChevronDownIcon,
  ClipboardCopyIcon,
  CreditCardIcon,
  LockIcon,
  MapPinnedIcon,
  MinusIcon,
  PlusIcon,
  RefreshCwIcon,
  ShieldCheckIcon,
  SmartphoneIcon,
  UserIcon,
  UsersIcon,
  XIcon,
} from 'lucide-react'
import { TRANSPORT_OPTIONS } from '../../data/options'
import { useTrip } from '../../contexts/TripContext'
import { useLanguage } from '../../contexts/LanguageContext'
import { dateLabel, routeLabel } from '../../utils/trip'
import type { BookingSummary, Travelers, TripResult, TripStop } from '../../types/trip'
import { StopsTimeline } from './StopsTimeline'
import { ModalPortal } from '../common/ModalPortal'

interface BookingDialogProps {
  result: TripResult
  onClose: () => void
  onConfirm: (booking: BookingSummary) => void
}

type Phase = 'confirm' | 'payment' | 'processing' | 'done' | 'error'
type PaymentMethod = 'card' | 'mobile_tn' | 'mobile_ly' | 'mobile_dz' | 'cash'
export type CardBrandType = 'visa' | 'mastercard' | 'cib' | 'edinar'

interface CardBrand {
  id: CardBrandType
  name: string
  label: string
  gradient: string
  accentColor: string
  patternColor: string
}

const CARD_BRANDS: CardBrand[] = [
  {
    id: 'visa',
    name: 'Visa',
    label: 'Visa',
    gradient: 'from-[#1A1F71] via-[#0D47A1] to-[#1565C0]',
    accentColor: '#F7B600',
    patternColor: 'rgba(255, 255, 255, 0.08)',
  },
  {
    id: 'mastercard',
    name: 'Mastercard',
    label: 'Mastercard',
    gradient: 'from-[#1E1E24] via-[#2B2D42] to-[#1A1A1D]',
    accentColor: '#EB001B',
    patternColor: 'rgba(255, 255, 255, 0.06)',
  },
  {
    id: 'cib',
    name: 'CIB',
    label: 'CIB',
    gradient: 'from-[#004D40] via-[#00695C] to-[#00796B]',
    accentColor: '#4DB6AC',
    patternColor: 'rgba(255, 255, 255, 0.08)',
  },
  {
    id: 'edinar',
    name: 'e-Dinar',
    label: 'e-Dinar',
    gradient: 'from-[#0D2538] via-[#103E65] to-[#B26A00]',
    accentColor: '#FFB300',
    patternColor: 'rgba(255, 255, 255, 0.08)',
  },
]

function VisaLogo({ className = 'h-5' }: { className?: string }) {
  return (
    <svg className={className} viewBox="0 0 54 18" fill="none" xmlns="http://www.w3.org/2000/svg">
      <path
        d="M21.5 1.5L14.1 16.5H9.2L5.6 4.8C5.4 4.1 5.2 3.8 4.5 3.5C3.5 3 1.7 2.5 0 2.2L0.1 1.5H7.8C8.8 1.5 9.7 2.1 9.9 3.1L11.8 12L16.5 1.5H21.5ZM40.5 11.5C40.5 7.5 34.2 7.3 34.3 5.5C34.3 5 34.8 4.4 36.1 4.3C36.7 4.2 38.3 4.2 40.2 5L40.9 2C39.9 1.7 38.6 1.4 36.9 1.4C32.4 1.4 29.3 3.5 29.2 6.5C29.2 8.7 31.4 10 33.1 10.7C34.9 11.5 35.5 12 35.5 12.7C35.5 13.7 34.1 14.2 32.8 14.2C30.5 14.2 29.2 13.6 28.1 13.2L27.3 16.4C28.4 16.8 30.5 17.2 32.6 17.2C37.4 17.2 40.4 15.1 40.5 11.5ZM52.4 16.5H56.7L52.9 1.5H48.9C48 1.5 47.2 2 46.9 2.7L40 16.5H44.9L45.9 14.1H51.8L52.4 16.5ZM47.2 10.9L49.7 5L51.1 10.9H47.2ZM28.2 1.5L24.4 16.5H19.7L23.5 1.5H28.2Z"
        fill="currentColor"
      />
    </svg>
  )
}

function MastercardLogo({ className = 'h-5' }: { className?: string }) {
  return (
    <svg className={className} viewBox="0 0 36 24" fill="none" xmlns="http://www.w3.org/2000/svg">
      <circle cx="13" cy="12" r="11" fill="#EB001B" />
      <circle cx="23" cy="12" r="11" fill="#F79E1B" fillOpacity="0.86" />
      <path
        d="M18 5.6a11 11 0 0 0 0 12.8 11 11 0 0 0 0-12.8z"
        fill="#FF5F00"
      />
    </svg>
  )
}

function CibBadge({ className = 'h-5' }: { className?: string }) {
  return (
    <div
      className={`inline-flex items-center justify-center font-black tracking-wider px-2 py-0.5 rounded bg-gradient-to-r from-emerald-600 to-teal-700 text-white text-[11px] uppercase shadow-xs ${className}`}
    >
      CIB
    </div>
  )
}

function EdinarBadge({ className = 'h-5' }: { className?: string }) {
  return (
    <div
      className={`inline-flex items-center gap-1 font-extrabold px-2 py-0.5 rounded bg-gradient-to-r from-amber-400 to-yellow-500 text-blue-950 text-[10px] uppercase shadow-xs ${className}`}
    >
      <span>e-Dinar</span>
    </div>
  )
}

function CardBrandIcon({ brand, className }: { brand: CardBrandType; className?: string }) {
  switch (brand) {
    case 'visa':
      return <VisaLogo className={className || 'h-4 text-blue-600'} />
    case 'mastercard':
      return <MastercardLogo className={className || 'h-5'} />
    case 'cib':
      return <CibBadge className={className} />
    case 'edinar':
      return <EdinarBadge className={className} />
  }
}

interface PaymentOption {
  id: PaymentMethod
  label: string
  description: string
  icon: React.ComponentType<{ className?: string }>
  countries?: string[]
  color: string
}

function getPaymentOptions(t: import('../../i18n/translations').TranslationSchema): PaymentOption[] {
  return [
    {
      id: 'card',
      label: t.paymentLabels.card,
      description: t.paymentLabels.cardDesc,
      icon: CreditCardIcon,
      color: 'text-blue-600',
    },
    {
      id: 'mobile_tn',
      label: t.paymentLabels.mobileTn,
      description: t.paymentLabels.mobileTnDesc,
      icon: SmartphoneIcon,
      countries: ['TN'],
      color: 'text-red-600',
    },
    {
      id: 'mobile_ly',
      label: t.paymentLabels.mobileLy,
      description: t.paymentLabels.mobileLyDesc,
      icon: SmartphoneIcon,
      countries: ['LY'],
      color: 'text-green-600',
    },
    {
      id: 'mobile_dz',
      label: t.paymentLabels.mobileDz,
      description: t.paymentLabels.mobileDzDesc,
      icon: SmartphoneIcon,
      countries: ['DZ'],
      color: 'text-emerald-600',
    },
    {
      id: 'cash',
      label: t.paymentLabels.cash,
      description: t.paymentLabels.cashDesc,
      icon: BanknoteIcon,
      color: 'text-amber-600',
    },
  ]
}

function makeReference(): string {
  const random = Math.random().toString(36).slice(2, 7).toUpperCase()
  return `VYN-${random}`
}

function sleep(ms: number) {
  return new Promise((resolve) => setTimeout(resolve, ms))
}

export function BookingDialog({ result, onClose, onConfirm }: BookingDialogProps) {
  const { trip, patchTrip, resetTrip } = useTrip()
  const { t, language, isRTL } = useLanguage()
  const stops = useMemo(() => result.stops ?? [], [result.stops])
  const boardingOptions = useMemo(
    () => stops.filter((stop) => stop.kind === 'origin' || stop.kind === 'stop'),
    [stops],
  )
  const fallbackStop: TripStop = {
    name: t.trip.departure,
    place: `${result.operator} · ${t.booking.departureAtTime}`,
    time: result.departure,
    kind: 'origin',
  }
  const [boarding, setBoarding] = useState<TripStop>(boardingOptions[0] ?? stops[0] ?? fallbackStop)
  const [stopsOpen, setStopsOpen] = useState(false)
  const [phase, setPhase] = useState<Phase>('confirm')
  const [summary, setSummary] = useState<BookingSummary | null>(null)
  const summaryRef = useRef<BookingSummary | null>(null)
  const sentRef = useRef(false)


  // Date sélectionnée
  const bookingDate = result.date || trip.date
  const formattedBookingDate = dateLabel(bookingDate, language) ?? (bookingDate ? bookingDate : t.trip.today)


  // Voyageurs éditables
  const [travelers, setTravelers] = useState<Travelers>(() => {
    const t = trip.travelers
    const sum = (t.adults || 0) + (t.children || 0) + (t.assisted || 0)
    if (sum > 0) {
      return {
        adults: Math.max(1, t.adults || 1),
        children: Math.max(0, t.children || 0),
        assisted: Math.max(0, t.assisted || 0),
      }
    }
    return { adults: 1, children: 0, assisted: 0 }
  })

  const updateTravelers = (category: keyof Travelers, count: number) => {
    const nextTravelers = { ...travelers, [category]: count }
    setTravelers(nextTravelers)
    patchTrip({ travelers: nextTravelers })
  }

  const totalTravelers = Math.max(1, travelers.adults + travelers.children + travelers.assisted)
  const total = result.price * totalTravelers
  const option = TRANSPORT_OPTIONS.find((entry) => entry.id === result.mode)
  const route = routeLabel(trip) ?? `${stops[0]?.name ?? ''} → ${stops[stops.length - 1]?.name ?? ''}`

  const travelersText = useMemo(() => {
    const parts: string[] = []
    if (travelers.adults > 0)
      parts.push(`${travelers.adults} ${travelers.adults > 1 ? t.travelers.adults : t.travelers.adult}`)
    if (travelers.children > 0)
      parts.push(`${travelers.children} ${travelers.children > 1 ? t.travelers.children : t.travelers.child}`)
    if (travelers.assisted > 0)
      parts.push(`${travelers.assisted} ${travelers.assisted > 1 ? t.travelers.assisteds : t.travelers.assisted}`)
    return parts.join(', ') || t.travelers.defaultOne
  }, [travelers, t])

  // ── Mode de paiement & Choix de la carte ──────────────────────────────────
  const [selectedPayment, setSelectedPayment] = useState<PaymentMethod>('card')
  const [selectedCardBrand, setSelectedCardBrand] = useState<CardBrandType>('visa')
  const [cardHolder, setCardHolder] = useState('')
  const [cardNumber, setCardNumber] = useState('')
  const [cardExpiry, setCardExpiry] = useState('')
  const [cardCvv, setCardCvv] = useState('')
  const [phoneNumber, setPhoneNumber] = useState('')
  const [copiedRef, setCopiedRef] = useState(false)

  // Détection automatique du type de carte selon les premiers chiffres
  const handleCardNumberChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const raw = e.target.value.replace(/\D/g, '').slice(0, 16)
    const formatted = raw.replace(/(.{4})/g, '$1 ').trim()
    setCardNumber(formatted)

    if (raw.startsWith('4')) {
      setSelectedCardBrand('visa')
    } else if (raw.startsWith('5') || raw.startsWith('2')) {
      setSelectedCardBrand('mastercard')
    } else if (raw.startsWith('9')) {
      setSelectedCardBrand('edinar')
    }
  }

  // Filtrer les options de paiement disponibles par pays
  const originCountry = trip.origin?.country ?? (result.stops?.[0]?.name?.includes('Tunis') ? 'TN' : null)

  const availablePaymentOptions = useMemo(() => {
    const allOptions = getPaymentOptions(t)
    return allOptions.filter((opt) => {
      if (!opt.countries) return true
      if (!originCountry) return true
      return opt.countries.includes(originCountry)
    })
  }, [originCountry, t])

  /** Ferme la modale */
  const close = useCallback(() => {
    if (summaryRef.current && !sentRef.current) {
      sentRef.current = true
      onConfirm(summaryRef.current)
      resetTrip()
    }
    onClose()
  }, [onClose, onConfirm, resetTrip])

  useEffect(() => {
    const onKeyDown = (event: KeyboardEvent) => {
      if (event.key === 'Escape') close()
    }
    document.addEventListener('keydown', onKeyDown)
    return () => document.removeEventListener('keydown', onKeyDown)
  }, [close])

  /** Passer au paiement */
  const goToPayment = () => {
    setPhase('payment')
  }

  /** Traitement du paiement */
  const processPay = async () => {
    setPhase('processing')

    await sleep(2000)

    const success = true // Transaction simulée avec succès

    if (success) {
      const activeBrand = CARD_BRANDS.find((b) => b.id === selectedCardBrand)
      const rawNumber = cardNumber.replace(/\s/g, '')
      const last4 = rawNumber.length >= 4 ? rawNumber.slice(-4) : '4242'

      const next: BookingSummary = {
        reference: makeReference(),
        result: {
          ...result,
          date: bookingDate || undefined,
        },
        travelers: totalTravelers,
        travelersDetail: travelers,
        travelersLabel: travelersText,
        total,
        currency: result.currency,
        boardingStop: boarding,
        routeLabel: route,
        paymentMethod:
          selectedPayment === 'card'
            ? `${t.paymentLabels.paymentMethodCard} (${activeBrand?.name ?? 'Visa'})`
            : selectedPayment === 'cash'
            ? t.paymentLabels.paymentMethodCash
            : t.paymentLabels.paymentMethodMobile,
        cardType: selectedPayment === 'card' ? (activeBrand?.name ?? 'Visa') : undefined,
        cardLast4: selectedPayment === 'card' ? last4 : undefined,
      }

      try {
        await fetch('http://localhost:8000/api/book', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(next),
        })
      } catch {
        // Fallback offline
      }

      summaryRef.current = next
      setSummary(next)
      setPhase('done')
    } else {
      setPhase('error')
    }
  }

  const retryPayment = () => {
    setPhase('payment')
  }

  const copyReference = () => {
    if (summary?.reference) {
      navigator.clipboard.writeText(summary.reference).catch(() => {})
      setCopiedRef(true)
      setTimeout(() => setCopiedRef(false), 2000)
    }
  }

  const dialogTitle = {
    confirm: t.booking.stepDetails,
    payment: t.booking.stepPayment,
    processing: t.booking.processingTitle,
    done: t.booking.stepConfirmation,
    error: t.paymentLabels.paymentError,
  }[phase]

  const isCardMethod = selectedPayment === 'card'
  const isMobileMethod = selectedPayment.startsWith('mobile')
  const activeCardBrand = CARD_BRANDS.find((b) => b.id === selectedCardBrand) || CARD_BRANDS[0]

  // Formatage du numéro affiché sur la carte virtuelle
  const displayCardNumber = useMemo(() => {
    const clean = cardNumber.replace(/\s/g, '')
    let formatted = ''
    for (let i = 0; i < 16; i++) {
      if (i > 0 && i % 4 === 0) formatted += ' '
      formatted += clean[i] || '•'
    }
    return formatted
  }, [cardNumber])

  return (
    <ModalPortal>
      <div className="fixed inset-0 z-[100] flex items-end justify-center p-0 sm:items-center sm:p-6">
        <motion.button
          type="button"
          aria-label={t.common.close}
          onClick={close}
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ duration: 0.2, ease: [0.23, 1, 0.32, 1] }}
          className="absolute inset-0 cursor-default bg-ink/40 backdrop-blur-xs"
        />
      <motion.div
        role="dialog"
        aria-modal="true"
        aria-labelledby="booking-title"
        initial={{ opacity: 0, y: 16, scale: 0.98 }}
        animate={{ opacity: 1, y: 0, scale: 1 }}
        transition={{ duration: 0.24, ease: [0.23, 1, 0.32, 1] }}
        className="relative flex max-h-[92vh] w-full max-w-lg flex-col overflow-hidden rounded-t-2xl border border-line bg-surface shadow-panel sm:rounded-2xl"
      >
        {/* ─── En-tête ────────────────────────────────────────────────────── */}
        <div className="flex items-center gap-3 border-b border-line px-5 py-4">
          {phase === 'payment' ? (
            <button
              type="button"
              onClick={() => setPhase('confirm')}
              className="flex h-8 w-8 shrink-0 items-center justify-center rounded-full text-ink-muted transition-colors hover:bg-surface-sunken hover:text-ink"
              aria-label={t.common.back}
            >
              <ArrowLeftIcon className={`h-4 w-4 ${isRTL ? 'rotate-180' : ''}`} />
            </button>
          ) : null}
          <div className="min-w-0">
            <h2 id="booking-title" className="text-sm font-semibold text-ink">
              {dialogTitle}
            </h2>
            <p className="mt-0.5 truncate text-xs text-ink-muted">{route}</p>
          </div>
          <button
            type="button"
            onClick={close}
            aria-label={t.common.close}
            className="ms-auto flex h-8 w-8 shrink-0 items-center justify-center rounded-full text-ink-muted transition-colors duration-150 ease-out hover:bg-surface-sunken hover:text-ink"
          >
            <XIcon className="h-4 w-4" aria-hidden="true" />
          </button>
        </div>


        {/* ─── Corps ──────────────────────────────────────────────────────── */}
        <div className="veyn-scroll flex-1 overflow-y-auto">
          <AnimatePresence mode="wait">

            {/* Phase 1 : Confirmation des détails */}
            {phase === 'confirm' ? (
              <motion.div
                key="confirm"
                initial={{ opacity: 0, x: 0 }}
                animate={{ opacity: 1, x: 0 }}
                exit={{ opacity: 0, x: -20 }}
                transition={{ duration: 0.18 }}
                className="px-5 py-4"
              >
                {/* Résumé horaire */}
                <div className="flex flex-wrap items-baseline justify-between gap-x-4 gap-y-1">
                  <p className="text-xl font-bold tabular-nums text-ink">
                    {result.departure} <span className="font-normal text-ink-faint">→</span> {result.arrival}
                  </p>
                  <p className="text-xs text-ink-muted">
                    {option?.label ?? result.mode} · {result.operator} · {result.durationLabel}
                  </p>
                </div>

                {/* Date & Voyageurs */}
                <div className="mt-4 grid grid-cols-1 gap-2.5 sm:grid-cols-2">
                  <div className="rounded-xl border border-line bg-surface-sunken/40 p-3">
                    <div className="flex items-center gap-1.5 text-[11px] font-semibold text-ink-muted">
                      <CalendarIcon className="h-3.5 w-3.5 text-accent" aria-hidden="true" />
                      <span>{t.bookingCard.travelDate}</span>
                    </div>
                    <p className="mt-1 text-sm font-bold capitalize text-ink">{formattedBookingDate}</p>
                    <p className="text-[11px] text-ink-muted">{t.booking.departureAtTime} {result.departure}</p>
                  </div>
                  <div className="rounded-xl border border-line bg-surface-sunken/40 p-3">
                    <div className="flex items-center justify-between">
                      <span className="flex items-center gap-1.5 text-[11px] font-semibold text-ink-muted">
                        <UsersIcon className="h-3.5 w-3.5 text-accent" aria-hidden="true" />
                        <span>{t.booking.summaryTravelers}</span>
                      </span>
                      <span className="rounded-full bg-accent/10 px-2 py-0.5 text-[10px] font-bold text-accent">
                        {totalTravelers} {totalTravelers > 1 ? t.booking.seatPlural : t.booking.seatSingular}
                      </span>
                    </div>
                    <p className="mt-1 text-xs font-semibold text-ink">{travelersText}</p>
                    <p className="text-[11px] text-ink-muted">
                      {result.price} {result.currency} {t.booking.perTraveler}
                    </p>
                  </div>
                </div>

                {/* Compteurs voyageurs */}
                <div className="mt-3 rounded-xl border border-line bg-surface p-3.5">
                  <div className="mb-2.5 flex items-center justify-between">
                    <span className="text-xs font-semibold text-ink">{t.booking.modifyTravelers}</span>
                    <span className="text-[11px] text-ink-muted">{totalTravelers} {t.booking.selectedCount}</span>
                  </div>
                  <div className="space-y-2 divide-y divide-line/60">
                    {[
                      { key: 'adults' as keyof Travelers, label: t.trip.adults, hint: t.trip.adultsHint, min: 1 },
                      { key: 'children' as keyof Travelers, label: t.trip.children, hint: t.trip.childrenHint, min: 0 },
                      { key: 'assisted' as keyof Travelers, label: t.trip.assisted, hint: t.trip.assistedHint, min: 0 },
                    ].map(({ key, label, hint, min }) => (
                      <div key={key} className="flex items-center justify-between pt-2 first:pt-0">
                        <div>
                          <p className="text-xs font-semibold text-ink">{label}</p>
                          <p className="text-[10px] text-ink-muted">{hint}</p>
                        </div>
                        <div className="flex items-center gap-2">
                          <button
                            type="button"
                            onClick={() => updateTravelers(key, Math.max(min, travelers[key] - 1))}
                            disabled={travelers[key] <= min}
                            className="flex h-7 w-7 items-center justify-center rounded-full border border-line text-ink-soft transition-colors hover:border-line-strong hover:text-ink disabled:cursor-not-allowed disabled:opacity-30"
                          >
                            <MinusIcon className="h-3.5 w-3.5" />
                          </button>
                          <span className="w-5 text-center text-xs font-bold tabular-nums text-ink">
                            {travelers[key]}
                          </span>
                          <button
                            type="button"
                            onClick={() => updateTravelers(key, Math.min(9, travelers[key] + 1))}
                            className="flex h-7 w-7 items-center justify-center rounded-full border border-line text-ink-soft transition-colors hover:border-line-strong hover:text-ink"
                          >
                            <PlusIcon className="h-3.5 w-3.5" />
                          </button>
                        </div>
                      </div>
                    ))}
                  </div>
                </div>

                {/* Point de montée */}
                {boardingOptions.length > 1 ? (
                  <fieldset className="mt-4">
                    <legend className="text-[11px] font-semibold text-ink-faint">{t.booking.boardingPointLegend}</legend>
                    <div className="veyn-scroll mt-2 max-h-48 space-y-1 overflow-y-auto overscroll-contain pr-1">
                      {boardingOptions.map((stop) => {
                        const active = stop.name === boarding.name
                        return (
                          <label
                            key={`${stop.name}-${stop.time}`}
                            className={`flex cursor-pointer items-center gap-3 rounded-lg border px-3 py-2 transition-colors duration-150 ease-out ${
                              active ? 'border-ink/30 bg-surface-raised' : 'border-line hover:border-line-strong'
                            }`}
                          >
                            <input
                              type="radio"
                              name="boarding"
                              checked={active}
                              onChange={() => setBoarding(stop)}
                              className="h-4 w-4 accent-ink"
                            />
                            <span className="min-w-0">
                              <span className="block truncate text-[13px] font-medium text-ink">{stop.name}</span>
                              <span className="block truncate text-[11px] text-ink-faint">{stop.place}</span>
                            </span>
                            <span className="ml-auto text-xs font-semibold tabular-nums text-ink-muted">{stop.time}</span>
                          </label>
                        )
                      })}
                    </div>
                  </fieldset>
                ) : null}

                {/* Points d'arrêt déroulants */}
                {stops.length > 0 ? (
                  <div className="mt-4 rounded-xl border border-line bg-surface-sunken/40">
                    <button
                      type="button"
                      onClick={() => setStopsOpen((open) => !open)}
                      aria-expanded={stopsOpen}
                      className="flex w-full items-center gap-2 rounded-xl px-3.5 py-2.5 text-left transition-colors duration-150 ease-out hover:bg-surface-sunken/80"
                    >
                      <MapPinnedIcon className="h-4 w-4 shrink-0 text-accent" aria-hidden="true" />
                      <span className="text-xs font-semibold text-ink">{t.booking.stopsItineraryTitle}</span>
                      <span className="text-[11px] text-ink-muted">({stops.length} {t.booking.stopsCountParenthesis})</span>
                      <ChevronDownIcon
                        className={`ml-auto h-4 w-4 shrink-0 text-ink-faint transition-transform duration-150 ease-out ${stopsOpen ? 'rotate-180' : ''}`}
                        aria-hidden="true"
                      />
                    </button>
                    <AnimatePresence initial={false}>
                      {stopsOpen ? (
                        <motion.div
                          initial={{ height: 0, opacity: 0 }}
                          animate={{ height: 'auto', opacity: 1 }}
                          exit={{ height: 0, opacity: 0 }}
                          transition={{ duration: 0.18, ease: [0.23, 1, 0.32, 1] }}
                          className="overflow-hidden"
                        >
                          <div className="veyn-scroll max-h-60 overflow-y-auto overscroll-contain border-t border-line px-3.5 py-3">
                            <StopsTimeline stops={stops} boardingName={boarding.name} />
                          </div>
                        </motion.div>
                      ) : null}
                    </AnimatePresence>
                  </div>
                ) : null}
              </motion.div>
            ) : null}

            {/* Phase 2 : Mode de paiement & Choix de la carte */}
            {phase === 'payment' ? (
              <motion.div
                key="payment"
                initial={{ opacity: 0, x: 20 }}
                animate={{ opacity: 1, x: 0 }}
                exit={{ opacity: 0, x: 20 }}
                transition={{ duration: 0.18 }}
                className="px-5 py-4"
              >
                {/* Récapitulatif compact */}
                <div className="mb-4 rounded-xl border border-line/70 bg-surface-sunken/50 p-3">
                  <div className="flex items-center justify-between gap-2 text-xs">
                    <span className="font-semibold text-ink">{route}</span>
                    <span className="font-bold text-accent tabular-nums">{total} {result.currency}</span>
                  </div>
                  <div className="mt-1 flex items-center gap-2 text-[11px] text-ink-muted">
                    <CalendarIcon className="h-3 w-3" />
                    <span className="capitalize">{formattedBookingDate}</span>
                    <span>·</span>
                    <UsersIcon className="h-3 w-3" />
                    <span>{travelersText}</span>
                  </div>
                </div>

                {/* Sélecteur de méthode principale */}
                <p className="mb-2 text-xs font-semibold text-ink-muted">
                  {t.booking.paymentMethod} :
                </p>
                <div className="grid grid-cols-1 gap-2 sm:grid-cols-2">
                  {availablePaymentOptions.map((opt) => {
                    const Icon = opt.icon
                    const isSelected = selectedPayment === opt.id
                    return (
                      <button
                        key={opt.id}
                        type="button"
                        onClick={() => setSelectedPayment(opt.id)}
                        className={`flex items-center gap-2.5 rounded-xl border p-2.5 text-left transition-all duration-150 ${
                          isSelected
                            ? 'border-accent bg-accent/5 ring-2 ring-accent/30'
                            : 'border-line bg-surface hover:border-accent/30 hover:bg-surface-elevated'
                        }`}
                      >
                        <div className={`flex h-8 w-8 shrink-0 items-center justify-center rounded-lg bg-surface-sunken ${opt.color}`}>
                          <Icon className="h-4 w-4" />
                        </div>
                        <div className="min-w-0 flex-1">
                          <p className="truncate text-xs font-semibold text-ink">{opt.label}</p>
                          <p className="truncate text-[10px] text-ink-muted">{opt.description}</p>
                        </div>
                        {isSelected ? (
                          <CheckCircle2Icon className="h-4 w-4 shrink-0 text-accent" />
                        ) : null}
                      </button>
                    )
                  })}
                </div>

                {/* ─── Section : Choix de la carte & Carte bancaire virtuelle ─── */}
                <AnimatePresence mode="wait">
                  {isCardMethod ? (
                    <motion.div
                      key="card-section"
                      initial={{ opacity: 0, y: 10 }}
                      animate={{ opacity: 1, y: 0 }}
                      exit={{ opacity: 0, y: -10 }}
                      transition={{ duration: 0.2 }}
                      className="mt-4"
                    >
                      {/* 1. Choix du type de carte */}
                      <div className="mb-3">
                        <label className="block text-xs font-semibold text-ink mb-1.5">
                          {t.booking.chooseCardBrand}
                        </label>
                        <div className="grid grid-cols-2 gap-2 sm:grid-cols-4">
                          {CARD_BRANDS.map((brand) => {
                            const isChosen = selectedCardBrand === brand.id
                            return (
                              <button
                                key={brand.id}
                                type="button"
                                onClick={() => setSelectedCardBrand(brand.id)}
                                className={`flex flex-col items-center justify-center rounded-xl border p-2.5 transition-all duration-150 ${
                                  isChosen
                                    ? 'border-accent bg-accent/10 ring-2 ring-accent/40 shadow-xs scale-[1.02]'
                                    : 'border-line bg-surface hover:border-line-strong hover:bg-surface-sunken'
                                }`}
                              >
                                <div className="flex h-6 items-center justify-center">
                                  <CardBrandIcon brand={brand.id} className="h-5" />
                                </div>
                                <span className={`mt-1.5 text-[11px] font-semibold ${isChosen ? 'text-accent' : 'text-ink'}`}>
                                  {brand.name}
                                </span>
                              </button>
                            )
                          })}
                        </div>
                      </div>

                      {/* 2. Carte virtuelle interactive */}
                      <div className="relative mb-4 overflow-hidden rounded-2xl p-5 text-white shadow-lg transition-all duration-300">
                        {/* Dégradé de fond selon la marque de carte choisie */}
                        <div className={`absolute inset-0 bg-gradient-to-tr ${activeCardBrand.gradient}`} />
                        {/* Motif décoratif */}
                        <div
                          className="absolute inset-0 opacity-20 pointer-events-none"
                          style={{
                            backgroundImage: `radial-gradient(circle at 80% 20%, white 0%, transparent 60%)`,
                          }}
                        />

                        {/* Rangée supérieure : Puce & Logo de la carte */}
                        <div className="relative z-10 flex items-center justify-between">
                          {/* Puce EMV & Contactless */}
                          <div className="flex items-center gap-2">
                            <div className="h-7 w-9 rounded-md bg-gradient-to-br from-amber-300 via-yellow-400 to-amber-500 shadow-inner flex items-center justify-center">
                              <div className="h-4 w-6 rounded border border-amber-600/40 bg-amber-400/80" />
                            </div>
                            {/* Onde sans contact */}
                            <svg className="h-4 w-4 text-white/70" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                              <path d="M8.5 16.5a5 5 0 0 1 0-9" />
                              <path d="M12 19a8.5 8.5 0 0 0 0-14" />
                              <path d="M15.5 21.5a12 12 0 0 0 0-19" />
                            </svg>
                          </div>

                          {/* Logo de la carte sélectionnée */}
                          <div className="flex items-center px-2 py-1 rounded bg-white/10 backdrop-blur-xs">
                            <CardBrandIcon brand={activeCardBrand.id} className="h-5 text-white" />
                          </div>
                        </div>

                        {/* Numéro de la carte */}
                        <div className="relative z-10 mt-5">
                          <p className="font-mono text-lg font-bold tracking-widest text-white/95 drop-shadow-sm sm:text-xl">
                            {displayCardNumber}
                          </p>
                        </div>

                        {/* Rangée inférieure : Titulaire & Expiration */}
                        <div className="relative z-10 mt-4 flex items-end justify-between text-xs">
                          <div>
                            <span className="block text-[9px] uppercase tracking-wider text-white/60">
                              {t.booking.fullName}
                            </span>
                            <span className="block font-semibold uppercase tracking-wider text-white truncate max-w-[160px]">
                              {cardHolder || t.booking.fullNamePlaceholder.toUpperCase()}
                            </span>
                          </div>
                          <div className="text-right">
                            <span className="block text-[9px] uppercase tracking-wider text-white/60">
                              {t.booking.expiry.split('(')[0].trim()}
                            </span>
                            <span className="block font-mono font-bold text-white">
                              {cardExpiry || (language === 'en' ? 'MM/YY' : 'MM/AA')}
                            </span>
                          </div>
                        </div>
                      </div>

                      {/* 3. Formulaire de saisie pour la carte */}
                      <div className="space-y-3 rounded-xl border border-line bg-surface-sunken/40 p-3.5">
                        <div className="flex items-center gap-2 text-xs font-semibold text-ink-muted">
                          <LockIcon className="h-3.5 w-3.5 text-blue-600" />
                          <span>{t.booking.securityBadge}</span>
                        </div>

                        {/* Titulaire de la carte */}
                        <div>
                          <label className="block text-[11px] font-semibold text-ink-muted mb-1">
                            {t.booking.fullName}
                          </label>
                          <div className="relative">
                            <input
                              type="text"
                              value={cardHolder}
                              onChange={(e) => setCardHolder(e.target.value.toUpperCase())}
                              placeholder="MOHAMED BEN ALI"
                              className="w-full rounded-lg border border-line bg-surface px-3 py-2 pl-8 text-xs font-semibold text-ink uppercase placeholder:normal-case placeholder:font-normal placeholder:text-ink-faint focus:border-accent/60 focus:outline-none focus:ring-2 focus:ring-accent/20"
                            />
                            <UserIcon className="absolute left-2.5 top-2.5 h-3.5 w-3.5 text-ink-faint" />
                          </div>
                        </div>

                        {/* Numéro de la carte */}
                        <div>
                          <label className="block text-[11px] font-semibold text-ink-muted mb-1">
                            {t.booking.cardNumber} ({activeCardBrand.name})
                          </label>
                          <div className="relative">
                            <input
                              type="text"
                              value={cardNumber}
                              onChange={handleCardNumberChange}
                              placeholder="0000 0000 0000 0000"
                              maxLength={19}
                              className="w-full rounded-lg border border-line bg-surface px-3 py-2 pr-12 text-sm font-mono font-medium text-ink placeholder:text-ink-faint focus:border-accent/60 focus:outline-none focus:ring-2 focus:ring-accent/20"
                            />
                            <div className="absolute right-2.5 top-2.5 flex items-center">
                              <CardBrandIcon brand={activeCardBrand.id} className="h-4" />
                            </div>
                          </div>
                        </div>

                        {/* Date d'expiration & Code CVV */}
                        <div className="grid grid-cols-2 gap-2">
                          <div>
                            <label className="block text-[11px] font-semibold text-ink-muted mb-1">
                              {t.booking.expiry}
                            </label>
                            <input
                              type="text"
                              value={cardExpiry}
                              onChange={(e) => {
                                const raw = e.target.value.replace(/\D/g, '').slice(0, 4)
                                const formatted = raw.length > 2 ? `${raw.slice(0, 2)}/${raw.slice(2)}` : raw
                                setCardExpiry(formatted)
                              }}
                              placeholder={language === 'en' ? 'MM/YY' : 'MM/AA'}
                              maxLength={5}
                              className="w-full rounded-lg border border-line bg-surface px-3 py-2 text-sm font-mono font-medium text-ink placeholder:text-ink-faint focus:border-accent/60 focus:outline-none focus:ring-2 focus:ring-accent/20"
                            />
                          </div>
                          <div>
                            <label className="block text-[11px] font-semibold text-ink-muted mb-1">
                              {t.booking.cvv}
                            </label>
                            <input
                              type="password"
                              value={cardCvv}
                              onChange={(e) => setCardCvv(e.target.value.replace(/\D/g, '').slice(0, 4))}
                              placeholder="•••"
                              maxLength={4}
                              className="w-full rounded-lg border border-line bg-surface px-3 py-2 text-sm font-mono font-medium text-ink placeholder:text-ink-faint focus:border-accent/60 focus:outline-none focus:ring-2 focus:ring-accent/20"
                            />
                          </div>
                        </div>
                      </div>
                    </motion.div>
                  ) : null}

                  {isMobileMethod ? (
                    <motion.div
                      key="mobile-section"
                      initial={{ opacity: 0, y: 10 }}
                      animate={{ opacity: 1, y: 0 }}
                      exit={{ opacity: 0, y: -10 }}
                      transition={{ duration: 0.18 }}
                      className="mt-4 rounded-xl border border-emerald-200 bg-emerald-50/40 p-4"
                    >
                      <div className="mb-3 flex items-center gap-2">
                        <ShieldCheckIcon className="h-4 w-4 text-emerald-600" />
                        <span className="text-xs font-semibold text-emerald-800">
                          {t.booking.secureMobileTitle}
                        </span>
                      </div>
                      <div>
                        <label className="block text-[11px] font-semibold text-ink-muted mb-1">
                          {t.booking.phoneNumberLabel}
                        </label>
                        <input
                          type="tel"
                          value={phoneNumber}
                          onChange={(e) => setPhoneNumber(e.target.value.replace(/\D/g, '').slice(0, 12))}
                          placeholder="+216 XX XXX XXX"
                          className="w-full rounded-lg border border-line bg-surface px-3 py-2 text-sm font-medium text-ink placeholder:text-ink-faint focus:border-accent/60 focus:outline-none focus:ring-2 focus:ring-accent/20"
                        />
                      </div>
                      <p className="mt-2 text-[11px] text-emerald-700/90">
                        {t.booking.smsNotice}
                      </p>
                    </motion.div>
                  ) : null}

                  {selectedPayment === 'cash' ? (
                    <motion.div
                      key="cash-section"
                      initial={{ opacity: 0, y: 10 }}
                      animate={{ opacity: 1, y: 0 }}
                      exit={{ opacity: 0, y: -10 }}
                      transition={{ duration: 0.18 }}
                      className="mt-4 rounded-xl border border-amber-200 bg-amber-50/50 p-4"
                    >
                      <div className="flex items-start gap-2">
                        <AlertCircleIcon className="mt-0.5 h-4 w-4 shrink-0 text-amber-600" />
                        <div className="text-[12px] leading-relaxed text-amber-900">
                          <p className="font-semibold mb-1">{t.booking.agencyNoticeTitle}</p>
                          <p>{t.booking.agencyNoticeText} <strong>{total} {result.currency}</strong>.</p>
                        </div>
                      </div>
                    </motion.div>
                  ) : null}
                </AnimatePresence>

                {/* Badge sécurité */}
                <div className="mt-4 flex items-center justify-center gap-2 text-[11px] text-ink-muted">
                  <ShieldCheckIcon className="h-3.5 w-3.5 text-emerald-600" />
                  <span>{t.booking.securityBadge}</span>
                </div>
              </motion.div>
            ) : null}

            {/* Phase 3 : Traitement en cours */}
            {phase === 'processing' ? (
              <motion.div
                key="processing"
                initial={{ opacity: 0 }}
                animate={{ opacity: 1 }}
                exit={{ opacity: 0 }}
                transition={{ duration: 0.2 }}
                className="flex flex-col items-center justify-center px-5 py-16 text-center"
              >
                <motion.div
                  animate={{ rotate: 360 }}
                  transition={{ duration: 1.2, repeat: Infinity, ease: 'linear' }}
                  className="mb-5 flex h-16 w-16 items-center justify-center rounded-full border-4 border-accent/20 border-t-accent"
                />
                <p className="text-sm font-semibold text-ink">
                  {t.booking.validatingPayment}
                </p>
                <p className="mt-1.5 text-xs text-ink-muted">
                  {t.booking.connectingBank}
                </p>
              </motion.div>
            ) : null}

            {/* Phase 4 : Succès */}
            {phase === 'done' ? (
              <motion.div
                key="done"
                initial={{ opacity: 0, scale: 0.96 }}
                animate={{ opacity: 1, scale: 1 }}
                transition={{ duration: 0.28, ease: [0.23, 1, 0.32, 1] }}
                className="flex flex-col items-center px-5 py-6 text-center"
              >
                <motion.div
                  initial={{ scale: 0.5, opacity: 0 }}
                  animate={{ scale: 1, opacity: 1 }}
                  transition={{ type: 'spring', stiffness: 260, damping: 18, delay: 0.1 }}
                  className="mb-3 flex h-16 w-16 items-center justify-center rounded-full bg-emerald-100"
                >
                  <CheckCircle2Icon className="h-9 w-9 text-emerald-600" />
                </motion.div>

                <h3 className="text-lg font-bold text-ink">{t.booking.paymentSuccessTitle}</h3>
                <p className="mt-1 text-xs text-ink-muted">{t.booking.paymentSuccessSub}</p>

                {/* Référence avec bouton de copie */}
                <div className="mt-3 flex items-center gap-2 rounded-xl border border-emerald-200 bg-emerald-50 px-4 py-2.5">
                  <BadgeCheckIcon className="h-5 w-5 text-emerald-600" />
                  <span className="text-base font-extrabold tracking-widest text-emerald-800">
                    {summary?.reference}
                  </span>
                  <button
                    type="button"
                    onClick={copyReference}
                    className="ml-1 flex h-7 w-7 items-center justify-center rounded-lg text-emerald-600 transition-colors hover:bg-emerald-100"
                    title={t.booking.copyRefTitle}
                  >
                    {copiedRef ? (
                      <CheckCircle2Icon className="h-4 w-4 text-emerald-500" />
                    ) : (
                      <ClipboardCopyIcon className="h-4 w-4" />
                    )}
                  </button>
                </div>

                {/* Détails du billet */}
                <div className="mt-4 w-full rounded-xl border border-line bg-surface-sunken/50 p-3.5 text-left">
                  <div className="space-y-2 text-xs">
                    <div className="flex items-center justify-between">
                      <span className="text-ink-muted">{t.booking.summaryRoute}</span>
                      <span className="font-semibold text-ink">{route}</span>
                    </div>
                    <div className="flex items-center justify-between">
                      <span className="text-ink-muted">{t.booking.summaryDateTime}</span>
                      <span className="font-semibold capitalize text-ink">
                        {formattedBookingDate} · {result.departure}
                      </span>
                    </div>
                    <div className="flex items-center justify-between">
                      <span className="text-ink-muted">{t.booking.summaryTravelers}</span>
                      <span className="font-semibold text-ink">{travelersText}</span>
                    </div>
                    <div className="flex items-center justify-between">
                      <span className="text-ink-muted">{t.booking.summaryBoarding}</span>
                      <span className="font-semibold text-ink">{boarding.place}</span>
                    </div>
                    <div className="flex items-center justify-between border-t border-line/80 pt-2">
                      <span className="text-ink-muted">{t.booking.summaryPaymentMode}</span>
                      <span className="flex items-center gap-1.5 font-bold text-ink">
                        <CardBrandIcon brand={activeCardBrand.id} className="h-4" />
                        <span>{activeCardBrand.name}</span>
                      </span>
                    </div>
                    <div className="flex items-center justify-between border-t border-line/80 pt-2">
                      <span className="font-bold text-ink">{t.booking.summaryTotalAmount}</span>
                      <span className="text-base font-extrabold text-accent tabular-nums">
                        {total} {result.currency}
                      </span>
                    </div>
                  </div>
                </div>

                <p className="mt-3 text-[11px] text-ink-muted">
                  {t.booking.arriveEarlyNotice}<br />
                  {t.booking.archiveChatNotice}
                </p>
              </motion.div>
            ) : null}

            {/* Phase 5 : Erreur */}
            {phase === 'error' ? (
              <motion.div
                key="error"
                initial={{ opacity: 0, scale: 0.96 }}
                animate={{ opacity: 1, scale: 1 }}
                transition={{ duration: 0.24 }}
                className="flex flex-col items-center px-5 py-10 text-center"
              >
                <div className="mb-4 flex h-20 w-20 items-center justify-center rounded-full bg-red-100">
                  <AlertTriangleIcon className="h-10 w-10 text-red-500" />
                </div>
                <h3 className="text-lg font-bold text-ink">{t.paymentLabels.paymentError}</h3>
                <p className="mt-1.5 max-w-xs text-xs text-ink-muted">
                  {t.errorNotice.message}
                </p>
                <div className="mt-6 flex flex-col gap-2 w-full max-w-xs">
                  <button
                    type="button"
                    onClick={retryPayment}
                    className="flex items-center justify-center gap-2 rounded-full bg-accent px-5 py-2.5 text-xs font-semibold text-white shadow-sm transition-colors hover:bg-accent-hover"
                  >
                    <RefreshCwIcon className="h-3.5 w-3.5" />
                    {t.booking.retryWithCard}
                  </button>
                  <button
                    type="button"
                    onClick={close}
                    className="rounded-full border border-line px-5 py-2.5 text-xs font-semibold text-ink transition-colors hover:border-line-strong"
                  >
                    {t.booking.cancelBtn}
                  </button>
                </div>
              </motion.div>
            ) : null}

          </AnimatePresence>
        </div>

        {/* ─── Pied de modale ─────────────────────────────────────────────── */}
        {phase !== 'processing' && phase !== 'error' ? (
          <div className="flex flex-wrap items-center gap-3 border-t border-line bg-surface-sunken/70 px-5 py-4">
            <div>
              <p className="text-[11px] text-ink-faint">
                {t.booking.totalPlace} ({totalTravelers} {totalTravelers > 1 ? t.booking.seatPlural : t.booking.seatSingular})
              </p>
              <p className="text-lg font-extrabold tabular-nums text-ink">
                {total} {result.currency}
              </p>
            </div>

            {phase === 'confirm' ? (
              <div className="ml-auto flex items-center gap-2">
                <button
                  type="button"
                  onClick={close}
                  className="rounded-full border border-line bg-surface px-4 py-2.5 text-xs font-semibold text-ink transition-colors duration-150 ease-out hover:border-line-strong"
                >
                  {t.booking.cancelBtn}
                </button>
                <button
                  type="button"
                  onClick={goToPayment}
                  className="flex items-center gap-1.5 rounded-full bg-accent px-5 py-2.5 text-xs font-semibold text-white shadow-sm transition-colors duration-150 ease-out hover:bg-accent-hover active:scale-[0.98]"
                >
                  <CreditCardIcon className="h-3.5 w-3.5" />
                  {t.booking.payNow}
                </button>
              </div>
            ) : phase === 'payment' ? (
              <button
                type="button"
                onClick={processPay}
                className="ml-auto flex items-center gap-2 rounded-full bg-accent px-5 py-2.5 text-xs font-semibold text-white shadow-sm transition-all duration-150 ease-out hover:bg-accent-hover active:scale-[0.98]"
              >
                <LockIcon className="h-3.5 w-3.5" />
                {t.booking.payAndConfirm} · {total} {result.currency}
              </button>
            ) : phase === 'done' ? (
              <button
                type="button"
                onClick={close}
                className="ml-auto flex items-center gap-2 rounded-full bg-emerald-600 px-5 py-2.5 text-xs font-semibold text-white shadow-sm transition-colors duration-150 ease-out hover:bg-emerald-700"
              >
                <CheckCircle2Icon className="h-3.5 w-3.5" />
                {t.booking.doneBtn}
              </button>
            ) : null}
          </div>
        ) : null}

        {phase === 'confirm' ? (
          <p className="flex items-start gap-1.5 border-t border-line px-5 py-2.5 text-[11px] text-ink-muted">
            <AlertCircleIcon className="mt-0.5 h-3 w-3 shrink-0 text-ink-faint" aria-hidden="true" />
            {t.booking.provisionalNotice}
          </p>
        ) : null}
      </motion.div>
    </div>
  </ModalPortal>
  )
}
