import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/task_service.dart';
import 'admin_task_monitoring_detail.dart';

class AdminSearchTaskScreen extends StatefulWidget {
  const AdminSearchTaskScreen({super.key});

  @override
  State<AdminSearchTaskScreen> createState() => _AdminSearchTaskScreenState();
}

class _AdminSearchTaskScreenState extends State<AdminSearchTaskScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _searchResults = [];
  bool _isSearching = false;

  final Color primaryBlue = const Color(0xFF1A56F0);
  final Color bgGrey = const Color(0xFFF0F2F5);
  final Color borderGrey = const Color(0xFFE0E4E8);

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    setState(() => _isSearching = true);
    final results = await TaskService().searchTasks(query);
    setState(() {
      _searchResults = results;
      _isSearching = false;
    });
  }

  String formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return "-";
    try {
      return DateFormat('d MMM yyyy').format(DateTime.parse(dateStr));
    } catch (e) {
      return "-";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgGrey,
      appBar: AppBar(
        title: const Text("Pencarian Global"),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(70),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: "Cari Agenda / Nama Pelanggan...",
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey),
                  onPressed: () {
                    _searchController.clear();
                    _performSearch("");
                  },
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
              ),
              onChanged: _performSearch,
            ),
          ),
        ),
      ),
      body: _isSearching
          ? Center(child: CircularProgressIndicator(color: primaryBlue))
          : _searchResults.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final task = _searchResults[index];
                    return _buildHistoryCard(task);
                  },
                ),
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> task) {
    bool isSelesai = task['status'] == 'Selesai';
    Color statusColor = isSelesai ? Colors.green : (task['status'] == 'Menunggu Pembongkaran' ? primaryBlue : Colors.orange);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: borderGrey)),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (c) => AdminTaskMonitoringDetail(taskData: task)),
        ),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("AGENDA: ${task['id_pelanggan']}", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: primaryBlue.withOpacity(0.8))),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                    child: Text(task['status'].toUpperCase(), style: TextStyle(color: statusColor, fontSize: 9, fontWeight: FontWeight.w900)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(task['nama_pelanggan'] ?? "", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.engineering, size: 14, color: primaryBlue),
                  const SizedBox(width: 6),
                  Text("Teknisi: ${task['teknisi']}", style: const TextStyle(fontSize: 12, color: Colors.black54)),
                ],
              ),
              const Divider(height: 28, thickness: 0.5),
              Row(
                children: [
                  _infoTile("PASANG", formatDate(task['tgl_pasang'])),
                  const SizedBox(width: 20),
                  _infoTile("BONGKAR", formatDate(task['tgl_bongkar'])),
                  const Spacer(),
                  const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey),
                ],
              ),
            ],
          ),
        ),
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
        const SizedBox(height: 80),
        Icon(Icons.search_off_rounded, size: 80, color: Colors.grey[300]),
        const SizedBox(height: 16),
        Text(
          _searchController.text.isEmpty ? "Cari agenda atau nama pelanggan..." : "Data penugasan tidak ditemukan",
          style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
        ),
      ],
    ),
  );
}