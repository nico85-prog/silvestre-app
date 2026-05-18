# Roadmap — Silvestre Fotoservizi App

## Phase 0 — Setup ✅ COMPLETATO
- [x] Project folders + brand assets + palette
- [x] Firestore schema design
- [x] Install Flutter, Node, Firebase CLI
- [x] Init Flutter project con theme (5 palette)
- [x] Init Firebase project (silvestre-fotoservizi)
- [x] Cloudinary account + unsigned upload preset
- [x] Pexels API + 36 immagini cachate

## Phase 1 — Foundation ✅ COMPLETATO (lato cliente)
- [x] Auth email/password (Firebase)
- [x] Catalogo dinamico (Listini/catalogo.csv → mock_catalog.dart)
- [x] Schermata dettaglio prodotto con varianti e prezzi
- [x] Upload foto (galleria/camera) via Cloudinary
- [x] Carrello (in-memory, persistito su Firestore al checkout)
- [x] Sottomissione ordine con codice ritiro
- [x] Storico ordini con stato real-time
- [x] Photobook editor con auto-layout AI
- [x] Pagamenti: pay in-store (reale) + Stripe demo + Satispay demo
- [x] Lavoro Personalizzato (richiesta → preventivo → accetta/rifiuta)
- [x] Operatore: dashboard, lista ordini, dettaglio, cambio stato
- [x] Operatore: invio messaggi WhatsApp/SMS/Email al cliente
- [x] Operatore: gestione preventivi Lavoro Personalizzato
- [x] Admin: aggiungi/rimuovi operatori (max 4) via email
- [x] PWA installabile su iOS Safari + Android Chrome

## Phase 1.5 — DevOps ✅ COMPLETATO
- [x] GitHub repo (nico85-prog/silvestre-app) privato
- [x] CI/CD GitHub Actions (build + deploy automatico su push main)
- [x] Firebase Hosting collegato
- [x] Auto-deploy ad ogni modifica codice

## Phase 2 — Produzione reale (next)
- [ ] Sostituire 36 immagini Pexels con foto reali dei prodotti
- [ ] Testare il flow end-to-end con 1 cliente reale (beta)
- [ ] Privacy Policy + Termini con Iubenda (italiano)
- [ ] Cookie banner GDPR
- [ ] Email transazionali (SendGrid o Resend) — conferma ordine
- [ ] Configurare Stripe/Satispay LIVE (non più demo)
- [ ] Backup automatico Firestore (Cloud Functions schedulato)
- [ ] Sentry per monitoring errori in produzione

## Phase 3 — Store mobili
- [ ] App icon + splash screen con logo
- [ ] Apple Developer account ($99/anno)
- [ ] Google Play Developer account ($25 una tantum)
- [ ] Build iOS (.ipa) + upload TestFlight
- [ ] Build Android (.aab) + upload Play Console
- [ ] Asset store (screenshot, descrizione, keywords)
- [ ] Review submission

## Phase 4 — Marketing & crescita
- [ ] Dominio personalizzato (es. silvestrefotoservizi.it)
- [ ] SEO base per la PWA
- [ ] Instagram/Facebook business integrato
- [ ] Campagna lancio locale (Frattamaggiore)
- [ ] Programma fedeltà (sconto N-esimo ordine)
- [ ] Notifiche push promozionali (FCM)
