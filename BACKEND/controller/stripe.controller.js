const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);
const UserModel = require('../model/user.model');

// Create checkout session for subscription
exports.createCheckoutSession = async (req, res) => {
    try {
        const { email } = req.body;

        const user = await UserModel.findOne({ email });
        if (!user) {
            return res.status(404).json({ message: 'User not found' });
        }

        // Create or retrieve Stripe customer
        let customerId = user.stripeCustomerId;
        if (!customerId) {
            const customer = await stripe.customers.create({
                email: user.email,
                metadata: {
                    userId: user._id.toString()
                }
            });
            customerId = customer.id;
            user.stripeCustomerId = customerId;
            await user.save();
        }

        // Create checkout session
        const session = await stripe.checkout.sessions.create({
            customer: customerId,
            payment_method_types: ['card'],
            line_items: [
                {
                    price: process.env.STRIPE_PRICE_ID,
                    quantity: 1,
                },
            ],
            mode: 'subscription',
            success_url: `${req.headers.origin || 'http://localhost:3000'}/success?session_id={CHECKOUT_SESSION_ID}`,
            cancel_url: `${req.headers.origin || 'http://localhost:3000'}/cancel`,
        });

        res.json({ sessionId: session.id, url: session.url });
    } catch (error) {
        console.error('Stripe checkout error:', error);
        res.status(500).json({ message: 'Failed to create checkout session', error: error.message });
    }
};

// Handle Stripe webhooks
exports.handleWebhook = async (req, res) => {
    const sig = req.headers['stripe-signature'];
    let event;

    try {
        event = stripe.webhooks.constructEvent(
            req.body,
            sig,
            process.env.STRIPE_WEBHOOK_SECRET
        );
    } catch (err) {
        console.error('Webhook signature verification failed:', err.message);
        return res.status(400).send(`Webhook Error: ${err.message}`);
    }

    // Handle the event
    switch (event.type) {
        case 'customer.subscription.created':
        case 'customer.subscription.updated':
            await handleSubscriptionUpdate(event.data.object);
            break;
        case 'customer.subscription.deleted':
            await handleSubscriptionCancellation(event.data.object);
            break;
        default:
            console.log(`Unhandled event type ${event.type}`);
    }

    res.json({ received: true });
};

// Get subscription status
exports.getSubscriptionStatus = async (req, res) => {
    try {
        const { email } = req.query;

        const user = await UserModel.findOne({ email });
        if (!user) {
            return res.status(404).json({ message: 'User not found' });
        }

        res.json({
            isPremium: user.isPremium,
            subscriptionStatus: user.subscriptionStatus,
            subscriptionEndDate: user.subscriptionEndDate
        });
    } catch (error) {
        console.error('Get subscription status error:', error);
        res.status(500).json({ message: 'Failed to get subscription status', error: error.message });
    }
};

// Cancel subscription
exports.cancelSubscription = async (req, res) => {
    try {
        const { email } = req.body;

        const user = await UserModel.findOne({ email });
        if (!user || !user.stripeSubscriptionId) {
            return res.status(404).json({ message: 'No active subscription found' });
        }

        await stripe.subscriptions.cancel(user.stripeSubscriptionId);

        res.json({ message: 'Subscription cancelled successfully' });
    } catch (error) {
        console.error('Cancel subscription error:', error);
        res.status(500).json({ message: 'Failed to cancel subscription', error: error.message });
    }
};

// Helper function to handle subscription updates
async function handleSubscriptionUpdate(subscription) {
    try {
        const user = await UserModel.findOne({ stripeCustomerId: subscription.customer });
        if (user) {
            user.stripeSubscriptionId = subscription.id;
            user.subscriptionStatus = subscription.status;
            user.isPremium = subscription.status === 'active' || subscription.status === 'trialing';
            user.subscriptionEndDate = new Date(subscription.current_period_end * 1000);
            await user.save();
        }
    } catch (error) {
        console.error('Error updating subscription:', error);
    }
}

// Helper function to handle subscription cancellation
async function handleSubscriptionCancellation(subscription) {
    try {
        const user = await UserModel.findOne({ stripeCustomerId: subscription.customer });
        if (user) {
            user.subscriptionStatus = 'canceled';
            user.isPremium = false;
            await user.save();
        }
    } catch (error) {
        console.error('Error handling subscription cancellation:', error);
    }
}
