"""Import dei 6000+ contatti dal CSV nella collection Firestore
`marketing_contacts`.

Schema documento:
  {
    name: "Cliente X" o nome reale,
    phone: "+393351234567",            # normalizzato senza spazi
    email: "" o email valida,
    optInStatus: "pending",            # pending | yes | no
    optInSentAt: null,                 # timestamp invio soft opt-in
    optInRepliedAt: null,              # timestamp risposta SI/STOP
    source: "csv_import_2026-05-20",
    createdAt: timestamp ISO,
  }

Usa OAuth refresh token Firebase CLI per autenticarsi alla REST API
Firestore (stessa pattern di setup_admin_and_seed.py).

Esegui:
  $env:FIREBASE_REFRESH_TOKEN = "<token da firebase login:ci>"
  python scripts/import_marketing_contacts.py
"""
import json
import os
import re
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from datetime import datetime, timezone
from pathlib import Path

# --- CONFIG ---
PROJECT_ID = "silvestre-fotoservizi"
CSV_PATH = Path(__file__).resolve().parent.parent / "Contatti_Clienti.csv"
COLLECTION = "marketing_contacts"
SOURCE_TAG = f"csv_import_{datetime.now(timezone.utc).strftime('%Y-%m-%d')}"

OAUTH_CLIENT_ID = (
    "563584335869-fgrhgmd47bqnekij5i8b5pr03ho849e6.apps.googleusercontent.com"
)
OAUTH_CLIENT_SECRET = os.environ.get(
    "FIREBASE_CLI_CLIENT_SECRET", "j9iVZfS8kkCEFUPaAeJV0sAi"
)
REFRESH_TOKEN = os.environ.get("FIREBASE_REFRESH_TOKEN")
if not REFRESH_TOKEN:
    raise SystemExit(
        "ERRORE: imposta FIREBASE_REFRESH_TOKEN.\n"
        "Ottieni un refresh token con:  firebase.cmd login:ci"
    )

# --- AUTH ---

def get_access_token():
    body = urllib.parse.urlencode({
        "client_id": OAUTH_CLIENT_ID,
        "client_secret": OAUTH_CLIENT_SECRET,
        "refresh_token": REFRESH_TOKEN,
        "grant_type": "refresh_token",
    }).encode("utf-8")
    req = urllib.request.Request(
        "https://oauth2.googleapis.com/token", data=body, method="POST"
    )
    req.add_header("Content-Type", "application/x-www-form-urlencoded")
    with urllib.request.urlopen(req) as resp:
        return json.loads(resp.read().decode("utf-8"))["access_token"]


# --- PHONE NORMALIZATION (mirrora MessagingService.normalizePhoneForWhatsApp) ---

def normalize_phone(raw: str) -> str:
    s = (raw or "").strip()
    if not s:
        return ""
    digits = re.sub(r"[^0-9]", "", s)
    if digits.startswith("00"):
        digits = digits[2:]
    if 9 <= len(digits) <= 11 and digits.startswith("3") and not digits.startswith("39"):
        digits = "39" + digits
    if len(digits) < 8:
        return ""
    return "+" + digits


# --- CSV PARSE ---

def parse_csv():
    raw = CSV_PATH.read_bytes()
    if raw.startswith(b"\xef\xbb\xbf"):
        raw = raw[3:]
    text = raw.decode("utf-8")
    lines = text.split("\r\n")
    contacts = []
    for i, line in enumerate(lines):
        if i == 0 or not line:
            continue
        parts = line.split(";", 2)
        if len(parts) < 3:
            continue
        name = parts[0].strip()
        phone = normalize_phone(parts[1])
        email = parts[2].strip()
        if not phone:
            print(f"  [skip] riga {i}: phone non valido '{parts[1]}'")
            continue
        contacts.append({
            "name": name or "Cliente sconosciuto",
            "phone": phone,
            "email": email,
        })
    return contacts


# --- FIRESTORE WRITE (REST) ---

def write_doc(access_token: str, contact_id: str, data: dict):
    """PATCH crea o sostituisce il documento (idempotente)."""
    url = (
        f"https://firestore.googleapis.com/v1/projects/{PROJECT_ID}"
        f"/databases/(default)/documents/{COLLECTION}/{contact_id}"
    )
    # Firestore REST richiede campi tipizzati
    fields = {
        "name": {"stringValue": data["name"]},
        "phone": {"stringValue": data["phone"]},
        "email": {"stringValue": data["email"]},
        "optInStatus": {"stringValue": "pending"},
        "optInSentAt": {"nullValue": None},
        "optInRepliedAt": {"nullValue": None},
        "source": {"stringValue": SOURCE_TAG},
        "createdAt": {
            "timestampValue": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%S.000Z")
        },
    }
    body = {"fields": fields}
    req = urllib.request.Request(
        url, data=json.dumps(body).encode("utf-8"), method="PATCH"
    )
    req.add_header("Authorization", f"Bearer {access_token}")
    req.add_header("Content-Type", "application/json")
    try:
        with urllib.request.urlopen(req) as resp:
            resp.read()
            return True
    except urllib.error.HTTPError as e:
        print(f"  [error {e.code}] {contact_id}: {e.read().decode('utf-8', errors='ignore')[:200]}")
        return False


# --- MAIN ---

def doc_id_for(contact: dict) -> str:
    """Usa il numero normalizzato come document ID (deduplicazione naturale)."""
    return contact["phone"].replace("+", "")


def main():
    if not CSV_PATH.exists():
        raise SystemExit(f"CSV non trovato: {CSV_PATH}")

    print(f"[1/4] Lettura CSV: {CSV_PATH}")
    contacts = parse_csv()
    print(f"      {len(contacts)} contatti validi parseati")

    # Deduplicazione locale (in caso lo stesso telefono appaia 2 volte)
    seen = set()
    unique = []
    dupes = 0
    for c in contacts:
        key = c["phone"]
        if key in seen:
            dupes += 1
            continue
        seen.add(key)
        unique.append(c)
    print(f"      {len(unique)} unici dopo dedup (rimossi {dupes} duplicati)")

    print(f"[2/4] Auth Firebase ...")
    token = get_access_token()
    print(f"      Token OK")

    print(f"[3/4] Upload a Firestore collection '{COLLECTION}' ...")
    ok = 0
    fail = 0
    started = time.time()
    for i, c in enumerate(unique, 1):
        cid = doc_id_for(c)
        if write_doc(token, cid, c):
            ok += 1
        else:
            fail += 1
        if i % 100 == 0:
            elapsed = time.time() - started
            rate = i / elapsed if elapsed > 0 else 0
            eta = (len(unique) - i) / rate if rate > 0 else 0
            print(f"      {i}/{len(unique)}  ok={ok} fail={fail}  "
                  f"rate={rate:.1f}/s  ETA={eta:.0f}s")
        # Token OAuth scade dopo ~1h; rinnova ogni 50 minuti per sicurezza
        if i % 2500 == 0:
            print("      [refresh token]")
            token = get_access_token()

    print(f"[4/4] FINE. Ok={ok}  Fail={fail}  Totale processato={len(unique)}")
    print(f"      Tempo totale: {time.time() - started:.1f}s")


if __name__ == "__main__":
    main()
