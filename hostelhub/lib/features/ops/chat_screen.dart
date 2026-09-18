import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../data/backend_provider.dart';
import '../../data/models/chat_message.dart';
import '../../data/models/user.dart';
import '../../presentation/widgets/glass.dart';
import '../auth/auth_controller.dart';
import '../onboarding/hostel_providers.dart';
import 'ops_providers.dart';

/// Owner: pick an inmate to chat with.
class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final propAsync = ref.watch(currentPropertyProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat'),
        backgroundColor: Colors.transparent,
      ),
      extendBodyBehindAppBar: true,
      body: GlassBackground(
        dark: isDark,
        child: SafeArea(
          child: propAsync.when(
            data: (prop) => prop == null
                ? Center(
                    child: Text('Set up your hostel first.',
                        style: textTheme.bodyMedium))
                : _list(context, ref, prop.id, textTheme),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => const Center(child: Text('Error')),
          ),
        ),
      ),
    );
  }

  Widget _list(BuildContext context, WidgetRef ref, String propertyId,
      TextTheme textTheme) {
    final inmates = ref.watch(inmatesProvider(propertyId)).value ?? const [];
    if (inmates.isEmpty) {
      return Center(child: Text('No inmates yet.', style: textTheme.bodyMedium));
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      children: [
        for (final i in inmates)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GlassCard(
              onTap: () => context.go('/chat/${i.id}'),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withValues(alpha: 0.16),
                    ),
                    child: const Icon(Icons.person_rounded,
                        size: 20, color: AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Text(i.name, style: textTheme.titleMedium)),
                  const Icon(Icons.chat_bubble_outline_rounded,
                      size: 20, color: AppColors.primary),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// A chat thread between the owner and one inmate.
class ChatThreadScreen extends ConsumerStatefulWidget {
  final String inmateId;
  const ChatThreadScreen({super.key, required this.inmateId});

  @override
  ConsumerState<ChatThreadScreen> createState() => _ChatThreadScreenState();
}

class _ChatThreadScreenState extends ConsumerState<ChatThreadScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final user = ref.read(authControllerProvider).user;
    if (user == null) return;
    await ref.read(backendProvider).ops.sendMessage(
          inmateId: widget.inmateId,
          senderId: user.id,
          senderRole: user.role == UserRole.owner ? 'owner' : 'inmate',
          text: text,
        );
    ref.invalidate(chatMessagesProvider(widget.inmateId));
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).user;
    final messages =
        ref.watch(chatMessagesProvider(widget.inmateId)).value ?? const [];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat'),
        backgroundColor: Colors.transparent,
      ),
      extendBodyBehindAppBar: true,
      body: GlassBackground(
        dark: isDark,
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: messages.isEmpty
                    ? const Center(
                        child: Text('No messages yet — say hello.'))
                    : ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          for (final m in messages)
                            _bubble(m, user?.id ?? ''),
                        ],
                      ),
              ),
              _inputBar(isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bubble(ChatMessage m, String myId) {
    final mine = m.senderId == myId;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bubbleColor = mine
        ? (isDark ? AppColors.primaryDark : AppColors.primary)
        : (isDark ? AppColors.glassDark : AppColors.glassLight);
    final textColor = mine
        ? Colors.white
        : (isDark ? AppColors.textDark : AppColors.textLight);
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(m.text, style: TextStyle(color: textColor, fontSize: 14)),
      ),
    );
  }

  Widget _inputBar(bool isDark) {
    final primary = isDark ? AppColors.primaryDark : AppColors.primary;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Row(
        children: [
          Expanded(
            child: GlassTextField(
              controller: _controller,
              label: 'Message',
              icon: Icons.chat_bubble_outline_rounded,
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _send,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(shape: BoxShape.circle, color: primary),
              child: const Icon(Icons.send_rounded,
                  color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
