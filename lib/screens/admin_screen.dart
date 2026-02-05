import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';
import '../models/user_model.dart';

class AdminScreen extends StatefulWidget {
  final UserModel user; // Penerimaan data user agar tidak merah
  const AdminScreen({super.key, required this.user});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  // --- SEMUA CONTROLLER FORM (Lengkap 100%) ---
  final agendaCtrl = TextEditingController(); 
  final namaCtrl = TextEditingController();
  final noTelpCtrl = TextEditingController(); 
  final alamatCtrl = TextEditingController();
  final eMinCtrl = TextEditingController(text: "0"); 
  final kwhTerbayarCtrl = TextEditingController(text: "0"); 
  
  // --- CONTROLLER MAPS ---
  final MapController _mapController = MapController();
  LatLng _selectedLocation = const LatLng(-8.2045, 111.0921); // Default Pacitan

  final supabase = Supabase.instance.client;

  DateTime? tglP;
  DateTime? tglB;
  String? selectedTeknisi;
  String? selectedDaya;
  List<UserModel> availableTeknisi = [];
  bool isLoadingTeknisi = false;
  bool isSearching = false;

  final List<String> dayaOptions = [
    "5500", "6600", "7700", "10600", "13200", "16500", "23000",
    "33000", "41500", "53000", "66000", "77000", "82500",
    "105000", "131000", "164000", "197000",
  ];

  final Color primaryBlue = const Color(0xFF1A56F0);
  final Color bgGrey = const Color(0xFFF0F2F5);
  final Color inputGrey = const Color(0xFFF8F9FA);
  final Color borderGrey = const Color(0xFFE0E4E8);

