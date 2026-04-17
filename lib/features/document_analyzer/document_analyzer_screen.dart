import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../app/routes.dart';
import '../../core/services/ai_service.dart';
import '../../core/services/locale_service.dart';
import '../../core/models/compliance_item_model.dart';
import '../../core/constants/api_constants.dart';
import '../../shared/widgets/shared_widgets.dart';

final documentAnalysisProvider =
    StateNotifierProvider<DocumentAnalysisNotifier, DocumentAnalysisState>(
        (ref) => DocumentAnalysisNotifier(ref));

class DocumentAnalysisState {
  final bool isAnalyzing;
  final int analysisStep; // 0=idle, 1=reading, 2=understanding, 3=done
  final String? selectedDocType;
  final File? selectedFile;
  final String? fileName;
  final DocumentAnalysisResult? result;
  final String? error;

  const DocumentAnalysisState({
    this.isAnalyzing = false,
    this.analysisStep = 0,
    this.selectedDocType,
    this.selectedFile,
    this.fileName,
    this.result,
    this.error,
  });

  DocumentAnalysisState copyWith({
    bool? isAnalyzing,
    int? analysisStep,
    String? selectedDocType,
    File? selectedFile,
    String? fileName,
    DocumentAnalysisResult? result,
    String? error,
  }) =>
      DocumentAnalysisState(
        isAnalyzing: isAnalyzing ?? this.isAnalyzing,
        analysisStep: analysisStep ?? this.analysisStep,
        selectedDocType: selectedDocType ?? this.selectedDocType,
        selectedFile: selectedFile ?? this.selectedFile,
        fileName: fileName ?? this.fileName,
        result: result ?? this.result,
        error: error ?? this.error,
      );
}

class DocumentAnalysisNotifier extends StateNotifier<DocumentAnalysisState> {
  final Ref _ref;
  DocumentAnalysisNotifier(this._ref) : super(const DocumentAnalysisState());

  void selectDocType(String type) =>
      state = state.copyWith(selectedDocType: type);

  Future<void> analyzeFile(File file, String fileName) async {
    final lang = _ref.read(languageProvider);
    state = state.copyWith(
        isAnalyzing: true, analysisStep: 1, selectedFile: file, fileName: fileName, error: null);

    await Future.delayed(const Duration(milliseconds: 500));
    state = state.copyWith(analysisStep: 2);

    await Future.delayed(const Duration(milliseconds: 500));
    state = state.copyWith(analysisStep: 3);

    try {
      final ext = fileName.split('.').last.toLowerCase();

      final result = await _ref.read(aiServiceProvider).analyzeDocument(
            filePath: file.path,
            fileType: ext,
            documentTypeHint: state.selectedDocType ?? 'other',
            language: lang,
          );

      state = state.copyWith(isAnalyzing: false, result: result, analysisStep: 0);
    } catch (e) {
      state = state.copyWith(isAnalyzing: false, error: e.toString(), analysisStep: 0);
    }
  }

  void reset() => state = const DocumentAnalysisState();
}

class DocumentAnalyzerScreen extends ConsumerStatefulWidget {
  const DocumentAnalyzerScreen({super.key});

  @override
  ConsumerState<DocumentAnalyzerScreen> createState() =>
      _DocumentAnalyzerScreenState();
}

