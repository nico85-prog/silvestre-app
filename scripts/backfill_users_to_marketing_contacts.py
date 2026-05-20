"""Backfill one-shot: per ogni utente in users/, scrive/aggiorna il
record marketing_contacts/{phone} con email/nome/consenso.

Cosi' i clienti esistenti registrati PRIMA dell'auto-sync popolano
subito la lista marketing senza aspettare il prossimo login.

Idempotente via merge:true.
"""
import json
import os
import re
import sys
import urllib.error
import urllib.parse
import urllib.request
from datetime import datetime, timezone

PROJECT_ID = "silvestre-fotoservizi"
OAUTH_CLIENT_ID = (
    "563584335869-fgrhgmd47bqnekij5i8b5pr03ho849e6.apps.googleusercontent.com"
)
OAUTH_CLIENT_SECRET = "j9iVZfS8kkCEFUPaAeJV0sAi"
REFRESH_TOKEN = os.environ.get("FIREBASE_REFRESH_TOKEN")
if not REFRESH_TOKEN:
    raise SystemExit("ERRORE: serve FIREBASE_REFRESH_TOKEN env")


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


def normalize_phone(raw):
    if not raw:
        return None
    n = re.sub(r"[^0-9]", "", raw)
    if n.startswith("00"):
        n = n[2:]
    if 9 <= len(n) <= 11 and n.startswith("3") and not n.startswith("39"):
        n = "39" + n
    return n if len(n) >= 8 else None


def list_users(token):
    """Pagina tutti i documenti users/."""
    url = (
        f"https://firestore.googleapis.com/v1/projects/{PROJECT_ID}"
        f"/databases/(default)/documents/users?pageSize=300"
    )
    users = []
    page_token = None
    while True:
        u = url + (f"&pageToken={page_token}" if page_token else "")
        r = http("GET", u, None,
                 headers={"Authorization": f"Bearer {token}"})
        if "_http_error" in r:
            print(f"  [error] {r}")
            break
        for doc in r.get("documents", []):
            uid = doc["name"].split("/")[-1]
            fields = doc.get("fields", {})
            users.append({
                "uid": uid,
                "email": fields.get("email", {}).get("stringValue", ""),
                "displayName": fields.get("displayName", {}).get(
                    "stringValue", ""),
                "phone": fields.get("phone", {}).get("stringValue"),
                "role": fields.get("role", {}).get("stringValue", "customer"),
                "acceptedMarketing":
                    fields.get("acceptedMarketing", {}).get(
                        "booleanValue", False),
            })
        page_token = r.get("nextPageToken")
        if not page_token:
            break
    return users


def sync_marketing(token, user):
    """Scrive marketing_contacts/{phone} per l'utente."""
    if user["role"] != "customer":
        return "skip (operator/admin)"
    phone = normalize_phone(user["phone"])
    if not phone:
        return "skip (no phone)"
    status = "yes" if user["acceptedMarketing"] else "no"
    today = datetime.now(timezone.utc).strftime("%Y-%m-%d")
    url = (
        f"https://firestore.googleapis.com/v1/projects/{PROJECT_ID}"
        f"/databases/(default)/documents/marketing_contacts/{phone}"
        f"?updateMask.fieldPaths=name"
        f"&updateMask.fieldPaths=phone"
        f"&updateMask.fieldPaths=email"
        f"&updateMask.fieldPaths=optInStatus"
        f"&updateMask.fieldPaths=linkedUserId"
        f"&updateMask.fieldPaths=source"
    )
    body = {
        "fields": {
            "name": {"stringValue": user["displayName"] or "Cliente"},
            "phone": {"stringValue": f"+{phone}"},
            "email": {"stringValue": user["email"] or ""},
            "optInStatus": {"stringValue": status},
            "linkedUserId": {"stringValue": user["uid"]},
            "source": {"stringValue": f"backfill_app_{today}"},
        }
    }
    r = http("PATCH", url, body,
             headers={"Authorization": f"Bearer {token}"})
    if "_http_error" in r:
        return f"FAIL {r['_http_error']}"
    return "OK"


def main():
    print("[1/3] Auth Firebase...")
    token = get_access_token()
    print("      Token OK")

    print("[2/3] Lista users/...")
    users = list_users(token)
    print(f"      {len(users)} utenti trovati")

    print("[3/3] Sync marketing_contacts...")
    counts = {"OK": 0, "skip (operator/admin)": 0, "skip (no phone)": 0}
    for u in users:
        result = sync_marketing(token, u)
        counts[result] = counts.get(result, 0) + 1
        if result == "OK":
            print(f"  [OK] {u['email']} (uid {u['uid'][:8]}, phone "
                  f"{u['phone']})")
        elif result.startswith("FAIL"):
            print(f"  [X] {u['email']}: {result}")
    print()
    print(f"=== FINE ===")
    for k, v in counts.items():
        print(f"  {k}: {v}")


if __name__ == "__main__":
    main()
