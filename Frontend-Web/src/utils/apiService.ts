import type { AssistantResponse, BookingSummary, ChatMessage, TripQuery } from '../types/trip'

const PREF_KEY = 'veyn_api_base_url'

export const CANDIDATE_URLS = [
  'http://localhost:8000',
  'http://127.0.0.1:8000',
  'http://192.168.100.15:8000',
  'http://192.168.100.6:8000',
]

class ApiService {
  private _customBaseUrl: string | null = null

  constructor() {
    if (typeof window !== 'undefined') {
      const saved = localStorage.getItem(PREF_KEY)
      if (saved && saved.trim().length > 0) {
        this._customBaseUrl = saved.trim()
      }
    }
  }

  get baseUrl(): string {
    return this._customBaseUrl || 'http://localhost:8000'
  }

  set baseUrl(url: string) {
    const clean = url.trim().replace(/\/+$/, '')
    this._customBaseUrl = clean
    if (typeof window !== 'undefined') {
      localStorage.setItem(PREF_KEY, clean)
    }
  }

  async checkHealth(targetUrl?: string): Promise<boolean> {
    const url = (targetUrl ?? this.baseUrl).trim().replace(/\/+$/, '')
    try {
      const controller = new AbortController()
      const timeoutId = setTimeout(() => controller.abort(), 3500)
      const res = await fetch(`${url}/health`, {
        method: 'GET',
        signal: controller.signal,
      })
      clearTimeout(timeoutId)
      return res.ok
    } catch {
      return false
    }
  }

  async autoDetectWorkingUrl(): Promise<string | null> {
    if (await this.checkHealth(this.baseUrl)) return this.baseUrl

    for (const url of CANDIDATE_URLS) {
      if (url === this.baseUrl) continue
      if (await this.checkHealth(url)) {
        this.baseUrl = url
        return url
      }
    }
    return null
  }

  async sendChat({
    question,
    trip,
    messages,
    language = 'fr',
    sessionId = 'veyn-web-session',
  }: {
    question: string
    trip: TripQuery
    messages: ChatMessage[]
    language?: string
    sessionId?: string
  }): Promise<AssistantResponse | null> {
    const recentMessages = messages.slice(-6).map((m) => ({
      role: m.role,
      text: m.text,
    }))

    const payload = {
      session_id: sessionId,
      question,
      trip,
      messages: recentMessages,
      language,
    }

    try {
      const res = await fetch(`${this.baseUrl}/api/chat`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload),
      })
      if (res.ok) {
        return (await res.json()) as AssistantResponse
      }
    } catch (err) {
      console.warn('[ApiService] Échec sur baseUrl, recherche d\'une URL alternative...', err)
    }

    const workingUrl = await this.autoDetectWorkingUrl()
    if (workingUrl && workingUrl !== this.baseUrl) {
      try {
        const res = await fetch(`${workingUrl}/api/chat`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(payload),
        })
        if (res.ok) {
          return (await res.json()) as AssistantResponse
        }
      } catch (err) {
        console.error('[ApiService] Échec sur fallback URL:', err)
      }
    }

    return null
  }

  async bookTrip(booking: BookingSummary): Promise<boolean> {
    try {
      const res = await fetch(`${this.baseUrl}/api/book`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(booking),
      })
      return res.ok
    } catch (err) {
      console.error('[ApiService] bookTrip error:', err)
      return false
    }
  }

  async transcribeAudio(audioBlob: Blob): Promise<string | null> {
    const formData = new FormData()
    formData.append('file', audioBlob, 'audio.webm')

    try {
      const res = await fetch(`${this.baseUrl}/api/transcribe`, {
        method: 'POST',
        body: formData,
      })
      if (res.ok) {
        const data = await res.json()
        return data.text || ''
      }
    } catch (err) {
      console.error('[ApiService] transcribeAudio error:', err)
    }
    return null
  }
}

export const apiService = new ApiService()
