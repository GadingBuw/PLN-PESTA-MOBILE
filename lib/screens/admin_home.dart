import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; 
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'admin_screen.dart';
import 'admin_monitoring_screen.dart';
import 'profile_screen.dart';
import 'manage_tech_screen.dart';
import 'report_screen.dart';
import 'admin_notification_screen.dart';

class AdminHome extends StatefulWidget {
  final UserModel user;
  const AdminHome({super.key, required this.user});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  int _selectedIndex = 0;
  
  final supabase = Supabase.instance.client;

  Map<String, dynamic> stats = {
    "selesai": 0,
    "progress": 0,
    "pending": 0,
  };

  List<dynamic> dynamicNotifs = [];
  List<String> hiddenNotifIds = [];

  @override
  void initState() {
    super.initState();
    _loadHiddenNotifications();
    _refreshAllData();
  }

  Future<void> _loadHiddenNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        hiddenNotifIds = prefs.getStringList('hidden_notifs_${widget.user.username}') ?? [];
      });
    }
  }

  Future<void> _hideNotificationPermanently(String idPelanggan) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      hiddenNotifIds.add(idPelanggan);
    });
    await prefs.setStringList('hidden_notifs_${widget.user.username}', hiddenNotifIds);
  }

  Future<void> _refreshAllData() async {
    await _fetchStats();
    await _fetchNotifications();
  }

  Future<void> _fetchStats() async {
    try {
      final response = await supabase.from('pesta_tasks').select('status');
      final List<dynamic> data = response as List<dynamic>;

      if (mounted) {
        setState(() {
          stats = {
            "selesai": data.where((t) => t['status'] == 'Selesai').length,
            "progress": data.where((t) => t['status'] == 'Menunggu Pembongkaran').length,
            "pending": data.where((t) => t['status'] == 'Menunggu Pemasangan').length,
          };
        });
      }
    } catch (e) {
      debugPrint("Error Stats Supabase: $e");
    }
  }

  Future<void> _fetchNotifications() async {
    try {
      final response = await supabase
          .from('pesta_tasks')
          .select()
          .order('created_at', ascending: false)
          .limit(10);

      if (mounted) {
        setState(() {
          dynamicNotifs = (response as List<dynamic>).map((n) {
            String status = n['status'] ?? '';
            n['aksi'] = (status == 'Selesai') ? "menyelesaikan tugas" : "memperbarui status";
            return n;
          }).toList();
        });
      }
    } catch (e) {
      debugPrint("Error Notif Supabase: $e");
    }
  }

  void _showDetailDialog(Map<String, dynamic> n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Detail Aktivitas", style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _itemInfo("Teknisi", n['teknisi'] ?? "-"),
            _itemInfo("Agenda", n['id_pelanggan'] ?? "-"),
            _itemInfo("Nama", n['nama_pelanggan'] ?? "-"),
            _itemInfo("Alamat", n['alamat'] ?? "-"),
            _itemInfo("Daya", "${n['daya'] ?? '0'} VA"),
            const Divider(),
            _itemInfo("Tgl Pasang", n['tgl_pasang'] ?? "-"),
            _itemInfo("Tgl Bongkar", n['tgl_bongkar'] ?? "-"),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(8),
              width: double.infinity,
              decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(10)),
              child: Text(
                "Status: ${n['status']}",
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Tutup")),
        ],
      ),
    );
  }

  Widget _itemInfo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
          Text(value, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: _selectedIndex == 0 ? _buildAppBar() : null,
      body: [
        _buildBeranda(),
        AdminMonitoringScreen(onBack: () => setState(() => _selectedIndex = 0)),
        ProfileScreen(user: widget.user),
      ][_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -2))]),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          backgroundColor: const Color(0xFFF8F9FA),
          selectedItemColor: const Color(0xFF1A56F0),
          unselectedItemColor: Colors.grey.shade500,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          onTap: (index) => setState(() => _selectedIndex = index),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: "Beranda"),
            BottomNavigationBarItem(icon: Icon(Icons.bar_chart_outlined), activeIcon: Icon(Icons.bar_chart), label: "Monitoring"),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: "Akun"),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Image.asset(
            'assets/images/logo_pln.png',
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => const Icon(Icons.bolt, size: 30, color: Colors.red),
          ),
        ),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Selamat datang,", style: TextStyle(fontSize: 12, color: Colors.grey)),
          Text(widget.user.nama, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
        ],
      ),
      actions: [
        IconButton(onPressed: _refreshAllData, icon: const Icon(Icons.refresh, color: Colors.blue)),
        IconButton(
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (c) => const AdminNotificationScreen())).then((_) => _refreshAllData());
          },
          icon: const Icon(Icons.notifications_none, color: Colors.black54),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildBeranda() {
    return RefreshIndicator(
      onRefresh: _refreshAllData,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildStatHeader(),
          const SizedBox(height: 25),
          _buildMenuGrid(),
          const SizedBox(height: 25),
          const Text("Pemberitahuan Terbaru", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 15),
          Builder(
            builder: (context) {
              final visibleNotifs = dynamicNotifs.where((n) => !hiddenNotifIds.contains(n['id_pelanggan'].toString())).toList();
              if (visibleNotifs.isEmpty) {
                return const Center(child: Padding(padding: EdgeInsets.all(20), child: Text("Belum ada aktivitas baru", style: TextStyle(fontSize: 12, color: Colors.grey))));
              }
              return Column(
                children: visibleNotifs.map((n) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: InkWell(
                      onTap: () => _showDetailDialog(n),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)]),
                        child: Row(
                          children: [
                            Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.notifications_none, color: Colors.blue)),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("${n['teknisi']} ${n['aksi']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                                  Text("Agenda: ${n['id_pelanggan']} - ${n['nama_pelanggan']}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                ],
                              ),
                            ),
                            IconButton(icon: const Icon(Icons.close, size: 18, color: Colors.grey), onPressed: () => _hideNotificationPermanently(n['id_pelanggan'].toString())),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: const Color(0xFF00C7E1), borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Status Pekerjaan Keseluruhan", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildStatBox(Icons.check_circle_outline, stats['selesai'].toString(), "Selesai")),
              const SizedBox(width: 12),
              Expanded(child: _buildStatBox(Icons.access_time, stats['progress'].toString(), "Progress")),
              const SizedBox(width: 12),
              Expanded(child: _buildStatBox(Icons.warning_amber_rounded, stats['pending'].toString(), "Pending")),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox(IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(15)),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildMenuGrid() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15, offset: const Offset(0, 8))]),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMenuIcon(Icons.add, "Input\nPengajuan", () {
            Navigator.push(context, MaterialPageRoute(builder: (c) => const AdminScreen())).then((_) => _refreshAllData());
          }),
          _buildMenuIcon(Icons.bar_chart, "Monitoring\nProgress", () => setState(() => _selectedIndex = 1)),
          
          // PERBAIKAN: Hapus kata 'const' di sini
          _buildMenuIcon(Icons.people_outline, "Kelola\nTeknisi", () {
            Navigator.push(context, MaterialPageRoute(builder: (c) => ManageTechScreen()));
          }),
          
          _buildMenuIcon(Icons.description_outlined, "Laporan", () => Navigator.push(context, MaterialPageRoute(builder: (c) => const ReportScreen()))),
        ],
      ),
    );
  }

  Widget _buildMenuIcon(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 80,
        child: Column(
          children: [
            Container(height: 60, width: 60, decoration: BoxDecoration(color: const Color(0xFF00C7E1), borderRadius: BorderRadius.circular(15)), child: Icon(icon, color: Colors.white, size: 28)),
            const SizedBox(height: 8),
            Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black54, height: 1.2)),
          ],
        ),
      ),
    );
  }
}