import 'package:flutter/material.dart';
<<<<<<< HEAD
import 'package:http/http.dart' as http;
import 'dart:convert';
=======
import 'package:supabase_flutter/supabase_flutter.dart';
>>>>>>> EditArya
import 'package:intl/intl.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';
<<<<<<< HEAD
import '../main.dart';
=======
>>>>>>> EditArya
import '../models/user_model.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});
  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
<<<<<<< HEAD
  final idPelCtrl = TextEditingController(); // Nomor Agenda/Register
  final namaCtrl = TextEditingController(); // Nama Pemohon
  final alamatCtrl = TextEditingController(); // Alamat Lokasi
  final dayaCtrl = TextEditingController(); // Daya VA
  final MapController _mapController = MapController();

  DateTime? tglP;
  DateTime? tglB;
  LatLng _selectedLocation = const LatLng(
    -8.2045,
    111.0921,
  ); // Default: Pacitan
  String? selectedTeknisi;

  List<UserModel> availableTeknisi = [];
  bool isLoadingTeknisi = false;

  // FUNGSI PENCARIAN ALAMAT (DIPERBAIKI)
  Future<void> _searchFromAddress() async {
    if (alamatCtrl.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Isi alamat dulu!")));
      return;
    }

    try {
      // Menampilkan loading sederhana di bagian bawah
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Sedang mencari lokasi..."),
          duration: Duration(seconds: 1),
        ),
      );

      // Mencari koordinat dari teks alamat
      List<Location> locations = await locationFromAddress(alamatCtrl.text);

