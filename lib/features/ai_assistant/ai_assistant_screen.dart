import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:uuid/uuid.dart';
import '../../app/theme.dart';
import '../../core/services/ai_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/locale_service.dart';
import '../../core/models/compliance_item_model.dart';
import '../../shared/widgets/shared_widgets.dart';
import '../../app/routes.dart';
import 'package:go_router/go_router.dart';

// Chat state provider
final chatMessagesProvider =
    StateNotifierProvider<ChatNotifier, List<ChatMessage>>((ref) {
  return ChatNotifier(ref);
});

class ChatNotifier extends StateNotifier<List<ChatMessage>> {
  final Ref _ref;
  ChatNotifier(this._ref) : super([]);

  Future<void> sendMessage(String text, String lang) async {
    final userMsg = ChatMessage(
      id: const Uuid().v4(),
      content: text,
      sender: MessageSender.user,
      timestamp: DateTime.now(),
    );

    final loadingMsg = ChatMessage(
      id: const Uuid().v4(),
      content: '',
      sender: MessageSender.ai,
      timestamp: DateTime.now(),
      isLoading: true,
    );

    state = [...state, userMsg, loadingMsg];

    final history = state
        .where((m) => !m.isLoading)
        .take(10)
        .map((m) => {'role': m.sender == MessageSender.user ? 'user' : 'assistant', 'content': m.content})
        .toList();

    try {
      final response = await _ref.read(aiServiceProvider).chat(
            message: text,
            language: lang,
            history: history,
          );

      final aiMsg = ChatMessage(
        id: loadingMsg.id,
        content: response,
        sender: MessageSender.ai,
        timestamp: DateTime.now(),
        isLoading: false,
      );

      state = state.map((m) => m.id == loadingMsg.id ? aiMsg : m).toList();
    } catch (_) {
      state = state.where((m) => m.id != loadingMsg.id).toList();
    }
  }

  void clear() => state = [];
}

