import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../widgets/app_snackbar.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey   = GlobalKey<FormState>();
  final _nameCtrl  = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  final _confCtrl  = TextEditingController();
  bool _obscure = true;
  String _role = 'patient';

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
    context.read<AuthBloc>().add(AuthRegisterRequested(
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
      fullName: _nameCtrl.text.trim(),
      role: _role,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthBlocState>(
      listener: (context, state) {
        if (state is AuthRegistrationSuccess) {
          AppSnackbar.success(context, 'تم إنشاء الحساب! تحقق من بريدك الإلكتروني');
          context.go(AppConstants.routeLogin);
        }
        if (state is AuthError) AppSnackbar.error(context, state.message);
      },
      builder: (context, state) => Scaffold(
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
              Text('نوع الحساب', style: AppTextStyles.labelLarge),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: _RoleBtn(label: 'مريض / ولي أمر', icon: Icons.family_restroom_rounded,
                    selected: _role == 'patient', onTap: () => setState(() => _role = 'patient'))),
                const SizedBox(width: 12),
                Expanded(child: _RoleBtn(label: 'طبيب', icon: Icons.medical_services_rounded,
                    selected: _role == 'doctor', onTap: () => setState(() => _role = 'doctor'))),
              ]).animate().fadeIn(),
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
      ),
    );
  }
}

class _RoleBtn extends StatelessWidget {
  final String label; final IconData icon; final bool selected; final VoidCallback onTap;
  const _RoleBtn({required this.label, required this.icon, required this.selected, required this.onTap});
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: selected ? AppColors.primaryContainer : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: selected ? AppColors.primary : AppColors.border, width: selected ? 2 : 1),
      ),
      child: Column(children: [
        Icon(icon, color: selected ? AppColors.primary : AppColors.textSecondary, size: 28),
        const SizedBox(height: 8),
        Text(label, style: AppTextStyles.labelLarge.copyWith(color: selected ? AppColors.primary : AppColors.textSecondary), textAlign: TextAlign.center),
      ]),
    ),
  );
}
