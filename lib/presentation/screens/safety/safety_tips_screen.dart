import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class SafetyTipsScreen extends StatelessWidget {
  const SafetyTipsScreen({super.key});

  // Use a non-const list to avoid const issues with Color arguments
  static List<_TipData> get _tips => [
    _TipData(icon: Icons.vaccines_rounded, color: const Color(0xFF0077B6),
        title: 'التحصينات في الوقت المحدد', body: 'احرص على أخذ طفلك لمواعيد التطعيم ضمن الجدول المعتمد. التطعيم يحمي طفلك من أمراض خطيرة وقابلة للوقاية.'),
    _TipData(icon: Icons.local_hospital_rounded, color: const Color(0xFF00B4D8),
        title: 'متابعة النمو الدورية', body: 'راجع طبيب الأطفال بشكل منتظم لمتابعة نمو طفلك وكشف أي مشكلة مبكراً. قياس الوزن والطول يعكسان صحة الطفل.'),
    _TipData(icon: Icons.no_food_rounded, color: const Color(0xFFE63946),
        title: 'الحذر من الاختناق', body: 'لا تعطِ الأطفال دون 3 سنوات الأطعمة الصلبة الصغيرة (مكسرات، عنب). كن دائماً قريباً عند الأكل.'),
    _TipData(icon: Icons.water_rounded, color: const Color(0xFF48CAE4),
        title: 'الوقاية من الغرق', body: 'لا تترك طفلك أبداً وحيداً بالقرب من الماء ولو لثوانٍ. ضع سواتر حول أحواض السباحة والبرك.'),
    _TipData(icon: Icons.security_rounded, color: const Color(0xFF2EC4B6),
        title: 'سلامة أثناء النوم', body: 'ضع الرضيع على ظهره دائماً، في سرير صلب خالٍ من الوسائد والبطانيات. تجنب النوم المشترك مع الرضع.'),
    _TipData(icon: Icons.directions_car_rounded, color: const Color(0xFFFF9F1C),
        title: 'مقعد السيارة', body: 'استخدم مقعد أمان مناسب لعمر طفلك وتأكد من تثبيته بشكل صحيح في كل رحلة مهما كانت قصيرة.'),
    _TipData(icon: Icons.coronavirus_rounded, color: const Color(0xFF9B2226),
        title: 'النظافة والحماية من العدوى', body: 'علّم طفلك غسل اليدين بانتظام بالماء والصابون لمدة 20 ثانية. ابقِ الأطفال المرضى في المنزل لمنع انتشار العدوى.'),
    _TipData(icon: Icons.wb_sunny_rounded, color: const Color(0xFFFFB703),
        title: 'الحماية من أشعة الشمس', body: 'استخدم واقي شمس مناسب للأطفال، وأبعد الرضّع عن الشمس المباشرة. احرص على ارتداء القبعات في الأجواء الحارة.'),
    _TipData(icon: Icons.food_bank_rounded, color: const Color(0xFF52B788),
        title: 'التغذية السليمة', body: 'الرضاعة الطبيعية هي الأفضل للرضع لأول 6 أشهر. اعرض على طفلك مجموعة متنوعة من الخضروات والفواكه والحبوب.'),
    _TipData(icon: Icons.phone_android_rounded, color: const Color(0xFF6D6875),
        title: 'تقليل وقت الشاشات', body: 'لا يُوصى بالشاشات لمن هم دون سنتين. قيّد وقت الشاشة للأكبر وتأكد من محتوى تعليمي مناسب للعمر.'),
  ];

  @override
  Widget build(BuildContext context) {
    final tips = _tips;
    return Scaffold(
      appBar: AppBar(title: const Text('نصائح سلامة الأطفال')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: tips.length,
        itemBuilder: (context, i) => _TipCard(tip: tips[i])
            .animate(delay: Duration(milliseconds: i * 60))
            .fadeIn(duration: 400.ms)
            .slideY(begin: 0.2, end: 0),
      ),
    );
  }
}

class _TipData {
  final IconData icon; final Color color; final String title, body;
  const _TipData({required this.icon, required this.color, required this.title, required this.body});
}

class _TipCard extends StatefulWidget {
  final _TipData tip;
  const _TipCard({required this.tip});
  @override State<_TipCard> createState() => _TipCardState();
}

class _TipCardState extends State<_TipCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => setState(() => _expanded = !_expanded),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              CircleAvatar(
                backgroundColor: widget.tip.color.withValues(alpha: 0.1),
                child: Icon(widget.tip.icon, color: widget.tip.color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(widget.tip.title, style: AppTextStyles.titleSmall)),
              Icon(_expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded, color: AppColors.textSecondary),
            ]),
            if (_expanded) ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Text(widget.tip.body, style: AppTextStyles.bodyMedium.copyWith(height: 1.6)),
            ],
          ]),
        ),
      ),
    );
  }
}
