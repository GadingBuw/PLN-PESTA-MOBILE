import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'admin_home.dart';
import 'tech_home.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final u = TextEditingController();
  final p = TextEditingController();
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkSession(); // Cek apakah sudah pernah login sebelumnya
  }

  // Fungsi untuk mengecek sesi login yang tersimpan (Auto-Login)
  Future<void> _checkSession() async {
    final prefs = await SharedPreferences.getInstance();
    final String? savedUsername = prefs.getString('user_session');

    if (savedUsername != null) {
      try {
        // Cari data user dari listUser lokal berdasarkan username yang disimpan
        final user = listUser.firstWhere((x) => x.username == savedUsername);

        if (mounted) {
          _navigateToHome(user);
        }
        return;
      } catch (e) {
        // Jika user tidak ditemukan di listUser, biarkan tetap di halaman login
      }
    }

    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  void login() async {
    try {
      // Validasi login terhadap listUser statis
      final user = listUser.firstWhere(
        (x) => x.username == u.text && x.password == p.text,
      );

      // SIMPAN SESSION: Menyimpan username secara permanen di HP
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_session', user.username);

      if (mounted) {
        _navigateToHome(user);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Username atau Password Salah!")),
      );
    }
  }

  void _navigateToHome(UserModel user) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (c) =>
            user.role == "admin" ? AdminHome(user: user) : TechHome(user: user),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1A56F0), Color(0xFF0039A6)],
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 100),
              // Logo PLN
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: Colors.yellow,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(Icons.bolt, size: 70, color: Colors.red),
              ),
              const SizedBox(height: 15),
              const Text(
                "PESTA MOBILE",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Text(
                "PLN - Pemasangan & Pembongkaran",
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 50),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: Container(
                  padding: const EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Login Akun",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF333333),
                        ),
                      ),
                      const SizedBox(height: 25),
                      TextField(
                        controller: u,
                        decoration: InputDecoration(
                          hintText: "Username",
                          prefixIcon: const Icon(Icons.person_outline),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: p,
                        obscureText: true,
                        decoration: InputDecoration(
                          hintText: "Password",
                          prefixIcon: const Icon(Icons.lock_outline),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                      ),
                      const SizedBox(height: 35),
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1A56F0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          child: const Text(
                            "MASUK",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 60),
              const Text(
                "© 2026 PLN ULP Pacitan",
                style: TextStyle(color: Colors.white54, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
