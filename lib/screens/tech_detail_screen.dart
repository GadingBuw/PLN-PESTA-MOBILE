import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart'; 
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
<<<<<<< HEAD

  // Controller untuk input angka stand meter dari lapangan
  final TextEditingController _standController = TextEditingController();

  // Inisialisasi client Supabase
=======
  final TextEditingController _standController = TextEditingController();
>>>>>>> d771f310c3aa1a2c1ac8c1ede9b4597798fd2c8b
  final supabase = Supabase.instance.client;

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

  // --- FITUR: MULTI-CHANNEL COMMUNICATION ---
  Future<void> _contactCustomer() async {
    final String phone = widget.taskData['no_telp'] ?? "";
    if (phone.isEmpty) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Nomor telepon tidak tersedia")));
      return;
    }
    
    String cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanPhone.startsWith('0')) cleanPhone = '62${cleanPhone.substring(1)}';

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text("Pilih Metode Komunikasi", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.green,
                radius: 15,
                child: Icon(Icons.chat, color: Colors.white, size: 16), // Diganti agar tidak merah
              ),
              title: const Text('Kirim WhatsApp'),
              onTap: () {
                Navigator.pop(context);
                _launchExternalUrl("https://wa.me/$cleanPhone");
              },
            ),
            ListTile(
              leading: const Icon(Icons.phone, color: Colors.blue),
              title: const Text('Telepon Reguler (Pulsa)'),
              onTap: () {
                Navigator.pop(context);
                _launchExternalUrl("tel:+$cleanPhone");
              },
            ),
            ListTile(
              leading: const Icon(Icons.sms, color: Colors.orange),
              title: const Text('Kirim SMS'),
              onTap: () {
                Navigator.pop(context);
                _launchExternalUrl("sms:+$cleanPhone");
              },
            ),
          ],
        ),
      ),
    );
  }

  // Helper Launcher dengan pengecekan canLaunchUrl (Menghilangkan garis biru)
  Future<void> _launchExternalUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        throw 'Tidak bisa membuka $urlString';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal membuka aplikasi: $e")));
      }
    }
  }

  // --- FITUR: PILIH SUMBER FOTO ---
  Future<void> _pickImage(ImageSource source) async {
    final p = await ImagePicker().pickImage(source: source, imageQuality: 40);
    if (p != null) setState(() => _img = File(p.path));
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(
                Icons.camera_enhance_rounded,
                color: Colors.blue,
              ),
              title: const Text('Ambil Foto Langsung (Kamera)'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_library_rounded,
                color: Colors.orange,
              ),
              title: const Text('Pilih dari Memori HP (Galeri)'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  // --- FITUR: EDIT FOTO ---
  Future<void> _processEditPhoto(bool isPasang, ImageSource source) async {
    final p = await ImagePicker().pickImage(source: source, imageQuality: 40);
    if (p == null) return;

    setState(() => _loading = true);
    try {
      final String fileName =
          "${DateTime.now().millisecondsSinceEpoch}_edit.jpg";
      final String path = "bukti_${widget.taskData['id']}/$fileName";
      await supabase.storage.from('task-photos').upload(path, File(p.path));

      String kolomFoto = isPasang ? 'foto_pemasangan' : 'foto_pembongkaran';
      await TaskService().updateTask(widget.taskData['id'], {
        kolomFoto: fileName,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Foto bukti berhasil diperbarui!")),
        );
        setState(() {
          widget.taskData[kolomFoto] = fileName;
        });
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Gagal edit: $e")));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showEditOptions(bool isPasang) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                "Ubah ${isPasang ? 'Foto Pasang' : 'Foto Bongkar'}",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.blue),
              title: const Text('Ganti via Kamera'),
              onTap: () {
                Navigator.pop(context);
                _processEditPhoto(isPasang, ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.orange),
              title: const Text('Ganti via Galeri'),
              onTap: () {
                Navigator.pop(context);
                _processEditPhoto(isPasang, ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  // --- FITUR: CETAK PDF ---
  void _showSuplisiDialog() {
    final hargaCtrl = TextEditingController(text: "1973.42");
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          "Cetak PDF Suplisi",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        content: TextField(
          controller: hargaCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: "Harga per KWH (Rp)",
            border: OutlineInputBorder(),
            prefixText: "Rp ",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              PdfService.generateSuplisiPdf(
                taskData: widget.taskData,
                hargaPerKwh: double.tryParse(hargaCtrl.text) ?? 0,
              );
            },
            child: const Text("Cetak"),
          ),
        ],
      ),
    );
  }

  // --- LOGIKA KONFIRMASI H-1 ---
  Future<void> _submit() async {
    if (_img == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ambil atau upload foto bukti!")),
      );
      return;
    }
    if (_standController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Isi angka stand meter lapangan!")),
      );
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

    if (status == 'Menunggu Pemasangan') {
      DateTime hMinus1 = tglRencana.subtract(const Duration(days: 1));
      if (todayDate.isBefore(hMinus1)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Pemasangan maksimal dilakukan H-1 dari jadwal!"),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
    } else {
      if (tglRencana.isAfter(todayDate)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Belum masuk jadwal pembongkaran!"),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    setState(() => _loading = true);
    try {
      final String fileName = "${DateTime.now().millisecondsSinceEpoch}.jpg";
      final String path = "bukti_${widget.taskData['id']}/$fileName";
      await supabase.storage.from('task-photos').upload(path, _img!);

      String statusBaru = (status == 'Menunggu Pemasangan')
          ? 'Menunggu Pembongkaran'
          : 'Selesai';
      String kolomFoto = (status == 'Menunggu Pemasangan')
          ? 'foto_pemasangan'
          : 'foto_pembongkaran';
      String kolomStand = (status == 'Menunggu Pemasangan')
          ? 'stand_pasang'
          : 'stand_bongkar';

      await TaskService().updateTask(widget.taskData['id'], {
        'status': statusBaru,
        kolomFoto: fileName,
        kolomStand: double.tryParse(_standController.text) ?? 0,
      });

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isSelesai = widget.taskData['status'] == 'Selesai';
<<<<<<< HEAD
    bool isBongkar = widget.taskData['status'].toString().contains(
      'Pembongkaran',
    );

=======
    bool isBongkar = widget.taskData['status'].toString().contains('Pembongkaran');
>>>>>>> d771f310c3aa1a2c1ac8c1ede9b4597798fd2c8b
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
              "Agenda: ${widget.taskData['no_agenda']}",
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
<<<<<<< HEAD
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
=======
                    _buildInfoRow(Icons.person_pin_rounded, "Nama Pemohon", widget.taskData['nama_pelanggan']),
                    
                    // DISPLAY: Nomor Telepon
                    Padding(
                      padding: const EdgeInsets.only(bottom: 18),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.blue.withOpacity(0.08), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.contact_phone, size: 20, color: Colors.blue)),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("Nomor Telepon Pelanggan", style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.w600)),
                                const SizedBox(height: 3),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(widget.taskData['no_telp'] ?? "-", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
                                    if (widget.taskData['no_telp'] != null)
                                      InkWell(
                                        onTap: _contactCustomer,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                          decoration: BoxDecoration(color: Colors.blue.shade700, borderRadius: BorderRadius.circular(20)),
                                          child: const Text("HUBUNGI", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    _buildInfoRow(Icons.map_rounded, "Alamat Lengkap", widget.taskData['alamat']),
                    _buildInfoRow(Icons.bolt_rounded, "Daya Terpasang", "${widget.taskData['daya']} VA"),
>>>>>>> d771f310c3aa1a2c1ac8c1ede9b4597798fd2c8b
                  ]),

                  const SizedBox(height: 16),

                  if (!isSelesai)
                    _buildSectionCard("INPUT HASIL LAPANGAN", [
                      const Text(
                        "Masukkan angka stand meter dan foto kwh meter sebagai bukti.",
                        style: TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                      const SizedBox(height: 20),
<<<<<<< HEAD

=======
>>>>>>> d771f310c3aa1a2c1ac8c1ede9b4597798fd2c8b
                      TextField(
                        controller: _standController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
<<<<<<< HEAD
                          labelText: isBongkar
                              ? "Stand Bongkar (KWH)"
                              : "Stand Pasang (KWH)",
=======
                          label: Text(isBongkar ? "Stand Bongkar (KWH)" : "Stand Pasang (KWH)"),
>>>>>>> d771f310c3aa1a2c1ac8c1ede9b4597798fd2c8b
                          hintText: "Contoh: 1250.50",
                          prefixIcon: const Icon(Icons.speed_rounded),
                          border: const OutlineInputBorder(),
                        ),
                      ),
<<<<<<< HEAD

=======
>>>>>>> d771f310c3aa1a2c1ac8c1ede9b4597798fd2c8b
                      const SizedBox(height: 20),
                      GestureDetector(
                        onTap: _showImageSourceDialog,
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
                                    const Text(
                                      "Ambil / Upload Foto Bukti",
                                      style: TextStyle(
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
<<<<<<< HEAD

=======
>>>>>>> d771f310c3aa1a2c1ac8c1ede9b4597798fd2c8b
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

                  const SizedBox(height: 16),

                  _buildSectionCard("BUKTI DOKUMENTASI & CETAK", [
                    _buildPhotoViewerWithEdit(
                      "FOTO PEMASANGAN",
                      checkPasang
                          ? _getPublicUrl(widget.taskData['foto_pemasangan'])
                          : null,
                      () => _showEditOptions(true),
                    ),
                    const SizedBox(height: 20),
                    _buildPhotoViewerWithEdit(
                      "FOTO PEMBONGKARAN",
                      checkBongkar
                          ? _getPublicUrl(widget.taskData['foto_pembongkaran'])
                          : null,
                      () => _showEditOptions(false),
                    ),
                    const Divider(height: 40),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade700,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _showSuplisiDialog,
                        icon: const Icon(
                          Icons.picture_as_pdf,
                          color: Colors.white,
                        ),
                        label: const Text(
                          "CETAK PDF SUPLISI",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ]),

                  const SizedBox(height: 16),

                  _buildSectionCard("TITIK LOKASI PENERANGAN", [
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

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

<<<<<<< HEAD
  // --- HELPER WIDGETS (IDENTIK DENGAN ASLI ANDA) ---

  Widget _buildPhotoViewerWithEdit(
    String title,
    String? url,
    VoidCallback onEdit,
  ) {
=======
  Widget _buildPhotoViewerWithEdit(String title, String? url, VoidCallback onEdit) {
>>>>>>> d771f310c3aa1a2c1ac8c1ede9b4597798fd2c8b
    bool hasUrl = url != null && url.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            if (hasUrl)
              IconButton(
                icon: const Icon(
                  Icons.edit_rounded,
                  color: Colors.orange,
                  size: 20,
                ),
                onPressed: onEdit,
              ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          height: 180,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: borderGrey, width: 2),
          ),
          child: hasUrl
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Image.network(
                    url,
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => const Icon(Icons.broken_image),
                  ),
                )
              : Center(
                  child: Icon(
                    Icons.image_not_supported,
                    color: Colors.grey[300],
                    size: 40,
                  ),
                ),
        ),
      ],
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
