import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class AdminTaskMonitoringDetail extends StatelessWidget {
  final Map taskData; // Data dipassing dari AdminTechHistoryDetail
  const AdminTaskMonitoringDetail({super.key, required this.taskData});

  final Color primaryBlue = const Color(0xFF1A56F0);
  final Color bgGrey = const Color(0xFFF0F2F5);
  final Color borderGrey = const Color(0xFFE0E4E8);

  // Fungsi ambil URL Foto Publik dari Supabase
  String _getPublicUrl(String? fileName) {
    if (fileName == null || fileName.isEmpty) return "";
    final String folder = "bukti_${taskData['id']}";
    return Supabase.instance.client.storage
        .from('task-photos')
        .getPublicUrl("$folder/$fileName");
  }

  @override
  Widget build(BuildContext context) {
    String status = taskData['status'] ?? "";
    bool isSelesai = status == 'Selesai';
    bool isBongkar = status.contains('Pembongkaran');

    // Logika Step & Foto Berdasarkan Status
    bool checkPasang = isBongkar || isSelesai;
    bool checkBongkar = isSelesai;

    LatLng loc = LatLng(
      double.tryParse(taskData['latitude'].toString()) ?? -8.2045,
      double.tryParse(taskData['longitude'].toString()) ?? 111.0921,
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
            const Text(
              "DOKUMENTASI PENUGASAN",
              style: TextStyle(
                color: Colors.grey,
                fontSize: 10,
                letterSpacing: 1,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              "Agenda: ${taskData['id_pelanggan']}",
              style: const TextStyle(
                color: Colors.black,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Biru Senada dengan TechDetailScreen
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStepItem(
                        "RENCANA PASANG",
                        taskData['tgl_pasang'],
                        checkPasang,
                      ),
                      Expanded(
                        child: Container(
                          height: 2,
                          color: checkBongkar
                              ? Colors.greenAccent
                              : Colors.white24,
                          margin: const EdgeInsets.symmetric(horizontal: 15),
                        ),
                      ),
                      _buildStepItem(
                        "RENCANA BONGKAR",
                        taskData['tgl_bongkar'],
                        checkBongkar,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // 1. Informasi Pelanggan
                  _buildSectionCard("INFORMASI PELANGGAN", [
                    _buildInfoRow(
                      Icons.person_pin_rounded,
                      "Nama Pemohon",
                      taskData['nama_pelanggan'],
                    ),
                    _buildInfoRow(
                      Icons.map_rounded,
                      "Alamat Lengkap",
                      taskData['alamat'],
                    ),
                    _buildInfoRow(
                      Icons.bolt_rounded,
                      "Daya Terpasang",
                      "${taskData['daya']} VA",
                    ),
                  ]),

                  const SizedBox(height: 16),

                  // 2. Lokasi Peta
                  _buildSectionCard("TITIK LOKASI PENUGASAN", [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: SizedBox(
                        height: 200,
                        child: FlutterMap(
                          options: MapOptions(
                            initialCenter: loc,
                            initialZoom: 15,
                          ),
                          children: [
                            TileLayer(
                              urlTemplate:
                                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            ),
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: loc,
                                  width: 45,
                                  height: 45,
                                  child: Icon(
                                    Icons.location_on_rounded,
                                    color: primaryBlue,
                                    size: 45,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ]),

                  const SizedBox(height: 16),

                  // 3. Bukti Foto (Dinamis Sesuai Status)
                  _buildSectionCard("BUKTI PEKERJAAN LAPANGAN", [
                    _buildPhotoViewer(
                      "BUKTI PASANG",
                      checkPasang
                          ? _getPublicUrl(taskData['foto_pemasangan'])
                          : null,
                    ),
                    const SizedBox(height: 20),
                    _buildPhotoViewer(
                      "BUKTI BONGKAR",
                      checkBongkar
                          ? _getPublicUrl(taskData['foto_pembongkaran'])
                          : null,
                    ),
                  ]),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget Tampilan Foto
  Widget _buildPhotoViewer(String title, String? imageUrl) {
    bool hasImage = imageUrl != null && imageUrl.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          height: 200,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: borderGrey, width: 2),
          ),
          child: hasImage
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        _buildPlaceholder(
                          Icons.broken_image,
                          "Gagal memuat gambar",
                        ),
                  ),
                )
              : _buildPlaceholder(
                  Icons.image_not_supported,
                  "Pekerjaan belum dikerjakan",
                ),
        ),
      ],
    );
  }

  Widget _buildPlaceholder(IconData icon, String label) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 40, color: Colors.grey[300]),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(color: Colors.grey[400], fontSize: 12)),
      ],
    );
  }

  // UI Helpers (Read Only)
  Widget _buildStepItem(String label, String? date, bool isActive) => Column(
    children: [
      Text(
        label,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        date ?? "-",
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 10),
      Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.white24,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.check_rounded,
          color: isActive ? primaryBlue : Colors.transparent,
          size: 16,
        ),
      ),
    ],
  );

  Widget _buildSectionCard(String title, List<Widget> children) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: borderGrey),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 11,
            color: primaryBlue,
            letterSpacing: 0.8,
          ),
        ),
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
          decoration: BoxDecoration(
            color: primaryBlue.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: primaryBlue),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value ?? "-",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