class AiAssistantScreen extends ConsumerStatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  ConsumerState<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends ConsumerState<AiAssistantScreen> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isSending = false;

  final List<Map<String, String>> _quickQuestions = const [
    {'hi': 'GST नोटिस आया, क्या करूं?', 'en': 'Received GST notice, what to do?'},
    {'hi': 'किराया विवाद में क्या अधिकार हैं?', 'en': 'Rights in rent dispute?'},
    {'hi': '60 दिन से पेमेंट नहीं मिला?', 'en': 'Payment pending 60 days?'},
    {'hi': 'Employee terminate कैसे करें?', 'en': 'How to terminate employee?'},
    {'hi': 'FSSAI license प्रक्रिया क्या है?', 'en': 'FSSAI license process?'},
    {'hi': 'GST return late penalty क्या?', 'en': 'GST return late penalty?'},
    {'hi': 'Labour law में क्या rights हैं?', 'en': 'Labour law rights?'},
    {'hi': 'Shop Act renewal कैसे होता है?', 'en': 'How to renew Shop Act?'},
  ];

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    final lang = ref.read(languageProvider);
    _inputController.clear();
    setState(() => _isSending = true);
    await ref.read(chatMessagesProvider.notifier).sendMessage(text.trim(), lang);
    setState(() => _isSending = false);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final messages = ref.watch(chatMessagesProvider);
    final userAsync = ref.watch(currentUserProvider);
    final user = userAsync.valueOrNull;
    final questionsUsed = user?.aiQuestionsUsed ?? 0;
    final questionsLimit = user?.aiQuestionsLimit ?? 3;
    final isFreePlan = user?.planName == 'free' || user?.planName == null;
    final limitReached = isFreePlan && questionsUsed >= questionsLimit;

    // Auto-scroll when new messages arrive
    ref.listen(chatMessagesProvider, (_, __) => _scrollToBottom());

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(child: Text('⚖️', style: TextStyle(fontSize: 16))),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(lang == 'hi' ? 'AI सहायक' : 'AI Assistant',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                Text(lang == 'hi' ? 'ऑनलाइन • हिंदी + English' : 'Online • Hindi + English',
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ],
        ),
        actions: [
          if (messages.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () {
                ref.read(chatMessagesProvider.notifier).clear();
              },
            ),
          const LanguageToggle(),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Usage bar (free plan)
          if (isFreePlan)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppColors.surface,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        lang == 'hi'
                            ? '$questionsLimit में से $questionsUsed प्रश्न उपयोग किए'
                            : '$questionsUsed of $questionsLimit questions used this month',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      TextButton(
                        onPressed: () => context.push(AppRoutes.subscription),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                          minimumSize: const Size(0, 24),
                        ),
                        child: Text(
                          lang == 'hi' ? 'अपग्रेड करें' : 'Upgrade',
                          style: const TextStyle(fontSize: 12, color: AppColors.secondary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: questionsLimit > 0 ? questionsUsed / questionsLimit : 0,
                      backgroundColor: AppColors.border,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        questionsUsed >= questionsLimit ? AppColors.error : AppColors.primary,
                      ),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            ),

          // Messages
          Expanded(
            child: messages.isEmpty
                ? _buildEmptyState(lang)
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      return _buildMessage(messages[index], lang);
                    },
                  ),
          ),

          // Disclaimer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            color: AppColors.warningLight,
            child: Text(
              lang == 'hi'
                  ? '⚠️ यह कानूनी जानकारी है, कानूनी सलाह नहीं। जटिल मामलों में वकील से परामर्श लें।'
                  : '⚠️ This is legal information, not legal advice. Consult a lawyer for complex matters.',
              style: const TextStyle(fontSize: 11, color: AppColors.warning),
              textAlign: TextAlign.center,
            ),
          ),

          // Input bar
          _buildInputBar(lang, limitReached),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String lang) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SizedBox(height: 24),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Center(child: Text('🤖', style: TextStyle(fontSize: 40))),
          ),
          const SizedBox(height: 16),
          Text(
            lang == 'hi' ? 'नमस्ते! मैं VakilAI हूं' : 'Hello! I\'m VakilAI',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            lang == 'hi'
                ? 'आपके business के किसी भी कानूनी सवाल का जवाब देने के लिए यहाँ हूं।'
                : 'I\'m here to answer any legal questions about your business.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 28),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              lang == 'hi' ? 'लोकप्रिय सवाल:' : 'Popular questions:',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _quickQuestions.map((q) {
              return GestureDetector(
                onTap: () => _sendMessage(lang == 'hi' ? q['hi']! : q['en']!),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    lang == 'hi' ? q['hi']! : q['en']!,
                    style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMessage(ChatMessage message, String lang) {
    final isUser = message.sender == MessageSender.user;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(child: Text('⚖️', style: TextStyle(fontSize: 14))),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isUser ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(isUser ? 16 : 4),
                  topRight: Radius.circular(isUser ? 4 : 16),
                  bottomLeft: const Radius.circular(16),
                  bottomRight: const Radius.circular(16),
                ),
                border: isUser ? null : Border.all(color: AppColors.border),
              ),
              child: message.isLoading
                  ? _buildTypingIndicator()
                  : isUser
                      ? Text(
                          message.content,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            MarkdownBody(
                              data: message.content,
                              styleSheet: MarkdownStyleSheet(
                                p: const TextStyle(fontSize: 14, color: AppColors.textPrimary, height: 1.5),
                                strong: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                                h2: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.primary),
                                h3: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                                listBullet: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _formatTime(message.timestamp),
                              style: const TextStyle(fontSize: 10, color: AppColors.textHint),
                            ),
                          ],
                        ),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('AI सोच रहा है', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        const SizedBox(width: 8),
        SizedBox(
          width: 36,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(3, (i) {
              return _BouncingDot(delay: Duration(milliseconds: i * 150));
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildInputBar(String lang, bool limitReached) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: SafeArea(
        top: false,
        child: limitReached
            ? UpgradePromptCard(onUpgrade: () => context.push(AppRoutes.subscription))
            : Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _inputController,
                      maxLines: 4,
                      minLines: 1,
                      textInputAction: TextInputAction.send,
                      onSubmitted: _sendMessage,
                      decoration: InputDecoration(
                        hintText: lang == 'hi' ? 'कुछ भी पूछें...' : 'Ask anything...',
                        hintStyle: const TextStyle(color: AppColors.textHint),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                        ),
                        filled: true,
                        fillColor: AppColors.background,
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.attach_file, size: 20),
                          onPressed: () => context.push(AppRoutes.documentAnalyzer),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _isSending ? null : () => _sendMessage(_inputController.text),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _isSending ? AppColors.border : AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: _isSending
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class _BouncingDot extends StatefulWidget {
  final Duration delay;
  const _BouncingDot({required this.delay});

  @override
  State<_BouncingDot> createState() => _BouncingDotState();
}

class _BouncingDotState extends State<_BouncingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _anim = Tween<double>(begin: 0, end: -6).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    Future.delayed(widget.delay, () {
      if (mounted) _ctrl.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Transform.translate(
        offset: Offset(0, _anim.value),
        child: Container(
          width: 7,
          height: 7,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
