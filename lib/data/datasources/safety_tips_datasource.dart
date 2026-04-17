import 'package:supabase_flutter/supabase_flutter.dart';

abstract class SafetyTipsDataSource {
  Future<List<Map<String, dynamic>>> getSafetyTips(String locale);
}

class SafetyTipsDataSourceImpl implements SafetyTipsDataSource {
  final SupabaseClient _client;
  SafetyTipsDataSourceImpl(this._client);

  @override
  Future<List<Map<String, dynamic>>> getSafetyTips(String locale) async {
    final data = await _client
        .from('safety_tips')
        .select()
        .eq('locale', locale)
        .order('display_order');
    return List<Map<String, dynamic>>.from(data);
  }
}
