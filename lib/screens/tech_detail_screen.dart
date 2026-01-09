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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Ambil foto bukti!")));
      return;
    }

    // LOGIKA TANGGAL: HANYA BOLEH HARI INI ATAU TELAT
    DateTime todayDate = DateTime.parse(DateFormat('yyyy-MM-dd').format(DateTime.now()));
    String status = widget.taskData['status'];
    DateTime tglRencana = DateTime.parse(status == 'Menunggu Pemasangan' ? widget.taskData['tgl_pasang'] : widget.taskData['tgl_bongkar']);

    if (tglRencana.isAfter(todayDate)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Belum masuk jadwal pengerjaan!"), backgroundColor: Colors.orange));
      return;
    }

    setState(() => _loading = true);
    try {
      var req = http.MultipartRequest('POST', Uri.parse("$baseUrl?action=complete_task"));
      req.fields['id'] = widget.taskData['id'].toString();
      req.fields['current_status'] = status;
      req.files.add(await http.MultipartFile.fromPath('foto', _img!.path));
      var res = await req.send();
      if (res.statusCode == 200) { Navigator.pop(context); }
    } catch (e) { debugPrint("Error: $e"); }
    finally { setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    LatLng loc = LatLng(double.tryParse(widget.taskData['latitude'].toString()) ?? -8.2045, double.tryParse(widget.taskData['longitude'].toString()) ?? 111.0921);
    bool isCompleted = widget.taskData['status'] == 'Selesai';

    return Scaffold(
      appBar: AppBar(title: const Text("Detail Tugas"), backgroundColor: const Color(0xFF00549B), foregroundColor: Colors.white),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.taskData['nama_pelanggan'], style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          Text("Status: ${widget.taskData['status']}"),
          const SizedBox(height: 20),
          SizedBox(height: 200, child: ClipRRect(borderRadius: BorderRadius.circular(15), child: FlutterMap(options: MapOptions(initialCenter: loc, initialZoom: 15), children: [TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'), MarkerLayer(markers: [Marker(point: loc, width: 40, height: 40, child: const Icon(Icons.location_on, color: Colors.red, size: 40))])]))),
          const SizedBox(height: 20),
          if (!isCompleted) ...[
            GestureDetector(
              onTap: () async {
                final p = await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 40);
                if (p != null) setState(() => _img = File(p.path));
              },
              child: Container(width: double.infinity, height: 180, decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(10)), child: _img == null ? const Icon(Icons.camera_alt, size: 50) : ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.file(_img!, fit: BoxFit.cover))),
            ),
            const SizedBox(height: 20),
            SizedBox(width: double.infinity, height: 50, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00549B), foregroundColor: Colors.white), onPressed: _loading ? null : _submit, child: _loading ? const CircularProgressIndicator() : const Text("KONFIRMASI SELESAI"))),
          ]
        ]),
      ),
    );
  }
}