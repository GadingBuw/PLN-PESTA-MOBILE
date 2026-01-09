import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import '../main.dart'; 
import '../models/user_model.dart';
import 'tech_detail_screen.dart';

class TechHistoryScreen extends StatefulWidget {
  final UserModel user;
  const TechHistoryScreen({super.key, required this.user});

  @override
  State<TechHistoryScreen> createState() => _TechHistoryScreenState();
}

class _TechHistoryScreenState extends State<TechHistoryScreen> {
  late Future<List<dynamic>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _historyFuture = fetchHistory();
  }

  Future<List<dynamic>> fetchHistory() async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl?action=get_history&teknisi=${widget.user.username}"),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw "Server Error: ${response.statusCode}";
      }
    } catch (e) {
      throw "Gagal terhubung ke server. Pastikan Apache di XAMPP hidup dan URL benar.";
    }
  }

  String formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty || dateStr == "0000-00-00") return "-";
    try {
      return DateFormat('dd MMM').format(DateTime.parse(dateStr));
    } catch (e) {
      return "-";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(30),
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFF00549B), Color(0xFF00CCFF)]),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 20),
                Text("PESTA MOBILE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                Text("Riwayat Pekerjaan", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: _historyFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        "Error:\n${snapshot.error}",
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("Tidak ada riwayat ditemukan."));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(15),
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    var task = snapshot.data![index];
                    return _buildHistoryCard(task);
                  },
                );
              },
            ),
          )
        ],
      ),
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> task) {
    String type = task['status'].toString().contains('Pemasangan') ? "PEMASANGAN" : "PEMBONGKARAN";
    bool isSelesai = task['status'] == 'Selesai';
    bool isTelat = task['is_telat'].toString() == "1";
    
    Color statusColor = isSelesai ? Colors.green : (isTelat ? Colors.red : Colors.orange);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      margin: const EdgeInsets.only(bottom: 15),
      elevation: 2,
      child: InkWell(
        onTap: () => Navigator.push(
          context, 
          MaterialPageRoute(builder: (c) => TechDetailScreen(taskData: task))
        ).then((_) => setState(() { _historyFuture = fetchHistory(); })),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(5)),
                    child: Text(type, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 10)),
                  ),
                  if (isTelat && !isSelesai)
                    const Text("⚠️ TERLAMBAT", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 10)),
                ],
              ),
              const SizedBox(height: 10),
              Text(task['nama_pelanggan'] ?? "No Name", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text(task['alamat'] ?? "-", style: const TextStyle(fontSize: 12, color: Colors.grey)),
              const Divider(height: 25),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Pasang: ${formatDate(task['tgl_pasang'])}", style: const TextStyle(fontSize: 10)),
                  Text("Bongkar: ${formatDate(task['tgl_bongkar'])}", style: const TextStyle(fontSize: 10)),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: statusColor.withOpacity(0.05), borderRadius: BorderRadius.circular(10)),
                child: Center(
                  child: Text(task['status'] ?? "-", style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}