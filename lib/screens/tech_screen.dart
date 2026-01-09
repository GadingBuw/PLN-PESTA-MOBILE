import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../main.dart';
import '../models/user_model.dart';
import 'tech_detail_screen.dart';

class TechScreen extends StatefulWidget {
  final UserModel user; // Menerima data user yang login
  const TechScreen({super.key, required this.user});

  @override
  State<TechScreen> createState() => _TechScreenState();
}

class _TechScreenState extends State<TechScreen> {
  // Ambil data dari API dengan filter nama teknisi
  Future<List> fetchMyTasks() async {
    final response = await http.get(Uri.parse("$baseUrl?action=get_tasks&teknisi=${widget.user.username}"));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Tugas Saya: ${widget.user.username}"), backgroundColor: const Color(0xFF00549B), foregroundColor: Colors.white),
      body: FutureBuilder<List>(
        future: fetchMyTasks(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          if (snapshot.data!.isEmpty) return const Center(child: Text("Belum ada tugas hari ini."));

          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              var task = snapshot.data![index];
              return Card(
                child: ListTile(
                  title: Text(task['nama_pelanggan'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("ID: ${task['id_pelanggan']}\nAlamat: ${task['alamat']}"),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (c) => TechDetailScreen(taskData: task))).then((_) => setState(() {}));
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}