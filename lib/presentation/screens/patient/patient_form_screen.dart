import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/patient_model.dart';
import '../../blocs/patient/patient_bloc.dart';
import '../../blocs/doctor/doctor_bloc.dart';
import '../../widgets/app_snackbar.dart';

class PatientFormScreen extends StatefulWidget {
  final String? patientId;
  const PatientFormScreen({super.key, this.patientId});

  @override
  State<PatientFormScreen> createState() => _PatientFormScreenState();
}

class _PatientFormScreenState extends State<PatientFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _guardianNameCtrl = TextEditingController();
  final _guardianPhoneCtrl = TextEditingController();
  final _guardianEmailCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _allergiesCtrl = TextEditingController();
  final _chronicCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();

  Gender _gender = Gender.male;
  DateTime _dateOfBirth = DateTime.now().subtract(const Duration(days: 365));
  String? _bloodType;
  TreatmentStatus _treatmentStatus = TreatmentStatus.underTreatment;
  DateTime? _nextVisitDate;
  bool _allowChat = true, _allowPhotos = true, _allowVoice = true, _allowMessages = true;
  String? _doctorId;

  bool get isEditing => widget.patientId != null;

  @override
  void initState() {
    super.initState();
    _loadDoctorId();
    if (isEditing) {
      context.read<PatientBloc>().add(LoadPatientById(widget.patientId!));
    }
  }

  void _loadDoctorId() {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null) {
      context.read<DoctorBloc>().add(LoadDoctorByUserId(userId));
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _guardianNameCtrl.dispose(); _guardianPhoneCtrl.dispose();
    _guardianEmailCtrl.dispose(); _addressCtrl.dispose(); _notesCtrl.dispose();
    _allergiesCtrl.dispose(); _chronicCtrl.dispose(); _weightCtrl.dispose(); _heightCtrl.dispose();
    super.dispose();
  }

  void _populateFromExisting(PatientModel patient) {
    _nameCtrl.text = patient.fullName;
    _guardianNameCtrl.text = patient.guardianName;
    _guardianPhoneCtrl.text = patient.guardianPhone;
    _guardianEmailCtrl.text = patient.guardianEmail ?? '';
    _addressCtrl.text = patient.address ?? '';
    _notesCtrl.text = patient.notes ?? '';
    _allergiesCtrl.text = patient.allergies ?? '';
    _chronicCtrl.text = patient.chronicDiseases ?? '';
    _weightCtrl.text = patient.weight?.toString() ?? '';
    _heightCtrl.text = patient.height?.toString() ?? '';
    setState(() {
      _gender = patient.gender;
      _dateOfBirth = patient.dateOfBirth;
      _bloodType = patient.bloodType;
      _treatmentStatus = patient.treatmentStatus;
      _nextVisitDate = patient.nextVisitDate;
      _allowChat = patient.allowChat;
      _allowPhotos = patient.allowPhotos;
      _allowVoice = patient.allowVoice;
      _allowMessages = patient.allowMessages;
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_doctorId == null) { AppSnackbar.error(context, 'تعذر تحديد الطبيب'); return; }

    final patient = PatientModel(
      id: isEditing ? widget.patientId! : const Uuid().v4(),
      doctorId: _doctorId!,
      fullName: _nameCtrl.text.trim(),
      dateOfBirth: _dateOfBirth,
      gender: _gender,
      bloodType: _bloodType,
      weight: double.tryParse(_weightCtrl.text),
      height: double.tryParse(_heightCtrl.text),
      guardianName: _guardianNameCtrl.text.trim(),
      guardianPhone: _guardianPhoneCtrl.text.trim(),
      guardianEmail: _guardianEmailCtrl.text.trim().isEmpty ? null : _guardianEmailCtrl.text.trim(),
      address: _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      allergies: _allergiesCtrl.text.trim().isEmpty ? null : _allergiesCtrl.text.trim(),
      chronicDiseases: _chronicCtrl.text.trim().isEmpty ? null : _chronicCtrl.text.trim(),
      treatmentStatus: _treatmentStatus,
      nextVisitDate: _nextVisitDate,
      allowChat: _allowChat,
      allowPhotos: _allowPhotos,
      allowVoice: _allowVoice,
      allowMessages: _allowMessages,
      createdAt: DateTime.now(),
    );

    if (isEditing) {
      context.read<PatientBloc>().add(UpdatePatient(patient));
    } else {
      context.read<PatientBloc>().add(CreatePatient(patient));
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<PatientBloc, PatientState>(
          listener: (context, state) {
            if (state is PatientLoaded && isEditing) {
              _populateFromExisting(state.patient);
            }
            if (state is PatientOperationSuccess) {
              AppSnackbar.success(context, state.message);
              context.go(AppConstants.routePatientList);
            }
            if (state is PatientError) AppSnackbar.error(context, state.message);
          },
        ),
        BlocListener<DoctorBloc, DoctorState>(
          listener: (context, state) {
            if (state is DoctorProfileLoaded && state.doctor != null) {
              setState(() => _doctorId = state.doctor!.id);
            }
          },
        ),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: Text(isEditing ? 'تعديل بيانات المريض' : 'إضافة مريض جديد'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => context.pop(),
          ),
          actions: [
            BlocBuilder<PatientBloc, PatientState>(
              builder: (context, state) => TextButton(
                onPressed: state is PatientLoading ? null : _submit,
                child: const Text('حفظ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
        body: BlocBuilder<PatientBloc, PatientState>(
          builder: (context, state) {
            if (state is PatientLoading && isEditing) {
              return const Center(child: CircularProgressIndicator());
            }
            return Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildSection('البيانات الأساسية', [
                    _buildTextField('اسم المريض *', _nameCtrl, Icons.person_outline, required: true),
                    const SizedBox(height: 12),
                    _buildDateField('تاريخ الميلاد *', _dateOfBirth, (picked) => setState(() => _dateOfBirth = picked)),
                    const SizedBox(height: 12),
                    _buildGenderSelector(),
                    const SizedBox(height: 12),
                    _buildBloodTypeDropdown(),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(child: _buildTextField('الوزن (كغ)', _weightCtrl, Icons.monitor_weight_rounded, type: TextInputType.number)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildTextField('الطول (سم)', _heightCtrl, Icons.height_rounded, type: TextInputType.number)),
                    ]),
                  ]),
                  const SizedBox(height: 16),
                  _buildSection('ولي الأمر', [
                    _buildTextField('اسم ولي الأمر *', _guardianNameCtrl, Icons.family_restroom_rounded, required: true),
                    const SizedBox(height: 12),
                    _buildTextField('هاتف ولي الأمر *', _guardianPhoneCtrl, Icons.phone_outlined, type: TextInputType.phone, required: true),
                    const SizedBox(height: 12),
                    _buildTextField('البريد الإلكتروني', _guardianEmailCtrl, Icons.email_outlined, type: TextInputType.emailAddress),
                    const SizedBox(height: 12),
                    _buildTextField('العنوان', _addressCtrl, Icons.location_on_outlined),
                  ]),
                  const SizedBox(height: 16),
                  _buildSection('الحالة الصحية', [
                    _buildTreatmentStatusSelector(),
                    const SizedBox(height: 12),
                    _buildTextField('الحساسية', _allergiesCtrl, Icons.warning_amber_outlined),
                    const SizedBox(height: 12),
                    _buildTextField('أمراض مزمنة', _chronicCtrl, Icons.local_hospital_outlined),
                    const SizedBox(height: 12),
                    _buildDateField('المراجعة القادمة', _nextVisitDate, (d) => setState(() => _nextVisitDate = d), allowNull: true),
                  ]),
                  const SizedBox(height: 16),
                  _buildSection('تمكين التواصل', [
                    _buildSwitch('المحادثة النصية', _allowChat, (v) => setState(() => _allowChat = v)),
                    _buildSwitch('إرسال الصور', _allowPhotos, (v) => setState(() => _allowPhotos = v)),
                    _buildSwitch('الرسائل الصوتية', _allowVoice, (v) => setState(() => _allowVoice = v)),
                    _buildSwitch('الرسائل النصية', _allowMessages, (v) => setState(() => _allowMessages = v)),
                  ]),
                  const SizedBox(height: 16),
                  _buildSection('ملاحظات', [
                    TextFormField(
                      controller: _notesCtrl,
                      maxLines: 4,
                      decoration: const InputDecoration(hintText: 'أدخل ملاحظاتك هنا...', prefixIcon: Icon(Icons.notes_rounded)),
                    ),
                  ]),
                  const SizedBox(height: 32),
                  BlocBuilder<PatientBloc, PatientState>(
                    builder: (context, state) => ElevatedButton(
                      onPressed: state is PatientLoading ? null : _submit,
                      child: state is PatientLoading
                          ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Text(isEditing ? 'حفظ التعديلات' : 'إضافة المريض'),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(title, style: AppTextStyles.titleSmall.copyWith(color: AppColors.primary)),
          ),
          Divider(height: 1),
          Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children)),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController ctrl, IconData icon, {
    TextInputType type = TextInputType.text, bool required = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.labelLarge),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl,
          keyboardType: type,
          decoration: InputDecoration(prefixIcon: Icon(icon), hintText: label),
          validator: (v) => required && (v == null || v.isEmpty) ? '$label مطلوب' : null,
        ),
      ],
    );
  }

  Widget _buildDateField(String label, DateTime? value, Function(DateTime) onChanged, {bool allowNull = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.labelLarge),
        const SizedBox(height: 6),
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: value ?? DateTime.now(),
              firstDate: DateTime(1900),
              lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
            );
            if (picked != null) onChanged(picked);
          },
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_rounded, color: AppColors.textSecondary, size: 20),
                const SizedBox(width: 12),
                Text(
                  value != null ? '${value.day}/${value.month}/${value.year}' : 'اختر التاريخ',
                  style: AppTextStyles.bodyMedium.copyWith(color: value != null ? AppColors.textPrimary : AppColors.textHint),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGenderSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('الجنس', style: AppTextStyles.labelLarge),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(child: _GenderButton(gender: Gender.male, selected: _gender == Gender.male, onTap: () => setState(() => _gender = Gender.male))),
            const SizedBox(width: 12),
            Expanded(child: _GenderButton(gender: Gender.female, selected: _gender == Gender.female, onTap: () => setState(() => _gender = Gender.female))),
          ],
        ),
      ],
    );
  }

  Widget _buildBloodTypeDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('فصيلة الدم', style: AppTextStyles.labelLarge),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          // ignore: deprecated_member_use
          value: _bloodType,
          decoration: const InputDecoration(prefixIcon: Icon(Icons.bloodtype_outlined)),
          hint: const Text('اختر فصيلة الدم'),
          items: AppConstants.bloodTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
          onChanged: (v) => setState(() => _bloodType = v),
        ),
      ],
    );
  }

  Widget _buildTreatmentStatusSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('حالة العلاج', style: AppTextStyles.labelLarge),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(child: _StatusButton(label: 'قيد العلاج', selected: _treatmentStatus == TreatmentStatus.underTreatment, color: AppColors.primary, onTap: () => setState(() => _treatmentStatus = TreatmentStatus.underTreatment))),
            const SizedBox(width: 12),
            Expanded(child: _StatusButton(label: 'تم الشفاء', selected: _treatmentStatus == TreatmentStatus.recovered, color: AppColors.success, onTap: () => setState(() => _treatmentStatus = TreatmentStatus.recovered))),
          ],
        ),
      ],
    );
  }

  Widget _buildSwitch(String label, bool value, Function(bool) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppTextStyles.bodyMedium)),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _GenderButton extends StatelessWidget {
  final Gender gender;
  final bool selected;
  final VoidCallback onTap;
  const _GenderButton({required this.gender, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isMale = gender == Gender.male;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? (isMale ? Colors.blue.withValues(alpha: 0.1) : Colors.pink.withValues(alpha: 0.1)) : Colors.grey.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? (isMale ? Colors.blue : Colors.pink) : AppColors.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isMale ? Icons.male_rounded : Icons.female_rounded, color: selected ? (isMale ? Colors.blue : Colors.pink) : AppColors.textSecondary),
            const SizedBox(width: 8),
            Text(isMale ? 'ذكر' : 'أنثى', style: AppTextStyles.labelLarge.copyWith(color: selected ? (isMale ? Colors.blue : Colors.pink) : AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _StatusButton extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  const _StatusButton({required this.label, required this.selected, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? color : AppColors.border),
        ),
        child: Center(child: Text(label, style: AppTextStyles.labelLarge.copyWith(color: selected ? color : AppColors.textSecondary))),
      ),
    );
  }
}
