import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/medication_model.dart';
import '../../providers/medication/medication_provider.dart';
import '../../providers/doctor/doctor_provider.dart';
import '../../widgets/app_snackbar.dart';

class MedicationsScreen extends ConsumerStatefulWidget {
  const MedicationsScreen({super.key});
  @override ConsumerState<MedicationsScreen> createState() => _MedicationsScreenState();
}

class _MedicationsScreenState extends ConsumerState<MedicationsScreen> {
  String? _doctorId;
  String _search = '';

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId != null) ref.read(doctorProvider.notifier).loadDoctorByUserId(userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<DoctorState>(doctorProvider, (previous, next) {
      if (next is DoctorProfileLoaded && next.doctor != null) {
        setState(() => _doctorId = next.doctor!.id);
        ref.read(medicationProvider.notifier).loadMedications(next.doctor!.id);
      }
    });

    final state = ref.watch(medicationProvider);

    ref.listen<MedicationState>(medicationProvider, (previous, next) {
      if (next is MedicationSuccess) {
        AppSnackbar.success(context, next.message);
        if (_doctorId != null) ref.read(medicationProvider.notifier).loadMedications(_doctorId!);
      }
      if (next is MedicationError) AppSnackbar.error(context, next.message);
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('قائمة الأدوية'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              onChanged: (v) => setState(() => _search = v.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'البحث عن دواء...',
                hintStyle: const TextStyle(color: Colors.white60),
                prefixIcon: const Icon(Icons.search_rounded, color: Colors.white70),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.15),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ),
      ),
      body: Builder(
        builder: (context) {
          if (state is MedicationLoading) return const Center(child: CircularProgressIndicator());
          if (state is MedicationsLoaded) {
            final meds = state.medications
                .where((m) => _search.isEmpty || m.name.toLowerCase().contains(_search) || (m.genericName?.toLowerCase().contains(_search) ?? false))
                .toList();
            if (meds.isEmpty) {
              return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.medication_outlined, size: 80, color: AppColors.textHint),
                const SizedBox(height: 16),
                Text('لا توجد أدوية مسجلة', style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textHint)),
              ]));
            }
            // Group by form
            final grouped = <String, List<MedicationModel>>{};
            for (final m in meds) {
              final key = m.form ?? 'أخرى';
              grouped.putIfAbsent(key, () => []).add(m);
            }
            return ListView(
              padding: const EdgeInsets.all(16),
              children: grouped.entries.expand((entry) => [
                _FormHeader(label: _formLabel(entry.key)),
                ...entry.value.asMap().entries.map((e) => _MedicationCard(
                  med: e.value,
                  onDelete: () => ref.read(medicationProvider.notifier).deleteMedication(e.value.id),
                ).animate(delay: Duration(milliseconds: e.key * 40)).fadeIn().slideX(begin: 0.2)),
                const SizedBox(height: 8),
              ]).toList(),
            );
          }
          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddMedicationSheet(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('إضافة دواء'),
      ),
    );
  }

  String _formLabel(String form) {
    const labels = {'tablet': 'أقراص', 'syrup': 'شراب', 'injection': 'حقن', 'drops': 'قطرات', 'cream': 'كريم', 'أخرى': 'أخرى'};
    return labels[form] ?? form;
  }

  void _showAddMedicationSheet(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _AddMedicationSheet(doctorId: _doctorId ?? ''),
    );
  }
}

class _FormHeader extends StatelessWidget {
  final String label;
  const _FormHeader({required this.label});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(children: [
      const Icon(Icons.medication_rounded, size: 18, color: AppColors.primary),
      const SizedBox(width: 8),
      Text(label, style: AppTextStyles.titleSmall.copyWith(color: AppColors.primary)),
    ]),
  );
}

class _MedicationCard extends StatelessWidget {
  final MedicationModel med;
  final VoidCallback onDelete;
  const _MedicationCard({required this.med, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primaryContainer,
          child: Text(med.name[0], style: AppTextStyles.titleMedium.copyWith(color: AppColors.primary)),
        ),
        title: Text(med.name, style: AppTextStyles.titleSmall),
        subtitle: Text([
          if (med.genericName != null) med.genericName!,
          if (med.strength != null) med.strength!,
        ].join(' — '), style: AppTextStyles.bodySmall),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          if (med.form != null) Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: AppColors.primaryContainer, borderRadius: BorderRadius.circular(12)),
            child: Text(_formLabel(med.form!), style: AppTextStyles.labelSmall.copyWith(color: AppColors.primary)),
          ),
          IconButton(icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20), onPressed: onDelete),
        ]),
      ),
    );
  }

  String _formLabel(String form) {
    const labels = {'tablet': 'قرص', 'syrup': 'شراب', 'injection': 'حقنة', 'drops': 'قطرة', 'cream': 'كريم'};
    return labels[form] ?? form;
  }
}

class _AddMedicationSheet extends ConsumerStatefulWidget {
  final String doctorId;
  const _AddMedicationSheet({required this.doctorId});
  @override ConsumerState<_AddMedicationSheet> createState() => _AddMedicationSheetState();
}

class _AddMedicationSheetState extends ConsumerState<_AddMedicationSheet> {
  final _nameCtrl = TextEditingController();
  final _genericCtrl = TextEditingController();
  final _strengthCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String _form = 'tablet';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Text('إضافة دواء جديد', style: AppTextStyles.headlineSmall),
          const SizedBox(height: 16),
          TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'اسم الدواء *', prefixIcon: Icon(Icons.medication_rounded))),
          const SizedBox(height: 12),
          TextField(controller: _genericCtrl, decoration: const InputDecoration(labelText: 'الاسم العلمي', prefixIcon: Icon(Icons.science_outlined))),
          const SizedBox(height: 12),
          TextField(controller: _strengthCtrl, decoration: const InputDecoration(labelText: 'التركيز (مثال: 250mg)', prefixIcon: Icon(Icons.numbers_rounded))),
          const SizedBox(height: 12),
          Text('الشكل الصيدلاني', style: AppTextStyles.labelLarge),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final f in ['tablet', 'syrup', 'injection', 'drops', 'cream'])
              ChoiceChip(
                label: Text({'tablet': 'قرص', 'syrup': 'شراب', 'injection': 'حقنة', 'drops': 'قطرة', 'cream': 'كريم'}[f]!),
                selected: _form == f,
                selectedColor: AppColors.primaryContainer,
                onSelected: (_) => setState(() => _form = f),
              ),
          ]),
          const SizedBox(height: 12),
          TextField(controller: _notesCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'ملاحظات', prefixIcon: Icon(Icons.notes_rounded))),
          const SizedBox(height: 20),
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: () {
              if (_nameCtrl.text.trim().isEmpty) return;
              ref.read(medicationProvider.notifier).addMedication(MedicationModel(
                id: const Uuid().v4(),
                doctorId: widget.doctorId,
                name: _nameCtrl.text.trim(),
                genericName: _genericCtrl.text.trim().isEmpty ? null : _genericCtrl.text.trim(),
                form: _form,
                strength: _strengthCtrl.text.trim().isEmpty ? null : _strengthCtrl.text.trim(),
                notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
                createdAt: DateTime.now(),
              ));
              Navigator.pop(context);
            },
            child: const Text('إضافة الدواء'),
          )),
        ]),
      ),
    );
  }
}
