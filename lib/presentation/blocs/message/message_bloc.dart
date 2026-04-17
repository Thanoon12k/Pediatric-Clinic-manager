import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/message_model.dart';
import '../../../domain/repositories/message_repository.dart';

// ─── Events ──────────────────────────────────────────────────────────────────
abstract class MessageEvent extends Equatable {
  @override List<Object?> get props => [];
}
class LoadConversations extends MessageEvent { final String userId; LoadConversations(this.userId); @override List<Object?> get props => [userId]; }
class LoadMessages      extends MessageEvent { final String conversationId; LoadMessages(this.conversationId); @override List<Object?> get props => [conversationId]; }
class SendMessage       extends MessageEvent { final MessageModel message; SendMessage(this.message); @override List<Object?> get props => [message]; }
class MarkAsRead        extends MessageEvent { final String conversationId; MarkAsRead(this.conversationId); @override List<Object?> get props => [conversationId]; }
class StartConversationStream extends MessageEvent { final String conversationId; StartConversationStream(this.conversationId); @override List<Object?> get props => [conversationId]; }

// ─── States ───────────────────────────────────────────────────────────────────
abstract class MessageState extends Equatable {
  @override List<Object?> get props => [];
}
class MessageInitial        extends MessageState {}
class MessageLoading        extends MessageState {}
class ConversationsLoaded   extends MessageState { final List<ConversationModel> conversations; ConversationsLoaded(this.conversations); @override List<Object?> get props => [conversations]; }
class MessagesLoaded        extends MessageState { final List<MessageModel> messages; MessagesLoaded(this.messages); @override List<Object?> get props => [messages]; }
class MessageSent           extends MessageState { final MessageModel message; MessageSent(this.message); @override List<Object?> get props => [message]; }
class MessageError          extends MessageState { final String message; MessageError(this.message); @override List<Object?> get props => [message]; }

// ─── BLoC ─────────────────────────────────────────────────────────────────────
class MessageBloc extends Bloc<MessageEvent, MessageState> {
  final MessageRepository _repo;
  MessageBloc(this._repo) : super(MessageInitial()) {
    on<LoadConversations>((event, emit) async {
      emit(MessageLoading());
      try { emit(ConversationsLoaded(await _repo.getConversations(event.userId))); }
      catch (e) { emit(MessageError(e.toString())); }
    });

    on<LoadMessages>((event, emit) async {
      emit(MessageLoading());
      try {
        final msgs = await _repo.getMessages(event.conversationId);
        emit(MessagesLoaded(msgs));
      } catch (e) { emit(MessageError(e.toString())); }
    });

    on<SendMessage>((event, emit) async {
      try {
        await _repo.sendMessage(event.message);
        emit(MessageSent(event.message));
        // Reload messages
        final msgs = await _repo.getMessages(event.message.conversationId);
        emit(MessagesLoaded(msgs));
      } catch (e) { emit(MessageError(e.toString())); }
    });

    on<MarkAsRead>((event, emit) async {
      try { await _repo.markAsRead(event.conversationId); }
      catch (_) {}
    });
  }
}
