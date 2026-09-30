## Backend FastAPI – Guide rapide

Ce backend implémente une API de chat basée sur FastAPI. Il se connecte à PostgreSQL, génère des embeddings (Gemini) pour rechercher des politiques internes, et expose un endpoint principal de conversation propulsé par un agent LangChain.

### Prérequis

- Python 3.10+
- Un serveur PostgreSQL accessible via `DATABASE_URL`
- Clé API Google pour Gemini (Generative AI)

### Variables d’environnement (.env)

Créez un fichier `.env` à la racine du projet (même dossier que `backend.py`) :

```
DATABASE_URL=...             # ex: postgres://user:pass@host:5432/dbname
GROQ_API_KEY=...             # Clé API Groq
```

Remarque: `DATABASE_URL` doit être compatible `psycopg2`.

### Installation

Installez les dépendances Python:

```bash
pip install -U fastapi uvicorn python-dotenv psycopg2-binary langchain scikit-learn numpy pandas langchain-google-genai
```

### Lancer le serveur

```bash
uvicorn backend:app --host 0.0.0.0 --port 8000 --reload
```

Endpoints disponibles:

- `GET /` → statut simple `{ "status": "ok" }`
- `GET /health` → santé `{ "health": "ok" }`
- `GET /ready` → prêt si pool PostgreSQL actif
- `POST /ask` → endpoint principal de chat

### Description fonctionnelle

Au démarrage (`startup`), le service:

1. Crée un pool PostgreSQL (`DATABASE_URL`).
2. Charge le modèle d’embedding Gemini (`GOOGLE_API_KEY`).
3. Lit la table `configs (key, value)` depuis PostgreSQL, reformule chaque valeur en texte naturel avec un LLM, puis vectorise ces textes pour la recherche sémantique. Les embeddings sont mis en cache dans `config_embeddings_cache.pkl`.

L’API `/ask` utilise un agent LangChain (Gemini) avec 3 outils:

- `TripInfoSQL` → génère puis exécute des requêtes SQL en lecture sur tables de trajets.
- `PricingSQL` → génère puis exécute des requêtes SQL en lecture sur tables de prix.
- `Policy` → recherche vectorielle dans les politiques (configs) reformulées.

Sécurité SQL: seules les requêtes `SELECT`/`WITH` sont autorisées, mots-clés destructifs interdits. Les outils limitent également les tables utilisables.

### Schémas I/O

Requête `POST /ask`:

```json
{
  "session_id": "abc-123",
  "question": "Donne-moi les trajets de Tripoli vers Jufra le 10 juin 2025"
}
```

Réponse:

```json
{
  "question": "...",
  "answer": "...",
  "source": "agent"
}
```

Exemple cURL:

```bash
curl -X POST http://localhost:8000/ask \
  -H "Content-Type: application/json" \
  -d '{
    "session_id": "demo",
    "question": "Quels trajets sont disponibles entre Tripoli et Jufra ?"
  }'
```

### Tables attendues (extraits)

- Trajets: `routes`, `route_segments`, `next_schedules`, `stops`
- Prix: `segment_prices`, `monies`, `currencies`
- Politiques: `configs (key, value)`

Assurez-vous que ces tables existent et sont peuplées en lecture seule pour les outils SQL.

### CORS

Par défaut, CORS autorise l’origine `http://localhost:4200`. Adaptez dans `backend.py` si nécessaire.

### Journalisation & cache

- Démarrage: messages explicites ✅/❌ sur connexions et embeddings.
- Cache embeddings: fichier `config_embeddings_cache.pkl` au même niveau que `backend.py`.

### Dépannage

- `❌ DATABASE_URL manquante.` → ajoutez `DATABASE_URL` au `.env`.
- `❌ Échec chargement embedding model` → vérifiez `GOOGLE_API_KEY` et quotas.
- Quotas 429/erreurs 5xx Gemini: le code applique un backoff automatique.

### Licence

Ce projet est un projet interne développé dans le cadre d'un stage d'été chez Veyn.
