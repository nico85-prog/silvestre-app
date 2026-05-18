"""
MANUALE_GENERALE_Silvestre.docx — guida compatta e scorrevole.
Entry-point: contiene tutto l'essenziale + rimanda agli altri docs per il dettaglio.
"""

from docx import Document
from docx.shared import Pt, RGBColor
from docx.enum.text import WD_ALIGN_PARAGRAPH
from datetime import date

ORANGE = RGBColor(0xF4, 0x75, 0x21)
DARK = RGBColor(0x2B, 0x2B, 0x2B)
GREY = RGBColor(0x7A, 0x7A, 0x7A)
RED = RGBColor(0xD6, 0x45, 0x45)
GREEN = RGBColor(0x3D, 0xA3, 0x5D)
BLUE = RGBColor(0x1F, 0x77, 0xB4)


def h(doc, t, level=1, color=ORANGE):
    par = doc.add_heading(t, level=level)
    for r in par.runs:
        r.font.color.rgb = color
        r.font.name = "Calibri"


def p(doc, t, bold=False, italic=False, color=DARK, size=11):
    par = doc.add_paragraph()
    r = par.add_run(t)
    r.bold = bold
    r.italic = italic
    r.font.color.rgb = color
    r.font.size = Pt(size)
    r.font.name = "Calibri"


def bul(doc, items):
    for it in items:
        par = doc.add_paragraph(style="List Bullet")
        r = par.add_run(it)
        r.font.size = Pt(11)
        r.font.name = "Calibri"


def num(doc, items):
    for it in items:
        par = doc.add_paragraph(style="List Number")
        r = par.add_run(it)
        r.font.size = Pt(11)
        r.font.name = "Calibri"


def warn(doc, t):
    par = doc.add_paragraph()
    r = par.add_run("\u26a0  " + t)
    r.bold = True
    r.font.color.rgb = RED
    r.font.size = Pt(11)
    r.font.name = "Calibri"


def tip(doc, t):
    par = doc.add_paragraph()
    r = par.add_run("\U0001f4a1  " + t)
    r.font.color.rgb = GREEN
    r.bold = True
    r.font.size = Pt(11)
    r.font.name = "Calibri"


def table(doc, headers, rows):
    t = doc.add_table(rows=1 + len(rows), cols=len(headers))
    t.style = "Light Grid Accent 1"
    hdr = t.rows[0].cells
    for i, htxt in enumerate(headers):
        hdr[i].text = ""
        par = hdr[i].paragraphs[0]
        run = par.add_run(htxt)
        run.bold = True
        run.font.color.rgb = RGBColor(0xFF, 0xFF, 0xFF)
        run.font.name = "Calibri"
        run.font.size = Pt(10.5)
        from docx.oxml.ns import qn
        from docx.oxml import OxmlElement
        shading = OxmlElement("w:shd")
        shading.set(qn("w:fill"), "F47521")
        hdr[i]._tc.get_or_add_tcPr().append(shading)
    for r, row in enumerate(rows, start=1):
        cells = t.rows[r].cells
        for i, val in enumerate(row):
            cells[i].text = ""
            run = cells[i].paragraphs[0].add_run(str(val))
            run.font.size = Pt(10.5)
            run.font.name = "Calibri"


# ============================================================================
doc = Document()
styles = doc.styles
styles["Normal"].font.name = "Calibri"
styles["Normal"].font.size = Pt(11)

# ---- COVER ----
title = doc.add_paragraph()
title.alignment = WD_ALIGN_PARAGRAPH.CENTER
r = title.add_run("MANUALE GENERALE")
r.bold = True
r.font.size = Pt(30)
r.font.color.rgb = ORANGE
r.font.name = "Calibri"

sub = doc.add_paragraph()
sub.alignment = WD_ALIGN_PARAGRAPH.CENTER
r = sub.add_run("App Silvestre Fotoservizi")
r.font.size = Pt(18)
r.font.color.rgb = DARK
r.font.name = "Calibri"

st = doc.add_paragraph()
st.alignment = WD_ALIGN_PARAGRAPH.CENTER
r = st.add_run("La guida che apri quando ti serve capire qualcosa")
r.font.size = Pt(12)
r.italic = True
r.font.color.rgb = GREY
r.font.name = "Calibri"

