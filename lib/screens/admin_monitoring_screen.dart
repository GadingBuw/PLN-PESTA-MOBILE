import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart'; // Digunakan agar tidak kuning/warning
import '../models/user_model.dart';
import 'admin_tech_history_detail.dart';
import 'admin_search_task_screen.dart';

class AdminMonitoringScreen extends StatefulWidget {
  final UserModel user; // Tambahkan ini agar data user diterima
  final VoidCallback? onBack;
  const AdminMonitoringScreen({super.key, this.onBack, required this.user});

  @override
  State<AdminMonitoringScreen> createState() => _AdminMonitoringScreenState();
}

class _AdminMonitoringScreenState extends State<AdminMonitoringScreen> {
  // 1. Definisikan Stream untuk memantau tabel 'pesta_tasks' secara realtime
  late final Stream<List<Map<String, dynamic>>> _monitoringStream;
  final supabase = Supabase.instance.client;

  // 2. Map bantu untuk menyimpan data nomor HP teknisi dari tabel 'users'
  Map<String, String> techPhones = {};

  final Color primaryBlue = const Color(0xFF1A56F0);
  final Color bgGrey = const Color(0xFFF0F2F5);
  final Color borderGrey = const Color(0xFFE0E4E8);

  @override
  void initState() {
    super.initState();
    
    // Memuat data profil teknisi (Nomor HP)
    _fetchTechDetails();

    // LOGIKA MULTI-UNIT: Inisialisasi stream realtime Supabase
    var query = supabase.from('pesta_tasks').stream(primaryKey: ['id']);

    // Jika bukan superadmin, kunci monitoring hanya pada unit admin tsb
    if (widget.user.role.toLowerCase() != 'superadmin') {
      _monitoringStream = query
          .eq('unit', widget.user.unit)
          .order('created_at')
          .map((data) => data); // .map digunakan untuk memastikan sinkronisasi tipe data (anti-merah)
    } else {
      _monitoringStream = query
          .order('created_at')
          .map((data) => data);
    }
  }

  // FITUR: Logika Hubungi Teknisi (TETAP ADA)
  Future<void> _contactTechnician(String phone, String name) async {
    if (phone == "Belum diatur" || phone.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Petugas belum mendaftarkan nomor HP di profil")),
        );
      }
      return;
    }

    String cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanPhone.startsWith('0')) {
      cleanPhone = '62${cleanPhone.substring(1)}';
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  "Hubungi Petugas: $name",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.green,
                  radius: 15,
                  child: Icon(Icons.chat_bubble_outline, color: Colors.white, size: 16),
                ),
                title: const Text('Kirim WhatsApp'),
                onTap: () {
                  Navigator.pop(context);
                  _launchExternalUrl("https://wa.me/$cleanPhone");
                },
              ),
              ListTile(
                leading: const Icon(Icons.phone, color: Colors.blue),
                title: const Text('Telepon Reguler (Seluler)'),
                onTap: () {
                  Navigator.pop(context);
                  _launchExternalUrl("tel:+$cleanPhone");
                },
              ),
              ListTile(
                leading: const Icon(Icons.sms, color: Colors.orange),
                title: const Text('Kirim SMS'),
                onTap: () {
                  Navigator.pop(context);
                  _launchExternalUrl("sms:+$cleanPhone");
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  // Helper untuk membuka URL (WhatsApp/Telp/SMS)
  Future<void> _launchExternalUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        throw 'Tidak bisa membuka aplikasi';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal membuka aplikasi: $e")),
        );
      }
    }
  }

  // FUNGSI: Mengambil data nomor HP (Filter per unit jika bukan Superadmin)
  Future<void> _fetchTechDetails() async {
    try {
      var query = supabase.from('users').select('username, phone').eq('role', 'teknisi');

      if (widget.user.role.toLowerCase() != 'superadmin') {
        query = query.eq('unit', widget.user.unit);
      }

      final response = await query;
      final List<dynamic> data = response as List;
      
      if (mounted) {
        setState(() {
          for (var item in data) {
            String uname = item['username'] ?? '';
            String ph = item['phone'] ?? "Belum diatur";
            techPhones[uname] = ph;
          }
        });
      }
    } catch (e) {
      debugPrint("Sinkronisasi kontak teknisi gagal: $e");
    }
  }

  // FUNGSI: Mengolah data stream menjadi statistik per petugas
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
      int pendingCount = data['pending'];
      data['kapasitas'] = (pendingCount >= 5) ? "Jadwal Penuh" : "Tersedia";
      return data;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    bool isSuper = widget.user.role.toLowerCase() == 'superadmin';

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
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isSuper ? "Monitoring Seluruh Unit" : "Monitoring Unit ${widget.user.unit}",
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
            const Text(
              "Progress Global Teknisi",
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AdminSearchTaskScreen(),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _monitoringStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(strokeWidth: 3));
          }

          if (snapshot.hasError) {
            return Center(child: Text("Kesalahan Realtime: ${snapshot.error}", style: const TextStyle(color: Colors.red)));
          }

          final List<dynamic> listData = _processStreamData(snapshot.data ?? []);

          return RefreshIndicator(
            onRefresh: () async {
              await _fetchTechDetails();
              setState(() {});
            },
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text(
                  "Status Petugas Lapangan",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF444444)),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.bolt, size: 12, color: Colors.green),
                    const SizedBox(width: 4),
                    Text(
                      "Update Otomatis: ${DateFormat('HH:mm').format(DateTime.now())}",
                      style: const TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                
                if (listData.isEmpty)
                  _buildEmptyState()
                else
                  ...listData.map((data) => _buildTechnicianCard(data)).toList(),
                
                const SizedBox(height: 50),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTechnicianCard(Map<String, dynamic> data) {
    int selesai = data['selesai'];
    int total = data['total_tugas'];
    int pending = data['pending'];
    String techUser = data['teknisi'];
    String statusKapasitas = data['kapasitas'];
    String techPhone = techPhones[techUser] ?? "Memuat nomor...";

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
              builder: (context) => AdminTechHistoryDetail(
                username: techUser,
                nama: techUser,
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
                    decoration: BoxDecoration(color: primaryBlue.withOpacity(0.1), shape: BoxShape.circle),
                    child: Icon(Icons.engineering_rounded, color: primaryBlue, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(techUser.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Icon(Icons.phone_android, size: 12, color: primaryBlue),
                            const SizedBox(width: 4),
                            Text(techPhone, style: TextStyle(fontSize: 11, color: primaryBlue, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => _contactTechnician(techPhone, techUser),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      minimumSize: const Size(0, 34),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      elevation: 0,
                    ),
                    child: const Text("HUBUNGI", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Progress Pengerjaan", style: TextStyle(fontSize: 11, color: Colors.grey)),
                  Text("${(progressPercent * 100).toInt()}%", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryBlue)),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progressPercent,
                  backgroundColor: const Color(0xFFF0F2F5),
                  valueColor: AlwaysStoppedAnimation<Color>(progressPercent == 1.0 ? Colors.green : primaryBlue),
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
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: statusKapasitas == "Jadwal Penuh" ? Colors.red.withOpacity(0.05) : Colors.green.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    statusKapasitas,
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusKapasitas == "Jadwal Penuh" ? Colors.red : Colors.green),
                  ),
                ),
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
            Text(label, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
            const SizedBox(height: 2),
            Text(value.toString(), style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 60),
          Icon(Icons.monitor_heart_outlined, size: 70, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text("Belum ada data penugasan yang masuk.", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}