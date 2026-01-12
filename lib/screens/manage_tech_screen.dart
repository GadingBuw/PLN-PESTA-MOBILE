import 'package:flutter/material.dart';
import '../models/user_model.dart';
import 'tech_calendar_screen.dart';

class ManageTechScreen extends StatelessWidget {
  const ManageTechScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Filter hanya user dengan role teknisi dari list lokal
    final technicians = listUser.where((u) => u.role == "teknisi").toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        title: const Text("Kelola Teknisi Lapangan"),
        backgroundColor: const Color(0xFF1A56F0),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: technicians.length,
        itemBuilder: (context, index) {
          final tech = technicians[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 15),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: ListTile(
              contentPadding: const EdgeInsets.all(15),
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFE3F2FD),
                child: Icon(Icons.person, color: Colors.blue),
              ),
              title: Text(tech.nama, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text("Username: ${tech.username}"),
              trailing: const Icon(Icons.calendar_month, color: Colors.blue),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (c) => TechCalendarScreen(user: tech)),
                );
              },
            ),
          );
        },
      ),
    );
  }
}