import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../app/routes.dart';
import '../../core/constants/compliance_data.dart';
import '../../core/services/locale_service.dart';
import '../../shared/widgets/shared_widgets.dart';

class DocumentGeneratorScreen extends ConsumerStatefulWidget {
  const DocumentGeneratorScreen({super.key});

  @override
  ConsumerState<DocumentGeneratorScreen> createState() =>
      _DocumentGeneratorScreenState();
}

class _DocumentGeneratorScreenState
    extends ConsumerState<DocumentGeneratorScreen> {
  String _selectedCategory = 'all';

  final Map<String, Map<String, String>> _categories = {
    'all': {'hi': 'सभी', 'en': 'All'},
    'agreements': {'hi': 'अनुबंध', 'en': 'Agreements'},
    'property': {'hi': 'संपत्ति', 'en': 'Property'},
    'notices': {'hi': 'नोटिस', 'en': 'Notices'},
    'hr': {'hi': 'HR', 'en': 'HR'},
    'business': {'hi': 'बिज़नेस', 'en': 'Business'},
  };

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final templates = ComplianceData.documentTemplates;
    final filtered = _selectedCategory == 'all'
        ? templates
        : templates.where((t) => t['category'] == _selectedCategory).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(lang == 'hi' ? 'दस्तावेज़ जनरेटर' : 'Document Generator'),
      ),
      body: Column(
        children: [
          // Category filter
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: _categories.entries.map((entry) {
                  final selected = _selectedCategory == entry.key;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedCategory = entry.key),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: selected ? AppColors.primary : AppColors.background,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: selected ? AppColors.primary : AppColors.border),
                        ),
                        child: Text(
                          lang == 'hi' ? entry.value['hi']! : entry.value['en']!,
                          style: TextStyle(
                            color: selected ? Colors.white : AppColors.textSecondary,
                            fontSize: 13,
                            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Info banner
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.infoLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Text('⚡', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    lang == 'hi'
                        ? 'AI द्वारा भारतीय कानून के अनुसार तैयार दस्तावेज़ — 2 मिनट में'
                        : 'AI-drafted documents per Indian law — ready in 2 minutes',
                    style: const TextStyle(fontSize: 13, color: AppColors.info),
                  ),
                ),
              ],
            ),
          ),

          // Templates grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.2,
              ),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final template = filtered[index];
                return _TemplateCard(
                  template: template,
                  lang: lang,
                  onTap: () => context.push(
                    AppRoutes.documentForm,
                    extra: {
                      'templateType': template['id'],
                      'templateName': lang == 'hi' ? template['nameHindi'] : template['name'],
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  final Map<String, dynamic> template;
  final String lang;
  final VoidCallback onTap;

  const _TemplateCard({
    required this.template,
    required this.lang,
    required this.onTap,
  });

  Color _getCategoryColor(String cat) {
    switch (cat) {
      case 'agreements': return const Color(0xFFE8EEF5);
      case 'property': return const Color(0xFFE8F5E9);
      case 'notices': return const Color(0xFFFFF3E0);
      case 'hr': return const Color(0xFFFBE9E7);
      case 'business': return const Color(0xFFF3E5F5);
      default: return AppColors.background;
    }
  }

  Color _getCategoryAccent(String cat) {
    switch (cat) {
      case 'agreements': return AppColors.primary;
      case 'property': return AppColors.success;
      case 'notices': return AppColors.warning;
      case 'hr': return AppColors.error;
      case 'business': return const Color(0xFF7B1FA2);
      default: return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cat = template['category'] as String;
    final bgColor = _getCategoryColor(cat);
    final accent = _getCategoryAccent(cat);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: accent.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(template['icon'] as String, style: const TextStyle(fontSize: 28)),
            const Spacer(),
            Text(
              lang == 'hi'
                  ? template['nameHindi'] as String
                  : template['name'] as String,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: accent,
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    lang == 'hi' ? 'AI बनाएं' : 'AI Draft',
                    style: TextStyle(fontSize: 10, color: accent, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
