"""Genera Promozioni.docx con il piano completo per la feature Promozioni."""
from docx import Document
from docx.shared import Pt, RGBColor, Cm
from docx.enum.text import WD_ALIGN_PARAGRAPH
from pathlib import Path


def add_heading(doc, text, level=1):
    h = doc.add_heading(text, level=level)
    for run in h.runs:
        run.font.color.rgb = RGBColor(0xF4, 0x75, 0x21)  # Silvestre orange
    return h


def add_para(doc, text, bold=False, italic=False, size=11):
    p = doc.add_paragraph()
    run = p.add_run(text)
    run.font.size = Pt(size)
    run.bold = bold
    run.italic = italic
    return p


def add_bullet(doc, text, level=0):
    p = doc.add_paragraph(text, style="List Bullet")
    p.paragraph_format.left_indent = Cm(0.6 + level * 0.6)
    return p


def add_table(doc, headers, rows):
    t = doc.add_table(rows=1 + len(rows), cols=len(headers))
    t.style = "Light Grid Accent 1"
    hdr = t.rows[0].cells
    for i, h in enumerate(headers):
        hdr[i].text = h
        for p in hdr[i].paragraphs:
            for r in p.runs:
                r.bold = True
    for r_idx, row in enumerate(rows, start=1):
        for c_idx, cell in enumerate(row):
            t.rows[r_idx].cells[c_idx].text = cell
    return t


def add_callout(doc, title, body):
    p = doc.add_paragraph()
    r = p.add_run(f"▸ {title}\n")
    r.bold = True
    r.font.size = Pt(11)
    r.font.color.rgb = RGBColor(0xF4, 0x75, 0x21)
    r2 = p.add_run(body)
    r2.font.size = Pt(10)
    r2.italic = True
    return p


