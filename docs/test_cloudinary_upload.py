"""
Test che il preset Cloudinary 'silvestre_uploads' funzioni davvero:
- genera una PNG 600x400 in memoria
- POST multipart/form-data al endpoint unsigned upload
- verifica risposta + URL accessibile
"""

import io
import json
import sys
import urllib.request
import urllib.parse
import uuid
from PIL import Image, ImageDraw, ImageFont

CLOUD_NAME = "dcag1ztpq"
PRESET = "silvestre_uploads"
USER_ID = "smoketest_uid_001"

URL = f"https://api.cloudinary.com/v1_1/{CLOUD_NAME}/image/upload"


def make_test_image(text):
    img = Image.new("RGB", (600, 400), (244, 117, 33))  # Silvestre orange
    draw = ImageDraw.Draw(img)
    try:
        font = ImageFont.truetype("arial.ttf", 28)
    except OSError:
        font = ImageFont.load_default()
    draw.text((40, 180), text, fill="white", font=font)
    draw.text((40, 220), "Silvestre Fotoservizi", fill="white", font=font)
    buf = io.BytesIO()
    img.save(buf, format="PNG")
    return buf.getvalue()


def build_multipart(fields, files):
    boundary = uuid.uuid4().hex
    body = bytearray()
    for k, v in fields.items():
        body += f"--{boundary}\r\n".encode()
        body += f'Content-Disposition: form-data; name="{k}"\r\n\r\n'.encode()
        body += f"{v}\r\n".encode()
    for fk, (fname, fdata, ctype) in files.items():
        body += f"--{boundary}\r\n".encode()
        body += (
            f'Content-Disposition: form-data; name="{fk}"; filename="{fname}"\r\n'
        ).encode()
        body += f"Content-Type: {ctype}\r\n\r\n".encode()
        body += fdata + b"\r\n"
    body += f"--{boundary}--\r\n".encode()
    return bytes(body), f"multipart/form-data; boundary={boundary}"


def upload(name, image_bytes):
    body, content_type = build_multipart(
        fields={"upload_preset": PRESET, "folder": f"uploads/{USER_ID}"},
        files={"file": (name, image_bytes, "image/png")},
    )
    req = urllib.request.Request(URL, data=body, method="POST")
    req.add_header("Content-Type", content_type)
    try:
        with urllib.request.urlopen(req) as resp:
            return json.loads(resp.read().decode("utf-8"))
    except urllib.error.HTTPError as e:
        return {"_http_error": e.code, "_body": e.read().decode("utf-8", errors="ignore")}


def verify_url(url):
    req = urllib.request.Request(url, method="HEAD")
    try:
        with urllib.request.urlopen(req) as resp:
            return {
                "status": resp.status,
                "content_type": resp.headers.get("Content-Type"),
                "content_length": resp.headers.get("Content-Length"),
            }
    except urllib.error.HTTPError as e:
        return {"status": e.code}


def main():
    print("=== Cloudinary upload smoke test ===")
    print(f"Cloud: {CLOUD_NAME}  Preset: {PRESET}")
    print()

    results = []
    for i in range(3):
        name = f"smoke_{i}_{uuid.uuid4().hex[:8]}.png"
        print(f"-> Generating + uploading {name} ...")
        img = make_test_image(f"Test #{i + 1}")
        r = upload(name, img)
        if "_http_error" in r:
            print(f"   FAILED: HTTP {r['_http_error']}")
            print(f"   Body: {r['_body'][:200]}")
            sys.exit(1)
        url = r.get("secure_url")
        public_id = r.get("public_id")
        print(f"   OK -> public_id={public_id}")
        print(f"        url={url}")
        v = verify_url(url)
        print(f"        verify HEAD: {v}")
        results.append({"name": name, "url": url, "public_id": public_id})

    print()
    print("=== ALL 3 uploads passed ===")
    print()
    print("URLs (incolla in browser per vedere):")
    for r in results:
        print(f"  - {r['url']}")
    print()

    # Save URLs to a small JSON file so the next script can use them
    with open("test_cloudinary_uploaded.json", "w") as f:
        json.dump(results, f, indent=2)
    print("URLs salvate in: docs/test_cloudinary_uploaded.json")


if __name__ == "__main__":
    main()
