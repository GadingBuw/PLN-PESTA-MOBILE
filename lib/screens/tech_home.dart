import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Tambahkan ini
import 'package:intl/intl.dart';
import '../models/user_model.dart';
import '../services/notification_service.dart';
import 'tech_detail_screen.dart';
import 'tech_history_screen.dart';
import 'profile_screen.dart';

class TechHome extends StatefulWidget {
  final UserModel user;
  const TechHome({super.key, required this.user});

  @override
  State<TechHome> createState() => _TechHomeState();
}

class _TechHomeState extends State<TechHome> {
  int _currentIndex = 0;
  late Future<List<dynamic>> _taskFuture;
  final supabase = Supabase.instance.client; // Inisialisasi client

  int pending = 0;
  int progress = 0;
  int selesai = 0;
  int terlambat = 0;

  @override
  void initState() {
    super.initState();
    _taskFuture = fetchAllTasks();
  }

  Future<List<dynamic>> fetchAllTasks() async {
    try {
      // Mengambil data dari tabel 'pesta_tasks' difilter berdasarkan teknisi
      // Kita mengambil data yang belum selesai ATAU yang selesai di bulan berjalan
      final DateTime now = DateTime.now();
      final String firstDayOfMonth = DateFormat('yyyy-MM-01').format(now);

      final response = await supabase
          .from('pesta_tasks')
          .select()
          .eq('teknisi', widget.user.username) // Gunakan username untuk filter
          .or('status.neq.Selesai,tgl_pasang.gte.$firstDayOfMonth')
          .order('tgl_pasang', ascending: true);

      List<dynamic> data = response as List<dynamic>;

      // Karena PHP 'is_hari_ini' & 'is_telat' hilang, kita hitung manual di Flutter
      final String todayStr = DateFormat('yyyy-MM-dd').format(now);
      
      for (var task in data) {
        String status = task['status'] ?? '';
        String tglP = task['tgl_pasang'] ?? '';
        String tglB = task['tgl_bongkar'] ?? '';

        // Hitung Flag Hari Ini
        bool isHariIni = (status == 'Menunggu Pemasangan' && tglP == todayStr) ||
                         (status == 'Menunggu Pembongkaran' && tglB == todayStr);
        
        // Hitung Flag Terlambat
        bool isTelat = (status == 'Menunggu Pemasangan' && tglP.compareTo(todayStr) < 0) ||
                       (status == 'Menunggu Pembongkaran' && tglB.compareTo(todayStr) < 0);

        // Masukkan kembali ke Map agar UI tidak perlu berubah banyak
        task['is_hari_ini'] = isHariIni ? "1" : "0";
        task['is_telat'] = isTelat ? "1" : "0";

        if (isHariIni) {
          NotificationService.showInstantNotification(task);
        }
      }

      _calculateStats(data);
      return data;
    } catch (e) {
      debugPrint("Error Supabase: $e");
      throw "Koneksi Bermasalah";
    }
  }

