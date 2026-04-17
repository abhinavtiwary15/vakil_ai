import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../app/routes.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/locale_service.dart';
import '../../shared/widgets/shared_widgets.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _gstNotifications = true;
  bool _pfNotifications = true;
  bool _esiNotifications = true;
  bool _whatsappNotifications = false;
  bool _darkMode = false;

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final userAsync = ref.watch(currentUserProvider);
    final user = userAsync.valueOrNull;
    final profile = user?.businessProfile;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(lang == 'hi' ? 'प्रोफाइल' : 'Profile'),
        actions: [const LanguageToggle(), const SizedBox(width: 12)],
      ),
      body: ListView(
        children: [
          // Profile header
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 2),
                  ),
                  child: const Center(child: Text('🏢', style: TextStyle(fontSize: 28))),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(profile?.businessName ?? 'My Business',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                      Text('${profile?.businessType ?? ''} • ${profile?.city ?? ''}',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                      const SizedBox(height: 4),
                      SubscriptionBadge(plan: user?.planName ?? 'free'),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
                  onPressed: () {},
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Business Profile Section
          _buildSection(
            lang == 'hi' ? 'बिज़नेस प्रोफाइल' : 'Business Profile',
            [
              _SettingsTile(
                icon: Icons.business,
                labelHi: 'बिज़नेस का नाम',
                labelEn: 'Business Name',
                value: profile?.businessName ?? '-',
                lang: lang,
                onTap: () {},
              ),
              _SettingsTile(
                icon: Icons.category,
                labelHi: 'उद्योग',
                labelEn: 'Industry',
                value: profile?.industry ?? '-',
                lang: lang,
                onTap: () {},
              ),
              _SettingsTile(
                icon: Icons.location_on,
                labelHi: 'शहर / राज्य',
                labelEn: 'City / State',
                value: '${profile?.city ?? ''}, ${profile?.state ?? ''}',
                lang: lang,
                onTap: () {},
              ),
              _SettingsTile(
                icon: Icons.receipt,
                labelHi: 'GSTIN',
                labelEn: 'GSTIN',
                value: profile?.gstin ?? (lang == 'hi' ? 'नहीं जोड़ा' : 'Not added'),
                lang: lang,
                onTap: () {},
              ),
              _SettingsTile(
                icon: Icons.badge,
                labelHi: 'PAN',
                labelEn: 'PAN',
                value: profile?.pan ?? (lang == 'hi' ? 'नहीं जोड़ा' : 'Not added'),
                lang: lang,
                onTap: () {},
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Subscription Section
          _buildSection(
            lang == 'hi' ? 'सब्सक्रिप्शन' : 'Subscription',
            [
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    SubscriptionBadge(plan: user?.planName ?? 'free'),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(lang == 'hi' ? 'वर्तमान प्लान' : 'Current Plan',
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          Text(
                            user?.planName == 'saathi' ? 'Saathi — ₹999/month' :
                            user?.planName == 'vakil' ? 'Vakil — ₹2,499/month' : 'Free Plan',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.push(AppRoutes.subscription),
                      child: Text(lang == 'hi' ? 'अपग्रेड' : 'Upgrade',
                          style: const TextStyle(color: AppColors.primary, fontSize: 13)),
                    ),
                  ],
                ),
              ),
              _SettingsTile(
                icon: Icons.history,
                labelHi: 'भुगतान इतिहास',
                labelEn: 'Payment History',
                lang: lang, onTap: () {},
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Preferences
          _buildSection(
            lang == 'hi' ? 'प्राथमिकताएं' : 'Preferences',
            [
              _ToggleTile(
                icon: Icons.notifications,
                labelHi: 'GST Reminders',
                labelEn: 'GST Reminders',
                value: _gstNotifications,
                lang: lang,
                onChanged: (v) => setState(() => _gstNotifications = v),
              ),
              _ToggleTile(
                icon: Icons.notifications,
                labelHi: 'PF & ESI Reminders',
                labelEn: 'PF & ESI Reminders',
                value: _pfNotifications,
                lang: lang,
                onChanged: (v) => setState(() => _pfNotifications = v),
              ),
              _ToggleTile(
                icon: Icons.message,
                labelHi: 'WhatsApp Reminders',
                labelEn: 'WhatsApp Reminders',
                value: _whatsappNotifications,
                lang: lang,
                onChanged: (v) => setState(() => _whatsappNotifications = v),
              ),
              // Language toggle
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    const Icon(Icons.language, color: AppColors.primary, size: 20),
                    const SizedBox(width: 14),
                    Expanded(child: Text(lang == 'hi' ? 'भाषा' : 'Language',
                        style: const TextStyle(fontSize: 14))),
                    Row(
                      children: ['hi', 'en'].map((l) {
                        final selected = lang == l;
                        return GestureDetector(
                          onTap: () => ref.read(localeProvider.notifier).setLocale(l),
                          child: Container(
                            margin: const EdgeInsets.only(left: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: selected ? AppColors.primary : AppColors.background,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: selected ? AppColors.primary : AppColors.border),
                            ),
                            child: Text(l == 'hi' ? 'हिंदी' : 'English',
                                style: TextStyle(fontSize: 12, color: selected ? Colors.white : AppColors.textSecondary)),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Help & Support
          _buildSection(
            lang == 'hi' ? 'सहायता' : 'Help & Support',
            [
              _SettingsTile(icon: Icons.help_outline, labelHi: 'FAQ', labelEn: 'FAQ', lang: lang, onTap: () => _showFAQ(context, lang)),
               _SettingsTile(icon: Icons.message, labelHi: 'WhatsApp Support', labelEn: 'WhatsApp Support', lang: lang, onTap: () {}),
              _SettingsTile(icon: Icons.bug_report_outlined, labelHi: 'Bug Report करें', labelEn: 'Report a Bug', lang: lang, onTap: () {}),
              _SettingsTile(icon: Icons.star_outline, labelHi: 'App को Rate करें', labelEn: 'Rate the App', lang: lang, onTap: () {}),
            ],
          ),

          const SizedBox(height: 8),

          // Legal
          _buildSection(
            lang == 'hi' ? 'कानूनी' : 'Legal',
            [
              _SettingsTile(icon: Icons.description_outlined, labelHi: 'नियम और शर्तें', labelEn: 'Terms of Service', lang: lang, onTap: () {}),
              _SettingsTile(icon: Icons.privacy_tip_outlined, labelHi: 'गोपनीयता नीति', labelEn: 'Privacy Policy', lang: lang, onTap: () {}),
              _SettingsTile(icon: Icons.info_outline, labelHi: 'Disclaimer', labelEn: 'Disclaimer', lang: lang, onTap: () {}),
              _SettingsTile(
                icon: Icons.apps,
                labelHi: 'App Version',
                labelEn: 'App Version',
                value: 'v1.0.0',
                lang: lang,
                onTap: () {},
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Logout
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextButton(
              onPressed: () => _showLogoutDialog(context, lang),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.error,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: AppColors.error, width: 1),
                ),
              ),
              child: Text(lang == 'hi' ? '🚪 लॉग आउट' : '🚪 Logout',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      color: AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: Text(title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.5,
                )),
          ),
          ...children,
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, String lang) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(lang == 'hi' ? 'लॉग आउट करें?' : 'Logout?'),
        content: Text(lang == 'hi'
            ? 'क्या आप VakilAI से लॉग आउट करना चाहते हैं?'
            : 'Are you sure you want to logout from VakilAI?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(lang == 'hi' ? 'रद्द' : 'Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(authServiceProvider).signOut();
              if (context.mounted) context.go(AppRoutes.auth);
            },
            child: Text(lang == 'hi' ? 'लॉग आउट' : 'Logout',
                style: const TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  void _showFAQ(BuildContext context, String lang) {
    final faqs = [
      {'q': 'GST notice कब आता है?', 'a': 'GSTR-1 और GSTR-3B में अंतर होने पर, late filing पर, या tax mismatch पर GST notice आता है।'},
      {'q': 'FSSAI license के बिना क्या हो सकता है?', 'a': 'बिना FSSAI के food business करने पर ₹5 लाख तक जुर्माना और 6 महीने की सज़ा हो सकती है।'},
      {'q': 'PF कटौती कितनी होती है?', 'a': 'Employee का 12% + Employer का 12% (8.33% EPS + 3.67% EPF) कुल 24% PF contribution होती है।'},
      {'q': 'MSME में payment delay पर क्या होता है?', 'a': 'MSMED Act 2006 के तहत 45 दिन से ज़्यादा देरी पर 3× bank rate ब्याज मिलता है।'},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        expand: false,
        builder: (_, controller) => ListView.builder(
          controller: controller,
          padding: const EdgeInsets.all(16),
          itemCount: faqs.length + 1,
          itemBuilder: (context, i) {
            if (i == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text('FAQ', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              );
            }
            final faq = faqs[i - 1];
            return ExpansionTile(
              title: Text(faq['q']!, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Text(faq['a']!, style: const TextStyle(color: AppColors.textSecondary, height: 1.5)),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String labelHi;
  final String labelEn;
  final String? value;
  final String lang;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.labelHi,
    required this.labelEn,
    this.value,
    required this.lang,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary, size: 20),
      title: Text(lang == 'hi' ? labelHi : labelEn, style: const TextStyle(fontSize: 14)),
      trailing: value != null
          ? Text(value!, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary))
          : const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textSecondary),
      onTap: onTap,
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  final IconData icon;
  final String labelHi;
  final String labelEn;
  final bool value;
  final String lang;
  final ValueChanged<bool> onChanged;

  const _ToggleTile({
    required this.icon,
    required this.labelHi,
    required this.labelEn,
    required this.value,
    required this.lang,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      secondary: Icon(icon, color: AppColors.primary, size: 20),
      title: Text(lang == 'hi' ? labelHi : labelEn, style: const TextStyle(fontSize: 14)),
      value: value,
      onChanged: onChanged,
      activeColor: AppColors.primary,
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
    );
  }
}
