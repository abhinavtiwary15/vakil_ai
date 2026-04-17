import '../models/compliance_item_model.dart';

class ComplianceData {
  static List<ComplianceItem> getDefaultItems(String businessId) {
    final now = DateTime.now();

    List<ComplianceItem> items = [];

    // GST Compliance
    items.addAll([
      ComplianceItem(
        id: 'gst_gstr1_${now.year}_${now.month}',
        businessId: businessId,
        name: 'GSTR-1',
        nameHindi: 'GSTR-1 (बिक्री रिटर्न)',
        description: 'Monthly outward supply return',
        descriptionHindi: 'मासिक बाहरी आपूर्ति रिटर्न',
        category: ComplianceCategory.gst,
        frequency: ComplianceFrequency.monthly,
        dayOfMonth: 11,
        penaltyInfo: 'Late fee: ₹50/day (₹25 CGST + ₹25 SGST), max ₹5,000',
        penaltyInfoHindi: 'देर से दाखिल करने पर प्रतिदिन ₹50 जुर्माना, अधिकतम ₹5,000',
        applicableTo: ['gst_registered'],
        status: ComplianceStatus.pending,
        createdAt: DateTime.now(),
      ),
      ComplianceItem(
        id: 'gst_gstr3b_${now.year}_${now.month}',
        businessId: businessId,
        name: 'GSTR-3B',
        nameHindi: 'GSTR-3B (मासिक सारांश)',
        description: 'Monthly summary return with tax payment',
        descriptionHindi: 'कर भुगतान के साथ मासिक सारांश रिटर्न',
        category: ComplianceCategory.gst,
        frequency: ComplianceFrequency.monthly,
        dayOfMonth: 20,
        penaltyInfo: 'Interest @ 18% p.a. on tax due + ₹50/day late fee',
        penaltyInfoHindi: 'बकाया कर पर 18% वार्षिक ब्याज + प्रतिदिन ₹50 जुर्माना',
        applicableTo: ['gst_registered'],
        status: ComplianceStatus.pending,
        createdAt: DateTime.now(),
      ),
      ComplianceItem(
        id: 'gst_gstr9_${now.year}',
        businessId: businessId,
        name: 'GSTR-9',
        nameHindi: 'GSTR-9 (वार्षिक रिटर्न)',
        description: 'Annual GST return',
        descriptionHindi: 'वार्षिक GST रिटर्न',
        category: ComplianceCategory.gst,
        frequency: ComplianceFrequency.annual,
        specificDate: DateTime(now.year, 12, 31),
        penaltyInfo: '₹200/day (₹100 CGST + ₹100 SGST)',
        penaltyInfoHindi: 'प्रतिदिन ₹200 जुर्माना',
        applicableTo: ['gst_registered'],
        status: ComplianceStatus.pending,
        createdAt: DateTime.now(),
      ),
    ]);

    // Labour Compliance
    items.addAll([
      ComplianceItem(
        id: 'labour_pf_${now.year}_${now.month}',
        businessId: businessId,
        name: 'PF Deposit (ECR)',
        nameHindi: 'PF जमा (ECR)',
        description: 'Monthly PF contribution deposit',
        descriptionHindi: 'मासिक PF योगदान जमा',
        category: ComplianceCategory.labour,
        frequency: ComplianceFrequency.monthly,
        dayOfMonth: 15,
        penaltyInfo: 'Interest @ 12% p.a. + damages up to 25% of arrears',
        penaltyInfoHindi: '12% वार्षिक ब्याज + बकाया का 25% तक जुर्माना',
        applicableTo: ['pf_registered'],
        status: ComplianceStatus.pending,
        createdAt: DateTime.now(),
      ),
      ComplianceItem(
        id: 'labour_esi_${now.year}_${now.month}',
        businessId: businessId,
        name: 'ESI Deposit',
        nameHindi: 'ESI जमा',
        description: 'Monthly ESI contribution deposit',
        descriptionHindi: 'मासिक ESI योगदान जमा',
        category: ComplianceCategory.labour,
        frequency: ComplianceFrequency.monthly,
        dayOfMonth: 15,
        penaltyInfo: 'Interest @ 12% p.a. on delayed contribution',
        penaltyInfoHindi: '12% वार्षिक ब्याज',
        applicableTo: ['esic_registered'],
        status: ComplianceStatus.pending,
        createdAt: DateTime.now(),
      ),
      ComplianceItem(
        id: 'labour_pf_return_${now.year}_${now.month}',
        businessId: businessId,
        name: 'PF Return (Monthly)',
        nameHindi: 'PF रिटर्न (मासिक)',
        description: 'Monthly PF return filing',
        descriptionHindi: 'मासिक PF रिटर्न दाखिल करना',
        category: ComplianceCategory.labour,
        frequency: ComplianceFrequency.monthly,
        dayOfMonth: 25,
        penaltyInfo: 'Penalty under EPF Act',
        penaltyInfoHindi: 'EPF अधिनियम के तहत जुर्माना',
        applicableTo: ['pf_registered'],
        status: ComplianceStatus.pending,
        createdAt: DateTime.now(),
      ),
    ]);

    // Tax Compliance - Advance Tax
    final currentYear = now.year;
    items.addAll([
      ComplianceItem(
        id: 'tax_advance_q1_$currentYear',
        businessId: businessId,
        name: 'Advance Tax Q1',
        nameHindi: 'अग्रिम कर Q1 (15 जून)',
        description: '15% of estimated tax liability',
        descriptionHindi: 'अनुमानित कर देयता का 15%',
        category: ComplianceCategory.tax,
        frequency: ComplianceFrequency.quarterly,
        specificDate: DateTime(currentYear, 6, 15),
        penaltyInfo: 'Interest u/s 234B & 234C @ 1% per month',
        penaltyInfoHindi: 'धारा 234B और 234C के तहत 1% प्रतिमाह ब्याज',
        applicableTo: ['all'],
        status: ComplianceStatus.pending,
        createdAt: DateTime.now(),
      ),
      ComplianceItem(
        id: 'tax_advance_q2_$currentYear',
        businessId: businessId,
        name: 'Advance Tax Q2',
        nameHindi: 'अग्रिम कर Q2 (15 सितम्बर)',
        description: '45% of estimated tax liability',
        descriptionHindi: 'अनुमानित कर देयता का 45%',
        category: ComplianceCategory.tax,
        frequency: ComplianceFrequency.quarterly,
        specificDate: DateTime(currentYear, 9, 15),
        penaltyInfo: 'Interest u/s 234B & 234C @ 1% per month',
        penaltyInfoHindi: 'धारा 234B और 234C के तहत 1% प्रतिमाह ब्याज',
        applicableTo: ['all'],
        status: ComplianceStatus.pending,
        createdAt: DateTime.now(),
      ),
      ComplianceItem(
        id: 'tax_advance_q3_$currentYear',
        businessId: businessId,
        name: 'Advance Tax Q3',
        nameHindi: 'अग्रिम कर Q3 (15 दिसम्बर)',
        description: '75% of estimated tax liability',
        descriptionHindi: 'अनुमानित कर देयता का 75%',
        category: ComplianceCategory.tax,
        frequency: ComplianceFrequency.quarterly,
        specificDate: DateTime(currentYear, 12, 15),
        penaltyInfo: 'Interest u/s 234B & 234C @ 1% per month',
        penaltyInfoHindi: 'धारा 234B और 234C के तहत 1% प्रतिमाह ब्याज',
        applicableTo: ['all'],
        status: ComplianceStatus.pending,
        createdAt: DateTime.now(),
      ),
      ComplianceItem(
        id: 'tax_advance_q4_$currentYear',
        businessId: businessId,
        name: 'Advance Tax Q4',
        nameHindi: 'अग्रिम कर Q4 (15 मार्च)',
        description: '100% of estimated tax liability',
        descriptionHindi: 'अनुमानित कर देयता का 100%',
        category: ComplianceCategory.tax,
        frequency: ComplianceFrequency.quarterly,
        specificDate: DateTime(currentYear + 1, 3, 15),
        penaltyInfo: 'Interest u/s 234B & 234C @ 1% per month',
        penaltyInfoHindi: 'धारा 234B और 234C के तहत 1% प्रतिमाह ब्याज',
        applicableTo: ['all'],
        status: ComplianceStatus.pending,
        createdAt: DateTime.now(),
      ),
      ComplianceItem(
        id: 'tax_itr_${now.year}',
        businessId: businessId,
        name: 'Income Tax Return',
        nameHindi: 'आयकर रिटर्न (31 जुलाई)',
        description: 'Annual ITR filing',
        descriptionHindi: 'वार्षिक आयकर रिटर्न दाखिल करना',
        category: ComplianceCategory.tax,
        frequency: ComplianceFrequency.annual,
        specificDate: DateTime(currentYear, 7, 31),
        penaltyInfo: '₹5,000 penalty u/s 234F (₹1,000 if income < ₹5L)',
        penaltyInfoHindi: 'धारा 234F के तहत ₹5,000 जुर्माना',
        applicableTo: ['all'],
        status: ComplianceStatus.pending,
        createdAt: DateTime.now(),
      ),
    ]);

    return items;
  }

