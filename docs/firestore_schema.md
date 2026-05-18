# Firestore Schema — Silvestre Fotoservizi

## Collections

### `users/{uid}`
```
{
  uid: string,
  email: string,
  displayName: string,
  phone: string,
  createdAt: timestamp,
  defaultPickupNote: string?,
  role: "customer" | "staff" | "admin"
}
```

### `products/{productId}`
Dynamic catalog — admin can add/edit product types without app updates.
```
{
  id: string,
  category: "print" | "photobook" | "calendar" | "canvas" | "magnet" | "gadget" | ...,
  name: string,                  // "Stampa 10x15 lucida"
  description: string,
  basePrice: number,             // EUR
  active: boolean,
  variants: [                    // sizes, finishes, page counts...
    { id, name, priceDelta, attributes: {...} }
  ],
  editorConfig: {                // how editor handles this product
    canvasSize: { w, h, unit: "mm" },
    bleed: number,
    minDpi: number,
    template: string?            // ref to /templates/{id}
  },
  thumbnailUrl: string,
  galleryUrls: string[],
  sortOrder: number
}
```

### `templates/{templateId}`
Photobook / calendar / canvas layout templates.
```
{
  id, name, category, pageCount,
  pages: [                       // each page has placeholders
    { width, height, layers: [{type: "photo"|"text", x, y, w, h, ...}] }
  ],
  thumbnailUrl: string
}
```

### `orders/{orderId}`
```
{
  id: string,
  userId: string,
  status: "draft" | "submitted" | "in_production" | "ready_for_pickup" | "picked_up" | "cancelled",
  items: [
    {
      productId, variantId, quantity,
      designId: string,          // ref to /designs/{id}
      unitPrice, lineTotal
    }
  ],
  subtotal, total,
  pickupCode: string,            // shown to customer + printed receipt
  pickupNote: string?,
  createdAt, submittedAt, readyAt, pickedUpAt: timestamp?
}
```

### `designs/{designId}`
User's edited project (photobook layout, single print crop, etc.).
```
{
  id, userId, productId, templateId?,
  pages: [...],                  // serialized canvas state
  assetRefs: [string],           // /uploads/{userId}/{...}
  thumbnailUrl: string,
  updatedAt: timestamp
}
```

### `uploads/{userId}/{uploadId}` (Storage, not Firestore)
Raw user photo uploads. Metadata mirrored in Firestore at `users/{uid}/uploads/{id}`.

### `settings/store` (single doc)
```
{
  name: "Silvestre Fotoservizi",
  address: "Via Vittorio Emanuele III, 205, 80027 Frattamaggiore (NA)",
  phone: "+390818306365",
  email: "fotosilvestre1970@gmail.com",
  hours: { mon: "09:00-13:00", ... },
  pickupNoticeHours: 24          // min lead time
}
```

## Security rules (high-level)
- `users/{uid}` — owner read/write own, admin read all
- `products`, `templates`, `settings` — public read, admin write
- `orders` — owner read own + create, admin (= operatore@) read/write all
- `designs` — owner read/write own, admin read for production
- `uploads/{userId}` Storage — owner read/write, admin read

## Cloud Functions
- `onOrderSubmit` — generate pickupCode, send notification to admin
- `onOrderStatusChange` — push notification to customer
- `processUpload` — auto-generate thumbnails, EXIF extraction, DPI validation
