import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../providers/auth/auth_provider.dart';

/// Both doctors and secretaries use this screen. All permissions are enforced
/// by Supabase RLS and narrowly-scoped SECURITY DEFINER RPCs, not this widget.
class ClinicQueueScreen extends ConsumerStatefulWidget {
  const ClinicQueueScreen({super.key});

  @override
  ConsumerState<ClinicQueueScreen> createState() => _ClinicQueueScreenState();
}

class _ClinicQueueScreenState extends ConsumerState<ClinicQueueScreen> {
  final _nameController = TextEditingController();
  final _client = Supabase.instance.client;
  DateTime get _today => DateTime.now();

  List<Map<String, dynamic>> _queue = [];
  String? _doctorId;
  String _doctorName = '';
  String _accountRole = '';
  String? _error;
  bool _loading = true;
  bool _busy = false;

  String get _day => '${_today.year.toString().padLeft(4, '0')}-'
      '${_today.month.toString().padLeft(2, '0')}-'
      '${_today.day.toString().padLeft(2, '0')}';

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final rawContext = await _client.rpc('clinic_queue_context');
      final matches = rawContext as List<dynamic>;
      if (matches.isEmpty) {
        throw StateError('حسابك غير مرتبط بطبيب فعّال، أو ليست لديك صلاحية إدارة الطابور.');
      }
      final assignment = Map<String, dynamic>.from(matches.first as Map);
      final doctorId = assignment['doctor_id'] as String;

      final rows = await _client
          .from('clinic_queue')
          .select('id,doctor_id,visit_date,patient_name,token_number,sort_order,status')
          .eq('doctor_id', doctorId)
          .eq('visit_date', _day)
          .order('sort_order')
          .order('token_number');

