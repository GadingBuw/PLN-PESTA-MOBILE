import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'admin_tech_history_detail.dart';
import 'admin_search_task_screen.dart'; // Import ditambahkan di sini

class AdminMonitoringScreen extends StatefulWidget {
  final VoidCallback? onBack;
  const AdminMonitoringScreen({super.key, this.onBack});

  @override
  State<AdminMonitoringScreen> createState() => _AdminMonitoringScreenState();
}

class _AdminMonitoringScreenState extends State<AdminMonitoringScreen> {
  // 1. Definisikan Stream untuk memantau tabel 'pesta_tasks'
  late final Stream<List<Map<String, dynamic>>> _monitoringStream;
  final supabase = Supabase.instance.client;

  final Color primaryBlue = const Color(0xFF1A56F0);
  final Color bgGrey = const Color(0xFFF0F2F5);
  final Color borderGrey = const Color(0xFFE0E4E8);

  @override
  void initState() {
    super.initState();
    // 2. Inisialisasi stream. 'id' adalah primary key tabel Anda
    _monitoringStream = supabase
        .from('pesta_tasks')
        .stream(primaryKey: ['id'])
        .order('created_at'); // Mengurutkan data di dalam stream
  }

  // 3. Fungsi pembantu untuk mengelompokkan data stream per teknisi
  List<dynamic> _processStreamData(List<Map<String, dynamic>> allTasks) {
    Map<String, Map<String, dynamic>> techStats = {};

    for (var task in allTasks) {
      String techName = task['teknisi'] ?? "Tanpa Nama";
      String status = task['status'] ?? "";

      if (!techStats.containsKey(techName)) {
        techStats[techName] = {
          'teknisi': techName,
          'selesai': 0,
          'pending': 0,
          'total_tugas': 0,
        };
      }

      techStats[techName]!['total_tugas']++;
      if (status == 'Selesai') {
        techStats[techName]!['selesai']++;
      } else {
        techStats[techName]!['pending']++;
      }
    }

    return techStats.values.map((data) {
      int pending = data['pending'];
      data['kapasitas'] = (pending >= 5) ? "Jadwal Penuh" : "Tersedia";
      return data;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgGrey,
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
        // FITUR SEARCH DITAMBAHKAN DI SINI
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (c) => const AdminSearchTaskScreen(),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      // 4. Gunakan StreamBuilder sebagai pengganti FutureBuilder
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _monitoringStream,
        builder: (context, snapshot) {
          // Tampilan saat loading data pertama kali
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Tampilan jika error
          if (snapshot.hasError) {
            return Center(
              child: Text("Terjadi kesalahan realtime: ${snapshot.error}"),
            );
          }

          // Proses data mentah dari stream menjadi daftar teknisi
          final List<dynamic> listData = _processStreamData(
            snapshot.data ?? [],
          );

          return ListView(
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
              const Row(
                children: [
                  Icon(Icons.bolt, size: 12, color: Colors.green),
                  SizedBox(width: 4),
                  Text(
                    "Data diperbarui secara otomatis (Realtime)",
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (listData.isEmpty)
                _buildEmptyState()
              else
                ...listData.map((data) => _buildTechnicianCard(data)).toList(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTechnicianCard(Map<String, dynamic> data) {
    int selesai = data['selesai'];
    int total = data['total_tugas'];
    int pending = data['pending'];
    String statusKapasitas = data['kapasitas'];
    double progressPercent = total > 0 ? selesai / total : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderGrey),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (c) => AdminTechHistoryDetail(
                username: data['teknisi'] ?? '',
                nama: data['teknisi'] ?? '',
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
                          data['teknisi'],
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
                  const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
                ],
              ),
              const SizedBox(height: 20),
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
            Text(
              value.toString(),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        children: [
          SizedBox(height: 40),
          Icon(Icons.monitor_heart_outlined, size: 60, color: Colors.grey),
          SizedBox(height: 10),
          Text(
            "Belum ada data penugasan.",
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
