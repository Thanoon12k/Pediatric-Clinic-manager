import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../blocs/patient/patient_bloc.dart';
import '../../../data/models/patient_model.dart';

class PdfReportScreen extends StatefulWidget {
  final String patientId;
  const PdfReportScreen({super.key, required this.patientId});
  @override State<PdfReportScreen> createState() => _PdfReportScreenState();
}

class _PdfReportScreenState extends State<PdfReportScreen> {
  @override
  void initState() {
    super.initState();
    context.read<PatientBloc>().add(LoadPatientById(widget.patientId));
  }

  Future<pw.Document> _buildPdf(PatientModel patient) async {
    final doc = pw.Document();
    final arabicFont = await PdfGoogleFonts.cairoRegular();
    final arabicFontBold = await PdfGoogleFonts.cairoBold();

    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      textDirection: pw.TextDirection.rtl,
      theme: pw.ThemeData.withFont(base: arabicFont, bold: arabicFontBold),
      header: (ctx) => pw.Container(
        padding: const pw.EdgeInsets.only(bottom: 12),
        decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.blueGrey200))),
        child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
          pw.Text('عيادتي — تقرير المريض', style: pw.TextStyle(font: arabicFontBold, fontSize: 14, color: PdfColor.fromHex('#0077B6'))),
          pw.Text('تاريخ الطباعة: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}', style: pw.TextStyle(font: arabicFont, fontSize: 10, color: PdfColors.grey600)),
        ]),
      ),
      build: (ctx) => [
        pw.SizedBox(height: 20),
        pw.Text(patient.fullName, style: pw.TextStyle(font: arabicFontBold, fontSize: 22)),
        pw.SizedBox(height: 4),
        pw.Text('${patient.ageDisplay} • ${patient.gender == Gender.male ? 'ذكر' : 'أنثى'}', style: pw.TextStyle(font: arabicFont, fontSize: 12, color: PdfColors.grey600)),
        pw.SizedBox(height: 20),
        _pdfSection('البيانات الشخصية', [
          _pdfRow('فصيلة الدم', patient.bloodType ?? '—', arabicFont),
          _pdfRow('الوزن', patient.weight != null ? '${patient.weight} كغ' : '—', arabicFont),
          _pdfRow('الطول', patient.height != null ? '${patient.height} سم' : '—', arabicFont),
          _pdfRow('تاريخ الميلاد', '${patient.dateOfBirth.day}/${patient.dateOfBirth.month}/${patient.dateOfBirth.year}', arabicFont),
        ], arabicFontBold),
        pw.SizedBox(height: 16),
        _pdfSection('ولي الأمر', [
          _pdfRow('الاسم', patient.guardianName, arabicFont),
          _pdfRow('الهاتف', patient.guardianPhone, arabicFont),
          if (patient.address != null) _pdfRow('العنوان', patient.address!, arabicFont),
        ], arabicFontBold),
        if (patient.allergies != null || patient.chronicDiseases != null) ...[
          pw.SizedBox(height: 16),
          _pdfSection('الحالة الصحية', [
            if (patient.allergies != null) _pdfRow('الحساسية', patient.allergies!, arabicFont),
            if (patient.chronicDiseases != null) _pdfRow('أمراض مزمنة', patient.chronicDiseases!, arabicFont),
          ], arabicFontBold),
        ],
        if (patient.notes != null) ...[
          pw.SizedBox(height: 16),
          _pdfSection('ملاحظات الطبيب', [
            pw.Text(patient.notes!, style: pw.TextStyle(font: arabicFont, fontSize: 11)),
          ], arabicFontBold),
        ],
      ],
    ));
    return doc;
  }

  pw.Widget _pdfSection(String title, List<pw.Widget> children, pw.Font boldFont) {
    return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: pw.BoxDecoration(color: PdfColor.fromHex('#E8F4FD'), borderRadius: pw.BorderRadius.circular(6)),
        child: pw.Text(title, style: pw.TextStyle(font: boldFont, fontSize: 12, color: PdfColor.fromHex('#0077B6'))),
      ),
      pw.SizedBox(height: 8),
      ...children,
    ]);
  }

  pw.Widget _pdfRow(String label, String value, pw.Font font) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(children: [
        pw.SizedBox(width: 120, child: pw.Text(label, style: pw.TextStyle(font: font, fontSize: 11, color: PdfColors.grey600))),
        pw.Text(value, style: pw.TextStyle(font: font, fontSize: 11)),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تقرير المريض PDF')),
      body: BlocBuilder<PatientBloc, PatientState>(
        builder: (context, state) {
          if (state is PatientLoading) return const Center(child: CircularProgressIndicator());
          if (state is PatientLoaded) {
            return PdfPreview(
              build: (format) async => (await _buildPdf(state.patient)).save(),
              pdfFileName: 'تقرير_${state.patient.fullName}.pdf',
              allowPrinting: true,
              allowSharing: true,
              canChangeOrientation: false,
              canChangePageFormat: false,
            );
          }
          return const Center(child: Text('تعذر تحميل بيانات المريض'));
        },
      ),
    );
  }
}
