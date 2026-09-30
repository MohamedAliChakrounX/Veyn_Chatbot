import { cityLabel, cityShortLabel } from '../data/locations'
import { apiService } from './apiService'
import type {
  AssistantResponse,
  ChatMessage,
  TripConflict,
  TripField,
  TripQuery,
} from '../types/trip'
import { extractFromText } from './nlu'
import { buildResults, resultsSummary } from './mockResults'
import { dateLabel, isFieldFilled, timeLabel, travelersLabel, tripCurrency } from './trip'

import type { Language } from '../i18n/translations'

export interface AssistantOptions {
  onSearching?: () => void
  language?: Language
}

const REQUIRED_ORDER: TripField[] = ['origin', 'destination', 'travelers']

function getMissingPrompt(field: TripField, lang: Language = 'fr'): { question: string; quickReplies: { label: string; value: string }[] } {
  if (lang === 'ar') {
    switch (field) {
      case 'origin':
        return {
          question: 'من أي مدينة تود الانطلاق؟',
          quickReplies: [
            { label: 'طرابلس', value: 'أريد الانطلاق من طرابلس.' },
            { label: 'تونس', value: 'أريد الانطلاق من تونس.' },
            { label: 'مصراتة', value: 'أريد الانطلاق من مصراتة.' },
            { label: 'صفاقس', value: 'أريد الانطلاق من صفاقس.' },
          ],
        }
      case 'destination':
        return {
          question: 'إلى أي وجهة تود السفر؟',
          quickReplies: [
            { label: 'تونس', value: 'أريد الذهاب إلى تونس.' },
            { label: 'طرابلس', value: 'أريد الذهاب إلى طرابلس.' },
            { label: 'صفاقس', value: 'أريد الذهاب إلى صفاقس.' },
            { label: 'سوسة', value: 'أريد الذهاب إلى سوسة.' },
          ],
        }
      case 'travelers':
        return {
          question: 'كم عدد المسافرين؟',
          quickReplies: [
            { label: '1 بالغ', value: 'مسافر واحد بالغ.' },
            { label: '2 بالغين', value: 'مسافران بالغان.' },
            { label: 'عائلة مع طفل', value: 'بالغان وطفل واحد.' },
            { label: 'مساعدة ذوي الاحتياجات', value: 'بالغ واحد ومسافر من ذوي الاحتياجات.' },
          ],
        }
      case 'date':
        return {
          question: 'متى ترغب في السفر؟',
          quickReplies: [
            { label: 'اليوم', value: 'أريد السفر اليوم.' },
            { label: 'غداً', value: 'أريد السفر غداً.' },
          ],
        }
      case 'time':
        return { question: 'في أي وقت من اليوم تفضل السفر؟', quickReplies: [] }
      case 'modes':
        return { question: 'ما هي وسيلة النقل المفضلة لديك؟', quickReplies: [] }
      case 'budget':
        return { question: 'هل لديك ميزانية قصوى محددة؟', quickReplies: [] }
    }
  }

  if (lang === 'en') {
    switch (field) {
      case 'origin':
        return {
          question: 'Where are you departing from?',
          quickReplies: [
            { label: 'Tripoli', value: 'I will depart from Tripoli.' },
            { label: 'Tunis', value: 'I will depart from Tunis.' },
            { label: 'Misrata', value: 'I will depart from Misrata.' },
            { label: 'Sfax', value: 'I will depart from Sfax.' },
          ],
        }
      case 'destination':
        return {
          question: 'Where would you like to go?',
          quickReplies: [
            { label: 'Tunis', value: 'I want to go to Tunis.' },
            { label: 'Tripoli', value: 'I want to go to Tripoli.' },
            { label: 'Sfax', value: 'I want to go to Sfax.' },
            { label: 'Sousse', value: 'I want to go to Sousse.' },
          ],
        }
      case 'travelers':
        return {
          question: 'How many travelers are there?',
          quickReplies: [
            { label: '1 adult', value: '1 adult.' },
            { label: '2 adults', value: '2 adults.' },
            { label: 'Family with child', value: '2 adults and 1 child.' },
            { label: 'PRM assistance', value: '1 adult and 1 PRM.' },
          ],
        }
      case 'date':
        return {
          question: 'When would you like to travel?',
          quickReplies: [
            { label: 'Today', value: 'I want to travel today.' },
            { label: 'Tomorrow', value: 'I want to travel tomorrow.' },
          ],
        }
      case 'time':
        return { question: 'What time of day do you prefer?', quickReplies: [] }
      case 'modes':
        return { question: 'Which transport mode do you prefer?', quickReplies: [] }
      case 'budget':
        return { question: 'Do you have a maximum budget?', quickReplies: [] }
    }
  }

  // French (default)
  switch (field) {
    case 'origin':
      return {
        question: 'D’où partez-vous ?',
        quickReplies: [
          { label: 'Tripoli', value: 'Je partirai de Tripoli.' },
          { label: 'Tunis', value: 'Je partirai de Tunis.' },
          { label: 'Misrata', value: 'Je partirai de Misrata.' },
          { label: 'Sfax', value: 'Je partirai de Sfax.' },
        ],
      }
    case 'destination':
      return {
        question: 'Où souhaitez-vous aller ?',
        quickReplies: [
          { label: 'Tunis', value: 'Je veux aller à Tunis.' },
          { label: 'Tripoli', value: 'Je veux aller à Tripoli.' },
          { label: 'Sfax', value: 'Je veux aller à Sfax.' },
          { label: 'Sousse', value: 'Je veux aller à Sousse.' },
        ],
      }
    case 'travelers':
      return {
        question: 'Combien de voyageurs êtes-vous ?',
        quickReplies: [
          { label: '1 adulte', value: '1 adulte.' },
          { label: '2 adultes', value: '2 adultes.' },
          { label: 'Famille avec enfant', value: '2 adultes et 1 enfant.' },
          { label: 'Assistance PMR', value: '1 adulte et 1 PMR.' },
        ],
      }
    case 'date':
      return {
        question: 'Quand souhaitez-vous voyager ?',
        quickReplies: [
          { label: "Aujourd'hui", value: "Je veux partir aujourd'hui." },
          { label: 'Demain', value: 'Je veux partir demain.' },
        ],
      }
    case 'time':
      return { question: 'À quel moment de la journée ?', quickReplies: [] }
    case 'modes':
      return { question: 'Quel moyen de transport préférez-vous ?', quickReplies: [] }
    case 'budget':
      return { question: 'Avez-vous un budget maximum ?', quickReplies: [] }
  }
}

