from fastapi import FastAPI, HTTPException, Request, UploadFile, File
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
from typing import Dict, List, Optional, Any, Union
import os
import re
import time
import random
import datetime
import difflib
import psycopg2
from psycopg2 import pool
from dotenv import load_dotenv

# Charger les variables d'environnement
load_dotenv()

# Initialiser FastAPI
app = FastAPI(
    title="Veyn Transport Chat API",
    description="API de chat et moteur de recherche de trajets réels connectée à PostgreSQL"
)

# Configurer CORS pour autoriser le frontend Vite / React / Angular
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# --- Variables Globales ---
postgreSQL_pool: Optional[psycopg2.pool.ThreadedConnectionPool] = None
groq_client = None
config_texts: List[str] = []

# Initialisation de Groq API (openai/gpt-oss-120b)
groq_api_key = os.getenv("GROQ_API_KEY")
if groq_api_key:
    try:
        from groq import Groq
        groq_client = Groq(api_key=groq_api_key)
        print("[OK] Client Groq initialise avec le modele openai/gpt-oss-120b.")
    except Exception as e:
        print("[WARN] Erreur initialisation Groq :", e)


def generate_llm_response(prompt: str, model: str = "openai/gpt-oss-120b") -> str:
    """Génère une réponse avec Groq. Essaie d'abord openai/gpt-oss-120b, puis openai/gpt-oss-20b et qwen/qwen3.8-27b en fallback."""
    if not groq_client:
        return ""

    # Modèles à essayer dans l'ordre avec fallback fiable
    models_to_try = [model]
    for fb in ["openai/gpt-oss-20b", "qwen/qwen3.8-27b"]:
        if fb not in models_to_try:
            models_to_try.append(fb)

    for current_model in models_to_try:
        try:
            # Les modèles gpt-oss supportent reasoning_effort='medium'
            extra_params = {}
            if "gpt-oss" in current_model:
                extra_params["reasoning_effort"] = "medium"

            completion = groq_client.chat.completions.create(
                model=current_model,
                messages=[
                    {
                        "role": "user",
                        "content": prompt
                    }
                ],
                temperature=1 if "gpt-oss" in current_model else 0.7,
                max_completion_tokens=2048,
                top_p=1,
                stream=True,
                stop=None,
                **extra_params
            )
            collected = []
            for chunk in completion:
                delta = chunk.choices[0].delta
                content = delta.content if delta.content else ""
                collected.append(content)
            result = "".join(collected).strip()
            if result:
                if current_model != model:
                    print(f"[INFO] Fallback vers {current_model} utilisé avec succès.")
                return result
            else:
                print(f"[WARN] Modèle {current_model} a retourné une réponse vide, tentative suivante...")
        except Exception as e:
            err_msg = repr(e)
            print(f"[WARN] Erreur Groq LLM ({current_model}): {err_msg[:200]}")
            continue

    print("[ERROR] Tous les modèles Groq ont échoué.")
    return ""

# --- Modèles Pydantic pour le Frontend React ---
class TripStopModel(BaseModel):
    name: str
    place: str
    time: str
    kind: str
    waitMinutes: Optional[int] = None

class TripResultModel(BaseModel):
    id: str
    departure: str
    arrival: str
    durationLabel: str
    mode: str
    transfers: int
    price: float
    currency: str
    operator: str
    seatsLeft: Optional[int] = None
    badge: Optional[str] = None
    date: Optional[str] = None
    stops: List[TripStopModel] = Field(default_factory=list)

class TravelersModel(BaseModel):
    adults: int = 0
    children: int = 0
    assisted: int = 0

class CityModel(BaseModel):
    name: str
    id: Optional[str] = None
    country: Optional[str] = None
    aliases: List[str] = Field(default_factory=list)

class TripQueryModel(BaseModel):
    origin: Optional[Union[CityModel, Dict[str, Any], str]] = None
    destination: Optional[Union[CityModel, Dict[str, Any], str]] = None
    travelers: Optional[TravelersModel] = None
    date: Optional[str] = None
    dates: List[str] = Field(default_factory=list)
    period: Optional[str] = None
    periods: List[str] = Field(default_factory=list)
    exactTime: Optional[str] = None
    modes: List[str] = Field(default_factory=list)
    budget: Optional[float] = None

class QuickReplyModel(BaseModel):
    label: str
    value: str

class ChatApiRequest(BaseModel):
    session_id: Optional[str] = "default"
    question: Optional[str] = ""
    trip: Optional[TripQueryModel] = None
    messages: Optional[List[Dict[str, Any]]] = None
    language: Optional[str] = "fr"

class AssistantResponseModel(BaseModel):
    reply: str
    tripPatch: Optional[Dict[str, Any]] = None
    recognized: Optional[List[str]] = None
    results: Optional[List[TripResultModel]] = None
    conflict: Optional[Dict[str, Any]] = None
    missing: Optional[List[str]] = None
    quickReplies: Optional[List[QuickReplyModel]] = None
    noResults: Optional[bool] = None

class AskRequest(BaseModel):
    session_id: str
    question: str

class AskResponse(BaseModel):
    question: str
    answer: str
    source: str

class BookingRequestModel(BaseModel):
    reference: str
    result: TripResultModel
    travelers: int
    total: float
    currency: str
    boardingStop: TripStopModel
    routeLabel: str
    travelersDetail: Optional[TravelersModel] = None
    travelersLabel: Optional[str] = None
    paymentMethod: Optional[str] = None
    cardType: Optional[str] = None
    cardLast4: Optional[str] = None

# --- Endpoints de Santé ---
@app.get("/")
async def root():
    return {"status": "ok", "service": "Veyn Chatbot API"}

@app.get("/health")
async def health():
    return {"health": "ok"}

@app.get("/ready")
async def ready():
    if postgreSQL_pool is None:
        raise HTTPException(status_code=503, detail="Base de données non prête")
    return {"ready": True}

# --- Cycle de vie de l'application ---
@app.on_event("startup")
async def startup_event():
    global postgreSQL_pool, config_texts

    # 1. PostgreSQL Pool
    DATABASE_URL = os.getenv("DATABASE_URL")
    if not DATABASE_URL:
        print("[ERROR] DATABASE_URL manquante.")
    else:
        try:
            postgreSQL_pool = psycopg2.pool.ThreadedConnectionPool(1, 20, DATABASE_URL)
            print("[OK] Connexion a PostgreSQL etablie avec succes.")
        except Exception as e:
            print("[ERROR] Echec connexion PostgreSQL :", e)
            postgreSQL_pool = None

    # 2. Chargement des configs / politiques internes depuis la base de données
    config_texts.clear()
    if postgreSQL_pool:
        try:
            conn = postgreSQL_pool.getconn()
            cur = conn.cursor()
            cur.execute("SELECT key, value FROM configs WHERE value IS NOT NULL AND TRIM(value) != ''")
            rows = cur.fetchall()
            cur.close()
            postgreSQL_pool.putconn(conn)

            # Formater les configs en langage naturel compréhensible pour le client, sans exposer les clés techniques
            HUMAN_CONFIG_MAPPING = {
                "ticket_validity": "Validité des billets : {value} mois.",
                "cancel_ticket_process": "Délai de traitement d'annulation : {value} jours.",
                "cancel_ticket_fees_seven_days": "Frais d'annulation au moins 7 jours avant le départ : {value} DT (annulation sans frais).",
                "age_discount_less_than_two": "Réduction pour les bébés de moins de 2 ans : {value}% de réduction (gratuit sur les genoux).",
                "age_discount_less_than_two_with_seat": "Réduction pour les bébés de moins de 2 ans avec siège réservé : {value}% de réduction.",
                "age_discount_less_than_six": "Réduction pour les enfants de moins de 6 ans : {value}% de réduction sur le tarif adulte standard.",
                "loyalty_point_expiry_days": "Durée de validité des points de fidélité : {value} jours.",
                "special_needs_discount": "Assistance et réduction pour les voyageurs à mobilité réduite (PMR) : {value}% de réduction sur le tarif adulte standard.",
                "luggage_weight_limit": "Poids maximal autorisé par valise en soute : {value} kg.",
            }
            formatted = []
            for r in rows:
                k = str(r[0]).strip().lower()
                v = str(r[1]).strip()
                if k in HUMAN_CONFIG_MAPPING:
                    formatted.append(HUMAN_CONFIG_MAPPING[k].format(value=v))
            config_texts = formatted
            print(f"[OK] {len(config_texts)} regles metier formatees chargees depuis la DB.")
        except Exception as e:
            print("[WARN] Erreur lors du chargement des configs :", e)

@app.on_event("shutdown")
async def shutdown_event():
    global postgreSQL_pool
    if postgreSQL_pool:
        postgreSQL_pool.closeall()
        print("[OK] Pool PostgreSQL ferme.")

# --- Utilitaires de Base de Données ---
def get_db_connection():
    if postgreSQL_pool is None:
        raise HTTPException(status_code=500, detail="Base de données non disponible.")
    return postgreSQL_pool.getconn()

def release_db_connection(conn):
    if postgreSQL_pool and conn:
        postgreSQL_pool.putconn(conn)

def normalize_text(text: str) -> str:
    if not text:
        return ""
    return re.sub(r"\s+", " ", re.sub(r"[^\w\s\u0600-\u06FF]", " ", text.lower())).strip()

CITY_COUNTRIES: Dict[str, str] = {
    "tunis": "TN",
    "sfax": "TN",
    "sousse": "TN",
    "hammamet": "TN",
    "djerba": "TN",
    "zarzis": "TN",
    "koutine": "TN",
    "ras jedir": "TN",
    "ras ajdir": "TN",
    "kairouan": "TN",
    "bizerte": "TN",
    "gabes": "TN",
    "nabeul": "TN",
    "monastir": "TN",
    "mahdia": "TN",
    "gafsa": "TN",
    "tozeur": "TN",
    "tataouine": "TN",
    "tripoli": "LY",
    "misrata": "LY",
    "benghazi": "LY",
    "jufra": "LY",
    "sabha": "LY",
    "sirte": "LY",
    "tobruk": "LY",
    "zuwara": "LY",
    "khoms": "LY",
    "zliten": "LY",
    "ajdabiya": "LY",
    "derna": "LY",
    "al bayda": "LY",
    "bin jawad": "LY",
    "ras lanouf": "LY",
    "el brega": "LY",
    "janzour": "LY",
    "alger": "DZ",
    "oran": "DZ",
    "constantine": "DZ",
    "annaba": "DZ",
    "setif": "DZ",
    "batna": "DZ",
    "cairo": "EG",
    "alexandria": "EG",
}

def normalize_arabic(text: str) -> str:
    """Normalise les caractères arabes pour effacer les différences de saisie."""
    if not text:
        return ""
    # Supprimer les diacritiques (Tashkeel) et le Tatweel/Kashida
    text = re.sub(r"[\u064B-\u0652\u0640]", "", text)
    # Unifier les différentes formes d'Alef et Hamza
    text = re.sub(r"[إأآٱء]", "ا", text)
    # Taa marbouta et Yaa
    text = text.replace("ة", "ه").replace("ى", "ي")
    return text

def phonetic_arabic(text: str) -> str:
    """Réduction phonétique arabe pour tolérer les confusions classiques (ص/س, ط/ت, إلخ)."""
    if not text:
        return ""
    text = normalize_arabic(text)
    # Équivalences phonétiques fréquentes dans les dialectes et fautes de frappe
    text = text.replace("ص", "س").replace("ط", "ت").replace("ض", "د")
    text = text.replace("ق", "ك").replace("ذ", "ز").replace("ث", "س").replace("ظ", "ز")
    # Réduction des voyelles allongées consécutives (ex: صافاقص -> سافاكس)
    text = re.sub(r"ا+", "ا", text)
    text = re.sub(r"و+", "و", text)
    text = re.sub(r"ي+", "ي", text)
    return text

def similarity_score(term: str, target: str) -> float:
    """Calcule le score de similarité maximal entre deux termes (direct et phonétique)."""
    t1 = clean_term(term)
    t2 = clean_term(target)
    if not t1 or not t2:
        return 0.0
    if t1 == t2:
        return 1.0
    r_direct = difflib.SequenceMatcher(None, t1, t2).ratio()
    p1 = phonetic_arabic(t1)
    p2 = phonetic_arabic(t2)
    r_phonetic = difflib.SequenceMatcher(None, p1, p2).ratio() if p1 and p2 else 0.0
    return max(r_direct, r_phonetic)

def display_city_name(name: str, is_arabic: bool) -> str:
    """Retourne une dénomination soignée et élégante pour la ville dans la langue cible."""
    if not name:
        return ""
    n_lower = name.lower()
    for std_ar, aliases in [
        ("طرابلس", ["tripoli", "طرابلس"]),
        ("صفاقس", ["sfax", "صفاقس"]),
        ("تونس", ["tunis", "تونس"]),
        ("سوسة", ["sousse", "سوسة"]),
        ("مصراتة", ["misrata", "مصراتة"]),
        ("بنغازي", ["benghazi", "بنغازي"]),
        ("الحمامات", ["hammamet", "الحمامات"]),
        ("جربة", ["djerba", "جربة"]),
        ("قابس", ["gabes", "قابس"]),
        ("بنزرت", ["bizerte", "بنزرت"]),
        ("القاهرة", ["cairo", "القاهرة"]),
        ("الإسكندرية", ["alexandria", "الإسكندرية"]),
        ("الجزائر", ["alger", "الجزائر"]),
        ("وهران", ["oran", "وهران"]),
        ("قسنطينة", ["constantine", "قسنطينة"]),
        ("سرت", ["sirte", "سرت"]),
        ("طبرق", ["tobruk", "طبرق"]),
        ("زوارة", ["zuwara", "زوارة"]),
        ("الخمس", ["khoms", "الخمس"]),
        ("زليتن", ["zliten", "زليتن"]),
        ("جرجيس", ["zarzis", "جرجيس"]),
        ("رأس جدير", ["ras jedir", "رأس جدير"]),
    ]:
        if any(a in n_lower for a in aliases):
            return std_ar if is_arabic else aliases[0].capitalize()
    ar_match = re.findall(r"[\u0600-\u06FF]+", name)
    lat_match = re.findall(r"[a-zA-Z]+", name)
    if is_arabic and ar_match:
        return " ".join(ar_match)
    elif not is_arabic and lat_match:
        return " ".join(lat_match)
    return name

