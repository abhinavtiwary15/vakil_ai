import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/auth_service.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/auth/auth_screen.dart';
import '../features/auth/business_profile_setup_screen.dart';
import '../features/home/home_screen.dart';
import '../features/ai_assistant/ai_assistant_screen.dart';
import '../features/document_analyzer/document_analyzer_screen.dart';
import '../features/document_generator/document_generator_screen.dart';
import '../features/document_generator/document_form_screen.dart';
import '../features/compliance_tracker/compliance_tracker_screen.dart';
import '../features/legal_notice_responder/legal_notice_responder_screen.dart';
import '../features/subscription/subscription_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/documents/my_documents_screen.dart';
import '../features/home/splash_screen.dart';
import 'routes.dart';



final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final isGuest = ref.watch(guestModeProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    redirect: (context, state) {
      final isLoggedIn = authState.valueOrNull != null || isGuest;
      final isOnSplash = state.matchedLocation == AppRoutes.splash;
      final isOnboarding = state.matchedLocation == AppRoutes.onboarding;
      final isAuth = state.matchedLocation == AppRoutes.auth;

      if (isOnSplash || isOnboarding || isAuth) return null;
      if (!isLoggedIn) return AppRoutes.auth;
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.auth,
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        path: AppRoutes.businessSetup,
        builder: (context, state) => const BusinessProfileSetupScreen(),
      ),
      GoRoute(
        path: AppRoutes.subscription,
        builder: (context, state) => const SubscriptionScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.aiAssistant,
        builder: (context, state) => const AiAssistantScreen(),
      ),
      GoRoute(
        path: AppRoutes.documentAnalyzer,
        builder: (context, state) => const DocumentAnalyzerScreen(),
      ),
      GoRoute(
        path: AppRoutes.documentGenerator,
        builder: (context, state) => const DocumentGeneratorScreen(),
      ),
      GoRoute(
        path: AppRoutes.documentForm,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return DocumentFormScreen(
            templateType: extra?['templateType'] ?? 'vendor_agreement',
            templateName: extra?['templateName'] ?? 'Vendor Agreement',
          );
        },
      ),
      GoRoute(
        path: AppRoutes.complianceTracker,
        builder: (context, state) => const ComplianceTrackerScreen(),
      ),
      GoRoute(
        path: AppRoutes.legalNoticeResponder,
        builder: (context, state) => const LegalNoticeResponderScreen(),
      ),
      GoRoute(
        path: AppRoutes.profile,
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.myDocuments,
        builder: (context, state) => const MyDocumentsScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Page not found: ${state.error}')),
    ),
  );
});
