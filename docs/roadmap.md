# Roadmap — Silvestre Fotoservizi App

## Phase 0 — Setup (current)
- [x] Project folders + brand assets + palette
- [x] Firestore schema design
- [ ] Install Flutter, Node, Firebase CLI
- [ ] Init Flutter project with theme
- [ ] Init Firebase project
- [ ] Init Next.js admin

## Phase 1 — Foundation (the base that supports everything)
- [ ] Auth (email + Google Sign-In + phone OTP)
- [ ] Dynamic catalog screen (reads `products/`)
- [ ] Product detail screen with variant selection
- [ ] Photo upload (gallery + camera) with thumbnail + DPI check
- [ ] Cart (local, persisted)
- [ ] Order submission (status=draft → submitted, pickupCode generated)
- [ ] Order history screen
- [ ] Generic canvas editor primitives (drag/pinch/rotate, page model, save/load design)
- [ ] Admin: orders list, order detail, status update, product CRUD

## Phase 2 — Products on top of the base
- [ ] Prints (10x15, 13x18, 15x21, 20x30, ...) — simplest, just crop+order
- [ ] Photobooks — full editor with templates, page reorder, text
- [ ] Calendars — 12-page editor with date overlays
- [ ] Canvas wall art — single-image, crop with safe area
- [ ] Magnets — small format, multi-up
- [ ] Gadgets (mugs, cushions, etc.) — template-based

## Phase 3 — Production-ready
- [ ] App icon + splash screen with logo
- [ ] App Store + Play Store assets
- [ ] Apple Developer + Google Play accounts
- [ ] Privacy policy + terms (Italian + English)
- [ ] Test with real customer
- [ ] Soft launch
