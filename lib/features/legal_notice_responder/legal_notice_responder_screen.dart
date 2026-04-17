import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme.dart';
import '../../core/services/ai_service.dart';
import '../../core/services/locale_service.dart';
import '../../core/models/compliance_item_model.dart';
import '../../shared/widgets/shared_widgets.dart';

final noticeResponderProvider =
    StateNotifierProvider<NoticeResponderNotifier, NoticeResponderState>(
        (ref) => NoticeResponderNotifier(ref));

class NoticeResponderState {
  final int step;
  final DocumentAnalysisResult? analysis;
  final String position;
  final String keyFacts;
  final String tone;
  final bool isDrafting;
  final String? draftResponse;

  const NoticeResponderState({
    this.step = 1,
    this.analysis,
    this.position = 'dispute',
    this.keyFacts = '',
    this.tone = 'firm',
    this.isDrafting = false,
    this.draftResponse,
  });

  NoticeResponderState copyWith({
    int? step,
    DocumentAnalysisResult? analysis,
    String? position,
    String? keyFacts,
    String? tone,
    bool? isDrafting,
    String? draftResponse,
  }) =>
      NoticeResponderState(
        step: step ?? this.step,
        analysis: analysis ?? this.analysis,
        position: position ?? this.position,
        keyFacts: keyFacts ?? this.keyFacts,
        tone: tone ?? this.tone,
        isDrafting: isDrafting ?? this.isDrafting,
        draftResponse: draftResponse ?? this.draftResponse,
      );
}

class NoticeResponderNotifier extends StateNotifier<NoticeResponderState> {
  final Ref _ref;
  NoticeResponderNotifier(this._ref) : super(const NoticeResponderState());

  void setAnalysis(DocumentAnalysisResult analysis) =>
      state = state.copyWith(step: 3, analysis: analysis);

  void setPosition(String p) => state = state.copyWith(position: p);
  void setTone(String t) => state = state.copyWith(tone: t);
  void setKeyFacts(String f) => state = state.copyWith(keyFacts: f);

  Future<void> draftResponse() async {
    if (state.analysis == null) return;
    final lang = _ref.read(languageProvider);
    state = state.copyWith(isDrafting: true, step: 4);

    try {
      final draft = await _ref.read(aiServiceProvider).draftNoticeResponse(
            analysis: state.analysis!,
            position: state.position,
            keyFacts: state.keyFacts,
            tone: state.tone,
            language: lang,
          );
      state = state.copyWith(isDrafting: false, draftResponse: draft, step: 5);
    } catch (e) {
      state = state.copyWith(isDrafting: false, step: 3);
    }
  }

  void reset() => state = const NoticeResponderState();
}

class LegalNoticeResponderScreen extends ConsumerStatefulWidget {
  const LegalNoticeResponderScreen({super.key});

  @override
  ConsumerState<LegalNoticeResponderScreen> createState() =>
      _LegalNoticeResponderScreenState();
}

