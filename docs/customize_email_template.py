"""customize_email_template.py — personalizza il template email Firebase Auth
(senderDisplayName, subject, body) per ridurre lo spam score."""
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

# Get access token
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

# Read current config (so we can update template safely)
url = f"https://identitytoolkit.googleapis.com/admin/v2/projects/{PROJECT_ID}/config"
req = urllib.request.Request(url)
req.add_header("Authorization", f"Bearer {tok}")
try:
    with urllib.request.urlopen(req) as r:
        cfg = json.loads(r.read())
    print("Current config keys:", list(cfg.keys()))
    if "notification" in cfg:
        print("  notification.sendEmail keys:",
              list(cfg["notification"].get("sendEmail", {}).keys()))
except urllib.error.HTTPError as e:
    print(f"GET config FAIL: {e.code} {e.read().decode()[:400]}")
    raise SystemExit(1)

# Customize email template for VERIFY_EMAIL
new_template = {
    "subject": "Conferma la tua email — Silvestre Fotoservizi",
    "body": (
        "<p>Ciao %DISPLAY_NAME%,</p>"
        "<p>Grazie per esserti registrato su <b>Silvestre Fotoservizi</b>.</p>"
        "<p>Conferma la tua email cliccando il pulsante qui sotto:</p>"
        "<p style='text-align:center;margin:24px 0;'>"
        "<a href='%LINK%' style='background:#F47521;color:white;padding:12px 24px;"
        "text-decoration:none;border-radius:8px;font-weight:bold;'>Conferma email</a></p>"
        "<p>Se non hai creato un account, ignora questa email.</p>"
        "<p>Silvestre Fotoservizi · Frattamaggiore (NA) · dal 1970</p>"
    ),
    "bodyFormat": "HTML",
    "senderDisplayName": "Silvestre Fotoservizi",
    "replyTo": "fotosilvestre1970@gmail.com",
    "customized": True,
}

patch_body = {
    "notification": {
        "sendEmail": {
            "method": "DEFAULT",
            "verifyEmailTemplate": new_template,
            "resetPasswordTemplate": {
                "subject": "Reimposta la tua password — Silvestre Fotoservizi",
                "body": (
                    "<p>Ciao,</p>"
                    "<p>Hai richiesto di reimpostare la password del tuo account "
                    "<b>Silvestre Fotoservizi</b>.</p>"
                    "<p>Clicca sul pulsante qui sotto per scegliere una nuova password:</p>"
                    "<p style='text-align:center;margin:24px 0;'>"
                    "<a href='%LINK%' style='background:#F47521;color:white;"
                    "padding:12px 24px;text-decoration:none;border-radius:8px;"
                    "font-weight:bold;'>Reimposta password</a></p>"
                    "<p>Se non hai richiesto questo, ignora questa email.</p>"
                    "<p>Silvestre Fotoservizi · Frattamaggiore (NA) · dal 1970</p>"
                ),
                "bodyFormat": "HTML",
                "senderDisplayName": "Silvestre Fotoservizi",
                "replyTo": "fotosilvestre1970@gmail.com",
                "customized": True,
            },
        }
    }
}

mask = "notification.sendEmail.method,notification.sendEmail.verifyEmailTemplate,notification.sendEmail.resetPasswordTemplate"
url = (f"https://identitytoolkit.googleapis.com/admin/v2/projects/{PROJECT_ID}"
       f"/config?updateMask={mask}")
req = urllib.request.Request(url, data=json.dumps(patch_body).encode(),
                              method="PATCH")
req.add_header("Content-Type", "application/json")
req.add_header("Authorization", f"Bearer {tok}")
try:
    with urllib.request.urlopen(req) as r:
        print(f"\nPATCH config OK: {r.status}")
        d = json.loads(r.read())
        vt = d.get("notification", {}).get("sendEmail", {}).get(
            "verifyEmailTemplate", {})
        print(f"  Sender display: {vt.get('senderDisplayName','?')}")
        print(f"  Subject: {vt.get('subject','?')[:60]}")
        print(f"  Customized: {vt.get('customized','?')}")
except urllib.error.HTTPError as e:
    print(f"PATCH FAIL: {e.code} {e.read().decode()[:500]}")
    raise SystemExit(1)
