import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../app/theme.dart';
import '../../app/router.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/locale_service.dart';
import '../../core/constants/compliance_data.dart';
import '../../core/models/compliance_item_model.dart';
import '../../app/routes.dart';
import '../../shared/widgets/shared_widgets.dart';
import '../ai_assistant/ai_assistant_screen.dart';
import '../compliance_tracker/compliance_tracker_screen.dart';
import '../documents/my_documents_screen.dart';
import '../profile/profile_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedTab = 0;

  final List<Widget> _tabs = const [
    _HomeTab(),
    AiAssistantScreen(),
    MyDocumentsScreen(),
    ComplianceTrackerScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    return Scaffold(
      body: IndexedStack(
        index: _selectedTab,
        children: _tabs,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, -2))],
        ),
        child: SafeArea(
          child: BottomNavigationBar(
            currentIndex: _selectedTab,
            onTap: (i) => setState(() => _selectedTab = i),
            type: BottomNavigationBarType.fixed,
            backgroundColor: AppColors.surface,
            selectedItemColor: AppColors.primary,
            unselectedItemColor: AppColors.textSecondary,
            selectedFontSize: 11,
            unselectedFontSize: 11,
            items: [
              BottomNavigationBarItem(
                icon: const Icon(Icons.home_outlined), 
                activeIcon: const Icon(Icons.home), 
                label: lang == 'hi' ? 'होम' : 'Home'
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.smart_toy_outlined), 
                activeIcon: const Icon(Icons.smart_toy), 
                label: lang == 'hi' ? 'AI सहायक' : 'AI Assistant'
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.folder_outlined), 
                activeIcon: const Icon(Icons.folder), 
                label: lang == 'hi' ? 'दस्तावेज़' : 'Documents'
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.calendar_today_outlined), 
                activeIcon: const Icon(Icons.calendar_today), 
                label: lang == 'hi' ? 'अनुपालन' : 'Compliance'
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.person_outline), 
                activeIcon: const Icon(Icons.person), 
                label: lang == 'hi' ? 'प्रोफ़ाइल' : 'Profile'
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeTab extends ConsumerWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(languageProvider);
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverToBoxAdapter(child: _buildAppBar(context, ref, lang, userAsync)),

            // Greeting Card
            SliverToBoxAdapter(child: _buildGreetingCard(context, ref, lang, userAsync)),

            // Quick Actions
            SliverToBoxAdapter(child: _buildQuickActions(context, ref, lang)),

            // Compliance Alerts
            SliverToBoxAdapter(child: _buildComplianceAlerts(context, ref, lang)),

            // Legal Health Score
            SliverToBoxAdapter(child: _buildHealthScore(context, ref, lang)),

            // Legal News
            SliverToBoxAdapter(child: _buildLegalNews(context, lang)),

            // Recent Activity
            SliverToBoxAdapter(child: _buildRecentActivity(context, lang)),

            const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, WidgetRef ref, String lang, AsyncValue userAsync) {
    final user = userAsync.valueOrNull;
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const Text('⚖️', style: TextStyle(fontSize: 28)),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('VakilAI', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.primary)),
              Text(
                user?.businessProfile?.businessName ?? (lang == 'hi' ? 'मेरा बिज़नेस' : 'My Business'),
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            onPressed: () {},
            icon: Badge(
              label: const Text('3'),
              child: const Icon(Icons.notifications_outlined, color: AppColors.textPrimary),
            ),
          ),
          const LanguageToggle(),
        ],
      ),
    );
  }

  Widget _buildGreetingCard(BuildContext context, WidgetRef ref, String lang, AsyncValue userAsync) {
    final user = userAsync.valueOrNull;
    final name = user?.displayName?.split(' ').first ?? (lang == 'hi' ? 'दोस्त' : 'Friend');

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFF2A5A8C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lang == 'hi' ? 'नमस्ते, $name! 🙏' : 'Hello, $name! 🙏',
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                SubscriptionBadge(plan: user?.planName ?? 'free'),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    lang == 'hi'
                        ? '⚠️ GSTR-3B 6 दिन में due है'
                        : '⚠️ GSTR-3B due in 6 days',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Center(child: Text('⚖️', style: TextStyle(fontSize: 30))),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, WidgetRef ref, String lang) {
    final actions = [
      _QuickAction(
        emoji: '📄',
        labelHi: 'नोटिस अपलोड करें',
        labelEn: 'Upload Notice',
        bgColor: const Color(0xFFFFF3E0),
        accentColor: AppColors.warning,
        route: AppRoutes.documentAnalyzer,
      ),
      _QuickAction(
        emoji: '📝',
        labelHi: 'दस्तावेज़ बनाएं',
        labelEn: 'Create Document',
        bgColor: const Color(0xFFE8F5E9),
        accentColor: AppColors.success,
        route: AppRoutes.documentGenerator,
      ),
      _QuickAction(
        emoji: '🤖',
        labelHi: 'AI से पूछें',
        labelEn: 'Ask AI',
        bgColor: const Color(0xFFE8EEF5),
        accentColor: AppColors.primary,
        route: AppRoutes.aiAssistant,
      ),
      _QuickAction(
        emoji: '📅',
        labelHi: 'Compliance',
        labelEn: 'Compliance',
        bgColor: const Color(0xFFFBE9E7),
        accentColor: AppColors.error,
        route: AppRoutes.complianceTracker,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            titleHi: 'त्वरित कार्य',
            titleEn: 'Quick Actions',
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.5,
            children: actions.map((action) => GestureDetector(
              onTap: () => context.push(action.route),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: action.bgColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: action.accentColor.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(action.emoji, style: const TextStyle(fontSize: 24)),
                    const Spacer(),
                    Text(
                      lang == 'hi' ? action.labelHi : action.labelEn,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: action.accentColor,
                      ),
                    ),
                  ],
                ),
              ),
            )).toList(),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildComplianceAlerts(BuildContext context, WidgetRef ref, String lang) {
    final items = ComplianceData.getDefaultItems('user');
    final upcoming = items
        .where((i) => i.daysUntilDue >= 0 && i.daysUntilDue <= 30)
        .toList()
      ..sort((a, b) => a.daysUntilDue.compareTo(b.daysUntilDue));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            titleHi: 'आने वाली Deadlines',
            titleEn: 'Upcoming Deadlines',
            actionLabelHi: 'सभी देखें',
            actionLabelEn: 'See all',
            onAction: () => context.push(AppRoutes.complianceTracker),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: upcoming.take(5).length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final item = upcoming[index];
                return _buildComplianceAlertCard(item, lang);
              },
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildComplianceAlertCard(ComplianceItem item, String lang) {
    Color bgColor;
    Color textColor;
    if (item.daysUntilDue <= 7) {
      bgColor = AppColors.errorLight;
      textColor = AppColors.error;
    } else if (item.daysUntilDue <= 14) {
      bgColor = AppColors.warningLight;
      textColor = AppColors.warning;
    } else {
      bgColor = AppColors.successLight;
      textColor = AppColors.success;
    }

    return Container(
      width: 150,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: textColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(lang == 'hi' ? item.nameHindi : item.name,
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: textColor),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          const Spacer(),
          Text(
            item.daysUntilDue == 0
                ? (lang == 'hi' ? 'आज due है!' : 'Due today!')
                : (lang == 'hi' ? '${item.daysUntilDue} दिन बचे' : '${item.daysUntilDue} days left'),
            style: TextStyle(fontSize: 12, color: textColor, fontWeight: FontWeight.w500),
          ),
          Text(
            '${item.nextDueDate.day}/${item.nextDueDate.month}/${item.nextDueDate.year}',
            style: TextStyle(fontSize: 11, color: textColor.withOpacity(0.7)),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthScore(BuildContext context, WidgetRef ref, String lang) {
    const score = 72;
    const color = AppColors.warning;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: VakilCard(
        onTap: () {},
        child: Row(
          children: [
            SizedBox(
              width: 70,
              height: 70,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 70,
                    height: 70,
                    child: CircularProgressIndicator(
                      value: score / 100,
                      strokeWidth: 7,
                      backgroundColor: AppColors.border,
                      valueColor: const AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                  Text('$score', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 20, color: AppColors.textPrimary)),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lang == 'hi' ? 'कानूनी स्वास्थ्य स्कोर' : 'Legal Health Score',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    lang == 'hi'
                        ? '🔶 मध्यम — FSSAI update करें (+15 pts)'
                        : '🔶 Medium — Update FSSAI (+15 pts)',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 24)),
                    child: Text(lang == 'hi' ? 'सुधारें →' : 'Improve →',
                        style: const TextStyle(fontSize: 13, color: AppColors.primary)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegalNews(BuildContext context, String lang) {
    final news = [
      {'title': 'GST late fee waived for small taxpayers', 'titleHi': 'छोटे करदाताओं को GST late fee में राहत', 'category': 'GST', 'time': '2 दिन पहले'},
      {'title': 'MSME Samadhaan portal upgraded', 'titleHi': 'MSME समाधान पोर्टल अपग्रेड', 'category': 'MSME', 'time': '5 दिन पहले'},
    ];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            titleHi: 'कानूनी समाचार',
            titleEn: 'Legal News',
            actionLabelHi: 'और देखें',
            actionLabelEn: 'More',
          ),
          const SizedBox(height: 10),
          ...news.map((item) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(item['category']!, style: const TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    lang == 'hi' ? item['titleHi']! : item['title']!,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildRecentActivity(BuildContext context, String lang) {
    final activities = [
      {'icon': '📄', 'action': 'GST Notice analysed', 'actionHi': 'GST Notice का विश्लेषण हुआ', 'time': '2 घंटे पहले'},
      {'icon': '📝', 'action': 'Vendor Agreement generated', 'actionHi': 'Vendor Agreement बना', 'time': 'कल'},
      {'icon': '✅', 'action': 'GSTR-3B marked complete', 'actionHi': 'GSTR-3B पूरा किया', 'time': '3 दिन पहले'},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(titleHi: 'हाल की गतिविधि', titleEn: 'Recent Activity'),
          const SizedBox(height: 10),
          ...activities.map((a) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Center(child: Text(a['icon']!, style: const TextStyle(fontSize: 16))),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    lang == 'hi' ? a['actionHi']! : a['action']!,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                Text(a['time']!, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

class _QuickAction {
  final String emoji;
  final String labelHi;
  final String labelEn;
  final Color bgColor;
  final Color accentColor;
  final String route;

  const _QuickAction({
    required this.emoji,
    required this.labelHi,
    required this.labelEn,
    required this.bgColor,
    required this.accentColor,
    required this.route,
  });
}
