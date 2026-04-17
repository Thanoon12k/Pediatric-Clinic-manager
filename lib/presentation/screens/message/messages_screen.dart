import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/message_model.dart';
import '../../blocs/message/message_bloc.dart';
import '../../widgets/app_snackbar.dart';

// ─── Messages List Screen ────────────────────────────────────────────────────
class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
    context.read<MessageBloc>().add(LoadConversations(userId));

    return Scaffold(
      appBar: AppBar(title: const Text('رسائل المرضى')),
      body: BlocBuilder<MessageBloc, MessageState>(
        builder: (context, state) {
          if (state is MessageLoading) return const Center(child: CircularProgressIndicator());
          if (state is ConversationsLoaded && state.conversations.isEmpty) {
            return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.chat_bubble_outline_rounded, size: 80, color: AppColors.textHint),
              const SizedBox(height: 16),
              Text('لا توجد محادثات حتى الآن', style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textHint)),
            ]));
          }
          if (state is ConversationsLoaded) {
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.conversations.length,
              itemBuilder: (context, i) {
                final conv = state.conversations[i];
                final recipientName = conv.doctorName;
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primaryContainer,
                      child: Text(recipientName.isNotEmpty ? recipientName[0] : 'ط', style: AppTextStyles.titleMedium.copyWith(color: AppColors.primary)),
                    ),
                    title: Text(recipientName, style: AppTextStyles.titleSmall),
                    subtitle: Text(conv.lastMessage ?? 'لا توجد رسائل', style: AppTextStyles.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                    trailing: conv.unreadCount > 0
                        ? CircleAvatar(radius: 12, backgroundColor: AppColors.primary, child: Text('${conv.unreadCount}', style: const TextStyle(color: Colors.white, fontSize: 10)))
                        : conv.lastMessageAt != null
                            ? Text(timeago.format(conv.lastMessageAt!, locale: 'ar'), style: AppTextStyles.labelSmall)
                            : null,
                    onTap: () => context.go('/chat/${conv.id}', extra: {'recipientName': recipientName}),
                  ),
                ).animate(delay: Duration(milliseconds: i * 60)).fadeIn().slideX(begin: 0.2);
              },
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

// ─── Chat Screen ─────────────────────────────────────────────────────────────
class ChatScreen extends StatefulWidget {
  final String conversationId;
  final String recipientName;
  const ChatScreen({super.key, required this.conversationId, required this.recipientName});
  @override State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  String _myId = '';

  @override
  void initState() {
    super.initState();
    _myId = Supabase.instance.client.auth.currentUser?.id ?? '';
    context.read<MessageBloc>().add(LoadMessages(widget.conversationId));
    timeago.setLocaleMessages('ar', timeago.ArMessages());
  }

  @override
  void dispose() { _msgCtrl.dispose(); _scrollCtrl.dispose(); super.dispose(); }

  void _send() {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    final myName = Supabase.instance.client.auth.currentUser?.email ?? '';
    context.read<MessageBloc>().add(SendMessage(MessageModel(
      id: const Uuid().v4(),
      conversationId: widget.conversationId,
      senderId: _myId,
      senderName: myName,
      content: text,
      createdAt: DateTime.now(),
    )));
    _msgCtrl.clear();
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollCtrl.hasClients) _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          CircleAvatar(radius: 18, backgroundColor: Colors.white.withValues(alpha: 0.2),
            child: Text(widget.recipientName.isNotEmpty ? widget.recipientName[0] : 'ط', style: const TextStyle(color: Colors.white))),
          const SizedBox(width: 10),
          Expanded(child: Text(widget.recipientName, style: AppTextStyles.titleMedium.copyWith(color: Colors.white))),
        ]),
      ),
      body: Column(
        children: [
          Expanded(
            child: BlocConsumer<MessageBloc, MessageState>(
              listener: (context, state) {
                if (state is MessageError) AppSnackbar.error(context, state.message);
              },
              builder: (context, state) {
                if (state is MessageLoading) return const Center(child: CircularProgressIndicator());
                if (state is MessagesLoaded) {
                  if (state.messages.isEmpty) {
                    return const Center(child: Text('ابدأ المحادثة الآن...', style: TextStyle(color: AppColors.textHint)));
                  }
                  return ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.all(16),
                    itemCount: state.messages.length,
                    itemBuilder: (context, i) {
                      final msg = state.messages[i];
                      final isMe = msg.senderId == _myId;
                      return _MessageBubble(message: msg, isMe: isMe)
                          .animate(delay: Duration(milliseconds: i * 30)).fadeIn();
                    },
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),

          // Input bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, -2))],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  IconButton(icon: const Icon(Icons.attach_file_rounded, color: AppColors.textSecondary), onPressed: () {}),
                  IconButton(icon: const Icon(Icons.mic_rounded, color: AppColors.textSecondary), onPressed: () {}),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(color: AppColors.backgroundLight, borderRadius: BorderRadius.circular(24)),
                      child: TextField(
                        controller: _msgCtrl,
                        maxLines: null,
                        decoration: const InputDecoration.collapsed(hintText: 'اكتب رسالتك...'),
                        onSubmitted: (_) => _send(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  BlocBuilder<MessageBloc, MessageState>(
                    builder: (context, state) => CircleAvatar(
                      backgroundColor: AppColors.primary,
                      child: IconButton(
                        icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                        onPressed: _send,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  const _MessageBubble({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
        decoration: BoxDecoration(
          color: isMe ? AppColors.primary : Colors.white,
          borderRadius: BorderRadiusDirectional.only(
            topStart: const Radius.circular(16),
            topEnd: const Radius.circular(16),
            bottomEnd: isMe ? Radius.zero : const Radius.circular(16),
            bottomStart: isMe ? const Radius.circular(16) : Radius.zero,
          ),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 4)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (message.content != null)
              Text(message.content!, style: TextStyle(color: isMe ? Colors.white : AppColors.textPrimary, fontSize: 15)),
            const SizedBox(height: 4),
            Text(
              '${message.createdAt.hour.toString().padLeft(2, '0')}:${message.createdAt.minute.toString().padLeft(2, '0')}',
              style: TextStyle(color: isMe ? Colors.white60 : AppColors.textHint, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