  void _calculateStats(List<dynamic> tasks) {
    if (mounted) {
      setState(() {
        terlambat = tasks.where((t) => t['is_telat'] == "1").length;

        pending = tasks.where((t) => 
          t['status'] == 'Menunggu Pemasangan' && t['is_telat'] == "0"
        ).length;

        progress = tasks.where((t) => 
          t['status'] == 'Menunggu Pembongkaran' && t['is_telat'] == "0"
        ).length;

        selesai = tasks.where((t) => t['status'] == 'Selesai').length;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: _currentIndex == 0 ? _buildAppBar() : null,
      body: [
        _buildHomeContent(),
        TechHistoryScreen(user: widget.user),
        ProfileScreen(user: widget.user),
      ][_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: const Color(0xFF1A56F0),
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: "Beranda"),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: "Riwayat"),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: "Akun"),
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Image.asset(
            'assets/images/logo_pln.png',
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.bolt, size: 30, color: Colors.red),
          ),
        ),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Selamat datang,", style: TextStyle(fontSize: 11, color: Colors.grey)),
          Text(
            widget.user.nama,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeContent() {
    return RefreshIndicator(
      onRefresh: () async => setState(() { _taskFuture = fetchAllTasks(); }),
      child: ListView(
        children: [
          _buildBlueHeader(),
          _buildStatSection(),
          FutureBuilder<List<dynamic>>(
            future: _taskFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting)
                return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()));
              if (!snapshot.hasData || snapshot.data!.isEmpty)
                return const Center(child: Padding(padding: EdgeInsets.all(40), child: Text("Tidak ada tugas.")));

              final activeTasks = snapshot.data!.where((t) => 
                t['is_hari_ini'] == "1" || t['is_telat'] == "1"
              ).toList();

              final futureTasks = snapshot.data!.where((t) => 
                t['is_hari_ini'] == "0" && t['is_telat'] == "0" && t['status'] != 'Selesai'
              ).toList();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle("Daftar Penugasan Aktif"),
                  if (activeTasks.isEmpty) _buildEmptyInfo("Tidak ada tugas aktif hari ini.")
                  else ...activeTasks.map((t) => _buildTaskCard(t)).toList(),
                  
                  const SizedBox(height: 15),
                  
                  _buildSectionTitle("Penugasan Akan Datang"),
                  if (futureTasks.isEmpty) _buildEmptyInfo("Belum ada tugas terjadwal selanjutnya.")
                  else ...futureTasks.map((t) => _buildTaskCard(t)).toList(),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
    );
  }

  Widget _buildEmptyInfo(String text) {
    return Center(child: Padding(padding: const EdgeInsets.all(20), child: Text(text, style: const TextStyle(fontSize: 12, color: Colors.grey))));
  }

  Widget _buildBlueHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(color: Color(0xFF1A56F0)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("PESTA MOBILE - ULP PACITAN", style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
            child: Row(
              children: [
                const CircleAvatar(backgroundColor: Color(0xFF00C7E1), child: Icon(Icons.engineering, color: Colors.white)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Petugas Lapangan", style: TextStyle(fontSize: 10, color: Colors.grey)),
                      Text(widget.user.nama, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                ),
                Column(
                  children: [
                    const Text("Total Tugas", style: TextStyle(fontSize: 10, color: Colors.grey)),
                    Text((pending + progress + terlambat).toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1A56F0))),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF00C7E1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatBox(terlambat.toString(), "Terlambat", Icons.warning_amber_rounded),
            Container(width: 1, height: 30, color: Colors.white24),
            _buildStatBox((pending + progress).toString(), "Antrian", Icons.access_time),
            Container(width: 1, height: 30, color: Colors.white24),
            _buildStatBox(selesai.toString(), "Selesai", Icons.check_circle_outline),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBox(String val, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 6),
        Text(val, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildTaskCard(Map t) {
    bool isTelat = t['is_telat'] == "1";
    bool isHariIni = t['is_hari_ini'] == "1";
    bool isBongkar = t['status'].toString().toLowerCase().contains('bongkar');

    Color themeColor = isTelat ? Colors.red : (isHariIni ? (isBongkar ? Colors.orange : Colors.green) : Colors.blueGrey);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))]),
        child: InkWell(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => TechDetailScreen(taskData: t))).then((_) => setState(() { _taskFuture = fetchAllTasks(); })),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(15.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: themeColor.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                      child: Text(isTelat ? "TERLAMBAT" : (isHariIni ? (isBongkar ? "PEMBONGKARAN" : "PEMASANGAN") : "TERJADWAL"), style: TextStyle(color: themeColor, fontSize: 9, fontWeight: FontWeight.bold)),
                    ),
                    Text("Agenda: ${t['id_pelanggan']}", style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 12),
                Text(t['nama_pelanggan'] ?? "", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 6),
                Row(children: [const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey), const SizedBox(width: 4), Expanded(child: Text(t['alamat'] ?? "", style: const TextStyle(fontSize: 12, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis))]),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(children: [const Icon(Icons.bolt, size: 14, color: Colors.orange), const SizedBox(width: 4), Text("${t['daya']} VA", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold))]),
                    Text("Jadwal: ${isBongkar ? t['tgl_bongkar'] : t['tgl_pasang']}", style: TextStyle(fontSize: 11, color: isTelat ? Colors.red : Colors.black54, fontWeight: isTelat ? FontWeight.bold : FontWeight.normal)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}