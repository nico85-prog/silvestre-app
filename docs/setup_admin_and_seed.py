"""
Setup test admin + sample orders in Firestore via REST API.

Uses the Firebase OAuth refresh token (login:ci) to mint an access token,
then calls Identity Toolkit + Firestore REST endpoints.

Run from anywhere with Python 3.10+ (requests stdlib only — uses urllib).
"""

import json
import os
import sys
import urllib.parse
import urllib.request
from datetime import datetime, timezone, timedelta

# --- CONFIG ---
PROJECT_ID = "silvestre-fotoservizi"
API_KEY = "AIzaSyDYD22PfEgBwg9QYa3pWH1jrXO78Hj6scU"  # web API key, public
# Refresh token from `firebase login:ci` — DO NOT COMMIT.
# Export with:  set FIREBASE_REFRESH_TOKEN=...  (Windows CMD)
#               $env:FIREBASE_REFRESH_TOKEN="..." (PowerShell)
REFRESH_TOKEN = os.environ.get("FIREBASE_REFRESH_TOKEN")
OAUTH_CLIENT_ID = "563584335869-fgrhgmd47bqnekij5i8b5pr03ho849e6.apps.googleusercontent.com"
OAUTH_CLIENT_SECRET = os.environ.get(
    "FIREBASE_CLI_CLIENT_SECRET", "j9iVZfS8kkCEFUPaAeJV0sAi")
if not REFRESH_TOKEN:
    raise SystemExit(
        "ERRORE: imposta la variabile d'ambiente FIREBASE_REFRESH_TOKEN. "
        "Ottienila con: firebase.cmd login:ci")

TARGET_EMAIL = "nicolarosano85@gmail.com"
TEMP_PASSWORD = "AdminSilvestre2026!"  # tell user to change after login
DISPLAY_NAME = "Nicola Rosano"

# ---------- HTTP HELPERS ----------

def post_json(url, body, headers=None):
    data = json.dumps(body).encode("utf-8")
    req = urllib.request.Request(url, data=data, method="POST")
    req.add_header("Content-Type", "application/json")
    if headers:
        for k, v in headers.items():
            req.add_header(k, v)
    try:
        with urllib.request.urlopen(req) as resp:
            return json.loads(resp.read().decode("utf-8"))
    except urllib.error.HTTPError as e:
        raw = e.read().decode("utf-8", errors="ignore")
        return {"_http_error": e.code, "_body": raw}


def patch_json(url, body, headers=None):
    data = json.dumps(body).encode("utf-8")
    req = urllib.request.Request(url, data=data, method="PATCH")
    req.add_header("Content-Type", "application/json")
    if headers:
        for k, v in headers.items():
            req.add_header(k, v)
    try:
        with urllib.request.urlopen(req) as resp:
            return json.loads(resp.read().decode("utf-8"))
    except urllib.error.HTTPError as e:
        raw = e.read().decode("utf-8", errors="ignore")
        return {"_http_error": e.code, "_body": raw}


# ---------- AUTH ----------

def get_access_token():
    body = urllib.parse.urlencode({
        "client_id": OAUTH_CLIENT_ID,
        "client_secret": OAUTH_CLIENT_SECRET,
        "refresh_token": REFRESH_TOKEN,
        "grant_type": "refresh_token",
    }).encode("utf-8")
    req = urllib.request.Request("https://oauth2.googleapis.com/token",
                                  data=body, method="POST")
    req.add_header("Content-Type", "application/x-www-form-urlencoded")
    with urllib.request.urlopen(req) as resp:
        return json.loads(resp.read().decode("utf-8"))["access_token"]


def lookup_user_by_email(access_token, email):
    url = f"https://identitytoolkit.googleapis.com/v1/projects/{PROJECT_ID}/accounts:lookup"
    r = post_json(url, {"email": [email]},
                  headers={"Authorization": f"Bearer {access_token}"})
    if "_http_error" in r:
        return None
    users = r.get("users", [])
    return users[0] if users else None


