"""Genera il cartello QR pronto da stampare per il bancone del negozio.

Output:
  - docs/qr_cartello_A5.png  (formato A5 per stampa diretta)
  - docs/qr_only.png         (solo QR puro, per riusi)

Il QR codifica https://silvestre-fotoservizi-it.web.app/?optin=marketing
Quando un cliente lo scansiona, l'app/PWA Silvestre si apre e attiva
automaticamente il consenso marketing (vedi task #43).
"""
from pathlib import Path
import qrcode
from PIL import Image, ImageDraw, ImageFont

# ===== CONFIG =====
APP_URL = "https://silvestre-fotoservizi-it.web.app/?optin=marketing"
DOCS_DIR = Path(__file__).resolve().parent.parent / "docs"
SHOP_NAME = "SILVESTRE FOTOSERVIZI"
ORANGE = (244, 117, 33)   # F47521
DARK = (40, 40, 40)
WHITE = (255, 255, 255)

# A5 a 300 DPI = 1748 x 2480 px (verticale)
A5_W, A5_H = 1748, 2480
QR_SIZE = 1000  # pixel del QR centrale


def _load_font(size: int, bold: bool = False) -> ImageFont.FreeTypeFont:
    """Prova font Windows comuni; fallback al default PIL."""
    candidates = [
        "C:/Windows/Fonts/seguibl.ttf" if bold else "C:/Windows/Fonts/segoeui.ttf",
        "C:/Windows/Fonts/arialbd.ttf" if bold else "C:/Windows/Fonts/arial.ttf",
    ]
    for p in candidates:
        try:
            return ImageFont.truetype(p, size)
        except OSError:
            continue
    return ImageFont.load_default()


def _centered_text(draw, text, font, y, w, color=DARK):
    bbox = draw.textbbox((0, 0), text, font=font)
    tw = bbox[2] - bbox[0]
    draw.text(((w - tw) // 2, y), text, font=font, fill=color)
    return bbox[3] - bbox[1]


def main():
    DOCS_DIR.mkdir(parents=True, exist_ok=True)

    # ===== QR puro =====
    qr = qrcode.QRCode(
        version=None,
        error_correction=qrcode.constants.ERROR_CORRECT_H,  # Alta correzione
        box_size=10,
        border=2,
    )
    qr.add_data(APP_URL)
    qr.make(fit=True)
    qr_img = qr.make_image(fill_color="black", back_color="white").convert("RGB")
    qr_only_path = DOCS_DIR / "qr_only.png"
    qr_img.save(qr_only_path, dpi=(300, 300))

    # ===== Cartello A5 =====
    cartello = Image.new("RGB", (A5_W, A5_H), WHITE)
    draw = ImageDraw.Draw(cartello)

    # Sfondo arancione in alto (header)
    draw.rectangle([0, 0, A5_W, 220], fill=ORANGE)

    # Header: nome negozio
    f_shop = _load_font(72, bold=True)
    _centered_text(draw, SHOP_NAME, f_shop, 70, A5_W, color=WHITE)

    # Titolo principale (sotto header)
    f_title = _load_font(96, bold=True)
    _centered_text(draw, "RICEVI", f_title, 290, A5_W, color=DARK)
    _centered_text(draw, "PROMOZIONI ESCLUSIVE", f_title, 410, A5_W, color=ORANGE)

    # Sottotitolo
    f_sub = _load_font(42)
    _centered_text(draw,
                   "Scansiona il QR con la fotocamera del tuo telefono",
                   f_sub, 570, A5_W, color=DARK)

    # QR centrale
    qr_resized = qr_img.resize((QR_SIZE, QR_SIZE), Image.LANCZOS)
    qr_x = (A5_W - QR_SIZE) // 2
    qr_y = 700
    # Bordo arancione attorno al QR
    border = 20
    draw.rectangle(
        [qr_x - border, qr_y - border,
         qr_x + QR_SIZE + border, qr_y + QR_SIZE + border],
        outline=ORANGE, width=8,
    )
    cartello.paste(qr_resized, (qr_x, qr_y))

    # Lista benefici sotto QR
    f_benefit = _load_font(38, bold=True)
    f_benefit_desc = _load_font(34)
    benefits_y = qr_y + QR_SIZE + 90

    benefits = [
        ("STAMPE A PREZZO RISERVATO",
         "Sconti fino al -40% solo per clienti app"),
        ("PROMO LAMPO",
         "Offerte esclusive in anteprima"),
        ("GESTISCI ORDINI DA CASA",
         "Carica foto, paga, ritira in negozio"),
    ]

    y = benefits_y
    bullet_r = 12  # radius del cerchio
    for title, desc in benefits:
        # Disegno bullet circolare arancione a sx del titolo
        bbox = draw.textbbox((0, 0), title, font=f_benefit)
        tw = bbox[2] - bbox[0]
        bullet_x = (A5_W - tw) // 2 - 40
        bullet_cy = y + (bbox[3] - bbox[1]) // 2 + 6
        draw.ellipse(
            [bullet_x - bullet_r, bullet_cy - bullet_r,
             bullet_x + bullet_r, bullet_cy + bullet_r],
            fill=ORANGE,
        )
        _centered_text(draw, title, f_benefit, y, A5_W, color=ORANGE)
        y += 50
        _centered_text(draw, desc, f_benefit_desc, y, A5_W, color=DARK)
        y += 70

    # Footer
    f_foot = _load_font(28)
    _centered_text(draw,
                   "Via Vittorio Emanuele III, 205 — Frattamaggiore (NA)",
                   f_foot, A5_H - 90, A5_W, color=DARK)
    _centered_text(draw,
                   "Tel: +39 335 169 7903",
                   f_foot, A5_H - 50, A5_W, color=DARK)

    cartello_path = DOCS_DIR / "qr_cartello_A5.png"
    cartello.save(cartello_path, dpi=(300, 300))

    print(f"[OK] QR codificato: {APP_URL}")
    print(f"     QR puro:     {qr_only_path}")
    print(f"     Cartello A5: {cartello_path}")
    print(f"     Dimensione:  {A5_W}x{A5_H}px @ 300dpi (A5 fisico)")


if __name__ == "__main__":
    main()
