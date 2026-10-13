import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/patient_model.dart';

class PatientListTile extends StatelessWidget {
  final PatientModel patient;
  final VoidCallback onTap;
  const PatientListTile({super.key, required this.patient, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final recovered = patient.treatmentStatus == TreatmentStatus.recovered;
    final name = patient.fullName.trim();
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(children: [
            CircleAvatar(
              radius: 25,
              backgroundColor: AppColors.primaryContainer,
              foregroundImage: patient.avatarUrl == null || patient.avatarUrl!.isEmpty
                  ? null : NetworkImage(patient.avatarUrl!),
              child: Text(name.isEmpty ? 'ط' : name.substring(0, 1),
                style: AppTextStyles.titleMedium.copyWith(color: AppColors.primaryDark)),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name.isEmpty ? 'طفل' : name,
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.titleSmall),
                const SizedBox(height: 5),
                Text('${patient.ageDisplay}  •  ${patient.guardianName}',
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodySmall),
                if (patient.nextVisitDate != null) ...[
                  const SizedBox(height: 4),
                  Text('المراجعة القادمة: ${patient.nextVisitDate!.day}/${patient.nextVisitDate!.month}/${patient.nextVisitDate!.year}',
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.labelSmall.copyWith(color: AppColors.primary)),
                ],
              ],
            )),
            const SizedBox(width: 6),
            Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: (recovered ? AppColors.success : AppColors.info).withValues(alpha: 0.11),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(recovered ? 'متعافٍ' : 'متابعة',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: recovered ? AppColors.success : AppColors.info)),
              ),
              const SizedBox(height: 6),
              const Icon(Icons.chevron_left_rounded, size: 18, color: AppColors.textHint),
            ]),
          ]),
        ),
      ),
    );
  }
}
