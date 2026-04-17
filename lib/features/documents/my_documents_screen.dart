import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../app/routes.dart';
import '../../core/models/compliance_item_model.dart';
import '../../core/services/locale_service.dart';
import '../../shared/widgets/shared_widgets.dart';

// Mock documents provider
final documentsProvider = StateNotifierProvider<DocumentsNotifier, List<DocumentModel>>(
    (ref) => DocumentsNotifier());

class DocumentsNotifier extends StateNotifier<List<DocumentModel>> {
  DocumentsNotifier() : super(_mockDocuments);

  void delete(String id) => state = state.where((d) => d.id != id).toList();

  static final List<DocumentModel> _mockDocuments = [
    DocumentModel(
      id: '1', userId: 'user',
      name: 'GST Demand Notice - March 2025',
      source: DocumentSource.uploaded,
      type: DocumentType.gstNotice,
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    DocumentModel(
      id: '2', userId: 'user',
      name: 'Vendor Agreement - ABC Supplies',
      source: DocumentSource.generated,
      type: DocumentType.vendorAgreement,
      templateType: 'vendor_agreement',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    DocumentModel(
      id: '3', userId: 'user',
      name: 'Employee Appointment Letter - Suresh',
      source: DocumentSource.generated,
      type: DocumentType.employeeAgreement,
      templateType: 'appointment_letter',
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
    DocumentModel(
      id: '4', userId: 'user',
      name: 'Income Tax Notice FY24',
      source: DocumentSource.uploaded,
      type: DocumentType.incomeTaxNotice,
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
    ),
    DocumentModel(
      id: '5', userId: 'user',
      name: 'Shop Rent Deed - MG Road',
      source: DocumentSource.generated,
      type: DocumentType.rentDeed,
      templateType: 'rent_deed_residential',
      createdAt: DateTime.now().subtract(const Duration(days: 20)),
    ),
  ];
}

class MyDocumentsScreen extends ConsumerStatefulWidget {
  const MyDocumentsScreen({super.key});

  @override
  ConsumerState<MyDocumentsScreen> createState() => _MyDocumentsScreenState();
}

class _MyDocumentsScreenState extends ConsumerState<MyDocumentsScreen> {
  String _searchQuery = '';
  String _selectedFilter = 'all';
  final _searchCtrl = TextEditingController();

  final Map<String, Map<String, String>> _filters = {
    'all': {'hi': 'सभी', 'en': 'All'},
    'notices': {'hi': 'नोटिस', 'en': 'Notices'},
    'agreements': {'hi': 'अनुबंध', 'en': 'Agreements'},
    'generated': {'hi': 'बनाए गए', 'en': 'Generated'},
    'uploaded': {'hi': 'अपलोड', 'en': 'Uploaded'},
  };

  List<DocumentModel> _filteredDocs(List<DocumentModel> docs) {
    return docs.where((d) {
      final matchesSearch = _searchQuery.isEmpty ||
          d.name.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesFilter = _selectedFilter == 'all' ||
          (_selectedFilter == 'notices' && (d.type == DocumentType.gstNotice || d.type == DocumentType.incomeTaxNotice || d.type == DocumentType.labourNotice || d.type == DocumentType.municipalityNotice)) ||
          (_selectedFilter == 'agreements' && (d.type == DocumentType.vendorAgreement || d.type == DocumentType.rentDeed || d.type == DocumentType.employeeAgreement)) ||
          (_selectedFilter == 'generated' && d.source == DocumentSource.generated) ||
          (_selectedFilter == 'uploaded' && d.source == DocumentSource.uploaded);
      return matchesSearch && matchesFilter;
    }).toList();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final allDocs = ref.watch(documentsProvider);
    final filtered = _filteredDocs(allDocs);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(lang == 'hi' ? 'मेरे दस्तावेज़' : 'My Documents'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push(AppRoutes.documentGenerator),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: lang == 'hi' ? 'दस्तावेज़ खोजें...' : 'Search documents...',
                prefixIcon: const Icon(Icons.search, color: AppColors.textHint),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),

          // Filter chips
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: _filters.entries.map((entry) {
                  final selected = _selectedFilter == entry.key;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedFilter = entry.key),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: selected ? AppColors.primary : AppColors.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: selected ? AppColors.primary : AppColors.border),
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

          // Document count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  '${filtered.length} ${lang == 'hi' ? 'दस्तावेज़' : 'documents'}',
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
                const Spacer(),
                // Storage indicator
                Text(
                  '2.4 MB / 100 MB',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Document list
          Expanded(
            child: filtered.isEmpty
                ? _buildEmptyState(lang)
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) =>
                        _buildDocCard(context, lang, filtered[index]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocCard(BuildContext context, String lang, DocumentModel doc) {
    final typeInfo = _getTypeInfo(doc.type);
    final daysAgo = DateTime.now().difference(doc.createdAt).inDays;
    final timeStr = daysAgo == 0
        ? (lang == 'hi' ? 'आज' : 'Today')
        : daysAgo == 1
            ? (lang == 'hi' ? 'कल' : 'Yesterday')
            : (lang == 'hi' ? '$daysAgo दिन पहले' : '$daysAgo days ago');

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: typeInfo['bg'] as Color,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(child: Text(typeInfo['emoji'] as String, style: const TextStyle(fontSize: 22))),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(doc.name,
                      style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: doc.source == DocumentSource.generated
                              ? AppColors.infoLight
                              : AppColors.warningLight,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          doc.source == DocumentSource.generated
                              ? (lang == 'hi' ? 'AI द्वारा' : 'Generated')
                              : (lang == 'hi' ? 'अपलोड' : 'Uploaded'),
                          style: TextStyle(
                            fontSize: 10,
                            color: doc.source == DocumentSource.generated ? AppColors.info : AppColors.warning,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(timeStr, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    ],
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (action) => _handleDocAction(context, lang, doc, action),
              itemBuilder: (_) => [
                PopupMenuItem(value: 'view', child: Row(children: [const Icon(Icons.visibility_outlined, size: 16), const SizedBox(width: 8), Text(lang == 'hi' ? 'देखें' : 'View')])),
                PopupMenuItem(value: 'share', child: Row(children: [const Icon(Icons.share_outlined, size: 16), const SizedBox(width: 8), Text(lang == 'hi' ? 'Share' : 'Share')])),
                PopupMenuItem(value: 'delete', child: Row(children: [const Icon(Icons.delete_outline, size: 16, color: AppColors.error), const SizedBox(width: 8), Text(lang == 'hi' ? 'हटाएं' : 'Delete', style: const TextStyle(color: AppColors.error))])),
              ],
              child: const Icon(Icons.more_vert, color: AppColors.textSecondary, size: 20),
            ),
          ],
        ),
      ),
    );
  }

  void _handleDocAction(BuildContext context, String lang, DocumentModel doc, String action) {
    switch (action) {
      case 'delete':
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(lang == 'hi' ? 'हटाएं?' : 'Delete?'),
            content: Text(lang == 'hi' ? 'क्या आप "${doc.name}" हटाना चाहते हैं?' : 'Delete "${doc.name}"?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: Text(lang == 'hi' ? 'रद्द' : 'Cancel')),
              TextButton(
                onPressed: () {
                  ref.read(documentsProvider.notifier).delete(doc.id);
                  Navigator.pop(ctx);
                },
                child: Text(lang == 'hi' ? 'हटाएं' : 'Delete',
                    style: const TextStyle(color: AppColors.error)),
              ),
            ],
          ),
        );
        break;
      case 'share':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(lang == 'hi' ? 'Share हो रहा है...' : 'Sharing...')),
        );
        break;
    }
  }

  Widget _buildEmptyState(String lang) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('📂', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 16),
          Text(lang == 'hi' ? 'अभी तक कोई दस्तावेज़ नहीं' : 'No documents yet',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(
            lang == 'hi' ? 'नोटिस अपलोड करें या दस्तावेज़ बनाएं' : 'Upload a notice or create a document',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () => context.push(AppRoutes.documentAnalyzer),
                icon: const Icon(Icons.upload_file, size: 16),
                label: Text(lang == 'hi' ? 'अपलोड करें' : 'Upload'),
                style: ElevatedButton.styleFrom(minimumSize: const Size(0, 42)),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () => context.push(AppRoutes.documentGenerator),
                icon: const Icon(Icons.add, size: 16),
                label: Text(lang == 'hi' ? 'बनाएं' : 'Create'),
                style: OutlinedButton.styleFrom(minimumSize: const Size(0, 42)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getTypeInfo(DocumentType type) {
    switch (type) {
      case DocumentType.gstNotice:
        return {'emoji': '🧾', 'bg': const Color(0xFFFFF3E0)};
      case DocumentType.incomeTaxNotice:
        return {'emoji': '📑', 'bg': const Color(0xFFE8EEF5)};
      case DocumentType.vendorAgreement:
        return {'emoji': '🤝', 'bg': const Color(0xFFE8F5E9)};
      case DocumentType.rentDeed:
        return {'emoji': '🏠', 'bg': const Color(0xFFF3E5F5)};
      case DocumentType.employeeAgreement:
        return {'emoji': '👔', 'bg': const Color(0xFFE0F7FA)};
      default:
        return {'emoji': '📄', 'bg': AppColors.background};
    }
  }
}