function detectConflict(trip: TripQuery, patch: Partial<TripQuery>, lang: Language = 'fr'): TripConflict | null {
  if (patch.date && trip.date && patch.date !== trip.date) {
    const question =
      lang === 'ar'
        ? 'تم تحديد تاريخين مختلفين. أيهما تفضل اعتماده؟'
        : lang === 'en'
          ? 'Two different dates were provided. Which one would you like to keep?'
          : 'Deux dates différentes ont été indiquées. Laquelle garder ?'
    return {
      field: 'date',
      question,
      currentLabel: dateLabel(trip.date, lang) ?? trip.date,
      proposedLabel: dateLabel(patch.date, lang) ?? patch.date,
      proposed: { date: patch.date },
    }
  }
  if (patch.origin && trip.origin && patch.origin.id !== trip.origin.id) {
    const question =
      lang === 'ar'
        ? 'تم تحديد مدينتي انطلاق مختلفتين. أيهما تفضل اعتمادها؟'
        : lang === 'en'
          ? 'Two different departure points were provided. Which one would you like to keep?'
          : 'Deux lieux de départ différents ont été indiqués. Lequel garder ?'
    return {
      field: 'origin',
      question,
      currentLabel: cityLabel(trip.origin, lang),
      proposedLabel: cityLabel(patch.origin, lang),
      proposed: { origin: patch.origin },
    }
  }
  if (patch.destination && trip.destination && patch.destination.id !== trip.destination.id) {
    const question =
      lang === 'ar'
        ? 'تم تحديد وجهتين مختلفتين. أيهما تفضل اعتمادها؟'
        : lang === 'en'
          ? 'Two different destinations were provided. Which one would you like to keep?'
          : 'Deux destinations différentes ont été indiquées. Laquelle garder ?'
    return {
      field: 'destination',
      question,
      currentLabel: cityLabel(trip.destination, lang),
      proposedLabel: cityLabel(patch.destination, lang),
      proposed: { destination: patch.destination },
    }
  }
  return null
}

function acknowledge(trip: TripQuery, lang: Language = 'fr'): string {
  const parts: string[] = []
  const arrow = lang === 'ar' ? ' ← ' : ' → '
  if (trip.origin && trip.destination) {
    parts.push(`${cityShortLabel(trip.origin, lang)}${arrow}${cityShortLabel(trip.destination, lang)}`)
  }
  const date = dateLabel(trip.date, lang)
  const time = timeLabel(trip, lang)
  if (date) parts.push(time ? `${date} ${time}` : date)
  const travelers = travelersLabel(trip, lang)
  if (travelers) parts.push(travelers)
  if (parts.length === 0) return ''
  if (lang === 'ar') return `تم تسجيل : ${parts.join('، ')}.`
  if (lang === 'en') return `Noted: ${parts.join(', ')}.`
  return `C’est noté : ${parts.join(', ')}.`
}

