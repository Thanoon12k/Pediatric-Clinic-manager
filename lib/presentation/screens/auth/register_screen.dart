import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../providers/auth/auth_provider.dart';
import '../../widgets/app_snackbar.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});
  @override ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey   = GlobalKey<FormState>();
  final _nameCtrl  = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  final _confCtrl  = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _nameCtrl.dispose(); _emailCtrl.dispose();
    _passCtrl.dispose(); _confCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_passCtrl.text != _confCtrl.text) {
      AppSnackbar.error(context, 'كلمتا المرور غير متطابقتين');
      return;
    }
    ref.read(authProvider.notifier).register(
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
      fullName: _nameCtrl.text.trim(),
      role: 'patient',
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authProvider);

    ref.listen<AuthBlocState>(authProvider, (previous, next) {
      if (next is AuthRegistrationSuccess) {
        AppSnackbar.success(context, 'تم إنشاء الحساب! تحقق من بريدك الإلكتروني');
        context.go(AppConstants.routeLogin);
      }
      if (next is AuthError) AppSnackbar.error(context, next.message);
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('إنشاء حساب جديد'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded), onPressed: () => context.pop()),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(children: [
                  const CircleAvatar(
                    backgroundColor: AppColors.primaryContainer,
                    child: Icon(Icons.family_restroom_rounded, color: AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('إنشاء حساب ولي أمر', style: AppTextStyles.titleSmall),
                      const SizedBox(height: 4),
                      Text('حساب الطبيب يتم تفعيله بواسطة إدارة العيادة لحماية ملفات المرضى.',
                        style: AppTextStyles.bodySmall),
                    ],
                  )),
                ]),
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'الاسم الكامل *', prefixIcon: Icon(Icons.person_outline)),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'الاسم الكامل مطلوب' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              textDirection: TextDirection.ltr,
              decoration: const InputDecoration(labelText: 'البريد الإلكتروني *', prefixIcon: Icon(Icons.email_outlined)),
              validator: (v) => (v == null || !v.contains('@')) ? 'بريد غير صحيح' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passCtrl,
              obscureText: _obscure,
              textDirection: TextDirection.ltr,
              decoration: InputDecoration(
                labelText: 'كلمة المرور *',
                prefixIcon: const Icon(Icons.lock_outlined),
                suffixIcon: IconButton(
                  icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              validator: (v) => (v == null || v.length < 6) ? 'كلمة المرور 6 أحرف على الأقل' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _confCtrl,
              obscureText: true,
              textDirection: TextDirection.ltr,
              decoration: const InputDecoration(labelText: 'تأكيد كلمة المرور *', prefixIcon: Icon(Icons.lock_outlined)),
              validator: (v) => (v == null || v.isEmpty) ? 'تأكيد المرور مطلوب' : null,
            ),
            const SizedBox(height: 28),
            ElevatedButton(
              onPressed: state is AuthLoading ? null : _submit,
              child: state is AuthLoading
                  ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('إنشاء الحساب'),
            ),
            const SizedBox(height: 16),
            Center(child: TextButton(
              onPressed: () => context.go(AppConstants.routeLogin),
              child: const Text('لديك حساب بالفعل؟ تسجيل الدخول'),
            )),
          ]),
        ),
      ),
    );
  }
}