def create_auth_user(email, password, display_name):
    url = f"https://identitytoolkit.googleapis.com/v1/accounts:signUp?key={API_KEY}"
    r = post_json(url, {
        "email": email,
        "password": password,
        "returnSecureToken": False,
    })
    if "_http_error" in r:
        return r
    # Set displayName
    if display_name and r.get("idToken"):
        post_json(
            f"https://identitytoolkit.googleapis.com/v1/accounts:update?key={API_KEY}",
            {"idToken": r["idToken"], "displayName": display_name, "returnSecureToken": False}
        )
    return r


# ---------- FIRESTORE ----------

def fs_value(v):
    """Convert Python value to Firestore REST 'Value' object."""
    if v is None:
        return {"nullValue": None}
    if isinstance(v, bool):
        return {"booleanValue": v}
    if isinstance(v, int):
        return {"integerValue": str(v)}
    if isinstance(v, float):
        return {"doubleValue": v}
    if isinstance(v, str):
        return {"stringValue": v}
    if isinstance(v, datetime):
        return {"timestampValue": v.astimezone(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")}
    if isinstance(v, list):
        return {"arrayValue": {"values": [fs_value(x) for x in v]}}
    if isinstance(v, dict):
        return {"mapValue": {"fields": {k: fs_value(val) for k, val in v.items()}}}
    raise ValueError(f"Unsupported type: {type(v)}")


def fs_fields(d):
    return {"fields": {k: fs_value(v) for k, v in d.items()}}


def fs_patch_doc(access_token, path, data):
    url = (
        f"https://firestore.googleapis.com/v1/projects/{PROJECT_ID}"
        f"/databases/(default)/documents/{path}"
    )
    return patch_json(url, fs_fields(data),
                       headers={"Authorization": f"Bearer {access_token}"})


def fs_create_doc(access_token, collection, data):
    url = (
        f"https://firestore.googleapis.com/v1/projects/{PROJECT_ID}"
        f"/databases/(default)/documents/{collection}"
    )
    return post_json(url, fs_fields(data),
                      headers={"Authorization": f"Bearer {access_token}"})


# ---------- MAIN ----------

def main():
    print("=== Refreshing access token ===")
    token = get_access_token()
    print("  OK")

    print(f"\n=== Looking up user {TARGET_EMAIL} ===")
    user = lookup_user_by_email(token, TARGET_EMAIL)
    if user:
        uid = user["localId"]
        print(f"  Found existing user: uid={uid}")
        print(f"  (Tieni la TUA password esistente — non la cambio.)")
    else:
        print(f"  Not found, creating with temp password '{TEMP_PASSWORD}'...")
        r = create_auth_user(TARGET_EMAIL, TEMP_PASSWORD, DISPLAY_NAME)
        if "_http_error" in r:
            print(f"  ERROR: {r}")
            sys.exit(1)
        uid = r["localId"]
        print(f"  Created user: uid={uid}")

    print(f"\n=== Setting users/{uid} role=admin ===")
    user_doc = {
        "email": TARGET_EMAIL,
        "displayName": DISPLAY_NAME,
        "phone": "+390818306365",
        "createdAt": datetime.now(timezone.utc).isoformat(),
        "role": "admin",
        "acceptedTos": True,
        "acceptedMarketing": False,
        "acceptedPortfolioUse": False,
    }
    r = fs_patch_doc(token, f"users/{uid}", user_doc)
    if "_http_error" in r:
        print(f"  ERROR: {r}")
        sys.exit(1)
    print("  OK")

    print("\n=== Seeding 5 sample orders ===")
    now = datetime.now(timezone.utc)
    samples = [
        {
            "userId": uid,  # ordini tuoi (cliente=tu, operatore=tu)
            "items": [
                {"id": "i1", "productId": "print_classic", "variantId": "10x15",
                 "productName": "Stampa classica", "variantName": "10x15 cm",
                 "quantity": 20, "unitPrice": 0.20, "designId": None,
                 "photoUrls": []},
            ],
            "status": "submitted",
            "pickupCode": "SLV-100001",
            "total": 4.00,
            "createdAt": now - timedelta(hours=1),
            "readyAt": None,
            "customerNote": "Carta lucida grazie",
            "customerName": "Maria Bianchi",
            "customerPhone": "3331234567",
        },
        {
            "userId": uid,
            "items": [
                {"id": "i1", "productId": "photobook_square_20",
                 "variantId": "20x20_20p", "productName": "Fotolibro Quadrato",
                 "variantName": "20x20 cm — 20 pagine", "quantity": 1,
                 "unitPrice": 24.90, "designId": None, "photoUrls": []},
            ],
            "status": "inProduction",
            "pickupCode": "SLV-100002",
            "total": 24.90,
            "createdAt": now - timedelta(hours=8),
            "readyAt": None,
            "customerNote": None,
            "customerName": "Giuseppe Romano",
            "customerPhone": "3387654321",
        },
        {
            "userId": uid,
            "items": [
                {"id": "i1", "productId": "calendar_wall",
                 "variantId": "A4_landscape", "productName": "Calendario da parete",
                 "variantName": "A4 orizzontale", "quantity": 2,
                 "unitPrice": 14.90, "designId": None, "photoUrls": []},
                {"id": "i2", "productId": "magnet_set",
                 "variantId": "9pcs", "productName": "Set magneti foto",
                 "variantName": "9 magneti 6x9 cm", "quantity": 1,
                 "unitPrice": 8.90, "designId": None, "photoUrls": []},
            ],
            "status": "readyForPickup",
            "pickupCode": "SLV-100003",
            "total": 38.70,
            "createdAt": now - timedelta(days=1),
            "readyAt": now - timedelta(hours=3),
            "customerNote": "Ritiro sabato mattina",
            "customerName": "Anna Esposito",
            "customerPhone": "3401122334",
        },
        {
            "userId": uid,
            "items": [
                {"id": "i1", "productId": "canvas_classic",
                 "variantId": "60x40", "productName": "Tela su telaio",
                 "variantName": "60x40 cm", "quantity": 1,
                 "unitPrice": 31.90, "designId": None, "photoUrls": []},
            ],
            "status": "pickedUp",
            "pickupCode": "SLV-100004",
            "total": 31.90,
            "createdAt": now - timedelta(days=3),
            "readyAt": now - timedelta(days=2),
            "customerNote": None,
            "customerName": "Luigi De Rosa",
            "customerPhone": "3491234567",
        },
        {
            "userId": uid,
            "items": [
                {"id": "i1", "productId": "print_classic", "variantId": "30x45",
                 "productName": "Stampa classica", "variantName": "30x45 cm",
                 "quantity": 5, "unitPrice": 5.00, "designId": None,
                 "photoUrls": []},
            ],
            "status": "inProduction",
            "pickupCode": "SLV-100005",
            # late: created 3 days ago, still in production
            "total": 25.00,
            "createdAt": now - timedelta(days=3),
            "readyAt": None,
            "customerNote": "URGENTE — regalo compleanno",
            "customerName": "Francesca Verdi",
            "customerPhone": "3471122334",
        },
    ]
    for i, s in enumerate(samples, 1):
        r = fs_create_doc(token, "orders", s)
        if "_http_error" in r:
            print(f"  Order {i}: ERROR {r}")
        else:
            print(f"  Order {i}: created ({s['pickupCode']}, {s['status']})")

    print("\n=== Done! ===")
    print(f"Email: {TARGET_EMAIL}")
    print(f"Role: admin")
    if user:
        print("Password: invariata (la tua di registrazione)")
    else:
        print(f"Password TEMP: {TEMP_PASSWORD}  ← CAMBIALA dopo il primo login!")
    print("\nAccedi a http://localhost:8080, logout se sei loggato, e fai login con")
    print("questa email. Atterri direttamente sull'app OPERATORE.")


if __name__ == "__main__":
    main()