  static List<String> get indianStates => [
    'Andhra Pradesh', 'Arunachal Pradesh', 'Assam', 'Bihar', 'Chhattisgarh',
    'Goa', 'Gujarat', 'Haryana', 'Himachal Pradesh', 'Jharkhand', 'Karnataka',
    'Kerala', 'Madhya Pradesh', 'Maharashtra', 'Manipur', 'Meghalaya',
    'Mizoram', 'Nagaland', 'Odisha', 'Punjab', 'Rajasthan', 'Sikkim',
    'Tamil Nadu', 'Telangana', 'Tripura', 'Uttar Pradesh', 'Uttarakhand',
    'West Bengal', 'Delhi', 'Jammu & Kashmir', 'Ladakh', 'Puducherry',
    'Chandigarh', 'Andaman & Nicobar Islands', 'Dadra & Nagar Haveli',
    'Daman & Diu', 'Lakshadweep',
  ];

  static List<String> get businessTypes => [
    'Proprietorship', 'Partnership', 'LLP', 'Private Limited', 'OPC',
    'Public Limited', 'Section 8 Company', 'Trust', 'Society',
  ];

  static List<String> get industries => [
    'Food & Beverage', 'Manufacturing', 'Trading', 'Services', 'Retail',
    'Construction', 'Healthcare', 'Education', 'IT & Technology',
    'Textile & Garments', 'Agriculture', 'Chemicals', 'Pharmaceuticals',
    'Auto & Components', 'Electrical & Electronics', 'Jewellery',
    'Logistics & Transport', 'Real Estate', 'Tourism & Hospitality',
    'Media & Entertainment', 'Finance & Insurance', 'Consulting',
    'E-commerce', 'Beauty & Wellness', 'Sports & Fitness', 'Other',
  ];

