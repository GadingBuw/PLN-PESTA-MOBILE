import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../models/user_model.dart';
import '../services/notification_service.dart';
import 'tech_detail_screen.dart';
import 'tech_history_screen.dart';
import 'profile_screen.dart';

class TechHome extends StatefulWidget {
  final UserModel user;
  const TechHome({super.key, required this.user});

  @override
  State<TechHome> createState() => _TechHomeState();
}

class _TechHomeState extends State<TechHome> {
  int _currentIndex = 0;
  late Future<List<dynamic>> _taskFuture;
  final supabase = Supabase.instance.client;

  int pending = 0;
  int progress = 0;
  int selesai = 0;
  int terlambat = 0;

  @override
  void initState() {
    super.initState();
    _taskFuture = fetchAllTasks();
  }

  // LOGIKA UTAMA: Mengambil data dan menghitung status H-1 secara akurat
  Future<List<dynamic>> fetchAllTasks() async {
    try {
<<<<<<< HEAD
      final response = await http.get(
        Uri.parse(
          "$baseUrl?action=get_all_tasks&teknisi=${widget.user.username}",
        ),
      );
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        _calculateStats(data);
        return data;
=======
      final DateTime now = DateTime.now();
      final String firstDayOfMonth = DateFormat('yyyy-MM-01').format(now);

      final response = await supabase
          .from('pesta_tasks')
          .select()
          .eq('teknisi', widget.user.username)
          .or('status.neq.Selesai,tgl_pasang.gte.$firstDayOfMonth')
          .order('tgl_pasang', ascending: true);

      List<dynamic> data = response as List<dynamic>;

      final String todayStr = DateFormat('yyyy-MM-dd').format(now);
      // Mendapatkan tanggal besok untuk validasi pengerjaan H-1
      final String tomorrowStr = DateFormat('yyyy-MM-dd').format(now.add(const Duration(days: 1)));
      
      for (var task in data) {
        String status = task['status'] ?? '';
        String tglP = task['tgl_pasang'] ?? '';
        String tglB = task['tgl_bongkar'] ?? '';

        // REVISI LOGIKA AKTIF: 
        // Pemasangan dianggap aktif jika dijadwalkan hari ini ATAU besok (H-1)
        // Pembongkaran tetap hanya aktif jika dijadwalkan hari ini
        bool isHariIni = (status == 'Menunggu Pemasangan' && (tglP == todayStr || tglP == tomorrowStr)) ||
                         (status == 'Menunggu Pembongkaran' && tglB == todayStr);
        
        // Logika Terlambat: Jika tanggal sudah lewat dari hari ini
        bool isTelat = (status == 'Menunggu Pemasangan' && tglP.compareTo(todayStr) < 0) ||
                       (status == 'Menunggu Pembongkaran' && tglB.compareTo(todayStr) < 0);

        task['is_hari_ini'] = isHariIni ? "1" : "0";
        task['is_telat'] = isTelat ? "1" : "0";

        // Memicu notifikasi instan untuk tugas yang sudah bisa dieksekusi (Hari ini / H-1)
        if (isHariIni && status != 'Selesai') {
          NotificationService.showInstantNotification(task);
        }
>>>>>>> EditArya
      }

      _calculateStats(data);
      return data;
    } catch (e) {
      debugPrint("Error Supabase TechHome: $e");
      throw "Koneksi Bermasalah";
    }
  }

  // Menghitung statistik berdasarkan data yang diambil
  void _calculateStats(List<dynamic> tasks) {
    if (mounted) {
      setState(() {
<<<<<<< HEAD
        terlambat = tasks.where((t) => t['is_telat'].toString() == "1").length;
        pending = tasks
            .where(
              (t) =>
                  t['status'] == 'Menunggu Pemasangan' &&
                  t['is_telat'].toString() == "0",
            )
            .length;
        progress = tasks
            .where(
              (t) =>
                  t['status'] == 'Menunggu Pembongkaran' &&
                  t['is_telat'].toString() == "0",
            )
            .length;
=======
        terlambat = tasks.where((t) => t['is_telat'] == "1").length;

        pending = tasks.where((t) => 
          t['status'] == 'Menunggu Pemasangan' && t['is_telat'] == "0"
        ).length;

        progress = tasks.where((t) => 
          t['status'] == 'Menunggu Pembongkaran' && t['is_telat'] == "0"
        ).length;

>>>>>>> EditArya
        selesai = tasks.where((t) => t['status'] == 'Selesai').length;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
<<<<<<< HEAD
      appBar: _currentIndex == 0
          ? AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              leading: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.yellow,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.bolt, color: Colors.red, size: 20),
                ),
              ),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Selamat datang,",
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  Text(
                    widget.user.nama,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  onPressed: () {},
                  icon: const Icon(
                    Icons.notifications_none,
                    color: Colors.black54,
                  ),
                ),
              ],
            )
          : null,
