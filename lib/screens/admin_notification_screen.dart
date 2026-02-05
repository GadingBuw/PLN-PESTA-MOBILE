import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; 
import 'package:intl/intl.dart'; // Sekarang tidak akan kuning lagi
import '../models/user_model.dart'; 

class AdminNotificationScreen extends StatefulWidget {
  final UserModel user; 
  const AdminNotificationScreen({super.key, required this.user});

  @override
  State<AdminNotificationScreen> createState() =>
      _AdminNotificationScreenState();
}

class _AdminNotificationScreenState extends State<AdminNotificationScreen> {
  late Future<List<dynamic>> _notifFuture;
  final Color primaryBlue = const Color(0xFF1A56F0);
  
  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _notifFuture = _fetchAllNotifications();
  }

  // HELPER: Memformat tanggal agar library 'intl' terpakai dan UI rapi
  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty || dateStr == "-") return "-";
    try {
      DateTime dt = DateTime.parse(dateStr);
      return DateFormat('dd MMM yyyy', 'id_ID').format(dt);
    } catch (e) {
      return dateStr; // Balikkan string asli jika gagal parse
    }
  }

  // FUNGSI UTAMA: Mengambil data aktivitas dengan filter Multi-Unit
  Future<List<dynamic>> _fetchAllNotifications() async {
    try {
      var query = supabase.from('pesta_tasks').select();

      if (widget.user.role.toLowerCase() != 'superadmin') {
        query = query.eq('unit', widget.user.unit);
      }

      final response = await query.order('created_at', ascending: false);
      final List<dynamic> data = response as List<dynamic>;

      return data.map((n) {
        String status = n['status'] ?? '';
        n['aksi'] = (status == 'Selesai') ? "menyelesaikan tugas" : "memperbarui status";
        return n;
      }).toList();
    } catch (e) {
      debugPrint("Error Fetch Notif: $e");
      return [];
    }
  }

  // MODAL BOTTOM SHEET: Menampilkan Detail (TETAP UTUH)
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
                width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 20),
            const Text("Detail Aktivitas", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(height: 30),

            _itemInfo("Teknisi Pelaksana", n['teknisi'] ?? "-"),
            _itemInfo("Unit Kerja", "PLN ULP ${n['unit'] ?? widget.user.unit}"),
            _itemInfo("ID Pelanggan / Agenda", n['no_agenda'] ?? "-"),
            _itemInfo("Nama Pelanggan", n['nama_pelanggan'] ?? "-"),
            _itemInfo("Alamat Lokasi", n['alamat'] ?? "-"),
            _itemInfo("Daya VA", "${n['daya'] ?? '0'} VA"),

            const SizedBox(height: 15),
            Row(
              children: [
                // Menggunakan _formatDate agar intl terpakai
                Expanded(child: _itemInfo("Tgl Pasang", _formatDate(n['tgl_pasang']))),
                Expanded(child: _itemInfo("Tgl Bongkar", _formatDate(n['tgl_bongkar']))),
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
                "STATUS AKHIR: ${n['status']?.toString().toUpperCase()}",
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold, color: primaryBlue, fontSize: 13),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Tutup Detail", style: TextStyle(color: Colors.grey)),
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
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isSuper = widget.user.role.toLowerCase() == 'superadmin';

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isSuper ? "Log Seluruh Unit" : "Log Unit ${widget.user.unit}",
              style: const TextStyle(fontSize: 10, color: Colors.white70),
            ),
            const Text("Riwayat Aktivitas", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
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
                
                // Ambil jam aktivitas untuk mempercantik list
                String activityTime = n['created_at'] != null 
                    ? DateFormat('HH:mm').format(DateTime.parse(n['created_at']))
                    : "--:--";

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
                      decoration: BoxDecoration(color: primaryBlue.withOpacity(0.1), shape: BoxShape.circle),
                      child: Icon(Icons.history_edu_rounded, color: primaryBlue, size: 20),
                    ),
                    title: Text(
                      "${n['teknisi'] ?? 'Teknisi'} ${n['aksi']}",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Pelanggan: ${n['nama_pelanggan'] ?? '-'}\nAgenda: ${n['no_agenda'] ?? '-'}",
                            style: const TextStyle(fontSize: 12, color: Colors.grey, height: 1.4),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("Pukul $activityTime WIB", style: const TextStyle(fontSize: 10, color: Colors.blueGrey, fontWeight: FontWeight.bold)),
                              if (isSuper)
                                Text("Unit: ${n['unit']}", style: TextStyle(fontSize: 10, color: primaryBlue, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ],
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