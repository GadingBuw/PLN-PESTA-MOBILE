import 'package:flutter/material.dart';
import 'package:workmanager/workmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/date_symbol_data_local.dart'; // Import untuk Locale
import 'services/notification_service.dart';
import 'screens/login_screen.dart';

// Ganti IP sesuai server Anda
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
            for (var t in data) {
              await NotificationService.showInstantNotification(t);
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

  // 1. WAJIB: Inisialisasi format tanggal lokal Indonesia untuk PDF
  await initializeDateFormatting('id_ID', null);

  // 2. Inisialisasi Notifikasi
  await NotificationService.initializeNotification();

  // 3. Inisialisasi Workmanager (Gunakan versi ^0.10.0)
  await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);

  await Workmanager().registerPeriodicTask(
    "pesta_task_check",
    "fetchDataTask",
    frequency: const Duration(minutes: 15),
    constraints: Constraints(networkType: NetworkType.connected),
  );

  runApp(
    const MaterialApp(debugShowCheckedModeBanner: false, home: LoginScreen()),
  );
}
