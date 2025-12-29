const express = require('express');
const router = express.Router();
const stripeController = require('../controller/stripe.controller');

// Create checkout session
router.post('/create-checkout-session', stripeController.createCheckoutSession);

// Webhook endpoint (must be raw body)
router.post('/webhook', express.raw({ type: 'application/json' }), stripeController.handleWebhook);

// Get subscription status
router.get('/subscription-status', stripeController.getSubscriptionStatus);

// Cancel subscription
router.post('/cancel-subscription', stripeController.cancelSubscription);

module.exports = router;
