/**
 * Silvestre Fotoservizi — Cloud Functions
 *
 * Triggers:
 *  1. onOrderCreated     → push to all operators when a new order arrives
 *  2. onOrderStatusChange → push to customer when status changes
 *  3. scheduledPhotoCleanup → daily run, delete Cloudinary photos 30 days
 *                              after pickup (data minimization / GDPR retention)
 *
 * DEPLOY: requires Blaze plan.
 *   cd firebase && firebase deploy --only functions
 */

const { onDocumentCreated, onDocumentUpdated } = require('firebase-functions/v2/firestore');
const { onSchedule } = require('firebase-functions/v2/scheduler');
const { logger } = require('firebase-functions/v2');
const admin = require('firebase-admin');

admin.initializeApp();
const db = admin.firestore();
const messaging = admin.messaging();

const STATUS_LABEL = {
  submitted: 'Ricevuto',
  inProduction: 'In lavorazione',
  readyForPickup: 'Pronto per il ritiro',
  pickedUp: 'Ritirato',
  cancelled: 'Annullato',
};

// -------------------------------------------------------------------
// 1) New order → notify operators
// -------------------------------------------------------------------
exports.onOrderCreated = onDocumentCreated('orders/{orderId}', async (event) => {
  const order = event.data.data();
  const orderId = event.params.orderId;
  if (!order) return;

  logger.info(`New order ${order.pickupCode} from ${order.customerName || order.userId}`);

  // Find all operators (role in [staff, admin])
  const opsSnap = await db
    .collection('users')
    .where('role', 'in', ['staff', 'admin'])
    .get();

  const allTokens = [];
  for (const opDoc of opsSnap.docs) {
    const tokensSnap = await db
      .collection('users')
      .doc(opDoc.id)
      .collection('fcmTokens')
      .get();
    for (const t of tokensSnap.docs) {
      allTokens.push(t.data().token);
    }
  }

  if (allTokens.length === 0) {
    logger.warn('No operator FCM tokens registered, skipping push.');
    return;
  }

  const itemCount = (order.items || []).reduce((s, i) => s + (i.quantity || 0), 0);
  const message = {
    notification: {
      title: `Nuovo ordine ${order.pickupCode}`,
      body: `${order.customerName || 'Cliente'} · ${itemCount} articoli · €${Number(order.total).toFixed(2)}`,
    },
    data: {
      orderId,
      type: 'new_order',
      pickupCode: order.pickupCode,
    },
    tokens: allTokens,
  };

  try {
    const res = await messaging.sendEachForMulticast(message);
    logger.info(`Push to operators: ${res.successCount} ok, ${res.failureCount} fail`);
  } catch (e) {
    logger.error('Push failed:', e);
  }
});

// -------------------------------------------------------------------
// 2) Order status change → notify customer
// -------------------------------------------------------------------
exports.onOrderStatusChange = onDocumentUpdated('orders/{orderId}', async (event) => {
  const before = event.data.before.data();
  const after = event.data.after.data();
  if (!before || !after) return;
  if (before.status === after.status) return; // not a status change

  logger.info(`Order ${after.pickupCode} status: ${before.status} → ${after.status}`);

  // Get customer FCM tokens
  const tokensSnap = await db
    .collection('users')
    .doc(after.userId)
    .collection('fcmTokens')
    .get();
  const tokens = tokensSnap.docs.map((d) => d.data().token);
  if (tokens.length === 0) {
    logger.warn(`No tokens for user ${after.userId}, skipping push.`);
    return;
  }

  const statusLabel = STATUS_LABEL[after.status] || after.status;
  const message = {
    notification: {
      title: `Ordine ${after.pickupCode}: ${statusLabel}`,
      body: after.status === 'readyForPickup'
        ? 'Il tuo ordine è pronto, ti aspettiamo in negozio!'
        : `Stato aggiornato: ${statusLabel}`,
    },
    data: {
      orderId: event.params.orderId,
      type: 'status_change',
      newStatus: after.status,
    },
    tokens,
  };

  try {
    const res = await messaging.sendEachForMulticast(message);
    logger.info(`Push to customer: ${res.successCount} ok, ${res.failureCount} fail`);
  } catch (e) {
    logger.error('Push failed:', e);
  }
});

