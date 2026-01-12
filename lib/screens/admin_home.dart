import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/user_model.dart';
import '../main.dart';
import 'admin_screen.dart';
import 'admin_monitoring_screen.dart';
import 'profile_screen.dart';
import 'manage_tech_screen.dart';
import 'report_screen.dart'; // Menambahkan import untuk halaman laporan

class AdminHome extends StatefulWidget {
  final UserModel user;
  const AdminHome({super.key, required this.user});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  int _selectedIndex = 0;
  Map<String, dynamic> stats = {
    "selesai": "0",
    "progress": "0",
    "pending": "0",
  };

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl?action=get_admin_stats"),
      );
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
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: _selectedIndex == 0
          ? AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              leading: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Image.network(
                  'https://upload.wikimedia.org/wikipedia/commons/9/97/Logo_PLN.png',
                  errorBuilder: (context, error, stackTrace) => Container(
                    decoration: BoxDecoration(
                      color: Colors.yellow,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.bolt, color: Colors.red),
                  ),
                ),
              ),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Selamat datang,",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Text(
                    widget.user.nama,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  onPressed: () {},
                  icon: const Icon(
                    Icons.notifications_none,
                    color: Colors.black54,
                  ),
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.more_vert, color: Colors.black54),
                ),
                const SizedBox(width: 8),
              ],
            )
          : null,
      body: [
        _buildBeranda(),
        AdminMonitoringScreen(onBack: () => setState(() => _selectedIndex = 0)),
        ProfileScreen(user: widget.user),
      ][_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF1A56F0),
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: "Beranda",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: "Monitoring",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: "Akun",
          ),
        ],
      ),
    );
  }

  Widget _buildBeranda() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF00C7E1),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Status Pekerjaan Hari Ini",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStatBox(
                      Icons.check_circle_outline,
                      stats['selesai'].toString(),
                      "Selesai",
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatBox(
                      Icons.access_time,
                      stats['progress'].toString(),
                      "Progress",
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatBox(
                      Icons.warning_amber_rounded,
                      stats['pending'].toString(),
                      "Pending",
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 25),

        Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMenuIcon(Icons.add, "Input\nPengajuan", () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (c) => const AdminScreen()),
                ).then((_) => _fetchStats());
              }),
              _buildMenuIcon(
                Icons.bar_chart,
                "Monitoring\nProgress",
                () => setState(() => _selectedIndex = 1),
              ),
              _buildMenuIcon(Icons.people_outline, "Kelola\nTeknisi", () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (c) => const ManageTechScreen()),
                );
              }),
              _buildMenuIcon(Icons.description_outlined, "Laporan", () {
                // LOGIKA BARU: Menuju halaman Laporan PDF
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (c) => const ReportScreen()),
                );
              }),
            ],
          ),
        ),

        const SizedBox(height: 25),
        const Text(
          "Pemberitahuan",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 15),

        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.notifications_none, color: Colors.blue),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Update Status Tugas",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "Pantau terus beban kerja teknisi lapangan hari ini.",
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatBox(IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuIcon(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 80,
        child: Column(
          children: [
            Container(
              height: 60,
              width: 60,
              decoration: BoxDecoration(
                color: const Color(0xFF00C7E1),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
