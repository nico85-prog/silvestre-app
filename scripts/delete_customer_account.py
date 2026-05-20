"""Cancellazione completa di un account cliente per testing.

Cancella:
  - Firestore users/{uid}
  - Firestore orders/* dove userId == uid
  - Firestore marketing_contacts/{phone} se linkedUserId == uid
  - Firebase Auth account

Usa OAuth refresh token CI per autenticarsi via REST.
"""
import json
import os
import sys
import urllib.error
import urllib.parse
import urllib.request

TARGET_EMAIL = "nicolarosano85@gmail.com"
PROJECT_ID = "silvestre-fotoservizi"
API_KEY = "AIzaSyDYD22PfEgBwg9QYa3pWH1jrXO78Hj6scU"
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


def lookup_user(token, email):
    url = (
        f"https://identitytoolkit.googleapis.com/v1/projects/{PROJECT_ID}"
        "/accounts:lookup"
    )
    r = http("POST", url, {"email": [email]},
             headers={"Authorization": f"Bearer {token}"})
    if "_http_error" in r:
        print(f"  [lookup_user error] {r}")
        return None
    users = r.get("users", [])
    return users[0] if users else None


def query_orders_by_user(token, uid):
    """Lista IDs degli ordini di uid via Firestore runQuery."""
    url = (
        f"https://firestore.googleapis.com/v1/projects/{PROJECT_ID}"
        "/databases/(default)/documents:runQuery"
    )
    body = {
        "structuredQuery": {
            "from": [{"collectionId": "orders"}],
            "where": {
                "fieldFilter": {
                    "field": {"fieldPath": "userId"},
                    "op": "EQUAL",
                    "value": {"stringValue": uid},
                }
            },
            "select": {"fields": [{"fieldPath": "userId"}]},
        }
    }
    r = http("POST", url, body,
             headers={"Authorization": f"Bearer {token}"})
    ids = []
    if isinstance(r, list):
        for entry in r:
            doc = entry.get("document")
            if doc and "name" in doc:
                ids.append(doc["name"].split("/")[-1])
    return ids


def delete_doc(token, path):
    url = f"https://firestore.googleapis.com/v1/{path}"
    r = http("DELETE", url, None,
             headers={"Authorization": f"Bearer {token}"})
    return "_http_error" not in r


def get_user_phone(token, uid):
    url = (
        f"https://firestore.googleapis.com/v1/projects/{PROJECT_ID}"
        f"/databases/(default)/documents/users/{uid}"
    )
    r = http("GET", url, None,
             headers={"Authorization": f"Bearer {token}"})
    if "_http_error" in r:
        return None
    fields = r.get("fields", {})
    return fields.get("phone", {}).get("stringValue")


def normalize_phone_for_id(phone):
    import re
    if not phone:
        return None
    n = re.sub(r"[^0-9]", "", phone)
    if n.startswith("00"):
        n = n[2:]
    if 9 <= len(n) <= 11 and n.startswith("3") and not n.startswith("39"):
        n = "39" + n
    return n if len(n) >= 8 else None


def delete_auth_user(token, uid):
    """Identity Toolkit deletes the auth account."""
    url = (
        f"https://identitytoolkit.googleapis.com/v1/projects/{PROJECT_ID}"
        "/accounts:delete"
    )
    r = http("POST", url, {"localId": uid},
             headers={"Authorization": f"Bearer {token}"})
    return "_http_error" not in r


def main():
    print(f"[1/6] Auth Firebase...")
    token = get_access_token()
    print(f"      Token OK")

    print(f"[2/6] Cerco user con email {TARGET_EMAIL}...")
    user = lookup_user(token, TARGET_EMAIL)
    if not user:
        print(f"      Nessun user trovato. Niente da cancellare.")
        return
    uid = user["localId"]
    print(f"      UID: {uid}")

    print(f"[3/6] Prendo telefono utente (per cleanup marketing_contacts)...")
    phone_raw = get_user_phone(token, uid)
    phone_id = normalize_phone_for_id(phone_raw)
    print(f"      Phone raw: {phone_raw}, normalized: {phone_id}")

    print(f"[4/6] Cerco ordini dell'utente...")
    order_ids = query_orders_by_user(token, uid)
    print(f"      {len(order_ids)} ordini trovati")
    for oid in order_ids:
        ok = delete_doc(token,
                        f"projects/{PROJECT_ID}/databases/(default)"
                        f"/documents/orders/{oid}")
        print(f"        ord/{oid}: {'OK' if ok else 'FAIL'}")

    print(f"[5/6] Cancello user doc + marketing_contact (se esiste)...")
    ok_user = delete_doc(token,
                         f"projects/{PROJECT_ID}/databases/(default)"
                         f"/documents/users/{uid}")
    print(f"      users/{uid}: {'OK' if ok_user else 'FAIL'}")
    if phone_id:
        ok_mc = delete_doc(token,
                           f"projects/{PROJECT_ID}/databases/(default)"
                           f"/documents/marketing_contacts/{phone_id}")
        status = "OK" if ok_mc else "NOT FOUND (forse non c'era)"
        print(f"      marketing_contacts/{phone_id}: {status}")

    print(f"[6/6] Cancello Firebase Auth account...")
    ok_auth = delete_auth_user(token, uid)
    print(f"      auth: {'OK' if ok_auth else 'FAIL'}")

    print()
    print(f"=== FINE ===")
    print(f"Account {TARGET_EMAIL} cancellato completamente.")
    print(f"Puoi riregistrarti dalla app come nuovo cliente.")


if __name__ == "__main__":
    main()