export async function sendToAssistant(
  messages: ChatMessage[],
  trip: TripQuery,
  options: AssistantOptions = {},
): Promise<AssistantResponse> {
  const lang = options.language ?? 'fr'
  const lastUser = [...messages].reverse().find((message) => message.role === 'user')
  const text = lastUser?.text ?? ''

  // 1. Extraire localement les entités pour une mise à jour instantanée des chips
  const { patch, recognized } = extractFromText(text, trip)
  const conflict = detectConflict(trip, patch, lang)

  if (conflict) {
    const safePatch: Partial<TripQuery> = { ...patch }
    if (conflict.field === 'date') delete safePatch.date
    if (conflict.field === 'origin') delete safePatch.origin
    if (conflict.field === 'destination') delete safePatch.destination
    return {
      reply: conflict.question,
      tripPatch: safePatch,
      recognized: recognized.filter((field) => field !== conflict.field),
      conflict,
    }
  }

  const merged: TripQuery = {
    ...trip,
    ...patch,
    travelers: patch.travelers ?? trip.travelers,
    modes: patch.modes ?? trip.modes,
  }

  const missing = REQUIRED_ORDER.filter((field) => !isFieldFilled(merged, field))

  // Récupérer l'ensemble des champs actifs (combinés depuis le bouton (+) et le texte)
  const activeTripFields: TripField[] = []
  if (merged.origin) activeTripFields.push('origin')
  if (merged.destination) activeTripFields.push('destination')
  if (merged.date) activeTripFields.push('date')
  if (merged.period || merged.exactTime) activeTripFields.push('time')
  if (merged.travelers && (merged.travelers.adults > 0 || merged.travelers.children > 0 || merged.travelers.assisted > 0)) {
    activeTripFields.push('travelers')
  }
  if (merged.modes && merged.modes.length > 0) activeTripFields.push('modes')
  if (merged.budget !== null && merged.budget !== undefined) activeTripFields.push('budget')

  // Si on a des critères complets ou une question libre, interroger l'API FastAPI Backend réelle
  try {
    options.onSearching?.()
    const apiPayload = {
      session_id: 'veyn-session',
      question: text,
      trip: merged,
      messages: messages.slice(-6).map((m) => ({ role: m.role, text: m.text })),
      language: lang,
    }

    const response = await fetch(`${apiService.baseUrl}/api/chat`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(apiPayload),
    })

    if (response.ok) {
      const data: AssistantResponse = await response.json()
      const allRecognized = Array.from(
        new Set([...recognized, ...(data.recognized as TripField[] ?? []), ...activeTripFields])
      ) as TripField[]

      return {
        reply: data.reply,
        tripPatch: { ...patch, ...(data.tripPatch ?? {}) },
        recognized: allRecognized,
        results: data.results,
        conflict: data.conflict,
        missing: data.missing ?? (missing.length > 0 ? missing : undefined),
        quickReplies: data.quickReplies,
        noResults: data.noResults,
      }
    }
  } catch (error) {
    console.warn('Backend /api/chat non joignable, utilisation du traitement direct:', error)
  }

  // Fallback si backend inaccessible
  const fallbackRecognized = Array.from(new Set([...recognized, ...activeTripFields])) as TripField[]

  if (missing.length > 0) {
    const next = missing[0]
    const prompt = getMissingPrompt(next, lang)
    const intro = acknowledge(merged, lang)
    return {
      reply: intro ? `${intro} ${prompt.question}` : prompt.question,
      tripPatch: patch,
      recognized: fallbackRecognized,
      missing,
      quickReplies: prompt.quickReplies,
    }
  }

  const results = buildResults(merged)
  const currency = tripCurrency(merged, lang)

  if (results.length === 0) {
    let noResultsReply = 'Aucun trajet ne correspond à ces critères. Voici ce que je peux ajuster :'
    if (lang === 'ar') {
      noResultsReply =
        merged.budget !== null
          ? `لا توجد رحلات بأقل من ${merged.budget} ${currency} لهذا اليوم. يمكنك تعديل الخيارات التالية :`
          : 'لا توجد رحلات تطابق هذه المعايير. يمكنك تعديل الخيارات التالية :'
    } else if (lang === 'en') {
      noResultsReply =
        merged.budget !== null
          ? `No trips found under ${merged.budget} ${currency} for this day. Here is what you can adjust:`
          : 'No trips match these criteria. Here is what you can adjust:'
    } else if (merged.budget !== null) {
      noResultsReply = `Aucun trajet sous ${merged.budget} ${currency} pour ce jour. Voici ce que je peux ajuster :`
    }

    return {
      reply: noResultsReply,
      tripPatch: patch,
      recognized: fallbackRecognized,
      noResults: true,
    }
  }

  return {
    reply: resultsSummary(results.length, currency, merged.budget, lang),
    tripPatch: patch,
    recognized: fallbackRecognized,
    results,
  }
}
