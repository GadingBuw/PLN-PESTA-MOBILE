import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';
import '../main.dart';
import '../models/user_model.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});
  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final idPelCtrl = TextEditingController();
  final namaCtrl = TextEditingController();
  final alamatCtrl = TextEditingController();
  final dayaCtrl = TextEditingController();
  final MapController _mapController = MapController();

  DateTime? tglP;
  DateTime? tglB;
  LatLng _selectedLocation = const LatLng(-6.2000, 106.8166);
  String? selectedTeknisi;
  List<UserModel> availableTeknisi = [];
  bool isLoadingTeknisi = false;
  bool isSearching = false;

  // Warna Bertema Abu-abu & Biru
  final Color primaryBlue = const Color(0xFF1A56F0);
  final Color bgGrey = const Color(0xFFF0F2F5); // Background utama abu-abu
  final Color inputGrey = const Color(
    0xFFF8F9FA,
  ); // Background input abu-abu sangat muda
  final Color borderGrey = const Color(0xFFE0E4E8); // Warna border halus

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
          _mapController.move(_selectedLocation, 15.0);
        });
      }
    } catch (e) {
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

  Future<void> _filterTeknisi(DateTime date) async {
    setState(() {
      isLoadingTeknisi = true;
      selectedTeknisi = null;
    });
    try {
      String formattedDate = DateFormat('yyyy-MM-dd').format(date);
      final response = await http.get(
        Uri.parse("$baseUrl?action=get_busy_teknisi&tanggal=$formattedDate"),
      );
      if (response.statusCode == 200) {
        List<dynamic> busyUsernames = jsonDecode(response.body);
        setState(() {
          availableTeknisi = listUser
              .where(
                (u) =>
                    u.role == "teknisi" && !busyUsernames.contains(u.username),
              )
              .toList();
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
      ).showSnackBar(const SnackBar(content: Text("Lengkapi semua data!")));
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
      final result = jsonDecode(response.body);
      if (!mounted) return;
      Navigator.pop(context);
      if (result['status'] == "success") {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Berhasil Ditugaskan!"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
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
            // SEKSI 1: INFORMASI PELANGGAN
            _buildSectionCard(
              icon: Icons.person_outline,
              title: "Informasi Pelanggan",
              children: [
                _buildLabel("ID Pelanggan"),
                _buildTextField(idPelCtrl, "PLG-2024-XXX"),
                const SizedBox(height: 16),
                _buildLabel("Nama Pelanggan"),
                _buildTextField(namaCtrl, "Nama lengkap pelanggan"),
                const SizedBox(height: 16),
                _buildLabel("Daya (VA)"),
                _buildTextField(dayaCtrl, "Contoh: 900", isNumber: true),
              ],
            ),
            const SizedBox(height: 16),

            // SEKSI 2: PENJADWALAN & TEKNISI
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

            // SEKSI 3: LOKASI PEMASANGAN
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

  // --- UI Components ---
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
          "SIMPAN PENGAJUAN",
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
        border: Border.all(color: borderGrey), // Border abu-abu halus
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
        ],
      ),
    );
  }

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
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
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
      fillColor: inputGrey, // Warna input abu-abu muda
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
