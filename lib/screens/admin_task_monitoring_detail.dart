import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'admin_edit_task_screen.dart';
import '../services/pdf_service.dart';

class AdminTaskMonitoringDetail extends StatefulWidget {
  final Map taskData;
  const AdminTaskMonitoringDetail({super.key, required this.taskData});

  @override
  State<AdminTaskMonitoringDetail> createState() => _AdminTaskMonitoringDetailState();
}

class _AdminTaskMonitoringDetailState extends State<AdminTaskMonitoringDetail> {
  final Color primaryBlue = const Color(0xFF1A56F0);
  final Color bgGrey = const Color(0xFFF0F2F5);
  final Color borderGrey = const Color(0xFFE0E4E8);

  String _getPublicUrl(String? fileName) {
    if (fileName == null || fileName.isEmpty) return "";
    final String folder = "bukti_${widget.taskData['id']}";
    return Supabase.instance.client.storage
        .from('task-photos')
        .getPublicUrl("$folder/$fileName");
  }

  // Dialog untuk Input Data Suplisi sebelum Cetak
  void _showSuplisiInputDialog() {
    final kwhTotalCtrl = TextEditingController(text: "1055");
    final kwhBayarCtrl = TextEditingController(text: "500");
    final hargaCtrl = TextEditingController(text: "1973.42");

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Input Parameter Suplisi", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDialogField(kwhTotalCtrl, "Total KWH Terpakai (Pesta)", "kWh"),
            _buildDialogField(kwhBayarCtrl, "KWH Sudah Terbayar (Awal)", "kWh"),
            _buildDialogField(hargaCtrl, "Harga per KWH (Rp)", "Rp"),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700),
            onPressed: () {
              Navigator.pop(context);
              PdfService.generateSuplisiPdf(
                taskData: widget.taskData,
                totalKwhPesta: double.tryParse(kwhTotalCtrl.text) ?? 0,
                kwhSudahTerbayar: double.tryParse(kwhBayarCtrl.text) ?? 0,
                hargaPerKwh: double.tryParse(hargaCtrl.text) ?? 0,
              );
            },
            child: const Text("CETAK PDF", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogField(TextEditingController ctrl, String label, String suffix) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: ctrl,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(labelText: label, suffixText: suffix, border: const OutlineInputBorder()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String status = widget.taskData['status'] ?? "";
    bool isSelesai = status == 'Selesai';
    bool isBongkar = status.contains('Pembongkaran');
    bool checkPasang = isBongkar || isSelesai;
    bool checkBongkar = isSelesai;

    LatLng loc = LatLng(
      double.tryParse(widget.taskData['latitude'].toString()) ?? -8.2045,
      double.tryParse(widget.taskData['longitude'].toString()) ?? 111.0921,
    );

    return Scaffold(
      backgroundColor: bgGrey,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: primaryBlue, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("DOKUMENTASI", style: TextStyle(color: Colors.grey, fontSize: 10)),
            Text(
              "Agenda: ${widget.taskData['id_pelanggan']}",
              style: const TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_note, color: Colors.orange, size: 28),
            onPressed: () => Navigator.push(
              context, 
              MaterialPageRoute(builder: (c) => AdminEditTaskScreen(taskData: widget.taskData))
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
              decoration: BoxDecoration(
                color: primaryBlue,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStepItem("RENCANA PASANG", widget.taskData['tgl_pasang'], checkPasang),
                      Expanded(
                        child: Container(
                          height: 2,
                          color: checkBongkar ? Colors.greenAccent : Colors.white24,
                          margin: const EdgeInsets.symmetric(horizontal: 15),
                        ),
                      ),
                      _buildStepItem("RENCANA BONGKAR", widget.taskData['tgl_bongkar'], checkBongkar),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildSectionCard("INFORMASI PELANGGAN", [
                    _buildInfoRow(Icons.person_pin_rounded, "Nama Pemohon", widget.taskData['nama_pelanggan']),
                    _buildInfoRow(Icons.map_rounded, "Alamat Lengkap", widget.taskData['alamat']),
                    _buildInfoRow(Icons.bolt_rounded, "Daya Terpasang", "${widget.taskData['daya']} VA"),
                    const SizedBox(height: 20),
                    // TOMBOL BARU: CETAK PDF SUPLISI
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade700,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: _showSuplisiInputDialog,
                        icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
                        label: const Text("CETAK PDF SUPLISI", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 16),
                  _buildSectionCard("TITIK LOKASI", [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: SizedBox(
                        height: 200,
                        child: FlutterMap(
                          options: MapOptions(initialCenter: loc, initialZoom: 15),
                          children: [
                            TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'),
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: loc,
                                  width: 45,
                                  height: 45,
                                  child: Icon(Icons.location_on_rounded, color: primaryBlue, size: 45),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 16),
                  _buildSectionCard("BUKTI PEKERJAAN", [
                    _buildPhotoViewer("BUKTI PASANG", checkPasang ? _getPublicUrl(widget.taskData['foto_pemasangan']) : null),
                    const SizedBox(height: 20),
                    _buildPhotoViewer("BUKTI BONGKAR", checkBongkar ? _getPublicUrl(widget.taskData['foto_pembongkaran']) : null),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepItem(String label, String? date, bool isActive) => Column(
    children: [
      Text(label, style: const TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.bold)),
      const SizedBox(height: 4),
      Text(date ?? "-", style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
      const SizedBox(height: 10),
      Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(color: isActive ? Colors.white : Colors.white24, shape: BoxShape.circle),
        child: Icon(Icons.check_rounded, color: isActive ? primaryBlue : Colors.transparent, size: 16),
      ),
    ],
  );

  Widget _buildSectionCard(String title, List<Widget> children) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: borderGrey)),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: primaryBlue, letterSpacing: 0.8)),
        const SizedBox(height: 15),
        const Divider(height: 1),
        const SizedBox(height: 20),
        ...children,
      ],
    ),
  );

  Widget _buildInfoRow(IconData icon, String label, String? value) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: primaryBlue.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 18, color: primaryBlue),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(value ?? "-", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _buildPhotoViewer(String title, String? imageUrl) {
    bool hasImage = imageUrl != null && imageUrl.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          height: 200,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: borderGrey, width: 2)),
          child: hasImage 
            ? ClipRRect(borderRadius: BorderRadius.circular(15), child: Image.network(imageUrl, fit: BoxFit.cover)) 
            : Center(child: Icon(Icons.image_not_supported, color: Colors.grey[300], size: 40)),
        ),
      ],
    );
  }
}