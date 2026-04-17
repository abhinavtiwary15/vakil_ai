// ============ USER MODEL ============
class UserModel {
  final String uid;
  final String? phoneNumber;
  final String? email;
  final String? displayName;
  final String? photoUrl;
  final BusinessProfile? businessProfile;
  final SubscriptionModel? subscription;
  final String language;
  final int aiQuestionsUsed;
  final int aiQuestionsLimit;
  final int docGenerationsUsed;
  final int docGenerationsLimit;
  final DateTime? lastResetDate;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    this.phoneNumber,
    this.email,
    this.displayName,
    this.photoUrl,
    this.businessProfile,
    this.subscription,
    this.language = 'hi',
    this.aiQuestionsUsed = 0,
    this.aiQuestionsLimit = 3,
    this.docGenerationsUsed = 0,
    this.docGenerationsLimit = 1,
    this.lastResetDate,
    required this.createdAt,
  });

  bool get isProfileComplete => businessProfile != null;
  bool get hasActivePlan => subscription != null && subscription!.isActive;
  String get planName => subscription?.planName ?? 'free';

  UserModel copyWith({
    String? displayName,
    String? photoUrl,
    BusinessProfile? businessProfile,
    SubscriptionModel? subscription,
    String? language,
    int? aiQuestionsUsed,
    int? docGenerationsUsed,
  }) {
    return UserModel(
      uid: uid,
      phoneNumber: phoneNumber,
      email: email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      businessProfile: businessProfile ?? this.businessProfile,
      subscription: subscription ?? this.subscription,
      language: language ?? this.language,
      aiQuestionsUsed: aiQuestionsUsed ?? this.aiQuestionsUsed,
      aiQuestionsLimit: aiQuestionsLimit,
      docGenerationsUsed: docGenerationsUsed ?? this.docGenerationsUsed,
      docGenerationsLimit: docGenerationsLimit,
      lastResetDate: lastResetDate,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() => {
    'uid': uid,
    'phoneNumber': phoneNumber,
    'email': email,
    'displayName': displayName,
    'photoUrl': photoUrl,
    'businessProfile': businessProfile?.toMap(),
    'subscription': subscription?.toMap(),
    'language': language,
    'aiQuestionsUsed': aiQuestionsUsed,
    'aiQuestionsLimit': aiQuestionsLimit,
    'docGenerationsUsed': docGenerationsUsed,
    'docGenerationsLimit': docGenerationsLimit,
    'lastResetDate': lastResetDate?.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
  };

  factory UserModel.fromMap(Map<String, dynamic> map) => UserModel(
    uid: map['uid'] ?? '',
    phoneNumber: map['phoneNumber'],
    email: map['email'],
    displayName: map['displayName'],
    photoUrl: map['photoUrl'],
    businessProfile: map['businessProfile'] != null
        ? BusinessProfile.fromMap(map['businessProfile'])
        : null,
    subscription: map['subscription'] != null
        ? SubscriptionModel.fromMap(map['subscription'])
        : null,
    language: map['language'] ?? 'hi',
    aiQuestionsUsed: map['aiQuestionsUsed'] ?? 0,
    aiQuestionsLimit: map['aiQuestionsLimit'] ?? 3,
    docGenerationsUsed: map['docGenerationsUsed'] ?? 0,
    docGenerationsLimit: map['docGenerationsLimit'] ?? 1,
    lastResetDate: map['lastResetDate'] != null
        ? DateTime.parse(map['lastResetDate'])
        : null,
    createdAt: map['createdAt'] != null
        ? DateTime.parse(map['createdAt'])
        : DateTime.now(),
  );
}

// ============ BUSINESS PROFILE ============
class BusinessProfile {
  final String businessName;
  final String businessType;
  final String industry;
  final String city;
  final String state;
  final String? gstin;
  final String? udyam;
  final String? pan;
  final String? fssai;
  final String? esic;
  final String? epfo;
  final String? iec;
  final bool shopAct;
  final bool tradeLicense;
  final String employeeCount;
  final String annualTurnover;
  final String? logoUrl;
  final int legalHealthScore;

  BusinessProfile({
    required this.businessName,
    required this.businessType,
    required this.industry,
    required this.city,
    required this.state,
    this.gstin,
    this.udyam,
    this.pan,
    this.fssai,
    this.esic,
    this.epfo,
    this.iec,
    this.shopAct = false,
    this.tradeLicense = false,
    required this.employeeCount,
    required this.annualTurnover,
    this.logoUrl,
    this.legalHealthScore = 60,
  });

  Map<String, dynamic> toMap() => {
    'businessName': businessName,
    'businessType': businessType,
    'industry': industry,
    'city': city,
    'state': state,
    'gstin': gstin,
    'udyam': udyam,
    'pan': pan,
    'fssai': fssai,
    'esic': esic,
    'epfo': epfo,
    'iec': iec,
    'shopAct': shopAct,
    'tradeLicense': tradeLicense,
    'employeeCount': employeeCount,
    'annualTurnover': annualTurnover,
    'logoUrl': logoUrl,
    'legalHealthScore': legalHealthScore,
  };

  factory BusinessProfile.fromMap(Map<String, dynamic> m) => BusinessProfile(
    businessName: m['businessName'] ?? '',
    businessType: m['businessType'] ?? '',
    industry: m['industry'] ?? '',
    city: m['city'] ?? '',
    state: m['state'] ?? '',
    gstin: m['gstin'],
    udyam: m['udyam'],
    pan: m['pan'],
    fssai: m['fssai'],
    esic: m['esic'],
    epfo: m['epfo'],
    iec: m['iec'],
    shopAct: m['shopAct'] ?? false,
    tradeLicense: m['tradeLicense'] ?? false,
    employeeCount: m['employeeCount'] ?? '<5',
    annualTurnover: m['annualTurnover'] ?? '<20L',
    logoUrl: m['logoUrl'],
    legalHealthScore: m['legalHealthScore'] ?? 60,
  );
}

// ============ SUBSCRIPTION MODEL ============
class SubscriptionModel {
  final String planId;
  final String planName;
  final double amount;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final String? razorpaySubscriptionId;
  final String? razorpayOrderId;

  SubscriptionModel({
    required this.planId,
    required this.planName,
    required this.amount,
    required this.startDate,
    required this.endDate,
    required this.isActive,
    this.razorpaySubscriptionId,
    this.razorpayOrderId,
  });

  bool get isExpired => DateTime.now().isAfter(endDate);
  int get daysUntilRenewal => endDate.difference(DateTime.now()).inDays;

  Map<String, dynamic> toMap() => {
    'planId': planId,
    'planName': planName,
    'amount': amount,
    'startDate': startDate.toIso8601String(),
    'endDate': endDate.toIso8601String(),
    'isActive': isActive,
    'razorpaySubscriptionId': razorpaySubscriptionId,
    'razorpayOrderId': razorpayOrderId,
  };

  factory SubscriptionModel.fromMap(Map<String, dynamic> m) => SubscriptionModel(
    planId: m['planId'] ?? '',
    planName: m['planName'] ?? '',
    amount: (m['amount'] ?? 0).toDouble(),
    startDate: DateTime.parse(m['startDate'] ?? DateTime.now().toIso8601String()),
    endDate: DateTime.parse(m['endDate'] ?? DateTime.now().add(const Duration(days: 30)).toIso8601String()),
    isActive: m['isActive'] ?? false,
    razorpaySubscriptionId: m['razorpaySubscriptionId'],
    razorpayOrderId: m['razorpayOrderId'],
  );
}

// ============ CHAT MESSAGE MODEL ============
enum MessageSender { user, ai }
enum MessageType { text, document, image }

class ChatMessage {
  final String id;
  final String content;
  final MessageSender sender;
  final MessageType type;
  final DateTime timestamp;
  final bool isLoading;
  final String? attachmentUrl;
  final String? attachmentName;

  ChatMessage({
    required this.id,
    required this.content,
    required this.sender,
    this.type = MessageType.text,
    required this.timestamp,
    this.isLoading = false,
    this.attachmentUrl,
    this.attachmentName,
  });

  ChatMessage copyWith({String? content, bool? isLoading}) {
    return ChatMessage(
      id: id,
      content: content ?? this.content,
      sender: sender,
      type: type,
      timestamp: timestamp,
      isLoading: isLoading ?? this.isLoading,
      attachmentUrl: attachmentUrl,
      attachmentName: attachmentName,
    );
  }
}

// ============ DOCUMENT MODEL ============
enum DocumentSource { uploaded, generated }
enum DocumentType {
  gstNotice, incomeTaxNotice, labourNotice, vendorAgreement,
  rentDeed, employeeAgreement, bankDocument, courtSummons,
  municipalityNotice, other
}

class DocumentModel {
  final String id;
  final String userId;
  final String name;
  final DocumentSource source;
  final DocumentType type;
  final String? fileUrl;
  final String? localPath;
  final int? fileSizeBytes;
  final DateTime createdAt;
  final Map<String, dynamic>? analysisResult;
  final String? templateType;

  DocumentModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.source,
    required this.type,
    this.fileUrl,
    this.localPath,
    this.fileSizeBytes,
    required this.createdAt,
    this.analysisResult,
    this.templateType,
  });

  String get typeLabel {
    switch (type) {
      case DocumentType.gstNotice: return 'GST Notice';
      case DocumentType.incomeTaxNotice: return 'Income Tax Notice';
      case DocumentType.vendorAgreement: return 'Vendor Agreement';
      case DocumentType.rentDeed: return 'Rent Deed';
      case DocumentType.employeeAgreement: return 'Employee Agreement';
      default: return 'Document';
    }
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'userId': userId,
    'name': name,
    'source': source.name,
    'type': type.name,
    'fileUrl': fileUrl,
    'fileSizeBytes': fileSizeBytes,
    'createdAt': createdAt.toIso8601String(),
    'analysisResult': analysisResult,
    'templateType': templateType,
  };

  factory DocumentModel.fromMap(Map<String, dynamic> m) => DocumentModel(
    id: m['id'] ?? '',
    userId: m['userId'] ?? '',
    name: m['name'] ?? '',
    source: DocumentSource.values.firstWhere(
      (e) => e.name == m['source'], orElse: () => DocumentSource.uploaded),
    type: DocumentType.values.firstWhere(
      (e) => e.name == m['type'], orElse: () => DocumentType.other),
    fileUrl: m['fileUrl'],
    fileSizeBytes: m['fileSizeBytes'],
    createdAt: DateTime.parse(m['createdAt'] ?? DateTime.now().toIso8601String()),
    analysisResult: m['analysisResult'],
    templateType: m['templateType'],
  );
}