class _LegalNoticeResponderScreenState
    extends ConsumerState<LegalNoticeResponderScreen> {
  final _keyFactsCtrl = TextEditingController();

  @override
  void dispose() {
    _keyFactsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final state = ref.watch(noticeResponderProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(lang == 'hi' ? 'नोटिस जवाब तैयार करें' : 'Draft Notice Response'),
        actions: [
          if (state.step > 1)
            TextButton(
              onPressed: () => ref.read(noticeResponderProvider.notifier).reset(),
              child: Text(lang == 'hi' ? 'रीसेट' : 'Reset',
                  style: const TextStyle(color: AppColors.error)),
            ),
        ],
      ),
      body: Column(
        children: [
          // Step progress bar
          _buildStepBar(state.step, lang),

          Expanded(
            child: state.isDrafting
                ? _buildDraftingScreen(lang)
                : [
                    _buildStep1(lang),
                    _buildStep2(lang, state),
                    _buildStep3(lang, state),
                    _buildDraftingScreen(lang),
                    _buildStep5(lang, state),
                  ][state.step - 1],
          ),
        ],
      ),
    );
  }

  Widget _buildStepBar(int currentStep, String lang) {
    final steps = lang == 'hi'
        ? ['अपलोड', 'विश्लेषण', 'विवरण', 'मसौदा', 'तैयार']
        : ['Upload', 'Analysis', 'Details', 'Draft', 'Ready'];

    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: List.generate(steps.length, (i) {
          final stepNum = i + 1;
          final isDone = stepNum < currentStep;
          final isCurrent = stepNum == currentStep;

          return Expanded(
            child: Row(
              children: [
                Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: isDone
                            ? AppColors.success
                            : isCurrent
                                ? AppColors.primary
                                : AppColors.border,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: isDone
                            ? const Icon(Icons.check, size: 14, color: Colors.white)
                            : Text(
                                '$stepNum',
                                style: TextStyle(
                                  color: isCurrent ? Colors.white : AppColors.textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(steps[i],
                        style: TextStyle(
                          fontSize: 10,
                          color: isCurrent ? AppColors.primary : AppColors.textSecondary,
                          fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
                        )),
                  ],
                ),
                if (i < steps.length - 1)
                  Expanded(
                    child: Container(
                      height: 2,
                      margin: const EdgeInsets.only(bottom: 16, left: 4, right: 4),
                      color: isDone ? AppColors.success : AppColors.border,
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStep1(String lang) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(lang == 'hi' ? 'नोटिस अपलोड करें' : 'Upload the Notice',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(
            lang == 'hi'
                ? 'जिस नोटिस का जवाब देना है उसे अपलोड करें'
                : 'Upload the notice you want to respond to',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),

          // Pricing info
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.secondary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.secondary.withOpacity(0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(lang == 'hi' ? '💰 ₹499 — एकल नोटिस जवाब' : '💰 ₹499 — Single Notice Response',
                    style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.secondary, fontSize: 15)),
                const SizedBox(height: 4),
                Text(
                  lang == 'hi'
                      ? '• AI द्वारा तैयार पूरा जवाब पत्र\n• सही धाराओं का उल्लेख\n• Saathi/Vakil plan में शामिल'
                      : '• Complete response letter by AI\n• Correct legal sections cited\n• Included in Saathi/Vakil plan',
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          GestureDetector(
            onTap: () => _loadMockAnalysis(),
            child: Container(
              width: double.infinity,
              height: 150,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withOpacity(0.5), width: 2),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('📤', style: TextStyle(fontSize: 40)),
                  const SizedBox(height: 10),
                  Text(lang == 'hi' ? 'नोटिस अपलोड करें' : 'Upload Notice',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.primary)),
                  Text('PDF, JPG, PNG • Max 10MB',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _UploadBtn(icon: Icons.folder_open, label: lang == 'hi' ? 'Files' : 'Files', onTap: _loadMockAnalysis)),
              const SizedBox(width: 10),
              Expanded(child: _UploadBtn(icon: Icons.camera_alt, label: 'Camera', onTap: _loadMockAnalysis)),
              const SizedBox(width: 10),
              Expanded(child: _UploadBtn(icon: Icons.photo, label: 'Gallery', onTap: _loadMockAnalysis)),
            ],
          ),
        ],
      ),
    );
  }

  void _loadMockAnalysis() {
    final mockResult = DocumentAnalysisResult(
      documentType: 'GST Demand Notice',
      documentTypeHindi: 'GST मांग नोटिस',
      issuingAuthority: 'GST Department, Rajasthan',
      noticeDate: DateTime.now().subtract(const Duration(days: 5)),
      responseDeadline: DateTime.now().add(const Duration(days: 25)),
      explanation: 'This is a GST demand notice under Section 73 CGST Act 2017.',
      explanationHindi: 'यह CGST अधिनियम 2017 की धारा 73 के तहत GST मांग नोटिस है।',
      keyPoints: ['Demand Amount: ₹45,000', 'Response Deadline: 30 days', 'Section 73 CGST Act'],
      keyPointsHindi: ['मांग राशि: ₹45,000', 'जवाब की समयसीमा: 30 दिन', 'CGST धारा 73'],
      actionSteps: ['Review GSTR filings', 'Prepare reconciliation', 'Submit response'],
      actionStepsHindi: ['GSTR फाइलिंग की समीक्षा करें', 'सुलह तैयार करें', 'जवाब जमा करें'],
      riskLevel: 'MEDIUM',
      demandAmount: 45000,
      relevantSection: 'Section 73 CGST Act 2017',
    );
    ref.read(noticeResponderProvider.notifier).setAnalysis(mockResult);
  }

  Widget _buildStep2(String lang, NoticeResponderState state) {
    final result = state.analysis;
    if (result == null) return const SizedBox.shrink();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(lang == 'hi' ? 'AI विश्लेषण' : 'AI Analysis',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),

          VakilCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('📄', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    Expanded(child: Text(lang == 'hi' ? result.documentTypeHindi : result.documentType,
                        style: const TextStyle(fontWeight: FontWeight.w600))),
                    RiskLevelBadge(level: result.riskLevel),
                  ],
                ),
                const Divider(height: 20),
                _InfoRow(label: lang == 'hi' ? 'जारीकर्ता:' : 'Issued by:', value: result.issuingAuthority),
                if (result.demandAmount != null)
                  _InfoRow(label: lang == 'hi' ? 'मांग राशि:' : 'Demand:', value: '₹${result.demandAmount!.toStringAsFixed(0)}'),
                if (result.responseDeadline != null)
                  _InfoRow(label: lang == 'hi' ? 'जवाब की समयसीमा:' : 'Response by:', value: '${result.responseDeadline!.day}/${result.responseDeadline!.month}/${result.responseDeadline!.year}'),
                if (result.relevantSection != null)
                  _InfoRow(label: lang == 'hi' ? 'धारा:' : 'Section:', value: result.relevantSection!),
              ],
            ),
          ),

          const SizedBox(height: 16),
          VakilButton(
            text: lang == 'hi' ? 'आगे बढ़ें — अपना जवाब दें' : 'Continue — Give Your Response',
            onPressed: () => ref.read(noticeResponderProvider.notifier)
                .state = state.copyWith(step: 3),
          ),
        ],
      ),
    );
  }

  Widget _buildStep3(String lang, NoticeResponderState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(lang == 'hi' ? 'आपका पक्ष' : 'Your Position',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),

          Text(lang == 'hi' ? 'आप इस नोटिस से:' : 'Regarding this notice you:',
              style: const TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 10),
          ...[
            {'val': 'agree', 'labelHi': '✅ सहमत हूं', 'labelEn': '✅ I agree'},
            {'val': 'dispute', 'labelHi': '❌ असहमत हूं', 'labelEn': '❌ I dispute'},
            {'val': 'partial', 'labelHi': '🔶 आंशिक सहमति', 'labelEn': '🔶 Partially agree'},
          ].map((opt) {
            final selected = state.position == opt['val'];
            return GestureDetector(
              onTap: () => ref.read(noticeResponderProvider.notifier).setPosition(opt['val']!),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary.withOpacity(0.1) : AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: selected ? AppColors.primary : AppColors.border, width: selected ? 2 : 1),
                ),
                child: Text(lang == 'hi' ? opt['labelHi']! : opt['labelEn']!,
                    style: TextStyle(color: selected ? AppColors.primary : AppColors.textPrimary, fontWeight: selected ? FontWeight.w600 : FontWeight.w400)),
              ),
            );
          }),

          const SizedBox(height: 16),
          Text(lang == 'hi' ? 'मुख्य तथ्य (वैकल्पिक)' : 'Key Facts (Optional)',
              style: const TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          TextFormField(
            controller: _keyFactsCtrl,
            maxLines: 4,
            onChanged: (v) => ref.read(noticeResponderProvider.notifier).setKeyFacts(v),
            decoration: InputDecoration(
              hintText: lang == 'hi'
                  ? 'अपनी बात यहाँ लिखें जैसे: payment already made on 15 Jan...'
                  : 'Add your facts here e.g. payment already made on 15 Jan...',
            ),
          ),
          const SizedBox(height: 16),

          Text(lang == 'hi' ? 'जवाब का tone:' : 'Response Tone:',
              style: const TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              {'val': 'cooperative', 'labelHi': 'सहयोगी', 'labelEn': 'Cooperative'},
              {'val': 'firm', 'labelHi': 'दृढ़', 'labelEn': 'Firm'},
              {'val': 'neutral', 'labelHi': 'तटस्थ', 'labelEn': 'Neutral'},
            ].map((t) {
              final selected = state.tone == t['val'];
              return ChoiceChip(
                label: Text(lang == 'hi' ? t['labelHi']! : t['labelEn']!),
                selected: selected,
                selectedColor: AppColors.primary.withOpacity(0.15),
                onSelected: (_) => ref.read(noticeResponderProvider.notifier).setTone(t['val']!),
              );
            }).toList(),
          ),

          const SizedBox(height: 24),
          VakilButton(
            text: lang == 'hi' ? '🤖 AI से जवाब तैयार करवाएं' : '🤖 Generate Response with AI',
            onPressed: () => ref.read(noticeResponderProvider.notifier).draftResponse(),
          ),
        ],
      ),
    );
  }

  Widget _buildDraftingScreen(String lang) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('✍️', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 20),
          Text(lang == 'hi' ? 'जवाब तैयार हो रहा है...' : 'Drafting response...',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(
            lang == 'hi'
                ? 'AI कानूनी भाषा में आपका जवाब तैयार कर रहा है'
                : 'AI is drafting your response in proper legal language',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 32),
          const CircularProgressIndicator(color: AppColors.primary),
        ],
      ),
    );
  }

  Widget _buildStep5(String lang, NoticeResponderState state) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.successLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: AppColors.success),
                      const SizedBox(width: 8),
                      Text(lang == 'hi' ? 'जवाब पत्र तैयार है ✓' : 'Response letter ready ✓',
                          style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: SelectableText(
                    state.draftResponse ?? '',
                    style: const TextStyle(fontSize: 13, height: 1.7),
                  ),
                ),
              ],
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          color: AppColors.surface,
          child: Column(
            children: [
              VakilButton(
                text: lang == 'hi' ? '📄 PDF Download करें' : '📄 Download PDF',
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(lang == 'hi' ? 'PDF तैयार हो रहा है...' : 'Preparing PDF...')),
                ),
              ),
              const SizedBox(height: 10),
              VakilButton(
                text: lang == 'hi' ? '⚖️ वकील से Review करवाएं' : '⚖️ Get Lawyer Review',
                onPressed: () {},
                isOutlined: true,
                backgroundColor: null,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
          const SizedBox(width: 8),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}

class _UploadBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _UploadBtn({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 20),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}
