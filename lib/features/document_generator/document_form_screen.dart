import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme.dart';
import '../../core/services/ai_service.dart';
import '../../core/services/locale_service.dart';
import '../../core/services/auth_service.dart';
import '../../shared/widgets/shared_widgets.dart';

final docGeneratorStateProvider =
    StateNotifierProvider<DocGeneratorNotifier, DocGeneratorState>(
        (ref) => DocGeneratorNotifier(ref));

class DocGeneratorState {
  final bool isGenerating;
  final String? generatedContent;
  final String? error;
  const DocGeneratorState({
    this.isGenerating = false,
    this.generatedContent,
    this.error,
  });
}

class DocGeneratorNotifier extends StateNotifier<DocGeneratorState> {
  final Ref _ref;
  DocGeneratorNotifier(this._ref) : super(const DocGeneratorState());

  Future<void> generate(String templateType, Map<String, dynamic> formData) async {
    final lang = _ref.read(languageProvider);
    state = const DocGeneratorState(isGenerating: true);
    try {
      final content = await _ref.read(aiServiceProvider).generateDocument(
            templateType: templateType,
            formData: formData,
            language: lang,
          );
      state = DocGeneratorState(generatedContent: content);
    } catch (e) {
      state = DocGeneratorState(error: e.toString());
    }
  }

  void reset() => state = const DocGeneratorState();
}

class DocumentFormScreen extends ConsumerStatefulWidget {
  final String templateType;
  final String templateName;

  const DocumentFormScreen({
    super.key,
    required this.templateType,
    required this.templateName,
  });

  @override
  ConsumerState<DocumentFormScreen> createState() => _DocumentFormScreenState();
}