      if (!mounted) return;
      setState(() {
        _doctorId = doctorId;
        _doctorName = assignment['doctor_name'] as String? ?? '';
        _accountRole = assignment['account_role'] as String? ?? '';
        _queue = (rows as List<dynamic>)
            .map((row) => Map<String, dynamic>.from(row as Map))
            .toList();
      });
    } catch (error) {
      if (mounted) setState(() => _error = _friendlyError(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _friendlyError(Object error) {
    if (error is PostgrestException) {
      if (error.code == 'PGRST202' || error.code == '42883') {
        return 'لم يتم تثبيت تحديث قاعدة البيانات رقم 003 بعد. اطلب من مسؤول العيادة تطبيقه أولاً.';
      }
      if (error.code == '23505') {
        return 'يوجد مريض داخل عند الطبيب حالياً، أنهِ زيارته أولاً.';
      }
      if (error.code == '42501') {
        return 'ليس لديك صلاحية إدارة طابور هذا الطبيب.';
      }
      return 'تعذّر تحميل الطابور. تحقق من الاتصال وصلاحية الحساب. (${error.code ?? ''})';
    }
    if (error is StateError) return error.message;
    return 'تعذّر الاتصال. تحقق من الإنترنت وحاول مجدداً.';
  }

  Future<void> _perform(Future<void> Function() action, String success) async {
    if (_busy || _doctorId == null) return;
    setState(() => _busy = true);
    try {
      await action();
      if (!mounted) return;
      _nameController.clear();
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(success)));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_friendlyError(error))),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _addPatient() async {
    final name = _nameController.text.trim();
    if (name.isEmpty || name.length > 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اكتب اسم المريض من 1 إلى 100 حرف.')),
      );
      return;
    }
    await _perform(
      () async {
        await _client.rpc('add_clinic_queue_patient', params: {
          'p_doctor_id': _doctorId,
          'p_patient_name': name,
        });
      },
      'تمت إضافة المريض إلى طابور اليوم',
    );
  }

  Future<void> _changeStatus(String queueId, String status) => _perform(
    () async {
      await _client.rpc('set_clinic_queue_status', params: {
        'p_queue_id': queueId,
        'p_status': status,
      });
    },
    'تم تحديث حالة المريض',
  );

  Future<void> _move(List<Map<String, dynamic>> waiting, int from, int to) async {
    if (to < 0 || to >= waiting.length) return;
    final ids = waiting.map((row) => row['id'] as String).toList();
    final item = ids.removeAt(from);
    ids.insert(to, item);
    await _perform(
      () async {
        await _client.rpc('reorder_clinic_queue', params: {
          'p_doctor_id': _doctorId,
          'p_ordered_ids': ids,
        });
      },
      'تم تعديل ترتيب الطابور',
    );
  }

  Future<void> _logout() async {
    await ref.read(authProvider.notifier).logout();
    if (mounted) context.go(AppConstants.routeWelcome);
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'waiting': return 'بانتظار الدور';
      case 'in_progress': return 'داخل عند الطبيب';
      case 'completed': return 'اكتمل';
      case 'cancelled': return 'ملغي';
      default: return status;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'in_progress': return AppColors.info;
      case 'completed': return AppColors.success;
      case 'cancelled': return AppColors.error;
      default: return AppColors.warning;
    }
  }

  List<(String, String)> _statusActions(String status) {
    switch (status) {
      case 'waiting':
        return [('in_progress', 'إدخال عند الطبيب'), ('cancelled', 'إلغاء الدور')];
      case 'in_progress':
        return [('completed', 'إنهاء الزيارة'), ('waiting', 'إرجاع للانتظار'),
          ('cancelled', 'إلغاء الدور')];
      case 'cancelled':
        return [('waiting', 'إرجاع إلى الطابور')];
      default:
        return [];
    }
  }

  Widget _stat(String title, int count, IconData icon, Color color) {
    return Expanded(
      child: Card(
        elevation: 0,
        color: color.withValues(alpha: 0.07),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          child: Column(children: [
            Icon(icon, color: color),
            const SizedBox(height: 5),
            Text('$count', style: TextStyle(
              fontSize: 24, fontWeight: FontWeight.w800, color: color,
            )),
            Text(title, textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12)),
          ]),
        ),
      ),
    );
  }

  Widget _queueItem(
    Map<String, dynamic> item,
    List<Map<String, dynamic>> waiting,
    int index,
  ) {
    final status = item['status'] as String;
    final statusColor = _statusColor(status);
    final isWaiting = status == 'waiting';

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(children: [
          CircleAvatar(
            backgroundColor: AppColors.primaryContainer,
            child: Text('${item['token_number']}',
              style: const TextStyle(color: AppColors.primaryDark,
                fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item['patient_name'] as String,
                maxLines: 2, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(_statusLabel(status),
                style: TextStyle(color: statusColor, fontSize: 12)),
            ],
          )),
          if (isWaiting) ...[
            IconButton(
              tooltip: 'تقديم الدور',
              onPressed: _busy || index == 0
                  ? null : () => _move(waiting, index, index - 1),
              icon: const Icon(Icons.keyboard_arrow_up_rounded),
            ),
            IconButton(
              tooltip: 'تأخير الدور',
              onPressed: _busy || index == waiting.length - 1
                  ? null : () => _move(waiting, index, index + 1),
              icon: const Icon(Icons.keyboard_arrow_down_rounded),
            ),
          ],
          PopupMenuButton<String>(
            tooltip: 'تغيير الحالة',
            enabled: !_busy && _statusActions(status).isNotEmpty,
            onSelected: (value) => _changeStatus(item['id'] as String, value),
            itemBuilder: (_) => [
              for (final action in _statusActions(status))
                PopupMenuItem(value: action.$1, child: Text(action.$2)),
            ],
            icon: const Icon(Icons.more_vert_rounded),
          ),
        ]),
      ),
    );
  }

  Widget _section(String label, List<Map<String, dynamic>> entries,
      {bool sortable = false}) {
    if (entries.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 22),
        Text('$label (${entries.length})',
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        for (var i = 0; i < entries.length; i++)
          _queueItem(entries[i], sortable ? entries : const [], i),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final waiting = _queue.where((q) => q['status'] == 'waiting').toList()
      ..sort((a, b) => (a['sort_order'] as int).compareTo(b['sort_order'] as int));
    final current = _queue.where((q) => q['status'] == 'in_progress').toList();
    final done = _queue.where((q) => q['status'] == 'completed').toList();
    final cancelled = _queue.where((q) => q['status'] == 'cancelled').toList();
    final secretary = _accountRole == 'secretary';

    return Scaffold(
      appBar: AppBar(
        title: Text(secretary ? 'استقبال العيادة' : 'طابور المرضى'),
        actions: [
          IconButton(tooltip: 'تحديث', onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh_rounded)),
          if (secretary) IconButton(tooltip: 'تسجيل الخروج',
            onPressed: _logout, icon: const Icon(Icons.logout_rounded)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.lock_outline_rounded,
                        color: AppColors.warning, size: 48),
                      const SizedBox(height: 12),
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 18),
                      ElevatedButton(onPressed: _load, child: const Text('إعادة المحاولة')),
                    ]),
                  ),
                ))
              : Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 860),
                    child: RefreshIndicator(
                      onRefresh: _load,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 18, 16, 36),
                        children: [
                          Text('طابور د. $_doctorName',
                            style: Theme.of(context).textTheme.headlineSmall),
                          const SizedBox(height: 4),
                          Text('اليوم: $_day  •  ${secretary ? 'حساب سكرتير' : 'حساب طبيب'}',
                            style: const TextStyle(color: AppColors.textSecondary)),
                          const SizedBox(height: 14),
                          Row(children: [
                            _stat('بالانتظار', waiting.length,
                              Icons.hourglass_top_rounded, AppColors.warning),
                            _stat('عند الطبيب', current.length,
                              Icons.medical_services_outlined, AppColors.info),
                            _stat('مكتمل', done.length,
                              Icons.check_circle_outline_rounded, AppColors.success),
                          ]),
                          const SizedBox(height: 14),
                          Card(
                            elevation: 0,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('إضافة اسم إلى الطابور',
                                    style: TextStyle(fontSize: 16,
                                      fontWeight: FontWeight.w700)),
                                  const SizedBox(height: 10),
                                  TextField(
                                    controller: _nameController,
                                    maxLength: 100,
                                    textInputAction: TextInputAction.done,
                                    onSubmitted: (_) {
                                      if (!_busy) _addPatient();
                                    },
                                    decoration: const InputDecoration(
                                      labelText: 'اسم المريض',
                                      prefixIcon: Icon(Icons.person_add_alt_1_outlined),
                                    ),
                                  ),
                                  SizedBox(
                                    width: double.infinity,
                                    child: FilledButton.icon(
                                      onPressed: _busy ? null : _addPatient,
                                      icon: const Icon(Icons.add_rounded),
                                      label: const Text('إضافة إلى طابور اليوم'),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text('هذه إضافة للطابور فقط، ولا تنشئ ملفاً طبياً.',
                                    style: TextStyle(fontSize: 12,
                                      color: AppColors.textSecondary)),
                                ],
                              ),
                            ),
                          ),
                          _section('داخل عند الطبيب', current),
                          _section('بانتظار الدور', waiting, sortable: true),
                          _section('زيارات مكتملة', done),
                          _section('أدوار ملغية', cancelled),
                          if (_queue.isEmpty) const Padding(
                            padding: EdgeInsets.symmetric(vertical: 46),
                            child: Column(children: [
                              Icon(Icons.event_available_outlined,
                                size: 54, color: AppColors.primaryLight),
                              SizedBox(height: 12),
                              Text('لا يوجد مرضى في طابور اليوم',
                                textAlign: TextAlign.center),
                            ]),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }
}
