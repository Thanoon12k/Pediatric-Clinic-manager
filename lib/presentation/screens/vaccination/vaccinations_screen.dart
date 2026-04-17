import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/vaccination_model.dart';
import '../../blocs/vaccination/vaccination_bloc.dart';
import '../../widgets/app_snackbar.dart';

class VaccinationsScreen extends StatelessWidget {
  final String patientId;
  const VaccinationsScreen({super.key, required this.patientId});

  @override
  Widget build(BuildContext context) {
    context.read<VaccinationBloc>().add(LoadVaccinations(patientId));
    return Scaffold(
      appBar: AppBar(title: const Text('التحصينات')),
      body: BlocConsumer<VaccinationBloc, VaccinationState>(
        listener: (ctx, state) {
          if (state is VaccinationSuccess) {
            AppSnackbar.success(ctx, state.message);
            ctx.read<VaccinationBloc>().add(LoadVaccinations(patientId));
          }
          if (state is VaccinationError) AppSnackbar.error(ctx, state.message);
        },
        builder: (ctx, state) {
          if (state is VaccinationLoading) return const Center(child: CircularProgressIndicator());
          if (state is VaccinationsLoaded && state.vaccinations.isEmpty) {
            return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.vaccines_outlined, size: 80, color: AppColors.textHint),
              const SizedBox(height: 16),
              Text('لا توجد تحصينات مسجلة', style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textHint)),
            ]));
          }
          if (state is VaccinationsLoaded) {
            // Group by status
            final given = state.vaccinations.where((v) => v.status == VaccinationStatus.given).toList();
            final due = state.vaccinations.where((v) => v.status == VaccinationStatus.due).toList();
            final overdue = state.vaccinations.where((v) => v.status == VaccinationStatus.overdue).toList();
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (overdue.isNotEmpty) ...[
                  _SectionHeader(label: 'متأخر ⚠️', color: AppColors.error),
                  ...overdue.map((v) => _VaccineCard(v: v, onDelete: () => ctx.read<VaccinationBloc>().add(DeleteVaccination(v.id)))),
                  const SizedBox(height: 12),
                ],
                if (due.isNotEmpty) ...[
                  _SectionHeader(label: 'موعد مستحق', color: AppColors.warning),
                  ...due.map((v) => _VaccineCard(v: v, onMarkGiven: () {
                    ctx.read<VaccinationBloc>().add(UpdateVaccination(VaccinationModel(
                      id: v.id, patientId: v.patientId, doctorId: v.doctorId,
                      vaccineName: v.vaccineName, dateGiven: DateTime.now(),
                      status: VaccinationStatus.given, doseNumber: v.doseNumber,
                      createdAt: v.createdAt,
                    )));
                  }, onDelete: () => ctx.read<VaccinationBloc>().add(DeleteVaccination(v.id)))),
                  const SizedBox(height: 12),
                ],
                if (given.isNotEmpty) ...[
                  _SectionHeader(label: 'تم تطعيمه ✓', color: AppColors.success),
                  ...given.map((v) => _VaccineCard(v: v, onDelete: () => ctx.read<VaccinationBloc>().add(DeleteVaccination(v.id)))),
                ],
              ],
            );
          }
          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddVaccineSheet(context, patientId),
        icon: const Icon(Icons.add_rounded),
        label: const Text('إضافة تحصين'),
      ),
    );
  }

  static void _showAddVaccineSheet(BuildContext ctx, String patientId) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => BlocProvider.value(
        value: ctx.read<VaccinationBloc>(),
        child: _AddVaccineSheet(patientId: patientId),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label; final Color color;
  const _SectionHeader({required this.label, required this.color});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Text(label, style: AppTextStyles.titleSmall.copyWith(color: color)),
  );
}

class _VaccineCard extends StatelessWidget {
  final VaccinationModel v;
  final VoidCallback? onMarkGiven;
  final VoidCallback onDelete;
  const _VaccineCard({required this.v, this.onMarkGiven, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final statusColors = {
      VaccinationStatus.given: AppColors.success,
      VaccinationStatus.due: AppColors.warning,
      VaccinationStatus.overdue: AppColors.error,
    };
    final statusLabels = {
      VaccinationStatus.given: 'تم الإعطاء',
      VaccinationStatus.due: 'مستحق',
      VaccinationStatus.overdue: 'متأخر',
    };
    final color = statusColors[v.status]!;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          CircleAvatar(backgroundColor: color.withValues(alpha: 0.1), child: Icon(Icons.vaccines_rounded, color: color, size: 20)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${v.vaccineName} — جرعة ${v.doseNumber}', style: AppTextStyles.titleSmall),
            if (v.dateGiven != null) Text('تاريخ الإعطاء: ${v.dateGiven!.day}/${v.dateGiven!.month}/${v.dateGiven!.year}', style: AppTextStyles.bodySmall),
            if (v.nextDueDate != null) Text('المستحق التالي: ${v.nextDueDate!.day}/${v.nextDueDate!.month}/${v.nextDueDate!.year}', style: AppTextStyles.bodySmall),
          ])),
          Column(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              child: Text(statusLabels[v.status]!, style: AppTextStyles.labelSmall.copyWith(color: color)),
            ),
            if (onMarkGiven != null) ...[
              const SizedBox(height: 6),
              TextButton(onPressed: onMarkGiven, child: const Text('أُعطي ✓', style: TextStyle(fontSize: 12))),
            ],
            IconButton(onPressed: onDelete, icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 18)),
          ]),
        ]),
      ),
    ).animate().fadeIn().slideX(begin: 0.2);
  }
}

