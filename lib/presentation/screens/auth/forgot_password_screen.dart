import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../widgets/app_snackbar.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey   = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();

  @override
  void dispose() { _emailCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthBlocState>(
      listener: (context, state) {
        if (state is AuthPasswordResetSent) {
          AppSnackbar.success(context, 'تم إرسال رابط إعادة تعيين كلمة المرور إلى بريدك الإلكتروني');
          context.go(AppConstants.routeLogin);
        }
        if (state is AuthError) AppSnackbar.error(context, state.message);
      },
      builder: (context, state) => Scaffold(
        appBar: AppBar(
          title: const Text('إعادة تعيين كلمة المرور'),
          leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded), onPressed: () => context.pop()),
        ),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const SizedBox(height: 24),
              const Icon(Icons.lock_reset_rounded, size: 64, color: Color(0xFF0077B6)),
              const SizedBox(height: 20),
              Text('نسيت كلمة المرور؟', style: AppTextStyles.titleLarge),
              const SizedBox(height: 8),
              Text('أدخل بريدك الإلكتروني وسنرسل لك رابطاً لإعادة التعيين.', style: AppTextStyles.bodyMedium.copyWith(height: 1.5)),
              const SizedBox(height: 28),
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                textDirection: TextDirection.ltr,
                decoration: const InputDecoration(labelText: 'البريد الإلكتروني', prefixIcon: Icon(Icons.email_outlined)),
                validator: (v) => (v == null || !v.contains('@')) ? 'بريد إلكتروني غير صحيح' : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: state is AuthLoading ? null : () {
                  if (_formKey.currentState!.validate()) {
                    context.read<AuthBloc>().add(AuthForgotPasswordRequested(email: _emailCtrl.text.trim()));
                  }
                },
                child: state is AuthLoading
                    ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('إرسال رابط إعادة التعيين'),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
