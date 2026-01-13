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
  LatLng _selectedLocation = const LatLng(-8.2045, 111.0921);
  String? selectedTeknisi;
  List<UserModel> availableTeknisi = [];
  bool isLoadingTeknisi = false;

  Future<void> _searchFromAddress() async {
    if (alamatCtrl.text.isEmpty) return;
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Lokasi tidak ditemukan!")));
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
      ).showSnackBar(const SnackBar(content: Text("Lengkapi data!")));
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
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.red,
          ),
        );
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
      appBar: AppBar(
        title: const Text("Input Penugasan Rill"),
        backgroundColor: const Color(0xFF1A56F0),
        foregroundColor: Colors.white,
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
              labelText: "Nama Pemohon",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 15),
          TextField(
            controller: alamatCtrl,
            decoration: InputDecoration(
              labelText: "Alamat Lokasi",
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: const Icon(Icons.search),
                onPressed: _searchFromAddress,
              ),
            ),
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
          ListTile(
            tileColor: Colors.blue.shade50,
            title: Text(
              tglP == null
                  ? "Set Mulai Pasang"
                  : DateFormat('dd-MM-yyyy').format(tglP!),
            ),
            trailing: const Icon(Icons.calendar_month),
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
          const SizedBox(height: 10),
          ListTile(
            tileColor: Colors.orange.shade50,
            title: Text(
              tglB == null
                  ? "Set Tgl Bongkar"
                  : DateFormat('dd-MM-yyyy').format(tglB!),
            ),
            trailing: const Icon(Icons.calendar_month),
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
            ),
            onPressed: _kirimData,
            child: const Text(
              "SIMPAN & TUGASKAN",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