=======
  // Controller diperbarui (idPelCtrl ganti jadi agendaCtrl + tambahan E-min & Terbayar)
  final agendaCtrl = TextEditingController(); 
  final namaCtrl = TextEditingController();
  final alamatCtrl = TextEditingController();
  final eMinCtrl = TextEditingController(text: "0"); // Revisi: Input E-Min
  final kwhTerbayarCtrl = TextEditingController(text: "0"); // Revisi: Input Terbayar Awal
  final MapController _mapController = MapController();

  // Inisialisasi client Supabase
  final supabase = Supabase.instance.client;

  DateTime? tglP;
  DateTime? tglB;
  LatLng _selectedLocation = const LatLng(-8.2045, 111.0921); // Default ke Pacitan
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

  // --- LOGIKA LOKASI (GEOMAPPING) - TETAP UTUH 100% ---
  Future<void> _searchFromAddress() async {
    if (alamatCtrl.text.isEmpty) return;
    setState(() => isSearching = true);
    try {
      List<Location> locations = await locationFromAddress(alamatCtrl.text);
>>>>>>> EditArya
      if (locations.isNotEmpty) {
        setState(() {
          _selectedLocation = LatLng(
            locations.first.latitude,
            locations.first.longitude,
          );
<<<<<<< HEAD
          // Menggerakkan peta ke lokasi yang ditemukan
=======
>>>>>>> EditArya
          _mapController.move(_selectedLocation, 15.0);
        });
      }
    } catch (e) {
<<<<<<< HEAD
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Lokasi tidak ditemukan. Coba tambahkan nama kota (contoh: Arjosari Pacitan)",
          ),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

=======
      debugPrint("Lokasi tidak ditemukan: $e");
    } finally {
      setState(() => isSearching = false);
    }
  }

  Future<void> _getAddressFromLatLng(LatLng position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        setState(() {
          alamatCtrl.text =
              "${place.street}, ${place.subLocality}, ${place.locality}";
        });
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  // --- LOGIKA FILTER TEKNISI (MAX 2 TUGAS PER HARI) - TETAP UTUH 100% ---
>>>>>>> EditArya
  Future<void> _filterTeknisi(DateTime date) async {
    setState(() {
      isLoadingTeknisi = true;
      selectedTeknisi = null;
<<<<<<< HEAD
    });

    try {
      String formattedDate = DateFormat('yyyy-MM-dd').format(date);
      final response = await http.get(
        Uri.parse("$baseUrl?action=get_busy_teknisi&tanggal=$formattedDate"),
      );

      if (response.statusCode == 200) {
        List<dynamic> busyUsernames = jsonDecode(response.body);
        setState(() {
          availableTeknisi = listUser.where((u) {
            return u.role == "teknisi" && !busyUsernames.contains(u.username);
          }).toList();
          isLoadingTeknisi = false;
        });
      }
    } catch (e) {
      setState(() => isLoadingTeknisi = false);
    }
  }

  Future<void> _kirimData() async {
    if (tglP == null ||
        tglB == null ||
        idPelCtrl.text.isEmpty ||
        selectedTeknisi == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Lengkapi data penugasan!")));
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final response = await http.post(
        Uri.parse("$baseUrl?action=add_task"),
        body: {
          'id_pelanggan': idPelCtrl.text,
          'nama_pelanggan': namaCtrl.text,
          'alamat': alamatCtrl.text,
          'daya': dayaCtrl.text,
          'tgl_pasang': DateFormat('yyyy-MM-dd').format(tglP!),
          'tgl_bongkar': DateFormat('yyyy-MM-dd').format(tglB!),
          'teknisi': selectedTeknisi,
          'latitude': _selectedLocation.latitude.toString(),
          'longitude': _selectedLocation.longitude.toString(),
        },
      );
=======
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
        if (task['tgl_pasang'] == formattedDate) {
          workloadMap[tech] = (workloadMap[tech] ?? 0) + 1;
        }
        if (task['tgl_bongkar'] == formattedDate) {
          workloadMap[tech] = (workloadMap[tech] ?? 0) + 1;
        }
      }

      final List<String> overlimitUsernames = workloadMap.entries
          .where((entry) => entry.value >= 2)
          .map((entry) => entry.key)
          .toList();

      final allTeknisiResponse = await supabase
          .from('users')
          .select()
          .eq('role', 'teknisi');

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
      debugPrint("Error Filter Teknisi: $e");
      setState(() => isLoadingTeknisi = false);
    }
  }

  // --- SIMPAN DATA KE SUPABASE (REVISI KOLOM DATABASE) ---
  Future<void> _kirimData() async {
    if (tglP == null ||
        tglB == null ||
        agendaCtrl.text.isEmpty ||
        selectedTeknisi == null ||
        selectedDaya == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Lengkapi semua data!")));
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await supabase.from('pesta_tasks').insert({
        'no_agenda': agendaCtrl.text, // Perubahan kolom
        'nama_pelanggan': namaCtrl.text,
        'alamat': alamatCtrl.text,
        'daya': selectedDaya,
        'e_min_kwh': double.tryParse(eMinCtrl.text) ?? 0, // Kolom Baru
        'kwh_terbayar': double.tryParse(kwhTerbayarCtrl.text) ?? 0, // Kolom Baru
        'stand_pasang': 0, // Inisialisasi awal 0
        'stand_bongkar': 0, // Inisialisasi awal 0
        'tgl_pasang': DateFormat('yyyy-MM-dd').format(tglP!),
        'tgl_bongkar': DateFormat('yyyy-MM-dd').format(tglB!),
        'teknisi': selectedTeknisi,
        'latitude': _selectedLocation.latitude.toString(),
        'longitude': _selectedLocation.longitude.toString(),
        'status': 'Menunggu Pemasangan',
      });
>>>>>>> EditArya

      if (!mounted) return;
      Navigator.pop(context);

<<<<<<< HEAD
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Penugasan PESTA Berhasil Disimpan!")),
        );
        Navigator.pop(context);
      }
=======
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Berhasil Ditugaskan!"),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
>>>>>>> EditArya
    } catch (e) {
      if (mounted) Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
<<<<<<< HEAD
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
=======
      ).showSnackBar(SnackBar(content: Text("Error Supabase: $e")));