dt = doc.add_paragraph()
dt.alignment = WD_ALIGN_PARAGRAPH.CENTER
r = dt.add_run(f"v1.0 — {date.today().strftime('%d/%m/%Y')}")
r.font.size = Pt(10)
r.font.color.rgb = GREY
r.font.name = "Calibri"

doc.add_paragraph()
p(doc, "Indice rapido", bold=True)
p(doc,
  "1. La tua app in 1 minuto  ·  2. Firebase e Cloudinary spiegati  ·  "
  "3. Lato cliente  ·  4. Lato operatore  ·  5. Cose da comprare  ·  "
  "5.5. Riepilogo cose mancanti (TIER 1/2/3)  ·  "
  "6. Click gratis da fare  ·  7. Altri documenti  ·  8. Problemi comuni  ·  "
  "9. Glossario", italic=True)

doc.add_page_break()

# ============================================================================
h(doc, "1. La tua app in 1 minuto", 1)

p(doc,
  "Hai una sola app con DUE FACCE: clienti e operatori. Cambia in base a chi si logga.")

p(doc, "Cliente:", bold=True)
p(doc, "Apre app → registra → sceglie prodotto → carica foto → ordina → paga (carta/Satispay/in negozio) → "
       "riceve codice ritiro → quando l'ordine è pronto riceve notifica → ritira in negozio.")

p(doc, "Operatore (tu + 3 dipendenti):", bold=True)
p(doc, "Apre app → vede dashboard con ordini in real-time → lavora gli ordini → cambia stato → "
       "manda messaggio cliente via WhatsApp/SMS/Email → cliente notificato.")

p(doc, "Hai 4 documenti in docs/. QUESTO è l'unico che devi leggere sempre. "
       "Gli altri li apri solo quando servono (vedi sezione 7).", italic=True)

doc.add_page_break()

# ============================================================================
h(doc, "2. Firebase e Cloudinary — chi sono e perché", 1)

p(doc, "La tua app è solo l'INTERFACCIA. I dati e le foto vivono altrove, "
       "in due servizi cloud che ti affittano spazio e funzioni. Senza di loro, "
       "ogni installazione dell'app sarebbe isolata, senza memoria.")

p(doc, "Servizi esterni in cui SEI GIÀ registrato:", bold=True)
table(doc,
      ["Servizio", "Tipo registrazione", "Costo attuale", "A cosa serve"],
      [
          ["Firebase (Google)", "Account Google", "Gratis (Spark)", "Auth + database + push + hosting"],
          ["Cloudinary", "Email + password", "Gratis (Developer)", "Magazzino foto utenti"],
          ["Pexels", "Email + password", "Gratis", "Foto stock per catalogo (con attribuzione automatica autori)"],
          ["GitHub", "Account GitHub", "Gratis", "Backup codice + CI/CD auto-deploy"],
      ])

p(doc, "Servizi esterni FUTURI (non aperti, vedi sez. 5 per dettagli):", bold=True)
bul(doc, [
    "Stripe — pagamenti carta",
    "Satispay Business — pagamenti Satispay",
    "Apple Developer + Google Play — pubblicazione store",
    "Iubenda — privacy/termini",
    "Aruba o FattureInCloud — fatturazione elettronica",
])

p(doc, "Servizi che l'app USA SENZA che tu sia registrato (URL pubblici, niente account):", bold=True)
bul(doc, [
    "LoremFlickr — immagini placeholder a tema (da sostituire con tue foto reali prima del rilascio)",
    "Google Fonts — font dell'app (CDN gratuito)",
    "Picsum Photos — placeholder backup quando LoremFlickr non risponde",
])

doc.add_paragraph()
h(doc, "\U0001f525 Firebase (Google)", 2)
p(doc, "Il \"cervello\" centrale dell'app. Fa 3 lavori:", bold=True)
bul(doc, [
    "Auth: gestisce login/registrazione. Le password sono cifrate da Google, non da te.",
    "Firestore: il database. Ordini, profili, ruoli, impostazioni — tutto lì.",
    "Cloud Functions: piccoli script automatici (es. \"manda push all'operatore quando arriva un nuovo ordine\").",
])
p(doc, "Perché è importante:", bold=True)
bul(doc, [
    "Cliente e operatore vedono gli STESSI dati in real-time (sync ~1 secondo).",
    "Le password non le gestisci tu = nessun rischio data breach lato tuo.",
    "Quando il cliente torna in app dopo 6 mesi, ritrova i suoi ordini.",
])
p(doc, "Costo: gratis per piccoli numeri. Quando attivi le push automatiche serve passare al "
       "piano Blaze (~0-5\u20ac/mese in pratica per un negozio piccolo).")

