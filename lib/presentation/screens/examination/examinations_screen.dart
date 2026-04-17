import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/examination_model.dart';
import '../../blocs/examination/examination_bloc.dart';
import '../../widgets/app_snackbar.dart';

class ExaminationsScreen extends StatelessWidget {
  final String patientId;
  const ExaminationsScreen({super.key, required this.patientId});

  @override
  Widget build(BuildContext context) {
    context.read<ExaminationBloc>().add(LoadExaminations(patientId));
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('الفحوصات'),
          bottom: const TabBar(
            tabs: [Tab(text: 'الفحوصات الطبية'), Tab(text: 'منحنى النمو')],
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            indicatorColor: Colors.white,
          ),
        ),
        body: TabBarView(children: [
          _ExaminationsList(patientId: patientId),
          _GrowthTab(patientId: patientId),
        ]),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showAddExaminationSheet(context, patientId),
          icon: const Icon(Icons.add_rounded),
          label: const Text('إضافة فحص'),
        ),
      ),
    );
  }

  static void _showAddExaminationSheet(BuildContext ctx, String patientId) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => BlocProvider.value(
        value: ctx.read<ExaminationBloc>(),
        child: _AddExaminationSheet(patientId: patientId),
      ),
    );
  }
}

class _ExaminationsList extends StatelessWidget {
  final String patientId;
  const _ExaminationsList({required this.patientId});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ExaminationBloc, ExaminationState>(
      listener: (ctx, state) {
        if (state is ExaminationSuccess) {
          AppSnackbar.success(ctx, state.message);
          ctx.read<ExaminationBloc>().add(LoadExaminations(patientId));
        }
        if (state is ExaminationError) AppSnackbar.error(ctx, state.message);
      },
      builder: (ctx, state) {
        if (state is ExaminationLoading) return const Center(child: CircularProgressIndicator());
        if (state is ExaminationsLoaded && state.examinations.isEmpty) {
          return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.medical_services_outlined, size: 64, color: AppColors.textHint),
            const SizedBox(height: 16),
            Text('لا توجد فحوصات مسجلة', style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textHint)),
          ]));
        }
        if (state is ExaminationsLoaded) {
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: state.examinations.length,
            itemBuilder: (ctx, i) {
              final exam = state.examinations[i];
              return _ExamCard(exam: exam, onDelete: () => ctx.read<ExaminationBloc>().add(DeleteExamination(exam.id)))
                  .animate(delay: Duration(milliseconds: i * 60)).fadeIn().slideX(begin: 0.2);
            },
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class _ExamCard extends StatelessWidget {
  final ExaminationModel exam;
  final VoidCallback onDelete;
  const _ExamCard({required this.exam, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final typeIcons = {
      'vision': Icons.visibility_rounded, 'hearing': Icons.hearing_rounded,
      'growth': Icons.monitor_weight_rounded, 'blood': Icons.bloodtype_rounded, 'general': Icons.medical_services_rounded,
    };
    final typeLabels = {'vision': 'فحص النظر', 'hearing': 'فحص السمع', 'growth': 'فحص النمو', 'blood': 'فحص الدم', 'general': 'الفحص العام'};
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            CircleAvatar(backgroundColor: AppColors.primaryContainer, child: Icon(typeIcons[exam.type] ?? Icons.medical_services_rounded, color: AppColors.primary, size: 20)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(typeLabels[exam.type] ?? exam.type, style: AppTextStyles.titleSmall),
              Text('${exam.examinationDate.day}/${exam.examinationDate.month}/${exam.examinationDate.year}', style: AppTextStyles.bodySmall),
            ])),
            IconButton(onPressed: onDelete, icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20)),
          ]),
          if (exam.result != null) ...[
            const Divider(height: 16),
            Text('النتيجة: ${exam.result}', style: AppTextStyles.bodyMedium),
          ],
          if (exam.notes != null) ...[
            const SizedBox(height: 4),
            Text('ملاحظات: ${exam.notes}', style: AppTextStyles.bodySmall),
          ],
          // Type-specific fields
          if (exam.type == 'vision' && (exam.leftEyeVision != null || exam.rightEyeVision != null)) ...[
            const Divider(height: 16),
            Row(children: [
              if (exam.leftEyeVision != null) Expanded(child: Text('العين اليسرى: ${exam.leftEyeVision}', style: AppTextStyles.bodySmall)),
              if (exam.rightEyeVision != null) Expanded(child: Text('العين اليمنى: ${exam.rightEyeVision}', style: AppTextStyles.bodySmall)),
            ]),
          ],
          if (exam.type == 'growth' && exam.weightAtExam != null) ...[
            const Divider(height: 16),
            Row(children: [
              if (exam.weightAtExam != null) Expanded(child: Text('الوزن: ${exam.weightAtExam} كغ', style: AppTextStyles.bodySmall)),
              if (exam.heightAtExam != null) Expanded(child: Text('الطول: ${exam.heightAtExam} سم', style: AppTextStyles.bodySmall)),
            ]),
          ],
        ]),
      ),
    );
  }
}

