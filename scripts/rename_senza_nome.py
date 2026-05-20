"""Rinomina i contatti '(senza nome)' nel CSV con numerazione sequenziale.

Preserva: BOM UTF-8, separatore ';', terminatori CRLF.
"""
from pathlib import Path

CSV_PATH = Path(__file__).resolve().parent.parent / "Contatti_Clienti.csv"

def main():
    raw = CSV_PATH.read_bytes()
    # BOM UTF-8 in testa
    bom = b'\xef\xbb\xbf' if raw.startswith(b'\xef\xbb\xbf') else b''
    text = raw[len(bom):].decode('utf-8')

    # Preserva CRLF
    lines = text.split('\r\n')
    out_lines = []
    counter = 0
    renamed = 0

    for i, line in enumerate(lines):
        if i == 0:
            # Header
            out_lines.append(line)
            continue
        if not line:
            out_lines.append(line)
            continue
        parts = line.split(';', 2)
        if len(parts) < 3:
            out_lines.append(line)
            continue
        nome, tel, email = parts[0], parts[1], parts[2]
        if nome.strip() == '(senza nome)':
            counter += 1
            new_name = f'Cliente senza nome {counter}'
            out_lines.append(f'{new_name};{tel};{email}')
            renamed += 1
            print(f'  riga {i}: "{nome}" -> "{new_name}" (tel {tel})')
        else:
            out_lines.append(line)

    new_text = '\r\n'.join(out_lines)
    CSV_PATH.write_bytes(bom + new_text.encode('utf-8'))
    print(f'\n[OK] Rinominati {renamed} contatti. CSV salvato: {CSV_PATH}')


if __name__ == '__main__':
    main()
