import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../main.dart';
import 'admin_tech_history_detail.dart';

class AdminMonitoringScreen extends StatefulWidget {
  final VoidCallback? onBack;
  const AdminMonitoringScreen({super.key, this.onBack});

  @override
  State<AdminMonitoringScreen> createState() => _AdminMonitoringScreenState();
}

class _AdminMonitoringScreenState extends State<AdminMonitoringScreen> {
  late Future<List<dynamic>> _monitoringFuture;

  // Definisi Warna Tema agar Senada
  final Color primaryBlue = const Color(0xFF1A56F0);
  final Color bgGrey = const Color(0xFFF0F2F5);
  final Color borderGrey = const Color(0xFFE0E4E8);
  final Color primaryCyan = const Color(0xFF06B6D4);

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
      backgroundColor: bgGrey, // Menggunakan abu-abu bersih
      appBar: AppBar(
        backgroundColor: primaryBlue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (widget.onBack != null) {
              widget.onBack!();
            } else if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
        ),
        title: const Column(
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
      ),
      body: FutureBuilder<List<dynamic>>(
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
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF444444),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  "Klik kartu untuk melihat rincian tugas aktif",
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 20),
                if (listData.isEmpty)
                  _buildEmptyState()
                else
                  ...listData
                      .map((data) => _buildTechnicianCard(data))
                      .toList(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTechnicianCard(Map<String, dynamic> data) {
    int selesai = int.tryParse(data['selesai'].toString()) ?? 0;
    int pending = int.tryParse(data['pending'].toString()) ?? 0;
    int total = int.tryParse(data['total_tugas'].toString()) ?? 0;
    String statusKapasitas = data['kapasitas'] ?? "Tersedia";
    double progressPercent = total > 0 ? selesai / total : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderGrey), // Menggunakan border halus
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
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
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: primaryBlue.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.engineering_rounded,
                        color: primaryBlue,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data['teknisi'] ?? "Tanpa Nama",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: statusKapasitas == "Jadwal Penuh"
                                      ? Colors.red
                                      : Colors.green,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                statusKapasitas,
                                style: TextStyle(
                                  color: statusKapasitas == "Jadwal Penuh"
                                      ? Colors.red
                                      : Colors.green,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      color: Colors.grey,
                      size: 20,
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Progress Bar Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Progress Pengerjaan",
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    Text(
                      "${(progressPercent * 100).toInt()}%",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: primaryBlue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progressPercent,
                    backgroundColor: const Color(0xFFF0F2F5),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      progressPercent == 1.0 ? Colors.green : primaryBlue,
                    ),
                    minHeight: 8,
                  ),
                ),

                const SizedBox(height: 16),

                // Stats Box
                Row(
                  children: [
                    _buildStatTile("SELESAI", selesai, Colors.green),
                    const SizedBox(width: 12),
                    _buildStatTile("ANTRIAN", pending, Colors.orange),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatTile(String label, int value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 9,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 2),
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 40),
          Icon(Icons.monitor_heart_outlined, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 10),
          const Text(
            "Belum ada data penugasan.",
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
