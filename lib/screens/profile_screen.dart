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
  bool isSaving = false;
  bool _isEditing = false; // Flag untuk kontrol tampilan
  
  late TextEditingController _phoneController;
  final supabase = Supabase.instance.client;

  final Color primaryBlue = const Color(0xFF1A56F0);
  final Color bgGrey = const Color(0xFFF0F2F5);
  final Color borderGrey = const Color(0xFFE0E4E8);

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController(text: widget.user.phone);
    
    // Jika nomor HP masih kosong, otomatis buka mode edit
    if (widget.user.phone.isEmpty) {
      _isEditing = true;
    }

    if (widget.user.role.toLowerCase() != 'admin') {
      _loadStats();
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

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

  Future<void> _updateProfile() async {
    if (_phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Nomor HP tidak boleh kosong!")),
      );
      return;
    }
    
    setState(() {
      isSaving = true;
    });

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
        setState(() {
          _isEditing = false; // Kembalikan ke tampilan teks setelah simpan
        });
      }
    } catch (e) {
      debugPrint("Gagal update: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
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
          (route) => false,
        );
      }
    } catch (e) {
      debugPrint("Gagal logout: $e");
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
                if (!isAdmin) ...[
                  _buildSectionTitle("RINGKASAN PERFORMA"),
                  _buildStatsCard(),
                  const SizedBox(height: 20),
                  
                  _buildSectionTitle("PENGATURAN PROFIL TEKNISI"),
                  _buildDynamicPhoneField(), // Memanggil widget toggle edit
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

  // WIDGET BARU: Menampilkan Teks jika sudah tersimpan, Input jika mode Edit
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

  // Layout saat nomor SUDAH tersimpan (Hanya Teks & Tombol Edit)
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
              Text(_phoneController.text, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87)),
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

  // Layout saat sedang MENGINPUT atau MENGUBAH nomor
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
            if (widget.user.phone.isNotEmpty)
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _isEditing = false),
                  style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  child: const Text("BATAL"),
                ),
              ),
            if (widget.user.phone.isNotEmpty) const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                onPressed: isSaving ? null : _updateProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: isSaving 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text("SIMPAN PERUBAHAN", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        )
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 60, bottom: 30, left: 20, right: 20),
      decoration: BoxDecoration(
        color: primaryBlue,
        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
      ),
      child: Column(
        children: [
          CircleAvatar(radius: 45, backgroundColor: Colors.white, child: Icon(Icons.person, size: 50, color: primaryBlue)),
          const SizedBox(height: 15),
          Text(widget.user.nama.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          Text("Level: ${widget.user.role.toUpperCase()}", style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
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
          isLoading ? const CircularProgressIndicator() : Text(totalSelesai, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green)),
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
          _buildInfoTile(Icons.alternate_email_rounded, "Username", "@${widget.user.username}"),
          const Divider(),
          _buildInfoTile(Icons.admin_panel_settings_outlined, "Role Akses", widget.user.role),
        ],
      ),
    );
  }

  Widget _buildLogoutButton() {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent.shade700, minimumSize: const Size(double.infinity, 54), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
      onPressed: _handleLogout,
      icon: const Icon(Icons.logout_rounded, color: Colors.white),
      label: const Text("LOGOUT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildSectionTitle(String title) => Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blueGrey, letterSpacing: 1));

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