class _GrowthTab extends StatelessWidget {
  final String patientId;
  const _GrowthTab({required this.patientId});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.bar_chart_rounded, size: 80, color: AppColors.primary),
            const SizedBox(height: 16),
            Text('رسوم النمو البياني', style: AppTextStyles.titleLarge),
            const SizedBox(height: 8),
            Text('يمكنك عرض منحنيات النمو الكاملة من قسم الرسوم البيانية', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _AddExaminationSheet extends StatefulWidget {
  final String patientId;
  const _AddExaminationSheet({required this.patientId});
  @override State<_AddExaminationSheet> createState() => _AddExaminationSheetState();
}

class _AddExaminationSheetState extends State<_AddExaminationSheet> {
  String _type = 'general';
  final _resultCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _leftEyeCtrl = TextEditingController();
  final _rightEyeCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();

  final _types = ['general', 'vision', 'hearing', 'growth', 'blood'];
  final _typeLabels = {'general': 'فحص عام', 'vision': 'فحص النظر', 'hearing': 'فحص السمع', 'growth': 'فحص النمو', 'blood': 'فحص الدم'};

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('إضافة فحص جديد', style: AppTextStyles.headlineSmall),
            const SizedBox(height: 20),
            Text('نوع الفحص', style: AppTextStyles.labelLarge),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: _types.map((t) => ChoiceChip(
              label: Text(_typeLabels[t]!),
              selected: _type == t,
              selectedColor: AppColors.primaryContainer,
              onSelected: (_) => setState(() => _type = t),
            )).toList()),
            const SizedBox(height: 16),
            if (_type == 'vision') ...[
              Row(children: [
                Expanded(child: TextField(controller: _leftEyeCtrl, decoration: const InputDecoration(labelText: 'العين اليسرى'))),
                const SizedBox(width: 12),
                Expanded(child: TextField(controller: _rightEyeCtrl, decoration: const InputDecoration(labelText: 'العين اليمنى'))),
              ]),
              const SizedBox(height: 12),
            ],
            if (_type == 'growth') ...[
              Row(children: [
                Expanded(child: TextField(controller: _weightCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'الوزن (كغ)'))),
                const SizedBox(width: 12),
                Expanded(child: TextField(controller: _heightCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'الطول (سم)'))),
              ]),
              const SizedBox(height: 12),
            ],
            TextField(controller: _resultCtrl, decoration: const InputDecoration(labelText: 'النتيجة', prefixIcon: Icon(Icons.fact_check_outlined))),
            const SizedBox(height: 12),
            TextField(controller: _notesCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'ملاحظات', prefixIcon: Icon(Icons.notes_rounded))),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final doctorId = Supabase.instance.client.auth.currentUser?.id ?? '';
                  context.read<ExaminationBloc>().add(AddExamination(ExaminationModel(
                    id: const Uuid().v4(),
                    patientId: widget.patientId,
                    doctorId: doctorId,
                    type: _type,
                    examinationDate: DateTime.now(),
                    result: _resultCtrl.text.trim().isEmpty ? null : _resultCtrl.text.trim(),
                    notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
                    leftEyeVision: _leftEyeCtrl.text.trim().isEmpty ? null : _leftEyeCtrl.text.trim(),
                    rightEyeVision: _rightEyeCtrl.text.trim().isEmpty ? null : _rightEyeCtrl.text.trim(),
                    weightAtExam: double.tryParse(_weightCtrl.text),
                    heightAtExam: double.tryParse(_heightCtrl.text),
                    createdAt: DateTime.now(),
                  )));
                  Navigator.pop(context);
                },
                child: const Text('إضافة الفحص'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