def main():
    doc = Document()

    # --- TITOLO ---
    title = doc.add_heading("Silvestre Fotoservizi — Piano Promozioni", level=0)
    for r in title.runs:
        r.font.color.rgb = RGBColor(0xF4, 0x75, 0x21)
    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    r = p.add_run("Dalla A alla Z: consenso cliente, contatti, canali di invio, "
                  "logica operativa, vincoli legali e tecnici.")
    r.italic = True
    r.font.size = Pt(11)
    r.font.color.rgb = RGBColor(0x60, 0x60, 0x60)

    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    r = p.add_run("Documento di pianificazione — versione 1.0 — 20 maggio 2026")
    r.italic = True
    r.font.size = Pt(9)
    r.font.color.rgb = RGBColor(0x99, 0x99, 0x99)

    doc.add_paragraph()

    # ============================================================
    # 1. PREMESSA
    # ============================================================
    add_heading(doc, "1. Premessa e obiettivo", level=1)
    add_para(doc,
             "Silvestre Fotoservizi possiede una base di 6000+ contatti clienti "
             "(file Contatti_Clienti.csv) raccolti negli anni dall'attività in "
             "negozio. L'obiettivo è poter inviare promozioni (sconti stagionali, "
             "offerte lampo, novità) a questa base in modo:")
    add_bullet(doc, "Legale (conforme al GDPR e al provvedimento del Garante "
                    "Privacy in materia di marketing diretto)")
    add_bullet(doc, "Economico (zero costi ricorrenti per il negozio)")
    add_bullet(doc, "Sostenibile nel tempo (l'operatore non deve diventare uno "
                    "schiavo della tastiera per inviare messaggi manualmente)")
    add_bullet(doc, "Tracciato (sapere chi ha ricevuto cosa, chi ha risposto "
                    "SI/STOP, chi è in blacklist)")

    # ============================================================
    # 2. IL PROBLEMA DEL CONSENSO (GDPR)
    # ============================================================
    add_heading(doc, "2. Il problema del consenso (GDPR)", level=1)
    add_para(doc, "2.1 — Cosa dice la legge", bold=True, size=12)
    add_para(doc,
             "Il GDPR (Regolamento UE 2016/679) e il Codice Privacy italiano "
             "richiedono per le comunicazioni promozionali via WhatsApp / email / "
             "SMS un consenso che sia:")
    add_bullet(doc, "Esplicito — il cliente deve aver attivamente spuntato una "
                    "casella «accetto di ricevere promozioni»")
    add_bullet(doc, "Specifico — il consenso al marketing è separato dal consenso "
                    "all'uso del servizio")
    add_bullet(doc, "Libero — non puoi rendere obbligatorio il marketing per "
                    "usare l'app (art. 7(4) GDPR: divieto di «consenso forzato»)")
    add_bullet(doc, "Documentato — devi poter dimostrare quando e come l'hai "
                    "ottenuto")
    add_bullet(doc, "Revocabile — il cliente può sempre disiscriversi (opt-out)")

    add_para(doc, "")
    add_para(doc, "2.2 — Lo stato attuale dei 6000+ contatti CSV", bold=True, size=12)
    add_para(doc,
             "I contatti nel CSV sono stati raccolti durante anni di attività in "
             "negozio. Hanno fornito il numero per ricevere conferme ordine, "
             "comunicazioni di servizio, ma NON hanno mai prestato un esplicito "
             "consenso a ricevere comunicazioni promozionali. Mandare loro una "
             "promo diretta è giuridicamente classificabile come spam, con "
             "sanzioni che possono arrivare a 20 milioni di euro o al 4% del "
             "fatturato annuo (art. 83 GDPR).")

    add_para(doc, "")
    add_para(doc, "2.3 — La soluzione adottata: doppio binario", bold=True, size=12)
    add_para(doc,
             "Per i futuri nuovi clienti che si registrano nell'app: checkbox "
             "marketing OPZIONALE, ben evidenziata graficamente per invogliare a "
             "selezionarla, ma non bloccante (l'app funziona uguale anche se la "
             "saltano). Default OFF, come richiede il GDPR.")
    add_para(doc,
             "Per i 6000+ contatti già esistenti nel CSV: campagna di soft "
             "opt-in. Una singola WhatsApp di richiesta consenso, chi risponde "
             "SI viene aggiunto alla lista marketing, gli altri vengono "
             "automaticamente segnati come non-opted-in dopo 30 giorni e "
             "rimossi dalla lista invii.")

    add_callout(doc, "Effetto pratico",
                "Nel giro di 2-3 mesi avremo una lista pulita di clienti opted-in "
                "(stima realistica: 1.500-2.500 contatti sui 6000+ iniziali). "
                "A quella lista possiamo mandare promozioni in totale "
                "tranquillità legale per anni.")

    add_para(doc, "")
    add_para(doc, "2.4 — Regola d'oro: la scelta esplicita vince sempre", bold=True, size=12)
    add_para(doc,
             "Il sistema applica automaticamente una regola fondamentale: se un "
             "cliente si registra nell'app e NON spunta la checkbox marketing, "
             "il suo eventuale stato 'pending' nel CSV viene immediatamente "
             "convertito in 'no' permanente. La sua scelta esplicita nell'app "
             "ha la priorità sullo stato CSV, e il soft opt-in non gli verrà "
             "mai inviato. Questo è dettagliato nella Tab 4 «Logica & GDPR» del "
             "pannello operatore.")

    # ============================================================
    # 3. IL MESSAGGIO DI SOFT OPT-IN
    # ============================================================
    add_heading(doc, "3. Campagna di soft opt-in iniziale", level=1)

    add_callout(doc, "PERIMETRO ESCLUSIVO",
                "La campagna di soft opt-in si applica UNICAMENTE ai contatti "
                "del CSV storico che NON hanno mai scaricato l'app Silvestre "
                "Fotoservizi. Chi è già registrato nell'app ha già espresso "
                "la propria scelta marketing (sì o no) durante la registrazione, "
                "quindi non riceve mai il messaggio di soft opt-in. Vedi "
                "sezione 5.2.2 «Le 4 categorie di cliente» per il dettaglio "
                "delle regole di dedup automatico.")

    add_para(doc, "")
    add_para(doc, "3.1 — Template del messaggio", bold=True, size=12)
    add_para(doc,
             "Il messaggio inviato una singola volta a ciascun contatto del "
             "CSV NON registrato in app:")
    p = doc.add_paragraph()
    r = p.add_run(
        "« Ciao {{nome}}, ti scriviamo da Silvestre Fotoservizi 📸. Hai usato i "
        "nostri servizi in passato e vorremmo restare in contatto via WhatsApp "
        "con sconti riservati e novità.\n\n"
        "Rispondi SI per iscriverti, oppure ignora questo messaggio per uscire "
        "dalla lista.\n\n"
        "In qualunque momento puoi disiscriverti rispondendo STOP. »"
    )
    r.italic = True
    r.font.size = Pt(10)
    r.font.color.rgb = RGBColor(0x40, 0x40, 0x40)

    add_para(doc, "")
    add_para(doc, "3.2 — Stati possibili di un contatto", bold=True, size=12)
    add_table(doc,
              headers=["Stato (optInStatus)", "Significato", "Riceve promo?"],
              rows=[
                  ["pending", "Messaggio opt-in non ancora inviato o appena inviato, attesa risposta", "NO"],
                  ["yes", "Ha risposto SI oppure si è registrato in app con consenso marketing attivo", "SÌ"],
                  ["no", "Ha risposto STOP, oppure 30 giorni senza risposta al soft opt-in", "NO (permanente)"],
              ])

    add_para(doc, "")
    add_para(doc, "3.3 — Come registriamo le risposte SI / STOP", bold=True, size=12)
    add_para(doc,
             "Il soft opt-in viene mandato via WhatsApp (vedi sezione 5.6.1 per "
             "il motivo tecnico per cui NON usiamo push o email per questa fase). "
             "Con WhatsApp manual batch non c'è modo di intercettare "
             "automaticamente le risposte — solo la Cloud API a pagamento lo "
             "permetterebbe. Quindi il flusso pratico è:")
    add_bullet(doc, "L'operatore legge le risposte ricevute su WhatsApp "
                    "Business (telefono o WhatsApp Web)")
    add_bullet(doc, "Apre l'app Silvestre operatore → Crea Promozione → Tab 1")
    add_bullet(doc, "Nella sezione «Inbox risposte soft opt-in» della Tab 1, "
                    "vede l'elenco dei 🟡 In attesa")
    add_bullet(doc, "Cerca per nome o numero il cliente che ha risposto su "
                    "WhatsApp")
    add_bullet(doc, "Tap sul bottone rapido «✅ SI ricevuto» (verde) → il sistema "
                    "aggiorna optInStatus=yes in Firestore")
    add_bullet(doc, "In alternativa, tap «❌ STOP ricevuto» (rosso) → "
                    "optInStatus=no permanente")

    add_para(doc, "")
    add_para(doc, "Tempo richiesto: ~2-3 secondi per cliente. Per un batch tipico "
                  "di 100 messaggi inviati arrivano 10-15 risposte SI nei primi "
                  "3-5 giorni. L'operatore dedica circa 30-45 secondi al giorno "
                  "durante la campagna soft opt-in. Sostenibile.", italic=True)

    add_para(doc, "")
    add_para(doc, "3.4 — Auto-cleanup dei pending senza risposta", bold=True, size=12)
    add_para(doc,
             "Una Cloud Function schedulata (cron job giornaliero) controlla "
             "tutti i contatti con optInStatus=pending. Se il messaggio soft "
             "opt-in è stato inviato più di 30 giorni fa (optInSentAt) e non "
             "c'è risposta, viene automaticamente segnato come optInStatus=no "
             "definitivo. L'operatore non deve farlo manualmente. Questo evita "
             "che la coda 'pending' cresca all'infinito e mantiene pulita la "
             "lista marketing.")

    # ============================================================
    # 4. ARCHITETTURA TECNICA
    # ============================================================
    add_heading(doc, "4. Architettura tecnica", level=1)
    add_para(doc, "4.1 — Storage dei contatti", bold=True, size=12)
    add_bullet(doc, "Collection Firestore marketing_contacts (contatti CSV "
                    "importati una tantum)")
    add_bullet(doc, "Collection Firestore users (clienti registrati nell'app, "
                    "con campo acceptedMarketing)")
    add_bullet(doc, "Firestore Security Rules: read solo se l'utente ha role "
                    "= admin/staff (cioè l'operatore). I clienti normali non "
                    "possono leggere nessuna lista, anche dall'APK scaricato")

    add_para(doc, "")
    add_para(doc, "4.2 — I 3 canali di invio promo (gratuiti)", bold=True, size=12)
    add_table(doc,
              headers=["Canale", "Stato attuale", "Costo", "Note"],
              rows=[
                  ["WhatsApp manual batch",
                   "ATTIVO",
                   "0 € sempre",
                   "Operatore preme «Apri WhatsApp» 1 volta per ogni "
                   "contatto. 50-100 invii/giorno per non triggerare "
                   "l'anti-spam"],
                  ["Push notification in-app (FCM)",
                   "STUB (richiede Blaze + Cloud Function)",
                   "0 € illimitato sotto Blaze",
                   "Bottone visibile nel form Nuova Promozione ma mostra "
                   "dialog 'configura Cloud Functions'. Sblocco con upgrade "
                   "Blaze + ~2h sviluppo"],
              ])

    add_callout(doc, "Perché WhatsApp e (in futuro) Push",
                "WhatsApp raggiunge tutti i 6000+ contatti della rubrica "
                "storica (telefono universale). Push notification (FCM) "
                "raggiungeranno solo gli utenti app — oggi pochi, in "
                "crescita nel tempo. Email rimosso perché poco usato dai "
                "clienti del negozio.")

    add_para(doc, "")
    add_para(doc, "4.3 — Perché NON usiamo WhatsApp Cloud API a pagamento", bold=True, size=12)
    add_para(doc,
             "La Cloud API ufficiale di Meta permetterebbe l'invio massivo "
             "automatico, ma costa circa 0,07 € per messaggio marketing in Italia. "
             "Per un singolo invio a 6000+ contatti si pagherebbero ~470 €, e "
             "richiederebbe l'approvazione preventiva di ogni template da parte "
             "di Meta (tempistica 1-3 giorni). Scelta esplicita del committente: "
             "rimanere su canali gratuiti, accettando il pace più lento.")

    # ============================================================
    # 5. IL PANNELLO «CREA PROMOZIONE»
    # ============================================================
    add_heading(doc, "5. Il pannello «Crea Promozione» nell'app operatore", level=1)
    add_para(doc, "5.1 — Struttura generale", bold=True, size=12)
    add_para(doc,
             "Nuova card nella dashboard operatore «Crea Promozione». "
             "Aprendola si arriva a una schermata con 6 tab in alto + un "
             "pulsante verde «NUOVA PROMOZIONE» in alto a destra. "
             "L'ordine delle tab è progettato per ricordare la compliance "
             "PRIMA che l'operatore inizi a creare promozioni:")
    add_bullet(doc, "Tab 1 — «Logica & GDPR» (documentazione + statistiche)")
    add_bullet(doc, "Tab 2 — «👥 Tutti (N)» — ACTION SURFACE: tutti i contatti "
                    "con bottoni di azione contestuali (OPT IN / SI / STOP / "
                    "reset / NO RESET)")
    add_bullet(doc, "Tab 3 — «🟢 Acconsentiti (N)» (read-only)")
    add_bullet(doc, "Tab 4 — «⚪ Nuovi (N)» (read-only)")
    add_bullet(doc, "Tab 5 — «🟡 In attesa (N)» (read-only)")
    add_bullet(doc, "Tab 6 — «🔴 Rifiutati (N)» (read-only)")
    add_para(doc,
             "I counter (N) tra parentesi si aggiornano in tempo reale.",
             italic=True)
    add_para(doc,
             "Pulsante «+ NUOVA PROMOZIONE» (verde, in alto a destra) "
             "apre un form dedicato per creare e lanciare una campagna "
             "promo standard a tutti i 🟢 Acconsentiti via WhatsApp manual "
             "batch.")


    add_para(doc, "")
    add_para(doc, "5.2 — Tab 1: Logica & Conformità GDPR (compliance first)",
             bold=True, size=12)
    add_para(doc,
             "PRIMA tab. Solo documentazione e statistiche live. Non contiene "
             "azioni (zero bottoni di invio). Serve a ricordare all'operatore "
             "le regole anti-spam del sistema PRIMA di andare nelle altre tab "
             "a interagire coi contatti.")
    add_para(doc, "")
    add_para(doc, "Contenuto:", bold=True, size=11)
    add_bullet(doc, "Statistiche live (totale, acconsentiti, nuovi, in attesa, "
                    "rifiutati) aggiornate in tempo reale")
    add_bullet(doc, "Tabella delle 4 categorie di cliente (A/B/C/D) e quale "
                    "riceve il soft opt-in")
    add_bullet(doc, "Regola d'oro: la scelta esplicita in app vince sempre "
                    "sullo stato CSV importato")
    add_bullet(doc, "Lista «Cosa NON deve mai succedere» (impedito by design)")
    add_bullet(doc, "Spiegazione auto-cleanup pending 30 giorni (futuro, "
                    "richiede Cloud Function / piano Blaze)")
    add_bullet(doc, "Box «Come si usa il pannello» che rimanda alla Tab Tutti "
                    "per le azioni concrete")

    add_para(doc, "")
    add_para(doc, "5.3 — Tab 2: 👥 Tutti (action surface principale)",
             bold=True, size=12)
    add_para(doc,
             "TAB PRINCIPALE di interazione. Mostra TUTTI i contatti gestiti "
             "ordinati alfabeticamente, con badge colorato dello stato "
             "(🟢🟡⚪🔴) e info contestuali (data invio, motivo rifiuto, "
             "tempo trascorso). A destra di ogni riga c'è un bottone di "
             "azione contestuale al suo stato:")
    add_table(doc,
              headers=["Stato cliente", "Bottone di azione", "Cosa fa"],
              rows=[
                  ["⚪ Nuovo",
                   "Bottone verde «OPT IN»",
                   "Apre WhatsApp col template fisso di richiesta consenso. "
                   "Il contatto passa a 🟡 In attesa (markOptInSent)."],
                  ["🟡 In attesa",
                   "✅ SI / ❌ STOP",
                   "Click SI → contatto passa a 🟢 Acconsentito. "
                   "Click STOP → dialog «STOP esplicito o NO generico?». "
                   "Il motivo determina se sarà resettabile."],
                  ["🟢 Acconsentito",
                   "(nessuno in produzione)",
                   "Read-only: il cliente è già nella lista marketing attiva."],
                  ["🔴 Rifiutato",
                   "🔄 reset oppure 🔒 «NO RESET»",
                   "Mostra reset se rejectionReason ammette riprova "
                   "(no_reply_30d, manual_operator). Mostra «NO RESET» "
                   "bloccato se il cliente ha detto STOP esplicito o "
                   "rifiutato in app (vincolo GDPR)."],
              ])
    add_para(doc, "")
    add_para(doc, "Componenti aggiuntivi:", bold=True, size=11)
    add_bullet(doc, "Banner spiegativo in cima")
    add_bullet(doc, "Barra di ricerca per nome / telefono / email")
    add_bullet(doc, "Counter «N contatti totali» live")
    add_bullet(doc, "Background row colorato in base allo stato")
    add_bullet(doc, "Badge sorgente: 📱 (app) o 📇 (rubrica)")

    add_para(doc, "")
    add_para(doc, "5.4 — Tab 3-6: 🟢 Acconsentiti / ⚪ Nuovi / 🟡 In attesa / "
                  "🔴 Rifiutati (read-only)",
             bold=True, size=12)
    add_para(doc,
             "Le 4 tab dedicate sono VISTE FILTRATE READ-ONLY della stessa "
             "base dati di Tab Tutti. Servono per audit/focus su una "
             "categoria specifica senza dover scrollare 6000+ contatti. "
             "Ogni tab ha:")
    add_bullet(doc, "Banner spiegativo: chi è in questa categoria, perché, "
                    "cosa può succedere dopo")
    add_bullet(doc, "Barra di ricerca")
    add_bullet(doc, "Counter live nel titolo tab (es. «🟢 Acconsentiti (1.847)»)")
    add_bullet(doc, "Lista contatti senza bottoni di azione (read-only)")
    add_para(doc, "")
    add_para(doc, "La Tab 🔴 Rifiutati mostra inoltre per ogni contatto:",
             italic=True)
    add_bullet(doc, "Data del rifiuto + tempo trascorso (es. «3 mesi fa»)")
    add_bullet(doc, "Motivo testuale (es. «Cliente ha scritto STOP esplicito», "
                    "«Cliente ha rifiutato il marketing in app», «Nessuna "
                    "risposta dopo 30 giorni»)")

    add_para(doc, "")
    add_para(doc, "5.5 — Pulsante «+ NUOVA PROMOZIONE» (form promo standard)",
             bold=True, size=12)
    add_para(doc,
             "Pulsante verde in alto a destra dell'AppBar, sempre visibile "
             "in tutte le tab. Apre uno schermo dedicato con il form di "
             "creazione campagna promo standard.")
    add_para(doc, "")
    add_para(doc, "Campi del form:", bold=True, size=11)
    add_bullet(doc, "Titolo promozione (testo breve)")
    add_bullet(doc, "Dettagli promozione (multilinea)")
    add_bullet(doc, "Costo / Sconto (es. «-30%», «da 10€», «gratis»)")
    add_bullet(doc, "Data validità DA / Data validità A (date picker)")
    add_bullet(doc, "Anteprima messaggio live (placeholder sostituiti)")
    add_bullet(doc, "Counter «Destinatari: N clienti acconsentiti»")
    add_para(doc, "")
    add_para(doc, "Bottone «INVIA VIA WHATSAPP» verde in basso. Disabilitato "
                  "finché tutti i campi non sono compilati. Al click parte "
                  "il dialog di conferma («SI INVIA» verde / «NO INDIETRO» "
                  "grigio). Se confermato, viene creata una Promotion document "
                  "in Firestore con channel='whatsapp', recipientIds = "
                  "snapshot di tutti i 🟢 Acconsentiti correnti, e si naviga "
                  "alla schermata WhatsAppBatchScreen.")

    add_para(doc, "")
    add_para(doc, "5.6 — Schermata WhatsAppBatchScreen (invio batch)",
             bold=True, size=12)
    add_para(doc,
             "Schermo dedicato dove l'operatore preme «Apri WhatsApp» per "
             "ogni destinatario in modo seriale. Funziona in 2 modi:")
    add_table(doc,
              headers=["Modalità", "Recipients", "Comportamento"],
              rows=[
                  ["Promo standard (channel='whatsapp')",
                   "Snapshot dei 🟢 Acconsentiti al momento della creazione",
                   "Lista mostra recipientIds - sentIds. Quando vuoto, "
                   "auto-completata."],
                  ["Soft opt-in (channel='soft_optin')",
                   "DINAMICO: tutti i ⚪ Nuovi correnti (re-query realtime)",
                   "Reset di un 🔴 a ⚪ rientra automaticamente nella coda. "
                   "Counter «Ancora da inviare» si aggiorna live."],
              ])
    add_para(doc, "")
    add_para(doc, "Per ogni contatto in lista:", bold=True, size=11)
    add_bullet(doc, "Click bottone verde «Apri WhatsApp»")
    add_bullet(doc, "MessagingService.sendWhatsApp apre WhatsApp con messaggio "
                    "precompilato")
    add_bullet(doc, "L'operatore preme Invia su WhatsApp")
    add_bullet(doc, "App automaticamente marca il contatto come inviato: "
                    "markOptInSent per soft_optin, markSent sulla promo per "
                    "promo standard")
    add_bullet(doc, "Il contatto sparisce dalla lista (per soft_optin diventa "
                    "🟡 In attesa; per promo standard è aggiunto a sentIds)")
    add_para(doc, "")
    add_para(doc, "Progress bar in cima mostra «inviati / ancora da inviare / "
                  "totale» con percentuale.")


    # ============================================================
    # 6. FLUSSO OPERATIVO TIPICO
    # ============================================================
    add_heading(doc, "6. Flusso operativo tipico (esempio reale)", level=1)
    add_para(doc, "Esempio: l'operatore vuole mandare la promo «Stampe in Tela "
                  "-30% dal 1 al 15 giugno».", italic=True)
    add_bullet(doc, "Apre l'app operatore → tap su card «Crea Promozione»")
    add_bullet(doc, "Atterra su Tab 1 «Logica & GDPR»: dà un'occhiata alle "
                    "statistiche live (es. 1.847 opted-in, 4.612 pending) e si "
                    "ricorda le regole prima di procedere")
    add_bullet(doc, "Tab 2: compila titolo «Stampe Tela -30%», dettagli, foto "
                    "di una stampa su tela, date 01/06 — 15/06, costo «-30%»")
    add_bullet(doc, "Vede l'anteprima del messaggio. Vuole controllare le liste.")
    add_bullet(doc, "Tab 3: vede i contatti opted-in (es. 1.847). Toglie la "
                    "checkbox a 3 clienti che lo hanno chiamato lamentandosi "
                    "delle troppe promo → vanno automaticamente in Tab 4.")
    add_bullet(doc, "Torna Tab 2. Vede contatore aggiornato: «1.844 contatti».")
    add_bullet(doc, "Clicca «Invia via Push» → arriva l'alert «Stai per inviare "
                    "a 1.844 contatti via Push» → conferma «SÌ, INVIA»")
    add_bullet(doc, "Le push partono istantaneamente a tutti i 1.844 utenti app "
                    "che hanno marketing attivo")
    add_bullet(doc, "Decide di inviare anche via WhatsApp: clicca «Invia "
                    "WhatsApp» → conferma → l'app apre WhatsApp con il primo "
                    "contatto precompilato. Operatore preme Invia su WhatsApp, "
                    "torna in app, parte automaticamente al secondo. Pace ~50 "
                    "invii in mezz'ora.")
    add_bullet(doc, "Il giorno dopo riprende il batch da dove si era fermato "
                    "(progresso salvato in Firestore). In 30-40 giorni copre i "
                    "1.844 contatti opted-in via WhatsApp.")

    # ============================================================
    # 7. SICUREZZA DEI DATI
    # ============================================================
    add_heading(doc, "7. Sicurezza e privacy operativa", level=1)
    add_bullet(doc, "I 6000+ contatti del CSV vengono importati una sola volta "
                    "in Firestore (collection marketing_contacts), poi il file "
                    "fisico .csv non viene mai più toccato")
    add_bullet(doc, "Firestore Security Rules: «allow read: if request.auth != "
                    "null && request.auth.token.role == 'admin'». Nessun cliente "
                    "normale può vedere la lista.")
    add_bullet(doc, "I dati sensibili (telefoni, email) non vengono mai "
                    "bundlizzati nel build dell'app. Restano solo lato server.")
    add_bullet(doc, "Anche se qualcuno reverse-engineering il codice client, "
                    "non trova mai la lista contatti.")
    add_bullet(doc, "Audit trail: ogni invio promozionale registra in Firestore "
                    "(collection promotions_sent) chi è stato contattato, "
                    "quando, su che canale. Serve per dimostrare al Garante "
                    "che si rispetta il consenso.")

    # ============================================================
    # 8. ROADMAP DI IMPLEMENTAZIONE
    # ============================================================
    add_heading(doc, "8. Roadmap di implementazione", level=1)
    add_table(doc,
              headers=["#", "Task", "Stima", "Stato"],
              rows=[
                  ["1", "Re-introdurre Satispay nel checkout", "30 min", "✓ FATTO"],
                  ["2", "Aggiungere Bonifico Istantaneo come metodo pagamento", "1 h", "In attesa IBAN"],
                  ["3", "Box marketing evidenziata in registrazione + Impostazioni", "30 min", "Prossimo"],
                  ["4", "Import CSV 6000+ contatti in Firestore + rules", "1 h", "Pianificato"],
                  ["5", "Pannello «Crea Promozione» 4 tab (3 operative + Logica/GDPR) + 3 canali invio", "6-7 h", "Pianificato"],
                  ["6", "Campagna soft opt-in WhatsApp (manual batch)", "Operatore: 60-90 gg", "Dopo task 5"],
              ])

    # ============================================================
    # 9. DECISIONI PENDENTI
    # ============================================================
    add_heading(doc, "9. Decisioni pendenti dal committente", level=1)
    add_bullet(doc, "IBAN, intestatario e banca per il bonifico istantaneo "
                    "(serve per task 2)")
    add_bullet(doc, "QR in negozio per acquisire nuovi utenti app: "
                    "soprasseduto per il momento, eventualmente da aggiungere "
                    "in seconda battuta")
    add_bullet(doc, "Integrazione Brevo (email broadcast): credenziali API "
                    "Brevo da generare quando si attiva il canale email")
    add_bullet(doc, "Verifica volume effettivo email valide nel CSV (molti "
                    "contatti hanno solo telefono, l'email è vuota)")

    # ============================================================
    # 10. APPENDICE — DATI CHIAVE
    # ============================================================
    add_heading(doc, "10. Appendice — Dati chiave e riferimenti", level=1)
    add_table(doc,
              headers=["Dato", "Valore"],
              rows=[
                  ["Contatti CSV totali", "6000+ contatti"],
                  ["Numero WhatsApp Business negozio", "+39 335 169 7903"],
                  ["Email negozio", "fotosilvestre1970@gmail.com"],
                  ["Indirizzo negozio", "Via V. Emanuele III, 205 — Frattamaggiore (NA)"],
                  ["Firebase project", "silvestre-fotoservizi"],
                  ["File CSV originale", "Desktop/SilvestreApp/Contatti_Clienti.csv"],
                  ["Provider pagamenti scelto", "Satispay (online) + Bonifico Istantaneo + Caparra in negozio"],
                  ["Provider email (gratis)", "Brevo (ex Sendinblue) — 300 email/giorno free tier"],
                  ["Provider push (gratis)", "Firebase Cloud Messaging — illimitato"],
              ])

    # ============================================================
    # FOOTER
    # ============================================================
    doc.add_paragraph()
    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    r = p.add_run(
        "Documento generato il 20 maggio 2026 — Silvestre Fotoservizi · "
        "Frattamaggiore (NA)"
    )
    r.italic = True
    r.font.size = Pt(9)
    r.font.color.rgb = RGBColor(0xAA, 0xAA, 0xAA)

    out_path = (
        Path(__file__).resolve().parent.parent / "docs" / "Promozioni.docx"
    )
    out_path.parent.mkdir(parents=True, exist_ok=True)
    doc.save(out_path)
    print(f"[OK] Documento generato: {out_path}")
    print(f"     Pagine stimate: ~6-8 A4")


if __name__ == "__main__":
    main()
