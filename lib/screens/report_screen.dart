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

  final List<String> months = ["01", "02", "03", "04", "05", "06", "07", "08", "09", "10", "11", "12"];
  final List<String> years = ["2024", "2025", "2026", "2027"];

  Future<void> _generatePdf() async {
    setState(() => isGenerating = true);
    try {
      final response = await http.get(
        Uri.parse("$baseUrl?action=get_report&bulan=$selectedMonth&tahun=$selectedYear"),
      );

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        if (data.isEmpty) {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Tidak ada data periode ini.")));
          setState(() => isGenerating = false); return;
        }

        final pdf = pw.Document();
        pdf.addPage(
          pw.MultiPage(
            pageFormat: PdfPageFormat.a4.landscape,
            margin: const pw.EdgeInsets.all(32),
            build: (pw.Context context) {
              return [
                pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                  pw.Text("PT PLN (PERSERO) - ULP PACITAN", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
                  pw.Text("LAPORAN BULANAN PENUGASAN PESTA", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                  pw.Text("Periode: $selectedMonth / $selectedYear", style: pw.TextStyle(fontSize: 10)),
                  pw.Divider(thickness: 2),
                ]),
                pw.SizedBox(height: 15),
                pw.TableHelper.fromTextArray(
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9, color: PdfColors.white),
                  headerDecoration: const pw.BoxDecoration(color: PdfColors.blue800),
                  cellStyle: const pw.TextStyle(fontSize: 8),
                  headers: ['No', 'No. Agenda', 'Nama Pelanggan', 'Alamat Lokasi', 'Daya', 'Pasang', 'Bongkar', 'Teknisi', 'Status'],
                  data: List<List<dynamic>>.generate(data.length, (index) => [
                    index + 1,
                    data[index]['id_pelanggan'],
                    data[index]['nama_pelanggan'],
                    data[index]['alamat'],
                    "${data[index]['daya']} VA",
                    data[index]['tgl_pasang'],
                    data[index]['tgl_bongkar'],
                    data[index]['teknisi'],
                    data[index]['status'],
                  ]),
                ),
                pw.SizedBox(height: 40),
                pw.Align(alignment: pw.Alignment.centerRight, child: pw.Column(children: [
                  pw.Text("Pacitan, ${DateFormat('dd MMMM yyyy').format(DateTime.now())}", style: const pw.TextStyle(fontSize: 9)),
                  pw.SizedBox(height: 50),
                  pw.Text("__________________________", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text("Admin PESTA Mobile", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                ]))
              ];
            },
          ),
        );
        await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
      }
    } catch (e) {
      debugPrint("PDF Error: $e");
    } finally {
      if (mounted) setState(() => isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(title: const Text("Laporan Bulanan PDF"), backgroundColor: const Color(0xFF1A56F0), foregroundColor: Colors.white, elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.picture_as_pdf, size: 60, color: Colors.redAccent),
          const SizedBox(height: 20),
          const Text("Cetak Laporan Penugasan", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
          const Text("Silakan pilih periode laporan penugasan rill.", style: TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 40),
          DropdownButtonFormField<String>(
            value: selectedMonth,
            decoration: const InputDecoration(labelText: "Pilih Bulan", border: OutlineInputBorder()),
            items: months.map((m) => DropdownMenuItem(value: m, child: Text("Bulan $m"))).toList(),
            onChanged: (val) => setState(() => selectedMonth = val!),
          ),
          const SizedBox(height: 20),
          DropdownButtonFormField<String>(
            value: selectedYear,
            decoration: const InputDecoration(labelText: "Pilih Tahun", border: OutlineInputBorder()),
            items: years.map((y) => DropdownMenuItem(value: y, child: Text("Tahun $y"))).toList(),
            onChanged: (val) => setState(() => selectedYear = val!),
          ),
          const SizedBox(height: 50),
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A56F0), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
              onPressed: isGenerating ? null : _generatePdf,
              icon: isGenerating ? const CircularProgressIndicator(color: Colors.white) : const Icon(Icons.download),
              label: const Text("GENERATE & DOWNLOAD PDF", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ]),
      ),
    );
  }
}