// ============ COMPLIANCE ITEM MODEL ============
enum ComplianceCategory { gst, labour, tax, license, custom }
enum ComplianceFrequency { monthly, quarterly, annual, oneTime }
enum ComplianceStatus { pending, completed, overdue }

class ComplianceItem {
  final String id;
  final String businessId;
  final String name;
  final String nameHindi;
  final String description;
  final String descriptionHindi;
  final ComplianceCategory category;
  final ComplianceFrequency frequency;
  final int? dayOfMonth;
  final DateTime? specificDate;
  final String penaltyInfo;
  final String penaltyInfoHindi;
  final List<String> applicableTo;
  ComplianceStatus status;
  DateTime? completedAt;
  bool reminderEnabled;
  List<int> reminderDaysBefore;
  final DateTime createdAt;

  ComplianceItem({
    required this.id,
    required this.businessId,
    required this.name,
    required this.nameHindi,
    required this.description,
    required this.descriptionHindi,
    required this.category,
    required this.frequency,
    this.dayOfMonth,
    this.specificDate,
    required this.penaltyInfo,
    required this.penaltyInfoHindi,
    required this.applicableTo,
    required this.status,
    this.completedAt,
    this.reminderEnabled = true,
    this.reminderDaysBefore = const [7, 3, 1],
    required this.createdAt,
  });