class _DocumentFormScreenState extends ConsumerState<DocumentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {};
  String _paymentTerms = 'Net 30';
  String _disputeResolution = 'Arbitration';
  bool _hasPenaltyClause = false;
  String _docLanguage = 'en';

  List<Map<String, dynamic>> get _fields {
    switch (widget.templateType) {
      case 'vendor_agreement':
        return [
          {'key': 'party1Name', 'labelHi': 'आपका नाम / कंपनी', 'labelEn': 'Your Name / Company', 'hint': 'Ramesh Enterprises'},
          {'key': 'party1Address', 'labelHi': 'आपका पता', 'labelEn': 'Your Address', 'hint': '123 MG Road, Jaipur'},
          {'key': 'party2Name', 'labelHi': 'विक्रेता का नाम', 'labelEn': 'Vendor Name', 'hint': 'ABC Suppliers Pvt Ltd'},
          {'key': 'party2Address', 'labelHi': 'विक्रेता का पता', 'labelEn': 'Vendor Address', 'hint': 'Vendor address'},
          {'key': 'goodsServices', 'labelHi': 'माल / सेवाएं', 'labelEn': 'Goods / Services', 'hint': 'Raw materials, packaging etc', 'maxLines': 3},
          {'key': 'contractValue', 'labelHi': 'अनुबंध मूल्य (₹)', 'labelEn': 'Contract Value (₹)', 'hint': '500000', 'type': 'number'},
          {'key': 'deliveryTimeline', 'labelHi': 'डिलीवरी समयसीमा', 'labelEn': 'Delivery Timeline', 'hint': '30 days from order'},
          {'key': 'jurisdiction', 'labelHi': 'न्यायक्षेत्र', 'labelEn': 'Jurisdiction', 'hint': 'Jaipur'},
        ];
      case 'appointment_letter':
        return [
          {'key': 'employerName', 'labelHi': 'नियोक्ता का नाम', 'labelEn': 'Employer Name', 'hint': 'Company Name'},
          {'key': 'employeeName', 'labelHi': 'कर्मचारी का नाम', 'labelEn': 'Employee Name', 'hint': 'Full Name'},
          {'key': 'designation', 'labelHi': 'पद', 'labelEn': 'Designation', 'hint': 'Sales Manager'},
          {'key': 'department', 'labelHi': 'विभाग', 'labelEn': 'Department', 'hint': 'Sales & Marketing'},
          {'key': 'salary', 'labelHi': 'वेतन (₹/महीना)', 'labelEn': 'Salary (₹/month)', 'hint': '25000', 'type': 'number'},
          {'key': 'joiningDate', 'labelHi': 'ज्वाइनिंग तिथि', 'labelEn': 'Joining Date', 'hint': '01/06/2025'},
          {'key': 'probationPeriod', 'labelHi': 'परिवीक्षा अवधि', 'labelEn': 'Probation Period', 'hint': '3 months'},
          {'key': 'noticePeriod', 'labelHi': 'नोटिस अवधि', 'labelEn': 'Notice Period', 'hint': '30 days'},
          {'key': 'workLocation', 'labelHi': 'कार्यस्थल', 'labelEn': 'Work Location', 'hint': 'Head Office, Jaipur'},
        ];
      case 'payment_recovery':
        return [
          {'key': 'senderName', 'labelHi': 'आपका नाम', 'labelEn': 'Your Name', 'hint': 'Your business name'},
          {'key': 'receiverName', 'labelHi': 'प्राप्तकर्ता का नाम', 'labelEn': 'Recipient Name', 'hint': 'Debtor name'},
          {'key': 'receiverAddress', 'labelHi': 'प्राप्तकर्ता का पता', 'labelEn': 'Recipient Address', 'hint': 'Full address'},
          {'key': 'amount', 'labelHi': 'बकाया राशि (₹)', 'labelEn': 'Due Amount (₹)', 'hint': '150000', 'type': 'number'},
          {'key': 'dueDate', 'labelHi': 'मूल देय तिथि', 'labelEn': 'Original Due Date', 'hint': '15/01/2025'},
          {'key': 'invoiceNumbers', 'labelHi': 'Invoice नंबर', 'labelEn': 'Invoice Numbers', 'hint': 'INV-001, INV-002'},
          {'key': 'paymentDeadline', 'labelHi': 'भुगतान की अंतिम तिथि', 'labelEn': 'Payment Deadline (days)', 'hint': '15', 'type': 'number'},
        ];
      default:
        return [
          {'key': 'party1Name', 'labelHi': 'पक्ष 1 का नाम', 'labelEn': 'Party 1 Name', 'hint': 'Your name/company'},
          {'key': 'party2Name', 'labelHi': 'पक्ष 2 का नाम', 'labelEn': 'Party 2 Name', 'hint': 'Other party name'},
          {'key': 'amount', 'labelHi': 'राशि (₹)', 'labelEn': 'Amount (₹)', 'hint': '100000', 'type': 'number'},
          {'key': 'date', 'labelHi': 'तिथि', 'labelEn': 'Date', 'hint': 'DD/MM/YYYY'},
          {'key': 'description', 'labelHi': 'विवरण', 'labelEn': 'Description', 'hint': 'Details...', 'maxLines': 4},
          {'key': 'jurisdiction', 'labelHi': 'न्यायक्षेत्र', 'labelEn': 'Jurisdiction', 'hint': 'City name'},
        ];
    }
  }

  TextEditingController _ctrl(String key) {
    if (!_controllers.containsKey(key)) {
      _controllers[key] = TextEditingController();
    }
    return _controllers[key]!;
  }

  @override
  void dispose() {
    for (final c in _controllers.values) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final genState = ref.watch(docGeneratorStateProvider);

    if (genState.isGenerating) return _buildGeneratingScreen(lang);
    if (genState.generatedContent != null) {
      return _buildPreviewScreen(lang, genState.generatedContent!);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(widget.templateName)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Text('⚖️', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      lang == 'hi'
                          ? 'भारतीय Contract Act 1872 के अनुसार AI द्वारा तैयार'
                          : 'AI-drafted as per Indian Contract Act 1872',
                      style: const TextStyle(fontSize: 13, color: AppColors.primary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            ..._fields.map((field) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: TextFormField(
                controller: _ctrl(field['key'] as String),
                keyboardType: field['type'] == 'number'
                    ? TextInputType.number
                    : (field['maxLines'] != null && (field['maxLines'] as int) > 1
                        ? TextInputType.multiline
                        : TextInputType.text),
                maxLines: (field['maxLines'] as int?) ?? 1,
                decoration: InputDecoration(
                  labelText: lang == 'hi' ? field['labelHi'] as String : field['labelEn'] as String,
                  hintText: field['hint'] as String,
                ),
              ),
            )),

            // Payment terms (for contracts)
            if (widget.templateType == 'vendor_agreement') ...[
              DropdownButtonFormField<String>(
                value: _paymentTerms,
                decoration: InputDecoration(
                  labelText: lang == 'hi' ? 'भुगतान शर्तें' : 'Payment Terms',
                ),
                items: ['Advance', 'On Delivery', 'Net 15', 'Net 30', 'Net 60']
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) => setState(() => _paymentTerms = v!),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Checkbox(
                    value: _hasPenaltyClause,
                    onChanged: (v) => setState(() => _hasPenaltyClause = v!),
                    activeColor: AppColors.primary,
                  ),
                  Text(lang == 'hi' ? 'Penalty Clause जोड़ें' : 'Add Penalty Clause'),
                ],
              ),

              DropdownButtonFormField<String>(
                value: _disputeResolution,
                decoration: InputDecoration(
                  labelText: lang == 'hi' ? 'विवाद समाधान' : 'Dispute Resolution',
                ),
                items: ['Arbitration', 'Court / Civil Suit', 'Mediation']
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) => setState(() => _disputeResolution = v!),
              ),
              const SizedBox(height: 16),
            ],

            // Document language
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(lang == 'hi' ? 'दस्तावेज़ की भाषा' : 'Document Language',
                    style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _LangButton(label: 'हिंदी', selected: _docLanguage == 'hi', onTap: () => setState(() => _docLanguage = 'hi'))),
                    const SizedBox(width: 8),
                    Expanded(child: _LangButton(label: 'English', selected: _docLanguage == 'en', onTap: () => setState(() => _docLanguage = 'en'))),
                    const SizedBox(width: 8),
                    Expanded(child: _LangButton(label: 'Bilingual', selected: _docLanguage == 'both', onTap: () => setState(() => _docLanguage = 'both'))),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            VakilButton(
              text: lang == 'hi' ? '🤖 दस्तावेज़ बनाएं' : '🤖 Generate Document',
              onPressed: _generate,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _generate() {
    final data = <String, dynamic>{};
    for (final field in _fields) {
      data[field['key'] as String] = _ctrl(field['key'] as String).text;
    }
    data['paymentTerms'] = _paymentTerms;
    data['disputeResolution'] = _disputeResolution;
    data['hasPenaltyClause'] = _hasPenaltyClause;
    data['docLanguage'] = _docLanguage;
    ref.read(docGeneratorStateProvider.notifier).generate(widget.templateType, data);
  }

  Widget _buildGeneratingScreen(String lang) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(widget.templateName)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('📝', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 20),
            Text(
              lang == 'hi' ? 'दस्तावेज़ तैयार हो रहा है...' : 'Generating document...',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Text(
              lang == 'hi'
                  ? 'AI भारतीय कानून के अनुसार अनुबंध तैयार कर रहा है'
                  : 'AI is drafting the agreement as per Indian law',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(color: AppColors.primary),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewScreen(String lang, String content) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(lang == 'hi' ? 'दस्तावेज़ प्रीव्यू' : 'Document Preview'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => ref.read(docGeneratorStateProvider.notifier).reset(),
            tooltip: lang == 'hi' ? 'बदलें' : 'Edit',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppColors.border),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
                    ),
                    child: SelectableText(
                      content,
                      style: const TextStyle(fontSize: 13, height: 1.7, color: AppColors.textPrimary, fontFamily: 'monospace'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.warningLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      lang == 'hi'
                          ? '⚠️ यह AI द्वारा तैयार मसौदा है। साइन करने से पहले वकील से समीक्षा करवाएं।'
                          : '⚠️ This is an AI-generated draft. Have it reviewed by a lawyer before signing.',
                      style: const TextStyle(fontSize: 12, color: AppColors.warning),
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
                  text: lang == 'hi' ? '📄 PDF डाउनलोड करें' : '📄 Download PDF',
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(lang == 'hi' ? 'PDF तैयार हो रहा है...' : 'Preparing PDF...')),
                    );
                  },
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: VakilButton(
                        text: lang == 'hi' ? '📤 WhatsApp' : '📤 WhatsApp',
                        onPressed: () {},
                        isOutlined: true,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: VakilButton(
                        text: lang == 'hi' ? '✨ AI बेहतर करे' : '✨ Enhance',
                        onPressed: () {},
                        isOutlined: true,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LangButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _LangButton({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: selected ? AppColors.primary : AppColors.border),
        ),
        child: Center(
          child: Text(label, style: TextStyle(
            fontSize: 12,
            color: selected ? Colors.white : AppColors.textSecondary,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          )),
        ),
      ),
    );
  }
}
