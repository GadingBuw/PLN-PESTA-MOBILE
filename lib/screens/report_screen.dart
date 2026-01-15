import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../main.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  String selectedMonth = DateFormat('MM').format(DateTime.now());
  String selectedYear = DateFormat('yyyy').format(DateTime.now());
  bool isGenerating = false;

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
      final response = await http.get(
        Uri.parse(
          "$baseUrl?action=get_report&bulan=$selectedMonth&tahun=$selectedYear",
        ),
      );

      if (response.body.isEmpty || response.statusCode != 200)
        throw "Error koneksi/data.";

      List<dynamic> data = jsonDecode(response.body);
      if (data.isEmpty) {
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Data tidak ditemukan pada periode ini"),
            ),
          );
        setState(() => isGenerating = false);
        return;
      }

      String monthLabel = months.firstWhere(
        (m) => m['value'] == selectedMonth,
      )['label']!;
      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(30),
          build: (pw.Context context) {
            return [
              pw.Text(
                "PT PLN (PERSERO) - ULP PACITAN",
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              pw.Text(
                "LAPORAN BULANAN PENUGASAN PESTA",
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 10,
                ),
              ),
              pw.Text(
                "Periode: $monthLabel / $selectedYear",
                style: pw.TextStyle(fontSize: 9),
              ),
              pw.SizedBox(height: 5),
              pw.Divider(thickness: 1),
              pw.SizedBox(height: 8),
              pw.TableHelper.fromTextArray(
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 8,
                  color: PdfColors.white,
                ),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.blue800,
                ),
                cellStyle: const pw.TextStyle(fontSize: 7.5),
                headers: [
                  'No',
                  'ID Pel',
                  'Nama Pelanggan',
                  'Alamat',
                  'Daya',
                  'Pasang',
                  'Bongkar',
                  'Teknisi',
                  'Status',
                ],
                data: List<List<dynamic>>.generate(
                  data.length,
                  (index) => [
                    index + 1,
                    data[index]['id_pelanggan'],
                    data[index]['nama_pelanggan'],
                    data[index]['alamat'],
                    "${data[index]['daya']} VA",
                    data[index]['tgl_pasang'],
                    data[index]['tgl_bongkar'],
                    data[index]['teknisi'],
                    data[index]['status'],
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
                      pw.Text(
                        "Pacitan, ${DateFormat('dd MMMM yyyy', 'id_ID').format(DateTime.now())}",
                        style: pw.TextStyle(fontSize: 9),
                      ),
                      pw.Text(
                        "Admin PESTA Mobile",
                        style: pw.TextStyle(fontSize: 9),
                      ),
                      pw.SizedBox(height: 40),
                      pw.Container(
                        width: 130,
                        decoration: const pw.BoxDecoration(
                          border: pw.Border(bottom: pw.BorderSide(width: 1)),
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        "PLN ULP PACITAN",
                        style: pw.TextStyle(
                          fontSize: 8,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ];
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (format) async => pdf.save(),
        name: 'Laporan_$monthLabel\_$selectedYear.pdf',
      );
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Gagal: $e")));
    } finally {
      if (mounted) setState(() => isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgGrey,
      appBar: AppBar(
        title: const Text(
          "Cetak Laporan PDF",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Header Icon Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE0E4E8)),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.picture_as_pdf_rounded,
                      size: 40,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Pilih Periode Laporan",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Laporan akan di-generate dalam format PDF landscape",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Form Selection Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE0E4E8)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel("Pilih Bulan"),
                  DropdownButtonFormField<String>(
                    value: selectedMonth,
                    decoration: _inputDecoration("Bulan"),
                    items: months
                        .map(
                          (m) => DropdownMenuItem(
                            value: m['value'],
                            child: Text(m['label']!),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => selectedMonth = v!),
                  ),
                  const SizedBox(height: 20),
                  _buildLabel("Pilih Tahun"),
                  DropdownButtonFormField<String>(
                    value: selectedYear,
                    decoration: _inputDecoration("Tahun"),
                    items: years
                        .map(
                          (y) => DropdownMenuItem(
                            value: y,
                            child: Text("Tahun $y"),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => selectedYear = v!),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Generate Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                onPressed: isGenerating ? null : _generatePdf,
                icon: isGenerating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.print_rounded),
                label: Text(
                  isGenerating ? "PROSES..." : "GENERATE PDF",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.black54,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFFF8F9FA),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE0E4E8)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primaryBlue, width: 1.5),
      ),
    );
  }
}
