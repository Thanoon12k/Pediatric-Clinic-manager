import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../blocs/doctor/doctor_bloc.dart';
import '../../widgets/app_snackbar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../data/models/doctor_model.dart';
import 'package:uuid/uuid.dart';

class DoctorProfileScreen extends StatefulWidget {
  const DoctorProfileScreen({super.key});
  @override State<DoctorProfileScreen> createState() => _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends State<DoctorProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _specialtyCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _licenseCtrl = TextEditingController();
  List<int> _availableDays = [1, 2, 3, 4, 6];
  DoctorModel? _existing;

  @override
  void initState() {
    super.initState();
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null) context.read<DoctorBloc>().add(LoadDoctorByUserId(userId));
  }

  void _populate(DoctorModel doctor) {
    _existing = doctor;
    _nameCtrl.text = doctor.fullName;
    _specialtyCtrl.text = doctor.specialty ?? '';
    _phoneCtrl.text = doctor.phone ?? '';
    _licenseCtrl.text = doctor.licenseNumber ?? '';
    setState(() => _availableDays = List.from(doctor.availableDays));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DoctorBloc, DoctorState>(
      listener: (context, state) {
        if (state is DoctorProfileLoaded && state.doctor != null) _populate(state.doctor!);
        if (state is DoctorSuccess) AppSnackbar.success(context, state.message);
        if (state is DoctorError) AppSnackbar.error(context, state.message);
      },
      builder: (context, state) => Scaffold(
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
                      child: const Icon(Icons.person_rounded, size: 60, color: AppColors.primary),
                    ),
                    Positioned(
                      bottom: 0, right: 0,
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: AppColors.primary,
                        child: const Icon(Icons.camera_alt_rounded, size: 16, color: Colors.white),
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
      licenseNumber: _licenseCtrl.text.trim().isEmpty ? null : _licenseCtrl.text.trim(),
      availableDays: _availableDays,
      createdAt: _existing?.createdAt ?? DateTime.now(),
    );
    if (_existing != null) { context.read<DoctorBloc>().add(UpdateDoctor(doctor)); }
    else { context.read<DoctorBloc>().add(CreateDoctor(doctor)); }
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
