import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../main.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  // Controller Input
  final idPelCtrl = TextEditingController(text: "PLG-2026-XXX");
  final namaCtrl = TextEditingController();
  final alamatCtrl = TextEditingController();
  final dayaCtrl = TextEditingController();
  final tglPasangCtrl = TextEditingController();
  final tglBongkarCtrl = TextEditingController();
  final searchCtrl = TextEditingController(); // Controller untuk search alamat

  // State Teknisi dari API
  String? _selectedTeknisi;
  List<dynamic> _listTeknisi = [];
  bool _isFetchingTeknisi = true;

  // State Peta
  final MapController _mapController = MapController();
  LatLng _selectedLocation = const LatLng(-6.2000, 106.8166);

  // Tema Warna
  final Color primaryBlue = const Color(0xFF1A56F0);
  final Color bgLight = const Color(0xFFF8F9FB);
  final List<String> listDaya = [
    "5500",
    "6600",
    "7700",
    "11000",
    "13200",
    "16500",
    "23000",
  ];

  @override
  void initState() {
    super.initState();
    _fetchTeknisi();
  }

  // --- FITUR SEARCH ALAMAT KE PETA ---
  Future<void> _searchFromAddress() async {
    if (searchCtrl.text.isEmpty) return;
    try {
      List<Location> locations = await locationFromAddress(searchCtrl.text);
      if (locations.isNotEmpty) {
        setState(() {
          _selectedLocation = LatLng(
            locations.first.latitude,
            locations.first.longitude,
          );
          _mapController.move(_selectedLocation, 15.0);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Alamat tidak ditemukan")));
    }
  }

  // --- AMBIL DATA TEKNISI DARI API ---
  Future<void> _fetchTeknisi() async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl?action=get_monitoring"),
      );
      if (response.statusCode == 200) {
        setState(() {
          _listTeknisi = jsonDecode(response.body);
          _isFetchingTeknisi = false;
        });
      }
    } catch (e) {
      setState(() => _isFetchingTeknisi = false);
    }
  }

  // --- SIMPAN KE DATABASE ---
  Future<void> _saveData() async {
    if (namaCtrl.text.isEmpty ||
        _selectedTeknisi == null ||
        tglPasangCtrl.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Lengkapi semua data!")));
      return;
    }

    try {
      var response = await http.post(
        Uri.parse("$baseUrl?action=add_task"),
        body: {
          "id_pelanggan": idPelCtrl.text,
          "nama_pelanggan": namaCtrl.text,
          "alamat": alamatCtrl.text,
          "daya": dayaCtrl.text,
          "tgl_pasang": tglPasangCtrl.text,
          "tgl_bongkar": tglBongkarCtrl.text,
          "teknisi": _selectedTeknisi,
          "latitude": _selectedLocation.latitude.toString(),
          "longitude": _selectedLocation.longitude.toString(),
        },
      );

      if (response.statusCode == 200) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Pengajuan Berhasil Disimpan")),
          );
        }
      }
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  Future<void> _selectDate(
    BuildContext context,
    TextEditingController ctrl,
  ) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() => ctrl.text = DateFormat('yyyy-MM-dd').format(picked));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgLight,
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.only(
              top: 50,
              left: 10,
              right: 20,
              bottom: 20,
            ),
            width: double.infinity,
            color: primaryBlue,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Form Pengajuan",
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    Text(
                      "PESTA Baru",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(15),
              children: [
                _buildCardSection(
                  icon: Icons.person_outline,
                  title: "Informasi Pelanggan",
                  children: [
                    _buildLabel("ID Pelanggan"),
                    _buildTextField(idPelCtrl, "PLG-2026-XXX"),
                    const SizedBox(height: 15),
                    _buildLabel("Nama Pelanggan"),
                    _buildTextField(namaCtrl, "Nama Pelanggan"),
                    const SizedBox(height: 15),
                    _buildLabel("Daya (VA)"),
                    _buildDropdownDaya(),
                  ],
                ),
                const SizedBox(height: 15),
                _buildCardSection(
                  icon: Icons.engineering_outlined,
                  title: "Penjadwalan & Teknisi",
                  iconColor: Colors.orange,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel("Tgl Pasang"),
                              _buildDateField(tglPasangCtrl),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel("Tgl Bongkar"),
                              _buildDateField(tglBongkarCtrl),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    _buildLabel("Pilih Teknisi Lapangan"),
                    _buildDropdownTeknisi(),
                  ],
                ),
                const SizedBox(height: 15),
                _buildCardSection(
                  icon: Icons.location_on_outlined,
                  title: "Lokasi Pemasangan",
                  iconColor: Colors.redAccent,
                  children: [
                    _buildLabel("Cari Alamat untuk Peta"),
                    _buildSearchField(), // FITUR SEARCH TETAP ADA
                    const SizedBox(height: 15),
                    _buildLabel("Alamat Lengkap (Manual)"),
                    _buildTextField(alamatCtrl, "Jl. ...", maxLines: 2),
                    const SizedBox(height: 15),
                    _buildMapWidget(),
                  ],
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
      bottomSheet: _buildSaveButton(),
    );
  }

  // --- WIDGET SEARCH FIELD ---
  Widget _buildSearchField() {
    return TextField(
      controller: searchCtrl,
      onSubmitted: (_) => _searchFromAddress(),
      decoration: InputDecoration(
        hintText: "Ketik alamat lalu tekan cari...",
        prefixIcon: const Icon(Icons.search, color: Colors.blue),
        suffixIcon: IconButton(
          icon: const Icon(Icons.send, color: Colors.blue),
          onPressed: _searchFromAddress,
        ),
        filled: true,
        fillColor: Colors.white,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: primaryBlue),
        ),
      ),
    );
  }

  // --- DROPDOWN TEKNISI DARI API ---
  Widget _buildDropdownTeknisi() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: _isFetchingTeknisi
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(10),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          : DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedTeknisi,
                hint: const Text(
                  "Pilih Nama Teknisi",
                  style: TextStyle(color: Colors.black26, fontSize: 14),
                ),
                isExpanded: true,
                items: _listTeknisi.map((item) {
                  return DropdownMenuItem<String>(
                    value: item['teknisi'],
                    child: Text(item['teknisi']),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedTeknisi = val),
              ),
            ),
    );
  }

  // Widget pendukung lainnya
  Widget _buildDropdownDaya() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: dayaCtrl.text.isEmpty ? null : dayaCtrl.text,
          hint: const Text(
            "Pilih Daya VA",
            style: TextStyle(color: Colors.black26, fontSize: 14),
          ),
          isExpanded: true,
          items: listDaya
              .map(
                (val) => DropdownMenuItem(value: val, child: Text("$val VA")),
              )
              .toList(),
          onChanged: (val) => setState(() => dayaCtrl.text = val!),
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: bgLight,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          minimumSize: const Size(double.infinity, 55),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: _saveData,
        child: const Text(
          "Simpan Pengajuan",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildCardSection({
    required IconData icon,
    required String title,
    required List<Widget> children,
    Color iconColor = Colors.blue,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 22),
              const SizedBox(width: 10),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: const TextStyle(fontSize: 12, color: Colors.black54),
    ),
  );
  Widget _buildTextField(
    TextEditingController ctrl,
    String hint, {
    int maxLines = 1,
  }) => TextField(
    controller: ctrl,
    maxLines: maxLines,
    decoration: InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: primaryBlue),
      ),
    ),
  );
  Widget _buildDateField(TextEditingController ctrl) => InkWell(
    onTap: () => _selectDate(context, ctrl),
    child: IgnorePointer(child: _buildTextField(ctrl, "YYYY-MM-DD")),
  );
  Widget _buildMapWidget() => Container(
    height: 200,
    decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: _selectedLocation,
          initialZoom: 13,
          onTap: (p, point) => setState(() => _selectedLocation = point),
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
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
  );
}
