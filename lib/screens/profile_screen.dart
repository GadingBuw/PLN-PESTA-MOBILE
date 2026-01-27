import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; 
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  final UserModel user;
  const ProfileScreen({super.key, required this.user});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String totalSelesai = "0";
  bool isLoading = true;

  // Inisialisasi client Supabase
  final supabase = Supabase.instance.client;

  final Color primaryBlue = const Color(0xFF1A56F0);
  final Color bgGrey = const Color(0xFFF0F2F5);
  final Color borderGrey = const Color(0xFFE0E4E8);

  @override
  void initState() {
    super.initState();
    // Hanya load statistik jika user BUKAN admin
    if (widget.user.role.toLowerCase() != 'admin') {
      _loadStats();
    } else {
      setState(() => isLoading = false);
    }
  }

  // Fungsi mengambil statistik penyelesaian tugas teknisi
  Future<void> _loadStats() async {
    try {
      final response = await supabase
          .from('pesta_tasks')
          .select('id')
          .eq('teknisi', widget.user.username)
          .eq('status', 'Selesai');

      if (mounted) {
        setState(() {
          totalSelesai = (response as List).length.toString();
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Gagal load statistik: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _handleLogout() async {
    try {
      await supabase.auth.signOut();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_session');

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (c) => const LoginScreen()),
          (r) => false,
        );
      }
    } catch (e) {
      debugPrint("Error saat logout: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isAdmin = widget.user.role.toLowerCase() == 'admin';

    return Scaffold(
      backgroundColor: bgGrey,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Kondisi: Hanya muncul jika BUKAN admin
                if (!isAdmin) ...[
                  _buildSectionTitle("RINGKASAN PERFORMA"),
                  _buildStatsCard(),
                  const SizedBox(height: 20),
                ],
                
                _buildSectionTitle("INFORMASI AKUN"),
                _buildInfoCard(),
                const SizedBox(height: 30),
                _buildLogoutButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET COMPONENTS ---

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 60, bottom: 30, left: 20, right: 20),
      decoration: BoxDecoration(
        color: primaryBlue,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
            child: CircleAvatar(
              radius: 45,
              backgroundColor: Colors.white,
              child: Icon(Icons.person, size: 50, color: primaryBlue),
            ),
          ),
          const SizedBox(height: 15),
          Text(
            widget.user.nama.toUpperCase(),
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 5),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(20)),
            child: Text(
              "Role: ${widget.user.role.toUpperCase()}",
              style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    return Container(
      margin: const EdgeInsets.only(top: 10, bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderGrey),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), shape: BoxShape.circle),
            child: const Icon(Icons.task_alt_rounded, color: Colors.green),
          ),
          const SizedBox(width: 15),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Total Pekerjaan Selesai", style: TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w500)),
                Text("Akumulasi Tugas", style: TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
          isLoading 
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
            : Text(totalSelesai, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.green)),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderGrey),
      ),
      child: Column(
        children: [
          _buildInfoTile(Icons.alternate_email_rounded, "Username", "@${widget.user.username}"),
          const Divider(height: 1, color: Color(0xFFF0F2F5)),
          _buildInfoTile(Icons.badge_outlined, "ID Pengguna", widget.user.username),
          const Divider(height: 1, color: Color(0xFFF0F2F5)),
          _buildInfoTile(Icons.admin_panel_settings_outlined, "Hak Akses", widget.user.role),
        ],
      ),
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.redAccent.shade700,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: _handleLogout,
        icon: const Icon(Icons.logout_rounded, size: 20),
        label: const Text("LOGOUT", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.8, fontSize: 14)),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueGrey, letterSpacing: 1));
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: primaryBlue),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
              Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
            ],
          ),
        ],
      ),
    );
  }
}