doc.add_paragraph()
h(doc, "\u2601\ufe0f Cloudinary", 2)
p(doc, "Il \"magazzino delle foto\". È un servizio specializzato per immagini.", bold=True)
bul(doc, [
    "Quando il cliente carica una foto da stampare, va su Cloudinary, non sul tuo server.",
    "Cloudinary fa anche thumbnail e ottimizzazioni al volo (lo stesso URL serve foto di dimensioni diverse).",
    "Il file è sicuro: solo il cliente e l'operatore possono accedervi.",
])
p(doc, "Perché lo usiamo invece di Firebase Storage:", bold=True)
bul(doc, [
    "Firebase Storage da metà 2024 richiede carta di credito anche solo per testare.",
    "Cloudinary regala 25 GB gratis (senza carta). Bastano per anni di ordini piccoli.",
    "Migrazione a Firebase Storage in futuro: 2 ore di lavoro se servisse.",
])
p(doc, "Costo: gratis fino a 25 GB di foto + 25 GB di traffico al mese. Per Silvestre primi anni = zero.")

doc.add_paragraph()
warn(doc, "Senza FIREBASE l'app non funziona proprio. Senza CLOUDINARY le foto non si caricano. "
          "Sono entrambi essenziali e operativi adesso.")

doc.add_page_break()

# ============================================================================
h(doc, "2.5 La tua app è GIÀ ONLINE", 1)
p(doc, "L'app è pubblicata sul cloud di Google ed è raggiungibile da qualsiasi telefono o computer "
       "del mondo. Niente Apple/Google store ancora — solo URL web.")

doc.add_paragraph()
p(doc, "URL pubblico:", bold=True)
p(doc, "  https://silvestre-fotoservizi.web.app", bold=True, color=BLUE)

doc.add_paragraph()
p(doc, "Come installarla \"come app\" su iPhone:", bold=True)
num(doc, [
    "Apri Safari (NON Chrome — Apple permette \"Aggiungi a Home\" solo da Safari)",
    "Vai a https://silvestre-fotoservizi.web.app",
    "Tocca icona Condividi (quadrato con freccia su, in basso al centro)",
    "Scorri menu \u2192 \"Aggiungi alla schermata Home\"",
    "Conferma \"Silvestre\" \u2192 Aggiungi",
    "Esci da Safari \u2192 trovi l'icona arancione sulla home del telefono",
    "Tocca \u2192 si apre a tutto schermo come un'app vera",
])

p(doc, "Come installarla su Android:", bold=True)
num(doc, [
    "Apri Chrome \u2192 vai all'URL sopra",
    "Chrome propone automaticamente \"Installa Silvestre Fotoservizi\" (banner in basso)",
    "Tocca \"Installa\" \u2192 fatto. In alternativa: men\u00f9 3 puntini \u22ee \u2192 \"Installa app\"",
])

tip(doc, "Per condividere l'app con clienti/amici basta inviargli il link "
         "https://silvestre-fotoservizi.web.app via WhatsApp.")

doc.add_paragraph()
h(doc, "Messaggi pronti da inoltrare ai clienti", 2)
p(doc, "Copia-incolla questi testi su WhatsApp o per email. "
       "Salva il documento e tienitelo a portata di mano in negozio.", italic=True)

doc.add_paragraph()
p(doc, "TESTO PER iPhone (iOS):", bold=True, color=BLUE)
p(doc,
  "Ciao! Apri questo link dall'iPhone usando SAFARI (importante, non Chrome): "
  "https://silvestre-fotoservizi.web.app\n\n"
  "1) Carica la pagina\n"
  "2) In basso al centro tocca l'icona Condividi (quadrato con freccia che esce verso l'alto)\n"
  "3) Scorri il menu verso il basso fino a \"Aggiungi alla schermata Home\"\n"
  "4) Tocca, conferma il nome \"Silvestre\" in alto a destra \u2192 Aggiungi\n"
  "5) Esci da Safari \u2192 trovi l'icona arancione Silvestre sulla home come una vera app\n\n"
  "Pronto! Aprila da li' come fai con le altre app.")

