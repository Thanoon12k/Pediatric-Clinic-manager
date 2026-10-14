import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_colors.dart';

/// Admin: provision/reset doctor accounts.
/// Doctor: provision/reset secretaries assigned to their own practice.
/// Passwords are sent only to the authenticated server Edge Function;
/// no service-role key or role mutation is ever included in the APK.
class StaffAccountsScreen extends StatefulWidget {
  const StaffAccountsScreen({super.key});

  @override
  State<StaffAccountsScreen> createState() => _StaffAccountsScreenState();
}

class _StaffAccountsScreenState extends State<StaffAccountsScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  final _specialty = TextEditingController();

  final _client = Supabase.instance.client;
  bool _loading = true;
  bool _submitting = false;
  bool _passwordVisible = false;
  bool _resetPassword = false;
  String? _role;
  String? _error;

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadRole);
  }

  @override
  void dispose() {
    _name.dispose();
    _username.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    _specialty.dispose();
    super.dispose();
  }

  Future<void> _loadRole() async {
    try {
      final id = _client.auth.currentUser?.id;
      if (id == null) throw StateError('يجب تسجيل الدخول أولاً.');
      final profile = await _client.from('profiles')
          .select('role').eq('id', id).single();
      final role = profile['role'] as String?;
      if (role != 'admin' && role != 'doctor') {
        throw StateError('هذه الخدمة متاحة للمدير والطبيب فقط.');
      }
      if (mounted) setState(() => _role = role);
    } catch (_) {
      if (mounted) setState(() =>
        _error = 'لا يمكنك إدارة حسابات العاملين بهذه الصلاحية.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String get _target => _role == 'admin' ? 'طبيب' : 'سكرتير';

  Future<void> _submit() async {
    if (_submitting || !_form.currentState!.validate()) return;
    if (_password.text != _confirmPassword.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('كلمتا المرور غير متطابقتين.')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final response = await _client.functions.invoke('provision-staff', body: {
        'action': _resetPassword ? 'reset_password' : 'create',
        'username': _username.text.trim().toLowerCase(),
        'password': _password.text,
        if (!_resetPassword) 'full_name': _name.text.trim(),
        if (_role == 'admin' && !_resetPassword)
          'specialty': _specialty.text.trim(),
      });

      final result = response.data;
      if (response.status < 200 || response.status >= 300 ||
          result is! Map || result['ok'] != true) {
        throw StateError('تعذّر تنفيذ الطلب. تحقق من صلاحياتك وإعداد الخادم.');
      }

      if (!mounted) return;
      _password.clear();
      _confirmPassword.clear();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_resetPassword
            ? 'تم تغيير كلمة المرور لحساب ${_username.text.trim()}.'
            : 'تم إنشاء حساب $_target بنجاح. يمكنه تسجيل الدخول باسم المستخدم وكلمة المرور المحددة.'),
        backgroundColor: AppColors.success,
      ));
      if (!_resetPassword) {
        _username.clear();
        _name.clear();
        _specialty.clear();
      }
    } on FunctionException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(
            'فشل طلب إنشاء الحساب (${error.status}). تحقق من تفعيل Edge Function، واسم المستخدم، وصلاحيات حسابك.',
          )),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر التواصل مع الخادم. تأكد من الإنترنت وحاول مجدداً.')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_role == 'admin'
          ? 'حسابات الأطباء' : 'حسابات السكرتارية')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(_error!, textAlign: TextAlign.center),
                ))
              : Center(child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Form(
                    key: _form,
                    child: ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(_role == 'admin'
                                ? Icons.medical_services_outlined
                                : Icons.support_agent_outlined,
                                color: AppColors.primary, size: 32),
                              const SizedBox(height: 8),
                              Text('إدارة حساب $_target',
                                style: Theme.of(context).textTheme.titleLarge),
                              const SizedBox(height: 6),
                              Text(_role == 'admin'
                                ? 'بصفتك مديراً، تستطيع إنشاء حساب طبيب جديد أو تغيير كلمة مروره.'
                                : 'كل سكرتير تضيفه يرتبط بطابور عيادتك أنت فقط. لا يحصل على صلاحيات قراءة السجل الطبي.'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        SegmentedButton<bool>(
                          segments: const [
                            ButtonSegment(value: false, label: Text('إنشاء حساب'),
                              icon: Icon(Icons.person_add_alt_1_rounded)),
                            ButtonSegment(value: true, label: Text('تغيير كلمة المرور'),
                              icon: Icon(Icons.lock_reset_rounded)),
                          ],
                          selected: {_resetPassword},
                          onSelectionChanged: (value) {
                            setState(() => _resetPassword = value.first);
                          },
                        ),
                        const SizedBox(height: 20),
                        if (!_resetPassword) ...[
                          TextFormField(
                            controller: _name,
                            decoration: InputDecoration(
                              labelText: 'الاسم الكامل للـ$_target',
                              prefixIcon: const Icon(Icons.badge_outlined),
                            ),
                            validator: (v) => (v ?? '').trim().length < 2
                                ? 'أدخل الاسم الكامل' : null,
                          ),
                          const SizedBox(height: 14),
                          if (_role == 'admin') ...[
                            TextFormField(
                              controller: _specialty,
                              decoration: const InputDecoration(
                                labelText: 'التخصص (اختياري)',
                                prefixIcon: Icon(Icons.local_hospital_outlined),
                              ),
                            ),
                            const SizedBox(height: 14),
                          ],
                        ],
                        TextFormField(
                          controller: _username,
                          textDirection: TextDirection.ltr,
                          autocorrect: false,
                          enableSuggestions: false,
                          decoration: const InputDecoration(
                            labelText: 'اسم المستخدم بالإنجليزية',
                            hintText: 'e.g. clinic_desk',
                            prefixIcon: Icon(Icons.alternate_email_rounded),
                            helperText: 'من 4 إلى 24 رمزاً: حروف إنجليزية صغيرة، أرقام أو _',
                            helperMaxLines: 2,
                          ),
                          validator: (v) =>
                            RegExp(r'^[a-z][a-z0-9_]{3,23}$').hasMatch(
                                (v ?? '').trim().toLowerCase())
                                ? null : 'اسم المستخدم غير صالح',
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _password,
                          obscureText: !_passwordVisible,
                          autocorrect: false,
                          enableSuggestions: false,
                          decoration: InputDecoration(
                            labelText: _resetPassword
                              ? 'كلمة المرور الجديدة' : 'كلمة المرور',
                            helperText: '12 رمزاً على الأقل. لا تشارك كلمة المرور داخل المحادثات.',
                            helperMaxLines: 2,
                            prefixIcon: const Icon(Icons.lock_outline_rounded),
                            suffixIcon: IconButton(
                              icon: Icon(_passwordVisible
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined),
                              onPressed: () => setState(
                                () => _passwordVisible = !_passwordVisible),
                            ),
                          ),
                          validator: (v) => (v ?? '').length < 12
                              ? 'كلمة المرور يجب أن تكون 12 رمزاً على الأقل' : null,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _confirmPassword,
                          obscureText: !_passwordVisible,
                          autocorrect: false,
                          enableSuggestions: false,
                          decoration: const InputDecoration(
                            labelText: 'تأكيد كلمة المرور',
                            prefixIcon: Icon(Icons.verified_user_outlined),
                          ),
                          validator: (v) => (v ?? '').isEmpty
                              ? 'أعد كتابة كلمة المرور' : null,
                        ),
                        const SizedBox(height: 22),
                        FilledButton.icon(
                          onPressed: _submitting ? null : _submit,
                          icon: _submitting
                              ? const SizedBox(width: 18, height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2))
                              : Icon(_resetPassword
                                  ? Icons.lock_reset_rounded
                                  : Icons.person_add_alt_1_rounded),
                          label: Text(_resetPassword
                              ? 'تعيين كلمة مرور جديدة'
                              : 'إنشاء حساب $_target'),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'تُنشأ الحسابات من خادم Supabase الآمن؛ لا تُحفظ كلمة المرور في ملفات التطبيق أو جداول البيانات. الحسابات بأسماء المستخدمين تحتاج المدير أو الطبيب لإعادة تعيين كلمات المرور.',
                          style: TextStyle(fontSize: 12,
                            color: AppColors.textSecondary, height: 1.6),
                        ),
                      ],
                    ),
                  ),
                )),
    );
  }
}
