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
      if (res.statusCode == 200) {
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint("Error: $e");
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isCompleted = widget.taskData['status'] == 'Selesai';
    bool isBongkar = widget.taskData['status'].toString().contains(
      'Pembongkaran',
    );
    LatLng loc = LatLng(
      double.tryParse(widget.taskData['latitude'].toString()) ?? -8.2045,
      double.tryParse(widget.taskData['longitude'].toString()) ?? 111.0921,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Eksekusi Penugasan",
              style: TextStyle(color: Colors.grey, fontSize: 11),
            ),
            Text(
              "Agenda: ${widget.taskData['id_pelanggan']}",
              style: const TextStyle(
                color: Colors.black,
                fontSize: 14,
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
              padding: const EdgeInsets.all(20),
              color: const Color(0xFF1A56F0),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isBongkar ? "FASE PEMBONGKARAN" : "FASE PEMASANGAN",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStepItem(
                        "Mulai",
                        widget.taskData['tgl_pasang'],
                        true,
                      ),
                      Expanded(
                        child: Container(
                          height: 2,
                          color: isBongkar
                              ? Colors.greenAccent
                              : Colors.white24,
                          margin: const EdgeInsets.symmetric(horizontal: 10),
                        ),
                      ),
                      _buildStepItem(
                        "Selesai",
                        widget.taskData['tgl_bongkar'],
                        isBongkar,
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
                  _buildSectionCard("Informasi PESTA (Sesuai Dokumen)", [
                    _buildInfoRow(
                      Icons.assignment_outlined,
                      "Nomor Agenda",
                      widget.taskData['id_pelanggan'],
                    ),
                    _buildInfoRow(
                      Icons.person_outline,
                      "Nama Pemohon",
                      widget.taskData['nama_pelanggan'],
                    ),
                    _buildInfoRow(
                      Icons.location_on_outlined,
                      "Alamat Lokasi",
                      widget.taskData['alamat'],
                    ),
                    _buildInfoRow(
                      Icons.bolt,
                      "Daya Terpasang",
                      "${widget.taskData['daya']} VA",
                    ),
                  ]),
                  const SizedBox(height: 20),
                  _buildSectionCard("Lokasi Proyek", [
                    SizedBox(
                      height: 200,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(15),
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
                                  width: 40,
                                  height: 40,
                                  child: const Icon(
                                    Icons.location_on,
                                    color: Colors.red,
                                    size: 40,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Center(
                      child: Text(
                        "Koordinat: ${loc.latitude}, ${loc.longitude}",
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 20),
                  if (!isCompleted)
                    _buildSectionCard("Konfirmasi Penyelesaian", [
                      const Text(
                        "Ambil foto sebagai bukti pengerjaan lapangan.",
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 15),
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
                          height: 180,
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: _img == null
                              ? const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.camera_enhance_outlined,
                                      size: 40,
                                      color: Colors.grey,
                                    ),
                                    Text(
                                      "Klik untuk Kamera",
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
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
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          onPressed: _loading ? null : _submit,
                          child: _loading
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : const Text(
                                  "KONFIRMASI SELESAI",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                        ),
                      ),
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
      Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
      Text(
        date ?? "-",
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 8),
      Icon(
        Icons.check_circle,
        color: isActive ? Colors.greenAccent : Colors.white24,
        size: 20,
      ),
    ],
  );
  Widget _buildSectionCard(String title, List<Widget> children) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Colors.blue,
          ),
        ),
        const Divider(height: 25),
        ...children,
      ],
    ),
  );
  Widget _buildInfoRow(IconData icon, String label, String? value) => Padding(
    padding: const EdgeInsets.only(bottom: 15),
    child: Row(
      children: [
        Icon(icon, size: 20, color: Colors.blue),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: Colors.grey, fontSize: 11),
              ),
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
