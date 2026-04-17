const admin = require('firebase-admin');
const { onCall, HttpsError, onRequest } = require('firebase-functions/v2/https');
const { defineSecret, defineString } = require('firebase-functions/params');
const Stripe = require('stripe');

admin.initializeApp();

const stripeSecretKey = defineSecret('STRIPE_SECRET_KEY');
const stripeWebhookSecret = defineSecret('STRIPE_WEBHOOK_SECRET');
const appUrl = defineString('APP_URL', {
  default: 'https://nxtgen-cart.web.app',
});

function getStripeClient() {
  const key = stripeSecretKey.value();
  if (!key) {
    throw new HttpsError('failed-precondition', 'Stripe secret key is not configured.');
  }
  return new Stripe(key);
}

function normalizeCartItems(rawItems) {
  if (!Array.isArray(rawItems) || rawItems.length === 0) {
    throw new HttpsError('invalid-argument', 'Cart items are required.');
  }

  return rawItems.map((item, index) => {
    const name = String(item?.name || '').trim();
    const quantity = Number.parseInt(String(item?.quantity || '0'), 10);
    const unitAmount = Number.parseInt(String(item?.unitAmount || '0'), 10);

    if (!name) {
      throw new HttpsError('invalid-argument', `Item at index ${index} is missing a name.`);
    }
    if (!Number.isFinite(quantity) || quantity < 1) {
      throw new HttpsError('invalid-argument', `Item ${name} has an invalid quantity.`);
    }
    if (!Number.isFinite(unitAmount) || unitAmount < 1) {
      throw new HttpsError('invalid-argument', `Item ${name} has an invalid amount.`);
    }

    return {
      id: String(item?.id || ''),
      name,
      quantity,
      unitAmount,
    };
  });
}

exports.createCheckoutSession = onCall(
  {
    secrets: [stripeSecretKey],
    cors: true,
    region: 'us-central1',
  },
  async (request) => {
    const trolleyId = String(request.data?.trolleyId || '').trim();
    const currency = String(request.data?.currency || 'inr').toLowerCase().trim();

    if (!trolleyId) {
      throw new HttpsError('invalid-argument', 'trolleyId is required.');
    }

    const cartItems = normalizeCartItems(request.data?.items);

    const stripe = getStripeClient();
    const originHeader = request.rawRequest?.headers?.origin;
    const baseUrl = String(originHeader || appUrl.value() || '').trim();

    if (!baseUrl) {
      throw new HttpsError(
        'failed-precondition',
        'App URL is missing. Set APP_URL function config and retry.'
      );
    }

    const session = await stripe.checkout.sessions.create({
      mode: 'payment',
      payment_method_types: ['card'],
      success_url: `${baseUrl}?payment=success&session_id={CHECKOUT_SESSION_ID}`,
      cancel_url: `${baseUrl}?payment=cancelled`,
      metadata: {
        trolleyId,
      },
      line_items: cartItems.map((item) => ({
        quantity: item.quantity,
        price_data: {
          currency,
          unit_amount: item.unitAmount,
          product_data: {
            name: item.name,
            metadata: {
              itemId: item.id,
            },
          },
        },
      })),
    });

    if (!session.url) {
      throw new HttpsError('internal', 'Stripe did not return a checkout URL.');
    }

    return {
      sessionId: session.id,
      url: session.url,
    };
  }
);

exports.handleStripeWebhook = onRequest(
  {
    secrets: [stripeSecretKey, stripeWebhookSecret],
    region: 'us-central1',
  },
  async (req, res) => {
    if (req.method !== 'POST') {
      res.status(405).send('Method Not Allowed');
      return;
    }

    const signature = req.header('stripe-signature');
    if (!signature) {
      res.status(400).send('Missing stripe-signature header');
      return;
    }

    let event;
    try {
      const stripe = getStripeClient();
      const webhookSecretValue = stripeWebhookSecret.value();
      if (!webhookSecretValue) {
        res.status(500).send('Stripe webhook secret is not configured.');
        return;
      }

      event = stripe.webhooks.constructEvent(req.rawBody, signature, webhookSecretValue);
    } catch (error) {
      res.status(400).send(`Webhook verification failed: ${error.message}`);
      return;
    }

    if (event.type === 'checkout.session.completed') {
      const session = event.data.object;
      const trolleyId = String(session?.metadata?.trolleyId || '').trim();
      if (trolleyId) {
        await admin.database().ref().update({
          [`trolleys/${trolleyId}/status`]: 'PAID',
          [`trolleys/${trolleyId}/cart_items`]: null,
          [`trolleys/${trolleyId}/lastPaymentSessionId`]: String(session.id || ''),
          [`trolleys/${trolleyId}/lastPaymentAt`]: Date.now(),
        });
      }
    }

    res.json({ received: true });
  }
);
