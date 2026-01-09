import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../main.dart';

class AdminMonitoringScreen extends StatefulWidget {
  const AdminMonitoringScreen({super.key});

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
      final response = await http.get(Uri.parse("$baseUrl?action=get_monitoring"));
      if (response.statusCode == 200) {
        // Tambahkan print untuk debug di console jika masih kosong
        print("Response Monitoring: ${response.body}");
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      debugPrint("Gagal memuat monitoring: $e");
      return [];
    }
  }

  Future<void> _refreshData() async {
    setState(() {
      _monitoringFuture = fetchMonitoring();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F9),
      body: FutureBuilder<List<dynamic>>(
        future: _monitoringFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return RefreshIndicator(
              onRefresh: _refreshData,
              child: ListView(
                children: const [
                  SizedBox(height: 200),
                  Center(child: Text("Belum ada data penugasan teknisi.")),
                ],
              ),
            );
          }
          
          return RefreshIndicator(
            onRefresh: _refreshData,
            child: ListView.builder(
              padding: const EdgeInsets.all(15),
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                var data = snapshot.data![index];
                
                String namaTeknisi = (data['teknisi'] ?? "Tanpa Nama").toString();
                String statusKapasitas = (data['kapasitas'] ?? "Tersedia").toString();
                bool isFull = statusKapasitas == "Jadwal Penuh";
                
                return Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  margin: const EdgeInsets.only(bottom: 15),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(15),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const CircleAvatar(
                              backgroundColor: Color(0xFFE3F2FD), 
                              child: Icon(Icons.person, color: Colors.blue)
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    namaTeknisi.toUpperCase(), 
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                                  ),
                                  const Text("Teknisi Lapangan", 
                                    style: TextStyle(color: Colors.grey, fontSize: 12)),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: isFull ? Colors.red[50] : Colors.green[50], 
                                borderRadius: BorderRadius.circular(10)
                              ),
                              child: Text(
                                statusKapasitas, 
                                style: TextStyle(
                                  fontSize: 10, 
                                  color: isFull ? Colors.red : Colors.green, 
                                  fontWeight: FontWeight.bold
                                )
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 30),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _statCol("TOTAL", (data['total_tugas'] ?? "0").toString()),
                            _statCol("SELESAI", (data['selesai'] ?? "0").toString()),
                            _statCol("PENDING", (data['pending'] ?? "0").toString()),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _statCol(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
      ],
    );
  }
}