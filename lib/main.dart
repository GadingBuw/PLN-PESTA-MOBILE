import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert'; // Untuk jsonDecode
import 'models/user_model.dart';
import 'screens/login_screen.dart';
import 'screens/admin_home.dart';
import 'screens/tech_home.dart';

// URL API Global
final String baseUrl = "http://10.5.224.198/pesta_api/index.php";

void main() async {
  // Wajib ditambahkan jika main menggunakan async
  WidgetsFlutterBinding.ensureInitialized();

  // CEK SESSION SAAT APLIKASI DIBUKA
  final prefs = await SharedPreferences.getInstance();
  final String? userData = prefs.getString('user_session');

  Widget initialScreen;

  if (userData != null) {
    // Jika data ada, ubah String JSON kembali ke Object
    try {
      UserModel user = UserModel.fromJson(jsonDecode(userData));
      // Tentukan halaman berdasarkan role
      initialScreen = (user.role == "admin") 
          ? AdminHome(user: user) 
          : TechHome(user: user);
    } catch (e) {
      // Jika terjadi error saat baca data, lempar ke login
      initialScreen = const LoginScreen();
    }
  } else {
    // Jika tidak ada session, ke halaman login
    initialScreen = const LoginScreen();
  }

  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'PESTA PLN',
    theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
    home: initialScreen,
  ));
}