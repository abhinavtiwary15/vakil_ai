---
title: Vakil AI
emoji: ⚖️
colorFrom: blue
colorTo: yellow
sdk: static
pinned: false
---
# VakilAI — Your Business Lawyer at ₹999/month

AI-powered legal assistant for India's 73 million MSMEs.

## 🚀 Quick Start

```bash
# 1. Install Flutter 3.19+
# 2. Clone this repo
cd vakilai

# 3. Get dependencies
flutter pub get

# 4. Add Firebase config files:
#    android/app/google-services.json
#    ios/Runner/GoogleService-Info.plist

# 5. Run the app
flutter run
```

## 📁 Project Structure

```
lib/
├── app/                  # App setup (router, theme, material app)
├── core/
│   ├── constants/        # Strings, API endpoints, compliance data
│   ├── models/           # All data models
│   ├── services/         # Firebase, AI, payment, notification services
│   └── utils/            # Helpers, validators, formatters
├── features/             # One folder per screen
│   ├── onboarding/       # 3-slide intro
│   ├── auth/             # Phone OTP + Google auth + business setup
│   ├── home/             # Dashboard with health score
│   ├── ai_assistant/     # Chat interface
│   ├── document_analyzer/# Upload + OCR + AI analysis
│   ├── document_generator/ # 20+ template generator
│   ├── compliance_tracker/ # Calendar + deadline manager
│   ├── legal_notice_responder/ # 5-step notice response
│   ├── subscription/     # Plans + Razorpay
│   ├── profile/          # Settings + preferences
│   ├── documents/        # Document vault
│   ├── payment_recovery/ # MSME payment recovery
│   └── legal_news/       # Personalized legal news
└── shared/
    ├── widgets/          # Reusable UI components
    ├── extensions/       # Dart extensions
    └── providers/        # Global Riverpod providers
```

## 🔧 Configuration

### Firebase
1. Create a Firebase project at console.firebase.google.com
2. Enable Phone Auth + Google Auth
3. Add your app (Android + iOS)
4. Download and add config files

### Razorpay
Update `lib/core/constants/api_constants.dart`:
```dart
static const String razorpayKey = 'rzp_live_YOUR_KEY';
```

### Backend API
Update `lib/core/constants/api_constants.dart`:
```dart
static const String baseUrl = 'https://your-api.vakilai.in/v1';
```

## 📦 Key Dependencies

| Package | Purpose |
|---------|---------|
| flutter_riverpod | State management |
| go_router | Navigation |
| firebase_auth | Authentication |
| dio | HTTP client |
| fl_chart | Charts |
| table_calendar | Compliance calendar |
| flutter_animate | Smooth animations |
| lottie | Loading animations |
| google_fonts | Syne + DM Sans typography |

## 🎨 Design System

- **Primary**: #0A1628 (Deep Navy)
- **Accent**: #F59E0B (Saffron Gold)  
- **Success**: #10B981
- **Error**: #EF4444
- **Font**: Syne (display) + DM Sans (body)

## 📜 License
Proprietary — All rights reserved, VakilAI Pvt Ltd
