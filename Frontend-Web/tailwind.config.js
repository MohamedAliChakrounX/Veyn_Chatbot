/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      fontFamily: {
        sans: ['Inter', 'ui-sans-serif', 'system-ui', 'sans-serif'],
      },
      colors: {
        accent: {
          DEFAULT: '#ED1C24',
          hover: '#CE151C',
          soft: '#FEF2F2',
          border: '#FBD5D6',
        },
        ink: {
          DEFAULT: '#18181B',
          soft: '#3F3F46',
          muted: '#71717A',
          faint: '#A1A1AA',
        },
        surface: {
          DEFAULT: '#FFFFFF',
          sunken: '#F7F7F8',
          raised: '#FAFAFA',
        },
        line: {
          DEFAULT: '#E4E4E7',
          strong: '#D4D4D8',
        },
      },
      transitionTimingFunction: {
        out: 'cubic-bezier(0.23, 1, 0.32, 1)',
      },
      boxShadow: {
        panel: '0 -1px 2px rgba(24,24,27,0.03), 0 12px 32px -12px rgba(24,24,27,0.18)',
        card: '0 1px 2px rgba(24,24,27,0.04)',
        drawer: '-12px 0 40px -18px rgba(24,24,27,0.28)',
      },
    },
  },
  plugins: [],
}