>>>>>>> EditArya
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
<<<<<<< HEAD
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Input Penugasan Rill"),
        backgroundColor: const Color(0xFF1A56F0),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            "DATA PERMINTAAN PLN",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
          ),
          const SizedBox(height: 15),
          TextField(
            controller: idPelCtrl,
            decoration: const InputDecoration(
              labelText: "Nomor Agenda / Register",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 15),
          TextField(
            controller: namaCtrl,
            decoration: const InputDecoration(
              labelText: "Nama Pemohon (Sesuai PDF)",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 15),

          // TextField Alamat dengan tombol cari Aktif
          TextField(
            controller: alamatCtrl,
            decoration: InputDecoration(
              labelText: "Alamat Lokasi Proyek",
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: const Icon(Icons.search, color: Colors.blue),
                onPressed: _searchFromAddress, // Memanggil fungsi cari
              ),
            ),
            onSubmitted: (_) =>
                _searchFromAddress(), // Cari juga saat tekan 'Enter' di keyboard
          ),
          const SizedBox(height: 15),

          TextField(
            controller: dayaCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: "Daya VA",
              border: OutlineInputBorder(),
              suffixText: "VA",
            ),
          ),
          const SizedBox(height: 25),

          const Text(
            "PENJADWALAN",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
          ),
          const SizedBox(height: 10),
          _buildDatePicker("Mulai Pasang", tglP, (date) {
            setState(() => tglP = date);
            _filterTeknisi(date);
          }, Colors.blue.shade50),
          const SizedBox(height: 10),
          _buildDatePicker(
            "Tgl Bongkar",
            tglB,
            (date) => setState(() => tglB = date),
            Colors.orange.shade50,
          ),

          const SizedBox(height: 20),
          isLoadingTeknisi
              ? const LinearProgressIndicator()
              : DropdownButtonFormField<String>(
                  value: selectedTeknisi,
                  hint: const Text("Pilih Teknisi Tersedia"),
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  items: availableTeknisi
                      .map(
                        (u) => DropdownMenuItem(
                          value: u.username,
                          child: Text(u.nama),
                        ),
                      )
                      .toList(),
                  onChanged: (val) => setState(() => selectedTeknisi = val),
                ),

          const SizedBox(height: 30),
          const Text(
            "TITIK LOKASI PADA PETA",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 200,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _selectedLocation,
                  initialZoom: 13.0,
                  onTap: (p, point) =>
                      setState(() => _selectedLocation = point),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _selectedLocation,
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
          const SizedBox(height: 30),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A56F0),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 55),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            onPressed: _kirimData,
            child: const Text(
              "SIMPAN & TUGASKAN",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 20),
