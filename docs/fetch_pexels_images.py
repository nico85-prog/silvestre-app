"""
Una tantum: cerca immagini Pexels per ogni categoria + prodotto del catalogo
e salva URL + attribuzione fotografo su Firestore (collection: catalog_images).

L'app Flutter legge da catalog_images per mostrare le foto invece dei placeholder.
"""

import io
import json
import os
import sys
import urllib.parse
import urllib.request
from datetime import datetime, timezone

# Force UTF-8 stdout on Windows
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")

PROJECT_ID = "silvestre-fotoservizi"
REFRESH_TOKEN = os.environ.get("FIREBASE_REFRESH_TOKEN")
OAUTH_CLIENT_ID = "563584335869-fgrhgmd47bqnekij5i8b5pr03ho849e6.apps.googleusercontent.com"
OAUTH_CLIENT_SECRET = os.environ.get(
    "FIREBASE_CLI_CLIENT_SECRET", "j9iVZfS8kkCEFUPaAeJV0sAi")
PEXELS_KEY = os.environ.get("PEXELS_API_KEY")

if not REFRESH_TOKEN:
    raise SystemExit("ERRORE: imposta env var FIREBASE_REFRESH_TOKEN")
if not PEXELS_KEY:
    raise SystemExit("ERRORE: imposta env var PEXELS_API_KEY")


# Mapping: ogni (category_id O product_id) → query Pexels in inglese
# Strategia: query "abstract/mockup/minimal" per evitare foto di persone reali.
SEARCH_TERMS = {
    # Categorie
    "cat_stampa": "photo prints stack abstract background",
    "cat_fotolibro": "photo album wedding scrapbook",
    "cat_calendario": "wall calendar landscape",
    "cat_fotoquadro": "canvas wall art interior modern minimal",
    "cat_fotoregalo": "gift wrapped boxes ribbon abstract",
    "cat_crystal": "crystal glass paperweight light",

    # Prodotti stampa (no persone reali)
    "stampa_classica": "photo prints display arrangement table",
    "stampa_media": "framed photo print on wall mockup",
    "stampa_panoramica": "panoramic landscape print mountain",
    "plotter_grande": "large poster print wall mockup",

    # Fotolibri
    "fotolibro_15x20": "photo book album small",
    "fotolibro_20x20": "square photo album wedding",
    "fotolibro_20x30": "landscape photo book travel",

    # Calendari
    "calendario_annuale": "calendar wall hanging",
    "calendario_mensile": "monthly calendar landscape",
    "calendario_bimestrale": "calendar planner",

    # Fotoquadri (mockup minimal)
    "fotoquadro_canvas": "blank canvas frame interior mockup",
    "plotter_tela": "canvas roll print art studio",

    # Fotoregali (mockup/astratti)
    "magnete_grande": "fridge magnet photo stylized abstract",
    "magnete_piccolo": "small magnet refrigerator door",
    "tazza": "white mug coffee cup mockup minimal",
    "tshirt": "white tshirt blank mockup folded",
    "tshirt_tua": "tshirt printing press abstract",
    "cuscino": "white cushion pillow sofa minimal interior",
    "puzzle": "jigsaw puzzle pieces wood pattern",
    "cucina": "kitchen apron utensils still life",
    "casa": "minimal home office desk objects",
    "tessili": "folded blanket textile texture cozy",
    "borse": "tote bag canvas blank mockup",
    "pannello_muro": "wooden wall panel minimal interior",
    "pannello_appoggio": "small picture frame desk minimal",
    "varie": "wrapped gift boxes ribbon assortment",

    # Crystal 3D
    "crystal_parallel": "crystal glass engraving 3d laser",
    "crystal_cuore": "heart crystal love gift",
    "crystal_cubo": "crystal cube glass paperweight",
    "crystal_basi": "led light base illumination",
}

