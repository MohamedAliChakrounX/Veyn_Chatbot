<div align="center">

# Veyn Intelligent Transport Assistant

**Next-generation conversational AI and multimodal transit assistant for intercity and cross-border travel across North Africa.**

[![FastAPI](https://img.shields.io/badge/FastAPI-0.104.1-009688?style=flat-square&logo=fastapi&logoColor=white)](https://fastapi.tiangolo.com)
[![Python](https://img.shields.io/badge/Python-3.10%2B-3776AB?style=flat-square&logo=python&logoColor=white)](https://www.python.org/)
[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=flat-square&logo=flutter&logoColor=white)](https://flutter.dev/)
[![React](https://img.shields.io/badge/React-18.3-61DAFB?style=flat-square&logo=react&logoColor=black)](https://react.dev/)
[![TypeScript](https://img.shields.io/badge/TypeScript-5.5-3178C6?style=flat-square&logo=typescript&logoColor=white)](https://www.typescriptlang.org/)
[![TailwindCSS](https://img.shields.io/badge/TailwindCSS-3.4-06B6D4?style=flat-square&logo=tailwindcss&logoColor=white)](https://tailwindcss.com/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-14%2B-4169E1?style=flat-square&logo=postgresql&logoColor=white)](https://www.postgresql.org/)
[![Groq](https://img.shields.io/badge/Groq-LPU%20Inference-F05A28?style=flat-square)](https://groq.com/)
[![Whisper](https://img.shields.io/badge/Whisper-v3%20Turbo-00A67E?style=flat-square)](https://groq.com/)
[![Gemini](https://img.shields.io/badge/Google-Gemini%20Embeddings-8E75C2?style=flat-square&logo=google&logoColor=white)](https://ai.google.dev/)

<br />

<a href="Veyn_Demo/Veyn_demo.mp4">
  <img src="Veyn_Demo/261shots_so.png" alt="Veyn Transport Assistant Interface Preview" width="850" />
</a>

<p align="center">
  <em>Interactive search results and trip cards across mobile devices. Click the preview to watch the full demonstration video.</em>
</p>

</div>

---

## Table of Contents

- [Project Overview](#project-overview)
- [Video Demonstration](#video-demonstration)
- [Visual Showcase](#visual-showcase)
- [Key Features](#key-features)
- [System Architecture](#system-architecture)
- [Technology Stack](#technology-stack)
- [Project Directory Structure](#project-directory-structure)
- [Installation and Configuration](#installation-and-configuration)
  - [Prerequisites](#prerequisites)
  - [Environment Variables](#environment-variables)
  - [Backend Setup](#backend-setup)
  - [Web Frontend Setup](#web-frontend-setup)
  - [Mobile Application Setup](#mobile-application-setup)
- [API Reference](#api-reference)
- [Future Enhancements](#future-enhancements)
- [Contribution](#contribution)
- [Author and License](#author-and-license)

---

## Project Overview

**Veyn Intelligent Transport Assistant** is an end-to-end multimodal transport booking platform and intelligent assistant. Engineered specifically to address intercity and international transit challenges across North Africa (Tunisia, Libya, Algeria, and Egypt), Veyn streamlines complex transit schedules, variable multi-operator pricing, and company policy inquiries into a single conversational interface.

### The Problem It Solves

- **Fragmented Transit Information**: Commuters frequently struggle with fragmented schedules across distinct bus companies, shared taxis (louages), and regional carriers.
- **Complex Multilingual Queries**: Travelers require assistance in Tunisian, Libyan, and standard Arabic, as well as French and English, often switching languages or speaking through voice notes.
- **Opaque Transport Policies**: Baggage limits, pet transportation, child discounts, and cancellation procedures are rarely indexed in a structured, easily searchable format.
- **Disconnected Booking Workflows**: Users typically query schedules in one place and navigate disparate, non-standard portals to book and pay for their tickets.

### The Solution

Veyn solves these pain points by pairing high-performance semantic search with relational SQL query generation:
- Natural language intent extraction transforms conversational queries directly into verified timetable queries.
- Retrieval-Augmented Generation (RAG) surfaces contextual transport regulations directly from embedded internal policy databases.
- Multi-channel clients (Flutter for iOS/Android and React for modern browsers) deliver interactive schedule cards, real-time seat tracking, and in-chat booking checkout.

---

## Video Demonstration

A complete, high-resolution demonstration video showcasing voice search, multi-turn reasoning, schedule browsing, and checkout is included in the repository.

<div align="center">

| Direct Video Preview |
| :---: |
| <a href="Veyn_Demo/Veyn_demo.mp4"><img src="Veyn_Demo/673shots_so.png" alt="Watch Veyn Demo" width="700" /><br />**Click Here to Watch the Full Video Walkthrough (Veyn_demo.mp4)**</a> |

</div>

> **Note**: If your browser or Markdown viewer does not support direct video rendering, open the file directly via [`Veyn_Demo/Veyn_demo.mp4`](file:///e:/DALY/Stage_Veyn/Veyn-chatbot/Veyn_Demo/Veyn_demo.mp4).

---

## Visual Showcase

The project features a cohesive design language implemented across both Flutter Mobile and React Web, adhering to strict design standards for both Left-to-Right (LTR) and Right-to-Left (RTL) Arabic typography.

<div align="center">

### 1. Conversational Policies & Voice Recording
<img src="Veyn_Demo/481shots_so.png" alt="Conversational Policies and Voice Dictation" width="850" />
<p><em>Semantic policy extraction (child discounts, cancellation timelines, pet travel) and live audio recording via Groq Whisper.</em></p>

<br />

### 2. Trip Parameters & Session History
<img src="Veyn_Demo/424shots_so.png" alt="Trip Criteria Panel and History Drawer" width="850" />
<p><em>Dynamic criteria panel displaying origin, destination, travel dates, passenger counts, and persistent conversation history.</em></p>

<br />

### 3. Interactive Search Results & Route Schedules
<img src="Veyn_Demo/261shots_so.png" alt="Live Search Results and Route Schedules" width="850" />
<p><em>Structured journey cards displaying direct routes, remaining seats, duration, intermediate stops, and multi-date tabs.</em></p>

<br />

### 4. Passenger Details & Multi-Method Checkout
<img src="Veyn_Demo/624shots_so.png" alt="Passenger Details and Multi-Method Checkout" width="850" />
<p><em>Modal passenger configuration (adults, children, special assistance) paired with simulated payment (Visa, Mastercard, CIB, e-Dinar, Cash).</em></p>

<br />

### 5. Ticket Confirmation & Digital Boarding Pass
<img src="Veyn_Demo/673shots_so.png" alt="Ticket Confirmation and Digital Boarding Pass" width="850" />
<p><em>Instant PNR reservation code generation, verified ticket cards injected into the conversation thread, and downloadable booking details.</em></p>

</div>

---

## Key Features

### Multi-Turn Conversational Reasoning
- Parses complex queries with origin, destination, dates, departure time brackets (morning, afternoon, evening), budget, and preferred transport modes.
- Preserves context across multi-turn exchanges, allowing travelers to refine criteria incrementally (e.g., *"Show me only morning departures"* or *"Add one child traveler"*).

### Multi-Modal Audio Transcription
- Integrated voice input powered by Groq Whisper (`whisper-large-v3-turbo` with automatic fallback to `whisper-large-v3`).
- Handles Arabic, French, and English audio inputs with low-latency server-side transcription.

### Real-Time SQL Query Engine
- Connects directly to PostgreSQL with connection pooling (`psycopg2.pool.ThreadedConnectionPool`).
- Employs strict read-only query generation against operational transit tables (`routes`, `route_segments`, `next_schedules`, `stops`, `segment_prices`, `monies`, `currencies`).
- Defends against SQL injection through read-only enforcement and query token validation.

### Knowledge Retrieval-Augmented Generation (RAG)
- Vector semantic indexing over corporate rules and transport guidelines stored in the `configs` database table.
- Employs Google Gemini generative embeddings combined with cosine similarity matching, backed by a persistent disk cache (`config_embeddings_cache.pkl`).

### Interactive Booking and Payment Simulator
- Native booking dialogue directly embedded inside the chat interface.
- Calculates total prices with child/special-needs passenger logic.
- Simulates regional payment methods, including e-Dinar, CIB, Visa, Mastercard, and in-person agency cash payments.
- Generates a unique booking reference code (e.g., `VY-XUK9613`) stored into the active session.

### Native Trilingual and RTL Design
- Full bidirectional layout support (Arabic right-to-left layout and French/English left-to-right).
- Context-aware localization for city names, transit operators, currencies (TND, LYD, DZD, EGP), and dates.

---

## System Architecture

```text
+-----------------------------------------------------------------------------------+
|                                  CLIENT LAYER                                     |
|                                                                                   |
|   +------------------------------------+   +----------------------------------+   |
|   |       Flutter Mobile App           |   |       React 18 Web App           |   |
|   | (Dart, Provider, Lucide, Audio)    |   | (TypeScript, Vite, TailwindCSS)  |   |
|   +-----------------+------------------+   +-----------------+----------------+   |
+---------------------|----------------------------------------|--------------------+
                      |                                        |
                      +-------------------+--------------------+
                                          | HTTP / JSON / Multipart
                                          v
+-----------------------------------------------------------------------------------+
|                             BACKEND API LAYER (FastAPI)                           |
|                                                                                   |
|  Endpoints:                                                                       |
|  * POST /api/chat         -> Multi-turn NLU, trip search & response synthesis     |
|  * POST /api/transcribe   -> Audio stream transcription via Groq Whisper          |
|  * GET  /api/locations    -> Dynamic city autocomplete & multilingual aliases     |
|  * POST /api/book         -> Reservation processing & ticket code issuance        |
|  * GET  /health, /ready   -> Service readiness & database pool health probes      |
+---------------------+-----------------------------------+-------------------------+
                      |                                   |
         +------------v------------+         +------------v------------+
         |     AI & NLU ENGINE     |         |    DATA & SEARCH ENGINE |
         +-------------------------+         +-------------------------+
         | * Groq LPU Inference    |         | * PostgreSQL Database   |
         |   - openai/gpt-oss-120b |         |   (Routes, Schedules,   |
         |   - openai/gpt-oss-20b  |         |    Stops, Prices)       |
         |   - qwen/qwen3.8-27b    |         | * Threaded Pool         |
         | * Groq Whisper STT      |         | * Vector Policy RAG     |
         | * Gemini Embeddings     |         |   (Gemini + Cosine Sim) |
         | * LangChain Agents      |         | * Local Embeddings PKL  |
         +-------------------------+         +-------------------------+
```

---

## Technology Stack

### Backend Services
| Component | Technology | Version / Specification |
| :--- | :--- | :--- |
| Framework | FastAPI | 0.104.1 |
| Server Gateway | Uvicorn (Standard) | 0.24.0 |
| Primary LLM Engine | Groq API | `openai/gpt-oss-120b`, `openai/gpt-oss-20b`, `qwen/qwen3.8-27b` |
| Speech Recognition | Groq Whisper | `whisper-large-v3-turbo`, `whisper-large-v3` |
| Semantic Embeddings | Google Gemini via LangChain | `langchain-google-genai` 0.0.11 |
| Database Connector | Psycopg2 Binary | 2.9.9 (ThreadedConnectionPool) |
| Relational Database | PostgreSQL | 14+ |
| Data Processing | Pandas & Scikit-Learn | Pandas 2.1.4, Scikit-learn 1.3.2, NumPy 1.24.3 |

### Frontend Web Client
| Component | Technology | Version / Specification |
| :--- | :--- | :--- |
| Framework | React | 18.3.1 |
| Build Tool | Vite | 5.4.2 |
| Language | TypeScript | 5.5.3 |
| Styling | TailwindCSS | 3.4.17 with PostCSS & Autoprefixer |
| UI Icons & Primitives | Lucide React & Radix UI | Lucide 0.577.0, Radix Icons 1.3.2 |
| Motion & Animation | Framer Motion | 11.18.2 |
| Content Rendering | React Markdown | 10.1.0 |

### Frontend Mobile Client
| Component | Technology | Version / Specification |
| :--- | :--- | :--- |
| Framework | Flutter SDK | ^3.11.0 |
| State Management | Provider | 6.1.5+1 |
| Audio Recording | Record | 6.2.1 |
| Localization | Flutter Localizations & Intl | intl 0.20.2 (ar, fr, en) |
| Networking | HTTP & HTTP Parser | http 1.6.0, http_parser 4.1.2 |
| Typography & Icons | Google Fonts & Lucide Icons | google_fonts 8.2.1, lucide_icons 0.257.0 |
| Local Storage | Shared Preferences | 2.5.5 |

---

## Project Directory Structure

```text
Veyn-chatbot/
|-- Backend/
|   |-- .env                            # Environment variables (API keys, DB URL)
|   |-- backend.py                      # FastAPI server, NLU engine, RAG pipeline, endpoints
|   |-- config_embeddings_cache.pkl     # Serialized vector embeddings cache for policies
|   |-- requirements.txt                # Python backend package dependencies
|   `-- README.md                       # Backend technical documentation
|
|-- Frontend-Mobile/
|   |-- android/                        # Android build scripts and manifest
|   |-- ios/                            # iOS workspace and configuration
|   |-- lib/
|   |   |-- main.dart                   # Flutter application entry point
|   |   |-- data/                       # Static location datasets and stop definitions
|   |   |-- l10n/                       # Localization strings (Arabic, English, French)
|   |   |-- models/                     # Data models (Trip, Stop, ChatMessage, User)
|   |   |-- providers/                  # State management (Chat, Trip, Language, History)
|   |   |-- screens/                    # ChatScreen main interface
|   |   |-- services/                   # ApiService, HistoryStorage, NLU Fallback
|   |   |-- theme/                      # Veyn color tokens and typography definitions
|   |   `-- widgets/                    # ResultCard, BookingDialog, Composer, TripPanel
|   |-- pubspec.yaml                    # Flutter dependencies and asset configuration
|   `-- README.md                       # Mobile client reference
|
|-- Frontend-Web/
|   |-- index.html                      # HTML5 web shell
|   |-- package.json                    # NPM dependencies and project scripts
|   |-- tailwind.config.js              # TailwindCSS design tokens and theme configuration
|   |-- tsconfig.json                   # TypeScript compiler settings
|   |-- vite.config.ts                  # Vite build and development configuration
|   |-- src/
|   |   |-- App.tsx                     # React root component with Providers
|   |   |-- components/                 # ChatHeader, Composer, ResultCard, BookingDialog
|   |   |-- contexts/                   # TripContext, LanguageContext, HistoryContext
|   |   |-- data/                       # Transit station definitions and localized names
|   |   |-- hooks/                      # useChat, useAudioRecorder custom hooks
|   |   |-- pages/                      # Chat page container
|   |   `-- types/                      # TypeScript interfaces and Pydantic-mirror models
|   `-- README.md                       # Web frontend documentation
|
`-- Veyn_Demo/
    |-- 261shots_so.png                 # Showcase: Trip search results and operator cards
    |-- 424shots_so.png                 # Showcase: Trip precision drawer and history list
    |-- 481shots_so.png                 # Showcase: Policy questions and live voice recording
    |-- 624shots_so.png                 # Showcase: Passenger configuration and payment modal
    |-- 673shots_so.png                 # Showcase: Booking confirmation and reference badge
    `-- Veyn_demo.mp4                   # Complete video demonstration walkthrough
```

---

## Installation and Configuration

### Prerequisites

- **Python**: Version `3.10` or higher
- **Node.js**: Version `18.x` or `20.x LTS` (with `npm` 9+)
- **Flutter SDK**: Version `3.11.0` or higher
- **PostgreSQL**: PostgreSQL instance accessible with transit schema tables populated
- **API Keys**:
  - A [Groq API Key](https://console.groq.com/) for high-speed LLM inference and Whisper STT
  - A [Google AI API Key](https://aistudio.google.com/) for Gemini vector embeddings

---

### Environment Variables

Create a `.env` file inside the `Backend/` directory:

```ini
# Backend/.env

# Groq Cloud API Key (LLM Inference and Audio Transcription)
GROQ_API_KEY=your_groq_api_key_here

# Google Generative AI API Key (Vector Policy Embeddings)
GOOGLE_API_KEY=your_google_ai_api_key_here

# PostgreSQL Database Connection URL (psycopg2 compatible)
DATABASE_URL=postgres://username:password@hostname:5432/database_name

# Optional Supabase Integration
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_KEY=your_supabase_anon_key
```

---

### Backend Setup

1. Navigate to the `Backend` directory:
   ```bash
   cd Backend
   ```

2. Create and activate a Python virtual environment:
   ```bash
   python -m venv venv

   # On Windows (PowerShell):
   .\venv\Scripts\Activate.ps1

   # On Linux / macOS:
   source venv/bin/activate
   ```

3. Install required Python packages:
   ```bash
   pip install --upgrade pip
   pip install -r requirements.txt
   ```

4. Launch the FastAPI server:
   ```bash
   uvicorn backend:app --host 0.0.0.0 --port 8000 --reload
   ```

5. Confirm the server status:
   - Health Check: `http://localhost:8000/health`
   - Readiness Check: `http://localhost:8000/ready`
   - Interactive Swagger API Documentation: `http://localhost:8000/docs`

---

### Web Frontend Setup

1. Navigate to the `Frontend-Web` directory:
   ```bash
   cd Frontend-Web
   ```

2. Install dependencies:
   ```bash
   npm install
   ```

3. Launch the Vite development server:
   ```bash
   npm run dev
   ```

4. Open the application in your browser at `http://localhost:5173/` (or port specified in terminal).

5. To generate a production build:
   ```bash
   npm run build
   ```

---

### Mobile Application Setup

1. Navigate to the `Frontend-Mobile` directory:
   ```bash
   cd Frontend-Mobile
   ```

2. Retrieve Flutter packages:
   ```bash
   flutter pub get
   ```

3. Check device readiness:
   ```bash
   flutter doctor
   ```

4. Run the application on an emulator or connected device:
   ```bash
   # Run on connected device or emulator
   flutter run

   # Run specifically on Chrome for web preview
   flutter run -d chrome
   ```

> **Android Physical Device Tip**: When testing on a physical Android device connected via USB, run `adb reverse tcp:8000 tcp:8000` to direct `http://127.0.0.1:8000` on the device straight to your workstation's FastAPI server.

---

## API Reference

### Core Endpoints

| Method | Endpoint | Description |
| :--- | :--- | :--- |
| `GET` | `/health` | Returns service status (`{"health": "ok"}`). |
| `GET` | `/ready` | Confirms the PostgreSQL connection pool is operational. |
| `POST` | `/api/chat` | Main conversational endpoint supporting multi-turn queries, trip searches, and intent analysis. |
| `POST` | `/api/transcribe` | Transcribes audio files (wav, mp3, m4a, webm) to text using Groq Whisper. |
| `GET` | `/api/locations` | Retrieves supported cities, transit hubs, and multilingual synonyms. |
| `POST` | `/api/book` | Processes booking reservations and returns confirmation records. |

### Sample Conversational Request (`POST /api/chat`)

```json
{
  "question": "What trips are available from Sfax to Tripoli tomorrow morning?",
  "language": "en",
  "trip": {
    "origin": { "name": "Sfax" },
    "destination": { "name": "Tripoli" },
    "travelers": { "adults": 1, "children": 0, "assisted": 0 }
  },
  "messages": []
}
```

### Sample Conversational Response

```json
{
  "message": "I found 2 direct trips matching your criteria from Sfax to Tripoli:",
  "trip": {
    "origin": { "name": "Sfax", "country": "Tunisia" },
    "destination": { "name": "Tripoli", "country": "Libya" },
    "date": "2025-09-25",
    "period": "morning"
  },
  "results": [
    {
      "id": "trip-8492",
      "departure": "06:30",
      "arrival": "15:00",
      "durationLabel": "8h 30m",
      "mode": "bus",
      "transfers": 0,
      "price": 80.0,
      "currency": "TND",
      "operator": "Veyn Express",
      "seatsLeft": 12,
      "badge": "Best Price",
      "stops": [
        { "name": "Sfax Central Station", "place": "Sfax", "time": "06:30", "kind": "departure" },
        { "name": "Ras Ajdir Border", "place": "Border", "time": "11:00", "kind": "transit", "waitMinutes": 45 },
        { "name": "Tripoli Central", "place": "Tripoli", "time": "15:00", "kind": "arrival" }
      ]
    }
  ],
  "quickReplies": [
    { "label": "Book Trip", "value": "book:trip-8492" },
    { "label": "Show Afternoon Trips", "value": "Show afternoon departures" }
  ]
}
```

---

## Future Enhancements

- **Live Vehicle Telemetry**: Integration with vehicle GPS devices to display real-time bus locations and delay alerts.
- **Production Payment Gateways**: Integration of production payment webhooks (Flouci, Konnect, Stripe, local bank switches).
- **Direct Ticketing Dispatch**: Automated PDF ticket generation and dispatch through WhatsApp and SMS.
- **Expanded Regional Routes**: Integration of national rail operators (SNCFT in Tunisia, SNTF in Algeria) alongside coach operators.

---

## Contribution

Contributions are welcome to expand coverage, refine NLP models, or enhance client user experiences.

1. Fork the repository.
2. Create a feature branch:
   ```bash
   git checkout -b feature/enhanced-routing
   ```
3. Commit your modifications following conventional commits:
   ```bash
   git commit -m "feat(routing): add intermediate stop duration calculations"
   ```
4. Push to your branch:
   ```bash
   git push origin feature/enhanced-routing
   ```
5. Submit a pull request with a detailed description of your changes.

---

## Author and License

- **Developer**: Mohamed Ali Chakroun / `mohamedalichakroun.x@gmail.com`)
- **Affiliation**: Developed as an internal technical initiative during an engineering internship at Veyn.
- **License**: Internal proprietary project developed for Veyn. All rights reserved. Refer to repository ownership and internal organizational guidelines for distribution policies.  

