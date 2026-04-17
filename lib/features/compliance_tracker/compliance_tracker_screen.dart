import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme.dart';
import '../../core/constants/compliance_data.dart';
import '../../core/models/compliance_item_model.dart';
import '../../core/services/locale_service.dart';
import '../../shared/widgets/shared_widgets.dart';

final complianceItemsProvider =
    StateNotifierProvider<ComplianceNotifier, List<ComplianceItem>>((ref) {
  return ComplianceNotifier();
});

class ComplianceNotifier extends StateNotifier<List<ComplianceItem>> {
  ComplianceNotifier()
      : super(ComplianceData.getDefaultItems('user'));

  void toggleStatus(String id) {
    state = state.map((item) {
      if (item.id == id) {
        item.status = item.status == ComplianceStatus.completed
            ? ComplianceStatus.pending
            : ComplianceStatus.completed;
        item.completedAt = item.status == ComplianceStatus.completed ? DateTime.now() : null;
        return item;
      }
      return item;
    }).toList();
  }

  void addCustomItem(ComplianceItem item) {
    state = [...state, item];
  }
}

class ComplianceTrackerScreen extends ConsumerStatefulWidget {
  const ComplianceTrackerScreen({super.key});

  @override
  ConsumerState<ComplianceTrackerScreen> createState() =>
      _ComplianceTrackerScreenState();
}

