import React, { useEffect, useState } from 'react'
import { createPortal } from 'react-dom'

interface ModalPortalProps {
  children: React.ReactNode
}

/**
 * Téléporte les fenêtres modales et dialogues directement dans document.body
 * pour éviter tout piège de bloc conteneur CSS lié aux transformations Framer Motion,
 * filtres, ou overflow: hidden/auto d'éléments parents.
 */
export function ModalPortal({ children }: ModalPortalProps) {
  const [mounted, setMounted] = useState(false)

  useEffect(() => {
    setMounted(true)
    return () => setMounted(false)
  }, [])

  if (!mounted || typeof document === 'undefined') {
    return null
  }

  return createPortal(children, document.body)
}
