import 'package:flutter/material.dart';
import 'package:workmanager/workmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/date_symbol_data_local.dart';
import 'services/notification_service.dart';
import 'screens/login_screen.dart';

final String baseUrl = "http://10.5.224.192/pesta_api/index.php";

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    final prefs = await SharedPreferences.getInstance();
    final String? username = prefs.getString('user_session');

    if (username != null) {
      try {
        final response = await http.get(
          Uri.parse("$baseUrl?action=get_all_tasks&teknisi=$username"),
        );

        if (response.statusCode == 200) {
          List data = jsonDecode(response.body);
          if (data.isNotEmpty) {
            await NotificationService.initializeNotification();

            DateTime now = DateTime.now();
            String todayStr =
                "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

            for (var t in data) {
              String status = t['status'] ?? '';
              String tglPasang = t['tgl_pasang']?.toString() ?? '';
              String tglBongkar = t['tgl_bongkar']?.toString() ?? '';

              // LOGIKA FILTER SANGAT KETAT
              bool isJadwalPasangHariIni =
                  (status == 'Menunggu Pemasangan' && tglPasang == todayStr);
              bool isJadwalBongkarHariIni =
                  (status == 'Menunggu Pembongkaran' && tglBongkar == todayStr);

              if (isJadwalPasangHariIni || isJadwalBongkarHariIni) {
                // Tambahan: Cek agar tidak mengirim notifikasi yang sama berkali-kali dalam 15 menit
                String lastNotifKey = "last_notif_${t['id']}";
                String? lastSent = prefs.getString(lastNotifKey);

                if (lastSent != todayStr) {
                  await NotificationService.showInstantNotification(t);
                  // Simpan tanda bahwa tugas ini sudah dikirim notifikasinya hari ini
                  await prefs.setString(lastNotifKey, todayStr);
                }
              }
            }
          }
        }
      } catch (e) {
        debugPrint("Background Fetch Error: $e");
      }
    }
    return Future.value(true);
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  await NotificationService.initializeNotification();

  // 1. Inisialisasi Workmanager
  await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);

  // 2. BERSIHKAN SEMUA TASK LAMA (Penting!)
  await Workmanager().cancelAll();

  // 3. DAFTARKAN ULANG DENGAN DELAY 10 DETIK
  // Gunakan registerOneOffTask dulu untuk testing segera, atau Periodic untuk rutin
  await Workmanager().registerPeriodicTask(
    "pesta_task_check_unique_id", // Gunakan ID baru agar tidak bentrok dengan cache lama
    "fetchDataTask",
    frequency: const Duration(minutes: 15),
    constraints: Constraints(networkType: NetworkType.connected),
    existingWorkPolicy: ExistingWorkPolicy.replace,
  );

  runApp(
    const MaterialApp(debugShowCheckedModeBanner: false, home: LoginScreen()),
  );
}
