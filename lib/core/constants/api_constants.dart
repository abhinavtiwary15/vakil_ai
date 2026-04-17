class ApiConstants {
  /// The base URL for the production API.
  /// IMPORTANT: Ensure your backend is running at this address.
  static const String baseUrl = 'https://api.vakilai.in/v1';

  // Endpoints
  static const String analyzeDocument = '/analyze-document';
  static const String aiChat = '/ai-chat';
  static const String generateDocument = '/generate-document';
  static const String complianceCalendar = '/compliance-calendar';
  static const String draftNoticeResponse = '/draft-notice-response';
  static const String legalNewsFeed = '/legal-news-feed';
  static const String userProfile = '/user/profile';
  static const String createSubscription = '/subscriptions/create';
  static const String verifySubscription = '/subscriptions/verify';
  static const String legalHealthScore = '/health-score';

  // Timeouts
  static const int connectTimeout = 15000;
  static const int receiveTimeout = 30000;

  // File limits
  static const int maxFileSizeMB = 10;
  static const int maxFileSizeBytes = 10 * 1024 * 1024;

  // Plan limits
  static const int freeAiQuestions = 3;
  static const int saathiAiQuestions = 50;
  static const int freeDocGenerations = 1;
  static const int saathiDocGenerations = 10;
}

class RazorpayConstants {
  /// IMPORTANT: Replace with your actual Razorpay Key ID from the Dashboard.
  /// You can find this in Settings -> API Keys.
  static const String keyId = 'rzp_test_YOUR_KEY_HERE';
  
  static const String saathiPlanId = 'plan_saathi_999';
  static const String vakilPlanId = 'plan_vakil_2499';
  static const int saathiAmount = 99900; // in paise
  static const int vakilAmount = 249900;
  static const int singleNoticeAmount = 49900;
  static const String currency = 'INR';
  static const String companyName = 'VakilAI';
  static const String companyLogoUrl = 'https://vakilai.in/logo.png';
}
