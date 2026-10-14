/// Tracks an in-progress password recovery so role navigation cannot override
/// the password update form during a Supabase deep link callback.
class AuthRecoveryState {
  AuthRecoveryState._();
  static bool active = false;
}
