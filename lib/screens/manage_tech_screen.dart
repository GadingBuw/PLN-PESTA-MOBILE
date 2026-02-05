import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; 
import '../models/user_model.dart';
import 'tech_calendar_screen.dart';

class ManageTechScreen extends StatelessWidget {
  // Nama parameter disesuaikan menjadi 'user' agar sinkron dengan AdminHome
  final UserModel user; 
  ManageTechScreen({super.key, required this.user});

  final supabase = Supabase.instance.client;

  final Color primaryBlue = const Color(0xFF1A56F0);
  final Color bgGrey = const Color(0xFFF0F2F5);
  final Color borderGrey = const Color(0xFFE0E4E8);

  // FUNGSI: Mengambil data teknisi dengan filter UNIT (Multi-Unit)
  Future<List<UserModel>> _fetchTechnicians() async {
    try {
      var query = supabase.from('users').select().eq('role', 'teknisi');

      // LOGIKA MULTI-UNIT: 
      // Jika bukan superadmin, kunci data hanya untuk unit user yang login
      if (user.role.toLowerCase() != 'superadmin') {
        query = query.eq('unit', user.unit);
      }

      final response = await query.order('nama', ascending: true);
      final List<dynamic> data = response as List<dynamic>;
      
      return data.map((u) => UserModel.fromMap(u)).toList();
    } catch (e) {
      debugPrint("Error fetching technicians: $e");
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isSuper = user.role.toLowerCase() == 'superadmin';

    return Scaffold(
      backgroundColor: bgGrey,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isSuper ? "Seluruh Unit" : "Unit ${user.unit}",
              style: const TextStyle(fontSize: 10, color: Colors.white70),
            ),
            const Text(
              "Kelola Teknisi Lapangan",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      body: FutureBuilder<List<UserModel>>(
        future: _fetchTechnicians(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Terjadi kesalahan: ${snapshot.error}"));
          }

          final technicians = snapshot.data ?? [];

          if (technicians.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: technicians.length,
            itemBuilder: (context, index) {
              final tech = technicians[index];
              return _buildTechCard(context, tech);
            },
          );
        },
      ),
    );
  }

  Widget _buildTechCard(BuildContext context, UserModel tech) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderGrey),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (c) => TechCalendarScreen(user: tech)),
          );
        },
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: primaryBlue.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.engineering_rounded, color: primaryBlue, size: 24),
        ),
        title: Text(
          tech.nama,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: Colors.black87,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "ID: ${tech.username}",
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              Text(
                "Unit: ${tech.unit}",
                style: TextStyle(
                  fontSize: 11, 
                  color: primaryBlue, 
                  fontWeight: FontWeight.bold
                ),
              ),
            ],
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderGrey),
          ),
          child: Icon(
            Icons.calendar_month_rounded,
            color: primaryBlue,
            size: 20,
          ),
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
          const Text(
            "Tidak ada teknisi ditemukan di unit ini",
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ],
      ),
    );
  }
}