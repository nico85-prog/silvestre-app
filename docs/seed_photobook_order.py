"""
Seed 1 ordine fotolibro REALE in Firestore con foto Cloudinary verificate.
Da eseguire DOPO test_cloudinary_upload.py (legge test_cloudinary_uploaded.json).
"""

import json
import os
import sys
import urllib.parse
import urllib.request
from datetime import datetime, timezone

PROJECT_ID = "silvestre-fotoservizi"
# Refresh token from `firebase login:ci` — load from env, never commit.
REFRESH_TOKEN = os.environ.get("FIREBASE_REFRESH_TOKEN")
OAUTH_CLIENT_ID = "563584335869-fgrhgmd47bqnekij5i8b5pr03ho849e6.apps.googleusercontent.com"
OAUTH_CLIENT_SECRET = os.environ.get(
    "FIREBASE_CLI_CLIENT_SECRET", "j9iVZfS8kkCEFUPaAeJV0sAi")
TARGET_USER_EMAIL = "nicolarosano85@gmail.com"
if not REFRESH_TOKEN:
    raise SystemExit("ERRORE: imposta env var FIREBASE_REFRESH_TOKEN")


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


def fs_value(v):
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


def fs_create_doc(token, collection, data):
    url = (
        f"https://firestore.googleapis.com/v1/projects/{PROJECT_ID}"
        f"/databases/(default)/documents/{collection}"
    )
    req = urllib.request.Request(
        url, data=json.dumps(fs_fields(data)).encode(), method="POST"
    )
    req.add_header("Authorization", f"Bearer {token}")
    req.add_header("Content-Type", "application/json")
    try:
        with urllib.request.urlopen(req) as resp:
            return json.loads(resp.read().decode())
    except urllib.error.HTTPError as e:
        return {"_http_error": e.code, "_body": e.read().decode(errors="ignore")}


def find_user_by_email(token, email):
    """Run Firestore structured query to find user with that email."""
    url = (
        f"https://firestore.googleapis.com/v1/projects/{PROJECT_ID}"
        f"/databases/(default)/documents:runQuery"
    )
    query = {
        "structuredQuery": {
            "from": [{"collectionId": "users"}],
            "where": {
                "fieldFilter": {
                    "field": {"fieldPath": "email"},
                    "op": "EQUAL",
                    "value": {"stringValue": email.lower()},
                }
            },
            "limit": 1,
        }
    }
    req = urllib.request.Request(
        url, data=json.dumps(query).encode(), method="POST"
    )
    req.add_header("Authorization", f"Bearer {token}")
    req.add_header("Content-Type", "application/json")
    with urllib.request.urlopen(req) as resp:
        results = json.loads(resp.read().decode())
        for r in results:
            if "document" in r:
                doc = r["document"]
                uid = doc["name"].split("/")[-1]
                return uid
    return None


def main():
    print("=== Seed photobook order with real Cloudinary photos ===\n")

    # Load uploaded photos from previous script
    photos_file = os.path.join(os.path.dirname(__file__), "test_cloudinary_uploaded.json")
    if not os.path.exists(photos_file):
        print("ERROR: test_cloudinary_uploaded.json non trovato. Esegui prima test_cloudinary_upload.py")
        sys.exit(1)
    with open(photos_file) as f:
        uploads = json.load(f)
    photo_urls = [u["url"] for u in uploads]
    print(f"Found {len(photo_urls)} uploaded photos")

    print("\nRefreshing access token...")
    token = get_access_token()

    print(f"Looking up user {TARGET_USER_EMAIL}...")
    uid = find_user_by_email(token, TARGET_USER_EMAIL)
    if not uid:
        print(f"ERRORE: user {TARGET_USER_EMAIL} non trovato")
        sys.exit(1)
    print(f"  uid={uid}")

    now = datetime.now(timezone.utc)

    # Compose a photobook order with auto-filled pages.
    # 3 photos in 5 pages = some pages have 1 photo, some empty.
    pages = [
        {"templateId": "1_full", "photoUrls": [photo_urls[0]]},
        {"templateId": "1_centered", "photoUrls": [photo_urls[1]]},
        {"templateId": "1_full", "photoUrls": [photo_urls[2]]},
        {"templateId": "1_centered", "photoUrls": [None]},
        {"templateId": "1_full", "photoUrls": [None]},
    ]

    order = {
        "userId": uid,
        "items": [
            {
                "id": "i1",
                "productId": "photobook_square_20",
                "variantId": "20x20_20p",
                "productName": "Fotolibro Quadrato",
                "variantName": "20x20 cm — 20 pagine",
                "quantity": 1,
                "unitPrice": 24.90,
                "designId": None,
                "photoUrls": photo_urls,
                "photobookPages": pages,
            }
        ],
        "status": "submitted",
        "pickupCode": "SLV-200001",
        "total": 24.90,
        "createdAt": now,
        "readyAt": None,
        "customerNote": "Fotolibro per matrimonio (TEST)",
        "customerName": "Test Customer Photobook",
        "customerPhone": "3331234567",
    }

    print("\nCreating order in Firestore...")
    r = fs_create_doc(token, "orders", order)
    if "_http_error" in r:
        print(f"ERROR: {r}")
        sys.exit(1)
    print(f"  OK: {r.get('name', '').split('/')[-1]}")

    print("\n=== Done ===")
    print(f"Codice: SLV-200001 — Fotolibro quadrato con {len(photo_urls)} foto reali Cloudinary")
    print(f"Logga come admin, vai in tab Ordini, cerca 'SLV-200001'")


if __name__ == "__main__":
    main()
