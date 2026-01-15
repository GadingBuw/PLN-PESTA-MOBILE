import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Menggunakan SDK Supabase
import 'package:intl/intl.dart';
import '../models/user_model.dart';
import 'tech_detail_screen.dart';

class TechHistoryScreen extends StatefulWidget {
  final UserModel user;
  const TechHistoryScreen({super.key, required this.user});

  @override
  State<TechHistoryScreen> createState() => _TechHistoryScreenState();
}

class _TechHistoryScreenState extends State<TechHistoryScreen> {
  late Future<List<dynamic>> _historyFuture;
  String _activeFilter = 'Semua';
  
  // Inisialisasi client Supabase untuk akses database
  final supabase = Supabase.instance.client;

  final Color primaryBlue = const Color(0xFF1A56F0);
  final Color bgGrey = const Color(0xFFF0F2F5);
  final Color borderGrey = const Color(0xFFE0E4E8);

  @override
  void initState() {
    super.initState();
    _historyFuture = fetchHistory();
  }

  Future<List<dynamic>> fetchHistory() async {
    try {
      // Mengambil data dari tabel 'pesta_tasks'
      // Perbaikan: Menggunakan 'ascending: false' untuk mengurutkan dari yang terbaru
      final response = await supabase
          .from('pesta_tasks')
          .select()
          .eq('teknisi', widget.user.username)
          .order('created_at', ascending: false); 

      List<dynamic> data = response as List<dynamic>;

      // Logika penghitungan status terlambat di sisi aplikasi
      final String todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      
      for (var task in data) {
        String status = task['status'] ?? '';
        String tglP = task['tgl_pasang'] ?? '';
        String tglB = task['tgl_bongkar'] ?? '';

        bool isTelat = (status == 'Menunggu Pemasangan' && tglP.compareTo(todayStr) < 0) ||
                       (status == 'Menunggu Pembongkaran' && tglB.compareTo(todayStr) < 0);
        
        // Simpan flag terlambat ke dalam map data
        task['is_telat'] = isTelat ? "1" : "0";
      }

      return data;
    } catch (e) {
      debugPrint("Error Supabase History: $e");
      throw "Gagal memuat riwayat penugasan.";
    }
  }

  String formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return "-";
    try {
      return DateFormat('d MMM yyyy').format(DateTime.parse(dateStr));
    } catch (e) {
      return "-";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgGrey,
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("PESTA MOBILE", style: TextStyle(fontSize: 10, color: Colors.white70, letterSpacing: 1)),
            Text("Riwayat Penugasan", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _activeFilter,
                dropdownColor: primaryBlue,
                icon: const Icon(Icons.filter_list, color: Colors.white),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                items: ['Semua', 'Pemasangan', 'Pembongkaran']
                    .map((val) => DropdownMenuItem(value: val, child: Text(val)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _activeFilter = val);
                },
              ),
            ),
          ),
        ],
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _historyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: primaryBlue));
          }
          if (snapshot.hasError) return Center(child: Text(snapshot.error.toString()));

          final allData = snapshot.data ?? [];

          // Logika Filter Lokal
          List<dynamic> filteredSource = allData.where((item) {
            if (_activeFilter == 'Semua') return true;
            if (_activeFilter == 'Pemasangan') return item['status'] == 'Menunggu Pemasangan';
            if (_activeFilter == 'Pembongkaran') return item['status'] == 'Menunggu Pembongkaran';
            return true;
          }).toList();

          List<dynamic> activeTasks = filteredSource.where((item) => item['status'] != 'Selesai').toList();
          List<dynamic> completedTasks = filteredSource.where((item) => item['status'] == 'Selesai').toList();

          return RefreshIndicator(
            onRefresh: () async => setState(() { _historyFuture = fetchHistory(); }),
            child: ListView(
              padding: const EdgeInsets.all(15),
              children: [
                if (activeTasks.isNotEmpty) ...[
                  _buildSectionTitle(_activeFilter == 'Semua' ? "TUGAS AKTIF" : "HASIL FILTER: $_activeFilter"),
                  ...activeTasks.map((task) => _buildHistoryCard(task)).toList(),
                ],
                if (_activeFilter == 'Semua' && completedTasks.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _buildSectionTitle("TUGAS SELESAI"),
                  ...completedTasks.map((task) => _buildHistoryCard(task)).toList(),
                ],
                if (activeTasks.isEmpty && (completedTasks.isEmpty || _activeFilter != 'Semua')) _buildEmptyState(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 5, bottom: 12, top: 5),
      child: Text(title, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.blueGrey[800], letterSpacing: 1.2)),
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> task) {
    bool isSelesai = task['status'] == 'Selesai';
    bool isTelat = task['is_telat'] == "1";
    Color statusColor = isSelesai ? Colors.green : (isTelat ? Colors.red : Colors.orange);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: borderGrey)),
      child: InkWell(
        onTap: () => Navigator.push(
          context, 
          MaterialPageRoute(builder: (c) => TechDetailScreen(taskData: task))
        ).then((_) => setState(() { _historyFuture = fetchHistory(); })),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("AGENDA: ${task['id_pelanggan']}", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: primaryBlue.withOpacity(0.8))),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                    child: Text(isTelat && !isSelesai ? "TERLAMBAT" : task['status'].toUpperCase(), style: TextStyle(color: statusColor, fontSize: 9, fontWeight: FontWeight.w900)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(task['nama_pelanggan'] ?? "", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.location_on_rounded, size: 14, color: primaryBlue),
                  const SizedBox(width: 6),
                  Expanded(child: Text(task['alamat'] ?? "", style: const TextStyle(fontSize: 12, color: Colors.black54), maxLines: 1, overflow: TextOverflow.ellipsis)),
                ],
              ),
              const Divider(height: 28, thickness: 0.5),
              Row(
                children: [
                  Expanded(child: _infoTile("TGL PASANG", formatDate(task['tgl_pasang']))),
                  Expanded(child: _infoTile("TGL BONGKAR", formatDate(task['tgl_bongkar']))),
                  Expanded(child: _infoTile("DAYA", "${task['daya']} VA", crossAxis: CrossAxisAlignment.end)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoTile(String label, String val, {CrossAxisAlignment crossAxis = CrossAxisAlignment.start}) => Column(
    crossAxisAlignment: crossAxis,
    children: [
      Text(label, style: const TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.w600)),
      const SizedBox(height: 4),
      Text(val, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.black87), maxLines: 1, overflow: TextOverflow.ellipsis),
    ],
  );

  Widget _buildEmptyState() => Center(
    child: Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Column(
        children: [
          Icon(Icons.assignment_outlined, size: 70, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text("Tidak ada tugas ditemukan", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
        ],
      ),
    ),
  );
}