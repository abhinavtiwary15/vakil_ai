import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../app/routes.dart';
import '../../core/constants/compliance_data.dart';
import '../../core/constants/app_strings.dart';
import '../../core/models/compliance_item_model.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/locale_service.dart';
import '../../shared/widgets/shared_widgets.dart';

class BusinessProfileSetupScreen extends ConsumerStatefulWidget {
  const BusinessProfileSetupScreen({super.key});

  @override
  ConsumerState<BusinessProfileSetupScreen> createState() =>
      _BusinessProfileSetupScreenState();
}

class _BusinessProfileSetupScreenState
    extends ConsumerState<BusinessProfileSetupScreen> {
  int _currentStep = 0;
  bool _isSaving = false;

  // Step 1
  final _businessNameCtrl = TextEditingController();
  String _businessType = 'Proprietorship';
  String _industry = 'Food & Beverage';
  String _city = '';
  String _state = 'Rajasthan';

  // Step 2
  final _gstinCtrl = TextEditingController();
  final _udyamCtrl = TextEditingController();
  final _panCtrl = TextEditingController();
  final _fssaiCtrl = TextEditingController();
  final _esicCtrl = TextEditingController();
  final _epfoCtrl = TextEditingController();
  final _iecCtrl = TextEditingController();
  bool _hasGstin = false;
  bool _hasUdyam = false;
  bool _hasPan = false;
  bool _hasFssai = false;
  bool _hasEsic = false;
  bool _hasEpfo = false;
  bool _hasIec = false;
  bool _shopAct = false;
  bool _tradeLicense = false;

  // Step 3
  String _employeeCount = '<5';
  String _annualTurnover = '<20L';
  String _language = 'hi';

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(AppStrings.get('business_setup_title', lang)),
        leading: _currentStep > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() => _currentStep--),
              )
            : null,
      ),
      body: Column(
        children: [
          // Progress indicator
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: List.generate(3, (i) {
                    return Expanded(
                      child: Container(
                        height: 4,
                        margin: EdgeInsets.only(right: i < 2 ? 4 : 0),
                        decoration: BoxDecoration(
                          color: i <= _currentStep ? AppColors.primary : AppColors.border,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 8),
                Text(
                  AppStrings.get('step_n_of_m', lang)
                      .replaceAll('{n}', '${_currentStep + 1}')
                      .replaceAll('{m}', '3'),
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: [
                _buildStep1(lang),
                _buildStep2(lang),
                _buildStep3(lang),
              ][_currentStep],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: VakilButton(
              text: _currentStep < 2
                  ? AppStrings.get('next', lang)
                  : AppStrings.get('save_profile', lang),
              onPressed: _isSaving ? null : _handleNext,
              isLoading: _isSaving,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep1(String lang) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppStrings.get('business_identity', lang),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
        Text(AppStrings.get('business_identity', lang == 'hi' ? 'en' : 'hi'),
            style: const TextStyle(color: AppColors.textSecondary)),
        const SizedBox(height: 24),

        TextFormField(
          controller: _businessNameCtrl,
          decoration: InputDecoration(
            labelText: AppStrings.get('business_name', lang),
            hintText: AppStrings.get('business_name_hint', lang),
          ),
        ),
        const SizedBox(height: 16),

        DropdownButtonFormField<String>(
          value: _businessType,
          decoration: InputDecoration(labelText: AppStrings.get('business_type', lang)),
          items: ComplianceData.businessTypes.map((t) {
            String label = t;
            // Map common types to localized keys
            if (t == 'Proprietorship') label = AppStrings.get('proprietorship', lang);
            if (t == 'Partnership') label = AppStrings.get('partnership', lang);
            if (t == 'LLP') label = AppStrings.get('llp', lang);
            if (t == 'Private Limited') label = AppStrings.get('pvt_ltd', lang);
            if (t == 'OPC') label = AppStrings.get('opc', lang);
            
            return DropdownMenuItem(value: t, child: Text(label));
          }).toList(),
          onChanged: (v) => setState(() => _businessType = v!),
        ),
        const SizedBox(height: 16),

        DropdownButtonFormField<String>(
          value: _industry,
          decoration: InputDecoration(labelText: AppStrings.get('industry', lang)),
          items: ComplianceData.industries.map((i) {
            String label = i;
            // Map industries to localized keys
            if (i == 'Food & Beverage') label = AppStrings.get('food_beverage', lang);
            if (i == 'Manufacturing') label = AppStrings.get('manufacturing', lang);
            if (i == 'Trading') label = AppStrings.get('trading', lang);
            if (i == 'Services') label = AppStrings.get('services', lang);
            if (i == 'Retail') label = AppStrings.get('retail', lang);
            if (i == 'Construction') label = AppStrings.get('construction', lang);
            if (i == 'Healthcare') label = AppStrings.get('healthcare', lang);
            if (i == 'IT & Technology') label = AppStrings.get('it_tech', lang);
            if (i == 'Other') label = AppStrings.get('other', lang);
            
            return DropdownMenuItem(value: i, child: Text(label));
          }).toList(),
          onChanged: (v) => setState(() => _industry = v!),
        ),
        const SizedBox(height: 16),

        TextFormField(
          onChanged: (v) => _city = v,
          decoration: InputDecoration(
            labelText: AppStrings.get('city', lang),
            hintText: AppStrings.get('city_hint', lang),
          ),
        ),
        const SizedBox(height: 16),

        DropdownButtonFormField<String>(
          value: _state,
          decoration: InputDecoration(labelText: AppStrings.get('state', lang)),
          items: ComplianceData.indianStates.map((s) {
            String label = s;
            if (s == 'Rajasthan') label = AppStrings.get('rajasthan', lang);
            if (s == 'Maharashtra') label = AppStrings.get('maharashtra', lang);
            if (s == 'Delhi') label = AppStrings.get('delhi', lang);
            if (s == 'Gujarat') label = AppStrings.get('gujarat', lang);
            if (s == 'Haryana') label = AppStrings.get('haryana', lang);
            if (s == 'Uttar Pradesh') label = AppStrings.get('uttar_pradesh', lang);
            
            return DropdownMenuItem(value: s, child: Text(label));
          }).toList(),
          onChanged: (v) => setState(() => _state = v!),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildStep2(String lang) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppStrings.get('registrations_title', lang),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
        Text(AppStrings.get('registrations_title', lang == 'hi' ? 'en' : 'hi'),
            style: const TextStyle(color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.infoLight,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            AppStrings.get('add_later', lang),
            style: const TextStyle(color: AppColors.info, fontSize: 12),
          ),
        ),
        const SizedBox(height: 20),

        _buildRegistrationTile(
          label: 'GSTIN',
          hindiLabel: AppStrings.get('gstin_label', lang),
          value: _hasGstin,
          controller: _gstinCtrl,
          onChanged: (v) => setState(() => _hasGstin = v),
          hint: '22AAAAA0000A1Z5',
        ),
        _buildRegistrationTile(
          label: 'UDYAM / MSME',
          hindiLabel: AppStrings.get('udyam_label', lang),
          value: _hasUdyam,
          controller: _udyamCtrl,
          onChanged: (v) => setState(() => _hasUdyam = v),
          hint: 'UDYAM-RJ-XX-XXXXXXX',
        ),
        _buildRegistrationTile(
          label: 'PAN',
          hindiLabel: AppStrings.get('pan_label', lang),
          value: _hasPan,
          controller: _panCtrl,
          onChanged: (v) => setState(() => _hasPan = v),
          hint: 'AAAAA0000A',
        ),
        _buildRegistrationTile(
          label: 'FSSAI',
          hindiLabel: AppStrings.get('fssai_label', lang),
          value: _hasFssai,
          controller: _fssaiCtrl,
          onChanged: (v) => setState(() => _hasFssai = v),
          hint: '14-digit FSSAI Number',
        ),
        _buildRegistrationTile(
          label: 'ESIC',
          hindiLabel: AppStrings.get('esic_label', lang),
          value: _hasEsic,
          controller: _esicCtrl,
          onChanged: (v) => setState(() => _hasEsic = v),
          hint: 'ESIC Registration Number',
        ),
        _buildRegistrationTile(
          label: 'EPFO / PF',
          hindiLabel: AppStrings.get('epfo_label', lang),
          value: _hasEpfo,
          controller: _epfoCtrl,
          onChanged: (v) => setState(() => _hasEpfo = v),
          hint: 'PF Establishment Code',
        ),

        // Toggle-only items
        _buildToggleTile(
          'Shop & Establishment Act',
          AppStrings.get('shop_act_label', lang),
          _shopAct,
          (v) => setState(() => _shopAct = v),
        ),
        _buildToggleTile(
          'Trade License',
          AppStrings.get('trade_license_label', lang),
          _tradeLicense,
          (v) => setState(() => _tradeLicense = v),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildRegistrationTile({
    required String label,
    required String hindiLabel,
    required bool value,
    required TextEditingController controller,
    required ValueChanged<bool> onChanged,
    required String hint,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
                  Text(hindiLabel, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeColor: AppColors.primary,
            ),
          ],
        ),
        if (value) ...[
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            decoration: InputDecoration(hintText: hint, isDense: true),
          ),
          const SizedBox(height: 8),
        ],
        const Divider(height: 16),
      ],
    );
  }

  Widget _buildToggleTile(String label, String hindiLabel, bool value, ValueChanged<bool> onChanged) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
                  Text(hindiLabel, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            Switch(value: value, onChanged: onChanged, activeColor: AppColors.primary),
          ],
        ),
        const Divider(height: 16),
      ],
    );
  }

  Widget _buildStep3(String lang) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppStrings.get('business_scale', lang),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
        Text(AppStrings.get('business_scale_subtitle', lang),
            style: const TextStyle(color: AppColors.textSecondary)),
        const SizedBox(height: 24),

        Text(AppStrings.get('num_employees', lang),
            style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          children: [
            {'val': '<5', 'key': 'emp_lt_5'},
            {'val': '5-20', 'key': 'emp_5_20'},
            {'val': '20-100', 'key': 'emp_20_100'},
            {'val': '100+', 'key': 'emp_gt_100'},
          ].map((opt) {
            final selected = _employeeCount == opt['val'];
            return ChoiceChip(
              label: Text(AppStrings.get(opt['key']!, lang)),
              selected: selected,
              selectedColor: AppColors.primary.withOpacity(0.15),
              onSelected: (_) => setState(() => _employeeCount = opt['val']!),
              labelStyle: TextStyle(
                color: selected ? AppColors.primary : AppColors.textSecondary,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 24),
        Text(AppStrings.get('annual_turnover', lang),
            style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            {'val': '<20L', 'key': 'turnover_lt_20l'},
            {'val': '20L-75L', 'key': 'turnover_20l_75l'},
            {'val': '75L-2Cr', 'key': 'turnover_75l_2cr'},
            {'val': '2Cr+', 'key': 'turnover_gt_2cr'},
          ].map((opt) {
            final selected = _annualTurnover == opt['val'];
            return ChoiceChip(
              label: Text(AppStrings.get(opt['key']!, lang)),
              selected: selected,
              selectedColor: AppColors.primary.withOpacity(0.15),
              onSelected: (_) => setState(() => _annualTurnover = opt['val']!),
              labelStyle: TextStyle(
                color: selected ? AppColors.primary : AppColors.textSecondary,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                fontSize: 12,
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 24),
        Text(AppStrings.get('language_pref', lang),
            style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _LangOption(
                label: 'हिंदी',
                sublabel: 'Hindi',
                selected: _language == 'hi',
                onTap: () => setState(() => _language = 'hi'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _LangOption(
                label: 'English',
                sublabel: 'अंग्रेजी',
                selected: _language == 'en',
                onTap: () => setState(() => _language = 'en'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  void _handleNext() {
    if (_currentStep < 2) {
      setState(() => _currentStep++);
    } else {
      _saveProfile();
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);
    try {
      final profile = BusinessProfile(
        businessName: _businessNameCtrl.text.isEmpty ? 'My Business' : _businessNameCtrl.text,
        businessType: _businessType,
        industry: _industry,
        city: _city.isEmpty ? 'Not set' : _city,
        state: _state,
        gstin: _hasGstin ? _gstinCtrl.text : null,
        udyam: _hasUdyam ? _udyamCtrl.text : null,
        pan: _hasPan ? _panCtrl.text : null,
        fssai: _hasFssai ? _fssaiCtrl.text : null,
        esic: _hasEsic ? _esicCtrl.text : null,
        epfo: _hasEpfo ? _epfoCtrl.text : null,
        shopAct: _shopAct,
        tradeLicense: _tradeLicense,
        employeeCount: _employeeCount,
        annualTurnover: _annualTurnover,
      );

      final auth = ref.read(authServiceProvider);
      final uid = auth.currentUser?.uid ?? 'dev_user';
      await auth.saveBusinessProfile(uid, profile);
      await auth.updateUserProfile(uid, {'language': _language});

      if (mounted) context.go(AppRoutes.subscription);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

class _LangOption extends StatelessWidget {
  final String label;
  final String sublabel;
  final bool selected;
  final VoidCallback onTap;

  const _LangOption({
    required this.label,
    required this.sublabel,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withOpacity(0.1) : AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(label, style: TextStyle(
              fontWeight: FontWeight.w600,
              color: selected ? AppColors.primary : AppColors.textPrimary,
              fontSize: 18,
            )),
            Text(sublabel, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}
