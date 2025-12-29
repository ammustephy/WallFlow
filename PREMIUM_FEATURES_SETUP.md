# WallFlow Premium Features Setup Guide

## Overview
This guide will help you set up the premium features including AI image generation, custom wallpaper creator, and Stripe payment integration.

## Prerequisites
- Node.js and npm installed
- Flutter SDK installed
- Stripe account (for payment processing)
- Google Gemini API key (for AI features)

## Backend Setup

### 1. Install Dependencies
```bash
cd BACKEND
npm install
```

The following packages will be installed:
- `stripe` - Payment processing
- `@google/generative-ai` - Google Gemini AI SDK
- `multer` - File upload handling

### 2. Configure Environment Variables
Edit `BACKEND/.env` and add your API keys:

```env
MONGODB_URI=mongodb+srv://stephyrn06_db_user:May131997@wallflow.n9ptyw6.mongodb.net/WallFlow?retryWrites=true&w=majority&appName=WallFlow
PORT=3000
JWT_SECRET=supersecretkey123

# Stripe Configuration
STRIPE_SECRET_KEY=sk_test_your_stripe_secret_key_here
STRIPE_PUBLISHABLE_KEY=pk_test_your_stripe_publishable_key_here
STRIPE_WEBHOOK_SECRET=whsec_your_webhook_secret_here
STRIPE_PRICE_ID=price_your_monthly_price_id_here

# Google Gemini AI Configuration
GOOGLE_GEMINI_API_KEY=your_gemini_api_key_here
```

### 3. Get API Keys

#### Stripe API Keys:
1. Go to https://dashboard.stripe.com/
2. Navigate to Developers > API keys
3. Copy your Publishable key and Secret key
4. Create a Product and Price for monthly subscription
5. Copy the Price ID

#### Google Gemini API Key:
1. Go to https://makersuite.google.com/app/apikey
2. Create a new API key
3. Copy the key

### 4. Update Backend URL in Flutter Services
In the Flutter app, update the `baseUrl` in these files:
- `lib/services/stripe_service.dart`
- `lib/services/ai_service.dart`
- `lib/services/custom_wallpaper_service.dart`

Replace `YOUR_BACKEND_URL` with your actual backend URL (e.g., `http://localhost:3000` or your ngrok URL).

### 5. Start the Backend
```bash
cd BACKEND
npm run dev
```

## Flutter Setup

### 1. Install Dependencies
```bash
flutter pub get
```

New dependencies added:
- `flutter_stripe` - Stripe payment integration
- `google_generative_ai` - Google Gemini AI
- `image` - Image manipulation
- `flutter_colorpicker` - Color picker for custom creator

### 2. Run the App
```bash
flutter run
```

## Features

### 1. AI Wallpaper Generation
- Navigate to **AI Generator** from the drawer menu
- Enter a text prompt describing your desired wallpaper
- Get AI-powered suggestions for creative prompts
- Generate stunning wallpapers using Google Gemini AI
- Premium feature (requires subscription)

### 2. Custom Wallpaper Creator
- Navigate to **Custom Creator** from the drawer menu
- Choose a background image or color
- Add text with customizable fonts, sizes, and colors
- Add shapes (rectangles, circles)
- Apply filters (brightness, contrast, saturation)
- Save your custom creations
- Premium feature (requires subscription)

### 3. Premium Subscription
- Navigate to **Premium** from the drawer menu
- View all premium features and pricing
- Subscribe using Stripe checkout
- Manage your subscription (cancel, view status)
- Monthly subscription at ₹99/month

### 4. Premium Access Control
- Non-premium users see lock icons on premium features
- Attempting to access premium features shows a paywall dialog
- Premium status is synced across the app

## API Endpoints

### Stripe Endpoints
- `POST /api/stripe/create-checkout-session` - Create Stripe checkout
- `POST /api/stripe/webhook` - Handle Stripe webhooks
- `GET /api/stripe/subscription-status` - Get subscription status
- `POST /api/stripe/cancel-subscription` - Cancel subscription

### AI Endpoints
- `POST /api/ai/generate-wallpaper` - Generate wallpaper from prompt
- `POST /api/ai/suggest-prompts` - Get AI prompt suggestions
- `GET /api/ai/my-generated` - Get user's generated wallpapers
- `DELETE /api/ai/generated/:id` - Delete generated wallpaper

### Custom Wallpaper Endpoints
- `POST /api/wallpaper/save-custom` - Save custom wallpaper
- `GET /api/wallpaper/my-custom` - Get user's custom wallpapers
- `DELETE /api/wallpaper/custom/:id` - Delete custom wallpaper

## Testing

### Test Stripe Payment (Test Mode)
Use Stripe test cards:
- Card number: `4242 4242 4242 4242`
- Expiry: Any future date
- CVC: Any 3 digits
- ZIP: Any 5 digits

### Test AI Generation
1. Make sure your Google Gemini API key is valid
2. Try prompts like:
   - "A serene mountain landscape at sunset"
   - "Abstract geometric patterns in vibrant colors"
   - "Cosmic nebula with stars and galaxies"

## Troubleshooting

### Backend Issues
- **Port already in use**: Change PORT in `.env`
- **MongoDB connection error**: Check MONGODB_URI
- **Stripe webhook not working**: Use Stripe CLI for local testing

### Flutter Issues
- **Dependencies not found**: Run `flutter pub get`
- **Build errors**: Run `flutter clean` then `flutter pub get`
- **API connection failed**: Check backend URL in service files

## Notes
- All premium features preserve the existing UI style
- The UI uses the same color scheme and design patterns
- Premium badges and lock icons are added subtly
- Subscription status is checked on app startup and login

## Support
For issues or questions, please refer to the implementation plan or contact support.
