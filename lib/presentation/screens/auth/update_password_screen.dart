import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/config/auth_recovery_state.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../providers/auth/auth_provider.dart';
import '../../widgets/app_snackbar.dart';

class UpdatePasswordScreen extends ConsumerStatefulWidget {
  const UpdatePasswordScreen({super.key});
  @override ConsumerState<UpdatePasswordScreen> createState() => _UpdatePasswordScreenState();
}

class _UpdatePasswordScreenState extends ConsumerState<UpdatePasswordScreen> {
  final _formKey  = GlobalKey<FormState>();
  final _passCtrl = TextEditingController();
  final _confCtrl = TextEditingController();
  bool _obscurePass = true;
  bool _obscureConf = true;

  @override
  void dispose() {
    _passCtrl.dispose();
    _confCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_passCtrl.text != _confCtrl.text) {
      AppSnackbar.error(context, 'كلمتا المرور غير متطابقتين');
      return;
    }
    ref.read(authProvider.notifier).updatePassword(_passCtrl.text);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authProvider);

    ref.listen<AuthBlocState>(authProvider, (previous, next) {
      if (next is AuthPasswordResetSent) {
        AuthRecoveryState.active = false;
        AppSnackbar.success(context, 'تم تغيير كلمة المرور بنجاح! يرجى تسجيل الدخول.');
        context.go(AppConstants.routeLogin);
      }
      if (next is AuthError) AppSnackbar.error(context, next.message);
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('تعيين كلمة مرور جديدة'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.go(AppConstants.routeLogin),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Form(
              key: _formKey,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.lock_reset_rounded, size: 52, color: AppColors.primary),
                  ),
                ),
                const SizedBox(height: 28),
                Text('كلمة مرور جديدة', style: AppTextStyles.headlineSmall),
                const SizedBox(height: 8),
                Text(
                  'أدخل كلمة المرور الجديدة لحسابك. يجب أن تكون 6 أحرف على الأقل.',
                  style: AppTextStyles.bodyMedium.copyWith(height: 1.5),
                ),
                const SizedBox(height: 32),

                // New password
                TextFormField(
                  controller: _passCtrl,
                  obscureText: _obscurePass,
                  textDirection: TextDirection.ltr,
                  decoration: InputDecoration(
                    labelText: 'كلمة المرور الجديدة *',
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePass ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                      onPressed: () => setState(() => _obscurePass = !_obscurePass),
                    ),
                  ),
                  validator: (v) => (v == null || v.length < 6)
                      ? 'كلمة المرور 6 أحرف على الأقل'
                      : null,
                ),
                const SizedBox(height: 16),

                // Confirm password
                TextFormField(
                  controller: _confCtrl,
                  obscureText: _obscureConf,
                  textDirection: TextDirection.ltr,
                  decoration: InputDecoration(
                    labelText: 'تأكيد كلمة المرور *',
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureConf ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                      onPressed: () => setState(() => _obscureConf = !_obscureConf),
                    ),
                  ),
                  validator: (v) => (v == null || v.isEmpty)
                      ? 'تأكيد المرور مطلوب'
                      : null,
                ),
                const SizedBox(height: 28),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: state is AuthLoading ? null : _submit,
                    child: state is AuthLoading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('تعيين كلمة المرور'),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
