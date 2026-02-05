import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; 
import '../models/user_model.dart';
import 'tech_calendar_screen.dart';
import 'add_user_screen.dart';

class ManageTechScreen extends StatefulWidget {
  final UserModel user; 
  const ManageTechScreen({super.key, required this.user});

  @override
  State<ManageTechScreen> createState() => _ManageTechScreenState();
}

class _ManageTechScreenState extends State<ManageTechScreen> {
  final supabase = Supabase.instance.client;

  final Color primaryBlue = const Color(0xFF1A56F0);
  final Color bgGrey = const Color(0xFFF0F2F5);
  final Color borderGrey = const Color(0xFFE0E4E8);

  // FUNGSI: Mengambil data user (Teknisi/Admin)
  Future<List<UserModel>> _fetchUsers() async {
    try {
      // 1. Kueri dasar
      var query = supabase.from('users').select();

      // 2. LOGIKA MULTI-UNIT: 
      if (widget.user.role.toLowerCase() != 'superadmin') {
        // Admin biasa cuma bisa liat Teknisi di unitnya sendiri
        query = query.eq('role', 'teknisi').eq('unit', widget.user.unit);
      } else {
        // Superadmin bisa liat semua kecuali akun Superadmin sendiri (biar nggak hapus diri sendiri)
        query = query.neq('role', 'superadmin');
      }

      final response = await query.order('nama', ascending: true);
      final List<dynamic> data = response as List<dynamic>;
      
      return data.map((u) => UserModel.fromMap(u)).toList();
    } catch (e) {
      debugPrint("Error fetching users: $e");
      return [];
    }
  }

  // FUNGSI: Hapus Akun dengan Konfirmasi
  Future<void> _deleteUser(UserModel targetUser) async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Hapus Akun?", style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text("Apakah Anda yakin ingin menghapus akun ${targetUser.nama}? Data yang sudah dihapus tidak bisa dikembalikan."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("BATAL")),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text("HAPUS", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))
          ),
        ],
      ),
    ) ?? false;

    if (confirm) {
      try {
        await supabase.from('users').delete().eq('username', targetUser.username);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Akun berhasil dihapus"), backgroundColor: Colors.black87));
          setState(() {}); // Refresh list
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal menghapus: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isSuper = widget.user.role.toLowerCase() == 'superadmin';

    return Scaffold(
      backgroundColor: bgGrey,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isSuper ? "Manajemen Seluruh Akun" : "Unit ${widget.user.unit}",
              style: const TextStyle(fontSize: 10, color: Colors.white70),
            ),
            Text(
              isSuper ? "Daftar Admin & Teknisi" : "Kelola Teknisi Lapangan",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      body: FutureBuilder<List<UserModel>>(
        future: _fetchUsers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final users = snapshot.data ?? [];

          if (users.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final item = users[index];
              return _buildUserCard(context, item);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (c) => AddUserScreen(admin: widget.user)),
          ).then((_) => setState(() {}));
        },
        backgroundColor: primaryBlue,
        icon: const Icon(Icons.person_add_alt_1, color: Colors.white),
        label: const Text("TAMBAH AKUN", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildUserCard(BuildContext context, UserModel item) {
    bool isTeknisi = item.role.toLowerCase() == 'teknisi';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderGrey),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        onTap: isTeknisi 
          ? () => Navigator.push(context, MaterialPageRoute(builder: (c) => TechCalendarScreen(user: item)))
          : null, // Admin tidak punya kalender tugas di UI ini
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: (isTeknisi ? primaryBlue : Colors.orange).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isTeknisi ? Icons.engineering_rounded : Icons.admin_panel_settings_rounded, 
            color: isTeknisi ? primaryBlue : Colors.orange, 
            size: 24
          ),
        ),
        title: Row(
          children: [
            Text(item.nama, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87)),
            const SizedBox(width: 8),
            if (!isTeknisi)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: Colors.orange.shade100, borderRadius: BorderRadius.circular(4)),
                child: const Text("ADMIN", style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.orange)),
              ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("ID: ${item.username}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
              Text("Unit: ${item.unit}", style: TextStyle(fontSize: 11, color: primaryBlue, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isTeknisi) Icon(Icons.calendar_month_rounded, color: primaryBlue.withOpacity(0.5), size: 20),
            const SizedBox(width: 8),
            // TOMBOL HAPUS AKUN
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 22),
              onPressed: () => _deleteUser(item),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline_rounded, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text("Tidak ada akun ditemukan", style: TextStyle(color: Colors.grey, fontSize: 14)),
        ],
      ),
    );
  }
}