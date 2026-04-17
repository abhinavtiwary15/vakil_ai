import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../app/theme.dart';
import '../../app/router.dart';
import '../../app/routes.dart';
import '../../shared/widgets/shared_widgets.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_OnboardingSlide> _slides = const [
    _OnboardingSlide(
      emoji: '😰',
      titleHi: 'नोटिस आए तो क्या करें?',
      titleEn: 'What to do when notices arrive?',
      subtitleHi: 'GST, FSSAI, labour notices — हर बिज़नेसमैन परेशान होता है। अब नहीं।',
      subtitleEn: 'GST, FSSAI, labour notices — every businessman worries. Not anymore.',
      bgColor: Color(0xFFFFF3E0),
      accentColor: Color(0xFFF57C00),
      items: ['GST Notice', 'FSSAI Order', 'Labour Dept', 'Income Tax'],
    ),
    _OnboardingSlide(
      emoji: '🤖',
      titleHi: 'हर नोटिस का जवाब सरल भाषा में',
      titleEn: 'Every notice explained in simple language',
      subtitleHi: 'कोई भी नोटिस अपलोड करें। सेकंड में हिंदी में पूरी जानकारी पाएं।',
      subtitleEn: 'Upload any notice. Get complete information in Hindi in seconds.',
      bgColor: Color(0xFFE8F5E9),
      accentColor: Color(0xFF2E7D32),
      items: ['अपलोड करें', 'AI विश्लेषण', 'सरल हिंदी', 'कदम-दर-कदम'],
    ),
    _OnboardingSlide(
      emoji: '✅',
      titleHi: '₹999/महीना में पूरा कानूनी सहारा',
      titleEn: 'Complete legal support at ₹999/month',
      subtitleHi: 'हर साल ₹10,000+ जुर्माने से बचें। Compliance कभी miss न करें।',
      subtitleEn: 'Save ₹10,000+ in penalties every year. Never miss a compliance.',
      bgColor: Color(0xFFE8EEF5),
      accentColor: Color(0xFF1A3C5E),
      items: ['GST Deadlines', 'PF & ESI', 'Document Vault', 'AI 24/7'],
    ),
  ];

  void _nextPage() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finishOnboarding();
    }
  }

  Future<void> _finishOnboarding() async {
    final box = await Hive.openBox('settings');
    await box.put('hasSeenOnboarding', true);
    if (mounted) context.go(AppRoutes.auth);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Padding(
              padding: const EdgeInsets.only(right: 16, top: 8),
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _finishOnboarding,
                  child: const Text('Skip', style: TextStyle(color: AppColors.textSecondary)),
                ),
              ),
            ),

            // Page view
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemCount: _slides.length,
                itemBuilder: (context, index) => _buildSlide(_slides[index]),
              ),
            ),

            // Dots and button
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Dot indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _slides.length,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == i ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == i
                              ? AppColors.primary
                              : AppColors.primary.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // CTA button
                  VakilButton(
                    text: _currentPage == _slides.length - 1
                        ? 'शुरू करें / Get Started'
                        : 'आगे बढ़ें / Next',
                    onPressed: _nextPage,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlide(_OnboardingSlide slide) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Illustration area
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: slide.bgColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(slide.emoji, style: const TextStyle(fontSize: 80)),
            ),
          ),

          const SizedBox(height: 16),

          // Floating chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: slide.items.map((item) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: slide.accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: slide.accentColor.withOpacity(0.3)),
              ),
              child: Text(
                item,
                style: TextStyle(
                  color: slide.accentColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            )).toList(),
          ),

          const SizedBox(height: 32),

          Text(
            slide.titleHi,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            slide.titleEn,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            slide.subtitleHi,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingSlide {
  final String emoji;
  final String titleHi;
  final String titleEn;
  final String subtitleHi;
  final String subtitleEn;
  final Color bgColor;
  final Color accentColor;
  final List<String> items;

  const _OnboardingSlide({
    required this.emoji,
    required this.titleHi,
    required this.titleEn,
    required this.subtitleHi,
    required this.subtitleEn,
    required this.bgColor,
    required this.accentColor,
    required this.items,
  });
}
