import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/user_model.dart';
import '../main.dart';

class ProfileScreen extends StatefulWidget {
  final UserModel user;
  const ProfileScreen({super.key, required this.user});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String totalSelesai = "0";

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      // Mengambil statistik berdasarkan username yang sedang login
      final response = await http.get(
        Uri.parse("$baseUrl?action=get_stats&teknisi=${widget.user.username}"),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          totalSelesai = data['total_selesai'].toString();
        });
      }
    } catch (e) {
      debugPrint("Gagal load statistik: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          // Header Profil (Dinamis sesuai User)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFF00549B), Color(0xFF00CCFF)]),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, size: 60, color: Color(0xFF00549B)),
                ),
                const SizedBox(height: 15),
                Text(
                  widget.user.nama.toUpperCase(), // Menampilkan Nama asli dari model
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                Text(
                  "Username: @${widget.user.username} | Role: ${widget.user.role}",
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Card Identitas (Dinamis sesuai User)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("INFORMASI AKUN", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                    const Divider(),
                    _buildInfoRow(Icons.badge, "Nama Lengkap", widget.user.nama),
                    _buildInfoRow(Icons.numbers, "NIM / ID Karyawan", widget.user.nim),
                    _buildInfoRow(Icons.security, "Hak Akses", widget.user.role.toUpperCase()),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Card Statistik Kerja (Dinamis dari API)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.check_circle, color: Colors.green),
                ),
                title: const Text("Pekerjaan Selesai", style: TextStyle(fontSize: 14)),
                subtitle: const Text("Bulan ini", style: TextStyle(fontSize: 12)),
                trailing: Text(
                  totalSelesai,
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.green),
                ),
              ),
            ),
          ),

          const Spacer(),

          // Tombol Logout
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                onPressed: () {
                  // Kembali ke halaman Login dan hapus semua history navigasi
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (c) => const LoginScreen()),
                    (r) => false,
                  );
                },
                icon: const Icon(Icons.power_settings_new),
                label: const Text("LOGOUT", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 22, color: const Color(0xFF00549B)),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}