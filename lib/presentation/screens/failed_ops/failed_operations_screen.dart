import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/constants/app_constants.dart';

class FailedOperationsScreen extends StatefulWidget {
  const FailedOperationsScreen({super.key});
  @override State<FailedOperationsScreen> createState() => _FailedOperationsScreenState();
}

class _FailedOperationsScreenState extends State<FailedOperationsScreen> {
  late Box _box;
  List<Map<dynamic, dynamic>> _ops = [];

  @override
  void initState() {
    super.initState();
    _box = Hive.box(AppConstants.boxOfflineQueue);
    _loadOps();
  }

  void _loadOps() {
    final raw = _box.values.toList();
    setState(() => _ops = raw.cast<Map<dynamic, dynamic>>());
  }

  void _retry(int index) async {
    final op = _ops[index];
    // In a real app: call the appropriate repository method
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('جاري إعادة المحاولة: ${op['type'] ?? 'عملية'}'), backgroundColor: AppColors.primary),
    );
    await Future.delayed(const Duration(seconds: 1));
    _box.deleteAt(index);
    _loadOps();
  }

  void _delete(int index) {
    _box.deleteAt(index);
    _loadOps();
  }

  void _clearAll() {
    showDialog(context: context, builder: (_) => AlertDialog(
      title: const Text('مسح الكل'),
      content: const Text('هل تريد مسح جميع العمليات المعلقة؟'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
          onPressed: () { Navigator.pop(context); _box.clear(); _loadOps(); },
          child: const Text('مسح الكل'),
        ),
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('العمليات المعلقة'),
        actions: [
          if (_ops.isNotEmpty)
            TextButton(onPressed: _clearAll, child: const Text('مسح الكل', style: TextStyle(color: Colors.white))),
        ],
      ),
      body: _ops.isEmpty
          ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.check_circle_outline_rounded, size: 80, color: AppColors.success),
              const SizedBox(height: 16),
              Text('لا توجد عمليات معلقة', style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              Text('جميع العمليات تمت بنجاح', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textHint)),
            ]))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _ops.length,
              itemBuilder: (context, i) {
                final op = _ops[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        const CircleAvatar(backgroundColor: Color(0xFFFFE5E5), child: Icon(Icons.error_outline_rounded, color: AppColors.error)),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(op['type'] as String? ?? 'عملية غير معروفة', style: AppTextStyles.titleSmall),
                          Text(op['timestamp'] as String? ?? '', style: AppTextStyles.bodySmall),
                        ])),
                      ]),
                      if (op['error'] != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8)),
                          child: Text(op['error'].toString(), style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(child: OutlinedButton.icon(
                          onPressed: () => _retry(i),
                          icon: const Icon(Icons.refresh_rounded, size: 16),
                          label: const Text('إعادة المحاولة'),
                        )),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: () => _delete(i),
                          style: OutlinedButton.styleFrom(foregroundColor: AppColors.error, side: const BorderSide(color: AppColors.error)),
                          child: const Text('حذف'),
                        ),
                      ]),
                    ]),
                  ),
                ).animate(delay: Duration(milliseconds: i * 60)).fadeIn().slideY(begin: 0.2);
              },
            ),
    );
  }
}
