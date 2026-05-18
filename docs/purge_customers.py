"""
purge_customers.py — cancella TUTTI gli utenti Firebase Auth + Firestore eccetto
admin e operatore di sistema.

Triggerare via GitHub Actions workflow `purge_customers.yml` che fornisce
FIREBASE_REFRESH_TOKEN come env var.

Account preservato:
  - operatore@silvestrefotoservizi.it
"""
import io
import json
import os
import sys
import urllib.parse
import urllib.request

# UTF-8 stdout per Windows runner (anche se in CI siamo su Linux)
try:
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")
except Exception:
    pass

PROJECT_ID = "silvestre-fotoservizi"
PRESERVE_EMAILS = {
    "operatore@silvestrefotoservizi.it",
}

REFRESH_TOKEN = os.environ.get("FIREBASE_REFRESH_TOKEN")
OAUTH_CLIENT_ID = "563584335869-fgrhgmd47bqnekij5i8b5pr03ho849e6.apps.googleusercontent.com"
OAUTH_CLIENT_SECRET = os.environ.get(
    "FIREBASE_CLI_CLIENT_SECRET", "j9iVZfS8kkCEFUPaAeJV0sAi")

if not REFRESH_TOKEN:
    raise SystemExit("ERRORE: imposta FIREBASE_REFRESH_TOKEN")


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
        return json.loads(r.read())["access_token"]


def list_all_users(token):
    """Pagina su tutti gli utenti Firebase Auth via accounts:query."""
    url = f"https://identitytoolkit.googleapis.com/v1/projects/{PROJECT_ID}/accounts:query"
    users = []
    next_token = None
    while True:
        body = {"limit": 500}
        if next_token:
            body["nextPageToken"] = next_token
        req = urllib.request.Request(url, data=json.dumps(body).encode(),
                                      method="POST")
        req.add_header("Content-Type", "application/json")
        req.add_header("Authorization", f"Bearer {token}")
        with urllib.request.urlopen(req) as r:
            d = json.loads(r.read())
        users.extend(d.get("userInfo", []))
        next_token = d.get("nextPageToken")
        if not next_token:
            break
    return users


def delete_auth_users(token, uids):
    """Batch delete (max 1000 per chiamata)."""
    if not uids:
        return 0
    url = f"https://identitytoolkit.googleapis.com/v1/projects/{PROJECT_ID}/accounts:batchDelete"
    deleted = 0
    for i in range(0, len(uids), 1000):
        chunk = uids[i:i + 1000]
        body = {"localIds": chunk, "force": True}
        req = urllib.request.Request(url, data=json.dumps(body).encode(),
                                      method="POST")
        req.add_header("Content-Type", "application/json")
        req.add_header("Authorization", f"Bearer {token}")
        with urllib.request.urlopen(req) as r:
            d = json.loads(r.read())
        errors = d.get("errors", [])
        deleted += len(chunk) - len(errors)
        for e in errors:
            print(f"    err uid={chunk[e.get('index', 0)]}: {e.get('message')}")
    return deleted


def delete_firestore_doc(token, path):
    url = (f"https://firestore.googleapis.com/v1/projects/{PROJECT_ID}"
           f"/databases/(default)/documents/{path}")
    req = urllib.request.Request(url, method="DELETE")
    req.add_header("Authorization", f"Bearer {token}")
    try:
        urllib.request.urlopen(req)
        return True
    except urllib.error.HTTPError as e:
        if e.code == 404:
            return True
        return False


def main():
    print("=== Refresh access token ===")
    token = get_access_token()
    print("  OK\n")

    print("=== Listing all Firebase Auth users ===")
    users = list_all_users(token)
    print(f"  Found: {len(users)}\n")

    to_delete = []
    preserved = []
    for u in users:
        email = (u.get("email") or "").lower()
        if email in PRESERVE_EMAILS:
            preserved.append(email)
        else:
            to_delete.append({"uid": u["localId"], "email": email})

    print(f"=== Preserved ({len(preserved)}) ===")
    for e in preserved:
        print(f"  KEEP {e}")
    print()

    print(f"=== To delete ({len(to_delete)}) ===")
    for x in to_delete:
        print(f"  DEL {x['email']} ({x['uid']})")
    print()

    if not to_delete:
        print("Nessun cliente da cancellare. Done.")
        return

    print("=== Deleting Firestore users/{uid} docs ===")
    fs_ok = 0
    for x in to_delete:
        if delete_firestore_doc(token, f"users/{x['uid']}"):
            fs_ok += 1
    print(f"  Firestore docs deleted: {fs_ok}/{len(to_delete)}\n")

    print("=== Batch deleting Auth users ===")
    auth_ok = delete_auth_users(token, [x["uid"] for x in to_delete])
    print(f"  Auth users deleted: {auth_ok}/{len(to_delete)}\n")

    print("=== DONE ===")


if __name__ == "__main__":
    main()
