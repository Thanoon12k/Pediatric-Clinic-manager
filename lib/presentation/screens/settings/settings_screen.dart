import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../widgets/app_snackbar.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late String _locale;
  late bool _isDark;

  @override
  void initState() {
    super.initState();
    final box = Hive.box(AppConstants.boxSettings);
    _locale = box.get(AppConstants.keyLocale, defaultValue: 'ar') as String;
    _isDark = box.get(AppConstants.keyThemeMode, defaultValue: 'light') == 'dark';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionHeader(label: 'التطبيق'),
          _SettingCard(children: [
            _SwitchTile(
              icon: Icons.dark_mode_rounded,
              label: 'الوضع الداكن',
              value: _isDark,
              onChanged: (v) {
                setState(() => _isDark = v);
                Hive.box(AppConstants.boxSettings).put(AppConstants.keyThemeMode, v ? 'dark' : 'light');
                AppSnackbar.info(context, 'يُرجى إعادة تشغيل التطبيق لتطبيق السمة');
              },
            ),
            const Divider(height: 1),
            _SelectTile(
              icon: Icons.language_rounded,
              label: 'لغة التطبيق',
              value: _locale == 'ar' ? 'العربية' : 'English',
              onTap: () => _toggleLocale(),
            ),
          ]),

          const SizedBox(height: 16),
          _SectionHeader(label: 'الحساب'),
          _SettingCard(children: [
            _NavTile(icon: Icons.person_outline_rounded, label: 'الملف الشخصي', onTap: () => context.go(AppConstants.routeDoctorProfile)),
            const Divider(height: 1),
            _NavTile(icon: Icons.notifications_outlined, label: 'الإشعارات', onTap: () => AppSnackbar.info(context, 'الإشعارات داخل التطبيق فقط')),
            const Divider(height: 1),
            _NavTile(icon: Icons.lock_outline_rounded, label: 'تغيير كلمة المرور', onTap: () => context.go(AppConstants.routeForgotPassword)),
          ]),

          const SizedBox(height: 16),
          _SectionHeader(label: 'الدعم والمعلومات'),
          _SettingCard(children: [
            _NavTile(icon: Icons.security_rounded, label: 'نصائح سلامة الأطفال', onTap: () => context.go(AppConstants.routeSafetyTips)),
            const Divider(height: 1),
            _NavTile(icon: Icons.error_outline_rounded, label: 'العمليات المعلقة', onTap: () => context.go(AppConstants.routeFailedOps)),
            const Divider(height: 1),
            _InfoTile(icon: Icons.info_outline_rounded, label: 'إصدار التطبيق', value: AppConstants.appVersion),
          ]),

          const SizedBox(height: 32),
          BlocConsumer<AuthBloc, AuthBlocState>(
            listener: (context, state) {
              if (state is AuthUnauthenticated) context.go(AppConstants.routeWelcome);
            },
            builder: (context, state) => OutlinedButton.icon(
              onPressed: () => _confirmLogout(context),
              icon: const Icon(Icons.logout_rounded, color: AppColors.error),
              label: const Text('تسجيل الخروج', style: TextStyle(color: AppColors.error)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.error),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _toggleLocale() {
    final newLocale = _locale == 'ar' ? 'en' : 'ar';
    setState(() => _locale = newLocale);
    Hive.box(AppConstants.boxSettings).put(AppConstants.keyLocale, newLocale);
    AppSnackbar.info(context, 'يُرجى إعادة تشغيل التطبيق لتطبيق اللغة');
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('تسجيل الخروج'),
        content: const Text('هل أنت متأكد من تسجيل الخروج؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthBloc>().add(AuthLogoutRequested());
            },
            child: const Text('خروج'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Text(label, style: AppTextStyles.labelLarge.copyWith(color: AppColors.textSecondary)),
  );
}

class _SettingCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingCard({required this.children});
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.divider)),
    child: Column(children: children),
  );
}

class _SwitchTile extends StatelessWidget {
  final IconData icon; final String label; final bool value; final ValueChanged<bool> onChanged;
  const _SwitchTile({required this.icon, required this.label, required this.value, required this.onChanged});
  @override
  Widget build(BuildContext context) => SwitchListTile(
    secondary: Icon(icon, color: AppColors.primary),
    title: Text(label, style: AppTextStyles.bodyMedium),
    value: value,
    onChanged: onChanged,
    activeThumbColor: AppColors.primary,
  );
}

class _NavTile extends StatelessWidget {
  final IconData icon; final String label; final VoidCallback onTap;
  const _NavTile({required this.icon, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon, color: AppColors.primary),
    title: Text(label, style: AppTextStyles.bodyMedium),
    trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textHint),
    onTap: onTap,
  );
}

class _SelectTile extends StatelessWidget {
  final IconData icon; final String label; final String value; final VoidCallback onTap;
  const _SelectTile({required this.icon, required this.label, required this.value, required this.onTap});
  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon, color: AppColors.primary),
    title: Text(label, style: AppTextStyles.bodyMedium),
    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
      Text(value, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
      const SizedBox(width: 4),
      const Icon(Icons.chevron_right_rounded, color: AppColors.textHint),
    ]),
    onTap: onTap,
  );
}

class _InfoTile extends StatelessWidget {
  final IconData icon; final String label; final String value;
  const _InfoTile({required this.icon, required this.label, required this.value});
  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon, color: AppColors.primary),
    title: Text(label, style: AppTextStyles.bodyMedium),
    trailing: Text(value, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
  );
}
