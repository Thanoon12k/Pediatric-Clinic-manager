import '../../data/models/message_model.dart';

abstract class MessageRepository {
  Future<List<ConversationModel>> getConversations(String userId);
  Future<ConversationModel> getOrCreateConversation({required String patientId, required String doctorId, required String patientName, required String doctorName});
  Future<List<MessageModel>> getMessages(String conversationId);
  Future<MessageModel> sendMessage(MessageModel message);
  Future<void> markAsRead(String conversationId);
  Stream<List<MessageModel>> messageStream(String conversationId);
}
