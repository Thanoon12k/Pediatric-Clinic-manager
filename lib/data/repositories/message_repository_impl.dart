import '../../data/datasources/message_datasource.dart';
import '../../data/models/message_model.dart';
import '../../domain/repositories/message_repository.dart';

class MessageRepositoryImpl implements MessageRepository {
  final MessageDataSource _ds;
  MessageRepositoryImpl(this._ds);

  @override Future<List<ConversationModel>> getConversations(String userId) => _ds.getConversations(userId);
  @override Future<ConversationModel> getOrCreateConversation({
    required String patientId, required String doctorId,
    required String patientName, required String doctorName,
  }) => _ds.getOrCreateConversation(patientId: patientId, doctorId: doctorId, patientName: patientName, doctorName: doctorName);
  @override Future<List<MessageModel>> getMessages(String conversationId) => _ds.getMessages(conversationId);
  @override Future<MessageModel> sendMessage(MessageModel message) => _ds.sendMessage(message);
  @override Future<void> markAsRead(String conversationId) => _ds.markAsRead(conversationId, '');
  @override Stream<List<MessageModel>> messageStream(String conversationId) => _ds.listenMessages(conversationId);
}