CITY_ALIASES: Dict[str, List[str]] = {
    "tunis": ["tunis", "tunisie", "tounes", "تونس", "تنس", "تونس العاصمة", "تونس العاصمه"],
    "tripoli": ["tripoli", "trablus", "طربلس", "طرابلس", "ترابلس", "طرابلس الغرب", "tripolie", "tarabulus"],
    "misrata": ["misrata", "misurata", "مصراتة", "مصراته", "مسراتة", "مسراته", "مصرطة", "مصراته الصمود"],
    "sfax": [
        "sfax", "safaqis", "sfaks", "safaqes", "sfaxe", "صفاقس", "صافاقص", "صفاقص",
        "سفاكس", "سفكس", "ساقية الزيت", "sakiet ezzit"
    ],
    "sousse": ["sousse", "souse", "souss", "soussa", "سوسة", "سوسه", "صوسة", "صوسه"],
    "cairo": ["cairo", "caire", "le caire", "القاهرة", "القاهره"],
    "alexandria": ["alexandria", "alexandrie", "الإسكندرية", "الاسكندرية", "الاسكندريه"],
    "benghazi": ["benghazi", "bengazi", "بنغازي", "بن غازي", "بنغازى"],
    "hammamet": ["hammamet", "hamamet", "الحمامات", "حمامات", "حمامات تونس"],
    "janzour": ["janzour", "janzur", "جنزور"],
    "zuwara": ["zuwara", "زواره", "زوارة", "zouara"],
    "koutine": ["koutine", "كوتين"],
    "ras jedir": ["ras jedir", "ras ajdir", "ra's ajdir", "ajdir", "jedir", "راس جدير", "رأس جدير", "راس جادير"],
    "djerba": ["djerba", "jerba", "جربة", "جربه", "جزيرة جربة", "حومة السوق", "houmt souk"],
    "zarzis": ["zarzis", "جرجيس", "jarjis"],
    "gabes": ["gabes", "gabès", "قابس", "قابص", "qabis"],
    "bizerte": ["bizerte", "بنزرت", "banzart"],
    "kairouan": ["kairouan", "القيروان", "قيروان", "qairawan"],
    "monastir": ["monastir", "المنستير", "منستير"],
    "mahdia": ["mahdia", "المهدية", "مهدية"],
    "gafsa": ["gafsa", "قفصة", "قفصه", "qafsa"],
    "tozeur": ["tozeur", "توزر"],
    "tataouine": ["tataouine", "تطاوين"],
    "nabeul": ["nabeul", "نابل"],
    "sirte": ["sirte", "surt", "سرت"],
    "tobruk": ["tobruk", "tobrouk", "طبرق"],
    "khoms": ["khoms", "الخمس", "خمس"],
    "zliten": ["zliten", "زليتن", "ًزليتن"],
    "sabha": ["sabha", "سبها", "sebha"],
    "ajdabiya": ["ajdabiya", "أجدابيا", "اجدابيا"],
    "derna": ["derna", "درنة", "درنه"],
    "al bayda": ["al bayda", "البيضاء", "بيضاء"],
    "bin jawad": ["bin jawad", "بن جواد"],
    "ras lanouf": ["ras lanouf", "راس لانوف"],
    "el brega": ["el brega", "البريقة", "بريقه"],
    "alger": ["alger", "algiers", "الجزائر", "الجزائر العاصمة"],
    "oran": ["oran", "وهران"],
    "constantine": ["constantine", "قسنطينة", "قسنطينه"],
    "annaba": ["annaba", "عنابة", "عنابه"],
    "setif": ["setif", "سطيف"],
    "batna": ["batna", "باتنة", "باتنه"],
}

def correct_user_query(question: str) -> str:
    """
    Corrige automatiquement et mentalement les fautes d'orthographe, de frappe et 
    les noms de villes déformés dans le message utilisateur avant tout traitement.
    """
    if not question:
        return ""
    tokens = question.split()
    corrected_tokens = []
    for tok in tokens:
        clean_tok = clean_term(tok)
        if not clean_tok or clean_tok in STOP_WORDS or len(clean_tok) < 3:
            corrected_tokens.append(tok)
            continue
        best_target = None
        best_score = 0.0
        for std_name, aliases in CITY_ALIASES.items():
            for a in aliases:
                score = similarity_score(clean_tok, a)
                if score > best_score:
                    best_score = score
                    # Préférer la forme arabe si le mot original est en arabe
                    is_ar = bool(re.search(r"[\u0600-\u06FF]", tok))
                    ar_options = [c for c in aliases if re.search(r"[\u0600-\u06FF]", c)]
                    best_target = ar_options[0] if (is_ar and ar_options) else std_name.capitalize()
        # Si une faute de frappe proche est identifiée (ex: صافاقص -> صفاقس)
        if best_score >= 0.78 and best_target and best_score < 1.0:
            corrected_tokens.append(best_target)
        else:
            corrected_tokens.append(tok)
    return " ".join(corrected_tokens)

STOP_WORDS = {
    "les", "des", "aux", "par", "sur", "sous", "dans", "pour", "avec", "sans",
    "vers", "bon", "est", "une", "vos", "nos", "mon", "ton", "son", "mes", "tes",
    "ses", "que", "qui", "pas", "ces", "tout", "tous", "toute", "toutes", "quel",
    "quelle", "quels", "quelles", "comment", "quand", "pourquoi", "merci", "salut",
    "bonjour", "bonsoir", "station", "arret", "gare", "depart", "arrivee", "trajet",
    "voyage", "prix", "tarif", "billet", "bagage", "bagages", "enfant", "bebe",
    "reduction", "wifi", "clim", "visa", "passeport", "animal", "animaux", "regle",
    "regles", "politique", "service", "services", "autre", "autres", "meme", "aussi",
    "bien", "plus", "moins", "tres", "peut", "peux", "faire", "avoir", "etre",
    "saint", "sainte", "arènes", "arenes", "touch", "ramassiers", "lardenne",
    "من", "الى", "إلى", "في", "على", "عن", "مع", "هذا", "هذه", "كم", "متى", "اين",
    "أين", "سعر", "تذكرة", "رحلة", "سفر", "امتعة", "حقيبة"
}

def get_stop_country(name: str, address: Optional[str] = None) -> str:
    n = clean_term(name)
    for k, c in CITY_COUNTRIES.items():
        if k in n or n in k:
            return c
    if address:
        addr = clean_term(address)
        if any(w in addr for w in ["tunisie", "tunis", "sfax", "sousse", "djerba"]):
            return "TN"
        if any(w in addr for w in ["libye", "libya", "tripoli", "misrata", "benghazi"]):
            return "LY"
        if any(w in addr for w in ["algerie", "algeria", "alger"]):
            return "DZ"
        if any(w in addr for w in ["egypte", "egypt", "caire"]):
            return "EG"
    return "TN"

def clean_term(s: str) -> str:
    if not s:
        return ""
    s = s.lower().replace("'", " ").replace("’", " ").replace("-", " ")
    return re.sub(r"\s+", " ", re.sub(r"[^\w\s\u0600-\u06FF]", " ", s)).strip()

def match_stop_in_db(name_or_alias: str, conn) -> Optional[Dict[str, Any]]:
    """Recherche un arrêt dans la table `stops` par nom arabe ou latin, alias ou code."""
    if not name_or_alias:
        return None
    term = clean_term(name_or_alias)
    if not term or term in STOP_WORDS:
        return None

    # 1. Vérification dans CITY_ALIASES
    for std_name, aliases in CITY_ALIASES.items():
        if any(term == clean_term(a) or clean_term(a) in term for a in aliases):
            for alias in aliases:
                norm_a = clean_term(alias)
                cur = conn.cursor()
                cur.execute("""
                    SELECT id, name, code, address, latitude, longitude
                    FROM stops
                    WHERE REPLACE(REPLACE(LOWER(name), '''', ' '), '-', ' ') LIKE %s
                       OR LOWER(code) LIKE %s
                    LIMIT 1;
                """, (f"%{norm_a}%", f"%{norm_a}%"))
                row = cur.fetchone()
                cur.close()
                if row:
                    return {
                        "id": str(row[0]),
                        "name": row[1],
                        "code": row[2],
                        "address": row[3] or f"Station de {row[1]}",
                        "lat": row[4],
                        "lng": row[5],
                        "country": get_stop_country(row[1], row[3])
                    }

    # 2. Recherche directe dans les arrêts connectés aux routes actives
    cur = conn.cursor()
    cur.execute("""
        SELECT s.id, s.name, s.code, s.address, s.latitude, s.longitude
        FROM stops s
        JOIN route_segments rs ON rs.stop_id = s.id
        WHERE REPLACE(REPLACE(LOWER(s.name), '''', ' '), '-', ' ') LIKE %s
           OR LOWER(s.code) LIKE %s
        LIMIT 1;
    """, (f"%{term}%", f"%{term}%"))
    row = cur.fetchone()

    # 3. Recherche par mots significatifs (hors stop words)
    if not row:
        words = [w for w in term.split() if len(w) >= 4 and w not in STOP_WORDS]
        for w in words:
            cur.execute("""
                SELECT s.id, s.name, s.code, s.address, s.latitude, s.longitude
                FROM stops s
                JOIN route_segments rs ON rs.stop_id = s.id
                WHERE REPLACE(REPLACE(LOWER(s.name), '''', ' '), '-', ' ') LIKE %s
                LIMIT 1;
            """, (f"%{w}%",))
            row = cur.fetchone()
            if row:
                break
    cur.close()

    if row:
        return {
            "id": str(row[0]),
            "name": row[1],
            "code": row[2],
            "address": row[3] or f"Station de {row[1]}",
            "lat": row[4],
            "lng": row[5],
            "country": get_stop_country(row[1], row[3])
        }

    # 4. Recherche par tolérance aux fautes de frappe et phonétique (Fuzzy matching)
    best_std = None
    best_score = 0.0
    for std_name, aliases in CITY_ALIASES.items():
        for a in aliases:
            score = similarity_score(term, a)
            if score > best_score:
                best_score = score
                best_std = std_name
    if best_score >= 0.78 and best_std:
        # Relancer avec l'identifiant standard validé
        return match_stop_in_db(best_std, conn)

    return None