  static List<Map<String, dynamic>> get documentTemplates => [
    // Agreements
    {'id': 'vendor_agreement', 'name': 'Vendor Agreement', 'nameHindi': 'विक्रेता अनुबंध', 'category': 'agreements', 'icon': '🤝'},
    {'id': 'employee_contract', 'name': 'Employee Contract', 'nameHindi': 'कर्मचारी अनुबंध', 'category': 'agreements', 'icon': '👷'},
    {'id': 'nda', 'name': 'NDA', 'nameHindi': 'गोपनीयता अनुबंध', 'category': 'agreements', 'icon': '🔒'},
    {'id': 'dealer_agreement', 'name': 'Dealer Agreement', 'nameHindi': 'डीलर अनुबंध', 'category': 'agreements', 'icon': '🏪'},
    {'id': 'transport_agreement', 'name': 'Transport Agreement', 'nameHindi': 'परिवहन अनुबंध', 'category': 'agreements', 'icon': '🚚'},
    // Property
    {'id': 'rent_deed_residential', 'name': 'Rent Deed (Residential)', 'nameHindi': 'किराया अनुबंध (आवासीय)', 'category': 'property', 'icon': '🏠'},
    {'id': 'commercial_lease', 'name': 'Commercial Lease', 'nameHindi': 'व्यावसायिक पट्टा', 'category': 'property', 'icon': '🏭'},
    {'id': 'leave_license', 'name': 'Leave & License', 'nameHindi': 'लाइसेंस अनुबंध', 'category': 'property', 'icon': '📋'},
    // Recovery & Notices
    {'id': 'payment_recovery', 'name': 'Payment Recovery Notice', 'nameHindi': 'भुगतान वसूली नोटिस', 'category': 'notices', 'icon': '💰'},
    {'id': 'legal_notice', 'name': 'Legal Notice (General)', 'nameHindi': 'कानूनी नोटिस', 'category': 'notices', 'icon': '⚖️'},
    {'id': 'demand_letter', 'name': 'Demand Letter', 'nameHindi': 'मांग पत्र', 'category': 'notices', 'icon': '📬'},
    {'id': 'notice_to_employee', 'name': 'Notice to Employee', 'nameHindi': 'कर्मचारी नोटिस', 'category': 'notices', 'icon': '🔔'},
    // HR & Compliance
    {'id': 'appointment_letter', 'name': 'Appointment Letter', 'nameHindi': 'नियुक्ति पत्र', 'category': 'hr', 'icon': '📄'},
    {'id': 'warning_letter', 'name': 'Warning Letter', 'nameHindi': 'चेतावनी पत्र', 'category': 'hr', 'icon': '⚠️'},
    {'id': 'termination_letter', 'name': 'Termination Letter', 'nameHindi': 'बर्खास्तगी पत्र', 'category': 'hr', 'icon': '🛑'},
    {'id': 'freelancer_agreement', 'name': 'Freelancer Agreement', 'nameHindi': 'फ्रीलांसर अनुबंध', 'category': 'hr', 'icon': '🤝'},
    // Business Setup
    {'id': 'partnership_deed', 'name': 'Partnership Deed', 'nameHindi': 'साझेदारी विलेख', 'category': 'business', 'icon': '📜'},
    {'id': 'mou', 'name': 'MOU', 'nameHindi': 'समझौता ज्ञापन', 'category': 'business', 'icon': '🤝'},
    {'id': 'service_agreement', 'name': 'Service Agreement', 'nameHindi': 'सेवा अनुबंध', 'category': 'business', 'icon': '💼'},
  ];
}
