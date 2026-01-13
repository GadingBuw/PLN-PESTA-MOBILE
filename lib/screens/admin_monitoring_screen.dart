import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../main.dart';
import 'admin_tech_history_detail.dart'; // Import file detail riwayat

class AdminMonitoringScreen extends StatefulWidget {
  final VoidCallback? onBack;
  const AdminMonitoringScreen({super.key, this.onBack});

  @override
  State<AdminMonitoringScreen> createState() => _AdminMonitoringScreenState();
}

class _AdminMonitoringScreenState extends State<AdminMonitoringScreen> {
  late Future<List<dynamic>> _monitoringFuture;

  @override
  void initState() {
    super.initState();
    _monitoringFuture = fetchMonitoring();
  }

  Future<List<dynamic>> fetchMonitoring() async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl?action=get_monitoring"),
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
      return [];
    } catch (e) {
      debugPrint("Gagal memuat monitoring: $e");
      return [];
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
            padding: const EdgeInsets.only(
              top: 50,
              left: 10,
              right: 20,
              bottom: 20,
            ),
            color: const Color(0xFF1A56F0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () {
                    if (widget.onBack != null) {
                      widget.onBack!();
                    } else if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    }
                  },
                ),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Monitoring",
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    Text(
                      "Progress Global Teknisi",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: _monitoringFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final listData = snapshot.data ?? [];
                return RefreshIndicator(
                  onRefresh: () async => setState(() {
                    _monitoringFuture = fetchMonitoring();
                  }),
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      const Text(
                        "Status Petugas Lapangan",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const Text(
                        "Klik kartu teknisi untuk melihat riwayat tugas aktif",
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                      const SizedBox(height: 20),
                      if (listData.isEmpty)
                        const Center(child: Text("Belum ada data penugasan."))
                      else
                        ...listData
                            .map((data) => _buildTechnicianCard(data))
                            .toList(),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTechnicianCard(Map<String, dynamic> data) {
    int selesai = int.tryParse(data['selesai'].toString()) ?? 0;
    int pending = int.tryParse(data['pending'].toString()) ?? 0;
    int total = int.tryParse(data['total_tugas'].toString()) ?? 0;
    String statusKapasitas = data['kapasitas'] ?? "Tersedia";

    // Hitung persentase pengerjaan
    double progressPercent = total > 0 ? selesai / total : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            // NAVIGASI: Ke halaman detail riwayat tugas aktif teknisi
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (c) => AdminTechHistoryDetail(
                  username: data['teknisi'],
                  nama: data['teknisi'],
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person_outline,
                        color: Colors.blue,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data['teknisi'] ?? "Tanpa Nama",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          // LOGIKA PERBAIKAN: Status berubah warna sesuai kapasitas hari ini
                          Text(
                            statusKapasitas,
                            style: TextStyle(
                              color: statusKapasitas == "Jadwal Penuh"
                                  ? Colors.red
                                  : Colors.green,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.grey),
                  ],
                ),
                const SizedBox(height: 15),
                // Progress Bar
                Stack(
                  children: [
                    Container(
                      height: 8,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: progressPercent,
                      child: Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    _buildStatBox("Selesai", selesai, Colors.green),
                    const SizedBox(width: 8),
                    _buildStatBox("Antrian", pending, Colors.orange),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatBox(String label, int value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              value.toString(),
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
