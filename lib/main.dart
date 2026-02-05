import 'package:flutter/material.dart';
import 'package:workmanager/workmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'services/notification_service.dart';
import 'screens/unit_selection_screen.dart';
import 'screens/admin_home.dart';
import 'screens/tech_home.dart';
import 'models/user_model.dart';

// Konfigurasi Supabase
const String supabaseUrl = 'https://vzupgvjbmllwudoenuxp.supabase.co';
const String supabaseKey = 'sb_publishable_0chiXdXnRJZB4l6VKTU1ww_myomOLhP';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    final prefs = await SharedPreferences.getInstance();
    final String? username = prefs.getString('user_session');

    if (username != null) {
      try {
        await Supabase.initialize(url: supabaseUrl, anonKey: supabaseKey);
        final supabase = Supabase.instance.client;

        final List<dynamic> data = await supabase
            .from('pesta_tasks')
            .select()
            .eq('teknisi', username); 

        if (data.isNotEmpty) {
          await NotificationService.initializeNotification();
          DateTime now = DateTime.now();
          String todayStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

          for (var t in data) {
            String status = t['status'] ?? '';
            String tglPasang = t['tgl_pasang']?.toString() ?? '';
            String tglBongkar = t['tgl_bongkar']?.toString() ?? '';

            bool isJadwalPasangHariIni = (status == 'Menunggu Pemasangan' && tglPasang == todayStr);
            bool isJadwalBongkarHariIni = (status == 'Menunggu Pembongkaran' && tglBongkar == todayStr);

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
        debugPrint("Background Fetch Error: $e");
      }
    }
    return Future.value(true);
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseKey);
  await initializeDateFormatting('id_ID', null);
  await NotificationService.initializeNotification();
  await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PLN PESTA Mobile',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1A56F0)),
      ),
      // GERBANG LOGIKA: Cek Sesi sebelum menentukan layar awal
      home: const RootCheck(),
    );
  }
}

// --- WIDGET BARU: Pengecek Sesi Login ---
class RootCheck extends StatefulWidget {
  const RootCheck({super.key});

  @override
  State<RootCheck> createState() => _RootCheckState();
}

class _RootCheckState extends State<RootCheck> {
  bool isLoading = true;
  Widget? startWidget;

  @override
  void initState() {
    super.initState();
    _checkSavedSession();
  }

  Future<void> _checkSavedSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? savedUsername = prefs.getString('user_session');

      if (savedUsername != null) {
        // Ambil data terbaru user dari Supabase berdasarkan username di SharedPreferences
        final data = await Supabase.instance.client
            .from('users')
            .select()
            .eq('username', savedUsername)
            .maybeSingle();

        if (data != null) {
          final user = UserModel.fromMap(data);
          // Langsung arahkan ke Beranda sesuai Role
          if (user.role == 'admin' || user.role == 'superadmin') {
            startWidget = AdminHome(user: user);
          } else {
            startWidget = TechHome(user: user);
          }
        } else {
          // Jika username di prefs tidak ditemukan di DB (misal akun dihapus)
          startWidget = const UnitSelectionScreen();
        }
      } else {
        // Tidak ada sesi tersimpan
        startWidget = const UnitSelectionScreen();
      }
    } catch (e) {
      debugPrint("Gagal memuat sesi: $e");
      startWidget = const UnitSelectionScreen();
    }

    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    return startWidget ?? const UnitSelectionScreen();
  }
}