import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../providers/patient/patient_provider.dart';
import '../../widgets/patient_list_tile.dart';

class PatientListScreen extends ConsumerWidget {
  const PatientListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(patientProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('قائمة المرضى')),
      body: Builder(
        builder: (context) {
          if (state is PatientLoading) return const Center(child: CircularProgressIndicator());
          if (state is PatientsLoaded && state.patients.isEmpty) {
            return Center(child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.people_outline_rounded, size: 80, color: AppColors.textHint),
                const SizedBox(height: 16),
                Text('لا يوجد مرضى حتى الآن', style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textHint)),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => context.go('/doctor/patients/add'),
                  icon: const Icon(Icons.person_add_rounded),
                  label: const Text('إضافة أول مريض'),
                ),
              ],
            ));
          }
          if (state is PatientsLoaded) {
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.patients.length,
              itemBuilder: (context, i) => PatientListTile(
                patient: state.patients[i],
                onTap: () => context.go('/doctor/patients/${state.patients[i].id}'),
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/doctor/patients/add'),
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('إضافة مريض'),
      ),
    );
  }
}
