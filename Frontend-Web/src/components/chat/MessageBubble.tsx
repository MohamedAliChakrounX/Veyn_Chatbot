import React from 'react'
import { motion } from 'framer-motion'
import ReactMarkdown from 'react-markdown'
import type { MessageRole } from '../../types/trip'

interface MessageBubbleProps {
  role: MessageRole
  children: React.ReactNode
}

export function MessageBubble({ role, children }: MessageBubbleProps) {
  const isUser = role === 'user'
  const isText = typeof children === 'string'

  return (
    <motion.div
      initial={{ opacity: 0, y: 6 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.18, ease: [0.23, 1, 0.32, 1] }}
      className={`max-w-[85%] px-4 py-3 text-[14px] leading-relaxed sm:max-w-[75%] ${
        isUser
          ? 'self-end rounded-2xl rounded-br-md bg-ink text-white whitespace-pre-wrap'
          : 'self-start rounded-2xl rounded-bl-md border border-line bg-surface text-ink-soft shadow-sm'
      }`}
    >
      {isUser || !isText ? (
        children
      ) : (
        <div className="prose-chat text-[14px]">
          <ReactMarkdown
            components={{
              h1: ({ children }) => (
                <h2 className="text-[16px] font-bold text-ink mt-3 mb-1.5 first:mt-0 tracking-tight">
                  {children}
                </h2>
              ),
              h2: ({ children }) => (
                <h2 className="text-[15px] font-bold text-ink mt-3 mb-1.5 first:mt-0 tracking-tight">
                  {children}
                </h2>
              ),
              h3: ({ children }) => (
                <h3 className="text-[14px] font-semibold text-ink mt-2.5 mb-1 tracking-tight">
                  {children}
                </h3>
              ),
              p: ({ children }) => (
                <p className="mb-2 last:mb-0 leading-relaxed text-ink-soft">
                  {children}
                </p>
              ),
              strong: ({ children }) => (
                <strong className="font-semibold text-ink">
                  {children}
                </strong>
              ),
              em: ({ children }) => (
                <em className="italic text-ink-soft">{children}</em>
              ),
              ul: ({ children }) => (
                <ul className="my-2 ms-4 list-disc space-y-1 text-ink-soft">
                  {children}
                </ul>
              ),
              ol: ({ children }) => (
                <ol className="my-2 ms-4 list-decimal space-y-1 text-ink-soft">
                  {children}
                </ol>
              ),
              li: ({ children }) => (
                <li className="leading-relaxed ps-0.5">{children}</li>
              ),
            }}
          >
            {children as string}
          </ReactMarkdown>
        </div>
      )}
    </motion.div>
  )
}

