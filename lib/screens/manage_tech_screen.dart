import 'package:flutter/material.dart';
import '../models/user_model.dart';
import 'tech_calendar_screen.dart';

class ManageTechScreen extends StatelessWidget {
  const ManageTechScreen({super.key});

  final Color primaryBlue = const Color(0xFF1A56F0);
  final Color bgGrey = const Color(0xFFF0F2F5);
  final Color borderGrey = const Color(0xFFE0E4E8);

  @override
  Widget build(BuildContext context) {
    // Filter hanya user dengan role teknisi dari list lokal
    final technicians = listUser.where((u) => u.role == "teknisi").toList();

    return Scaffold(
      backgroundColor: bgGrey,
      appBar: AppBar(
        title: const Text(
          "Kelola Teknisi Lapangan",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      body: technicians.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: technicians.length,
              itemBuilder: (context, index) {
                final tech = technicians[index];
                return _buildTechCard(context, tech);
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
          child: Text(
            "Username: ${tech.username}",
            style: const TextStyle(fontSize: 13, color: Colors.grey),
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
            "Tidak ada teknisi ditemukan",
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
