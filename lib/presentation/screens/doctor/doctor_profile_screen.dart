import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../providers/doctor/doctor_provider.dart';
import '../../widgets/app_snackbar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../data/models/doctor_model.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';

class DoctorProfileScreen extends ConsumerStatefulWidget {
  const DoctorProfileScreen({super.key});
  @override ConsumerState<DoctorProfileScreen> createState() => _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends ConsumerState<DoctorProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _specialtyCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _licenseCtrl = TextEditingController();
  List<int> _availableDays = [1, 2, 3, 4, 6];
  DoctorModel? _existing;
  String? _avatarUrl;
  bool _uploadingAvatar = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId != null) ref.read(doctorProvider.notifier).loadDoctorByUserId(userId);
    });
  }

  void _populate(DoctorModel doctor) {
    _existing = doctor;
    _avatarUrl = doctor.avatarUrl;
    _nameCtrl.text = doctor.fullName;
    _specialtyCtrl.text = doctor.specialty ?? '';
    _phoneCtrl.text = doctor.phone ?? '';
    _licenseCtrl.text = doctor.licenseNumber ?? '';
    setState(() => _availableDays = List.from(doctor.availableDays));
  }

  Future<void> _chooseAvatar() async {
    if (_uploadingAvatar) return;
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (sheetContext) => SafeArea(child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: const Text('التقاط صورة بالكاميرا'),
            onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('اختيار صورة من المعرض'),
            onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
          ),
        ],
      )),
    );
    if (source == null || !mounted) return;
    try {
      final selected = await ImagePicker().pickImage(
        source: source, imageQuality: 75, maxWidth: 1000, maxHeight: 1000,
      );
      if (selected == null || !mounted) return;
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) throw StateError('يرجى تسجيل الدخول.');
      setState(() => _uploadingAvatar = true);
      final bytes = await selected.readAsBytes();
      if (bytes.length > 5 * 1024 * 1024) {
        throw StateError('حجم الصورة أكبر من 5 ميغابايت.');
      }
      // Images always go to the current user's private write prefix.
      final path = '$userId/doctor_avatar.jpg';
      final bucket = Supabase.instance.client.storage.from('avatars');
      await bucket.uploadBinary(
        path, bytes,
        fileOptions: const FileOptions(upsert: true, contentType: 'image/jpeg'),
      );
      final url = '${bucket.getPublicUrl(path)}?v=${DateTime.now().millisecondsSinceEpoch}';
      // Persist independently of profile Save so tapping camera works directly.
      await Supabase.instance.client.from('doctors')
          .update({'avatar_url': url})
          .eq('user_id', userId)
          .select('id').single();
      if (!mounted) return;
      setState(() => _avatarUrl = url);
      AppSnackbar.success(context, 'تم تحديث صورة الملف الشخصي');
    } catch (error) {
      if (!mounted) return;
      AppSnackbar.error(context,
        'تعذر رفع الصورة. تحقق من إذن الكاميرا واتصال الإنترنت.');
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(doctorProvider);

    ref.listen<DoctorState>(doctorProvider, (previous, next) {
      if (next is DoctorProfileLoaded && next.doctor != null) _populate(next.doctor!);
      if (next is DoctorSuccess) AppSnackbar.success(context, next.message);
      if (next is DoctorError) AppSnackbar.error(context, next.message);
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('الملف الشخصي - الطبيب'),
        actions: [
          TextButton(
            onPressed: state is DoctorLoading ? null : _save,
            child: const Text('حفظ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: AppColors.primaryContainer,
                    backgroundImage: _avatarUrl != null && _avatarUrl!.isNotEmpty
                        ? NetworkImage(_avatarUrl!) : null,
                    child: _avatarUrl == null || _avatarUrl!.isEmpty
                        ? const Icon(Icons.person_rounded, size: 60, color: AppColors.primary)
                        : null,
                  ),
                  Positioned(
                    bottom: 0, right: 0,
                    child: Material(
                      color: AppColors.primary,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: _uploadingAvatar ? null : _chooseAvatar,
                        child: Padding(
                          padding: const EdgeInsets.all(9),
                          child: _uploadingAvatar
                              ? const SizedBox(width: 16, height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.camera_alt_rounded,
                                  size: 19, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _field('اسم الطبيب *', _nameCtrl, Icons.person_outline, required: true),
            const SizedBox(height: 12),
            _field('التخصص', _specialtyCtrl, Icons.medical_services_outlined),
            const SizedBox(height: 12),
            _field('رقم الهاتف', _phoneCtrl, Icons.phone_outlined, type: TextInputType.phone),
            const SizedBox(height: 12),
            _field('رقم الترخيص', _licenseCtrl, Icons.badge_outlined),
            const SizedBox(height: 20),
            Text('أيام الدوام', style: AppTextStyles.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                _DayChip(day: 1, label: 'الإثنين', selected: _availableDays.contains(1), onTap: () => _toggleDay(1)),
                _DayChip(day: 2, label: 'الثلاثاء', selected: _availableDays.contains(2), onTap: () => _toggleDay(2)),
                _DayChip(day: 3, label: 'الأربعاء', selected: _availableDays.contains(3), onTap: () => _toggleDay(3)),
                _DayChip(day: 4, label: 'الخميس', selected: _availableDays.contains(4), onTap: () => _toggleDay(4)),
                _DayChip(day: 5, label: 'الجمعة', selected: _availableDays.contains(5), onTap: () => _toggleDay(5)),
                _DayChip(day: 6, label: 'السبت', selected: _availableDays.contains(6), onTap: () => _toggleDay(6)),
                _DayChip(day: 7, label: 'الأحد', selected: _availableDays.contains(7), onTap: () => _toggleDay(7)),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _toggleDay(int day) {
    setState(() {
      if (_availableDays.contains(day)) { _availableDays.remove(day); }
      else { _availableDays.add(day); }
    });
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
    final doctor = DoctorModel(
      id: _existing?.id ?? const Uuid().v4(),
      userId: userId,
      fullName: _nameCtrl.text.trim(),
      specialty: _specialtyCtrl.text.trim().isEmpty ? null : _specialtyCtrl.text.trim(),
      phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      email: Supabase.instance.client.auth.currentUser?.email,
      avatarUrl: _avatarUrl,
      licenseNumber: _licenseCtrl.text.trim().isEmpty ? null : _licenseCtrl.text.trim(),
      availableDays: _availableDays,
      createdAt: _existing?.createdAt ?? DateTime.now(),
    );
    if (_existing != null) { ref.read(doctorProvider.notifier).updateDoctor(doctor); }
    else { ref.read(doctorProvider.notifier).createDoctor(doctor); }
  }

  Widget _field(String label, TextEditingController ctrl, IconData icon, {
    TextInputType type = TextInputType.text, bool required = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.labelLarge),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl, keyboardType: type,
          decoration: InputDecoration(prefixIcon: Icon(icon), hintText: label),
          validator: (v) => required && (v == null || v.isEmpty) ? '$label مطلوب' : null,
        ),
      ],
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _specialtyCtrl.dispose();
    _phoneCtrl.dispose(); _licenseCtrl.dispose();
    super.dispose();
  }
}

class _DayChip extends StatelessWidget {
  final int day; final String label; final bool selected; final VoidCallback onTap;
  const _DayChip({required this.day, required this.label, required this.selected, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.primaryContainer,
      checkmarkColor: AppColors.primary,
    );
  }
}
