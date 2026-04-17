import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/examination_model.dart';
import '../../blocs/examination/examination_bloc.dart';

class ChartsScreen extends StatefulWidget {
  final String patientId;
  const ChartsScreen({super.key, required this.patientId});
  @override State<ChartsScreen> createState() => _ChartsScreenState();
}

class _ChartsScreenState extends State<ChartsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    context.read<ExaminationBloc>().add(LoadGrowthRecords(widget.patientId));
  }

  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الرسوم البيانية'),
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: Colors.white,
          tabs: const [Tab(text: 'الوزن'), Tab(text: 'الطول'), Tab(text: 'الفحوصات')],
        ),
      ),
      body: BlocBuilder<ExaminationBloc, ExaminationState>(
        builder: (context, state) {
          if (state is ExaminationLoading) return const Center(child: CircularProgressIndicator());
          if (state is GrowthRecordsLoaded) {
            return TabBarView(
              controller: _tabCtrl,
              children: [
                _WeightChart(records: state.records),
                _HeightChart(records: state.records),
                _ExaminationHistoryView(patientId: widget.patientId),
              ],
            );
          }
          return const Center(child: Text('لا توجد بيانات بعد'));
        },
      ),
    );
  }
}

class _WeightChart extends StatelessWidget {
  final List<GrowthRecordModel> records;
  const _WeightChart({required this.records});

  @override
  Widget build(BuildContext context) {
    final weightData = records.where((r) => r.weight != null).toList();
    if (weightData.isEmpty) return _noDataWidget('لا توجد بيانات وزن مسجلة');

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('منحنى الوزن', style: AppTextStyles.titleLarge),
          const SizedBox(height: 8),
          Text('${weightData.last.weight} كغ — آخر قراءة', style: AppTextStyles.bodyLarge.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (v) => FlLine(color: AppColors.divider, strokeWidth: 1)),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30, getTitlesWidget: (v, _) {
                    final i = v.toInt();
                    if (i < 0 || i >= weightData.length) return const SizedBox.shrink();
                    return Text('${weightData[i].recordDate.month}/${weightData[i].recordDate.year % 100}', style: AppTextStyles.labelSmall);
                  })),
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40, getTitlesWidget: (v, _) => Text('${v.toStringAsFixed(0)} كغ', style: AppTextStyles.labelSmall))),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: weightData.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.weight!)).toList(),
                    isCurved: true,
                    color: AppColors.primary,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: true, getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(radius: 5, color: AppColors.primary, strokeWidth: 2, strokeColor: Colors.white)),
                    belowBarData: BarAreaData(show: true, color: AppColors.primary.withValues(alpha: 0.08)),
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(duration: 600.ms),
        ],
      ),
    );
  }
}

class _HeightChart extends StatelessWidget {
  final List<GrowthRecordModel> records;
  const _HeightChart({required this.records});

  @override
  Widget build(BuildContext context) {
    final heightData = records.where((r) => r.height != null).toList();
    if (heightData.isEmpty) return _noDataWidget('لا توجد بيانات طول مسجلة');

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('منحنى الطول', style: AppTextStyles.titleLarge),
          const SizedBox(height: 8),
          Text('${heightData.last.height} سم — آخر قراءة', style: AppTextStyles.bodyLarge.copyWith(color: AppColors.secondary, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true, drawVerticalLine: false),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30,
                    getTitlesWidget: (v, _) {
                      final i = v.toInt();
                      if (i < 0 || i >= heightData.length) return const SizedBox.shrink();
                      return Text('${heightData[i].recordDate.month}/${heightData[i].recordDate.year % 100}', style: AppTextStyles.labelSmall);
                    }
                  )),
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 45,
                    getTitlesWidget: (v, _) => Text('${v.toStringAsFixed(0)} سم', style: AppTextStyles.labelSmall)
                  )),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: heightData.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.height!)).toList(),
                    isCurved: true,
                    color: AppColors.secondary,
                    barWidth: 3,
                    dotData: FlDotData(show: true),
                    belowBarData: BarAreaData(show: true, color: AppColors.secondary.withValues(alpha: 0.08)),
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(duration: 600.ms),
        ],
      ),
    );
  }
}

class _ExaminationHistoryView extends StatelessWidget {
  final String patientId;
  const _ExaminationHistoryView({required this.patientId});
  @override
  Widget build(BuildContext context) {
    return const Center(child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.history_rounded, size: 64, color: AppColors.textHint),
        SizedBox(height: 16),
        Text('سجل الفحوصات متاح من شاشة الفحوصات', style: TextStyle(color: AppColors.textSecondary)),
      ],
    ));
  }
}

Widget _noDataWidget(String msg) => Center(child: Column(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    const Icon(Icons.bar_chart_rounded, size: 64, color: AppColors.textHint),
    const SizedBox(height: 16),
    Text(msg, style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textHint)),
  ],
));
