import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; 
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'unit_selection_screen.dart'; // Arahkan logout ke sini

class ProfileScreen extends StatefulWidget {
  final UserModel user;
  const ProfileScreen({super.key, required this.user});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String totalSelesai = "0";
  bool isLoading = true;
  bool isSaving = false;
  bool _isEditing = false; 
  
  late TextEditingController _phoneController;
  final supabase = Supabase.instance.client;

  final Color primaryBlue = const Color(0xFF1A56F0);
  final Color bgGrey = const Color(0xFFF0F2F5);
  final Color borderGrey = const Color(0xFFE0E4E8);

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController(text: widget.user.phone);
    
    if (widget.user.phone.isEmpty) {
      _isEditing = true;
    }

    // Hanya teknisi yang perlu memuat statistik pengerjaan
    if (widget.user.role.toLowerCase() != 'admin' && widget.user.role.toLowerCase() != 'superadmin') {
      _loadStats();
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  // FITUR: Load statistik pekerjaan teknisi (TETAP ADA)
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
      if (mounted) setState(() => isLoading = false);
    }
  }

  // FITUR: Update nomor HP (TETAP ADA)
  Future<void> _updateProfile() async {
    if (_phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Nomor HP tidak boleh kosong!")),
      );
      return;
    }
    
    setState(() => isSaving = true);

    try {
      await supabase
          .from('users')
          .update({'phone': _phoneController.text})
          .eq('username', widget.user.username);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Nomor HP Berhasil Diperbarui!"),
            backgroundColor: Colors.green,
          ),
        );
        setState(() => _isEditing = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal update: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  // FITUR: Logout & Hapus Seluruh Session (User & Unit)
  Future<void> _handleLogout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_session');
      await prefs.remove('unit_session'); // Hapus juga session unitnya

      if (mounted) {
        // Kembali ke layar pemilihan unit (Gerbang Utama)
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (c) => const UnitSelectionScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      debugPrint("Gagal logout: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isStaff = widget.user.role.toLowerCase() != 'admin' && widget.user.role.toLowerCase() != 'superadmin';

    return Scaffold(
      backgroundColor: bgGrey,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (isStaff) ...[
                  _buildSectionTitle("RINGKASAN PERFORMA"),
                  _buildStatsCard(),
                  const SizedBox(height: 20),
                  
                  _buildSectionTitle("PENGATURAN PROFIL TEKNISI"),
                  _buildDynamicPhoneField(), 
                  const SizedBox(height: 20),
                ],
                
                _buildSectionTitle("INFORMASI AKUN"),
                _buildInfoCard(),
                const SizedBox(height: 30),
                _buildLogoutButton(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDynamicPhoneField() {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderGrey),
      ),
      child: _isEditing ? _buildEditLayout() : _buildReadLayout(),
    );
  }

  Widget _buildReadLayout() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: primaryBlue.withOpacity(0.08), shape: BoxShape.circle),
          child: Icon(Icons.phone_android, color: primaryBlue, size: 20),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Nomor HP Aktif", style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(_phoneController.text.isEmpty ? "-" : _phoneController.text, 
                   style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87)),
            ],
          ),
        ),
        IconButton(
          onPressed: () => setState(() => _isEditing = true),
          icon: const Icon(Icons.edit_square, color: Colors.orange, size: 24),
        )
      ],
    );
  }

  Widget _buildEditLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Input Nomor HP / WhatsApp", style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            hintText: "Contoh: 08123xxx",
            prefixIcon: Icon(Icons.phone_android, color: primaryBlue, size: 20),
            filled: true,
            fillColor: bgGrey,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _isEditing = false),
                style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                child: const Text("BATAL"),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                onPressed: isSaving ? null : _updateProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: isSaving 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text("SIMPAN", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        )
      ],
    );
  }

  Widget _buildHeader() {
    bool isSuper = widget.user.role.toLowerCase() == 'superadmin';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 60, bottom: 30, left: 20, right: 20),
      decoration: BoxDecoration(
        color: primaryBlue,
        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 45, 
            backgroundColor: Colors.white, 
            child: Icon(Icons.person, size: 50, color: primaryBlue)
          ),
          const SizedBox(height: 15),
          Text(widget.user.nama.toUpperCase(), 
               style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isSuper ? "ADMIN PUSAT" : "UNIT ${widget.user.unit.toUpperCase()}", 
              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: borderGrey)),
      child: Row(
        children: [
          const Icon(Icons.task_alt_rounded, color: Colors.green),
          const SizedBox(width: 15),
          const Expanded(child: Text("Total Pekerjaan Selesai", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
          isLoading 
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) 
            : Text(totalSelesai, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green)),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: borderGrey)),
      child: Column(
        children: [
          _buildInfoTile(Icons.alternate_email_rounded, "Username Sistem", "@${widget.user.username}"),
          const Divider(),
          _buildInfoTile(Icons.location_on_outlined, "Unit Kerja", "ULP ${widget.user.unit}"),
          const Divider(),
          _buildInfoTile(Icons.admin_panel_settings_outlined, "Role Akses", widget.user.role.toUpperCase()),
        ],
      ),
    );
  }

  Widget _buildLogoutButton() {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.redAccent.shade700, 
        minimumSize: const Size(double.infinity, 54), 
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
      onPressed: _handleLogout,
      icon: const Icon(Icons.logout_rounded, color: Colors.white),
      label: const Text("KELUAR DARI AKUN", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildSectionTitle(String title) => 
      Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blueGrey, letterSpacing: 1));

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: primaryBlue),
          const SizedBox(width: 15),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
            Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          ]),
        ],
      ),
    );
  }
}