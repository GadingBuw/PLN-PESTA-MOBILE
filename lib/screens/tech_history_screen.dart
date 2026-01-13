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
        Uri.parse(
          "$baseUrl?action=get_history&teknisi=${widget.user.username}",
        ),
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
      throw "Server Error: ${response.statusCode}";
    } catch (e) {
      throw "Gagal terhubung ke server.";
    }
  }

  String formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty || dateStr == "0000-00-00")
      return "-";
    try {
      return DateFormat('d MMM yyyy').format(DateTime.parse(dateStr));
    } catch (e) {
      return "-";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      body: FutureBuilder<List<dynamic>>(
        future: _historyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator());
          final listData = snapshot.data ?? [];

          return ListView(
            padding: EdgeInsets.zero,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.only(
                  top: 50,
                  left: 20,
                  right: 20,
                  bottom: 20,
                ),
                decoration: const BoxDecoration(color: Color(0xFF1A56F0)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "PESTA MOBILE",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      "Riwayat Pengerjaan Rill",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(padding: const EdgeInsets.all(15)),
              if (listData.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: Text("Belum ada riwayat pengerjaan."),
                  ),
                )
              else
                ...listData.map((task) => _buildHistoryCard(task)).toList(),
              const SizedBox(height: 20),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> task) {
    bool isSelesai = task['status'] == 'Selesai';
    Color textColor = isSelesai ? Colors.green : Colors.orange;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: InkWell(
          onTap: () =>
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (c) => TechDetailScreen(taskData: task),
                ),
              ).then(
                (_) => setState(() {
                  _historyFuture = fetchHistory();
                }),
              ),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(15.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Agenda: ${task['id_pelanggan']}",
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: textColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        task['status'].toUpperCase(),
                        style: TextStyle(
                          color: textColor,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  task['nama_pelanggan'] ?? "",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                Text(
                  task['alamat'] ?? "",
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const Divider(height: 25),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _dateInfo("Tgl Pasang", formatDate(task['tgl_pasang'])),
                    _dateInfo("Tgl Bongkar", formatDate(task['tgl_bongkar'])),
                    Column(
                      children: [
                        const Text(
                          "Daya",
                          style: TextStyle(fontSize: 9, color: Colors.grey),
                        ),
                        Text(
                          "${task['daya']} VA",
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _dateInfo(String label, String val) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(fontSize: 9, color: Colors.grey)),
      Text(
        val,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
      ),
    ],
  );
}