=======
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
            _buildSectionCard(
              icon: Icons.person_outline,
              title: "Informasi Pelanggan",
              children: [
                _buildLabel("Nomor Agenda"),
                _buildTextField(agendaCtrl, "Masukkan Nomor Agenda"),
                const SizedBox(height: 16),
                _buildLabel("Nama Pelanggan"),
                _buildTextField(namaCtrl, "Nama lengkap pemohon"),
                const SizedBox(height: 16),
                
                // REVISI: Penambahan Row untuk E-Min dan Terbayar
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel("E Min KWH"),
                          _buildTextField(eMinCtrl, "0", isNumber: true),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel("KWH Terbayar"),
                          _buildTextField(kwhTerbayarCtrl, "0", isNumber: true),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                _buildLabel("Pilih Daya (VA)"),
                DropdownButtonFormField<String>(
                  value: selectedDaya,
                  hint: const Text("Pilih besaran daya"),
                  decoration: _inputDecoration("Minimum 5500 VA"),
                  items: dayaOptions.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text("$value VA"),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => selectedDaya = val),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSectionCard(
              icon: Icons.calendar_month_outlined,
              title: "Penjadwalan & Teknisi",
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel("Tgl Pasang"),
                          _buildDatePicker(
                            value: tglP,
                            hint: "Mulai",
                            onTap: () async {
                              DateTime? p = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime.now(),
                                lastDate: DateTime(2030),
                              );
                              if (p != null) {
                                setState(() => tglP = p);
                                _filterTeknisi(p); 
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel("Tgl Bongkar"),
                          _buildDatePicker(
                            value: tglB,
                            hint: "Selesai",
                            onTap: () async {
                              DateTime? p = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime.now(),
                                lastDate: DateTime(2030),
                              );
                              if (p != null) setState(() => tglB = p);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildLabel("Pilih Teknisi"),
                isLoadingTeknisi
                    ? const LinearProgressIndicator()
                    : DropdownButtonFormField<String>(
                        value: selectedTeknisi,
                        hint: Text(
                          availableTeknisi.isEmpty && tglP != null
                              ? "Semua teknisi penuh di tanggal ini"
                              : "Pilih Teknisi",
                        ),
                        decoration: _inputDecoration("Pilih Teknisi"),
                        items: availableTeknisi
                            .map(
                              (u) => DropdownMenuItem(
                                value: u.username,
                                child: Text(u.nama),
                              ),
                            )
                            .toList(),
                        onChanged: (val) =>
                            setState(() => selectedTeknisi = val),
                      ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSectionCard(
              icon: Icons.map_outlined,
              title: "Lokasi Pemasangan",
              children: [
                _buildLabel("Alamat Lengkap"),
                TextField(
                  controller: alamatCtrl,
                  maxLines: 2,
                  decoration: _inputDecoration("Cari alamat...").copyWith(
                    suffixIcon: isSearching
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : IconButton(
                            icon: const Icon(Icons.search),
                            onPressed: _searchFromAddress,
                          ),
                  ),
                  onSubmitted: (_) => _searchFromAddress(),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 250,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      children: [
                        FlutterMap(
                          mapController: _mapController,
                          options: MapOptions(
                            initialCenter: _selectedLocation,
                            initialZoom: 14.0,
                            onTap: (p, point) {
                              setState(() => _selectedLocation = point);
                              _getAddressFromLatLng(point);
                            },
                          ),
                          children: [
                            TileLayer(
                              urlTemplate:
                                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            ),
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: _selectedLocation,
                                  width: 45,
                                  height: 45,
                                  child: const Icon(
                                    Icons.location_on,
                                    color: Colors.red,
                                    size: 45,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        _buildMapOverlayTip(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomButton(),
    );
  }

  // --- SEMUA WIDGET HELPERS ASLI ANDA TETAP DI SINI ---
  Widget _buildMapOverlayTip() {
    return Positioned(
      top: 10,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
          borderRadius: BorderRadius.circular(30),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.touch_app, color: Colors.white, size: 14),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                "Klik peta untuk memindahkan marker",
                style: TextStyle(color: Colors.white, fontSize: 11),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
        onPressed: _kirimData,
        child: const Text(
          "SIMPAN PENGAJUAN PESTA",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderGrey),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.blueGrey, size: 22),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const Divider(height: 32, color: Color(0xFFEEEEEE)),
          ...children,
>>>>>>> EditArya
        ],
      ),
    );
  }

<<<<<<< HEAD
  Widget _buildDatePicker(
    String label,
    DateTime? value,
    Function(DateTime) onSelect,
    Color color,
  ) {
    return ListTile(
      tileColor: color,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      title: Text(
        value == null ? "Set $label" : DateFormat('dd-MM-yyyy').format(value),
      ),
      trailing: const Icon(Icons.calendar_month),
      onTap: () async {
        DateTime? picked = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime.now(),
          lastDate: DateTime(2030),
        );
        if (picked != null) onSelect(picked);
      },
    );
  }
}
=======
  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.black54,
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController ctrl,
    String hint, {
    bool isNumber = false,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
      decoration: _inputDecoration(hint),
    );
  }

  Widget _buildDatePicker({
    DateTime? value,
    required String hint,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: _inputDecoration(hint).copyWith(
          suffixIcon: const Icon(
            Icons.calendar_month,
            size: 20,
            color: Colors.grey,
          ),
        ),
        child: Text(
          value == null ? hint : DateFormat('dd/MM/yyyy').format(value),
          style: const TextStyle(fontSize: 14),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      filled: true,
      fillColor: inputGrey,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: borderGrey),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: borderGrey),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: primaryBlue),
      ),
    );
  }
}
>>>>>>> EditArya