doc.add_paragraph()
p(doc, "TESTO PER Android:", bold=True, color=BLUE)
p(doc,
  "Ciao! Apri questo link dall'Android usando CHROME: "
  "https://silvestre-fotoservizi.web.app\n\n"
  "OPZIONE 1 (automatica): apri la pagina, in basso compare il banner \"Installa "
  "Silvestre Fotoservizi\" \u2192 tocca Installa.\n\n"
  "OPZIONE 2 (manuale):\n"
  "1) Carica la pagina\n"
  "2) In alto a destra tocca i 3 puntini verticali\n"
  "3) Tocca \"Installa app\" (o \"Aggiungi a schermata Home\")\n"
  "4) Conferma \"Installa\"\n\n"
  "L'icona arancione Silvestre appare sulla home del telefono come una vera app.")

doc.add_paragraph()
p(doc, "Note importanti:", bold=True)
bul(doc, [
    "Su iPhone NON funziona con Chrome — Apple permette \"Aggiungi a Home\" solo da Safari "
    "(limite Apple, non nostro).",
    "Su Android funziona anche con Samsung Internet, Edge, Firefox — ma Chrome \u00e8 il pi\u00f9 semplice.",
    "Anche senza \"installare\", il cliente pu\u00f2 sempre usare l'app dal browser come "
    "un normale sito web.",
    "Una volta installata: splash screen arancione all'avvio, schermo intero, niente barra browser. "
    "Identica a un'app scaricata dallo store.",
])

doc.add_paragraph()
h(doc, "Come ricevere le modifiche (CI/CD attivo)", 2)
p(doc, "La pipeline automatica è ATTIVA. Ogni modifica al codice segue questo flusso:")
num(doc, [
    "Io modifico il codice sul tuo PC",
    "Faccio commit + push su GitHub (repository: nico85-prog/silvestre-app)",
    "GitHub Actions esegue automaticamente: flutter analyze + flutter test + build web + deploy Firebase Hosting",
    "In 3-5 minuti l'app online \u00e8 aggiornata",
    "Tu fai refresh sul telefono (Safari/Chrome) e vedi le novit\u00e0",
])

tip(doc, "Tu non devi mai aprire terminale, GitHub o Firebase Console. Mi dici 'aggiungi X' "
         "o 'modifica Y', faccio io tutto. La CI \u00e8 il guardiano: se introduce un errore "
         "blocca il deploy automaticamente, quindi il sito live non si rompe.")

doc.add_page_break()

# ============================================================================
h(doc, "3. Lato CLIENTE", 1)
p(doc, "Quello che vede chi scarica la tua app.")

num(doc, [
    "Schermata benvenuto con logo Silvestre → \"Accedi\" o \"Crea account\"",
    "Registrazione: nome, email, telefono, password + 3 consensi GDPR granulari "
    "(Termini obbligatori, Marketing opzionale, Foto portfolio opzionale)",
    "Riceve email di verifica (clicca link per confermare)",
    "Catalogo con 6 categorie (Stampe, Fotolibri, Calendari, Tele/Quadri, Fotoregali, Crystal 3D) — "
    "30 prodotti, 193 varianti reali dal listino Silvestre (incluse tutte le fasce quantità: 1-29, 30-49, 50-149, 150-299, 300-479, 480-599, 600+ per le stampe piccole)",
    "Sceglie prodotto → formato → carica le foto (per le stampe la quantità si imposta automaticamente al numero di foto caricate, sempre modificabile)",
    "Nel dettaglio prodotto vede: card descrizione dettagliata + selettore quantità a sinistra + prezzo totale sopra il bottone Aggiungi + freccia indietro",
    "Per i Fotolibri: si apre l'EDITOR AUTOMATICO che impagina da solo (1/2/3/4/6 foto per pagina)",
    "Aggiunge al carrello → checkout",
    "Sceglie come pagare: CARTA (Stripe) / SATISPAY / PAGA IN NEGOZIO",
    "Riceve CODICE RITIRO (es. SLV-100001)",
    "Vede l'ordine in tempo reale in tab \"Ordini\"",
    "Quando lo cambi a \"Pronto\", riceve PUSH NOTIFICATION sul telefono",
    "Va in negozio, mostra il codice, ritira",
])

