import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/user_model.dart';

abstract class AuthDataSource {
  Future<UserModel?> getCurrentUser();
  Future<UserModel> signIn({required String email, required String password});
  Future<UserModel> signUp({
    required String email, required String password,
    required String fullName, String? phone, UserRole role,
  });
  Future<void> signOut();
  Future<void> sendPasswordResetEmail(String email);
  Stream<UserModel?> get authStateChanges;
}

class AuthDataSourceImpl implements AuthDataSource {
  final SupabaseClient _client;
  AuthDataSourceImpl(this._client);

  @override
  Future<UserModel?> getCurrentUser() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    try {
      final data = await _client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();
      return UserModel.fromJson({...data, 'email': user.email ?? ''});
    } catch (_) {
      return null;
    }
  }

  @override
  Future<UserModel> signIn({required String email, required String password}) async {
    final response = await _client.auth.signInWithPassword(
      email: email, password: password,
    );
    if (response.user == null) throw Exception('فشل تسجيل الدخول');
    final data = await _client
        .from('profiles')
        .select()
        .eq('id', response.user!.id)
        .single();
    return UserModel.fromJson({...data, 'email': email});
  }

  @override
  Future<UserModel> signUp({
    required String email, required String password,
    required String fullName, String? phone, UserRole role = UserRole.patient,
  }) async {
    final response = await _client.auth.signUp(
      email: email, password: password,
      data: {'full_name': fullName, 'role': role.name},
    );
    if (response.user == null) throw Exception('فشل إنشاء الحساب');
    // Profile is created via trigger; wait briefly then fetch
    await Future.delayed(const Duration(milliseconds: 500));
    final data = await _client
        .from('profiles')
        .select()
        .eq('id', response.user!.id)
        .single();
    return UserModel.fromJson({...data, 'email': email});
  }

  @override
  Future<void> signOut() async => await _client.auth.signOut();

  @override
  Future<void> sendPasswordResetEmail(String email) async =>
      await _client.auth.resetPasswordForEmail(email);

  @override
  Stream<UserModel?> get authStateChanges {
    return _client.auth.onAuthStateChange.asyncMap((event) async {
      if (event.session == null) return null;
      return getCurrentUser();
    });
  }
}
