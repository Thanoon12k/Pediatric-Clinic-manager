import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/message_model.dart';
import '../../core/constants/app_constants.dart';

abstract class MessageDataSource {
  Future<List<ConversationModel>> getConversations(String userId);
  Future<ConversationModel> getOrCreateConversation({
    required String patientId, required String doctorId,
    required String patientName, required String doctorName,
  });
  Future<List<MessageModel>> getMessages(String conversationId);
  Future<MessageModel> sendMessage(MessageModel message);
  Stream<List<MessageModel>> listenMessages(String conversationId);
  Future<void> markAsRead(String conversationId, String userId);
}

class MessageDataSourceImpl implements MessageDataSource {
  final SupabaseClient _client;
  MessageDataSourceImpl(this._client);

  @override
  Future<List<ConversationModel>> getConversations(String userId) async {
    final data = await _client
        .from('conversations')
        .select()
        .or('patient_id.eq.$userId,doctor_id.eq.$userId')
        .order('last_message_at', ascending: false);
    return data.map((e) => ConversationModel.fromJson(e)).toList();
  }

  @override
  Future<ConversationModel> getOrCreateConversation({
    required String patientId, required String doctorId,
    required String patientName, required String doctorName,
  }) async {
    // Check if exists
    final existing = await _client
        .from('conversations')
        .select()
        .eq('patient_id', patientId)
        .eq('doctor_id', doctorId)
        .maybeSingle();
    if (existing != null) return ConversationModel.fromJson(existing);

    // Create new
    final data = await _client.from('conversations').insert({
      'patient_id': patientId,
      'doctor_id': doctorId,
      'patient_name': patientName,
      'doctor_name': doctorName,
    }).select().single();
    return ConversationModel.fromJson(data);
  }

  @override
  Future<List<MessageModel>> getMessages(String conversationId) async {
    final data = await _client
        .from(AppConstants.tableMessages)
        .select()
        .eq('conversation_id', conversationId)
        .order('created_at');
    return data.map((e) => MessageModel.fromJson(e)).toList();
  }

  @override
  Future<MessageModel> sendMessage(MessageModel message) async {
    final json = message.toJson()..remove('id');
    final data = await _client
        .from(AppConstants.tableMessages)
        .insert(json).select().single();
    // Update conversation last message
    await _client.from('conversations').update({
      'last_message': message.content ?? '[media]',
      'last_message_at': DateTime.now().toIso8601String(),
    }).eq('id', message.conversationId);
    return MessageModel.fromJson(data);
  }

  @override
  Stream<List<MessageModel>> listenMessages(String conversationId) {
    return _client
        .from(AppConstants.tableMessages)
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .order('created_at')
        .map((data) => data.map((e) => MessageModel.fromJson(e)).toList());
  }

  @override
  Future<void> markAsRead(String conversationId, String userId) async {
    await _client
        .from(AppConstants.tableMessages)
        .update({'is_read': true})
        .eq('conversation_id', conversationId)
        .neq('sender_id', userId)
        .eq('is_read', false);
  }
}