doc.add_paragraph()
h(doc, "Lavoro Personalizzato (cose fuori catalogo)", 2)
p(doc, "Se il cliente cerca qualcosa che non vede nel catalogo (es. una stampa su materiale insolito, "
       "un formato fuori standard, un lavoro complesso), tappa la card arancione \"Lavoro Personalizzato\" "
       "nella home → form con titolo, descrizione, foto di riferimento → invia richiesta. "
       "Tu ricevi e mandi il preventivo (importo + tempi + nota). Il cliente accetta o declina; "
       "se accetta, l'ordine prosegue come un ordine normale.")

p(doc, "In tab Account può: modificare profilo, esportare i suoi dati (GDPR), "
       "eliminare l'account (GDPR), cambiare tema dell'app, leggere Privacy + Termini.", italic=True)

doc.add_page_break()

# ============================================================================
h(doc, "4. Lato OPERATORE", 1)
p(doc, "Appena ti logghi come admin/staff, vedi una versione DIVERSA dell'app — "
       "badge arancione \"OPERATORE\" in alto, 4 tab in basso.")

doc.add_paragraph()
h(doc, "Tab Dashboard", 2)
bul(doc, [
    "Stat cards: ordini oggi, da fare, da ritirare, ricavi 7gg (cliccabili → filtro)",
    "ALERT rossi: ordini in ritardo, limite giornaliero raggiunto",
    "Lista ordini di oggi in tempo reale",
])

h(doc, "Tab Ordini", 2)
bul(doc, [
    "Lista TUTTI gli ordini (anche di altri operatori)",
    "Filtra per stato + cerca per codice/nome/telefono",
    "Tap su ordine → DETTAGLIO con articoli + foto + nota cliente",
    "Bottoni stato: Avvia lavorazione → Pronto → Ritirato (oppure Annulla)",
    "Bottone \"Invia messaggio cliente\" → apre WhatsApp/SMS/Email pre-compilato (testo da template, modificabile)",
    "Per i Fotolibri: vedi tutte le pagine impaginate, tap per ingrandire",
    "Per le richieste di Lavoro Personalizzato: vedi titolo+descrizione+foto, "
    "compili form preventivo (importo \u20ac + tempi + nota), invii — il cliente decide se accettare",
])

h(doc, "Tab Calendario", 2)
bul(doc, [
    "Vista 3 settimane (passate + future)",
    "Per ogni giorno: numero ordini + colore (verde <80% / giallo \u226580% / rosso saturo)",
])

h(doc, "Tab Impostazioni", 2)
bul(doc, [
    "GESTIONE OPERATORI: lista dei 4, aggiungi/rimuovi via email",
    "Limite ordini/giorno (default 20, regolabile +/-)",
    "Ore prima di marcare un ordine come \"in ritardo\"",
    "Template messaggi cliente (4 template modificabili)",
    "Dati negozio in fondo",
])

p(doc, "Real-time: se l'operatore A cambia stato di un ordine, l'operatore B vede "
       "l'aggiornamento entro ~1 secondo. Niente refresh.", italic=True)

doc.add_page_break()

# ============================================================================
h(doc, "5. Strategia di rilascio e cose da COMPRARE", 1)
warn(doc, "Niente di questa lista serve per testare l'app in locale. Serve solo per il rilascio pubblico.")

p(doc, "Hai DUE strade per portare l'app ai clienti:", bold=True)

doc.add_paragraph()
h(doc, "Strada A — PWA WEB (consigliata per iniziare)", 2)
p(doc, "I clienti aprono un URL (es. app.silvestrefotoservizi.it) dal browser del telefono. "
       "Dal menu \"Aggiungi a Home\" / \"Installa app\" l'icona finisce sul desktop del telefono "
       "come se fosse un'app vera. Funziona iOS + Android + PC.")
table(doc,
      ["Cosa", "Costo", "Note"],
      [
          ["Dominio (.it)", "~15\u20ac/anno", "Apri su Aruba/Register/GoDaddy"],
          ["Firebase Hosting", "GRATIS", "Hosting per Flutter web (fino a 10 GB)"],
          ["TOTALE", "~15\u20ac/anno", "Tutto qui."],
      ])
tip(doc, "Mio consiglio: PARTI con questa. Nessun Apple/Google. Pubblichi in 1 ora.")

