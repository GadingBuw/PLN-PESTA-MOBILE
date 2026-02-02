import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; 
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';
import '../services/task_service.dart';
import '../services/pdf_service.dart';

class TechDetailScreen extends StatefulWidget {
  final Map taskData;
  const TechDetailScreen({super.key, required this.taskData});
  @override
  State<TechDetailScreen> createState() => _TechDetailScreenState();
}

class _TechDetailScreenState extends State<TechDetailScreen> {
  File? _img;
  bool _loading = false;
  
  // Controller untuk input angka stand meter dari lapangan
  final TextEditingController _standController = TextEditingController();
  
  // Inisialisasi client Supabase
  final supabase = Supabase.instance.client;

  final Color primaryBlue = const Color(0xFF1A56F0);
  final Color bgGrey = const Color(0xFFF0F2F5);
  final Color borderGrey = const Color(0xFFE0E4E8);

  // Helper untuk mendapatkan URL Foto dari Storage
  String _getPublicUrl(String? fileName) {
    if (fileName == null || fileName.isEmpty) return "";
    final String folder = "bukti_${widget.taskData['id']}";
    return Supabase.instance.client.storage
        .from('task-photos')
        .getPublicUrl("$folder/$fileName");
  }

  // --- FITUR: PILIH SUMBER FOTO (KAMERA/GALERI) ---
  Future<void> _pickImage(ImageSource source) async {
    final p = await ImagePicker().pickImage(source: source, imageQuality: 40);
    if (p != null) setState(() => _img = File(p.path));
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_enhance_rounded, color: Colors.blue),
              title: const Text('Ambil Foto Langsung (Kamera)'),
              onTap: () { Navigator.pop(context); _pickImage(ImageSource.camera); },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded, color: Colors.orange),
              title: const Text('Pilih dari Memori HP (Galeri)'),
              onTap: () { Navigator.pop(context); _pickImage(ImageSource.gallery); },
            ),
          ],
        ),
      ),
    );
  }

  // --- FITUR: EDIT FOTO YANG SUDAH TERKONFIRMASI ---
  Future<void> _processEditPhoto(bool isPasang, ImageSource source) async {
    final p = await ImagePicker().pickImage(source: source, imageQuality: 40);
    if (p == null) return;

    setState(() => _loading = true);
    try {
      final String fileName = "${DateTime.now().millisecondsSinceEpoch}_edit.jpg";
      final String path = "bukti_${widget.taskData['id']}/$fileName";
      await supabase.storage.from('task-photos').upload(path, File(p.path));

      String kolomFoto = isPasang ? 'foto_pemasangan' : 'foto_pembongkaran';
      await TaskService().updateTask(widget.taskData['id'], {
        kolomFoto: fileName,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Foto bukti berhasil diperbarui!")));
        setState(() { widget.taskData[kolomFoto] = fileName; });
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal edit: $e")));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showEditOptions(bool isPasang) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text("Ubah ${isPasang ? 'Foto Pasang' : 'Foto Bongkar'}", style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.blue),
              title: const Text('Ganti via Kamera'),
              onTap: () { Navigator.pop(context); _processEditPhoto(isPasang, ImageSource.camera); },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.orange),
              title: const Text('Ganti via Galeri'),
              onTap: () { Navigator.pop(context); _processEditPhoto(isPasang, ImageSource.gallery); },
            ),
          ],
        ),
      ),
    );
  }

  // --- FITUR: CETAK PDF SUPLISI UNTUK PETUGAS ---
  void _showSuplisiDialog() {
    final hargaCtrl = TextEditingController(text: "1973.42");
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Cetak PDF Suplisi", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: TextField(
          controller: hargaCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: "Harga per KWH (Rp)", border: OutlineInputBorder(), prefixText: "Rp "),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              PdfService.generateSuplisiPdf(
                taskData: widget.taskData, 
                hargaPerKwh: double.tryParse(hargaCtrl.text) ?? 0
              );
            },
            child: const Text("Cetak"),
          ),
        ],
      ),
    );
  }

  // --- LOGIKA KONFIRMASI (REVISI H-1) ---
  Future<void> _submit() async {
    if (_img == null) {
<<<<<<< HEAD
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
=======
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Ambil atau upload foto bukti!")));
      return;
    }
    if (_standController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Isi angka stand meter lapangan!")));
      return;
    }

    DateTime todayDate = DateTime.parse(DateFormat('yyyy-MM-dd').format(DateTime.now()));
    String status = widget.taskData['status'];
    DateTime tglRencana = DateTime.parse(
      status == 'Menunggu Pemasangan' ? widget.taskData['tgl_pasang'] : widget.taskData['tgl_bongkar'],
    );

    // REVISI LOGIKA: Pemasangan boleh H-1, Pembongkaran harus Pas Hari-H
    if (status == 'Menunggu Pemasangan') {
      DateTime hMinus1 = tglRencana.subtract(const Duration(days: 1));
      if (todayDate.isBefore(hMinus1)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Pemasangan maksimal dilakukan H-1 dari jadwal!"), backgroundColor: Colors.orange),
        );
        return;
      }
    } else {
      if (tglRencana.isAfter(todayDate)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Belum masuk jadwal pembongkaran!"), backgroundColor: Colors.red),
        );
        return;
      }