def fetch_real_trips(
    origin_name: str,
    dest_name: str,
    target_date: Optional[str] = None,
    period: Optional[str] = None,
    exact_time: Optional[str] = None,
    budget: Optional[float] = None,
    modes: Optional[List[str]] = None,
    is_after: bool = False,
) -> List[Dict[str, Any]]:
    """
    Interroge les tables PostgreSQL réelles :
    `routes`, `route_segments`, `next_schedules`, `stops`, `segment_prices`, `monies`, `currencies`
    """
    conn = None
    results = []
    try:
        conn = get_db_connection()

        # 1. Identifier les arrêts de départ et destination dans la DB
        origin_stop = match_stop_in_db(origin_name, conn)
        dest_stop = match_stop_in_db(dest_name, conn)

        if not origin_stop or not dest_stop:
            return []

        origin_id = origin_stop["id"]
        dest_id = dest_stop["id"]

        # 2. Trouver les routes qui passent par origin_id puis dest_id dans le bon ordre
        cur = conn.cursor()

        if target_date:
            if is_after:
                # Si l'utilisateur a demandé 'après telle date', afficher les trajets à partir de cette date
                cur.execute("""
                    WITH matching_routes AS (
                        SELECT r.id AS route_id, r.name AS route_name, r.international,
                               rs1."order" AS origin_order, rs2."order" AS dest_order
                        FROM routes r
                        JOIN route_segments rs1 ON r.id = rs1.route_id
                        JOIN route_segments rs2 ON r.id = rs2.route_id
                        WHERE rs1.stop_id = %s AND rs2.stop_id = %s AND rs1."order" < rs2."order"
                    )
                    SELECT mr.route_id, mr.route_name, mr.international, mr.origin_order, mr.dest_order,
                           ns.id as schedule_id, ns.date, ns.time
                    FROM matching_routes mr
                    JOIN next_schedules ns ON mr.route_id = ns.route_id
                    WHERE ns.date >= %s
                    ORDER BY ns.date ASC, ns.time ASC
                    LIMIT 10;
                """, (origin_id, dest_id, target_date))
                schedule_rows = cur.fetchall()
            else:
                # Recherche des départs disponibles à partir de la date demandée (ou après)
                cur.execute("""
                    WITH matching_routes AS (
                        SELECT r.id AS route_id, r.name AS route_name, r.international,
                               rs1."order" AS origin_order, rs2."order" AS dest_order
                        FROM routes r
                        JOIN route_segments rs1 ON r.id = rs1.route_id
                        JOIN route_segments rs2 ON r.id = rs2.route_id
                        WHERE rs1.stop_id = %s AND rs2.stop_id = %s AND rs1."order" < rs2."order"
                    )
                    SELECT mr.route_id, mr.route_name, mr.international, mr.origin_order, mr.dest_order,
                           ns.id as schedule_id, ns.date, ns.time
                    FROM matching_routes mr
                    JOIN next_schedules ns ON mr.route_id = ns.route_id
                    WHERE ns.date >= %s
                    ORDER BY ns.date ASC, ns.time ASC
                    LIMIT 25;
                """, (origin_id, dest_id, target_date))
                schedule_rows = cur.fetchall()
        else:
            # Pas de date spécifiée : prochains départs à partir d'aujourd'hui
            cur.execute("""
                WITH matching_routes AS (
                    SELECT r.id AS route_id, r.name AS route_name, r.international,
                           rs1."order" AS origin_order, rs2."order" AS dest_order
                    FROM routes r
                    JOIN route_segments rs1 ON r.id = rs1.route_id
                    JOIN route_segments rs2 ON r.id = rs2.route_id
                    WHERE rs1.stop_id = %s AND rs2.stop_id = %s AND rs1."order" < rs2."order"
                )
                SELECT mr.route_id, mr.route_name, mr.international, mr.origin_order, mr.dest_order,
                       ns.id as schedule_id, ns.date, ns.time
                FROM matching_routes mr
                JOIN next_schedules ns ON mr.route_id = ns.route_id
                WHERE ns.date >= CURRENT_DATE
                ORDER BY ns.date ASC, ns.time ASC
                LIMIT 25;
            """, (origin_id, dest_id))
            schedule_rows = cur.fetchall()

        # Si pas d'horaires spécifiques prévus, récupérer les routes candidates avec horaires types sur 5 jours
        if not schedule_rows:
            cur.execute("""
                SELECT r.id AS route_id, r.name AS route_name, r.international,
                       rs1."order" AS origin_order, rs2."order" AS dest_order
                FROM routes r
                JOIN route_segments rs1 ON r.id = rs1.route_id
                JOIN route_segments rs2 ON r.id = rs2.route_id
                WHERE rs1.stop_id = %s AND rs2.stop_id = %s AND rs1."order" < rs2."order"
                LIMIT 5;
            """, (origin_id, dest_id))
            candidate_routes = cur.fetchall()
            base_d = datetime.datetime.strptime(target_date, "%Y-%m-%d").date() if target_date else datetime.date.today()
            schedule_rows = []
            for day_offset in range(5):
                cur_date = (base_d + datetime.timedelta(days=day_offset)).strftime("%Y-%m-%d")
                for r in candidate_routes:
                    schedule_rows.append((r[0], r[1], r[2], r[3], r[4], f"sch-{r[0]}-{cur_date}-m", cur_date, datetime.time(7, 30)))
                    schedule_rows.append((r[0], r[1], r[2], r[3], r[4], f"sch-{r[0]}-{cur_date}-a", cur_date, datetime.time(14, 0)))

        # 3. Récupérer le tarif réel depuis segment_prices + monies + currencies
        cur.execute("""
            SELECT sp.id, sp.route_id, m.value, c.name, c.symbol
            FROM segment_prices sp
            JOIN monies m ON m.priceable_type = 'segment_prices' AND m.priceable_id = sp.id
            JOIN currencies c ON c.id = m.currency_id
            WHERE sp.from = %s AND sp.to = %s AND m.value > 0
            ORDER BY m.value ASC;
        """, (origin_id, dest_id))
        price_rows = cur.fetchall()

        default_price = 80.0
        default_currency = "DT"
        if price_rows:
            tn_price = next((p for p in price_rows if 'DT' in str(p[4]) or 'تونسي' in str(p[3])), None)
            if tn_price:
                default_price = float(tn_price[2])
                default_currency = tn_price[4] or "DT"
            else:
                default_price = float(price_rows[0][2])
                default_currency = price_rows[0][4] or "DT"

        # 4. Pour chaque trajet, construire la liste des arrêts ordonnés réels
        seen_schedules = set()
        for s_row in schedule_rows:
            route_id, route_name, international, o_order, d_order, sched_id, s_date, s_time = s_row
            key = f"{route_id}-{s_date}-{s_time}"
            if key in seen_schedules:
                continue
            seen_schedules.add(key)

            cur.execute("""
                SELECT rs.stop_id, s.name, s.address, rs."order"
                FROM route_segments rs
                JOIN stops s ON rs.stop_id = s.id
                WHERE rs.route_id = %s AND rs."order" >= %s AND rs."order" <= %s
                ORDER BY rs."order" ASC;
            """, (route_id, o_order, d_order))
            route_stops_rows = cur.fetchall()

            dep_hour = s_time.hour if hasattr(s_time, 'hour') else 7
            dep_min = s_time.minute if hasattr(s_time, 'minute') else 0
            dep_total_mins = dep_hour * 60 + dep_min

            stops_list = []
            num_stops = len(route_stops_rows)
            total_duration_hours = max(4, num_stops * 1.5)

            for idx, stop_row in enumerate(route_stops_rows):
                st_id, st_name, st_addr, st_order = stop_row
                progress = idx / max(1, num_stops - 1)
                st_time_mins = int(dep_total_mins + progress * (total_duration_hours * 60))
                st_h = (st_time_mins // 60) % 24
                st_m = st_time_mins % 60
                formatted_time = f"{st_h:02d}:{st_m:02d}"

                if idx == 0:
                    kind = "origin"
                elif idx == num_stops - 1:
                    kind = "destination"
                elif "جدير" in st_name or "ajdir" in st_name.lower():
                    kind = "border"
                else:
                    kind = "stop"

                stops_list.append({
                    "name": st_name,
                    "place": st_addr or f"Station de {st_name}",
                    "time": formatted_time,
                    "kind": kind,
                    "waitMinutes": 10 if kind == "stop" else (45 if kind == "border" else None)
                })

            arr_time = stops_list[-1]["time"] if stops_list else f"{(dep_hour + 6) % 24:02d}:{dep_min:02d}"
            dur_hours = int(total_duration_hours)
            dur_mins = int((total_duration_hours - dur_hours) * 60)
            duration_label = f"{dur_hours}h{dur_mins:02d}" if dur_mins else f"{dur_hours}h00"

            formatted_date = s_date.strftime("%Y-%m-%d") if hasattr(s_date, 'strftime') else (str(s_date)[:10] if s_date else target_date)
            item = {
                "id": f"trip-db-{route_id}-{sched_id}",
                "date": formatted_date,
                "departure": f"{dep_hour:02d}:{dep_min:02d}",
                "arrival": arr_time,
                "durationLabel": duration_label,
                "mode": "bus",
                "transfers": 0,
                "price": default_price,
                "currency": default_currency,
                "operator": "Veyn Express" if international else "Rawahel",
                "seatsLeft": random.randint(4, 18),
                "stops": stops_list
            }

            if budget is not None and item["price"] > budget:
                continue

            results.append(item)

        cur.close()

        if results:
            results.sort(key=lambda x: x["price"])
            results[0]["badge"] = "Meilleur tarif réel"

    except Exception as e:
        print("[ERREUR] Erreur lors de la recherche des trajets reels en DB :", repr(e)[:200])
    finally:
        if conn:
            release_db_connection(conn)

    return results



def extract_cities_from_question(question: str, conn) -> Dict[str, Optional[Dict[str, Any]]]:
    """Extrait l'origine et/ou la destination à partir du texte avec tolérance aux fautes d'orthographe et dialectes."""
    res = {"origin": None, "destination": None}
    if not question:
        return res

    q_lower = f" {clean_term(question)} "
    found_stops = []

    # 1. Vérifier les alias connus (correspondance exacte)
    for std_name, aliases in CITY_ALIASES.items():
        for alias in aliases:
            norm_alias = clean_term(alias)
            if not norm_alias or norm_alias in STOP_WORDS:
                continue
            idx = q_lower.find(f" {norm_alias} ")
            if idx != -1:
                st = match_stop_in_db(std_name, conn)
                if st:
                    found_stops.append((idx, st))
                    break

    # 1.5 Recherche par similarité phonétique et tolérance aux fautes (Fuzzy matching)
    if len(found_stops) < 2:
        words = q_lower.split()
        for w in words:
            if w in STOP_WORDS or len(w) < 3:
                continue
            idx = q_lower.find(f" {w} ")
            # Ne pas re-matcher un mot déjà couvert par un arrêt exact
            if any(abs(idx - ex_idx) < 4 for ex_idx, _ in found_stops):
                continue
            best_std = None
            best_score = 0.0
            for std_name, aliases in CITY_ALIASES.items():
                for a in aliases:
                    score = similarity_score(w, a)
                    if score > best_score:
                        best_score = score
                        best_std = std_name
            if best_score >= 0.78 and best_std:
                st = match_stop_in_db(best_std, conn)
                if st and not any(str(s["id"]) == str(st["id"]) for _, s in found_stops):
                    found_stops.append((idx, st))

    # 2. Compléter uniquement avec les arrêts réels reliés à des trajets actifs
    if len(found_stops) < 2:
        try:
            cur = conn.cursor()
            cur.execute("""
                SELECT DISTINCT s.id, s.name, s.code, s.address, s.latitude, s.longitude
                FROM stops s
                JOIN route_segments rs ON rs.stop_id = s.id
                WHERE s.status = true OR s.status IS NULL;
            """)
            rows = cur.fetchall()
            cur.close()

            existing_ids = {s[1]["id"] for s in found_stops}
            for r in rows:
                if str(r[0]) in existing_ids:
                    continue
                st = {
                    "id": str(r[0]),
                    "name": r[1],
                    "code": r[2],
                    "address": r[3] or f"Station de {r[1]}",
                    "lat": r[4],
                    "lng": r[5],
                    "country": get_stop_country(r[1], r[3])
                }
                # Ne matcher que les mots significatifs (au moins 4 lettres et non stop words)
                for part in r[1].lower().split():
                    norm_p = clean_term(part)
                    if len(norm_p) >= 4 and norm_p not in STOP_WORDS and f" {norm_p} " in q_lower:
                        idx = q_lower.find(f" {norm_p} ")
                        found_stops.append((idx, st))
                        break
        except Exception as e:
            print("[WARN] Erreur lecture stops DB :", e)

    found_stops.sort(key=lambda x: x[0])

    # Éviter les doublons
    unique_stops = []
    seen_ids = set()
    for item in found_stops:
        sid = str(item[1]["id"])
        if sid not in seen_ids:
            seen_ids.add(sid)
            unique_stops.append(item)

    if len(unique_stops) >= 2:
        s0_idx, s0 = unique_stops[0]
        s1_idx, s1 = unique_stops[1]

        prefix0 = q_lower[:s0_idx]
        prefix1 = q_lower[:s1_idx]
        is_s0_origin = any(m in prefix0 for m in [" de ", " depuis ", " d ", " partir de ", " من "])
        is_s0_dest = any(m in prefix0 for m in [" a ", " vers ", " pour ", " jusqu a ", " direction ", " الى ", " إلي ", " نحو "])
        is_s1_origin = any(m in prefix1 for m in [" de ", " depuis ", " d ", " partir de ", " من "])
        is_s1_dest = any(m in prefix1 for m in [" a ", " vers ", " pour ", " jusqu a ", " direction ", " الى ", " إلي ", " نحو "])

        if is_s0_dest and is_s1_origin:
            res["origin"] = s1
            res["destination"] = s0
        else:
            res["origin"] = s0
            res["destination"] = s1
    elif len(unique_stops) == 1:
        idx = unique_stops[0][0]
        prefix = q_lower[:idx]
        if any(m in prefix for m in [" de ", " depuis ", " d ", " partir de ", " من "]):
            res["origin"] = unique_stops[0][1]
        elif any(m in prefix for m in [" a ", " vers ", " pour ", " jusqu a ", " direction ", " الى ", " إلي ", " نحو "]):
            res["destination"] = unique_stops[0][1]
        else:
            # Si pas de marqueur explicite, vérifier si la phrase exprime bien une recherche de voyage
            is_travel_query = any(w in q_lower for w in ["aller", "partir", "voyag", "bus", "trajet", "ticket", "billet", "سفر", "ذهاب", "رحلة"])
            if is_travel_query:
                res["destination"] = unique_stops[0][1]

    return res

FRENCH_MONTHS = {
    "janvier": 1, "fevrier": 2, "février": 2, "mars": 3, "avril": 4, "mai": 5,
    "juin": 6, "juillet": 7, "aout": 8, "août": 8, "septembre": 9, "octobre": 10,
    "novembre": 11, "decembre": 12, "décembre": 12
}

def extract_date_from_question(question: str) -> Optional[str]:
    """Extrait une date cible depuis la question, avec gestion du décalage pour 'après'."""
    if not question:
        return None
    today = datetime.date.today()
    q_norm = clean_term(question)

    if any(w in q_norm for w in ["apres demain", "après demain", "بعد غد"]):
        return (today + datetime.timedelta(days=2)).strftime("%Y-%m-%d")
    if any(w in q_norm for w in ["demain", "غدا", "غدوة"]):
        return (today + datetime.timedelta(days=1)).strftime("%Y-%m-%d")
    if any(w in q_norm for w in ["aujourd hui", "ce soir", "maintenant", "اليوم"]):
        return today.strftime("%Y-%m-%d")
    if any(w in q_norm for w in ["semaine prochaine", "الاسبوع القادم"]):
        return (today + datetime.timedelta(days=7)).strftime("%Y-%m-%d")

    is_after = bool(re.search(r"\b(apres|après|بعد)\b", question.lower()))

    # Dates textuelles : ex "11 septembre", "15 octobre"
    match_written = re.search(
        r"\b(\d{1,2})\s+(janvier|fevrier|février|mars|avril|mai|juin|juillet|aout|août|septembre|sept|octobre|oct|novembre|nov|decembre|décembre|dec)\b",
        question.lower()
    )
    if match_written:
        day = int(match_written.group(1))
        m_str = (
            match_written.group(2)
            .replace("sept", "septembre")
            .replace("oct", "octobre")
            .replace("nov", "novembre")
            .replace("dec", "decembre")
        )
        month = FRENCH_MONTHS.get(m_str, 9)
        year = today.year
        try:
            target = datetime.date(year, month, day)
            if target < today:
                target = datetime.date(year + 1, month, day)
            if is_after:
                target = target + datetime.timedelta(days=1)
            return target.strftime("%Y-%m-%d")
        except ValueError:
            pass

    # Dates numériques : YYYY-MM-DD ou DD/MM/YYYY ou DD/MM
    match_iso = re.search(r"\b(\d{4})[-/](\d{1,2})[-/](\d{1,2})\b", question)
    if match_iso:
        y, m, d = int(match_iso.group(1)), int(match_iso.group(2)), int(match_iso.group(3))
        try:
            target = datetime.date(y, m, d)
            if is_after:
                target = target + datetime.timedelta(days=1)
            return target.strftime("%Y-%m-%d")
        except ValueError:
            pass

    match_dmy = re.search(r"\b(\d{1,2})[-/](\d{1,2})(?:[-/](\d{2,4}))?\b", question)
    if match_dmy:
        d, m = int(match_dmy.group(1)), int(match_dmy.group(2))
        y = int(match_dmy.group(3)) if match_dmy.group(3) else today.year
        if y < 100:
            y += 2000
        try:
            target = datetime.date(y, m, d)
            if target < today:
                target = datetime.date(y + 1, m, d)
            if is_after:
                target = target + datetime.timedelta(days=1)
            return target.strftime("%Y-%m-%d")
        except ValueError:
            pass

    return None

def format_travelers_str(travelers: Optional[Dict[str, Any]], lang: str = "fr") -> str:
    if not travelers:
        return "مسافر واحد" if lang == "ar" else "1 traveler" if lang == "en" else "1 voyageur"
    parts = []
    adults = travelers.get("adults", 0)
    children = travelers.get("children", 0)
    assisted = travelers.get("assisted", 0)
    if lang == "ar":
        if adults > 0:
            parts.append(f"{adults} بالغ")
        if children > 0:
            parts.append(f"{children} طفل")
        if assisted > 0:
            parts.append(f"{assisted} ذوو الاحتياجات")
        return "، ".join(parts) if parts else "مسافر واحد"
    elif lang == "en":
        if adults > 0:
            parts.append(f"{adults} adult{'s' if adults > 1 else ''}")
        if children > 0:
            parts.append(f"{children} child{'ren' if children > 1 else ''}")
        if assisted > 0:
            parts.append(f"{assisted} PRM")
        return ", ".join(parts) if parts else "1 traveler"
    else:
        if adults > 0:
            parts.append(f"{adults} adulte{'s' if adults > 1 else ''}")
        if children > 0:
            parts.append(f"{children} enfant{'s' if children > 1 else ''}")
        if assisted > 0:
            parts.append(f"{assisted} PMR / mobilité réduite")
        return ", ".join(parts) if parts else "1 voyageur"

def format_trips_for_prompt(trips: List[Dict[str, Any]]) -> str:
    if not trips:
        return "Aucun trajet direct trouvé en base de données pour ces critères précis."
    lines = []
    for idx, t in enumerate(trips[:6], 1):
        stops_names = [s["name"] for s in t.get("stops", [])]
        stops_str = " -> ".join(stops_names) if stops_names else "Direct"
        date_str = t.get("date", "")
        lines.append(
            f"- Option {idx} : Date : {date_str} | {t.get('operator', 'Veyn Express')} | Départ {t.get('departure')} -> Arrivée {t.get('arrival')} "
            f"(Durée {t.get('durationLabel')}) | Tarif : {t.get('price')} {t.get('currency')} | "
            f"Places restantes : {t.get('seatsLeft')} | Arrêts : {stops_str}"
        )
    return "\n".join(lines)

def build_policies_context(config_texts: List[str]) -> str:
    policies = [
        "Assistance aux voyageurs à mobilité réduite (PMR / handicap) : Réduction de 50 % sur le tarif adulte standard. Accompagnement dédié à bord et lors du passage de la frontière de Ras Jedir (assistance pour l'embarquement, les contrôles et l'accès en fauteuil roulant). Pour toute demande spécifique comme un siège adapté, contacter directement le service client Veyn.",
        "Réduction bébés < 2 ans : 100% de réduction (gratuit sur les genoux d'un adulte) ou 50% de réduction avec un siège individuel réservé.",
        "Réduction enfants < 6 ans : 50% de réduction sur le tarif adulte standard.",
        "Franchise bagages : 1 valise en soute (jusqu'à 25 kg) et 1 bagage à main ou sac à dos en cabine par voyageur inclus sans surcoût.",
        "Équipements et confort : Autocars climatisés Grand Tourisme, sièges inclinables grand confort, prises USB individuelles pour recharge, Wi-Fi haut débit à bord.",
        "Poste frontière Ras Jedir : Passage sécurisé avec assistance à bord pour l'ensemble des passagers, contrôle douanier fluide (passeport en cours de validité indispensable).",
        "Validité et annulation : Billets valables 6 mois à compter de la date d'achat. Annulation gratuite sans frais jusqu'à 7 jours avant le départ.",
        "Animaux de compagnie : Seuls les chiens guides d'assistance accompagnant les personnes malvoyantes sont admis à bord de nos autocars.",
    ]
    for text in config_texts:
        if text not in policies:
            policies.append(text)
    return "\n".join([f"- {p}" for p in policies])

# --- Classificateur d'intention ---

POLICY_KEYWORDS = [
    # Bagages
    "bagage", "bagages", "valise", "valises", "sac", "poids", "kilo", "kg",
    # Tarifs / réductions / assistance
    "tarif", "prix", "reduction", "reduit", "enfant", "bebe", "nourrisson",
    "pmr", "handicap", "mobilite", "fauteuil", "special", "assistance", "senior", "etudiant",
    # Annulation / modification
    "annulation", "annuler", "remboursement", "rembourser", "modification", "modifier",
    "billet", "ticket", "validite", "valide",
    # Confort / équipements
    "wifi", "internet", "climatisation", "clim", "usb", "prise", "confort", "siege",
    # Frontière / documents
    "douane", "frontiere", "passeport", "visa", "document", "carte nationale",
    # Animaux
    "animal", "animaux", "chien", "chat",
    # Questions explicatives
    "politique", "regle", "condition", "inclus", "gratuit", "payant",
    # Arabe
    "امتعة", "حقيبة", "تذكرة", "الغاء", "رسوم", "طفل", "اطفال", "جواز", "حدود", "واي فاي", "خاصة", "اعاقة",
]

SEARCH_KEYWORDS = [
    "trajet", "bus", "taxi", "transport", "voyage", "partir", "depart", "arrivee",
    "disponible", "horaire", "prochain", "cherche", "recherche", "trouver", "aller",
    "رحلة", "حافلة", "موعد", "سفر", "متاح",
]

def classify_intent(question: str, has_origin: bool, has_dest: bool) -> str:
    """
    Classifie l'intention de la question pour choisir le format de réponse.
    Retourne : 'search' | 'policy' | 'mixed' | 'general'
    """
    if not question:
        return "search"
    q_norm = clean_term(question)
    has_policy_kw = any(kw in q_norm for kw in POLICY_KEYWORDS)
    has_search_kw = any(kw in q_norm for kw in SEARCH_KEYWORDS)
    has_cities = has_origin and has_dest

    if has_policy_kw and has_cities:
        return "mixed"    # question politique + contexte de trajet -> texte + cards
    if has_policy_kw:
        return "policy"   # policy keyword sans villes -> toujours policy (meme avec mot de recherche)
    if has_search_kw or has_cities:
        return "search"   # recherche de trajet -> cards
    return "general"      # conversation generale


def build_policy_prompt(question: str, policies_context: str, lang: str = "fr") -> str:
    """Prompt LLM pour une réponse propre, naturelle, professionnelle et richement formatée."""
    if lang == "ar":
        lang_directive = (
            "LANGUE STRICTEMENT OBLIGATOIRE : ARABE standard moderne (العربية الفصحى).\n"
            "Tu DOIS répondre EXCLUSIVEMENT en arabe. Aucun mot en français ni en anglais n'est toléré."
        )
    elif lang == "en":
        lang_directive = (
            "MANDATORY LANGUAGE: ENGLISH.\n"
            "You MUST reply EXCLUSIVELY in English. No words in French or Arabic are allowed."
        )
    else:
        lang_directive = (
            "LANGUE STRICTEMENT OBLIGATOIRE : Français.\n"
            "Tu dois répondre en français soigné."
        )

    return f"""Tu es l'assistant de voyage et de réservation Veyn. Ton rôle est de fournir des réponses propres, chaleureuses, professionnelles et agréables à lire.

QUESTION DU CLIENT :
{question}

POLITIQUES ET INFORMATIONS OFFICIELLES VEYN :
{policies_context}

DIRECTIVES DE RÉDACTION ET DE MISE EN FORME :
1. EXPÉRIENCE CLIENT ET CONFIDENTIALITÉ TECHNIQUE :
   - Ne mentionne JAMAIS de syntaxe brute ni de noms techniques internes de configuration ou de base de données (ne JAMAIS afficher de termes comme "special_needs_discount", "age_discount", "ticket_validity", "paramètre système", "table config", "ID", etc.).
   - Rédige toujours sous forme de texte fluide, rédigé directement pour le client final, comme un conseiller de voyage haut de gamme.

2. MISE EN FORME RICHE ET HARMONIEUSE :
   - Pour une question simple ou courte : réponds de façon concise et naturelle en 1 à 2 phrases sans titre inutile.
   - Pour une réponse explicative ou multi-sections (ex: conditions de voyage, assistance PMR, politique bagages, annulation) :
     * Utilise un titre de section en '## Nom du sujet' (ex: ## Assistance aux voyageurs à mobilité réduite).
     * Utilise des sous-titres en '### Sous-titre' pour organiser les thèmes (ex: ### Accompagnement pendant le voyage, ### Demandes particulières).
     * Utilise des listes à puces avec '-' lorsque plusieurs éléments doivent être énumérés clairement.
     * Utilise le **gras** pour mettre en évidence les chiffres, réductions, pourcentages, délais et informations clés (ex: **réduction de 50 %**, **25 kg**, **gratuit**, **7 jours**).
   - La mise en forme doit rester élégante et aérée, jamais excessive.

3. {lang_directive}
   - N'invente rien : base-toi uniquement sur les services et politiques officielles Veyn listées ci-dessus."""


def build_policy_fallback(question: str, policies_context: str, lang: str = "fr") -> str:
    """
    Fallback textuel enrichi quand le modèle LLM est indisponible.
    """
    q = clean_term(question)

    if lang == "ar":
        if any(w in q for w in ["pmr", "handicap", "mobilite", "fauteuil", "special", "assistance", "اعاقة", "خاصة", "مساعدة"]):
            return (
                "## مساعدة المسافرين من ذوي الاحتياجات الخاصة\n\n"
                "يستفيد المسافرون من ذوي الاحتياجات الخاصة من **تخفيض بنسبة 50 %** على سعر تذكرة البالغين.\n\n"
                "### المرافقة أثناء السفر\n"
                "تتوفر مرافقة خاصة على متن الحافلات وعند معبر راس جدير الحدودي لتسهيل إجراءات الصعود والتفتيش.\n\n"
                "### طلبات خاصة\n"
                "لأي طلب خاص كحجز مقعد مهيأ أو استخدام كرسي متحرك، يرجى التواصل مباشرة مع مصلحة عملاء Veyn لترتيب رحلتكم بأفضل الشروط."
            )

        if any(w in q for w in ["bagage", "valise", "sac", "poids", "kilo", "kg", "امتعة", "حقيبة", "وزن"]):
            return (
                "## سياسة الأمتعة المسموحة في Veyn\n\n"
                "يستفيد كل مسافر مجاناً من:\n"
                "- **حقيبة أمتعة واحدة في صندوق الحافلة** (حتى **25 كغ**)\n"
                "- **حقيبة يد أو حقيبة ظهر صغيرة** داخل المقصورة\n\n"
                "قد تخضع الأمتعة الإضافية أو ذات الحجم الكبير لرسوم إضافية حسب توفر الأماكن على متن الحافلة."
            )

        if any(w in q for w in ["enfant", "bebe", "nourrisson", "age", "mineur", "tarif", "famille", "طفل", "اطفال", "رضيع", "عائلة"]):
            return (
                "## أسعار وتخفيضات العائلات والأطفال\n\n"
                "- **الرضع (أقل من سنتين)**: **مجانًا** برفقة شخص بالغ (أو **تخفيض بنسبة 50 %** في حال حجز مقعد مخصص).\n"
                "- **الأطفال (أقل من 6 سنوات)**: **تخفيض بنسبة 50 %** على سعر تذكرة البالغين."
            )

        if any(w in q for w in ["wifi", "internet", "connexion", "clim", "climatisation", "usb", "prise", "confort", "siege", "واي فاي", "انترنت", "تكييف"]):
            return (
                "## الراحة والتجهيزات على متن الحافلات\n\n"
                "حافلاتنا السياحية مجهزة لضمان أقصى درجات الراحة:\n"
                "- **تكييف هوائي شامل** وقابل للتعديل\n"
                "- **مقاعد مريحة قابلة للإمالة**\n"
                "- **منافذ USB فردية** لشحن أجهزتكم\n"
                "- **خدمة Wi-Fi مجانية** للبقاء على اتصال طوال الرحلة"
            )

        if any(w in q for w in ["annul", "rembours", "modifier", "modification", "validite", "valable", "الغاء", "استرجاع", "تعديل", "صلاحية"]):
            return (
                "## صلاحية التذاكر وسياسة الإلغاء\n\n"
                "- **صلاحية التذاكر**: تظل تذاكركم صالحة لمدة **6 أشهر**.\n"
                "- **إلغاء مجاني**: يمكنكم إلغاء الحجز **مجانًا دون أي رسوم** حتى **7 أيام** قبل موعد الرحلة."
            )

        if any(w in q for w in ["frontiere", "douane", "passeport", "visa", "ras jedir", "ras ajdir", "حدود", "معبر", "جواز", "راس جدير"]):
            return (
                "## العبور عبر معبر رأس جدير الحدودي\n\n"
                "يتم العبور عبر معبر **رأس جدير** تحت إشراف ومرافقة لتسهيل الإجراءات الجمركية. يُشترط استظهار **جواز سفر ساري المفعول** للسفر."
            )

        if any(w in q for w in ["animal", "animaux", "chien", "chat", "حيوان", "حيوانات"]):
            return (
                "## الحيوانات الأليفة\n\n"
                "لدواعي النظافة والسلامة، يُسمح فقط بـ **كلاب المرافقة المعتمدة** لذوي الإعاقة البصرية على متن حافلاتنا."
            )

        return (
            "مرحباً بك! أنا في خدمتكم للإجابة عن استفساراتكم حول الرحلات والمواعيد والأسعار وسياسات Veyn. "
            "تفضل بطرح سؤالك أو التواصل مع خدمة العملاء."
        )

    elif lang == "en":
        if any(w in q for w in ["pmr", "handicap", "mobilite", "fauteuil", "special", "assistance"]):
            return (
                "## Assistance for Travelers with Reduced Mobility\n\n"
                "Passengers with reduced mobility receive a **50% discount** off standard adult fares.\n\n"
                "### Assistance During the Journey\n"
                "Dedicated assistance is provided on board and at the Ras Jedir border crossing to facilitate boarding and customs controls.\n\n"
                "### Special Requests\n"
                "For specific requests (such as an adapted seat or wheelchair accommodation), please contact Veyn customer support directly."
            )

        if any(w in q for w in ["bagage", "valise", "sac", "poids", "kilo", "kg", "baggage", "luggage"]):
            return (
                "## Veyn Baggage Allowance\n\n"
                "Each passenger is entitled free of charge to:\n"
                "- **1 hold luggage item** (up to **25 kg**)\n"
                "- **1 handbag or small backpack** in the cabin\n\n"
                "Additional or oversized baggage may be subject to a fee depending on onboard capacity."
            )

        if any(w in q for w in ["enfant", "bebe", "nourrisson", "age", "mineur", "tarif", "famille", "child", "children", "baby", "family"]):
            return (
                "## Family and Children Rates\n\n"
                "- **Infants under 2 years**: **Free** on an adult's lap (or **50% off** if a separate seat is booked).\n"
                "- **Children under 6 years**: **50% discount** off standard adult fares."
            )

        if any(w in q for w in ["wifi", "internet", "connexion", "clim", "climatisation", "usb", "prise", "confort", "siege"]):
            return (
                "## Onboard Comfort and Amenities\n\n"
                "Our coaches are equipped for your convenience:\n"
                "- **Full adjustable climate control**\n"
                "- **Reclining comfort seats**\n"
                "- **Individual USB charging sockets**\n"
                "- **Onboard Wi-Fi** to stay connected"
            )

        if any(w in q for w in ["annul", "rembours", "modifier", "modification", "validite", "valable", "cancel", "refund", "validity"]):
            return (
                "## Ticket Validity and Cancellation Policy\n\n"
                "- **Ticket Validity**: Tickets are valid for **6 months**.\n"
                "- **Free Cancellation**: You can cancel **free of charge** up to **7 days** before departure."
            )

        if any(w in q for w in ["frontiere", "douane", "passeport", "visa", "ras jedir", "border", "passport"]):
            return (
                "## Ras Jedir Border Crossing\n\n"
                "The **Ras Jedir** border crossing is supervised with onboard assistance to streamline customs procedures. A **valid passport** is mandatory to travel."
            )

        if any(w in q for w in ["animal", "animaux", "chien", "chat", "pet", "pets", "dog"]):
            return (
                "## Pet Policy\n\n"
                "For health and safety reasons, only certified **guide dogs** are allowed on board our coaches."
            )

        return (
            "Hello! I am here to help you with all questions regarding Veyn journeys, timetables, fares, and policies. "
            "Feel free to ask or reach out to our customer support."
        )

    # French (default)
    if any(w in q for w in ["pmr", "handicap", "mobilite", "fauteuil", "special", "assistance"]):
        return (
            "## Assistance aux voyageurs à mobilité réduite\n\n"
            "Les voyageurs à mobilité réduite bénéficient d'une **réduction de 50 %** sur le tarif adulte standard.\n\n"
            "### Accompagnement pendant le voyage\n"
            "Un accompagnement est prévu à bord ainsi que lors du passage à la frontière de Ras Jedir, notamment pour faciliter l'embarquement et les contrôles.\n\n"
            "### Demandes particulières\n"
            "Pour toute demande spécifique, comme un siège adapté ou l'utilisation d'un fauteuil roulant, veuillez contacter directement le service client Veyn afin d'organiser votre voyage dans les meilleures conditions."
        )

    if any(w in q for w in ["bagage", "valise", "sac", "poids", "kilo", "kg"]):
        return (
            "## Franchise bagages Veyn\n\n"
            "Chaque voyageur bénéficie sans surcoût de :\n"
            "- **1 valise en soute** (jusqu'à **25 kg**)\n"
            "- **1 sac à main ou sac à dos** en cabine\n\n"
            "Les bagages supplémentaires ou volumineux peuvent faire l'objet d'un supplément selon la disponibilité à bord."
        )

    if any(w in q for w in ["enfant", "bebe", "nourrisson", "age", "mineur", "tarif", "famille"]):
        return (
            "## Tarifs et réductions familles\n\n"
            "- **Bébés de moins de 2 ans** : **Gratuit** sur les genoux d'un adulte (ou **50 % de réduction** si un siège individuel est réservé).\n"
            "- **Enfants de moins de 6 ans** : **50 % de réduction** sur le tarif adulte standard."
        )

    if any(w in q for w in ["wifi", "internet", "connexion", "clim", "climatisation", "usb", "prise", "confort", "siege"]):
        return (
            "## Confort et équipements à bord\n\n"
            "Nos autocars Grand Tourisme sont équipés pour votre confort :\n"
            "- **Climatisation intégrale** réglable\n"
            "- **Sièges inclinables** grand confort\n"
            "- **Prises USB individuelles** pour la recharge de vos appareils\n"
            "- **Wi-Fi à bord** pour rester connecté tout au long du trajet"
        )

    if any(w in q for w in ["annul", "rembours", "modifier", "modification", "validite", "valable"]):
        return (
            "## Validité et politique d'annulation\n\n"
            "- **Validité des billets** : Vos billets sont valables pendant **6 mois**.\n"
            "- **Annulation sans frais** : Vous pouvez annuler **gratuitement sans frais** jusqu'à **7 jours** avant le départ."
        )

    if any(w in q for w in ["frontiere", "douane", "passeport", "visa", "ras jedir", "ras ajdir"]):
        return (
            "## Passage frontière Ras Jedir\n\n"
            "Le passage frontalier de **Ras Jedir** s'effectue sous encadrement sécurisé avec assistance à bord pour simplifier les formalités douanières. Un **passeport en cours de validité** est indispensable pour voyager."
        )

    if any(w in q for w in ["animal", "animaux", "chien", "chat"]):
        return (
            "## Animaux de compagnie\n\n"
            "Pour des raisons d'hygiène et de sécurité, seuls les **chiens guides d'assistance** sont admis à bord de nos autocars."
        )

    return (
        "Bonjour ! Je suis à votre entière disposition pour répondre à toutes vos questions sur les trajets, horaires, tarifs et services Veyn. "
        "N'hésitez pas à me demander des précisions ou à contacter directement notre service client."
    )


# ============================================================
# PIPELINE DE COMPRÉHENSION SÉMANTIQUE & GESTION DYNAMIQUE DES PRÉCISIONS
# ============================================================

import json

def _extract_mention_dates(text: str, today: datetime.date = None) -> List[str]:
    """Extrait de façon déterministe les jours mentionnés dans le texte (arabe, français, anglais)."""
    if not text:
        return []
    if today is None:
        today = datetime.date.today()

    norm = text.lower().replace("أ", "ا").replace("إ", "ا").replace("آ", "ا").replace("ة", "ه")

    # Si l'utilisateur révoque explicitement les dates
    if any(phrase in norm for phrase in ["peu importe la date", "n'importe quelle date", "sans date", "اي يوم", "اي تاريخ"]):
        return []

    found_dates = []
    if any(w in norm for w in ["اليوم", "aujourd", "today"]):
        found_dates.append(today.strftime("%Y-%m-%d"))
    if any(w in norm for w in ["غدا", "demain", "tomorrow"]):
        found_dates.append((today + datetime.timedelta(days=1)).strftime("%Y-%m-%d"))

    day_patterns = [
        (0, [r"\bالاثنين\b", r"\bاثنين\b", r"\blundi\b", r"\bmonday\b"]),
        (1, [r"\bالثلاثاء\b", r"\bثلاثاء\b", r"\bmardi\b", r"\btuesday\b"]),
        (2, [r"\bالاربعاء\b", r"\barbaa\b", r"\bاربعاء\b", r"\bmercredi\b", r"\bwednesday\b"]),
        (3, [r"\bالخميس\b", r"\bخميس\b", r"\bjeudi\b", r"\bthursday\b"]),
        (4, [r"\bالجمعه\b", r"\bجمعه\b", r"\bvendredi\b", r"\bfriday\b"]),
        (5, [r"\bالسبت\b", r"\bسبت\b", r"\bsamedi\b", r"\bsaturday\b"]),
        (6, [r"\bالاحد\b", r"\bاحد\b", r"\bdimanche\b", r"\bsunday\b"]),
    ]

    for w_idx, patterns in day_patterns:
        matched = False
        for p in patterns:
            if re.search(p, norm):
                matched = True
                break
        if matched:
            days_ahead = (w_idx - today.weekday()) % 7
            if days_ahead == 0 and not any(w in norm for w in ["اليوم", "aujourd", "today"]):
                days_ahead = 7
            target_date = today + datetime.timedelta(days=days_ahead)
            iso = target_date.strftime("%Y-%m-%d")
            if iso not in found_dates:
                found_dates.append(iso)

    return sorted(found_dates)


def analyze_and_update_precisions(
    question: str,
    current_trip: dict,
    messages: Optional[List[dict]] = None,
    lang: str = "fr"
) -> dict:
    """
    Analyse sémantique approfondie de la phrase utilisateur et mise à jour dynamique des précisions :
    1. Auto-correction transparente : fautes d'orthographe, frappe, dialectes et toponymie (ex: مصرطة -> Misrata, صفاقص -> Sfax).
    2. Résolution stricte et complète des dates :
       - Supporte les dates uniques ("demain", "غدا", "20 septembre").
       - Supporte les jours multiples / alternatifs ("mercredi ou jeudi", "الأربعاء أو الخميس", "ce week-end").
       - Convertit chaque jour mentionné en date ISO correspondante dans "dates": ["YYYY-MM-DD", ...].
       - Ne perd JAMAIS une contrainte de date exprimée par l'utilisateur !
    3. Suivi de l'état conversationnel multi-tours :
       - Conserver les critères valables non contredits.
       - Modifier / remplacer les critères modifiés par l'utilisateur.
       - Supprimer les critères explicitement révoqués ("peu importe l'heure" -> effacer time_period).
    4. Focus précis : "list_all" pour une recherche sur des dates précises, sans forcer "find_next".
    """
    today = datetime.date.today()
    extracted_text_dates = _extract_mention_dates(question, today)

    weekday_names = {
        0: ("Monday", "lundi", "الاثنين"),
        1: ("Tuesday", "mardi", "الثلاثاء"),
        2: ("Wednesday", "mercredi", "الأربعاء"),
        3: ("Thursday", "jeudi", "الخميس"),
        4: ("Friday", "vendredi", "الجمعة"),
        5: ("Saturday", "samedi", "السبت"),
        6: ("Sunday", "dimanche", "الأحد"),
    }

    calendar_lines = []
    days_map = {}
    for i in range(14):
        d = today + datetime.timedelta(days=i)
        w_en, w_fr, w_ar = weekday_names[d.weekday()]
        tag = " [AUJOURD'HUI / TODAY / اليوم]" if i == 0 else (" [DEMAIN / TOMORROW / غدا]" if i == 1 else "")
        iso_d = d.strftime("%Y-%m-%d")
        calendar_lines.append(f"- {iso_d} : {w_en} | {w_fr} | {w_ar}{tag}")
        days_map[w_en.lower()] = iso_d
        days_map[w_fr.lower()] = iso_d
        days_map[w_ar] = iso_d

    calendar_str = "\n".join(calendar_lines)

    cur_origin = (current_trip.get("origin") or {}).get("name") if isinstance(current_trip.get("origin"), dict) else current_trip.get("origin")
    cur_dest = (current_trip.get("destination") or {}).get("name") if isinstance(current_trip.get("destination"), dict) else current_trip.get("destination")
    cur_date = current_trip.get("date")
    cur_dates = current_trip.get("dates") or ([cur_date] if cur_date else [])
    cur_period = current_trip.get("period")
    cur_periods = current_trip.get("periods") or ([cur_period] if cur_period else [])
    cur_exact_time = current_trip.get("exactTime")
    cur_modes = current_trip.get("modes") or []
    cur_budget = current_trip.get("budget")

    simplified_current = {
        "origin": cur_origin,
        "destination": cur_dest,
        "dates": cur_dates,
        "time_period": cur_period,
        "periods": cur_periods,
        "exact_time": cur_exact_time,
        "modes": cur_modes,
        "budget": cur_budget
    }

    fallback_dates = extracted_text_dates if extracted_text_dates else cur_dates
    fallback = {
        "corrected_question": question,
        "intent": "search_trips" if (cur_origin and cur_dest) else "general",
        "query_focus": "list_all",
        "sort_by": None,
        "precisions": {
            "origin": cur_origin,
            "destination": cur_dest,
            "dates": fallback_dates,
            "date": fallback_dates[0] if fallback_dates else None,
            "date_is_after": False,
            "time_period": cur_period,
            "periods": cur_periods,
            "exact_time": cur_exact_time,
            "modes": cur_modes,
            "budget": cur_budget
        },
        "changed_fields": ["dates"] if extracted_text_dates else [],
        "cleared_fields": [],
        "policy_topics": []
    }

    if not groq_client or not question:
        return fallback

    recent_msgs = []
    if messages:
        for m in messages[-6:]:
            role = m.get("role", "user")
            txt = m.get("text", "")
            if txt:
                recent_msgs.append({"role": role, "text": txt[:300]})

    prompt = f"""You are the conversational NLU and Dynamic Precision Management Engine for Veyn Transport.
Analyze the user's message in the FULL CONTEXT of the conversation and existing trip precisions.

CALENDAR CONTEXT (Upcoming 14 days):
{calendar_str}

CURRENT TRIP PRECISIONS (State before this message):
{json.dumps(simplified_current, ensure_ascii=False, indent=2)}

RECENT CONVERSATION HISTORY:
{json.dumps(recent_msgs, ensure_ascii=False, indent=2) if recent_msgs else "[] (First message)"}

NEW USER MESSAGE:
"{question}"

CRITICAL INSTRUCTIONS:
1. AUTO-CORRECTION:
   - "صفاقص" / "صفاكس" -> "Sfax" / "صفاقس"
   - "مصرطة" / "مصراته" / "مسراتة" -> "Misrata" / "مصراتة" (NOT Sirte!)
   - "طربلس" -> "Tripoli" / "طرابلس"
   - "سوسه" -> "Sousse" / "سوسة"
   - Output `corrected_question`.

2. DATES RESOLUTION (STRICT RULE: NEVER DROP DATES - MULTI-SELECTION SUPPORT):
   - ALWAYS look up mentioned days in the CALENDAR CONTEXT above!
   - Multiple days ("mercredi ou jeudi", "الاربعاء او الخميس", "الأربعاء أو الخميس أو السبت") -> resolve EACH day to its upcoming ISO date:
     e.g. Wednesday and Thursday -> dates: ["YYYY-MM-DD", "YYYY-MM-DD"]!
   - Single day ("demain" / "غدا" / "dimanche") -> dates: ["YYYY-MM-DD"]!
   - Weekend ("ce week-end" / "نهاية الأسبوع") -> dates: ["YYYY-MM-DD", "YYYY-MM-DD"]!
   - Date range ("entre le 20 et le 23") -> dates: ["2026-09-20", "2026-09-21", "2026-09-22", "2026-09-23"]!
   - If user says "peu importe la date" / "أي يوم" -> dates: [], cleared_fields: ["dates"]!
   - NEVER leave dates empty or null if the user specified days or dates in their sentence!

3. TIME PERIODS RESOLUTION (MULTI-SELECTION SUPPORT):
   - Multiple periods ("matin ou soir", "الصباح أو المساء") -> periods: ["morning", "evening"]!
   - Single period ("le matin", "صباحاً") -> periods: ["morning"]!
   - Exact time ("à 15h30", "الساعة 15:00") -> exact_time: "15:00"!
   - If user says "peu importe l'heure" -> periods: [], exact_time: null, cleared_fields: ["time_period"]!

4. TRANSPORT MODES RESOLUTION (MULTI-SELECTION SUPPORT):
   - Modes: "bus", "train", "shared_taxi", "plane", "ferry"
   - Multiple modes ("bus ou train", "حافلة أو قطار") -> modes: ["bus", "train"]!

5. DYNAMIC STATE TRACKING (Conversation memory):
   - KEEP: Keep any previously defined precision that is NOT contradicted or modified by the user.
   - MODIFY / REPLACE: When user specifies a new value, update it.
   - CLEAR: When user clears a criterion, add to cleared_fields.

6. QUERY FOCUS & INTENT (ABSOLUTE RULE):
   - ALWAYS set "query_focus": "list_all" when the user specifies DAYS or DATES.
   - ONLY use "find_next" when the user EXPLICITLY asks for the SINGLE nearest trip. Never use find_next if dates are present!
   - RULE: if precisions.dates is non-empty -> query_focus MUST be "list_all".

Return ONLY a valid JSON object:
{{
  "corrected_question": "string",
  "intent": "search_trips | policy_query | mixed | general",
  "query_focus": "find_cheapest | find_fastest | find_next | count | compare | list_all",
  "sort_by": "price_asc | price_desc | departure_asc | null",
  "precisions": {{
    "origin": "Standard City Name or null",
    "destination": "Standard City Name or null",
    "dates": ["YYYY-MM-DD", ...],
    "date_is_after": false,
    "time_period": "morning | afternoon | evening | null",
    "periods": ["morning", "afternoon", "evening"],
    "exact_time": "HH:MM or null",
    "modes": ["bus", "train", "shared_taxi", "plane", "ferry"],
    "budget": number or null
  }},
  "changed_fields": ["origin", "destination", "dates", ...],
  "cleared_fields": [],
  "policy_topics": []
}}"""

    try:
        raw = generate_llm_response(prompt)
        match = re.search(r'\{[\s\S]*\}', raw)
        if match:
            parsed = json.loads(match.group(0))
            if "precisions" not in parsed:
                parsed["precisions"] = fallback["precisions"]
            else:
                p = parsed["precisions"]
                # Dates
                if (not p.get("dates") or len(p.get("dates", [])) == 0) and extracted_text_dates:
                    p["dates"] = extracted_text_dates
                if "dates" in p and p["dates"]:
                    p["date"] = p["dates"][0]
                    parsed["query_focus"] = "list_all"
                elif "date" in p and p["date"]:
                    p["dates"] = [p["date"]]
                    parsed["query_focus"] = "list_all"
                else:
                    p["dates"] = cur_dates if "dates" not in parsed.get("cleared_fields", []) else []
                    p["date"] = p["dates"][0] if p["dates"] else None

                # Periods
                if "periods" in p and p["periods"]:
                    p["time_period"] = p["periods"][0]
                elif "time_period" in p and p["time_period"]:
                    p["periods"] = [p["time_period"]]
                else:
                    p["periods"] = cur_periods if "time_period" not in parsed.get("cleared_fields", []) else []
                    p["time_period"] = p["periods"][0] if p["periods"] else None

                # Modes
                if "modes" not in p or p["modes"] is None:
                    p["modes"] = cur_modes if "modes" not in parsed.get("cleared_fields", []) else []

            return parsed
    except Exception as e:
        print(f"[WARN] analyze_and_update_precisions error: {repr(e)[:200]}")

    return fallback


def build_dynamic_sql(precisions: dict, origin_id: str, dest_id: str, query_focus: str = "list_all", sort_by: str = None) -> tuple:
    """
    Étape 2 : Construit dynamiquement la requête SQL STRICTE selon les précisions.
    Supporte les dates uniques, dates multiples (IN), périodes horaires multiples (OR) et budgets.
    Ne relâche JAMAIS silencieusement les filtres pour garantir la cohérence absolue de la carte.
    """
    dates = precisions.get("dates") or []
    date_val = precisions.get("date")
    if date_val and date_val not in dates:
        dates.append(date_val)

    date_is_after = precisions.get("date_is_after", False)
    time_period = precisions.get("time_period")
    periods = precisions.get("periods") or []
    if not periods and time_period:
        periods = [time_period]
    max_price = precisions.get("budget")

    meta = {
        "dates": dates,
        "date": dates[0] if dates else None,
        "date_is_after": date_is_after,
        "time_period": time_period,
        "periods": periods,
        "sort_by": sort_by or "departure_asc",
        "query_focus": query_focus,
        "max_price": max_price,
    }

    base_cte = """
        WITH matching_routes AS (
            SELECT r.id AS route_id, r.name AS route_name, r.international,
                   rs1."order" AS origin_order, rs2."order" AS dest_order
            FROM routes r
            JOIN route_segments rs1 ON r.id = rs1.route_id
            JOIN route_segments rs2 ON r.id = rs2.route_id
            WHERE rs1.stop_id = %s AND rs2.stop_id = %s AND rs1."order" < rs2."order"
        )
    """
    params = [origin_id, dest_id]

    # Filtrage strict des dates (IN multi-dates)
    if dates:
        if len(dates) == 1:
            if date_is_after:
                date_clause = "AND ns.date >= %s"
                params.append(dates[0])
            else:
                date_clause = "AND ns.date = %s"
                params.append(dates[0])
        else:
            placeholders = ", ".join(["%s"] * len(dates))
            date_clause = f"AND ns.date IN ({placeholders})"
            params.extend(dates)
    else:
        date_clause = "AND ns.date >= CURRENT_DATE"

    # Filtrage strict de la tranche horaire (OR entre tranches multiples)
    time_clause = ""
    period_clauses = []
    for p in periods:
        if p == "morning":
            period_clauses.append("EXTRACT(HOUR FROM ns.time) < 12")
        elif p == "afternoon":
            period_clauses.append("(EXTRACT(HOUR FROM ns.time) >= 12 AND EXTRACT(HOUR FROM ns.time) < 18)")
        elif p == "evening":
            period_clauses.append("EXTRACT(HOUR FROM ns.time) >= 18")
    if period_clauses:
        time_clause = "AND (" + " OR ".join(period_clauses) + ")"

    order_clause = "ORDER BY ns.date ASC, ns.time ASC"
    limit = 20
    if query_focus == "count":
        limit = 100

    sql = f"""
        {base_cte}
        SELECT mr.route_id, mr.route_name, mr.international, mr.origin_order, mr.dest_order,
               ns.id as schedule_id, ns.date, ns.time
        FROM matching_routes mr
        JOIN next_schedules ns ON mr.route_id = ns.route_id
        WHERE 1=1
        {date_clause}
        {time_clause}
        {order_clause}
        LIMIT {limit};
    """

    return sql, params, meta


def build_focused_response_prompt(
    question: str,
    nlu_data: dict,
    trips: List[Dict[str, Any]],
    policies_context: str,
    disp_origin: str,
    disp_dest: str,
    dates: List[str],
    travelers_str: str,
    lang: str
) -> str:
    """
    Étape 3 : Prompt LLM pour la réponse ciblée respectant scrupuleusement les dates demandées.
    - Si des trajets sont trouvés : annonce directement les départs sur les dates demandées.
    - Si 0 trajet trouvé : explique poliment et clairement pourquoi aucun départ n'est disponible sur ces dates précises.
    - INTERDICTION de chercher la "prochaine date disponible" si l'utilisateur a spécifié des dates précises !
    """
    query_focus = nlu_data.get("query_focus", "list_all")
    intent = nlu_data.get("intent", "search_trips")
    precisions = nlu_data.get("precisions", {})
    time_period = precisions.get("time_period")

    is_arabic = (lang == "ar") or bool(re.search(r'[\u0600-\u06FF]', question))
    is_english = (lang == "en")
    if is_arabic:
        lang_directive = "LANGUE STRICTEMENT OBLIGATOIRE : ARABE standard moderne (العربية الفصحى). Tu DOIS répondre EXCLUSIVEMENT en arabe."
    elif is_english:
        lang_directive = "MANDATORY LANGUAGE: ENGLISH. You MUST reply EXCLUSIVELY in English."
    else:
        lang_directive = "LANGUE STRICTEMENT OBLIGATOIRE : Français."

    period_label = {
        "morning": "le matin (avant 12h)" if not is_arabic else "في الصباح (قبل 12:00)",
        "afternoon": "l'après-midi (12h-18h)" if not is_arabic else "بعد الظهر (12:00 - 18:00)",
        "evening": "le soir (après 18h)" if not is_arabic else "في المساء (بعد 18:00)"
    }.get(time_period or "", "")

    dates_str = ", ".join(dates) if dates else ""

    # CAS 1 : AUCUN TRAJET NE CORRESPOND AUX CRITÈRES STRICTS
    if not trips:
        criteria_parts = [f"de {disp_origin} à {disp_dest}"]
        if dates:
            criteria_parts.append(f"pour le(s) {dates_str}")
        if period_label:
            criteria_parts.append(period_label)
        crit_str = " ".join(criteria_parts)

        return (
            f"Tu es l'assistant Veyn. Aucun trajet ne correspond aux critères stricts demandés par l'utilisateur.\n"
            f"Demande du client : {question}\n"
            f"Critères demandés : {crit_str}\n\n"
            f"Consignes :\n"
            f"1. Explique poliment et clairement en 1 phrase qu'aucun départ n'est disponible pour les dates ou créneaux demandés ({dates_str}).\n"
            f"2. Invite cordialement le client à choisir une autre date ou modifier la tranche horaire.\n"
            f"3. {lang_directive}\n"
            f"4. N'invente aucun horaire ni tarif imaginaire."
        )

    # CAS 2 : DES TRAJETS ONT ÉTÉ TROUVÉS
    trips_text = format_trips_for_prompt(trips)
    focus_instructions = ""

    if query_focus == "find_cheapest":
        cheapest = min(trips, key=lambda t: t.get("price", 9999))
        focus_instructions = (
            f"\n⚑ FOCUS : L'utilisateur veut SPÉCIFIQUEMENT savoir quel trajet est le MOINS CHER.\n"
            f"Le trajet le moins cher est : départ {cheapest.get('departure')} "
            f"à {cheapest.get('price')} {cheapest.get('currency')} "
            f"({'le ' + cheapest.get('date') if cheapest.get('date') else ''}).\n"
            f"→ Mentionne ce prix minimum EN PREMIER et EN GRAS dans ta réponse avant d'annoncer les cartes."
        )
    elif query_focus == "find_next":
        next_trip = trips[0]
        focus_instructions = (
            f"\n⚑ FOCUS : L'utilisateur a explicitement demandé le PROCHAIN départ disponible.\n"
            f"Le prochain départ est à {next_trip.get('departure')} le {next_trip.get('date')}.\n"
            f"→ Mentionne cet horaire EN PREMIER dans ta réponse."
        )
    elif query_focus == "count":
        focus_instructions = (
            f"\n⚑ FOCUS : L'utilisateur veut savoir COMBIEN de trajets sont disponibles.\n"
            f"Il y a {len(trips)} trajet(s) disponible(s).\n"
            f"→ Donne le nombre exact en premier, puis annonce les cartes."
        )
    elif query_focus == "compare":
        focus_instructions = (
            f"\n⚑ FOCUS : L'utilisateur veut COMPARER les options disponibles.\n"
            f"→ Résume brièvement les différences clés (tarifs, horaires) avant les cartes."
        )

    if intent == "mixed":
        return (
            f"Tu es l'assistant Veyn. L'utilisateur pose une question sur les services ET recherche un trajet.\n\n"
            f"QUESTION DU CLIENT : {question}\n"
            f"POLITIQUES VEYN :\n{policies_context}\n"
            f"TRAJETS TROUVÉS ({len(trips)}) entre {disp_origin} et {disp_dest} pour les dates demandées :\n{trips_text}\n"
            f"{focus_instructions}\n\n"
            f"REGLES STRICTES :\n"
            f"1. Corrige mentalement toute faute sans jamais la mentionner.\n"
            f"2. Réponds D'ABORD à la question sur les services en 1-2 phrases.\n"
            f"3. Annonce ensuite les cartes de trajets disponibles pour les dates demandées.\n"
            f"4. {lang_directive}"
        )
    else:
        return (
            f"Tu es l'assistant de voyage Veyn.\n\n"
            f"QUESTION DU CLIENT : {question}\n"
            f"CRITÈRES : De {disp_origin} vers {disp_dest}"
            f"{' | Dates : ' + dates_str if dates_str else ''}"
            f"{' | Période : ' + period_label if period_label else ''}"
            f" | Voyageurs : {travelers_str}\n"
            f"TRAJETS DISPONIBLES ({len(trips)}) :\n{trips_text}\n"
            f"{focus_instructions}\n\n"
            f"CONSIGNES STRICTES :\n"
            f"1. Corrige mentalement toute faute sans jamais la mentionner.\n"
            f"2. Annonce les cartes de façon très concise et naturelle (1 phrase) pour les dates demandées ({dates_str}).\n"
            f"3. N'invente JAMAIS une 'prochaine date' qui ne correspond pas aux dates demandées par le client !\n"
            f"4. Ne redécris pas chaque carte en détail (elles s'affichent en dessous).\n"
            f"5. N'affiche JAMAIS de texte artificiel comme '[Carte 1]'.\n"
            f"6. {lang_directive}"
        )


# --- Endpoint API pour le Frontend React & Mobile Flutter ---
@app.post("/api/chat", response_model=AssistantResponseModel)
async def api_chat(request: ChatApiRequest):
    """
    Pipeline sémantique multi-tours complet avec mise à jour dynamique des précisions,
    support complet des dates multiples et cohérence stricte de la carte.
    """
    question = (request.question or "").strip()
    trip_dict = request.trip.dict() if request.trip else {}
    messages = request.messages or []
    lang = (request.language or "fr").lower()

    is_arabic_query = (lang == "ar") or bool(re.search(r"[\u0600-\u06FF]", question))
    is_english_query = (lang == "en")

    is_default_query = not question or question.strip() in [
        "Rechercher avec ces informations.",
        "Rechercher avec ces informations",
        "Recherche avec les critères précisés ci-dessus",
        "Recherche avec les critères précisés ci-dessus.",
        "Recherche de trajet",
        "Search with this information.",
        "Search with this information",
        "البحث بهذه المعلومات.",
        "البحث بهذه المعلومات"
    ]

    # ================================================================
    # ÉTAPE 1 : AUTO-CORRECTION & ANALYSE MULTI-TOURS DES PRÉCISIONS
    # ================================================================
    if question and not is_default_query:
        nlu_result = analyze_and_update_precisions(question, trip_dict, messages, lang)
    else:
        cur_o = (trip_dict.get("origin") or {}).get("name") if isinstance(trip_dict.get("origin"), dict) else trip_dict.get("origin")
        cur_d = (trip_dict.get("destination") or {}).get("name") if isinstance(trip_dict.get("destination"), dict) else trip_dict.get("destination")
        cur_dt = trip_dict.get("date")
        cur_dts = trip_dict.get("dates") or ([cur_dt] if cur_dt else [])
        cur_period = trip_dict.get("period")
        cur_periods = trip_dict.get("periods") or ([cur_period] if cur_period else [])
        cur_modes = trip_dict.get("modes", [])
        nlu_result = {
            "corrected_question": question,
            "intent": "search_trips" if (cur_o and cur_d) else "general",
            "query_focus": "list_all",
            "sort_by": None,
            "precisions": {
                "origin": cur_o,
                "destination": cur_d,
                "dates": cur_dts,
                "date": cur_dts[0] if cur_dts else None,
                "date_is_after": False,
                "time_period": cur_period,
                "periods": cur_periods,
                "exact_time": trip_dict.get("exactTime"),
                "modes": cur_modes,
                "budget": trip_dict.get("budget")
            },
            "changed_fields": [],
            "cleared_fields": [],
            "policy_topics": []
        }

    corrected_question = nlu_result.get("corrected_question", question)
    intent_type = nlu_result.get("intent", "general")
    query_focus = nlu_result.get("query_focus", "list_all")
    sort_by = nlu_result.get("sort_by")
    precisions = nlu_result.get("precisions", {})
    changed_fields = nlu_result.get("changed_fields", [])
    cleared_fields = nlu_result.get("cleared_fields", [])

    origin_name = precisions.get("origin")
    dest_name = precisions.get("destination")
    dates = precisions.get("dates") or []
    date_val = precisions.get("date") or (dates[0] if dates else None)
    periods_val = precisions.get("periods") or []
    period_val = precisions.get("time_period") or (periods_val[0] if periods_val else None)
    if not periods_val and period_val:
        periods_val = [period_val]
    exact_time = precisions.get("exact_time")
    effective_budget = precisions.get("budget")
    travelers_val = trip_dict.get("travelers")
    modes_val = precisions.get("modes") if precisions.get("modes") is not None else trip_dict.get("modes", [])

    # ── GARDE-FOU ABSOLU ──────────────────────────────────────────────────────
    # Si l'utilisateur a spécifié des dates précises, on NE PEUT PAS utiliser
    # find_next (qui retournerait tous les voyages futurs sans filtre de date).
    # On force list_all pour garantir la cohérence stricte de la carte.
    if dates and query_focus == "find_next":
        print(f"[FIX] query_focus=find_next → forcé à list_all car dates={dates}")
        query_focus = "list_all"
    # ─────────────────────────────────────────────────────────────────────────

    trip_patch: Dict[str, Any] = {}

    # Synchroniser les suppressions explicites de critères
    if "time_period" in cleared_fields or "period" in cleared_fields or "periods" in cleared_fields:
        trip_patch["period"] = None
        trip_patch["periods"] = []
        period_val = None
        periods_val = []
        precisions["periods"] = []
    elif periods_val:
        trip_patch["periods"] = periods_val
        trip_patch["period"] = periods_val[0]
        precisions["periods"] = periods_val

    if "date" in cleared_fields or "dates" in cleared_fields:
        trip_patch["date"] = None
        trip_patch["dates"] = []
        dates = []
        date_val = None
        precisions["dates"] = []
    elif dates:
        trip_patch["dates"] = dates
        trip_patch["date"] = dates[0]
        precisions["dates"] = dates

    if "modes" in cleared_fields:
        trip_patch["modes"] = []
        modes_val = []
        precisions["modes"] = []
    elif modes_val:
        trip_patch["modes"] = modes_val
        precisions["modes"] = modes_val

    if "budget" in cleared_fields:
        trip_patch["budget"] = None
        effective_budget = None
    elif effective_budget is not None:
        trip_patch["budget"] = effective_budget

    # ================================================================
    # ÉTAPE 1b : FALLBACK — Villes via extracteurs legacy si manquantes
    # ================================================================
    if (not origin_name or not dest_name) and question and not is_default_query:
        conn = None
        try:
            conn = get_db_connection()
            extracted = extract_cities_from_question(corrected_question or question, conn)
            if not origin_name and extracted["origin"]:
                origin_name = extracted["origin"]["name"]
                precisions["origin"] = origin_name
                trip_patch["origin"] = extracted["origin"]
            if not dest_name and extracted["destination"]:
                dest_name = extracted["destination"]["name"]
                precisions["destination"] = dest_name
                trip_patch["destination"] = extracted["destination"]
        except Exception as e:
            print("[WARN] Erreur extraction villes legacy :", e)
        finally:
            if conn:
                release_db_connection(conn)

    # Identifier les champs actifs pour les badges et filtres du frontend
    recognized_fields = set()
    if origin_name:
        recognized_fields.add("origin")
    if dest_name:
        recognized_fields.add("destination")
    if dates or date_val:
        recognized_fields.add("date")
    if period_val or exact_time:
        recognized_fields.add("time")
    if travelers_val and (travelers_val.get("adults", 0) > 0 or travelers_val.get("children", 0) > 0 or travelers_val.get("assisted", 0) > 0):
        recognized_fields.add("travelers")
    if modes_val:
        recognized_fields.add("modes")
    if effective_budget is not None:
        recognized_fields.add("budget")

    print(f"[CONV-STATE] intent={intent_type} | focus={query_focus} | origin={origin_name} | dest={dest_name} | dates={dates} | period={period_val} | cleared={cleared_fields}")

    # ================================================================
    # CAS A : POLITIQUE PURE / CONVERSATION GÉNÉRALE SANS VILLES
    # ================================================================
    if intent_type in ("policy_query", "general") and not (origin_name and dest_name):
        policies_context = build_policies_context(config_texts)
        reply_text = ""
        if groq_client and question:
            try:
                if intent_type == "policy_query":
                    prompt = build_policy_prompt(question, policies_context, lang=lang)
                else:
                    if is_arabic_query:
                        lang_consigne = "LANGUE STRICTEMENT OBLIGATOIRE : ARABE standard moderne (العربية الفصحى). Tu DOIS répondre EXCLUSIVEMENT en arabe."
                    elif is_english_query:
                        lang_consigne = "MANDATORY LANGUAGE: ENGLISH. You MUST respond EXCLUSIVELY in English."
                    else:
                        lang_consigne = "LANGUE STRICTEMENT OBLIGATOIRE : Français."
                    prompt = (
                        f"Tu es l'assistant de voyage et de réservation Veyn. Réponds au client avec un ton chaleureux, naturel et soigné.\n"
                        f"Demande du client : {question}\n\n"
                        f"Consignes :\n"
                        f"1. Réponds de façon concise (1-2 phrases maximum).\n"
                        f"2. Invite cordialement le client à préciser son trajet ou poser ses questions sur nos services.\n"
                        f"3. {lang_consigne}"
                    )
                reply_text = generate_llm_response(prompt)
            except Exception as e:
                print(f"[WARN] Groq general/policy : {repr(e)[:200]}")

        if not reply_text:
            reply_text = build_policy_fallback(question, policies_context, lang=lang)
            if is_arabic_query:
                reply_text += "\n\nإذا كنت ترغب في حجز رحلة، يرجى تحديد مدينة الانطلاق والوجهة."
            elif is_english_query:
                reply_text += "\n\nIf you would like to book a trip, please specify your departure and destination cities."
            else:
                reply_text += "\n\nSi vous souhaitez réserver un trajet, veuillez indiquer votre ville de départ et de destination."

        return AssistantResponseModel(
            reply=reply_text,
            recognized=list(recognized_fields),
            tripPatch=trip_patch if trip_patch else None
        )

    # ================================================================
    # CAS B : DÉPART ET DESTINATION DÉFINIS — RECHERCHE STRICTE SQL
    # ================================================================
    if origin_name and dest_name:
        conn_dyn = None
        real_trips: List[Dict[str, Any]] = []
        disp_origin = display_city_name(origin_name, is_arabic_query)
        disp_dest = display_city_name(dest_name, is_arabic_query)
        travelers_str = format_travelers_str(travelers_val, lang=lang)
        policies_context = build_policies_context(config_texts)

        try:
            conn_dyn = get_db_connection()
            origin_stop = match_stop_in_db(origin_name, conn_dyn)
            dest_stop = match_stop_in_db(dest_name, conn_dyn)

            if origin_stop:
                trip_patch["origin"] = origin_stop
            if dest_stop:
                trip_patch["destination"] = dest_stop

            if origin_stop and dest_stop:
                origin_id = origin_stop["id"]
                dest_id = dest_stop["id"]

                # Construction de la requête SQL stricte
                sql, params, meta = build_dynamic_sql(precisions, origin_id, dest_id, query_focus, sort_by)
                print(f"[SQL-STRICT] params={params}")

                cur_dyn = conn_dyn.cursor()
                cur_dyn.execute(sql, tuple(params))
                sched_rows = cur_dyn.fetchall()

                # Tarifs réels
                cur_dyn.execute("""
                    SELECT sp.id, sp.route_id, m.value, c.name, c.symbol
                    FROM segment_prices sp
                    JOIN monies m ON m.priceable_type = 'segment_prices' AND m.priceable_id = sp.id
                    JOIN currencies c ON c.id = m.currency_id
                    WHERE sp.from = %s AND sp.to = %s AND m.value > 0
                    ORDER BY m.value ASC;
                """, (origin_id, dest_id))
                price_rows = cur_dyn.fetchall()
                default_price = 80.0
                default_currency = "DT"
                if price_rows:
                    tn_price = next((p for p in price_rows if 'DT' in str(p[4]) or 'تونسي' in str(p[3])), None)
                    if tn_price:
                        default_price = float(tn_price[2])
                        default_currency = tn_price[4] or "DT"
                    else:
                        default_price = float(price_rows[0][2])
                        default_currency = price_rows[0][4] or "DT"

                seen_schedules = set()
                for s_row in sched_rows:
                    route_id, route_name, international, o_order, d_order, sched_id, s_date, s_time = s_row
                    key = f"{route_id}-{s_date}-{s_time}"
                    if key in seen_schedules:
                        continue
                    seen_schedules.add(key)

                    cur_dyn.execute("""
                        SELECT rs.stop_id, s.name, s.address, rs."order"
                        FROM route_segments rs
                        JOIN stops s ON rs.stop_id = s.id
                        WHERE rs.route_id = %s AND rs."order" >= %s AND rs."order" <= %s
                        ORDER BY rs."order" ASC;
                    """, (route_id, o_order, d_order))
                    route_stops_rows = cur_dyn.fetchall()

                    dep_hour = s_time.hour if hasattr(s_time, 'hour') else 7
                    dep_min = s_time.minute if hasattr(s_time, 'minute') else 0
                    dep_total_mins = dep_hour * 60 + dep_min

                    stops_list = []
                    num_stops = len(route_stops_rows)
                    total_duration_hours = max(4, num_stops * 1.5)

                    for idx, stop_row in enumerate(route_stops_rows):
                        st_id, st_name, st_addr, st_order = stop_row
                        progress = idx / max(1, num_stops - 1)
                        st_time_mins = int(dep_total_mins + progress * (total_duration_hours * 60))
                        st_h = (st_time_mins // 60) % 24
                        st_m = st_time_mins % 60
                        if idx == 0:
                            kind = "origin"
                        elif idx == num_stops - 1:
                            kind = "destination"
                        elif "جدير" in st_name or "ajdir" in st_name.lower():
                            kind = "border"
                        else:
                            kind = "stop"
                        stops_list.append({
                            "name": st_name,
                            "place": st_addr or f"Station de {st_name}",
                            "time": f"{st_h:02d}:{st_m:02d}",
                            "kind": kind,
                            "waitMinutes": 10 if kind == "stop" else (45 if kind == "border" else None)
                        })

                    arr_time = stops_list[-1]["time"] if stops_list else f"{(dep_hour + 6) % 24:02d}:{dep_min:02d}"
                    dur_hours = int(total_duration_hours)
                    dur_mins = int((total_duration_hours - dur_hours) * 60)
                    duration_label = f"{dur_hours}h{dur_mins:02d}" if dur_mins else f"{dur_hours}h00"
                    formatted_date = s_date.strftime("%Y-%m-%d") if hasattr(s_date, 'strftime') else (str(s_date)[:10] if s_date else date_val)

                    item: Dict[str, Any] = {
                        "id": f"trip-db-{route_id}-{sched_id}",
                        "date": formatted_date,
                        "departure": f"{dep_hour:02d}:{dep_min:02d}",
                        "arrival": arr_time,
                        "durationLabel": duration_label,
                        "mode": "bus",
                        "transfers": 0,
                        "price": default_price,
                        "currency": default_currency,
                        "operator": "Veyn Express" if international else "Rawahel",
                        "seatsLeft": random.randint(4, 18),
                        "stops": stops_list
                    }

                    # Filtre modes strict (multi-sélection OR)
                    if modes_val and item["mode"] not in modes_val:
                        continue

                    # Filtre budget strict
                    if effective_budget is not None and item["price"] > effective_budget:
                        continue

                    real_trips.append(item)

                cur_dyn.close()

                # Tri selon le focus / tri demandé
                if sort_by == "price_asc":
                    real_trips.sort(key=lambda x: x["price"])
                elif sort_by == "price_desc":
                    real_trips.sort(key=lambda x: x["price"], reverse=True)
                else:
                    real_trips.sort(key=lambda x: (x.get("date", ""), x.get("departure", "")))

                # Badge : meilleur tarif
                if real_trips:
                    cheapest_idx = min(range(len(real_trips)), key=lambda i: real_trips[i]["price"])
                    real_trips[cheapest_idx]["badge"] = "Meilleur tarif réel"

        except Exception as e:
            print(f"[ERREUR] Requête SQL dynamique : {repr(e)[:300]}")
        finally:
            if conn_dyn:
                release_db_connection(conn_dyn)

        # ============================================================
        # ÉTAPE 3 : RÉPONSE LLM CIBLÉE SELON LA COHÉRENCE STRICTE
        # ============================================================
        reply_text = ""
        if groq_client:
            try:
                focused_prompt = build_focused_response_prompt(
                    question=question,
                    nlu_data=nlu_result,
                    trips=real_trips,
                    policies_context=policies_context,
                    disp_origin=disp_origin,
                    disp_dest=disp_dest,
                    dates=dates,
                    travelers_str=travelers_str,
                    lang=lang
                )
                raw_reply = generate_llm_response(focused_prompt)
                reply_text = re.sub(r"\[Carte\s*\d*\]", "", raw_reply).strip()
            except Exception as e:
                print(f"[WARN] Groq focused response: {repr(e)[:200]}")

        # Fallback réponse textuelle si LLM indisponible
        if not reply_text:
            dates_ann = ", ".join(dates) if dates else ""
            if real_trips:
                if is_arabic_query:
                    reply_text = f"إليك الرحلات والمواعيد المتاحة بين {disp_origin} و{disp_dest}{f' ليوم/أيام {dates_ann}' if dates_ann else ''} :"
                elif is_english_query:
                    reply_text = f"Here are the available trips between {disp_origin} and {disp_dest}{f' on {dates_ann}' if dates_ann else ''}:"
                else:
                    reply_text = f"Voici les départs disponibles entre {disp_origin} et {disp_dest}{f' le {dates_ann}' if dates_ann else ''} :"
            else:
                if is_arabic_query:
                    reply_text = f"عذرًا، لا توجد رحلات متاحة مطابقة لمعاييرك المحددة بين {disp_origin} و{disp_dest}{f' في {dates_ann}' if dates_ann else ''}. يرجى اختيار تاريخ آخر."
                elif is_english_query:
                    reply_text = f"Sorry, no trips match your exact criteria between {disp_origin} and {disp_dest}{f' on {dates_ann}' if dates_ann else ''}. Please adjust your dates."
                else:
                    reply_text = f"Aucun trajet direct ne correspond à vos critères entre {disp_origin} et {disp_dest}{f' le {dates_ann}' if dates_ann else ''}. Vous pouvez choisir une autre date."

        return AssistantResponseModel(
            reply=reply_text,
            results=[TripResultModel(**t) for t in real_trips] if real_trips else None,
            noResults=True if not real_trips else None,
            recognized=list(recognized_fields),
            tripPatch=trip_patch if trip_patch else None
        )

    # ================================================================
    # CAS C : VILLES MANQUANTES — demander la précision à l'utilisateur
    # ================================================================
    travelers_str = format_travelers_str(travelers_val, lang=lang)
    partial_info = []
    if origin_name:
        if is_arabic_query:
            partial_info.append(f"الانطلاق: {display_city_name(origin_name, True)}")
        elif is_english_query:
            partial_info.append(f"Departure: {display_city_name(origin_name, False)}")
        else:
            partial_info.append(f"Départ : {display_city_name(origin_name, False)}")
    if dest_name:
        if is_arabic_query:
            partial_info.append(f"الوجهة: {display_city_name(dest_name, True)}")
        elif is_english_query:
            partial_info.append(f"Destination: {display_city_name(dest_name, False)}")
        else:
            partial_info.append(f"Destination : {display_city_name(dest_name, False)}")
    if dates:
        dates_display = "، ".join(dates) if is_arabic_query else ", ".join(dates)
        if is_arabic_query:
            partial_info.append(f"التواريخ: {dates_display}")
        elif is_english_query:
            partial_info.append(f"Dates: {dates_display}")
        else:
            partial_info.append(f"Dates : {dates_display}")
    elif date_val:
        if is_arabic_query:
            partial_info.append(f"التاريخ: {date_val}")
        elif is_english_query:
            partial_info.append(f"Date: {date_val}")
        else:
            partial_info.append(f"Date : {date_val}")
    if period_val:
        if is_arabic_query:
            partial_info.append(f"الفترة: {period_val}")
        elif is_english_query:
            partial_info.append(f"Period: {period_val}")
        else:
            partial_info.append(f"Période : {period_val}")
    if travelers_val:
        if is_arabic_query:
            partial_info.append(f"المسافرون: {travelers_str}")
        elif is_english_query:
            partial_info.append(f"Travelers: {travelers_str}")
        else:
            partial_info.append(f"Voyageurs : {travelers_str}")

    sep = "، " if is_arabic_query else ", "
    partial_str = sep.join(partial_info) if partial_info else (
        "لم يتم تحديد معايير بعد" if is_arabic_query else
        ("No criteria defined yet" if is_english_query else "Aucun critère défini pour le moment")
    )

    if groq_client and question:
        try:
            if is_arabic_query:
                lang_consigne = "LANGUE STRICTEMENT OBLIGATOIRE : ARABE standard moderne (العربية الفصحى). Tu DOIS répondre EXCLUSIVEMENT en arabe."
            elif is_english_query:
                lang_consigne = "MANDATORY LANGUAGE: ENGLISH. You MUST respond EXCLUSIVELY in English."
            else:
                lang_consigne = "LANGUE STRICTEMENT OBLIGATOIRE : Français."

            prompt = (
                f"Tu es l'assistant de réservation Veyn. Tu dois répondre de façon TRÈS CONCISE (1 à 2 phrases maximum).\n"
                f"Demande du client : {question}\n"
                f"Critères déjà notés : {partial_str}\n\n"
                f"Consignes :\n"
                f"1. Corrige mentalement toute faute sans jamais la mentionner.\n"
                f"2. Réponds en 1 ou 2 phrases courtes maximum.\n"
                f"3. Invite cordialement à préciser la ville de départ ou de destination manquante.\n"
                f"4. {lang_consigne}"
            )
            llm_reply = generate_llm_response(prompt)
            if llm_reply:
                return AssistantResponseModel(
                    reply=llm_reply,
                    recognized=list(recognized_fields),
                    tripPatch=trip_patch if trip_patch else None
                )
        except Exception as e:
            print(f"[WARN] Groq conversationnel: {repr(e)[:200]}")

    if is_arabic_query:
        fallback_reply = f"مرحباً! لقد قمت بتسجيل معلوماتك ({partial_str}). من أي مدينة تود الانطلاق وإلى أي وجهة؟"
        quick_replies = [
            QuickReplyModel(label="طرابلس ← تونس", value="أريد الذهاب من طرابلس إلى تونس"),
            QuickReplyModel(label="تونس ← طرابلس", value="أريد الذهاب من تونس إلى طرابلس"),
            QuickReplyModel(label="مصراتة ← تونس", value="أريد الذهاب من مصراتة إلى تونس"),
        ]
    elif is_english_query:
        fallback_reply = f"Hello! I've noted your information ({partial_str}). Which city would you like to depart from and where are you heading?"
        quick_replies = [
            QuickReplyModel(label="Tripoli → Tunis", value="I want to go from Tripoli to Tunis"),
            QuickReplyModel(label="Tunis → Tripoli", value="I want to go from Tunis to Tripoli"),
            QuickReplyModel(label="Misrata → Tunis", value="I want to go from Misrata to Tunis"),
        ]
    else:
        fallback_reply = f"Bonjour ! J'ai bien noté ({partial_str}). De quelle ville souhaitez-vous partir et vers quelle destination ?"
        quick_replies = [
            QuickReplyModel(label="Tripoli → Tunis", value="Je veux aller de Tripoli à Tunis"),
            QuickReplyModel(label="Tunis → Tripoli", value="Je veux aller de Tunis à Tripoli"),
            QuickReplyModel(label="Misrata → Tunis", value="Je veux aller de Misrata à Tunis"),
        ]

    return AssistantResponseModel(
        reply=fallback_reply,
        quickReplies=quick_replies,
        recognized=list(recognized_fields),
        tripPatch=trip_patch if trip_patch else None
    )


# --- Endpoint GET /api/locations ---
@app.get("/api/locations")
async def get_locations():
    """Retourne la liste des arrêts réels enregistrés dans la table `stops`."""
    conn = None
    try:
        conn = get_db_connection()
        cur = conn.cursor()
        cur.execute("""
            SELECT DISTINCT s.id, s.name, s.code, s.address, s.latitude, s.longitude 
            FROM stops s
            JOIN route_segments rs ON rs.stop_id = s.id
            WHERE s.status = true OR s.status IS NULL 
            ORDER BY s.id ASC;
        """)
        rows = cur.fetchall()
        cur.close()
        stops = [
            {
                "id": str(r[0]),
                "name": r[1],
                "code": r[2],
                "address": r[3],
                "lat": r[4],
                "lng": r[5],
                "country": get_stop_country(r[1], r[3])
            }
            for r in rows
        ]
        return {"count": len(stops), "stops": stops}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        if conn:
            release_db_connection(conn)

# --- Endpoint POST /api/book ---
@app.post("/api/book")
async def create_booking(booking: BookingRequestModel):
    """Enregistre ou confirme une réservation."""
    return {
        "status": "confirmed",
        "reference": booking.reference,
        "message": f"Réservation {booking.reference} confirmée avec succès.",
        "booking": booking.dict()
    }

# --- Endpoint Legacy POST /ask pour compatibilité ---
@app.post("/ask", response_model=AskResponse)
async def ask_question(request: AskRequest):
    if groq_client:
        try:
            answer = generate_llm_response(request.question)
            return AskResponse(question=request.question, answer=answer or "Service en ligne.", source="groq")
        except Exception as e:
            return AskResponse(question=request.question, answer=f"Erreur : {str(e)}", source="agent")
    return AskResponse(question=request.question, answer="Service en ligne.", source="system")


# --- Endpoint POST /api/transcribe (Groq Whisper-large-v3-turbo / v3) ---
@app.post("/api/transcribe")
async def transcribe_audio(
    file: UploadFile = File(...),
    language: Optional[str] = None
):
    """Transcrit un message vocal audio avec Groq Whisper (turbo avec fallback large-v3)."""
    if not groq_client:
        raise HTTPException(status_code=500, detail="Client Groq non initialisé.")
    try:
        content = await file.read()
        if not content or len(content) < 50:
            return {"text": "", "status": "empty"}

        filename = file.filename or "audio.wav"
        if "." not in filename:
            filename = f"{filename}.wav"

        ext = filename.split(".")[-1].lower()
        mime_map = {
            "wav": "audio/wav",
            "mp3": "audio/mpeg",
            "m4a": "audio/m4a",
            "mp4": "audio/mp4",
            "ogg": "audio/ogg",
            "webm": "audio/webm",
            "aac": "audio/aac",
            "flac": "audio/flac",
        }
        content_type = file.content_type or mime_map.get(ext, "audio/wav")

        whisper_models = ["whisper-large-v3-turbo", "whisper-large-v3"]
        transcription_text = None
        last_error = None

        whisper_kwargs = {
            "file": (filename, content, content_type),
            "temperature": 0.0,
            "response_format": "json",
        }
        if language and language.strip().lower() in ["fr", "ar", "en"]:
            whisper_kwargs["language"] = language.strip().lower()

        for model_name in whisper_models:
            try:
                whisper_kwargs["model"] = model_name
                resp = groq_client.audio.transcriptions.create(**whisper_kwargs)
                text = getattr(resp, "text", None)
                if text is None and isinstance(resp, dict):
                    text = resp.get("text", "")
                elif text is None:
                    text = str(resp)
                transcription_text = text
                break
            except Exception as e:
                last_error = e
                print(f"[WARN] Échec Groq Whisper ({model_name}): {e}")
                continue

        if transcription_text is None and last_error:
            raise last_error

        clean_text = (transcription_text or "").strip()

        # Filtrage des artefacts Whisper sur du silence / bruit résiduel
        noise_artifacts = {
            ".", "..", "...", "!", "?", "Merci.", "Merci", "Thank you.", "Thank you",
            "You", "Subtitles by", "[silence]", "[musique]", "[Musique]", "[music]", "[Music]"
        }
        if clean_text in noise_artifacts or re.fullmatch(r"^[.\s?!,;:\-_–—]+$", clean_text):
            clean_text = ""

        return {
            "text": clean_text,
            "status": "success"
        }
    except Exception as e:
        print(f"[ERROR] Transcription audio Groq Whisper : {e}")
        raise HTTPException(status_code=500, detail=str(e))