# Target filter: env var TARGET può ridurre le entries da aggiornare
TARGET = os.environ.get("TARGET", "all").strip()
if TARGET == "stampa_fotoquadro_fotoregalo":
    PREFIXES = ("cat_stampa", "stampa_", "plotter_grande",
                "cat_fotoquadro", "fotoquadro_", "plotter_tela",
                "cat_fotoregalo", "magnete_", "tazza", "tshirt", "tshirt_tua",
                "cuscino", "puzzle", "cucina", "casa", "tessili", "borse",
                "pannello_muro", "pannello_appoggio", "varie")
    SEARCH_TERMS = {k: v for k, v in SEARCH_TERMS.items() if k.startswith(PREFIXES)}


def get_access_token():
    body = urllib.parse.urlencode({
        "client_id": OAUTH_CLIENT_ID,
        "client_secret": OAUTH_CLIENT_SECRET,
        "refresh_token": REFRESH_TOKEN,
        "grant_type": "refresh_token",
    }).encode()
    req = urllib.request.Request("https://oauth2.googleapis.com/token",
                                  data=body, method="POST")
    req.add_header("Content-Type", "application/x-www-form-urlencoded")
    with urllib.request.urlopen(req) as r:
        return json.loads(r.read().decode())["access_token"]


def pexels_search(query, per_page=1):
    url = (
        "https://api.pexels.com/v1/search?"
        + urllib.parse.urlencode({
            "query": query,
            "per_page": per_page,
            "orientation": "landscape",
        })
    )
    req = urllib.request.Request(url, method="GET")
    req.add_header("Authorization", PEXELS_KEY)
    # Pexels blocca il User-Agent di Python di default
    req.add_header("User-Agent",
                   "Mozilla/5.0 (Silvestre Fotoservizi app/1.0)")
    req.add_header("Accept", "application/json")
    try:
        with urllib.request.urlopen(req) as r:
            return json.loads(r.read().decode())
    except urllib.error.HTTPError as e:
        return {"_http_error": e.code, "_body": e.read().decode(errors="ignore")}


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
    raise ValueError(f"unsupported: {type(v)}")


def fs_patch(token, path, data):
    url = (f"https://firestore.googleapis.com/v1/projects/{PROJECT_ID}"
           f"/databases/(default)/documents/{path}")
    body = {"fields": {k: fs_value(v) for k, v in data.items()}}
    req = urllib.request.Request(url, data=json.dumps(body).encode(),
                                  method="PATCH")
    req.add_header("Authorization", f"Bearer {token}")
    req.add_header("Content-Type", "application/json")
    try:
        with urllib.request.urlopen(req) as r:
            return r.status
    except urllib.error.HTTPError as e:
        return e.code


def main():
    print("=== Fetch access token ===")
    token = get_access_token()
    print("  OK")

    print(f"\n=== Fetching {len(SEARCH_TERMS)} entries from Pexels + writing Firestore ===")
    ok = 0
    fail = 0
    for key, query in SEARCH_TERMS.items():
        r = pexels_search(query)
        if "_http_error" in r:
            print(f"  {key}: Pexels error {r['_http_error']}")
            fail += 1
            continue
        photos = r.get("photos", [])
        if not photos:
            print(f"  {key}: no results for '{query}'")
            fail += 1
            continue
        p = photos[0]
        # Use 'large' (1880x1200) for hero, app handles resize via Pexels params
        url = p["src"]["large"]
        data = {
            "url": url,
            "thumbUrl": p["src"]["medium"],
            "photographer": p["photographer"],
            "photographerUrl": p["photographer_url"],
            "pexelsId": int(p["id"]),
            "pexelsPageUrl": p["url"],
            "alt": p.get("alt", "") or "",
            "fetchedAt": datetime.now(timezone.utc),
            "searchQuery": query,
        }
        status = fs_patch(token, f"catalog_images/{key}", data)
        if status in (200, 201):
            print(f"  {key}: OK - by {p['photographer']}")
            ok += 1
        else:
            print(f"  {key}: Firestore error {status}")
            fail += 1

    print(f"\n=== Done: {ok} OK, {fail} FAIL ===")


if __name__ == "__main__":
    main()
