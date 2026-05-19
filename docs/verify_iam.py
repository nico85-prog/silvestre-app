"""verify_iam.py — controlla chi ha role=Owner sul progetto Firebase."""
import json
import os
import sys
import urllib.parse
import urllib.request

PROJECT_ID = "silvestre-fotoservizi"
REFRESH_TOKEN = os.environ.get("FIREBASE_REFRESH_TOKEN")
OAUTH_CLIENT_ID = "563584335869-fgrhgmd47bqnekij5i8b5pr03ho849e6.apps.googleusercontent.com"
OAUTH_CLIENT_SECRET = os.environ.get(
    "FIREBASE_CLI_CLIENT_SECRET", "j9iVZfS8kkCEFUPaAeJV0sAi")

if not REFRESH_TOKEN:
    raise SystemExit("ERRORE: FIREBASE_REFRESH_TOKEN non impostato")

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
    tok = json.loads(r.read())["access_token"]

url = f"https://cloudresourcemanager.googleapis.com/v1/projects/{PROJECT_ID}:getIamPolicy"
req = urllib.request.Request(url, data=b"{}", method="POST")
req.add_header("Authorization", f"Bearer {tok}")
req.add_header("Content-Type", "application/json")
try:
    with urllib.request.urlopen(req) as r:
        d = json.loads(r.read())
    print(f"=== IAM policy progetto {PROJECT_ID} ===\n")
    for b in d.get("bindings", []):
        role = b.get("role")
        members = b.get("members", [])
        print(f"Role: {role}")
        for m in members:
            print(f"  - {m}")
        print()
except urllib.error.HTTPError as e:
    print(f"FAIL: {e.code} {e.read().decode()[:400]}")
