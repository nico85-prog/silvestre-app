# Silvestre Fotoservizi — App

Mobile app + admin panel for Silvestre Fotoservizi (Frattamaggiore, NA).

## Structure
- `app/` — Flutter mobile app (iOS + Android)
- `admin/` — Next.js admin panel (orders, catalog, customers)
- `firebase/` — Firebase config, security rules, Cloud Functions
- `assets/brand/` — Logo, palette, typography
- `docs/` — Project documentation

## Stack
- **Mobile:** Flutter (Dart)
- **Backend:** Firebase (Auth, Firestore, Storage, Cloud Functions)
- **Admin:** Next.js + TailwindCSS
- **Payments:** "Pay & pick up in store" (no online payment v1)

## Build order
1. Foundation: auth, dynamic catalog, cart, orders, canvas editor, admin
2. Products one by one: prints → photobooks → calendars → canvas → magnets
