"""Trova un contatto per nome in marketing_contacts e lo cancella.
Usage: python delete_test_contact.py NickPattern"""
import json
import os
import re
import sys
import urllib.error
import urllib.parse
import urllib.request

PROJECT_ID = "silvestre-fotoservizi"
OAUTH_CLIENT_ID = (
    "563584335869-fgrhgmd47bqnekij5i8b5pr03ho849e6.apps.googleusercontent.com"
)
OAUTH_CLIENT_SECRET = "j9iVZfS8kkCEFUPaAeJV0sAi"
REFRESH_TOKEN = os.environ.get("FIREBASE_REFRESH_TOKEN")
if not REFRESH_TOKEN:
    raise SystemExit("ERRORE: serve FIREBASE_REFRESH_TOKEN env")

pattern = (sys.argv[1] if len(sys.argv) > 1 else "Nick").lower()


def http(method, url, body=None, headers=None):
    data = None if body is None else json.dumps(body).encode("utf-8")
    req = urllib.request.Request(url, data=data, method=method)
    req.add_header("Content-Type", "application/json")
    if headers:
        for k, v in headers.items():
            req.add_header(k, v)
    try:
        with urllib.request.urlopen(req) as resp:
            txt = resp.read().decode("utf-8")
            return json.loads(txt) if txt else {}
    except urllib.error.HTTPError as e:
        raw = e.read().decode("utf-8", errors="ignore")
        return {"_http_error": e.code, "_body": raw}


def get_token():
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


def main():
    print(f"Cerco contatti con nome contenente '{pattern}'...")
    token = get_token()
    matches = []
    page_token = None
    pages = 0
    while True:
        url = (
            f"https://firestore.googleapis.com/v1/projects/{PROJECT_ID}"
            f"/databases/(default)/documents/marketing_contacts?pageSize=300"
        )
        if page_token:
            url += f"&pageToken={page_token}"
        r = http("GET", url, None,
                 headers={"Authorization": f"Bearer {token}"})
        if "_http_error" in r:
            print(f"  [error] {r}")
            break
        for doc in r.get("documents", []):
            fields = doc.get("fields", {})
            name = fields.get("name", {}).get("stringValue", "")
            phone = fields.get("phone", {}).get("stringValue", "")
            status = fields.get("optInStatus", {}).get("stringValue", "")
            if pattern in name.lower():
                matches.append({
                    "id": doc["name"].split("/")[-1],
                    "name": name, "phone": phone, "status": status,
                })
        page_token = r.get("nextPageToken")
        pages += 1
        if not page_token:
            break
        if pages > 50:
            print("  [warn] troppi pages, fermo")
            break

    if not matches:
        print(f"Nessun contatto trovato con nome contenente '{pattern}'.")
        return

    print(f"\nTrovati {len(matches)} contatti:")
    for m in matches:
        print(f"  - {m['name']} ({m['phone']}, {m['status']}) docId={m['id']}")

    print(f"\nCancello {len(matches)} contatti...")
    for m in matches:
        url = (
            f"https://firestore.googleapis.com/v1/projects/{PROJECT_ID}"
            f"/databases/(default)/documents/marketing_contacts/{m['id']}"
        )
        r = http("DELETE", url, None,
                 headers={"Authorization": f"Bearer {token}"})
        if "_http_error" in r:
            print(f"  [FAIL] {m['name']}: {r}")
        else:
            print(f"  [OK]   {m['name']} ({m['id']})")


if __name__ == "__main__":
    main()
