import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/message_model.dart';
import '../../../domain/repositories/message_repository.dart';
import '../../../core/di/providers.dart';

// ─── States ──────────────────────────────────────────────────────────────────
abstract class MessageState extends Equatable {
  @override List<Object?> get props => [];
}

class MessageInitial extends MessageState {}
class MessageLoading extends MessageState {}
class ConversationsLoaded extends MessageState {
  final List<ConversationModel> conversations;
  ConversationsLoaded(this.conversations);
  @override List<Object?> get props => [conversations];
}
class MessagesLoaded extends MessageState {
  final List<MessageModel> messages;
  MessagesLoaded(this.messages);
  @override List<Object?> get props => [messages];
}
class MessageSent extends MessageState {
  final MessageModel message;
  MessageSent(this.message);
  @override List<Object?> get props => [message];
}
class MessageError extends MessageState {
  final String message;
  MessageError(this.message);
  @override List<Object?> get props => [message];
}

// ─── Notifier ────────────────────────────────────────────────────────────────
class MessageNotifier extends StateNotifier<MessageState> {
  final MessageRepository _repo;

  MessageNotifier(this._repo) : super(MessageInitial());

  Future<void> loadConversations(String userId) async {
    state = MessageLoading();
    try {
      final conversations = await _repo.getConversations(userId);
      state = ConversationsLoaded(conversations);
    } catch (e) {
      state = MessageError(e.toString());
    }
  }

  Future<void> loadMessages(String conversationId) async {
    state = MessageLoading();
    try {
      final msgs = await _repo.getMessages(conversationId);
      state = MessagesLoaded(msgs);
    } catch (e) {
      state = MessageError(e.toString());
    }
  }

  Future<void> sendMessage(MessageModel message) async {
    try {
      await _repo.sendMessage(message);
      state = MessageSent(message);
      // Reload messages
      final msgs = await _repo.getMessages(message.conversationId);
      state = MessagesLoaded(msgs);
    } catch (e) {
      state = MessageError(e.toString());
    }
  }

  Future<void> markAsRead(String conversationId) async {
    try {
      await _repo.markAsRead(conversationId);
    } catch (_) {}
  }
}

// ─── Provider ────────────────────────────────────────────────────────────────
final messageProvider = StateNotifierProvider<MessageNotifier, MessageState>((ref) {
  return MessageNotifier(ref.watch(messageRepositoryProvider));
});