// -------------------------------------------------------------------
// 3) Scheduled photo cleanup (GDPR retention)
// -------------------------------------------------------------------
// Runs daily at 03:00 Europe/Rome. Finds orders pickedUp > 30 days ago
// and clears their Cloudinary photoUrls + photobookPages.photoUrls.
// (Keeps order metadata for fiscal/accounting purposes — 10y per Italian law.)
exports.scheduledPhotoCleanup = onSchedule(
  { schedule: 'every day 03:00', timeZone: 'Europe/Rome' },
  async () => {
    const cutoff = admin.firestore.Timestamp.fromDate(
      new Date(Date.now() - 30 * 24 * 60 * 60 * 1000)
    );
    const oldOrders = await db
      .collection('orders')
      .where('status', '==', 'pickedUp')
      .where('readyAt', '<', cutoff)
      .get();

    logger.info(`Photo cleanup: ${oldOrders.size} orders to scrub`);

    const cloudName = 'dcag1ztpq';
    const apiKey = process.env.CLOUDINARY_API_KEY;
    const apiSecret = process.env.CLOUDINARY_API_SECRET;
    const fetch = (await import('node-fetch')).default;

    for (const orderDoc of oldOrders.docs) {
      const order = orderDoc.data();
      const items = order.items || [];

      // Collect public_ids from URLs (https://res.cloudinary.com/{cloud}/image/upload/{version}/{public_id}.ext)
      const publicIds = new Set();
      for (const it of items) {
        for (const url of it.photoUrls || []) {
          const id = extractPublicId(url);
          if (id) publicIds.add(id);
        }
        for (const page of it.photobookPages || []) {
          for (const url of page.photoUrls || []) {
            if (!url) continue;
            const id = extractPublicId(url);
            if (id) publicIds.add(id);
          }
        }
      }

      // Delete on Cloudinary (uses Admin API → needs API Secret)
      if (publicIds.size > 0 && apiKey && apiSecret) {
        try {
          await deleteCloudinaryAssets(fetch, cloudName, apiKey, apiSecret, [...publicIds]);
        } catch (e) {
          logger.error(`Cloudinary delete failed for order ${orderDoc.id}:`, e);
          continue;
        }
      }

      // Wipe URLs from Firestore order doc
      const scrubbedItems = items.map((it) => ({
        ...it,
        photoUrls: [],
        photobookPages: (it.photobookPages || []).map((p) => ({
          ...p,
          photoUrls: (p.photoUrls || []).map(() => null),
        })),
      }));
      await orderDoc.ref.update({
        items: scrubbedItems,
        photosCleanedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }
  }
);

// -------------------------------------------------------------------
// Helpers
// -------------------------------------------------------------------
function extractPublicId(url) {
  // https://res.cloudinary.com/dcag1ztpq/image/upload/v123/silvestre/UID/12345_name.png
  const m = url.match(/\/upload\/(?:v\d+\/)?(.+?)\.(jpg|jpeg|png|heic|webp)$/i);
  return m ? m[1] : null;
}

async function deleteCloudinaryAssets(fetch, cloudName, apiKey, apiSecret, publicIds) {
  const auth = Buffer.from(`${apiKey}:${apiSecret}`).toString('base64');
  const url = `https://api.cloudinary.com/v1_1/${cloudName}/resources/image/upload`;
  const params = new URLSearchParams();
  for (const id of publicIds) params.append('public_ids[]', id);
  const resp = await fetch(`${url}?${params}`, {
    method: 'DELETE',
    headers: { Authorization: `Basic ${auth}` },
  });
  if (!resp.ok) {
    const body = await resp.text();
    throw new Error(`Cloudinary delete HTTP ${resp.status}: ${body}`);
  }
}
