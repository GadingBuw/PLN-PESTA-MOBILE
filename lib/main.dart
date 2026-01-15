import 'package:flutter/material.dart';
import 'package:workmanager/workmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/date_symbol_data_local.dart';
import 'services/notification_service.dart';
import 'screens/login_screen.dart';

// URL API
final String baseUrl = "http://10.5.224.200/pesta_api/index.php";

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

              bool isJadwalPasangHariIni =
                  (status == 'Menunggu Pemasangan' && tglPasang == todayStr);
              bool isJadwalBongkarHariIni =
                  (status == 'Menunggu Pembongkaran' && tglBongkar == todayStr);

              if (isJadwalPasangHariIni || isJadwalBongkarHariIni) {
                String lastNotifKey = "last_notif_${t['id']}";
                String? lastSent = prefs.getString(lastNotifKey);

                if (lastSent != todayStr) {
                  await NotificationService.showInstantNotification(t);
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

  // Inisialisasi Lokal & Notifikasi
  await initializeDateFormatting('id_ID', null);
  await NotificationService.initializeNotification();

  // 1. Inisialisasi Workmanager
  await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);

  // 2. Bersihkan task lama
  await Workmanager().cancelAll();

  // 3. Daftarkan Periodic Task (Interval minimal Android adalah 15 menit)
  await Workmanager().registerPeriodicTask(
    "pesta_task_check_unique_id",
    "fetchDataTask",
    frequency: const Duration(minutes: 15),
    constraints: Constraints(networkType: NetworkType.connected),
    existingWorkPolicy: ExistingWorkPolicy.replace,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Definisi Warna Biru Solid Anda
    const Color myPrimaryColor = Color(0xFF1A56F0);
    const Color myBgGrey = Color(0xFFF0F2F5);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PLN PESTA Mobile',

      // --- PENYELARASAN TEMA GLOBAL ---
      theme: ThemeData(
        useMaterial3: true,
        // Warna utama aplikasi (Primary)
        colorScheme: ColorScheme.fromSeed(
          seedColor: myPrimaryColor,
          primary: myPrimaryColor,
          secondary: const Color(0xFF00C7E1), // Biru cyan untuk variasi
        ),

        // Warna Background Scaffold
        scaffoldBackgroundColor: myBgGrey,

        // Penyelarasan Warna Progress Indicator (Loading)
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: myPrimaryColor,
        ),

        // Penyelarasan AppBar Global
        appBarTheme: const AppBarTheme(
          backgroundColor: myPrimaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),

        // Penyelarasan Input/TextField Global
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE0E4E8)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE0E4E8)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: myPrimaryColor, width: 1.5),
          ),
        ),
      ),
      home: const LoginScreen(),
    );
  }
}