doc.add_paragraph()
h(doc, "Strada B — APP NATIVE su store ufficiali", 2)
p(doc, "Quando i clienti ti chiedono \"ma è sull'App Store?\" e vuoi quella legittimazione, "
       "aggiungi le versioni native. STESSO codice Flutter — solo build diversa.")
table(doc,
      ["#", "Cosa", "Costo", "Cosa sblocca"],
      [
          ["1", "Iubenda Plus", "~80\u20ac/anno", "Privacy + Termini conformi GDPR (obbligatorio app store)"],
          ["2", "Apple Developer", "99\u20ac/anno", "Pubblicare su App Store iPhone"],
          ["3", "Google Play Developer", "25$ una tantum", "Pubblicare su Play Store Android"],
          ["4", "Firebase Blaze", "0-5\u20ac/mese", "Push automatiche + cleanup foto automatico"],
          ["5", "Stripe", "0 apertura, 1.4% per tx", "Pagamenti carta online"],
          ["6", "Satispay Business", "0 apertura, 1% per tx", "Pagamento Satispay (richiede PIVA verifica)"],
          ["7", "Fatturazione elettronica (Aruba)", "25-50\u20ac/anno", "Fatture B2B + corrispettivi"],
          ["8", "Polizza RC + Cyber", "400-1200\u20ac/anno", "Protezione legale + violazioni dati"],
      ])

p(doc, "TOTALE Strada B primo anno (minimo): ~300\u20ac. Con assicurazioni: ~1.500-2.500\u20ac.", bold=True)

tip(doc, "Se vai Strada B: INIZIA SUBITO le iscrizioni Apple e Google. "
         "DUNS Apple = 2 settimane, cartolina Google = 3-5 settimane.")

doc.add_paragraph()
p(doc, "Importante: Claude (Anthropic) NON c'entra niente con questi costi. Sono regole "
       "di Apple e Google per il loro store. Senza l'app store di Apple, NESSUNA app può "
       "essere installata su iPhone normale.", italic=True)

doc.add_paragraph()
p(doc, "Per istruzioni step-by-step di OGNI acquisto, vedi: "
       "Pubblicazione_App_Silvestre.docx (sezioni 2 e 3).", italic=True)

doc.add_page_break()

# ============================================================================
h(doc, "5.5. Riepilogo COMPLETO: cosa manca per produzione (gratis + a pagamento)", 1)

p(doc, "Tabella organizzata per priorità. Tier 1 = obbligatorio prima di accettare ordini reali. "
       "Tier 2 = entro 30 giorni dal lancio. Tier 3 = espansione futura.", italic=True)

doc.add_paragraph()
h(doc, "TIER 1 — Indispensabile prima del lancio pubblico", 2)
table(doc,
      ["#", "Cosa manca", "Costo", "Tempo", "Note"],
      [
          ["1", "Foto reali dei prodotti", "GRATIS", "1 giorno", "Ora ci sono foto Pexels mockup. Scatta foto vere dei prodotti, le carico io sull'app"],
          ["2", "Pagamenti Stripe LIVE", "GRATIS apertura, ~1.4% + 0.25\u20ac per transazione", "1-2 giorni verifica", "Servono dati azienda + PIVA. Ora è in demo mode"],
          ["3", "Pagamenti Satispay LIVE", "GRATIS apertura, ~1.5% per transazione", "1 settimana verifica", "Account Satispay Business, ora demo"],
          ["4", "Email automatiche (SendGrid)", "GRATIS fino 100 mail/giorno", "30 minuti", "Conferma ordine, ordine pronto, preventivo accettato"],
          ["5", "Privacy + Termini GDPR (Iubenda)", "29-79\u20ac/anno", "10 minuti compilazione", "Obbligatorio se hai utenti reali. App Store/Play lo richiedono"],
          ["6", "Cookie banner GDPR", "Incluso in Iubenda", "5 minuti", "Stesso piano Iubenda lo genera automatico"],
          ["7", "Beta test con 5-10 clienti veri", "GRATIS", "1-2 settimane", "Manda agli amici via Istruzioni_Amici_Test.txt"],
      ])
p(doc, "TOTALE TIER 1: ~30-80\u20ac/anno (Iubenda) + commissioni transazioni. Tutto il resto è gratis.", bold=True)

