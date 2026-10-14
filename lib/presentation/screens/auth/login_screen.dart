import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/user_model.dart';
import '../../providers/auth/auth_provider.dart';
import '../../widgets/app_snackbar.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() { _emailCtrl.dispose(); _passCtrl.dispose(); super.dispose(); }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    ref.read(authProvider.notifier).login(
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authProvider);

    ref.listen<AuthBlocState>(authProvider, (previous, next) {
      if (next is AuthAuthenticated) {
        switch (next.user.role) {
          case UserRole.admin:   context.go(AppConstants.routeAdminDashboard); break;
          case UserRole.doctor:  context.go(AppConstants.routeDoctorDashboard); break;
          case UserRole.secretary: context.go(AppConstants.routeClinicQueue); break;
          case UserRole.patient: context.go(AppConstants.routePatientDashboard); break;
        }
      } else if (next is AuthError) {
        AppSnackbar.error(context, next.message);
      }
    });

    return Scaffold(
      body: Stack(children: [
        Container(height: 280, decoration: const BoxDecoration(gradient: AppColors.primaryGradient)),
        SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(children: [
              const SizedBox(height: 24),
              const Icon(Icons.local_hospital_rounded, size: 60, color: Colors.white)
                  .animate().scale(duration: 500.ms, curve: Curves.elasticOut),
              const SizedBox(height: 12),
              Text(AppConstants.appName, style: AppTextStyles.headlineSmall.copyWith(color: Colors.white))
                  .animate(delay: 200.ms).fadeIn(),
              const SizedBox(height: 48),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, 8))],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('تسجيل الدخول', style: AppTextStyles.titleLarge),
                    const SizedBox(height: 4),
                    Text('أدخل بياناتك للمتابعة', style: AppTextStyles.bodySmall),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      textDirection: TextDirection.ltr,
                      decoration: const InputDecoration(labelText: 'البريد الإلكتروني أو اسم المستخدم', prefixIcon: Icon(Icons.email_outlined)),
                      validator: (v) {
                        final value = (v ?? '').trim().toLowerCase();
                        final isEmail = value.contains('@') && value.indexOf('@') > 0;
                        final isUsername = RegExp(r'^[a-z][a-z0-9_]{3,23}$').hasMatch(value);
                        return isEmail || isUsername ? null
                            : 'أدخل البريد الإلكتروني أو اسم مستخدم صحيح';
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passCtrl,
                      obscureText: _obscure,
                      textDirection: TextDirection.ltr,
                      decoration: InputDecoration(
                        labelText: 'كلمة المرور',
                        prefixIcon: const Icon(Icons.lock_outlined),
                        suffixIcon: IconButton(
                          icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                      validator: (v) => (v == null || v.length < 6) ? 'كلمة المرور يجب أن تكون 6 أحرف على الأقل' : null,
                      onFieldSubmitted: (_) => _submit(),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: TextButton(
                        onPressed: () => context.go(AppConstants.routeForgotPassword),
                        child: const Text('نسيت كلمة المرور؟'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: state is AuthLoading ? null : _submit,
                      child: state is AuthLoading
                          ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('دخول'),
                    ),
                  ]),
                ),
              ).animate(delay: 300.ms).fadeIn().slideY(begin: 0.3),
              const SizedBox(height: 24),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('ليس لديك حساب؟', style: AppTextStyles.bodyMedium),
                TextButton(
                  onPressed: () => context.go(AppConstants.routeRegister),
                  child: const Text('إنشاء حساب'),
                ),
              ]),
            ]),
          ),
        ),
      ]),
    );
  }
}
