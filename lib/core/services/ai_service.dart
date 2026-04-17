import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/api_constants.dart';
import '../models/compliance_item_model.dart';

final aiServiceProvider = Provider<AiService>((ref) => AiService());

class AiService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: ApiConstants.baseUrl,
    connectTimeout: const Duration(milliseconds: ApiConstants.connectTimeout),
    receiveTimeout: const Duration(milliseconds: ApiConstants.receiveTimeout),
    headers: {'Content-Type': 'application/json'},
  ));

  // Chat with AI
  Future<String> chat({
    required String message,
    required String language,
    String? context,
    List<Map<String, String>>? history,
  }) async {
    final response = await _dio.post(
      ApiConstants.aiChat,
      data: {
        'message': message,
        'language': language,
        'context': context,
        'history': history ?? [],
      },
    );
    return response.data['response'] ?? '';
  }

  // Analyze document
  Future<DocumentAnalysisResult> analyzeDocument({
    required String filePath,
    required String fileType,
    required String documentTypeHint,
    required String language,
  }) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath, filename: 'document.$fileType'),
      'fileType': fileType,
      'documentTypeHint': documentTypeHint,
      'language': language,
    });

    final response = await _dio.post(
      ApiConstants.analyzeDocument,
      data: formData,
    );
    
    return _parseAnalysisResult(response.data);
  }

  // Generate document
  Future<String> generateDocument({
    required String templateType,
    required Map<String, dynamic> formData,
    required String language,
  }) async {
    final response = await _dio.post(
      ApiConstants.generateDocument,
      data: {
        'templateType': templateType,
        'formData': formData,
        'language': language,
      },
    );
    return response.data['documentContent'] ?? '';
  }

  // Draft notice response
  Future<String> draftNoticeResponse({
    required DocumentAnalysisResult analysis,
    required String position,
    required String keyFacts,
    required String tone,
    required String language,
  }) async {
    final response = await _dio.post(
      ApiConstants.draftNoticeResponse,
      data: {
        'analysis': {
          'documentType': analysis.documentType,
          'issuingAuthority': analysis.issuingAuthority,
          'explanation': analysis.explanation,
        },
        'position': position,
        'keyFacts': keyFacts,
        'tone': tone,
        'language': language,
      },
    );
    return response.data['draftResponse'] ?? '';
  }

  // Get legal news
  Future<List<LegalNewsItem>> getLegalNews({
    required String industry,
    required String state,
    required String language,
  }) async {
    final response = await _dio.get(
      ApiConstants.legalNewsFeed,
      queryParameters: {
        'industry': industry,
        'state': state,
        'language': language,
      },
    );
    return (response.data['news'] as List)
        .map((item) => LegalNewsItem(
              id: item['id'],
              title: item['title'],
              titleHindi: item['titleHindi'],
              summary: item['summary'],
              summaryHindi: item['summaryHindi'],
              category: item['category'],
              source: item['source'],
              publishedAt: DateTime.parse(item['publishedAt']),
            ))
        .toList();
  }

  // Legal health score
  Future<Map<String, dynamic>> getLegalHealthScore(String businessId) async {
    final response = await _dio.get('${ApiConstants.legalHealthScore}/$businessId');
    return response.data;
  }

  // ============ MOCK RESPONSES ============

  String _getMockChatResponse(String message, String language) {
    final lowerMessage = message.toLowerCase();

    if (lowerMessage.contains('gst') || lowerMessage.contains('जीएसटी')) {
      if (language == 'hi') {
        return '''## GST नोटिस के बारे में जानकारी

जब आपको GST विभाग से नोटिस मिलता है, तो **घबराएं नहीं**। यहाँ आपको क्या करना चाहिए:

### तुरंत करें:
1. **नोटिस को ध्यान से पढ़ें** - नोटिस का प्रकार, धारा, और जवाब देने की अंतिम तिथि नोट करें
2. **दस्तावेज़ इकट्ठा करें** - संबंधित invoices, returns, और payment proofs तैयार रखें
3. **समय सीमा का ध्यान रखें** - आमतौर पर 30 दिनों के भीतर जवाब देना होता है

### याद रखें:
- **धारा 73** - गलती/लापरवाही से कम कर भुगतान
- **धारा 74** - जानबूझकर कर चोरी (ज़्यादा गंभीर)
- GSTR-3B और GSTR-1 में अंतर होने पर अक्सर नोटिस आता है

### अगला कदम:
VakilAI से नोटिस अपलोड करें और हम पूरा विश्लेषण देंगे।

---
⚠️ *यह कानूनी जानकारी है, कानूनी सलाह नहीं।*''';
      } else {
        return '''## About GST Notices

When you receive a GST notice, **don't panic**. Here's what you should do:

### Immediate Steps:
1. **Read the notice carefully** - Note the type, section, and deadline for response
2. **Gather documents** - Keep relevant invoices, returns, and payment proofs ready
3. **Mind the deadline** - Usually 30 days to respond

### Key Sections:
- **Section 73** - Short payment due to mistakes/negligence
- **Section 74** - Intentional tax evasion (more serious)
- Mismatch between GSTR-3B and GSTR-1 often triggers notices

### Next Step:
Upload the notice to VakilAI for complete analysis and a drafted response.

---
⚠️ *This is legal information, not legal advice.*''';
      }
    }

    if (lowerMessage.contains('payment') || lowerMessage.contains('पेमेंट') || lowerMessage.contains('वसूली')) {
      if (language == 'hi') {
        return '''## पेमेंट वसूली के तरीके

60 दिन से ज़्यादा पेमेंट न मिलने पर आप इन कदमों का उपयोग कर सकते हैं:

### MSME के लिए विशेष अधिकार:
**MSMED Act 2006 के तहत**, अगर buyer बड़ी कंपनी है:
- 45 दिन में पेमेंट न मिले → **compound interest @ 3x bank rate**
- MSME Samadhaan Portal पर शिकायत दर्ज करें

### कदम-दर-कदम प्रक्रिया:
1. **Demand Letter** भेजें (registered post)
2. **Legal Notice** - वकील की ओर से
3. **MSME Samadhaan** पर online complaint
4. **Cheque bounce** हो तो Section 138 NI Act
5. **NCLT** में IBC के तहत insolvency petition (बड़ी राशि के लिए)

### ज़रूरी दस्तावेज़:
- Invoices और delivery challans
- Bank statements
- Email/WhatsApp communication records
- Agreement/Purchase Order

---
⚠️ *यह कानूनी जानकारी है, कानूनी सलाह नहीं।*''';
      }
    }

    if (lowerMessage.contains('fssai') || lowerMessage.contains('food')) {
      return language == 'hi'
          ? '''## FSSAI License की प्रक्रिया

### किसे चाहिए FSSAI License?
हर food business को FSSAI registration या license ज़रूरी है।

### तीन प्रकार:
1. **Basic Registration** (₹100/साल) - ₹12 लाख से कम टर्नओवर
2. **State License** (₹2,000-5,000/साल) - ₹12L से ₹20Cr टर्नओवर
3. **Central License** (₹7,500/साल) - ₹20Cr से अधिक टर्नओवर

### आवेदन प्रक्रिया:
1. FoSCoS portal (foscos.fssai.gov.in) पर जाएं
2. Documents: ID proof, address proof, business proof, food safety management plan
3. Processing time: 7-30 दिन
4. Validity: 1-5 साल (renewal possible)

### दंड:
बिना license के काम करने पर ₹5 लाख तक जुर्माना + 6 महीने कारावास

---
⚠️ *यह कानूनी जानकारी है, कानूनी सलाह नहीं।*'''
          : '''## FSSAI License Process

Every food business needs FSSAI registration or license.

**Three Types:**
1. **Basic Registration** (₹100/year) - Turnover below ₹12 lakhs
2. **State License** (₹2,000-5,000/year) - ₹12L to ₹20Cr
3. **Central License** (₹7,500/year) - Above ₹20Cr

Apply at FoSCoS portal. Processing: 7-30 days.

⚠️ *This is legal information, not legal advice.*''';
    }

    // Default response
    if (language == 'hi') {
      return '''## आपके प्रश्न का उत्तर

आपका प्रश्न प्राप्त हुआ। हमारा AI आपकी मदद करने के लिए तैयार है।

**VakilAI आपकी मदद कर सकता है:**
- 📄 किसी भी कानूनी नोटिस को समझने में
- 📝 व्यावसायिक दस्तावेज़ तैयार करने में
- 📅 GST, PF, ESI deadlines track करने में
- ⚖️ अपने business के कानूनी अधिकार जानने में

अपना विशिष्ट प्रश्न पूछें या नोटिस अपलोड करें।

---
⚠️ *यह कानूनी जानकारी है, कानूनी सलाह नहीं। जटिल मामलों में वकील से परामर्श लें।*''';
    } else {
      return '''## Answer to Your Question

Your question has been received. Our AI is ready to help you.

**VakilAI can help you with:**
- 📄 Understanding any legal notice
- 📝 Drafting business documents
- 📅 Tracking GST, PF, ESI deadlines
- ⚖️ Knowing your business legal rights

Please ask your specific question or upload a notice for analysis.

---
⚠️ *This is legal information, not legal advice. Consult a lawyer for complex matters.*''';
    }
  }

  DocumentAnalysisResult _getMockAnalysisResult(String type, String language) {
    return DocumentAnalysisResult(
      documentType: 'GST Demand Notice',
      documentTypeHindi: 'GST मांग नोटिस',
      issuingAuthority: 'GST Department, Rajasthan',
      noticeDate: DateTime.now().subtract(const Duration(days: 5)),
      responseDeadline: DateTime.now().add(const Duration(days: 25)),
      explanation: 'This is a GST demand notice issued under Section 73 of the CGST Act 2017. The tax department has identified a mismatch between your GSTR-1 and GSTR-3B returns for the period April 2024 - March 2025.',
      explanationHindi: 'यह CGST अधिनियम 2017 की धारा 73 के तहत जारी किया गया GST मांग नोटिस है। कर विभाग ने अप्रैल 2024 - मार्च 2025 की अवधि के लिए आपके GSTR-1 और GSTR-3B रिटर्न में अंतर पाया है।',
      keyPoints: [
        'Demand Amount: ₹45,000',
        'Response Deadline: 30 days from notice date',
        'Section: 73 CGST Act 2017',
        'Period: FY 2024-25',
      ],
      keyPointsHindi: [
        'मांग राशि: ₹45,000',
        'जवाब देने की अंतिम तिथि: नोटिस की तारीख से 30 दिन',
        'धारा: CGST अधिनियम 2017 की धारा 73',
        'अवधि: वित्त वर्ष 2024-25',
      ],
      actionSteps: [
        'Step 1: Review your GSTR-1 and GSTR-3B for the mentioned period',
        'Step 2: Identify and reconcile any mismatches in reported figures',
        'Step 3: Prepare a written reply explaining the discrepancy with supporting documents',
        'Step 4: Submit the reply through GST portal or by registered post within 30 days',
        'Step 5: If demand is valid, pay the tax along with interest',
      ],
      actionStepsHindi: [
        'कदम 1: उल्लिखित अवधि के लिए अपना GSTR-1 और GSTR-3B की समीक्षा करें',
        'कदम 2: रिपोर्ट किए गए आंकड़ों में किसी भी अंतर की पहचान करें',
        'कदम 3: सहायक दस्तावेजों के साथ विसंगति समझाते हुए लिखित जवाब तैयार करें',
        'कदम 4: 30 दिनों के भीतर GST पोर्टल या रजिस्टर्ड डाक के माध्यम से जवाब जमा करें',
        'कदम 5: यदि मांग वैध है, तो ब्याज सहित कर का भुगतान करें',
      ],
      riskLevel: 'MEDIUM',
      demandAmount: 45000,
      relevantSection: 'Section 73 CGST Act 2017',
    );
  }

  String _getMockDocument(String templateType, Map<String, dynamic> formData) {
    final party1 = formData['party1Name'] ?? 'Party A';
    final party2 = formData['party2Name'] ?? 'Party B';
    final date = DateTime.now().toString().split(' ')[0];

    return '''VENDOR AGREEMENT

This Vendor Agreement ("Agreement") is entered into as of $date between:

**Party 1:** $party1
Address: ${formData['party1Address'] ?? '[Address]'}
(hereinafter referred to as "Buyer")

**Party 2:** $party2  
Address: ${formData['party2Address'] ?? '[Address]'}
(hereinafter referred to as "Vendor")

**WHEREAS**, the parties desire to establish a vendor relationship for supply of goods/services as described herein.

**NOW, THEREFORE**, in consideration of the mutual covenants and agreements set forth herein, the parties agree as follows:

**1. SCOPE OF SERVICES**
The Vendor agrees to supply: ${formData['goodsServices'] ?? 'Goods/Services as mutually agreed'}

**2. CONTRACT VALUE**
Total Contract Value: ₹${formData['contractValue'] ?? '0'}

**3. PAYMENT TERMS**
Payment shall be made as per: ${formData['paymentTerms'] ?? 'Net 30 days'}

**4. DELIVERY TIMELINE**
${formData['deliveryTimeline'] ?? 'As per purchase order'}

**5. GOVERNING LAW**
This Agreement shall be governed by the laws of India, specifically the Indian Contract Act, 1872, and other applicable laws.

**6. DISPUTE RESOLUTION**
Any disputes shall be resolved through ${formData['disputeResolution'] ?? 'Arbitration'} in ${formData['jurisdiction'] ?? 'the appropriate jurisdiction'}.

**7. ENTIRE AGREEMENT**
This Agreement constitutes the entire agreement between the parties.

IN WITNESS WHEREOF, the parties have executed this Agreement as of the date first written above.

**$party1**                    **$party2**
Signature: _____________      Signature: _____________
Name:                         Name:
Date:                         Date:

---
*Generated by VakilAI | This document is a draft and should be reviewed by a qualified lawyer before signing.*''';
  }

  String _getMockNoticeResponse(String language) {
    if (language == 'hi') {
      return '''सेवा में,
श्रीमान/श्रीमती,
GST अधिकारी, [कार्यालय का नाम]

विषय: **GST मांग नोटिस का जवाब** - Reference No. [XX/XX/2025]

महोदय/महोदया,

उपरोक्त संदर्भ में आपके नोटिस दिनांक [XX/XX/2025] के संबंध में हम निम्नलिखित जवाब प्रस्तुत करते हैं:

**1. तथ्यात्मक स्थिति:**
हमारी कंपनी [कंपनी का नाम] GSTIN [GSTIN नंबर] के साथ विधिवत पंजीकृत है। हमने नियमित रूप से अपने GST रिटर्न दाखिल किए हैं।

**2. नोटिस में उठाए गए बिंदुओं पर जवाब:**
GSTR-1 और GSTR-3B में दिखाए गए अंतर के संबंध में हम स्पष्ट करना चाहते हैं कि यह अंतर [कारण] के कारण हुआ था।

**3. सहायक दस्तावेज़:**
इस पत्र के साथ निम्नलिखित दस्तावेज़ संलग्न हैं:
- GSTR-1 और GSTR-3B की प्रति
- संबंधित invoices
- भुगतान के प्रमाण

हम अनुरोध करते हैं कि उपरोक्त जानकारी के आधार पर हमारे मामले पर पुनर्विचार किया जाए।

भवदीय,
[हस्ताक्षर]
[नाम और पदनाम]
[तारीख]

---
*VakilAI द्वारा तैयार मसौदा - signing से पहले वकील से review करवाएं*''';
    } else {
      return '''To,
The GST Officer,
[Office Name and Address]

Subject: **Response to GST Demand Notice** - Reference No. [XX/XX/2025]

Sir/Madam,

With reference to the above notice dated [XX/XX/2025], we submit the following response:

**1. Factual Position:**
Our company [Company Name] is duly registered under GSTIN [GSTIN Number]. We have been filing our GST returns regularly and in compliance with applicable provisions.

**2. Response to Issues Raised:**
Regarding the discrepancy between GSTR-1 and GSTR-3B, we respectfully submit that the said difference arose due to [reason], which is further explained as follows:

**3. Supporting Documents:**
The following documents are enclosed herewith:
- Copies of GSTR-1 and GSTR-3B
- Relevant invoices
- Payment proofs

We request that this matter be reconsidered in light of the above submissions.

Yours faithfully,
[Signature]
[Name and Designation]
[Date]

---
*Draft generated by VakilAI - Please have this reviewed by a lawyer before sending*''';
    }
  }

  List<LegalNewsItem> _getMockLegalNews() {
    return [
      LegalNewsItem(
        id: '1',
        title: 'GST Council relaxes late fee for small taxpayers',
        titleHindi: 'GST परिषद ने छोटे करदाताओं के लिए विलंब शुल्क में छूट दी',
        summary: 'The GST Council in its latest meeting has decided to waive late fees for small taxpayers with turnover below ₹1.5 crore for delayed filing of GSTR-3B.',
        summaryHindi: 'GST परिषद ने अपनी नवीनतम बैठक में ₹1.5 करोड़ से कम टर्नओवर वाले छोटे करदाताओं के लिए GSTR-3B की देरी से दाखिली पर विलंब शुल्क माफ करने का फैसला किया।',
        category: 'GST',
        source: 'GST Council',
        publishedAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      LegalNewsItem(
        id: '2',
        title: 'MSME Samadhaan portal upgraded with new features',
        titleHindi: 'MSME समाधान पोर्टल में नई सुविधाएं जोड़ी गईं',
        summary: 'The Ministry of MSME has upgraded the Samadhaan portal for faster resolution of payment disputes. MSMEs can now track their complaint status in real-time.',
        summaryHindi: 'MSME मंत्रालय ने भुगतान विवादों के त्वरित समाधान के लिए समाधान पोर्टल को अपग्रेड किया है। अब MSMEs अपनी शिकायत की स्थिति real-time में ट्रैक कर सकते हैं।',
        category: 'Labour',
        source: 'Ministry of MSME',
        publishedAt: DateTime.now().subtract(const Duration(days: 5)),
      ),
      LegalNewsItem(
        id: '3',
        title: 'PF deposit deadline extended due to technical issues',
        titleHindi: 'तकनीकी समस्याओं के कारण PF जमा की समय सीमा बढ़ाई गई',
        summary: 'EPFO has extended the deadline for PF deposit for the month of March due to technical issues with the UAN portal.',
        summaryHindi: 'EPFO ने UAN पोर्टल में तकनीकी समस्याओं के कारण मार्च महीने के PF जमा की समय सीमा बढ़ा दी है।',
        category: 'Labour',
        source: 'EPFO',
        publishedAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];
  }

  DocumentAnalysisResult _parseAnalysisResult(dynamic data) {
    return DocumentAnalysisResult(
      documentType: data['documentType'] ?? '',
      documentTypeHindi: data['documentTypeHindi'] ?? '',
      issuingAuthority: data['issuingAuthority'] ?? '',
      explanation: data['explanation'] ?? '',
      explanationHindi: data['explanationHindi'] ?? '',
      keyPoints: List<String>.from(data['keyPoints'] ?? []),
      keyPointsHindi: List<String>.from(data['keyPointsHindi'] ?? []),
      actionSteps: List<String>.from(data['actionSteps'] ?? []),
      actionStepsHindi: List<String>.from(data['actionStepsHindi'] ?? []),
      riskLevel: data['riskLevel'] ?? 'MEDIUM',
      demandAmount: data['demandAmount']?.toDouble(),
      relevantSection: data['relevantSection'],
    );
  }
}
