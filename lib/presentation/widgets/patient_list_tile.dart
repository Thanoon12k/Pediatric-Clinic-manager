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
    final isRecovered = patient.treatmentStatus == TreatmentStatus.recovered;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.7),
                      AppColors.primaryLight,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: patient.avatarUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.network(patient.avatarUrl!, fit: BoxFit.cover))
                    : Center(
                        child: Text(
                          patient.fullName[0],
                          style: AppTextStyles.headlineSmall.copyWith(color: Colors.white),
                        ),
                      ),
              ),
              const SizedBox(width: 14),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(patient.fullName, style: AppTextStyles.titleSmall),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          patient.gender == Gender.male
                              ? Icons.male_rounded
                              : Icons.female_rounded,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(patient.ageDisplay, style: AppTextStyles.bodySmall),
                        if (patient.bloodType != null) ...[
                          const SizedBox(width: 8),
                          const Text('•', style: TextStyle(color: AppColors.textHint)),
                          const SizedBox(width: 8),
                          Text(patient.bloodType!, style: AppTextStyles.bodySmall),
                        ],
                      ],
                    ),
                    if (patient.nextVisitDate != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.event_rounded, size: 12, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text(
                            'المراجعة القادمة: ${_formatDate(patient.nextVisitDate!)}',
                            style: AppTextStyles.labelSmall.copyWith(color: AppColors.primary),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Status badge
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isRecovered
                          ? AppColors.success.withValues(alpha: 0.1)
                          : AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isRecovered ? 'بصحة جيدة' : 'قيد العلاج',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: isRecovered ? AppColors.success : AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Icon(Icons.chevron_right_rounded, color: AppColors.textHint),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