=======
      appBar: _currentIndex == 0 ? _buildAppBar() : null,
>>>>>>> EditArya
      body: [
        _buildHomeContent(),
        TechHistoryScreen(user: widget.user),
        ProfileScreen(user: widget.user),
      ][_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: const Color(0xFF1A56F0),
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
<<<<<<< HEAD
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: "Beranda",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: "Riwayat"),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: "Akun",
          ),
=======
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: "Beranda"),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: "Riwayat"),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: "Akun"),
>>>>>>> EditArya
        ],
      ),
    );
  }

  // --- WIDGET HELPER: APPBAR ---
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
            errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.bolt, size: 30, color: Colors.red),
          ),
        ),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Selamat datang,", style: TextStyle(fontSize: 11, color: Colors.grey)),
          Text(
            widget.user.nama,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black),
          ),
        ],
      ),
    );
  }

  // --- WIDGET HELPER: HOME CONTENT ---
  Widget _buildHomeContent() {
    return RefreshIndicator(
<<<<<<< HEAD
      onRefresh: () async => setState(() {
        _taskFuture = fetchAllTasks();
      }),
      child: ListView(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(color: Color(0xFF1A56F0)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "PESTA MOBILE - ULP PACITAN",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 15),
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: Color(0xFF00C7E1),
                        child: Icon(Icons.engineering, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Petugas Lapangan",
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              widget.user.nama,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        children: [
                          const Text(
                            "Total Tugas",
                            style: TextStyle(fontSize: 10, color: Colors.grey),
                          ),
                          Text(
                            (pending + progress + terlambat).toString(),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Color(0xFF1A56F0),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(15),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF00C7E1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatBox(
                    terlambat.toString(),
                    "Terlambat",
                    Icons.warning_amber,
                  ),
                  _buildStatBox(
                    (pending + progress).toString(),
                    "Pending",
                    Icons.access_time,
                  ),
                  _buildStatBox(
                    selesai.toString(),
                    "Selesai",
                    Icons.check_circle_outline,
                  ),
                ],
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 10, 20, 10),
            child: Text(
              "Daftar Penugasan Aktif",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
=======
      onRefresh: () async => setState(() { _taskFuture = fetchAllTasks(); }),
      child: ListView(
        children: [
          _buildBlueHeader(),
          _buildStatSection(),
>>>>>>> EditArya
          FutureBuilder<List<dynamic>>(
            future: _taskFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting)
                return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()));
              if (!snapshot.hasData || snapshot.data!.isEmpty)
<<<<<<< HEAD
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: Text("Tidak ada tugas hari ini."),
                  ),
                );
=======
                return const Center(child: Padding(padding: EdgeInsets.all(40), child: Text("Tidak ada tugas.")));

              // Memisahkan tugas aktif (Hari ini, H-1, Terlambat) dan tugas akan datang
              final activeTasks = snapshot.data!.where((t) => 
                t['is_hari_ini'] == "1" || t['is_telat'] == "1"
              ).toList();

              final futureTasks = snapshot.data!.where((t) => 
                t['is_hari_ini'] == "0" && t['is_telat'] == "0" && t['status'] != 'Selesai'
              ).toList();

>>>>>>> EditArya
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle("Daftar Penugasan Aktif"),
                  if (activeTasks.isEmpty) _buildEmptyInfo("Tidak ada tugas aktif hari ini.")
                  else ...activeTasks.map((t) => _buildTaskCard(t)).toList(),
                  
                  const SizedBox(height: 15),
                  
                  _buildSectionTitle("Penugasan Akan Datang"),
                  if (futureTasks.isEmpty) _buildEmptyInfo("Belum ada tugas terjadwal selanjutnya.")
                  else ...futureTasks.map((t) => _buildTaskCard(t)).toList(),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

<<<<<<< HEAD
=======
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
    );
  }

  Widget _buildEmptyInfo(String text) {
    return Center(child: Padding(padding: const EdgeInsets.all(20), child: Text(text, style: const TextStyle(fontSize: 12, color: Colors.grey))));
  }

  Widget _buildBlueHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(color: Color(0xFF1A56F0)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("PESTA MOBILE - ULP PACITAN", style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
            child: Row(
              children: [
                const CircleAvatar(backgroundColor: Color(0xFF00C7E1), child: Icon(Icons.engineering, color: Colors.white)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Petugas Lapangan", style: TextStyle(fontSize: 10, color: Colors.grey)),
                      Text(widget.user.nama, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                ),
                Column(
                  children: [
                    const Text("Total Tugas", style: TextStyle(fontSize: 10, color: Colors.grey)),
                    Text((pending + progress + terlambat).toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1A56F0))),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF00C7E1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatBox(terlambat.toString(), "Terlambat", Icons.warning_amber_rounded),
            Container(width: 1, height: 30, color: Colors.white24),
            _buildStatBox((pending + progress).toString(), "Antrian", Icons.access_time),
            Container(width: 1, height: 30, color: Colors.white24),
            _buildStatBox(selesai.toString(), "Selesai", Icons.check_circle_outline),
          ],
        ),
      ),
    );
  }

>>>>>>> EditArya
  Widget _buildStatBox(String val, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
<<<<<<< HEAD
        const SizedBox(height: 4),
        Text(
          val,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 10)),
=======
        const SizedBox(height: 6),
        Text(val, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w500)),