class _AddVaccineSheet extends StatefulWidget {
  final String patientId;
  const _AddVaccineSheet({required this.patientId});
  @override State<_AddVaccineSheet> createState() => _AddVaccineSheetState();
}

class _AddVaccineSheetState extends State<_AddVaccineSheet> {
  final _nameCtrl = TextEditingController();
  final _doseCtrl = TextEditingController(text: '1');
  final _batchCtrl = TextEditingController();
  DateTime? _dateGiven = DateTime.now();
  DateTime? _nextDue;

  // Common vaccines
  final _commonVaccines = ['BCG', 'الثلاثي (DPT)', 'شلل الأطفال (IPV)', 'الكبد الوبائي ب', 'MMR', 'الحصبة', 'التهاب السحايا', 'الروتا', 'الإنفلونزا'];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Text('إضافة تحصين جديد', style: AppTextStyles.headlineSmall),
          const SizedBox(height: 16),
          Text('اللقاحات الشائعة', style: AppTextStyles.labelLarge),
          const SizedBox(height: 8),
          Wrap(spacing: 6, runSpacing: 6, children: _commonVaccines.map((v) => ActionChip(
            label: Text(v, style: const TextStyle(fontSize: 12)),
            onPressed: () { _nameCtrl.text = v; setState(() {}); },
          )).toList()),
          const SizedBox(height: 12),
          TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'اسم اللقاح *', prefixIcon: Icon(Icons.vaccines_rounded))),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: TextField(controller: _doseCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'رقم الجرعة'))),
            const SizedBox(width: 12),
            Expanded(child: TextField(controller: _batchCtrl, decoration: const InputDecoration(labelText: 'رقم الدفعة'))),
          ]),
          const SizedBox(height: 12),
          _DateRow(label: 'تاريخ الإعطاء', value: _dateGiven, onPick: (d) => setState(() => _dateGiven = d)),
          const SizedBox(height: 8),
          _DateRow(label: 'الجرعة القادمة', value: _nextDue, onPick: (d) => setState(() => _nextDue = d)),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                if (_nameCtrl.text.trim().isEmpty) return;
                final doctorId = Supabase.instance.client.auth.currentUser?.id ?? '';
                context.read<VaccinationBloc>().add(AddVaccination(VaccinationModel(
                  id: const Uuid().v4(),
                  patientId: widget.patientId,
                  doctorId: doctorId,
                  vaccineName: _nameCtrl.text.trim(),
                  dateGiven: _dateGiven,
                  nextDueDate: _nextDue,
                  status: _dateGiven != null ? VaccinationStatus.given : VaccinationStatus.due,
                  doseNumber: int.tryParse(_doseCtrl.text) ?? 1,
                  batchNumber: _batchCtrl.text.trim().isEmpty ? null : _batchCtrl.text.trim(),
                  createdAt: DateTime.now(),
                )));
                Navigator.pop(context);
              },
              child: const Text('إضافة التحصين'),
            ),
          ),
        ]),
      ),
    );
  }
}

class _DateRow extends StatelessWidget {
  final String label; final DateTime? value; final Function(DateTime) onPick;
  const _DateRow({required this.label, required this.value, required this.onPick});
  @override
  Widget build(BuildContext context) => Row(children: [
    Expanded(child: Text(label, style: AppTextStyles.bodyMedium)),
    TextButton.icon(
      onPressed: () async {
        final d = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime.now().add(const Duration(days: 365 * 5)));
        if (d != null) onPick(d);
      },
      icon: const Icon(Icons.calendar_today_rounded, size: 16),
      label: Text(value != null ? '${value!.day}/${value!.month}/${value!.year}' : 'اختر التاريخ', style: const TextStyle(fontSize: 13)),
    ),
  ]);
}
