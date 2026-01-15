import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';
import '../main.dart';

class TechDetailScreen extends StatefulWidget {
  final Map taskData;
  const TechDetailScreen({super.key, required this.taskData});
  @override
  State<TechDetailScreen> createState() => _TechDetailScreenState();
}

class _TechDetailScreenState extends State<TechDetailScreen> {
  File? _img;
  bool _loading = false;

  final Color primaryBlue = const Color(0xFF1A56F0);
  final Color bgGrey = const Color(0xFFF0F2F5);
  final Color borderGrey = const Color(0xFFE0E4E8);

  Future<void> _submit() async {
    if (_img == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Ambil foto bukti!")));
      return;
    }

    DateTime todayDate = DateTime.parse(
      DateFormat('yyyy-MM-dd').format(DateTime.now()),
    );
    String status = widget.taskData['status'];
    DateTime tglRencana = DateTime.parse(
      status == 'Menunggu Pemasangan'
          ? widget.taskData['tgl_pasang']
          : widget.taskData['tgl_bongkar'],
    );

    if (tglRencana.isAfter(todayDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Belum masuk jadwal pengerjaan!"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      var req = http.MultipartRequest(
        'POST',
        Uri.parse("$baseUrl?action=complete_task"),
      );
      req.fields['id'] = widget.taskData['id'].toString();
      req.fields['current_status'] = status;
      req.files.add(await http.MultipartFile.fromPath('foto', _img!.path));
      var res = await req.send();
      if (res.statusCode == 200) Navigator.pop(context);
    } catch (e) {
      debugPrint("Error: $e");
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // --- LOGIKA STATUS ---
    bool isSelesai = widget.taskData['status'] == 'Selesai';
    bool isBongkar = widget.taskData['status'].toString().contains(
      'Pembongkaran',
    );

    // Centang Pasang: Jika sedang fase bongkar ATAU sudah selesai total
    bool checkPasang = isBongkar || isSelesai;
    // Centang Bongkar: Hanya jika sudah selesai total
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
            const Text(
              "EKSEKUSI PENUGASAN",
              style: TextStyle(
                color: Colors.grey,
                fontSize: 10,
                letterSpacing: 1,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              "Agenda: ${widget.taskData['id_pelanggan']}",
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
                      isSelesai
                          ? "PENUGASAN SELESAI"
                          : (isBongkar
                                ? "FASE PEMBONGKARAN"
                                : "FASE PEMASANGAN"),
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
                        widget.taskData['tgl_pasang'],
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
                        widget.taskData['tgl_bongkar'],
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
                  _buildSectionCard("INFORMASI PELANGGAN", [
                    _buildInfoRow(
                      Icons.person_pin_rounded,
                      "Nama Pemohon",
                      widget.taskData['nama_pelanggan'],
                    ),
                    _buildInfoRow(
                      Icons.map_rounded,
                      "Alamat Lengkap",
                      widget.taskData['alamat'],
                    ),
                    _buildInfoRow(
                      Icons.bolt_rounded,
                      "Daya Terpasang",
                      "${widget.taskData['daya']} VA",
                    ),
                  ]),
                  const SizedBox(height: 16),
                  _buildSectionCard("TITIK LOKASI", [
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
                    const SizedBox(height: 12),
                    Center(
                      child: Text(
                        "Koordinat: ${loc.latitude}, ${loc.longitude}",
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 16),
                  if (!isSelesai)
                    _buildSectionCard("BUKTI PEKERJAAN", [
                      const Text(
                        "Unggah foto dokumentasi pekerjaan di lapangan.",
                        style: TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                      const SizedBox(height: 20),
                      GestureDetector(
                        onTap: () async {
                          final p = await ImagePicker().pickImage(
                            source: ImageSource.camera,
                            imageQuality: 40,
                          );
                          if (p != null) setState(() => _img = File(p.path));
                        },
                        child: Container(
                          width: double.infinity,
                          height: 200,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: borderGrey, width: 2),
                          ),
                          child: _img == null
                              ? Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.camera_enhance_rounded,
                                      size: 48,
                                      color: primaryBlue.withOpacity(0.5),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      "Klik untuk Ambil Foto",
                                      style: TextStyle(
                                        color: primaryBlue,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                )
                              : ClipRRect(
                                  borderRadius: BorderRadius.circular(15),
                                  child: Image.file(_img!, fit: BoxFit.cover),
                                ),
                        ),
                      ),
                      const SizedBox(height: 25),
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00C853),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _loading ? null : _submit,
                          child: _loading
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 3,
                                  ),
                                )
                              : const Text(
                                  "KONFIRMASI PENYELESAIAN",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                        ),
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
            fontSize: 12,
            color: primaryBlue,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 15),
        const Divider(height: 1, thickness: 1),
        const SizedBox(height: 20),
        ...children,
      ],
    ),
  );

  Widget _buildInfoRow(IconData icon, String label, String? value) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: primaryBlue.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: primaryBlue),
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
              const SizedBox(height: 3),
              Text(
                value ?? "-",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
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