>>>>>>> EditArya
      ],
    );
  }

  // --- WIDGET HELPER: TASK CARD (REVISI LABEL & H-1) ---
  Widget _buildTaskCard(Map t) {
<<<<<<< HEAD
    bool isTelat = t['is_telat'].toString() == "1";
    bool isBongkar = t['status'].toString().toLowerCase().contains('bongkar');
    Color themeColor = isTelat
        ? Colors.red
        : (isBongkar ? Colors.orange : Colors.green);
=======
    bool isTelat = t['is_telat'] == "1";
    bool isHariIni = t['is_hari_ini'] == "1";
    bool isBongkar = t['status'].toString().toLowerCase().contains('bongkar');

    // Identifikasi khusus untuk penugasan H-1
    final String tomorrowStr = DateFormat('yyyy-MM-dd').format(DateTime.now().add(const Duration(days: 1)));
    bool isHMinus1 = t['status'] == 'Menunggu Pemasangan' && t['tgl_pasang'] == tomorrowStr;

    // Warna tema kartu berdasarkan urgensi
    Color themeColor = isTelat ? Colors.red : (isHariIni ? (isBongkar ? Colors.orange : (isHMinus1 ? Colors.blue : Colors.green)) : Colors.blueGrey);
>>>>>>> EditArya

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white, 
          borderRadius: BorderRadius.circular(20), 
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))]
        ),
        child: InkWell(
<<<<<<< HEAD
          onTap: () =>
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (c) => TechDetailScreen(taskData: t),
                ),
              ).then(
                (_) => setState(() {
                  _taskFuture = fetchAllTasks();
                }),
              ),
=======
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => TechDetailScreen(taskData: t))).then((_) => setState(() { _taskFuture = fetchAllTasks(); })),
>>>>>>> EditArya
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(15.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
<<<<<<< HEAD
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: themeColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isTelat
                            ? "TERLAMBAT"
                            : (isBongkar ? "PEMBONGKARAN" : "PEMASANGAN"),
                        style: TextStyle(
                          color: themeColor,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      "Agenda: ${t['id_pelanggan']}",
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  t['nama_pelanggan'] ?? "",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        t['alamat'] ?? "",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
=======
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: themeColor.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                      child: Text(
                        isTelat 
                          ? "TERLAMBAT" 
                          : (isHMinus1 
                              ? "EKSEKUSI (H-1)" 
                              : (isHariIni 
                                  ? (isBongkar ? "PEMBONGKARAN" : "PEMASANGAN") 
                                  : "TERJADWAL")), 
                        style: TextStyle(color: themeColor, fontSize: 9, fontWeight: FontWeight.bold)
                      ),
                    ),
                    // REVISI LABEL: Menggunakan data 'no_agenda'
                    Text("Agenda: ${t['no_agenda']}", style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 12),
                Text(t['nama_pelanggan'] ?? "", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(child: Text(t['alamat'] ?? "", style: const TextStyle(fontSize: 12, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis))
                  ]
>>>>>>> EditArya
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.bolt, size: 14, color: Colors.orange),
                        const SizedBox(width: 4),
<<<<<<< HEAD
                        Text(
                          "${t['daya']} VA",
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      "Jadwal: ${isBongkar ? t['tgl_bongkar'] : t['tgl_pasang']}",
                      style: TextStyle(
                        fontSize: 11,
                        color: isTelat ? Colors.red : Colors.black54,
                        fontWeight: isTelat
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
=======
                        Text("${t['daya']} VA", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold))
                      ]
                    ),
                    Text(
                      "Jadwal: ${isBongkar ? t['tgl_bongkar'] : t['tgl_pasang']}", 
                      style: TextStyle(
                        fontSize: 11, 
                        color: isTelat ? Colors.red : Colors.black54, 
                        fontWeight: isTelat ? FontWeight.bold : FontWeight.normal
                      )
>>>>>>> EditArya
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
<<<<<<< HEAD
}
=======
}
>>>>>>> EditArya