  DateTime get nextDueDate {
    final now = DateTime.now();
    if (specificDate != null) return specificDate!;
    if (dayOfMonth != null) {
      final thisMonth = DateTime(now.year, now.month, dayOfMonth!);
      if (thisMonth.isAfter(now)) return thisMonth;
      return DateTime(now.year, now.month + 1, dayOfMonth!);
    }
    return now;
  }

  int get daysUntilDue => nextDueDate.difference(DateTime.now()).inDays;
  bool get isOverdue => daysUntilDue < 0 && status != ComplianceStatus.completed;

  Map<String, dynamic> toMap() => {
    'id': id,
    'businessId': businessId,
    'name': name,
    'nameHindi': nameHindi,
    'description': description,
    'descriptionHindi': descriptionHindi,
    'category': category.name,
    'frequency': frequency.name,
    'dayOfMonth': dayOfMonth,
    'specificDate': specificDate?.toIso8601String(),
    'penaltyInfo': penaltyInfo,
    'penaltyInfoHindi': penaltyInfoHindi,
    'applicableTo': applicableTo,
    'status': status.name,
    'completedAt': completedAt?.toIso8601String(),
    'reminderEnabled': reminderEnabled,
    'reminderDaysBefore': reminderDaysBefore,
    'createdAt': createdAt.toIso8601String(),
  };

