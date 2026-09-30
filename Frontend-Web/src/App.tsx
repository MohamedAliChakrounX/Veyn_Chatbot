import React from 'react'
import { LanguageProvider } from './contexts/LanguageContext'
import { TripProvider } from './contexts/TripContext'
import { HistoryProvider } from './contexts/HistoryContext'
import { Chat } from './pages/Chat'

export function App() {
  return (
    <LanguageProvider>
      <HistoryProvider>
        <TripProvider>
          <Chat />
        </TripProvider>
      </HistoryProvider>
    </LanguageProvider>
  )
}
export default App;

