import 'package:flutter/material.dart';
import 'package:workmanager/workmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'services/notification_service.dart';
import 'screens/login_screen.dart';

// URL API Anda (Sesuaikan IP Laptop Anda)
final String baseUrl = "http://10.5.224.192/pesta_api/index.php";

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    // Ambil session username dari memori HP
    final prefs = await SharedPreferences.getInstance();
    final String? username = prefs.getString('user_session');

    if (username != null) {
      try {
        // Cek data ke server secara otomatis di background
        final response = await http.get(
          Uri.parse("$baseUrl?action=get_all_tasks&teknisi=$username"),
        );

        if (response.statusCode == 200) {
          List data = jsonDecode(response.body);
          if (data.isNotEmpty) {
            // Jika ada data, langsung munculkan notifikasi
            await NotificationService.initializeNotification();
            for (var t in data) {
              await NotificationService.showInstantNotification(t);
            }
          }
        }
      } catch (e) {
        print("Background Error: $e");
      }
    }
    return Future.value(true);
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Siapkan Notifikasi
  await NotificationService.initializeNotification();

  // 2. Siapkan Workmanager (Background Process)
  await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);

  // Daftarkan tugas rutin (Setiap 15 menit)
  await Workmanager().registerPeriodicTask(
    "1",
    "checkPestaTasks",
    frequency: const Duration(minutes: 15),
    constraints: Constraints(networkType: NetworkType.connected),
  );

  runApp(
    const MaterialApp(debugShowCheckedModeBanner: false, home: LoginScreen()),
  );
}
