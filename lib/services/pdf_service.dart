import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class PdfService {
  static Future<void> generateSuplisiPdf({
    required Map taskData,
    required double totalKwhPesta,
    required double kwhSudahTerbayar,
    required double hargaPerKwh,
  }) async {
    final pdf = pw.Document();
    final NumberFormat currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0);
    final NumberFormat decimalFormatter = NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 2);

    // 1. Inisialisasi Data Dasar
    final DateTime tglMulai = DateTime.parse(taskData['tgl_pasang']);
    final DateTime tglSelesai = DateTime.parse(taskData['tgl_bongkar']);
    final String agenda = taskData['id_pelanggan'] ?? "-";
    final String nama = (taskData['nama_pelanggan'] ?? "-").toString().toUpperCase();
    final String alamat = taskData['alamat'] ?? "-";
    final String daya = taskData['daya']?.toString() ?? "0";

    // 2. Logika Perhitungan Pro-Rata Hari
    final int totalHariPakai = tglSelesai.difference(tglMulai).inDays + 1;
    final double kwhPerHari = totalKwhPesta / totalHariPakai;
    
    List<List<String>> tableRows = [];
    double calculatedTotalRpKwh = 0;

    // Cek apakah melewati bulan yang berbeda
    if (tglMulai.month != tglSelesai.month) {
      // Perhitungan Bulan 1 (Hingga akhir bulan)
      int hariBulan1 = DateTime(tglMulai.year, tglMulai.month + 1, 0).day - tglMulai.day + 1;
      double kwhBulan1 = hariBulan1 * kwhPerHari;
      double rpBulan1 = kwhBulan1 * hargaPerKwh;
      tableRows.add([
        "${tglMulai.year}${tglMulai.month.toString().padLeft(2, '0')}",
        hariBulan1.toString(),
        kwhBulan1.toStringAsFixed(2),
        decimalFormatter.format(hargaPerKwh).trim(),
        currencyFormatter.format(rpBulan1).trim()
      ]);
      calculatedTotalRpKwh += rpBulan1;

      // Perhitungan Bulan 2 (Sisa hari di bulan berikutnya)
      int hariBulan2 = tglSelesai.day;
      double kwhBulan2 = hariBulan2 * kwhPerHari;
      double rpBulan2 = kwhBulan2 * hargaPerKwh;
      tableRows.add([
        "${tglSelesai.year}${tglSelesai.month.toString().padLeft(2, '0')}",
        hariBulan2.toString(),
        kwhBulan2.toStringAsFixed(2),
        decimalFormatter.format(hargaPerKwh).trim(),
        currencyFormatter.format(rpBulan2).trim()
      ]);
      calculatedTotalRpKwh += rpBulan2;
    } else {
      // Jika dalam bulan yang sama
      double totalRp = totalKwhPesta * hargaPerKwh;
      tableRows.add([
        "${tglMulai.year}${tglMulai.month.toString().padLeft(2, '0')}",
        totalHariPakai.toString(),
        totalKwhPesta.toStringAsFixed(2),
        decimalFormatter.format(hargaPerKwh).trim(),
        currencyFormatter.format(totalRp).trim()
      ]);
      calculatedTotalRpKwh = totalRp;
    }

    // 3. Perhitungan Biaya Suplisi & PPJ (Sesuai Ketentuan PLN)
    double biayaKwhTertagih = kwhSudahTerbayar * hargaPerKwh;
    double rpSuplisiKwh = calculatedTotalRpKwh - biayaKwhTertagih;
    double ppj = rpSuplisiKwh * 0.1; // PPJ 10%
    double jumlahTotal = rpSuplisiKwh + ppj;

    // 4. Desain Layout PDF
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text(
                  "PERHITUNGAN PEMAKAIAN REALISASI DAN SUPLISI /RESTITUSI PESTA (SIMULASI)",
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
                ),
              ),
              pw.SizedBox(height: 20),
              _buildInfoLine("Noagenda Pesta", agenda),
              _buildInfoLine("Noagenda SUPLISI", "-"),
              _buildInfoLine("Nama", nama),
              _buildInfoLine("Alamat", alamat),
              _buildInfoLine("Tarif Peruntukan", "B"),
              _buildInfoLine("Daya", currencyFormatter.format(int.parse(daya.replaceAll(RegExp(r'[^0-9]'), '')))),
              _buildInfoLine("KWH Sudah Terbayar", kwhSudahTerbayar.toInt().toString()),
              _buildInfoLine("KWH Suplisi", (totalKwhPesta - kwhSudahTerbayar).toInt().toString()),
              _buildInfoLine("Total KWH Pesta", totalKwhPesta.toInt().toString()),
              _buildInfoLine("Tgl Mulai", DateFormat('dd-MM-yyyy').format(tglMulai)),
              _buildInfoLine("Tgl Selesai", DateFormat('dd-MM-yyyy').format(tglSelesai)),
              
              pw.SizedBox(height: 20),

              // Tabel Perhitungan Dinamis
              pw.TableHelper.fromTextArray(
                headers: ["Bulan Pakai", "Hari Pakai", "Pem KWH", "Harga /KWH", "Rp KWH Pesta"],
                data: [
                  ...tableRows,
                  ["Total", totalHariPakai.toString(), totalKwhPesta.toInt().toString(), "Rp", currencyFormatter.format(calculatedTotalRpKwh).trim()],
                ],
                border: pw.TableBorder.all(),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
                cellStyle: const pw.TextStyle(fontSize: 8.5),
                cellAlignment: pw.Alignment.center,
              ),

              pw.SizedBox(height: 20),

              // Rincian Biaya Bawah
              _buildSummaryRow("Biaya KWH Tertagih", "Rp", currencyFormatter.format(biayaKwhTertagih).trim()),
              _buildSummaryRow("RP SUPLISI KWH", "Rp", currencyFormatter.format(rpSuplisiKwh).trim()),
              _buildSummaryRow("PPJ (10%)", "Rp", currencyFormatter.format(ppj).trim()),
              _buildSummaryRow("RP SUPLISI PPN", "Rp", "0"),
              pw.Divider(thickness: 1),
              _buildSummaryRow("Jumlah", "Rp", currencyFormatter.format(jumlahTotal).trim(), isBold: true),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Suplisi_$agenda.pdf',
    );
  }

  static pw.Widget _buildInfoLine(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
      child: pw.Row(children: [
        pw.SizedBox(width: 130, child: pw.Text(label, style: const pw.TextStyle(fontSize: 9))),
        pw.Text(": $value", style: const pw.TextStyle(fontSize: 9)),
      ]),
    );
  }

  static pw.Widget _buildSummaryRow(String label, String unit, String value, {bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: 10, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal)),
          pw.Row(children: [
            pw.Text(unit, style: const pw.TextStyle(fontSize: 10)),
            pw.SizedBox(width: 40),
            pw.SizedBox(width: 80, child: pw.Text(value, textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 10, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal))),
          ]),
        ],
      ),
    );
  }
}