import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../main.dart';
import '../models/user_model.dart';
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
      final response = await http.get(
        Uri.parse("$baseUrl?action=get_all_tasks&teknisi=${widget.user.username}"),
      );
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        _calculateStats(data);
        return data;
      }
      throw "Gagal memuat data";
    } catch (e) {
      throw "Koneksi Bermasalah";
    }
  }

  void _calculateStats(List<dynamic> tasks) {
    if (mounted) {
      setState(() {
        terlambat = tasks.where((t) => t['is_telat'].toString() == "1").length;
        pending = tasks.where((t) => t['status'] == 'Menunggu Pemasangan' && t['is_telat'].toString() == "0").length;
        progress = tasks.where((t) => t['status'] == 'Menunggu Pembongkaran' && t['is_telat'].toString() == "0").length;
        selesai = tasks.where((t) => t['status'] == 'Selesai').length;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: _currentIndex == 0
          ? AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              leading: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.yellow,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.bolt, color: Colors.red, size: 20),
                ),
              ),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Selamat datang,", style: TextStyle(fontSize: 11, color: Colors.grey)),
                  Text(widget.user.nama, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black)),
                ],
              ),
              actions: [
                IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_none, color: Colors.black54)),
              ],
            )
          : null,
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

  Widget _buildHomeContent() {
    return RefreshIndicator(
      onRefresh: () async => setState(() { _taskFuture = fetchAllTasks(); }),
      child: ListView(
        children: [
          Container(
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
          ),
          Padding(
            padding: const EdgeInsets.all(15),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: const Color(0xFF00C7E1), borderRadius: BorderRadius.circular(20)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatBox(terlambat.toString(), "Terlambat", Icons.warning_amber),
                  _buildStatBox((pending + progress).toString(), "Pending", Icons.access_time),
                  _buildStatBox(selesai.toString(), "Selesai", Icons.check_circle_outline),
                ],
              ),
            ),
          ),
          const Padding(padding: EdgeInsets.fromLTRB(20, 10, 20, 10), child: Text("Daftar Penugasan Aktif", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
          FutureBuilder<List<dynamic>>(
            future: _taskFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Padding(padding: EdgeInsets.all(40), child: Text("Tidak ada tugas hari ini.")));
              return Column(children: snapshot.data!.map((t) => _buildTaskCard(t)).toList());
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildStatBox(String val, String label, IconData icon) {
    return Column(children: [Icon(icon, color: Colors.white, size: 24), const SizedBox(height: 4), Text(val, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)), Text(label, style: const TextStyle(color: Colors.white, fontSize: 10))]);
  }

  Widget _buildTaskCard(Map t) {
    bool isTelat = t['is_telat'].toString() == "1";
    bool isBongkar = t['status'].toString().toLowerCase().contains('bongkar');
    Color themeColor = isTelat ? Colors.red : (isBongkar ? Colors.orange : Colors.green);

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
                      child: Text(isTelat ? "TERLAMBAT" : (isBongkar ? "PEMBONGKARAN" : "PEMASANGAN"), style: TextStyle(color: themeColor, fontSize: 9, fontWeight: FontWeight.bold)),
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