class _DocumentAnalyzerScreenState
    extends ConsumerState<DocumentAnalyzerScreen> {
  final _picker = ImagePicker();

  final List<Map<String, String>> _docTypes = const [
    {'id': 'gst_notice', 'label': 'GST Notice', 'labelHi': 'GST नोटिस', 'emoji': '🧾'},
    {'id': 'income_tax', 'label': 'Income Tax Notice', 'labelHi': 'IT नोटिस', 'emoji': '📑'},
    {'id': 'labour', 'label': 'Labour Notice', 'labelHi': 'श्रम नोटिस', 'emoji': '👷'},
    {'id': 'vendor', 'label': 'Vendor Agreement', 'labelHi': 'विक्रेता अनुबंध', 'emoji': '🤝'},
    {'id': 'rent', 'label': 'Rent Deed', 'labelHi': 'किराया अनुबंध', 'emoji': '🏠'},
    {'id': 'employee', 'label': 'Employee Agreement', 'labelHi': 'कर्मचारी अनुबंध', 'emoji': '👔'},
    {'id': 'bank', 'label': 'Bank Document', 'labelHi': 'बैंक दस्तावेज़', 'emoji': '🏦'},
    {'id': 'court', 'label': 'Court Summons', 'labelHi': 'न्यायालय समन', 'emoji': '⚖️'},
    {'id': 'municipality', 'label': 'Municipality Notice', 'labelHi': 'नगर पालिका नोटिस', 'emoji': '🏛️'},
    {'id': 'other', 'label': 'Other', 'labelHi': 'अन्य', 'emoji': '📄'},
  ];

  Future<void> _pickFromFiles() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'docx'],
    );
    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      if (await file.length() > ApiConstants.maxFileSizeBytes) {
        _showFileSizeError();
        return;
      }
      await ref.read(documentAnalysisProvider.notifier)
          .analyzeFile(file, result.files.single.name);
    }
  }

  Future<void> _pickFromGallery() async {
    final img = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (img != null) {
      final file = File(img.path);
      await ref.read(documentAnalysisProvider.notifier)
          .analyzeFile(file, img.name);
    }
  }

  Future<void> _pickFromCamera() async {
    final img = await _picker.pickImage(source: ImageSource.camera, imageQuality: 85);
    if (img != null) {
      final file = File(img.path);
      await ref.read(documentAnalysisProvider.notifier)
          .analyzeFile(file, img.name);
    }
  }

  void _showFileSizeError() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('फ़ाइल 10MB से छोटी होनी चाहिए / File must be < 10MB')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final analysisState = ref.watch(documentAnalysisProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(lang == 'hi' ? 'दस्तावेज़ विश्लेषक' : 'Document Analyzer'),
        actions: [
          if (analysisState.result != null)
            TextButton(
              onPressed: () => ref.read(documentAnalysisProvider.notifier).reset(),
              child: Text(lang == 'hi' ? 'नया' : 'New',
                  style: const TextStyle(color: AppColors.primary)),
            ),
        ],
      ),
      body: analysisState.isAnalyzing
          ? _buildAnalyzingScreen(lang, analysisState.analysisStep)
          : analysisState.result != null
              ? _buildResultScreen(lang, analysisState.result!)
              : _buildUploadScreen(lang, analysisState),
    );
  }

  Widget _buildUploadScreen(String lang, DocumentAnalysisState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Document type chips
          Text(lang == 'hi' ? 'दस्तावेज़ का प्रकार चुनें' : 'Select Document Type',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _docTypes.map((dt) {
              final selected = state.selectedDocType == dt['id'];
              return GestureDetector(
                onTap: () => ref.read(documentAnalysisProvider.notifier).selectDocType(dt['id']!),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.primary.withOpacity(0.1) : AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected ? AppColors.primary : AppColors.border,
                      width: selected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(dt['emoji']!, style: const TextStyle(fontSize: 14)),
                      const SizedBox(width: 6),
                      Text(
                        lang == 'hi' ? dt['labelHi']! : dt['label']!,
                        style: TextStyle(
                          fontSize: 13,
                          color: selected ? AppColors.primary : AppColors.textPrimary,
                          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 24),

          // Upload area
          Text(lang == 'hi' ? 'दस्तावेज़ अपलोड करें' : 'Upload Document',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
          const SizedBox(height: 12),

          GestureDetector(
            onTap: _pickFromFiles,
            child: Container(
              width: double.infinity,
              height: 160,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.4),
                  width: 2,
                  style: BorderStyle.solid,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.upload_file, color: AppColors.primary, size: 28),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    lang == 'hi'
                        ? 'अपना नोटिस या दस्तावेज़ यहाँ अपलोड करें'
                        : 'Upload your notice or document here',
                    style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  const Text('PDF, JPG, PNG, DOCX • Max 10MB',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Upload method buttons
          Row(
            children: [
              Expanded(
                child: _UploadMethodButton(
                  icon: Icons.folder_open,
                  labelHi: 'Files से',
                  labelEn: 'From Files',
                  lang: lang,
                  onTap: _pickFromFiles,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _UploadMethodButton(
                  icon: Icons.camera_alt,
                  labelHi: 'Camera',
                  labelEn: 'Camera',
                  lang: lang,
                  onTap: _pickFromCamera,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _UploadMethodButton(
                  icon: Icons.photo,
                  labelHi: 'Gallery',
                  labelEn: 'Gallery',
                  lang: lang,
                  onTap: _pickFromGallery,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Info box
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.infoLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, color: AppColors.info, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    lang == 'hi'
                        ? 'AI आपके दस्तावेज़ को पढ़कर सरल हिंदी में समझाएगा और आगे क्या करें यह बताएगा।'
                        : 'AI will read your document and explain it in simple language, with clear next steps.',
                    style: const TextStyle(fontSize: 13, color: AppColors.info),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyzingScreen(String lang, int step) {
    final steps = lang == 'hi'
        ? ['दस्तावेज़ पढ़ रहे हैं...', 'समझ रहे हैं...', 'जवाब तैयार कर रहे हैं...']
        : ['Reading document...', 'Understanding content...', 'Preparing analysis...'];

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('📄', style: TextStyle(fontSize: 60)),
            const SizedBox(height: 24),
            Text(
              lang == 'hi' ? 'विश्लेषण हो रहा है...' : 'Analyzing...',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 32),
            ...List.generate(3, (i) {
              final isDone = i < step - 1;
              final isCurrent = i == step - 1;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
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
                            ? const Icon(Icons.check, color: Colors.white, size: 14)
                            : isCurrent
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white),
                                  )
                                : Text('${i + 1}',
                                    style: const TextStyle(color: Colors.white, fontSize: 12)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      steps[i],
                      style: TextStyle(
                        color: isCurrent ? AppColors.primary : AppColors.textSecondary,
                        fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildResultScreen(String lang, DocumentAnalysisResult result) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Header card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('📄', style: TextStyle(fontSize: 24)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        lang == 'hi' ? result.documentTypeHindi : result.documentType,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
                      ),
                    ),
                    RiskLevelBadge(level: result.riskLevel),
                  ],
                ),
                const SizedBox(height: 8),
                Text('जारीकर्ता: ${result.issuingAuthority}',
                    style: const TextStyle(color: Colors.white70, fontSize: 13)),
                if (result.responseDeadline != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.schedule, color: Colors.white70, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        lang == 'hi'
                            ? 'जवाब की अंतिम तिथि: ${result.responseDeadline!.day}/${result.responseDeadline!.month}/${result.responseDeadline!.year}'
                            : 'Response Deadline: ${result.responseDeadline!.day}/${result.responseDeadline!.month}/${result.responseDeadline!.year}',
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Explanation
          _ResultSection(
            icon: '📝',
            titleHi: 'यह नोटिस क्या है?',
            titleEn: 'What is this notice?',
            lang: lang,
            child: Text(
              lang == 'hi' ? result.explanationHindi : result.explanation,
              style: const TextStyle(fontSize: 14, height: 1.6, color: AppColors.textPrimary),
            ),
          ),

          const SizedBox(height: 10),

          // Key points
          _ResultSection(
            icon: '⚠️',
            titleHi: 'मुख्य बातें',
            titleEn: 'Key Points',
            lang: lang,
            child: Column(
              children: (lang == 'hi' ? result.keyPointsHindi : result.keyPoints)
                  .map((point) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 6),
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                  color: AppColors.secondary, shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 10),
                            Expanded(child: Text(point, style: const TextStyle(fontSize: 14, height: 1.5))),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          ),

          const SizedBox(height: 10),

          // Action steps
          _ResultSection(
            icon: '✅',
            titleHi: 'आपको क्या करना चाहिए?',
            titleEn: 'What should you do?',
            lang: lang,
            child: Column(
              children: List.generate(
                (lang == 'hi' ? result.actionStepsHindi : result.actionSteps).length,
                (i) {
                  final step = (lang == 'hi' ? result.actionStepsHindi : result.actionSteps)[i];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text('${i + 1}',
                                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: Text(step, style: const TextStyle(fontSize: 14, height: 1.5))),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Action buttons
          VakilButton(
            text: lang == 'hi' ? '✍️ जवाब तैयार करें' : '✍️ Draft Response',
            onPressed: () => context.push(AppRoutes.legalNoticeResponder),
          ),
          const SizedBox(height: 10),
          VakilButton(
            text: lang == 'hi' ? '🤖 AI से और पूछें' : '🤖 Ask AI More',
            onPressed: () => context.push(AppRoutes.aiAssistant),
            isOutlined: true,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: VakilButton(
                  text: lang == 'hi' ? '💾 सेव करें' : '💾 Save',
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(lang == 'hi' ? 'सेव हो गया ✓' : 'Saved ✓')),
                    );
                  },
                  isOutlined: true,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: VakilButton(
                  text: lang == 'hi' ? '📤 Share' : '📤 Share',
                  onPressed: () {},
                  isOutlined: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _ResultSection extends StatelessWidget {
  final String icon;
  final String titleHi;
  final String titleEn;
  final String lang;
  final Widget child;

  const _ResultSection({
    required this.icon,
    required this.titleHi,
    required this.titleEn,
    required this.lang,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Text(
                lang == 'hi' ? titleHi : titleEn,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: AppColors.primary),
              ),
            ],
          ),
          const Divider(height: 16),
          child,
        ],
      ),
    );
  }
}

class _UploadMethodButton extends StatelessWidget {
  final IconData icon;
  final String labelHi;
  final String labelEn;
  final String lang;
  final VoidCallback onTap;

  const _UploadMethodButton({
    required this.icon,
    required this.labelHi,
    required this.labelEn,
    required this.lang,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 22),
            const SizedBox(height: 4),
            Text(lang == 'hi' ? labelHi : labelEn,
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}
