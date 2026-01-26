import 'package:flutter/material.dart';
import 'package:workmanager/workmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'services/notification_service.dart';
import 'screens/login_screen.dart';

// Masukkan URL dan Anon Key dari dashboard Supabase Anda (Project Settings > API)
const String supabaseUrl = 'https://vzupgvjbmllwudoenuxp.supabase.co';
const String supabaseKey = 'sb_publishable_0chiXdXnRJZB4l6VKTU1ww_myomOLhP';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    final prefs = await SharedPreferences.getInstance();
    final String? username = prefs.getString('user_session');

    if (username != null) {
      try {
        // Inisialisasi Supabase khusus untuk Background Process
        await Supabase.initialize(url: supabaseUrl, anonKey: supabaseKey);
        final supabase = Supabase.instance.client;

        // Mengambil data langsung dari tabel 'pesta_tasks'
        final List<dynamic> data = await supabase
            .from('pesta_tasks')
            .select()
            .eq('teknisi', username); // Filter berdasarkan nama teknisi

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
      } catch (e) {
        debugPrint("Background Fetch Error (Supabase): $e");
      }
    }
    return Future.value(true);
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Inisialisasi Supabase di awal aplikasi
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseKey);

  await initializeDateFormatting('id_ID', null);
  await NotificationService.initializeNotification();

  await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
  await Workmanager().cancelAll();

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
    const Color myPrimaryColor = Color(0xFF1A56F0);
    const Color myBgGrey = Color(0xFFF0F2F5);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PLN PESTA Mobile',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: myPrimaryColor,
          primary: myPrimaryColor,
          secondary: const Color(0xFF00C7E1),
        ),
        scaffoldBackgroundColor: myBgGrey,
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: myPrimaryColor,
        ),
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
