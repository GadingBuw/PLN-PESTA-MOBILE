import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart'; 
import 'admin_task_monitoring_detail.dart';

class AdminTechHistoryDetail extends StatefulWidget {
  final String username;
  final String nama;

  const AdminTechHistoryDetail({
    super.key,
    required this.username,
    required this.nama,
  });

  @override
  State<AdminTechHistoryDetail> createState() => _AdminTechHistoryDetailState();
}

class _AdminTechHistoryDetailState extends State<AdminTechHistoryDetail> {
  late Future<List<dynamic>> _historyFuture;
  String _activeFilter = 'Semua';

  final supabase = Supabase.instance.client;
  final Color primaryBlue = const Color(0xFF1A56F0);
  final Color bgGrey = const Color(0xFFF0F2F5);
  final Color borderGrey = const Color(0xFFE0E4E8);

  @override
  void initState() {
    super.initState();
    _historyFuture = fetchHistory();
  }

  // LOGIKA HUBUNGI PELANGGAN
  Future<void> _contactCustomer(Map task) async {
    final String phone = task['no_telp'] ?? "";
    if (phone.isEmpty) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Nomor telepon tidak tersedia")));
      return;
    }
    
    String cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanPhone.startsWith('0')) cleanPhone = '62${cleanPhone.substring(1)}';

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text("Hubungi Pelanggan via:", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            ListTile(
              leading: const CircleAvatar(backgroundColor: Colors.green, radius: 15, child: Icon(Icons.chat_bubble_outline, color: Colors.white, size: 16)),
              title: const Text('WhatsApp'),
              onTap: () { Navigator.pop(context); _launchExternalUrl("https://wa.me/$cleanPhone"); },
            ),
            ListTile(
              leading: const Icon(Icons.phone, color: Colors.blue),
              title: const Text('Telepon Reguler'),
              onTap: () { Navigator.pop(context); _launchExternalUrl("tel:+$cleanPhone"); },
            ),
            ListTile(
              leading: const Icon(Icons.sms, color: Colors.orange),
              title: const Text('SMS'),
              onTap: () { Navigator.pop(context); _launchExternalUrl("sms:+$cleanPhone"); },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchExternalUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        throw 'Gagal membuka $urlString';
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<List<dynamic>> fetchHistory() async {
    try {
      final response = await supabase
          .from('pesta_tasks')
          .select()
          .eq('teknisi', widget.username)
          .order('created_at', ascending: false);

      return response as List<dynamic>;
    } catch (e) {
      debugPrint("Error Fetch History: $e");
      return [];
    }
  }

  String formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return "-";
    try {
      return DateFormat('d MMM yyyy').format(DateTime.parse(dateStr));
    } catch (e) { return "-"; }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgGrey,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("MONITORING TEKNISI", style: TextStyle(fontSize: 10, color: Colors.white70, letterSpacing: 1)),
            Text(widget.nama, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [_buildFilterDropdown()],
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _historyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: primaryBlue));
          }

          final allData = snapshot.data ?? [];
          List<dynamic> filteredSource = allData.where((item) {
            if (_activeFilter == 'Semua') return true;
            if (_activeFilter == 'Pemasangan') return item['status'] == 'Menunggu Pemasangan';
            if (_activeFilter == 'Pembongkaran') return item['status'] == 'Menunggu Pembongkaran';
            return true;
          }).toList();

          List<dynamic> activeTasks = filteredSource.where((item) => item['status'] != 'Selesai').toList();
          List<dynamic> completedTasks = filteredSource.where((item) => item['status'] == 'Selesai').toList();

          return RefreshIndicator(
            onRefresh: () async => setState(() { _historyFuture = fetchHistory(); }),
            child: ListView(
              padding: const EdgeInsets.all(15),
              children: [
                if (activeTasks.isNotEmpty) ...[
                  _buildSectionTitle(_activeFilter == 'Semua' ? "PENUGASAN AKTIF" : "FILTER: $_activeFilter"),
                  ...activeTasks.map((task) => _buildHistoryCard(task)).toList(),
                ],
                if (_activeFilter == 'Semua' && completedTasks.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _buildSectionTitle("RIWAYAT SELESAI"),
                  ...completedTasks.map((task) => _buildHistoryCard(task)).toList(),
                ],
                if (activeTasks.isEmpty && (completedTasks.isEmpty || _activeFilter != 'Semua')) _buildEmptyState(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterDropdown() {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _activeFilter,
          dropdownColor: primaryBlue,
          icon: const Icon(Icons.filter_list, color: Colors.white),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
          items: ['Semua', 'Pemasangan', 'Pembongkaran'].map((val) => DropdownMenuItem(value: val, child: Text(val))).toList(),
          onChanged: (val) { if (val != null) setState(() => _activeFilter = val); },
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) => Padding(
    padding: const EdgeInsets.only(left: 5, bottom: 12, top: 5),
    child: Text(title, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.blueGrey[800], letterSpacing: 1.2)),
  );

  Widget _buildHistoryCard(Map<String, dynamic> task) {
    bool isSelesai = task['status'] == 'Selesai';
    Color statusColor = isSelesai ? Colors.green : (task['status'] == 'Menunggu Pembongkaran' ? primaryBlue : Colors.orange);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: borderGrey)),
      child: Column(
        children: [
          InkWell(
            onTap: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (c) => AdminTaskMonitoringDetail(taskData: task)));
              setState(() { _historyFuture = fetchHistory(); });
            },
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("AGENDA: ${task['no_agenda']}", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: primaryBlue.withOpacity(0.8))),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                        child: Text(task['status'].toString().toUpperCase(), style: TextStyle(color: statusColor, fontSize: 9, fontWeight: FontWeight.w900)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(task['nama_pelanggan'] ?? "", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.location_on_rounded, size: 14, color: primaryBlue),
                      const SizedBox(width: 6),
                      Expanded(child: Text(task['alamat'] ?? "", style: const TextStyle(fontSize: 12, color: Colors.black54), maxLines: 1, overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Icon(Icons.phone_android_rounded, size: 14, color: Colors.blueGrey[400]),
                const SizedBox(width: 6),
                Text(task['no_telp'] ?? "No. Telp Tidak Ada", style: TextStyle(fontSize: 12, color: Colors.blueGrey[700], fontWeight: FontWeight.w500)),
                const Spacer(),
                if (task['no_telp'] != null)
                  TextButton.icon(
                    onPressed: () => _contactCustomer(task),
                    style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12), minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                    icon: const Icon(Icons.chat_bubble_outline, size: 16, color: Colors.green),
                    label: const Text("HUBUNGI", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green)),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _infoTile("PASANG", formatDate(task['tgl_pasang'])),
                const SizedBox(width: 20),
                _infoTile("BONGKAR", formatDate(task['tgl_bongkar'])),
                const Spacer(),
                const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoTile(String label, String val) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(fontSize: 8, color: Colors.grey, fontWeight: FontWeight.w600)),
      const SizedBox(height: 2),
      Text(val, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.black87)),
    ],
  );

  Widget _buildEmptyState() => Center(
    child: Column(
      children: [
        const SizedBox(height: 60),
        Icon(Icons.assignment_outlined, size: 70, color: Colors.grey[300]),
        const SizedBox(height: 16),
        const Text("Tidak ada penugasan", style: TextStyle(color: Colors.grey)),
      ],
    ),
  );
}