class _ComplianceTrackerScreenState
    extends ConsumerState<ComplianceTrackerScreen> {
  DateTime _selectedMonth = DateTime.now();
  String _expandedCategory = '';

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final items = ref.watch(complianceItemsProvider);

    final total = items.length;
    final completed = items.where((i) => i.status == ComplianceStatus.completed).length;
    final pending = items.where((i) => i.status == ComplianceStatus.pending && !i.isOverdue).length;
    final overdue = items.where((i) => i.isOverdue).length;

    final grouped = _groupByCategory(items);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(lang == 'hi' ? 'अनुपालन ट्रैकर' : 'Compliance Tracker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => _showReminderSettings(context, lang),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        onPressed: () => _showAddCustomItem(context, lang),
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(lang == 'hi' ? 'जोड़ें' : 'Add',
            style: const TextStyle(color: Colors.white)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          // Summary row
          Row(
            children: [
              _StatCard(label: lang == 'hi' ? 'कुल' : 'Total', value: '$total', color: AppColors.primary),
              const SizedBox(width: 8),
              _StatCard(label: lang == 'hi' ? 'पूरे' : 'Done', value: '$completed', color: AppColors.success),
              const SizedBox(width: 8),
              _StatCard(label: lang == 'hi' ? 'बाकी' : 'Pending', value: '$pending', color: AppColors.warning),
              const SizedBox(width: 8),
              _StatCard(label: lang == 'hi' ? 'देर' : 'Overdue', value: '$overdue', color: AppColors.error),
            ],
          ),
          const SizedBox(height: 16),

          // Mini calendar
          _buildMiniCalendar(lang, items),
          const SizedBox(height: 16),

          // Category sections
          ...grouped.entries.map((entry) {
            return _buildCategorySection(context, lang, entry.key, entry.value);
          }),
        ],
      ),
    );
  }

  Widget _buildMiniCalendar(String lang, List<ComplianceItem> items) {
    final now = DateTime.now();
    final daysInMonth = DateUtils.getDaysInMonth(_selectedMonth.year, _selectedMonth.month);
    final firstDayOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final startingWeekday = firstDayOfMonth.weekday % 7;

    // Get due dates for this month
    final dueDays = items
        .where((i) => i.nextDueDate.year == _selectedMonth.year && i.nextDueDate.month == _selectedMonth.month)
        .map((i) => i.nextDueDate.day)
        .toSet();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // Month nav
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () => setState(() => _selectedMonth = DateTime(
                    _selectedMonth.year, _selectedMonth.month - 1)),
                iconSize: 20,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              Text(
                _monthName(_selectedMonth.month, lang) + ' ${_selectedMonth.year}',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () => setState(() => _selectedMonth = DateTime(
                    _selectedMonth.year, _selectedMonth.month + 1)),
                iconSize: 20,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Day headers
          Row(
            children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                .map((d) => Expanded(
                      child: Center(
                        child: Text(d,
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 4),
          // Calendar grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1,
            ),
            itemCount: daysInMonth + startingWeekday,
            itemBuilder: (context, index) {
              if (index < startingWeekday) return const SizedBox.shrink();
              final day = index - startingWeekday + 1;
              final isToday = now.year == _selectedMonth.year &&
                  now.month == _selectedMonth.month &&
                  now.day == day;
              final hasDue = dueDays.contains(day);

              return Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: isToday ? AppColors.primary : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '$day',
                        style: TextStyle(
                          fontSize: 12,
                          color: isToday ? Colors.white : AppColors.textPrimary,
                          fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
                        ),
                      ),
                    ),
                  ),
                  if (hasDue && !isToday)
                    Positioned(
                      bottom: 3,
                      child: Container(
                        width: 5,
                        height: 5,
                        decoration: const BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySection(
      BuildContext context, String lang, ComplianceCategory category, List<ComplianceItem> items) {
    final catLabels = {
      ComplianceCategory.gst: {'hi': '🧾 GST अनुपालन', 'en': '🧾 GST Compliance'},
      ComplianceCategory.labour: {'hi': '👷 श्रम अनुपालन', 'en': '👷 Labour Compliance'},
      ComplianceCategory.tax: {'hi': '💰 कर अनुपालन', 'en': '💰 Tax Compliance'},
      ComplianceCategory.license: {'hi': '📋 लाइसेंस नवीनीकरण', 'en': '📋 License Renewals'},
      ComplianceCategory.custom: {'hi': '⚙️ अन्य', 'en': '⚙️ Custom'},
    };

    final catKey = catLabels[category]!;
    final isExpanded = _expandedCategory == category.name;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => setState(() =>
                _expandedCategory = isExpanded ? '' : category.name),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      lang == 'hi' ? catKey['hi']! : catKey['en']!,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('${items.length}',
                        style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(width: 8),
                  Icon(isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      color: AppColors.textSecondary),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            const Divider(height: 1),
            ...items.map((item) => _buildComplianceItem(context, lang, item)),
          ],
        ],
      ),
    );
  }

  Widget _buildComplianceItem(
      BuildContext context, String lang, ComplianceItem item) {
    final isCompleted = item.status == ComplianceStatus.completed;
    final isOverdue = item.isOverdue;

    Color statusColor;
    if (isCompleted) statusColor = AppColors.success;
    else if (isOverdue) statusColor = AppColors.error;
    else if (item.daysUntilDue <= 7) statusColor = AppColors.error;
    else if (item.daysUntilDue <= 14) statusColor = AppColors.warning;
    else statusColor = AppColors.success;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.divider, width: 0.5)),
      ),
      child: Row(
        children: [
          // Status indicator
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lang == 'hi' ? item.nameHindi : item.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                    color: isCompleted ? AppColors.textSecondary : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    ComplianceStatusChip(
                      status: isCompleted ? 'completed' : (isOverdue ? 'overdue' : 'pending'),
                      daysLeft: isCompleted ? null : item.daysUntilDue,
                      lang: lang,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${item.nextDueDate.day}/${item.nextDueDate.month}/${item.nextDueDate.year}',
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Mark done button
          GestureDetector(
            onTap: () => ref.read(complianceItemsProvider.notifier).toggleStatus(item.id),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isCompleted ? AppColors.success : AppColors.background,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isCompleted ? AppColors.success : AppColors.border,
                  width: 2,
                ),
              ),
              child: isCompleted
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Map<ComplianceCategory, List<ComplianceItem>> _groupByCategory(
      List<ComplianceItem> items) {
    final map = <ComplianceCategory, List<ComplianceItem>>{};
    for (final item in items) {
      map.putIfAbsent(item.category, () => []).add(item);
    }
    return map;
  }

  String _monthName(int month, String lang) {
    const hiMonths = ['जनवरी', 'फरवरी', 'मार्च', 'अप्रैल', 'मई', 'जून', 'जुलाई', 'अगस्त', 'सितम्बर', 'अक्टूबर', 'नवम्बर', 'दिसम्बर'];
    const enMonths = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    return lang == 'hi' ? hiMonths[month - 1] : enMonths[month - 1];
  }

  void _showAddCustomItem(BuildContext context, String lang) {
    final nameCtrl = TextEditingController();
    DateTime dueDate = DateTime.now().add(const Duration(days: 30));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 16, right: 16, top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 16),
            Text(lang == 'hi' ? 'नया Compliance जोड़ें' : 'Add Custom Compliance',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(
                labelText: lang == 'hi' ? 'नाम' : 'Name',
                hintText: lang == 'hi' ? 'जैसे: Trade License Renewal' : 'e.g. Trade License Renewal',
              ),
            ),
            const SizedBox(height: 16),
            VakilButton(
              text: lang == 'hi' ? 'जोड़ें' : 'Add',
              onPressed: () {
                if (nameCtrl.text.isNotEmpty) {
                  ref.read(complianceItemsProvider.notifier).addCustomItem(
                    ComplianceItem(
                      id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
                      businessId: 'user',
                      name: nameCtrl.text,
                      nameHindi: nameCtrl.text,
                      description: 'Custom compliance item',
                      descriptionHindi: 'कस्टम compliance',
                      category: ComplianceCategory.custom,
                      frequency: ComplianceFrequency.oneTime,
                      specificDate: dueDate,
                      penaltyInfo: '',
                      penaltyInfoHindi: '',
                      applicableTo: ['all'],
                      status: ComplianceStatus.pending,
                      createdAt: DateTime.now(),
                    ),
                  );
                  Navigator.pop(context);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showReminderSettings(BuildContext context, String lang) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(lang == 'hi' ? '🔔 Reminder Settings' : '🔔 Reminder Settings',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            _ReminderTile(label: lang == 'hi' ? '7 दिन पहले' : '7 days before', value: true),
            _ReminderTile(label: lang == 'hi' ? '3 दिन पहले' : '3 days before', value: true),
            _ReminderTile(label: lang == 'hi' ? '1 दिन पहले' : '1 day before', value: false),
            _ReminderTile(label: lang == 'hi' ? 'WhatsApp reminder' : 'WhatsApp reminder', value: true),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatCard({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: color)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _ReminderTile extends StatefulWidget {
  final String label;
  final bool value;
  const _ReminderTile({required this.label, required this.value});

  @override
  State<_ReminderTile> createState() => _ReminderTileState();
}

class _ReminderTileState extends State<_ReminderTile> {
  late bool _val;
  @override
  void initState() { super.initState(); _val = widget.value; }

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      value: _val,
      onChanged: (v) => setState(() => _val = v),
      title: Text(widget.label, style: const TextStyle(fontSize: 14)),
      activeColor: AppColors.primary,
      contentPadding: EdgeInsets.zero,
    );
  }
}