doc.add_paragraph()
h(doc, "TIER 2 — Entro 30 giorni dal lancio", 2)
table(doc,
      ["#", "Cosa manca", "Costo", "Tempo", "Note"],
      [
          ["8", "Dominio personalizzato (.it)", "10-15\u20ac/anno", "10 minuti + 24h DNS", "Es. silvestrefotoservizi.it invece di silvestre-fotoservizi.web.app"],
          ["9", "Backup Firestore schedulato", "GRATIS (free tier)", "30 min setup", "Cloud Function che esporta i dati ogni notte su Storage"],
          ["10", "Sentry per monitoring errori", "GRATIS fino 5000 errori/mese", "15 min", "Quando l'app crasha lato cliente, ricevi alert su email"],
          ["11", "App icon professionale", "50-200\u20ac una tantum", "designer 1-3 gg", "Logo già c'è, ma servono icon multiple per Android/iOS"],
          ["12", "Bottone WhatsApp diretto", "GRATIS", "10 min codice", "In app: bottone \"Contattaci\" che apre WhatsApp con il tuo numero"],
          ["13", "Splash screen brand", "GRATIS (incluso Flutter)", "10 min", "Schermata logo all'avvio invece del bianco"],
      ])
p(doc, "TOTALE TIER 2: 60-215\u20ac primo anno.", bold=True)

doc.add_paragraph()
h(doc, "TIER 3 — Espansione (3-12 mesi dopo)", 2)
table(doc,
      ["#", "Cosa manca", "Costo", "Tempo", "Note"],
      [
          ["14", "Apple Developer (iOS App Store)", "99$ (~92\u20ac)/anno", "1-2 settimane verifica DUNS", "Per essere su App Store iPhone. Senza, solo PWA via Safari"],
          ["15", "Google Play Developer (Android)", "25$ (~23\u20ac) UNA TANTUM", "3-5 settimane verifica cartolina", "Per essere su Play Store"],
          ["16", "Google Analytics 4", "GRATIS", "20 min", "Quanti visitano, quanti ordinano, dove si bloccano"],
          ["17", "Programma fedeltà (sconto N-esimo ordine)", "GRATIS (solo sviluppo)", "1-2 giorni codice", "Es. al 10° ordine -20%. Aumenta retention"],
          ["18", "Notifiche push promozionali (FCM)", "GRATIS", "30 min", "Già pronto. Manda push manuale es. Black Friday, Natale"],
          ["19", "Versione inglese", "GRATIS (solo traduzione)", "1 giorno", "Per turisti / clienti fuori provincia"],
          ["20", "Polizza RC + Cyber", "400-1200\u20ac/anno", "1 ora preventivo", "Protezione legale per data breach o dispute"],
      ])
p(doc, "TOTALE TIER 3 primo anno: 115-1320\u20ac dipende da quanto includi.", bold=True)

doc.add_paragraph()
h(doc, "Cose GIÀ a posto (non manca nulla)", 2)
bul(doc, [
    "Auth con email/password (Firebase) — clienti possono registrarsi e fare login",
    "Catalogo dinamico da CSV (30 prodotti, 193 varianti)",
    "Carrello e ordini real-time (cliente e operatore vedono lo stesso in 1 secondo)",
    "Photobook editor con auto-impagina AI",
    "Lavoro personalizzato (richiesta preventivo)",
    "3 ruoli: customer, staff, admin con permessi Firestore",
    "Operatore manda messaggi cliente via WhatsApp/SMS/Email",
    "Codice ritiro generato automaticamente per ogni ordine",
    "PWA installabile su iOS Safari + Android Chrome",
    "CI/CD auto-deploy su push GitHub (Build & Deploy workflow)",
    "Workflow manuale Refresh Catalog Images (Pexels)",
    "Tutti i dati persistono ai deploy (Firestore non viene mai resettato)",
])

doc.add_page_break()

# ============================================================================
h(doc, "6. Click GRATIS — STATO: TUTTI FATTI \u2705", 1)
p(doc, "I 4 click iniziali sono stati completati durante il setup. Sezione qui per riferimento storico.")

table(doc,
      ["#", "Cosa", "Stato", "Dove vive ora"],
      [
          ["A", "VAPID key per push web", "FATTO", "push_notifications_service.dart riga 14"],
          ["B", "Registra app Android", "FATTO", "app/android/app/google-services.json"],
          ["C", "Registra app iOS", "FATTO", "app/ios/Runner/GoogleService-Info.plist"],
          ["D", "Cloudinary API Secret", "FATTO", ".env.local (27 caratteri)"],
      ])

