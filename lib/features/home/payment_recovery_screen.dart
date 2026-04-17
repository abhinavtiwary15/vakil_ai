import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme.dart';
import '../../core/services/ai_service.dart';
import '../../core/services/locale_service.dart';
import '../../shared/widgets/shared_widgets.dart';

class PaymentRecoveryScreen extends ConsumerStatefulWidget {
  const PaymentRecoveryScreen({super.key});

  @override
  ConsumerState<PaymentRecoveryScreen> createState() => _PaymentRecoveryScreenState();
}

class _PaymentRecoveryScreenState extends ConsumerState<PaymentRecoveryScreen> {
  int _currentStep = 0;
  bool _isGenerating = false;
  String? _generatedLetter;

  final _customerNameCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _dueDateCtrl = TextEditingController();
  final _invoiceCtrl = TextEditingController();
  String _recoveryStage = 'demand_letter';

  final List<Map<String, dynamic>> _stages = [
    {'id': 'demand_letter', 'emoji': '📬', 'labelHi': 'Demand Letter', 'labelEn': 'Demand Letter'},
    {'id': 'legal_notice', 'emoji': '⚖️', 'labelHi': 'Legal Notice', 'labelEn': 'Legal Notice'},
    {'id': 'msme_samadhaan', 'emoji': '🏛️', 'labelHi': 'MSME Samadhaan', 'labelEn': 'MSME Samadhaan'},
    {'id': 'section_138', 'emoji': '🏦', 'labelHi': 'Cheque Bounce (Sec 138)', 'labelEn': 'Cheque Bounce (Sec 138)'},
  ];

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(lang == 'hi' ? 'पेमेंट वसूली' : 'Payment Recovery'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.warningLight,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.warning.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(lang == 'hi' ? '💰 पेमेंट वसूली सहायक' : '💰 Payment Recovery Assistant',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: AppColors.warning)),
                  const SizedBox(height: 6),
                  Text(
                    lang == 'hi'
                        ? 'MSMED Act 2006 के तहत MSMEs को 45 दिन में payment मिलने का अधिकार है। देरी पर 3× bank rate ब्याज मिलता है।'
                        : 'MSMEs have the right to receive payment within 45 days under MSMED Act 2006. Delay attracts 3× bank rate interest.',
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Recovery stage selector
            Text(lang == 'hi' ? 'वसूली का चरण चुनें:' : 'Select Recovery Stage:',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            const SizedBox(height: 12),

            // Recovery timeline
            ...List.generate(_stages.length, (i) {
              final stage = _stages[i];
              final selected = _recoveryStage == stage['id'];
              return GestureDetector(
                onTap: () => setState(() => _recoveryStage = stage['id']!),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.primary.withOpacity(0.08) : AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: selected ? AppColors.primary : AppColors.border,
                        width: selected ? 2 : 1),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: selected ? AppColors.primary : AppColors.background,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text('${i + 1}',
                              style: TextStyle(
                                  color: selected ? Colors.white : AppColors.textSecondary,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(stage['emoji']!, style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(lang == 'hi' ? stage['labelHi']! : stage['labelEn']!,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: selected ? AppColors.primary : AppColors.textPrimary,
                                )),
                            Text(
                              _stageDescription(stage['id']!, lang),
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      if (selected) const Icon(Icons.check_circle, color: AppColors.primary, size: 20),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 16),

            // Form fields
            Text(lang == 'hi' ? 'विवरण भरें' : 'Fill Details',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            const SizedBox(height: 14),

            TextFormField(
              controller: _customerNameCtrl,
              decoration: InputDecoration(
                  labelText: lang == 'hi' ? 'ग्राहक / पार्टी का नाम' : 'Customer / Party Name'),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                  labelText: lang == 'hi' ? 'बकाया राशि (₹)' : 'Due Amount (₹)'),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _dueDateCtrl,
              decoration: InputDecoration(
                  labelText: lang == 'hi' ? 'Invoice की तारीख' : 'Invoice Date',
                  hintText: 'DD/MM/YYYY'),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _invoiceCtrl,
              decoration: InputDecoration(
                  labelText: lang == 'hi' ? 'Invoice Numbers' : 'Invoice Numbers',
                  hintText: 'INV-001, INV-002'),
            ),
            const SizedBox(height: 24),

            VakilButton(
              text: _isGenerating
                  ? (lang == 'hi' ? 'तैयार हो रहा है...' : 'Generating...')
                  : (lang == 'hi' ? '🤖 पत्र तैयार करें' : '🤖 Generate Letter'),
              onPressed: _isGenerating ? null : () => _generate(lang),
              isLoading: _isGenerating,
            ),

            if (_generatedLetter != null) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
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
                        const Icon(Icons.check_circle, color: AppColors.success, size: 18),
                        const SizedBox(width: 8),
                        Text(lang == 'hi' ? 'पत्र तैयार है ✓' : 'Letter Ready ✓',
                            style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.success)),
                      ],
                    ),
                    const Divider(height: 16),
                    SelectableText(_generatedLetter!,
                        style: const TextStyle(fontSize: 13, height: 1.7)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              VakilButton(
                text: lang == 'hi' ? '📄 PDF Download करें' : '📄 Download PDF',
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('PDF तैयार हो रहा है...')),
                ),
                isOutlined: true,
              ),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  String _stageDescription(String stage, String lang) {
    final desc = {
      'demand_letter': {'hi': 'पहली reminder, informal demand', 'en': 'First reminder, informal demand'},
      'legal_notice': {'hi': 'Formal legal notice via advocate', 'en': 'Formal legal notice via advocate'},
      'msme_samadhaan': {'hi': 'Government portal पर complaint', 'en': 'File complaint on government portal'},
      'section_138': {'hi': 'Cheque bounce पर criminal complaint', 'en': 'Criminal complaint for cheque bounce'},
    };
    return desc[stage]?[lang] ?? '';
  }

  Future<void> _generate(String lang) async {
    setState(() { _isGenerating = true; _generatedLetter = null; });
    await Future.delayed(const Duration(seconds: 2));
    final letter = lang == 'hi'
        ? '''${_customerNameCtrl.text.isEmpty ? '[ग्राहक का नाम]' : _customerNameCtrl.text} को,
[पता]

विषय: बकाया राशि ₹${_amountCtrl.text.isEmpty ? '[राशि]' : _amountCtrl.text} की मांग

महोदय/महोदया,

हम आपका ध्यान invoice संख्या ${_invoiceCtrl.text.isEmpty ? '[Invoice No.]' : _invoiceCtrl.text} दिनांक ${_dueDateCtrl.text.isEmpty ? '[तारीख]' : _dueDateCtrl.text} की ओर आकर्षित करना चाहते हैं।

उक्त invoice के विरुद्ध ₹${_amountCtrl.text.isEmpty ? '[राशि]' : _amountCtrl.text} की राशि अभी तक प्राप्त नहीं हुई है। MSMED Act 2006 की धारा 15 के अनुसार, MSME suppliers को 45 दिनों के भीतर भुगतान करना अनिवार्य है।

हम आपसे अनुरोध करते हैं कि इस पत्र के प्राप्ति से 15 दिनों के भीतर बकाया राशि का भुगतान करें। अन्यथा, हम MSME Samadhaan portal पर शिकायत दर्ज करने और कानूनी कार्रवाई करने के लिए विवश होंगे।

भवदीय,
[आपका नाम]
[तारीख]

---
*VakilAI द्वारा तैयार। वकील से review करवाएं।*'''
        : '''To,
${_customerNameCtrl.text.isEmpty ? '[Customer Name]' : _customerNameCtrl.text}
[Address]

Subject: Demand Notice for Outstanding Payment of ₹${_amountCtrl.text.isEmpty ? '[Amount]' : _amountCtrl.text}

Dear Sir/Madam,

This is to draw your attention to Invoice No. ${_invoiceCtrl.text.isEmpty ? '[Invoice No.]' : _invoiceCtrl.text} dated ${_dueDateCtrl.text.isEmpty ? '[Date]' : _dueDateCtrl.text} for which payment of ₹${_amountCtrl.text.isEmpty ? '[Amount]' : _amountCtrl.text} is still outstanding.

As per Section 15 of the MSMED Act 2006, payment to MSME suppliers must be made within 45 days. We request you to clear the outstanding amount within 15 days of receipt of this letter, failing which we shall be constrained to file a complaint on the MSME Samadhaan portal and initiate legal proceedings.

Yours faithfully,
[Your Name]
[Date]

---
*Draft by VakilAI. Please have this reviewed by a lawyer.*''';

    setState(() { _isGenerating = false; _generatedLetter = letter; });
  }
}
