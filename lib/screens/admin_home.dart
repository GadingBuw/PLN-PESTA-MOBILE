import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/user_model.dart';
import '../main.dart';
import 'admin_screen.dart';
import 'admin_monitoring_screen.dart';
import 'profile_screen.dart';

class AdminHome extends StatefulWidget {
  final UserModel user;
  const AdminHome({super.key, required this.user});
  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  int _selectedIndex = 0;
  Map<String, dynamic> stats = {"selesai": "0", "progress": "0", "pending": "0"};

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    try {
      final response = await http.get(Uri.parse("$baseUrl?action=get_admin_stats"));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            stats = data;
          });
        }
      }
    } catch (e) {
      debugPrint("Error Fetching Stats: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const Padding(
          padding: EdgeInsets.all(8.0),
          child: Icon(Icons.bolt, color: Colors.blue, size: 30),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Selamat datang,", style: TextStyle(fontSize: 12, color: Colors.grey)),
            Text(widget.user.nama, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
          ],
        ),
      ),
      body: [
        _buildBeranda(),
        const AdminMonitoringScreen(),
        ProfileScreen(user: widget.user),
      ][_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF00549B),
        onTap: (index) {
          setState(() => _selectedIndex = index);
          if (index == 0) _fetchStats();
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Beranda"),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: "Monitoring"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Akun"),
        ],
      ),
    );
  }

  Widget _buildBeranda() {
    return RefreshIndicator(
      onRefresh: _fetchStats,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF00CCFF), 
              borderRadius: BorderRadius.circular(15)
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatItem(stats['selesai'].toString(), "Selesai"),
                _StatItem(stats['progress'].toString(), "Progress"),
                _StatItem(stats['pending'].toString(), "Pending"),
              ],
            ),
          ),
          const SizedBox(height: 30),
          const Text("Menu Navigasi", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 15),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 15,
            crossAxisSpacing: 15,
            children: [
              _MenuTile(Icons.add_circle, "Input Pengajuan", Colors.cyan, () {
                Navigator.push(context, MaterialPageRoute(builder: (c) => const AdminScreen()))
                    .then((_) => _fetchStats());
              }),
              _MenuTile(Icons.analytics, "Monitoring Progress", Colors.cyan, () => setState(() => _selectedIndex = 1)),
              _MenuTile(Icons.people, "Kelola Teknisi", Colors.cyan, () {}),
              _MenuTile(Icons.description, "Laporan", Colors.cyan, () {}),
            ],
          )
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String val, label;
  const _StatItem(this.val, this.label);
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(val, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
      Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
    ]);
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon; final String label; final Color color; final VoidCallback onTap;
  const _MenuTile(this.icon, this.label, this.color, this.onTap);
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(15)),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 40, color: color),
          const SizedBox(height: 10),
          Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ]),
      ),
    );
  }
}