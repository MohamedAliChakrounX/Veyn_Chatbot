import React from "react";
import { AnimatePresence, motion } from "framer-motion";
import { ChevronDownIcon, LucideIcon } from "lucide-react";
import { useLanguage } from "../../contexts/LanguageContext";

interface PanelRowProps {
  id: string;
  label: string;
  value: string | null;
  icon: LucideIcon;
  open: boolean;
  onToggle: () => void;
  children: React.ReactNode;
}

export function PanelRow({
  id,
  label,
  value,
  icon: Icon,
  open,
  onToggle,
  children
}: PanelRowProps) {
  const { t } = useLanguage();

  return (
    <div className={`rounded-xl border transition-colors duration-150 ease-out ${open ? 'border-ink/25 bg-surface-raised' : 'border-line bg-surface hover:border-line-strong'}`}>
      <button
        type="button"
        onClick={onToggle}
        aria-expanded={open}
        aria-controls={`${id}-content`}
        className="flex w-full items-center gap-3 rounded-xl px-3 py-3 text-left focus:outline-none focus-visible:ring-2 focus-visible:ring-ink/20"
      >
        <Icon className="h-4 w-4 shrink-0 text-ink-muted" aria-hidden="true" />
        <span className="text-[13px] font-semibold text-ink">{label}</span>
        <span className={`ml-auto truncate pl-2 text-[13px] ${value ? 'text-ink-soft' : 'text-ink-faint'}`}>
          {value ?? t.tripPanel.optional}
        </span>
        <ChevronDownIcon className={`h-4 w-4 shrink-0 text-ink-faint transition-transform duration-150 ease-out ${open ? 'rotate-180' : ''}`} aria-hidden="true" />
      </button>
      <AnimatePresence initial={false}>
        {open ? (
          <motion.div
            id={`${id}-content`}
            initial={{ height: 0, opacity: 0 }}
            animate={{ height: 'auto', opacity: 1 }}
            exit={{ height: 0, opacity: 0 }}
            transition={{ duration: 0.18, ease: [0.23, 1, 0.32, 1] }}
            className="overflow-hidden"
          >
            <div className="border-t border-line px-3 py-3">{children}</div>
          </motion.div>
        ) : null}
      </AnimatePresence>
    </div>
  );
}
