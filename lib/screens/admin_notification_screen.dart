import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Gunakan SDK Supabase

class AdminNotificationScreen extends StatefulWidget {
  const AdminNotificationScreen({super.key});

  @override
  State<AdminNotificationScreen> createState() =>
      _AdminNotificationScreenState();
}

class _AdminNotificationScreenState extends State<AdminNotificationScreen> {
  late Future<List<dynamic>> _notifFuture;
  final Color primaryBlue = const Color(0xFF1A56F0);
  
  // Inisialisasi client Supabase
  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _notifFuture = _fetchAllNotifications();
  }

  // Fungsi Pengganti API get_notifications PHP
  Future<List<dynamic>> _fetchAllNotifications() async {
    try {
      // Mengambil data aktivitas dari Supabase diurutkan dari yang terbaru
      final response = await supabase
          .from('pesta_tasks')
          .select()
          .order('created_at', ascending: false);

      final List<dynamic> data = response as List<dynamic>;

      // Tambahkan field 'aksi' secara dinamis berdasarkan status tugas untuk tampilan UI
      return data.map((n) {
        String status = n['status'] ?? '';
        n['aksi'] = (status == 'Selesai') ? "menyelesaikan tugas" : "memperbarui status";
        return n;
      }).toList();
    } catch (e) {
      debugPrint("Error Fetch Notif Supabase: $e");
      return [];
    }
  }

  // MODAL BOTTOM SHEET (Tetap sama, hanya menyesuaikan handling data)
  void _showDetailBottomSheet(Map<String, dynamic> n) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Detail Aktivitas",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(height: 30),

            _itemInfo("Teknisi Pelaksana", n['teknisi'] ?? "-"),
            _itemInfo("ID Pelanggan / Agenda", n['id_pelanggan'] ?? "-"),
            _itemInfo("Nama Pelanggan", n['nama_pelanggan'] ?? "-"),
            _itemInfo("Alamat Lokasi", n['alamat'] ?? "-"),
            _itemInfo("Daya VA", "${n['daya'] ?? '0'} VA"),

            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(child: _itemInfo("Tgl Pasang", n['tgl_pasang'] ?? "-")),
                Expanded(child: _itemInfo("Tgl Bongkar", n['tgl_bongkar'] ?? "-")),
              ],
            ),

            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(15),
              width: double.infinity,
              decoration: BoxDecoration(
                color: primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: primaryBlue.withOpacity(0.2)),
              ),
              child: Text(
                "STATUS AKHIR: ${n['status']}",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: primaryBlue,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "Tutup Detail",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _itemInfo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.grey,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        title: const Text(
          "Riwayat Aktivitas",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _notifFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_toggle_off, size: 60, color: Colors.grey[300]),
                  const SizedBox(height: 10),
                  const Text("Belum ada riwayat aktivitas.", style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _notifFuture = _fetchAllNotifications();
              });
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final n = snapshot.data![index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    onTap: () => _showDetailBottomSheet(n),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: primaryBlue.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.history_edu_rounded, color: primaryBlue, size: 20),
                    ),
                    title: Text(
                      "${n['teknisi'] ?? 'Teknisi'} ${n['aksi']}",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        "Pelanggan: ${n['nama_pelanggan'] ?? '-'}\nID: ${n['id_pelanggan'] ?? '-'}",
                        style: const TextStyle(fontSize: 12, color: Colors.grey, height: 1.4),
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 18),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}