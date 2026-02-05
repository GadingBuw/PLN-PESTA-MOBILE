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

  Map<String, dynamic> stats = {"selesai": 0, "progress": 0, "pending": 0};

  List<dynamic> dynamicNotifs = [];
  List<String> hiddenNotifIds = [];

  @override
  void initState() {
    super.initState();
    _loadHiddenNotifications();
    _refreshAllData();
  }

  // FITUR: Sembunyikan notifikasi secara permanen di HP Admin ini
  Future<void> _loadHiddenNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        hiddenNotifIds =
            prefs.getStringList('hidden_notifs_${widget.user.username}') ?? [];
      });
    }
  }

  Future<void> _hideNotificationPermanently(String noAgenda) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      hiddenNotifIds.add(noAgenda);
    });
    await prefs.setStringList(
      'hidden_notifs_${widget.user.username}',
      hiddenNotifIds,
    );
  }

  Future<void> _refreshAllData() async {
    await _fetchStats();
    await _fetchNotifications();
  }

  // FITUR: Ambil statistik pengerjaan (Filter per unit jika bukan Superadmin)
  Future<void> _fetchStats() async {
    try {
      var query = supabase.from('pesta_tasks').select('status, unit');
      
      // LOGIKA MULTI-UNIT:
      if (widget.user.role != 'superadmin') {
        query = query.eq('unit', widget.user.unit);
      }

      final response = await query;
      final List<dynamic> data = response as List<dynamic>;

      if (mounted) {
        setState(() {
          stats = {
            "selesai": data.where((t) => t['status'] == 'Selesai').length,
            "progress": data
                .where((t) => t['status'] == 'Menunggu Pembongkaran')
                .length,
            "pending": data
                .where((t) => t['status'] == 'Menunggu Pemasangan')
                .length,
          };
        });
      }
    } catch (e) {
      debugPrint("Error Stats: $e");
    }
  }

  // FITUR: Ambil notifikasi aktivitas terbaru (Filter per unit jika bukan Superadmin)
  Future<void> _fetchNotifications() async {
    try {
      var query = supabase.from('pesta_tasks').select();
      
      if (widget.user.role != 'superadmin') {
        query = query.eq('unit', widget.user.unit);
      }

      final response = await query
          .order('created_at', ascending: false)
          .limit(10);

      if (mounted) {
        setState(() {
          dynamicNotifs = (response as List<dynamic>).map((n) {
            String status = n['status'] ?? '';
            n['aksi'] = (status == 'Selesai')
                ? "menyelesaikan tugas"
                : "memperbarui status";
            return n;
          }).toList();
        });
      }
    } catch (e) {
      debugPrint("Error Notif: $e");
    }
  }

  // FITUR: Pop up Detail Aktivitas (Bottom Sheet) - TETAP ADA
  void _showDetailBottomSheet(Map<String, dynamic> n) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 45,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 25),
            const Text(
              "Detail Aktivitas",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Divider(),
            const SizedBox(height: 20),
            _buildDetailItem("Teknisi Pelaksana", n['teknisi'] ?? "-"),
            _buildDetailItem("Asal Unit", "PLN ULP ${n['unit'] ?? widget.user.unit}"),
            _buildDetailItem("Nomor Agenda", n['no_agenda'] ?? "-"),
            _buildDetailItem("Nama Pelanggan", n['nama_pelanggan'] ?? "-"),
            _buildDetailItem("Alamat Lokasi", n['alamat'] ?? "-"),
            _buildDetailItem("Daya VA", "${n['daya'] ?? '0'} VA"),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildDetailItem("Tgl Pasang", n['tgl_pasang'] ?? "-"),
                ),
                Expanded(
                  child: _buildDetailItem(
                    "Tgl Bongkar",
                    n['tgl_bongkar'] ?? "-",
                  ),
                ),
              ],
            ),
            const SizedBox(height: 25),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                color: const Color(0xFFE8EFFF),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Text(
                "STATUS AKHIR: ${n['status']?.toString().toUpperCase()}",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF1A56F0),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "Tutup Detail",
                  style: TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.grey,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
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
        AdminMonitoringScreen(
          user: widget.user, 
          onBack: () => setState(() => _selectedIndex = 0)
        ),
        ProfileScreen(user: widget.user),
      ][_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF1A56F0),
          unselectedItemColor: Colors.grey.shade500,
          type: BottomNavigationBarType.fixed,
          onTap: (index) => setState(() => _selectedIndex = index),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: "Beranda",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_outlined),
              activeIcon: Icon(Icons.bar_chart),
              label: "Monitoring",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: "Akun",
            ),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    bool isSuper = widget.user.role.toLowerCase() == 'superadmin';
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.asset(
            'assets/images/logo_pln.png',
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.bolt, size: 30, color: Colors.red),
          ),
        ),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isSuper ? "Admin Pusat (Seluruh Unit)" : "Admin PLN Unit ${widget.user.unit}",
            style: const TextStyle(fontSize: 10, color: Colors.blue, fontWeight: FontWeight.bold),
          ),
          Text(
            widget.user.nama,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: _refreshAllData,
          icon: const Icon(Icons.refresh, color: Colors.blue),
        ),
        IconButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (c) => AdminNotificationScreen(user: widget.user)),
          ),
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
          const Text(
            "Pemberitahuan Terbaru",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 15),
          _buildNotificationList(),
        ],
      ),
    );
  }

  Widget _buildNotificationList() {
    final visibleNotifs = dynamicNotifs
        .where((n) => !hiddenNotifIds.contains(n['no_agenda'].toString()))
        .toList();
    if (visibleNotifs.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Text(
            "Belum ada aktivitas baru",
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }
    return Column(
      children: visibleNotifs
          .map(
            (n) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () => _showDetailBottomSheet(n),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.notifications_none,
                          color: Colors.blue,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "${n['teknisi']} ${n['aksi']}",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              "${n['no_agenda']} - ${n['nama_pelanggan']}",
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            if (widget.user.role == 'superadmin')
                              Text(
                                "Unit: ${n['unit']}",
                                style: const TextStyle(fontSize: 10, color: Colors.orange, fontWeight: FontWeight.bold),
                              ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.close,
                          size: 16,
                          color: Colors.grey,
                        ),
                        onPressed: () => _hideNotificationPermanently(
                          n['no_agenda'].toString(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildStatHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF00C7E1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.user.role == 'superadmin' ? "Status Pekerjaan Seluruh Unit" : "Status Pekerjaan Unit ${widget.user.unit}",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatBox(
                  Icons.check_circle_outline,
                  stats['selesai'].toString(),
                  "Selesai",
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatBox(
                  Icons.access_time,
                  stats['progress'].toString(),
                  "Progress",
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatBox(
                  Icons.warning_amber_rounded,
                  stats['pending'].toString(),
                  "Pending",
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox(IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuGrid() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildMenuIcon(
            Icons.add,
            "Input",
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (c) => AdminScreen(user: widget.user)),
            ).then((_) => _refreshAllData()),
          ),
          _buildMenuIcon(
            Icons.bar_chart,
            "Monitoring",
            () => setState(() => _selectedIndex = 1),
          ),
          _buildMenuIcon(
            Icons.people_outline,
            "Teknisi",
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (c) => ManageTechScreen(user: widget.user)),
            ),
          ),
          _buildMenuIcon(
            Icons.description_outlined,
            "Laporan",
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (c) => ReportScreen(user: widget.user)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuIcon(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            height: 55,
            width: 55,
            decoration: BoxDecoration(
              color: const Color(0xFF00C7E1),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, color: Colors.white, size: 26),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}