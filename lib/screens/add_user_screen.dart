import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

class AddUserScreen extends StatefulWidget {
  final UserModel admin; // Data Admin yang sedang login
  const AddUserScreen({super.key, required this.admin});

  @override
  State<AddUserScreen> createState() => _AddUserScreenState();
}

class _AddUserScreenState extends State<AddUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _namaCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  String? _selectedRole;
  String? _selectedUnit;
  bool _isLoading = false;

  // Daftar Unit & Role (Bisa ditambah sesuai kebutuhan)
  final List<String> _unitOptions = ["Pacitan", "Balong", "Ponorogo", "Trenggalek"];
  final List<String> _roleOptions = ["admin", "teknisi"];

  final Color primaryBlue = const Color(0xFF1A56F0);
  final Color bgGrey = const Color(0xFFF0F2F5);

  @override
  void initState() {
    super.initState();
    // LOGIKA LOCKDOWN: Jika bukan Superadmin, otomatis set unit dan role
    if (widget.admin.role.toLowerCase() != 'superadmin') {
      _selectedUnit = widget.admin.unit;
      _selectedRole = "teknisi";
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedRole == null || _selectedUnit == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Mohon pilih Role dan Unit!")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final client = Supabase.instance.client;

      // 1. Cek apakah username sudah dipakai
      final checkUser = await client
          .from('users')
          .select()
          .eq('username', _userCtrl.text.trim())
          .maybeSingle();

      if (checkUser != null) {
        throw "Username sudah terdaftar! Gunakan nama lain.";
      }

      // 2. Proses Simpan Data
      await client.from('users').insert({
        'username': _userCtrl.text.trim(),
        'password': _passCtrl.text,
        'nama': _namaCtrl.text,
        'phone': _phoneCtrl.text,
        'role': _selectedRole,
        'unit': _selectedUnit,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Akun Berhasil Dibuat!"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context); // Kembali ke ManageTechScreen
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isSuper = widget.admin.role.toLowerCase() == 'superadmin';

    return Scaffold(
      backgroundColor: bgGrey,
      appBar: AppBar(
        title: const Text("Registrasi Akun Baru"),
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle("IDENTITAS LOGIN"),
              _buildTextField(_userCtrl, "Username / ID", Icons.alternate_email),
              const SizedBox(height: 16),
              _buildTextField(_passCtrl, "Password", Icons.lock_outline, isPassword: true),
              
              const SizedBox(height: 30),
              _buildSectionTitle("PROFIL PENGGUNA"),
              _buildTextField(_namaCtrl, "Nama Lengkap", Icons.person_outline),
              const SizedBox(height: 16),
              _buildTextField(_phoneCtrl, "Nomor WA (Contoh: 0812...)", Icons.phone_android, isNumber: true),
              
              const SizedBox(height: 30),
              _buildSectionTitle("OTORITAS & WILAYAH"),

              // DROPDOWN ROLE (Hanya muncul/bisa diedit oleh Superadmin)
              _buildLabel("Role Akses"),
              isSuper 
                ? _buildDropdown(_selectedRole, _roleOptions, (val) => setState(() => _selectedRole = val))
                : _buildReadOnlyInfo("TEKNISI"),

              const SizedBox(height: 16),

              // DROPDOWN UNIT (Hanya muncul/bisa diedit oleh Superadmin)
              _buildLabel("Unit Kerja (ULP)"),
              isSuper 
                ? _buildDropdown(_selectedUnit, _unitOptions, (val) => setState(() => _selectedUnit = val))
                : _buildReadOnlyInfo("ULP ${_selectedUnit?.toUpperCase()}"),

              const SizedBox(height: 50),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white) 
                    : const Text("SIMPAN & DAFTARKAN AKUN", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGET HELPERS ---

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primaryBlue, letterSpacing: 1)),
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String hint, IconData icon, {bool isPassword = false, bool isNumber = false}) {
    return TextFormField(
      controller: ctrl,
      obscureText: isPassword,
      keyboardType: isNumber ? TextInputType.phone : TextInputType.text,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, size: 20),
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      validator: (v) => v!.isEmpty ? "Bidang ini wajib diisi" : null,
    );
  }

  Widget _buildDropdown(String? value, List<String> items, Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items.map((i) => DropdownMenuItem(value: i, child: Text(i.toUpperCase()))).toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
    );
  }

  Widget _buildReadOnlyInfo(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(10)),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
    );
  }
}