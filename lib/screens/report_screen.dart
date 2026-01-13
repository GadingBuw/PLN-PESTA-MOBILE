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
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("Data Kosong")));
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
              // Header Ringkas
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

              // Tabel
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

              // TANDA TANGAN (Dinaikkan mepet ke tabel)
              pw.SizedBox(height: 10), // Jarak pendek agar tidak pindah halaman
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
                      pw.SizedBox(height: 30), // Ruang TTD dipendekkan
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
        name: 'Laporan_$selectedMonth.pdf',
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
      appBar: AppBar(
        title: const Text("Cetak Laporan PDF"),
        backgroundColor: const Color(0xFF1A56F0),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          children: [
            const Icon(Icons.picture_as_pdf, size: 50, color: Colors.red),
            const SizedBox(height: 30),
            DropdownButtonFormField<String>(
              value: selectedMonth,
              decoration: const InputDecoration(
                labelText: "Bulan",
                border: OutlineInputBorder(),
              ),
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
            const SizedBox(height: 15),
            DropdownButtonFormField<String>(
              value: selectedYear,
              decoration: const InputDecoration(
                labelText: "Tahun",
                border: OutlineInputBorder(),
              ),
              items: years
                  .map(
                    (y) => DropdownMenuItem(value: y, child: Text("Tahun $y")),
                  )
                  .toList(),
              onChanged: (v) => setState(() => selectedYear = v!),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A56F0),
                  foregroundColor: Colors.white,
                ),
                onPressed: isGenerating ? null : _generatePdf,
                icon: isGenerating
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Icon(Icons.print),
                label: const Text("GENERATE PDF"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