  // FITUR: Cari lokasi dari teks alamat dan pindahkan kamera peta
  Future<void> _searchFromAddress() async {
    if (alamatCtrl.text.isEmpty) return;
    setState(() => isSearching = true);
    try {
      List<Location> locations = await locationFromAddress(alamatCtrl.text);
      if (locations.isNotEmpty) {
        setState(() {
          _selectedLocation = LatLng(
            locations.first.latitude,
            locations.first.longitude,
          );
          // Gerakkan kamera peta ke lokasi pencarian
          _mapController.move(_selectedLocation, 15.0);
        });
      }
    } catch (e) {
      debugPrint("Lokasi tidak ditemukan: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Alamat tidak ditemukan pada peta")),
        );
      }
    } finally {
      setState(() => isSearching = false);
    }
  }

  // FITUR: Ambil alamat (teks) dari titik koordinat saat peta diketuk
  Future<void> _getAddressFromLatLng(LatLng position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        setState(() {
          // Format alamat lengkap otomatis
          alamatCtrl.text =
              "${place.street}, ${place.subLocality}, ${place.locality}, ${place.subAdministrativeArea}";
        });
      }
    } catch (e) {
      debugPrint("Gagal mengambil teks alamat: $e");
    }
  }

  // FITUR: Filter Teknisi (DIPERBAIKI UNTUK SUPERADMIN)
  Future<void> _filterTeknisi(DateTime date) async {
    setState(() {
      isLoadingTeknisi = true;
      selectedTeknisi = null;
      availableTeknisi = [];
    });

    try {
      String formattedDate = DateFormat('yyyy-MM-dd').format(date);
      
      final responseTasks = await supabase
          .from('pesta_tasks')
          .select('teknisi, tgl_pasang, tgl_bongkar')
          .or('tgl_pasang.eq.$formattedDate,tgl_bongkar.eq.$formattedDate');

      final List<dynamic> tasksOnDate = responseTasks as List;
      Map<String, int> workloadMap = {};

      for (var task in tasksOnDate) {
        String tech = task['teknisi'].toString();
        if (task['tgl_pasang'] == formattedDate) workloadMap[tech] = (workloadMap[tech] ?? 0) + 1;
        if (task['tgl_bongkar'] == formattedDate) workloadMap[tech] = (workloadMap[tech] ?? 0) + 1;
      }

      final List<String> overlimitUsernames = workloadMap.entries
          .where((entry) => entry.value >= 2)
          .map((entry) => entry.key)
          .toList();

      // LOGIKA BYPASS UNIT UNTUK SUPERADMIN
      var query = supabase.from('users').select().eq('role', 'teknisi');
      
      // Jika bukan superadmin, maka hanya cari teknisi di unitnya sendiri
      if (widget.user.role.toLowerCase() != 'superadmin') {
        query = query.eq('unit', widget.user.unit);
      }

      final allTeknisiResponse = await query;

      final List<UserModel> allTeknisi = (allTeknisiResponse as List)
          .map((u) => UserModel.fromMap(u))
          .toList();

      setState(() {
        availableTeknisi = allTeknisi
            .where((u) => !overlimitUsernames.contains(u.username))
            .toList();
        isLoadingTeknisi = false;
      });
    } catch (e) {
      debugPrint("Error: $e");
      setState(() => isLoadingTeknisi = false);
    }
  }

  // FITUR: Kirim Data Penugasan (DIPERBAIKI TAG UNITNYA)
  Future<void> _kirimData() async {
    if (tglP == null || tglB == null || agendaCtrl.text.isEmpty || 
        noTelpCtrl.text.isEmpty || selectedTeknisi == null || selectedDaya == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Mohon lengkapi semua field!")));
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Ambil data teknisi terpilih untuk mendapatkan unit aslinya (Penting buat Superadmin)
      final tech = availableTeknisi.firstWhere((t) => t.username == selectedTeknisi);

      await supabase.from('pesta_tasks').insert({
        'no_agenda': agendaCtrl.text,
        'nama_pelanggan': namaCtrl.text,
        'no_telp': noTelpCtrl.text,
        'alamat': alamatCtrl.text,
        'daya': selectedDaya,
        'e_min_kwh': double.tryParse(eMinCtrl.text) ?? 0,
        'kwh_terbayar': double.tryParse(kwhTerbayarCtrl.text) ?? 0,
        'stand_pasang': 0,
        'stand_bongkar': 0,
        'tgl_pasang': DateFormat('yyyy-MM-dd').format(tglP!),
        'tgl_bongkar': DateFormat('yyyy-MM-dd').format(tglB!),
        'teknisi': selectedTeknisi,
        'latitude': _selectedLocation.latitude.toString(),
        'longitude': _selectedLocation.longitude.toString(),
        'status': 'Menunggu Pemasangan',
        // TUGAS DI-TAG KE UNIT TEKNISI (Biar muncul di Dashboard Unit yang bersangkutan)
        'unit': tech.unit, 
      });

      if (!mounted) return;
      Navigator.pop(context); // Tutup loading

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Penugasan Berhasil Disimpan!"), backgroundColor: Colors.green),
      );
      Navigator.pop(context); // Kembali ke Home
    } catch (e) {
      if (mounted) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Database Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgGrey,
      appBar: AppBar(
        title: const Text(
          "Form Pengajuan PESTA Baru",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // --- KARTU INFORMASI PELANGGAN ---
            _buildSectionCard(
              icon: Icons.person_outline,
              title: "Informasi Pelanggan (ULP ${widget.user.unit})",
              children: [
                _buildLabel("Nomor Agenda"),
                _buildTextField(agendaCtrl, "Masukkan Nomor Agenda"),
                const SizedBox(height: 16),
                _buildLabel("Nama Pelanggan"),
                _buildTextField(namaCtrl, "Nama lengkap pemohon"),
                const SizedBox(height: 16),
                _buildLabel("Nomor Telepon / WA"),
                _buildTextField(noTelpCtrl, "Contoh: 081234567XXX", isNumber: true),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_buildLabel("E Min KWH"), _buildTextField(eMinCtrl, "0", isNumber: true)])),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_buildLabel("KWH Terbayar"), _buildTextField(kwhTerbayarCtrl, "0", isNumber: true)])),
                  ],
                ),
                const SizedBox(height: 16),
                _buildLabel("Pilih Daya (VA)"),
                DropdownButtonFormField<String>(
                  value: selectedDaya,
                  hint: const Text("Pilih besaran daya"),
                  decoration: _inputDecoration("Besaran VA"),
                  items: dayaOptions.map((v) => DropdownMenuItem(value: v, child: Text("$v VA"))).toList(),
                  onChanged: (val) => setState(() => selectedDaya = val),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // --- KARTU PENJADWALAN ---
            _buildSectionCard(
              icon: Icons.calendar_month_outlined,
              title: "Penjadwalan & Teknisi",
              children: [
                Row(
                  children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_buildLabel("Tgl Pasang"), _buildDatePicker(value: tglP, hint: "Mulai", onTap: () async {
                      DateTime? p = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime(2030));
                      if (p != null) { setState(() => tglP = p); _filterTeknisi(p); }
                    })])),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_buildLabel("Tgl Bongkar"), _buildDatePicker(value: tglB, hint: "Selesai", onTap: () async {
                      DateTime? p = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime(2030));
                      if (p != null) setState(() => tglB = p);
                    })])),
                  ],
                ),
                const SizedBox(height: 16),
                _buildLabel("Pilih Teknisi"),
                isLoadingTeknisi 
                  ? const LinearProgressIndicator() 
                  : DropdownButtonFormField<String>(
                      value: selectedTeknisi,
                      hint: const Text("Pilih Petugas Lapangan"),
                      decoration: _inputDecoration("Nama Teknisi"),
                      items: availableTeknisi.map((u) => DropdownMenuItem(value: u.username, child: Text("${u.nama} (${u.unit})"))).toList(),
                      onChanged: (val) => setState(() => selectedTeknisi = val),
                    ),
              ],
            ),
            const SizedBox(height: 16),

            // --- KARTU LOKASI (DENGAN FIX ACCESS BLOCKED) ---
            _buildSectionCard(
              icon: Icons.map_outlined,
              title: "Lokasi Pemasangan",
              children: [
                _buildLabel("Alamat Lengkap"),
                TextField(
                  controller: alamatCtrl,
                  maxLines: 2,
                  decoration: _inputDecoration("Cari alamat atau geser pin peta...").copyWith(
                    suffixIcon: isSearching 
                      ? const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2))
                      : IconButton(icon: const Icon(Icons.search), onPressed: _searchFromAddress),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 250,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: _selectedLocation,
                        initialZoom: 14.0,
                        onTap: (tapPosition, point) {
                          setState(() => _selectedLocation = point);
                          _getAddressFromLatLng(point); // Otomatis update teks alamat
                        },
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          // SOLUSI: Menggunakan UserAgent yang lebih Unik agar server OSM tidak memblokir
                          userAgentPackageName: 'id.gading.pesta.mobile.pln.app', 
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: _selectedLocation,
                              width: 45, height: 45,
                              child: const Icon(Icons.location_on, color: Colors.red, size: 45),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                const Center(child: Text("Ketuk peta untuk memindahkan marker lokasi", style: TextStyle(fontSize: 10, color: Colors.grey))),
              ],
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomButton(),
    );
  }

  // --- WIDGET KOMPONEN UI ---

  Widget _buildSectionCard({required IconData icon, required String title, required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: borderGrey)),
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Icon(icon, color: Colors.blueGrey, size: 22), const SizedBox(width: 8), Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87))]),
        const Divider(height: 32, color: Color(0xFFEEEEEE)),
        ...children,
      ]),
    );
  }

  Widget _buildLabel(String text) => Padding(padding: const EdgeInsets.only(bottom: 6), child: Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black54)));

  Widget _buildTextField(TextEditingController ctrl, String hint, {bool isNumber = false}) {
    return TextField(controller: ctrl, keyboardType: isNumber ? TextInputType.number : TextInputType.text, decoration: _inputDecoration(hint));
  }

  Widget _buildDatePicker({DateTime? value, required String hint, VoidCallback? onTap}) {
    return InkWell(onTap: onTap, child: InputDecorator(decoration: _inputDecoration(hint).copyWith(suffixIcon: const Icon(Icons.calendar_month, size: 20, color: Colors.grey)), child: Text(value == null ? hint : DateFormat('dd/MM/yyyy').format(value), style: const TextStyle(fontSize: 14))));
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint, filled: true, fillColor: inputGrey,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: borderGrey)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: borderGrey)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: primaryBlue)),
    );
  }

  Widget _buildBottomButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))]),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: primaryBlue, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 54), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0),
        onPressed: _kirimData,
        child: const Text("SIMPAN PENGAJUAN PESTA", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }
}