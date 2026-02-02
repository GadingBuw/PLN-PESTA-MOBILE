import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; 
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  String selectedMonth = DateFormat('MM').format(DateTime.now());
  String selectedYear = DateFormat('yyyy').format(DateTime.now());
  bool isGenerating = false;

  final supabase = Supabase.instance.client;
  final Color primaryBlue = const Color(0xFF1A56F0);
  final Color bgGrey = const Color(0xFFF0F2F5);

  final List<Map<String, String>> months = [
    {"value": "01", "label": "Januari"},
    {"value": "02", "label": "Februari"},
    {"value": "03", "label": "Maret"},
    {"value": "04", "label": "April"},
    {"value": "05", "label": "Mei"},
    {"value": "06", "label": "Juni"},
    {"value": "07", "label": "Juli"},
    {"value": "08", "label": "Agustus"},
    {"value": "09", "label": "September"},
    {"value": "10", "label": "Oktober"},
    {"value": "11", "label": "November"},
    {"value": "12", "label": "Desember"},
  ];

  final List<String> years = ["2024", "2025", "2026", "2027"];

  Future<void> _generatePdf() async {
    setState(() => isGenerating = true);
    try {
      // 1. Tentukan rentang tanggal awal dan akhir secara dinamis
      final int year = int.parse(selectedYear);
      final int month = int.parse(selectedMonth);
      
      final String startDate = "$selectedYear-$selectedMonth-01";
      
      // Menggunakan DateTime untuk mencari hari terakhir bulan tersebut secara otomatis
      final DateTime lastDayDateTime = DateTime(year, month + 1, 0);
      final String endDate = DateFormat('yyyy-MM-dd').format(lastDayDateTime);

      // 2. Query ke Supabase
      final response = await supabase
          .from('pesta_tasks')
          .select()
          .gte('tgl_pasang', startDate)
          .lte('tgl_pasang', endDate)
          .order('tgl_pasang', ascending: true);

      final List<dynamic> data = response as List<dynamic>;

      if (data.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Data tidak ditemukan pada periode ini"), backgroundColor: Colors.orange),
          );
        }
        setState(() => isGenerating = false);
        return;
      }

      // 3. Logika Generate PDF
      String monthLabel = months.firstWhere((m) => m['value'] == selectedMonth)['label']!;
      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(30),
          header: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text("PT PLN (PERSERO) - ULP PACITAN", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
              pw.Text("LAPORAN BULANAN PENUGASAN PESTA", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
              pw.Text("Periode: $monthLabel / $selectedYear", style: pw.TextStyle(fontSize: 9)),
              pw.SizedBox(height: 5),
              pw.Divider(thickness: 1),
              pw.SizedBox(height: 8),
            ],
          ),
          build: (pw.Context context) => [
            pw.TableHelper.fromTextArray(
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blue800),
              cellStyle: const pw.TextStyle(fontSize: 7.5),
              headers: ['No', 'Agenda', 'Nama Pelanggan', 'Alamat', 'Daya', 'Pasang', 'Bongkar', 'Teknisi', 'Status'],
              data: List<List<dynamic>>.generate(
                data.length,
                (index) => [
                  index + 1,
                  data[index]['no_agenda'] ?? "-",
                  data[index]['nama_pelanggan'] ?? "-",
                  data[index]['alamat'] ?? "-",
                  "${data[index]['daya'] ?? '0'} VA",
                  data[index]['tgl_pasang'] ?? "-",
                  data[index]['tgl_bongkar'] ?? "-",
                  data[index]['teknisi'] ?? "-",
                  data[index]['status'] ?? "-",
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text("Pacitan, ${DateFormat('dd MMMM yyyy', 'id_ID').format(DateTime.now())}", style: pw.TextStyle(fontSize: 9)),
                    pw.Text("Admin PESTA Mobile", style: pw.TextStyle(fontSize: 9)),
                    pw.SizedBox(height: 40),
                    pw.Container(width: 130, decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(width: 1)))),
                    pw.SizedBox(height: 2),
                    pw.Text("PLN ULP PACITAN", style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ],
        ),
      );

      await Printing.layoutPdf(
        onLayout: (format) async => pdf.save(),
        name: 'Laporan_${monthLabel}_$selectedYear.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal Generate Laporan: $e"), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgGrey,
      appBar: AppBar(
        title: const Text("Cetak Laporan PDF", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE0E4E8))),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), shape: BoxShape.circle),
                    child: const Icon(Icons.picture_as_pdf_rounded, size: 40, color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  const Text("Pilih Periode Laporan", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(height: 4),
                  const Text("Laporan akan di-generate dalam format PDF landscape", textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE0E4E8))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel("Pilih Bulan"),
                  DropdownButtonFormField<String>(
                    value: selectedMonth,
                    decoration: _inputDecoration("Bulan"),
                    items: months.map((m) => DropdownMenuItem(value: m['value'], child: Text(m['label']!))).toList(),
                    onChanged: (v) => setState(() => selectedMonth = v!),
                  ),
                  const SizedBox(height: 20),
                  _buildLabel("Pilih Tahun"),
                  DropdownButtonFormField<String>(
                    value: selectedYear,
                    decoration: _inputDecoration("Tahun"),
                    items: years.map((y) => DropdownMenuItem(value: y, child: Text("Tahun $y"))).toList(),
                    onChanged: (v) => setState(() => selectedYear = v!),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity, height: 56,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: primaryBlue, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
                onPressed: isGenerating ? null : _generatePdf,
                icon: isGenerating 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                    : const Icon(Icons.print_rounded),
                label: Text(isGenerating ? "PROSES..." : "GENERATE PDF", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black54)));
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint, filled: true, fillColor: const Color(0xFFF8F9FA),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE0E4E8))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: primaryBlue, width: 1.5)),
    );
  }
}