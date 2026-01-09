import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
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

  @override
  void initState() {
    super.initState();
    _taskFuture = fetchAllTasks();
  }

  Future<List<dynamic>> fetchAllTasks() async {
    try {
      final response = await http.get(Uri.parse("$baseUrl?action=get_all_tasks&teknisi=${widget.user.username}"));
      if (response.statusCode == 200) return jsonDecode(response.body);
      throw "Gagal memuat data";
    } catch (e) { throw "Koneksi Bermasalah"; }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: [
        _buildHomeContent(),
        TechHistoryScreen(user: widget.user),
        ProfileScreen(user: widget.user),
      ][_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: const Color(0xFF00549B),
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Beranda"),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: "Riwayat"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Akun"),
        ],
      ),
    );
  }

  Widget _buildHomeContent() {
    return Column(
      children: [
        Container(
          width: double.infinity, padding: const EdgeInsets.all(30),
          decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF00549B), Color(0xFF00CCFF)])),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(height: 20),
            Text("Halo, ${widget.user.nama}", style: const TextStyle(color: Colors.white, fontSize: 18)),
            const Text("Manajemen Tugas", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          ]),
        ),
        Expanded(
          child: FutureBuilder<List<dynamic>>(
            future: _taskFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text("Tidak ada tugas."));

              List<dynamic> all = snapshot.data!;
              String today = DateFormat('yyyy-MM-dd').format(DateTime.now());

              // Filter Data
              var lateTasks = all.where((t) => t['is_telat'].toString() == "1").toList();
              var todayTasks = all.where((t) => t['is_telat'].toString() == "0" && (t['tgl_pasang'] == today || t['tgl_bongkar'] == today)).toList();
              var upcomingTasks = all.where((t) => t['is_telat'].toString() == "0" && t['tgl_pasang'] != today && t['tgl_bongkar'] != today).toList();

              return ListView(
                padding: const EdgeInsets.all(15),
                children: [
                  if (lateTasks.isNotEmpty) ...[
                    _sectionHeader("TUGAS TELAT", Icons.warning, Colors.red),
                    ...lateTasks.map((t) => _card(t, Colors.red.shade50, true)).toList(),
                  ],
                  _sectionHeader("TUGAS HARI INI", Icons.today, Colors.blue),
                  todayTasks.isEmpty ? const Center(child: Text("Kosong")) : Column(children: todayTasks.map((t) => _card(t, Colors.blue.shade50, false)).toList()),
                  const SizedBox(height: 15),
                  _sectionHeader("MENDATANG", Icons.calendar_month, Colors.grey),
                  upcomingTasks.isEmpty ? const Center(child: Text("Kosong")) : Column(children: upcomingTasks.map((t) => _card(t, Colors.white, false)).toList()),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _sectionHeader(String t, IconData i, Color c) => Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Row(children: [Icon(i, size: 18, color: c), const SizedBox(width: 8), Text(t, style: TextStyle(fontWeight: FontWeight.bold, color: c))]));

  Widget _card(Map t, Color bg, bool isLate) => Card(
    color: bg, margin: const EdgeInsets.only(bottom: 10),
    child: ListTile(
      title: Text(t['nama_pelanggan'], style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text("${t['alamat']}\nJadwal: ${t['status'] == 'Menunggu Pemasangan' ? t['tgl_pasang'] : t['tgl_bongkar']}"),
      trailing: isLate ? const Icon(Icons.error, color: Colors.red) : const Icon(Icons.arrow_forward_ios, size: 14),
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => TechDetailScreen(taskData: t))).then((_) => setState(() { _taskFuture = fetchAllTasks(); })),
    ),
  );
}