import { useState, useRef, useCallback } from 'react'

export interface AudioRecorderState {
  isRecording: boolean
  recordingTime: number
  isTranscribing: boolean
  error: string | null
  startRecording: () => Promise<void>
  stopAndTranscribe: () => Promise<string | null>
  cancelRecording: () => void
}

export function useAudioRecorder(): AudioRecorderState {
  const [isRecording, setIsRecording] = useState(false)
  const [recordingTime, setRecordingTime] = useState(0)
  const [isTranscribing, setIsTranscribing] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const mediaRecorderRef = useRef<MediaRecorder | null>(null)
  const audioChunksRef = useRef<Blob[]>([])
  const streamRef = useRef<MediaStream | null>(null)
  const timerRef = useRef<number | null>(null)

  const cleanupStream = useCallback(() => {
    if (streamRef.current) {
      streamRef.current.getTracks().forEach((track) => track.stop())
      streamRef.current = null
    }
    if (timerRef.current) {
      window.clearInterval(timerRef.current)
      timerRef.current = null
    }
    audioChunksRef.current = []
    mediaRecorderRef.current = null
    setRecordingTime(0)
  }, [])

  const startRecording = useCallback(async () => {
    setError(null)
    try {
      if (!navigator.mediaDevices || !navigator.mediaDevices.getUserMedia) {
        throw new Error("L'enregistrement audio n'est pas supporté par votre navigateur.")
      }

      const stream = await navigator.mediaDevices.getUserMedia({ audio: true })
      streamRef.current = stream

      let mimeType = ''
      if (typeof MediaRecorder !== 'undefined') {
        if (MediaRecorder.isTypeSupported('audio/webm;codecs=opus')) {
          mimeType = 'audio/webm;codecs=opus'
        } else if (MediaRecorder.isTypeSupported('audio/webm')) {
          mimeType = 'audio/webm'
        } else if (MediaRecorder.isTypeSupported('audio/mp4')) {
          mimeType = 'audio/mp4'
        }
      }

      const mediaRecorder = mimeType
        ? new MediaRecorder(stream, { mimeType })
        : new MediaRecorder(stream)

      mediaRecorderRef.current = mediaRecorder
      audioChunksRef.current = []

      mediaRecorder.ondataavailable = (event) => {
        if (event.data && event.data.size > 0) {
          audioChunksRef.current.push(event.data)
        }
      }

      mediaRecorder.start(100) // Récolte des données toutes les 100ms
      setIsRecording(true)
      setRecordingTime(0)

      timerRef.current = window.setInterval(() => {
        setRecordingTime((prev) => prev + 1)
      }, 1000)
    } catch (err: any) {
      console.error('[AudioRecorder] Erreur accès micro :', err)
      setError(err?.message || "Impossible d'accéder au microphone.")
      cleanupStream()
      setIsRecording(false)
    }
  }, [cleanupStream])

  const cancelRecording = useCallback(() => {
    if (mediaRecorderRef.current && mediaRecorderRef.current.state !== 'inactive') {
      mediaRecorderRef.current.stop()
    }
    cleanupStream()
    setIsRecording(false)
  }, [cleanupStream])

  const stopAndTranscribe = useCallback(async (): Promise<string | null> => {
    if (!mediaRecorderRef.current) {
      return null
    }

    return new Promise((resolve) => {
      const recorder = mediaRecorderRef.current!

      recorder.onstop = async () => {
        const chunks = audioChunksRef.current
        const mimeType = recorder.mimeType || 'audio/webm'
        const audioBlob = new Blob(chunks, { type: mimeType })
        cleanupStream()
        setIsRecording(false)

        if (audioBlob.size === 0) {
          resolve(null)
          return
        }

        setIsTranscribing(true)
        setError(null)

        try {
          const extension = mimeType.includes('mp4') ? 'm4a' : 'webm'
          const formData = new FormData()
          formData.append('file', audioBlob, `voice_message.${extension}`)

          const response = await fetch('http://localhost:8000/api/transcribe', {
            method: 'POST',
            body: formData,
          })

          if (!response.ok) {
            const errData = await response.json().catch(() => ({}))
            throw new Error(errData.detail || `Erreur serveur ${response.status}`)
          }

          const data = await response.json()
          const transcription = data.text || ''
          resolve(transcription)
        } catch (err: any) {
          console.error('[AudioRecorder] Erreur transcription :', err)
          setError(err?.message || 'Erreur lors de la transcription.')
          resolve(null)
        } finally {
          setIsTranscribing(false)
        }
      }

      if (recorder.state !== 'inactive') {
        recorder.stop()
      } else {
        recorder.onstop?.(new Event('stop'))
      }
    })
  }, [cleanupStream])

  return {
    isRecording,
    recordingTime,
    isTranscribing,
    error,
    startRecording,
    stopAndTranscribe,
    cancelRecording,
  }
}