tip(doc, "Prossimi click gratis utili (non più nel setup di base) — vedi sezione 5.5 TIER 1:")
bul(doc, [
    "Aprire account SendGrid free (100 mail/giorno gratis) per email automatiche",
    "Aprire account Sentry free (5000 errori/mese gratis) per monitoring",
    "Iscriversi a Iubenda (29\u20ac/anno) per Privacy + Termini GDPR",
    "Acquistare dominio .it (10\u20ac/anno) e collegarlo a Firebase Hosting",
])

doc.add_page_break()

# ============================================================================
h(doc, "7. Altri documenti — quando aprirli", 1)
table(doc,
      ["Documento", "Quando aprirlo"],
      [
          ["Conformita_Legale_Silvestre.docx",
           "Prima di andare da avvocato o commercialista"],
          ["Pubblicazione_App_Silvestre.docx",
           "Quando pubblichi su App Store / Play Store"],
          ["Guida_Firebase_Silvestre.docx",
           "Riferimento tecnico Firebase (per tecnici)"],
          ["Deploy_FCM_Mobile_Functions.docx",
           "Per attivare push notifications + cleanup automatico foto"],
      ])

tip(doc, "A un tecnico nuovo dai TUTTI questi 4 + questo manuale. A un commercialista "
         "solo \"Conformita_Legale\". A un cliente curioso solo questo manuale (sezioni 1-4).")

doc.add_page_break()

# ============================================================================
h(doc, "8. Problemi comuni", 1)
table(doc,
      ["Sintomo", "Cosa fare"],
      [
          ["Pagina bianca", "Ctrl+Shift+R per hard refresh"],
          ["Login non funziona", "Click \"Password dimenticata?\" \u2192 email reset"],
          ["Foto non si caricano", "Verifica file <15 MB e formato jpg/png/heic/webp"],
          ["Push non arrivano", "Manca VAPID (sez. 6A) o utente ha negato permessi browser"],
          ["Operatore vede solo i suoi ordini", "Il suo user role NON è admin/staff. Aggiungilo in Impostazioni"],
          ["Limite ordini saturato", "Tab Impostazioni \u2192 aumenta il limite"],
          ["Ordini segnati in ritardo", "Lavorali o cambia ore-soglia in Impostazioni"],
      ])

warn(doc, "Se in 5 minuti non risolvi: NON modificare il codice. Chiama un tecnico e dagli "
          "questo manuale + Guida_Firebase_Silvestre.docx.")

doc.add_page_break()

# ============================================================================
h(doc, "9. Glossario — minimo essenziale", 1)
table(doc,
      ["Termine", "Significato in 1 riga"],
      [
          ["Flutter", "Linguaggio Google con cui è scritta l'app (gira su iOS, Android, web)"],
          ["Firebase", "Cervello centrale: login + database + push (vedi sez. 2)"],
          ["Cloudinary", "Magazzino foto (vedi sez. 2)"],
          ["Firestore", "Il database dentro Firebase"],
          ["FCM", "Sistema push notification di Firebase"],
          ["VAPID", "Chiave necessaria per push sul browser web"],
          ["APNs", "Sistema push di Apple (per iPhone)"],
          ["Stripe", "Servizio pagamenti con carta"],
          ["Satispay", "App italiana di pagamento istantaneo"],
          ["GDPR", "Legge UE sulla privacy. L'app deve esserne conforme."],
          ["Blaze", "Piano Firebase a consumo (paghi solo quello che usi)"],
          ["Spark", "Piano Firebase gratuito (limitato)"],
          ["Build", "Generare il file installabile per gli store"],
          ["Hot reload", "Modifica codice e vedi risultato istantaneo (per il tecnico)"],
      ])

doc.add_paragraph()
p(doc, "Fine manuale. Per qualsiasi cosa tecnica scrivi a me. Per cose legali/fiscali al "
       "tuo avvocato/commercialista.", italic=True)
p(doc, f"Silvestre Fotoservizi \u00b7 {date.today().strftime('%d/%m/%Y')} \u00b7 v1.0",
  italic=True, color=GREY, size=10)

import os
out = os.path.join(os.path.dirname(__file__), "MANUALE_GENERALE_Silvestre.docx")
doc.save(out)
print(f"OK: {out}")
