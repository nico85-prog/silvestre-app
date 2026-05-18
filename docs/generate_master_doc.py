"""
generate_master_doc.py — genera tutti i .docx separati (numerati) + i .pdf corrispondenti.

Workflow:
1. Rigenera ogni .docx invocando i singoli generate_*.py
2. Rinomina ogni file nello schema numerato 1_xxx.docx ... 5_xxx.docx
3. Converte ciascuno in .pdf via docx2pdf (richiede Word installato)

Output finale in docs/:
  1_Manuale_Generale_Silvestre.docx + .pdf
  2_Conformita_Legale.docx + .pdf
  3_Guida_Firebase.docx + .pdf
  4_Pubblicazione_App_Store.docx + .pdf
  5_Deploy_FCM_Cloud_Functions.docx + .pdf
"""
import os
import subprocess
import sys

from docx2pdf import convert

DOCS_DIR = os.path.dirname(os.path.abspath(__file__))

# Generator script -> (default output filename, target numbered filename)
PIPELINE = [
    ("generate_manuale_generale.py",
     "MANUALE_GENERALE_Silvestre.docx",
     "1_Manuale_Generale_Silvestre.docx"),
    ("generate_legal_doc.py",
     "Conformita_Legale_Silvestre.docx",
     "2_Conformita_Legale.docx"),
    ("generate_firebase_doc.py",
     "Guida_Firebase_Silvestre.docx",
     "3_Guida_Firebase.docx"),
    ("generate_launch_doc.py",
     "Pubblicazione_App_Silvestre.docx",
     "4_Pubblicazione_App_Store.docx"),
    ("generate_fcm_mobile_deploy_doc.py",
     "Deploy_FCM_Mobile_Functions.docx",
     "5_Deploy_FCM_Cloud_Functions.docx"),
]


def run_generator(script):
    path = os.path.join(DOCS_DIR, script)
    if not os.path.exists(path):
        print(f"  SKIP: {script} non trovato")
        return False
    r = subprocess.run([sys.executable, path], capture_output=True, text=True)
    if r.returncode != 0:
        print(f"  ERRORE {script}: {r.stderr[:300]}")
        return False
    return True


def cleanup_stale_files():
    """Rimuove vecchi file generati che non sono nel target schema corrente."""
    keep = {target for _, _, target in PIPELINE}
    keep |= {target.replace(".docx", ".pdf") for _, _, target in PIPELINE}
    for f in os.listdir(DOCS_DIR):
        if (f.endswith(".docx") or f.endswith(".pdf")) and f not in keep:
            full = os.path.join(DOCS_DIR, f)
            try:
                os.remove(full)
                print(f"  Pulito vecchio: {f}")
            except Exception as e:
                print(f"  Non posso rimuovere {f}: {e}")


def main():
    print("=== STEP 1: rigenero i .docx individuali ===")
    for script, _, _ in PIPELINE:
        print(f"  {script}...", end=" ")
        if run_generator(script):
            print("OK")

    print("\n=== STEP 2: rinomino nello schema numerato ===")
    for _, default_name, target_name in PIPELINE:
        src = os.path.join(DOCS_DIR, default_name)
        dst = os.path.join(DOCS_DIR, target_name)
        if os.path.exists(src):
            if os.path.exists(dst):
                os.remove(dst)
            os.rename(src, dst)
            print(f"  {default_name} -> {target_name}")

    print("\n=== STEP 3: pulizia file obsoleti ===")
    cleanup_stale_files()

    print("\n=== STEP 4: converto .docx -> .pdf (richiede Word installato) ===")
    for _, _, target_name in PIPELINE:
        docx_path = os.path.join(DOCS_DIR, target_name)
        if not os.path.exists(docx_path):
            print(f"  SKIP {target_name}: non esiste")
            continue
        try:
            convert(docx_path)
            pdf_path = docx_path.replace(".docx", ".pdf")
            size_kb = os.path.getsize(pdf_path) / 1024
            print(f"  {target_name} -> .pdf ({size_kb:.0f} KB)")
        except Exception as e:
            print(f"  ERRORE conversione {target_name}: {e}")

    print(f"\n=== DONE === File in {DOCS_DIR}")
    for f in sorted(os.listdir(DOCS_DIR)):
        if f.endswith((".docx", ".pdf")):
            full = os.path.join(DOCS_DIR, f)
            size_kb = os.path.getsize(full) / 1024
            print(f"  {f} ({size_kb:.0f} KB)")


if __name__ == "__main__":
    main()