  factory ComplianceItem.fromMap(Map<String, dynamic> m) => ComplianceItem(
    id: m['id'] ?? '',
    businessId: m['businessId'] ?? '',
    name: m['name'] ?? '',
    nameHindi: m['nameHindi'] ?? '',
    description: m['description'] ?? '',
    descriptionHindi: m['descriptionHindi'] ?? '',
    category: ComplianceCategory.values.firstWhere(
      (e) => e.name == m['category'], orElse: () => ComplianceCategory.custom),
    frequency: ComplianceFrequency.values.firstWhere(
      (e) => e.name == m['frequency'], orElse: () => ComplianceFrequency.monthly),
    dayOfMonth: m['dayOfMonth'],
    specificDate: m['specificDate'] != null ? DateTime.parse(m['specificDate']) : null,
    penaltyInfo: m['penaltyInfo'] ?? '',
    penaltyInfoHindi: m['penaltyInfoHindi'] ?? '',
    applicableTo: List<String>.from(m['applicableTo'] ?? []),
    status: ComplianceStatus.values.firstWhere(
      (e) => e.name == m['status'], orElse: () => ComplianceStatus.pending),
    completedAt: m['completedAt'] != null ? DateTime.parse(m['completedAt']) : null,
    reminderEnabled: m['reminderEnabled'] ?? true,
    reminderDaysBefore: List<int>.from(m['reminderDaysBefore'] ?? [7, 3, 1]),
    createdAt: DateTime.parse(m['createdAt'] ?? DateTime.now().toIso8601String()),
  );
}

// ============ LEGAL NEWS ITEM ============
class LegalNewsItem {
  final String id;
  final String title;
  final String titleHindi;
  final String summary;
  final String summaryHindi;
  final String? aiSummary;
  final String category;
  final String source;
  final DateTime publishedAt;
  final String? url;

  LegalNewsItem({
    required this.id,
    required this.title,
    required this.titleHindi,
    required this.summary,
    required this.summaryHindi,
    this.aiSummary,
    required this.category,
    required this.source,
    required this.publishedAt,
    this.url,
  });
}

// ============ DOCUMENT ANALYSIS RESULT ============
class DocumentAnalysisResult {
  final String documentType;
  final String documentTypeHindi;
  final String issuingAuthority;
  final DateTime? noticeDate;
  final DateTime? responseDeadline;
  final String explanation;
  final String explanationHindi;
  final List<String> keyPoints;
  final List<String> keyPointsHindi;
  final List<String> actionSteps;
  final List<String> actionStepsHindi;
  final String riskLevel; // LOW, MEDIUM, HIGH, CRITICAL
  final double? demandAmount;
  final String? relevantSection;

  DocumentAnalysisResult({
    required this.documentType,
    required this.documentTypeHindi,
    required this.issuingAuthority,
    this.noticeDate,
    this.responseDeadline,
    required this.explanation,
    required this.explanationHindi,
    required this.keyPoints,
    required this.keyPointsHindi,
    required this.actionSteps,
    required this.actionStepsHindi,
    required this.riskLevel,
    this.demandAmount,
    this.relevantSection,
  });
}
