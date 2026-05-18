"""
Registra Android + iOS app in Firebase via Management API,
scarica google-services.json e GoogleService-Info.plist,
li salva nelle posizioni corrette del progetto Flutter.
"""

import base64
import json
import os
import sys
import time
import urllib.parse
import urllib.request

PROJECT_ID = "silvestre-fotoservizi"
PACKAGE_NAME = "com.silvestrefotoservizi.app"
# Refresh token from `firebase login:ci` — load from env, never commit.
REFRESH_TOKEN = os.environ.get("FIREBASE_REFRESH_TOKEN")
OAUTH_CLIENT_ID = "563584335869-fgrhgmd47bqnekij5i8b5pr03ho849e6.apps.googleusercontent.com"
OAUTH_CLIENT_SECRET = os.environ.get(
    "FIREBASE_CLI_CLIENT_SECRET", "j9iVZfS8kkCEFUPaAeJV0sAi")
if not REFRESH_TOKEN:
    raise SystemExit("ERRORE: imposta env var FIREBASE_REFRESH_TOKEN")

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ANDROID_OUT = os.path.join(ROOT, "app", "android", "app", "google-services.json")
IOS_OUT = os.path.join(ROOT, "app", "ios", "Runner", "GoogleService-Info.plist")


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


def api(token, method, url, body=None):
    data = json.dumps(body).encode() if body is not None else None
    req = urllib.request.Request(url, data=data, method=method)
    req.add_header("Authorization", f"Bearer {token}")
    if data is not None:
        req.add_header("Content-Type", "application/json")
    try:
        with urllib.request.urlopen(req) as r:
            return json.loads(r.read().decode())
    except urllib.error.HTTPError as e:
        return {"_http_error": e.code, "_body": e.read().decode(errors="ignore")}


def wait_for_operation(token, op_name):
    """Polls a long-running operation until done=true."""
    url = f"https://firebase.googleapis.com/v1beta1/{op_name}"
    for i in range(30):
        r = api(token, "GET", url)
        if "_http_error" in r:
            return r
        if r.get("done"):
            return r.get("response", r)
        time.sleep(2)
    return {"_timeout": True}


def find_or_create_android(token):
    print("\n=== ANDROID ===")
    # List existing
    list_url = (
        f"https://firebase.googleapis.com/v1beta1/projects/{PROJECT_ID}/androidApps"
    )
    existing = api(token, "GET", list_url)
    for app in existing.get("apps", []):
        if app.get("packageName") == PACKAGE_NAME:
            print(f"  Esiste già: appId={app['appId']}")
            return app["appId"]
    # Create
    print("  Creo nuova Android app ...")
    r = api(token, "POST", list_url, {
        "packageName": PACKAGE_NAME,
        "displayName": "Silvestre Android",
    })
    if "_http_error" in r:
        print(f"  ERRORE: {r}")
        sys.exit(1)
    op = wait_for_operation(token, r["name"])
    if "_http_error" in op or "_timeout" in op:
        print(f"  ERRORE: {op}")
        sys.exit(1)
    print(f"  Creata: appId={op['appId']}")
    return op["appId"]


def download_android_config(token, app_id):
    url = (f"https://firebase.googleapis.com/v1beta1/projects/{PROJECT_ID}"
           f"/androidApps/{app_id}/config")
    r = api(token, "GET", url)
    if "_http_error" in r:
        print(f"  ERRORE config: {r}")
        return False
    contents = base64.b64decode(r["configFileContents"]).decode("utf-8")
    os.makedirs(os.path.dirname(ANDROID_OUT), exist_ok=True)
    with open(ANDROID_OUT, "w", encoding="utf-8") as f:
        f.write(contents)
    print(f"  Salvato: {ANDROID_OUT}")
    return True


def find_or_create_ios(token):
    print("\n=== iOS ===")
    list_url = (
        f"https://firebase.googleapis.com/v1beta1/projects/{PROJECT_ID}/iosApps"
    )
    existing = api(token, "GET", list_url)
    for app in existing.get("apps", []):
        if app.get("bundleId") == PACKAGE_NAME:
            print(f"  Esiste già: appId={app['appId']}")
            return app["appId"]
    print("  Creo nuova iOS app ...")
    r = api(token, "POST", list_url, {
        "bundleId": PACKAGE_NAME,
        "displayName": "Silvestre iOS",
    })
    if "_http_error" in r:
        print(f"  ERRORE: {r}")
        sys.exit(1)
    op = wait_for_operation(token, r["name"])
    if "_http_error" in op or "_timeout" in op:
        print(f"  ERRORE: {op}")
        sys.exit(1)
    print(f"  Creata: appId={op['appId']}")
    return op["appId"]


def download_ios_config(token, app_id):
    url = (f"https://firebase.googleapis.com/v1beta1/projects/{PROJECT_ID}"
           f"/iosApps/{app_id}/config")
    r = api(token, "GET", url)
    if "_http_error" in r:
        print(f"  ERRORE config: {r}")
        return False
    contents = base64.b64decode(r["configFileContents"]).decode("utf-8")
    os.makedirs(os.path.dirname(IOS_OUT), exist_ok=True)
    with open(IOS_OUT, "w", encoding="utf-8") as f:
        f.write(contents)
    print(f"  Salvato: {IOS_OUT}")
    return True


def main():
    print("=== Refreshing access token ===")
    token = get_access_token()
    print("  OK")

    aid = find_or_create_android(token)
    download_android_config(token, aid)

    iid = find_or_create_ios(token)
    download_ios_config(token, iid)

    print("\n=== DONE ===")
    print(f"  Android: {ANDROID_OUT}")
    print(f"  iOS:     {IOS_OUT}")
    print("\nProssimo step: rigenerare firebase_options.dart con flutterfire configure")
    print("(facoltativo, le chiavi nei file scaricati funzionano già)")


if __name__ == "__main__":
    main()
