import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../main.dart';

class AdminMonitoringScreen extends StatefulWidget {
  final VoidCallback? onBack; // Parameter untuk fungsi kembali ke tab Beranda
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
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
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
          // --- HEADER BIRU ---
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
                    // LOGIKA BACK:
                    // Jika ada fungsi onBack (dari tab AdminHome), jalankan.
                    // Jika tidak (dibuka via Navigator.push), lakukan pop.
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

          // --- DAFTAR TEKNISI ---
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
                        "Klik untuk melihat detail tugas teknisi",
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
    // Pastikan data casting aman
    int selesai = int.tryParse(data['selesai'].toString()) ?? 0;
    int progress = int.tryParse(data['progress'].toString()) ?? 0;
    int pending = int.tryParse(data['pending'].toString()) ?? 0;
    int total = int.tryParse(data['total_tugas'].toString()) ?? 0;
    double progressPercent = total > 0 ? selesai / total : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
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
                    const Text(
                      "Wilayah Kerja",
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
          const SizedBox(height: 15),
          LinearProgressIndicator(
            value: progressPercent,
            minHeight: 8,
            backgroundColor: Colors.grey.shade200,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              _buildStatBox("Selesai", selesai, Colors.green),
              const SizedBox(width: 8),
              _buildStatBox("Progress", progress, Colors.blue),
              const SizedBox(width: 8),
              _buildStatBox("Pending", pending, Colors.orange),
            ],
          ),
        ],
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