>>>>>>> EditArya
    }

    setState(() => _loading = true);

    try {
<<<<<<< HEAD
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
=======
      final String fileName = "${DateTime.now().millisecondsSinceEpoch}.jpg";
      final String path = "bukti_${widget.taskData['id']}/$fileName";
      await supabase.storage.from('task-photos').upload(path, _img!);

      String statusBaru = (status == 'Menunggu Pemasangan') ? 'Menunggu Pembongkaran' : 'Selesai';
      String kolomFoto = (status == 'Menunggu Pemasangan') ? 'foto_pemasangan' : 'foto_pembongkaran';
      String kolomStand = (status == 'Menunggu Pemasangan') ? 'stand_pasang' : 'stand_bongkar';

      await TaskService().updateTask(widget.taskData['id'], {
        'status': statusBaru,
        kolomFoto: fileName,
        kolomStand: double.tryParse(_standController.text) ?? 0,
      });

      if (mounted) Navigator.pop(context);
>>>>>>> EditArya
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
<<<<<<< HEAD
=======
    bool isSelesai = widget.taskData['status'] == 'Selesai';
    bool isBongkar = widget.taskData['status'].toString().contains('Pembongkaran');

    bool checkPasang = isBongkar || isSelesai;
    bool checkBongkar = isSelesai;

>>>>>>> EditArya
    LatLng loc = LatLng(
      double.tryParse(widget.taskData['latitude'].toString()) ?? -8.2045,
      double.tryParse(widget.taskData['longitude'].toString()) ?? 111.0921,
    );
<<<<<<< HEAD
    bool isCompleted = widget.taskData['status'] == 'Selesai';
    bool isBongkar = widget.taskData['status'].toString().contains(
      'Pembongkaran',
    );
=======
>>>>>>> EditArya

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
<<<<<<< HEAD
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
=======
            const Text("EKSEKUSI PENUGASAN", style: TextStyle(color: Colors.grey, fontSize: 10, letterSpacing: 1, fontWeight: FontWeight.bold)),
            Text("Agenda: ${widget.taskData['no_agenda']}", style: const TextStyle(color: Colors.black, fontSize: 15, fontWeight: FontWeight.bold)),
>>>>>>> EditArya
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
<<<<<<< HEAD
=======
            // HEADER CONTAINER
>>>>>>> EditArya
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
              decoration: BoxDecoration(
                color: primaryBlue,
                borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
              ),
              child: Column(
                children: [
                  Container(
<<<<<<< HEAD
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
=======
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
                    child: Text(
                      isSelesai ? "PENUGASAN SELESAI" : (isBongkar ? "FASE PEMBONGKARAN" : "FASE PEMASANGAN"),
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2),
>>>>>>> EditArya
                    ),
                  ),
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
<<<<<<< HEAD
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
=======
                      _buildStepItem("RENCANA PASANG", widget.taskData['tgl_pasang'], checkPasang),
                      Expanded(child: Container(height: 2, color: checkBongkar ? Colors.greenAccent : Colors.white24, margin: const EdgeInsets.symmetric(horizontal: 15))),
                      _buildStepItem("RENCANA BONGKAR", widget.taskData['tgl_bongkar'], checkBongkar),
>>>>>>> EditArya
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
<<<<<<< HEAD
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
=======
                  // CARD 1: INFORMASI PELANGGAN
                  _buildSectionCard("INFORMASI PELANGGAN", [
                    _buildInfoRow(Icons.person_pin_rounded, "Nama Pemohon", widget.taskData['nama_pelanggan']),
                    _buildInfoRow(Icons.map_rounded, "Alamat Lengkap", widget.taskData['alamat']),
                    _buildInfoRow(Icons.bolt_rounded, "Daya Terpasang", "${widget.taskData['daya']} VA"),
                  ]),

                  const SizedBox(height: 16),

                  // CARD 2: INPUT LAPANGAN
                  if (!isSelesai)
                    _buildSectionCard("INPUT HASIL LAPANGAN", [
                      const Text("Masukkan angka stand meter dan foto kwh meter sebagai bukti.", style: TextStyle(fontSize: 12, color: Colors.black54)),
                      const SizedBox(height: 20),
                      
                      TextField(
                        controller: _standController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: isBongkar ? "Stand Bongkar (KWH)" : "Stand Pasang (KWH)",
                          hintText: "Contoh: 1250.50",
                          prefixIcon: const Icon(Icons.speed_rounded),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      
                      const SizedBox(height: 20),

                      GestureDetector(
                        onTap: _showImageSourceDialog,
                        child: Container(
                          width: double.infinity,
                          height: 200,
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: borderGrey, width: 2)),
                          child: _img == null
                              ? Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.camera_enhance_rounded, size: 48, color: primaryBlue.withOpacity(0.5)),
                                    const SizedBox(height: 12),
                                    const Text("Ambil / Upload Foto Bukti", style: TextStyle(fontWeight: FontWeight.w600)),
                                  ],
                                )
                              : ClipRRect(borderRadius: BorderRadius.circular(15), child: Image.file(_img!, fit: BoxFit.cover)),
                        ),
                      ),
                      
                      const SizedBox(height: 25),

                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00C853), foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                          onPressed: _loading ? null : _submit,
                          child: _loading
                              ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                              : const Text("KONFIRMASI PENYELESAIAN", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 0.5)),
                        ),
                      ),
                    ]),

                  const SizedBox(height: 16),

                  // CARD 3: BUKTI PEKERJAAN & CETAK
                  _buildSectionCard("BUKTI DOKUMENTASI & CETAK", [
                    _buildPhotoViewerWithEdit("FOTO PEMASANGAN", checkPasang ? _getPublicUrl(widget.taskData['foto_pemasangan']) : null, () => _showEditOptions(true)),
                    const SizedBox(height: 20),
                    _buildPhotoViewerWithEdit("FOTO PEMBONGKARAN", checkBongkar ? _getPublicUrl(widget.taskData['foto_pembongkaran']) : null, () => _showEditOptions(false)),
                    const Divider(height: 40),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        onPressed: _showSuplisiDialog,
                        icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
                        label: const Text("CETAK PDF SUPLISI", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ]),

                  const SizedBox(height: 16),

                  // CARD 4: TITIK LOKASI
                  _buildSectionCard("TITIK LOKASI PENERANGAN", [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: SizedBox(
                        height: 200,
                        child: FlutterMap(
                          options: MapOptions(initialCenter: loc, initialZoom: 15),
                          children: [
                            TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'),
                            MarkerLayer(markers: [Marker(point: loc, width: 45, height: 45, child: Icon(Icons.location_on_rounded, color: primaryBlue, size: 45))]),
                          ],
>>>>>>> EditArya
                        ),
                      ),
                    ),
                  ]),
<<<<<<< HEAD
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
=======
                  
                  const SizedBox(height: 30),
>>>>>>> EditArya
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

<<<<<<< HEAD
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
=======
  // --- HELPER WIDGETS (IDENTIK DENGAN ASLI ANDA) ---

  Widget _buildPhotoViewerWithEdit(String title, String? url, VoidCallback onEdit) {
    bool hasUrl = url != null && url.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
            if (hasUrl) IconButton(icon: const Icon(Icons.edit_rounded, color: Colors.orange, size: 20), onPressed: onEdit),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          height: 180,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: borderGrey, width: 2)),
          child: hasUrl 
            ? ClipRRect(borderRadius: BorderRadius.circular(15), child: Image.network(url, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.broken_image))) 
            : Center(child: Icon(Icons.image_not_supported, color: Colors.grey[300], size: 40)),
        ),
      ],
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
            Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: primaryBlue, letterSpacing: 0.8)),
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
            Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: primaryBlue.withOpacity(0.08), borderRadius: BorderRadius.circular(10)), child: Icon(icon, size: 20, color: primaryBlue)),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 3),
                  Text(value ?? "-", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
                ],
              ),
            ),
          ],
        ),
      );
}
>>>>>>> EditArya
