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
    _checkSession();
  }

  Future<void> _checkSession() async {
    final prefs = await SharedPreferences.getInstance();
    final String? savedUsername = prefs.getString('user_session');

    if (savedUsername != null) {
      try {
        final user = listUser.firstWhere((x) => x.username == savedUsername);
        if (mounted) {
          _navigateToHome(user);
        }
        return;
      } catch (e) {
        debugPrint("Session user not found");
      }
    }

    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  void login() async {
    try {
      final user = listUser.firstWhere(
        (x) => x.username == u.text && x.password == p.text,
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_session', user.username);

      if (mounted) {
        _navigateToHome(user);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Username atau Password Salah!"),
          backgroundColor: Colors.redAccent,
        ),
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

              // --- LOGO PLN OFFLINE (ASSET) ---
              Container(
                width: 100,
                height: 100,
                padding: const EdgeInsets.all(8),
                child: ClipRRect(
                  // Tambahkan ini untuk melengkungkan sudut gambar
                  borderRadius: BorderRadius.circular(
                    15,
                  ), // Radius 15 sesuai permintaan
                  child: Image.asset(
                    'assets/images/logo_pln.png',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.bolt, size: 60, color: Colors.red),
                  ),
                ),
              ),

              const SizedBox(height: 15),
              const Text(
                "PESTA MOBILE",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.2,
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
                          filled: true,
                          fillColor: const Color(0xFFF5F5F5),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide.none,
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
                          filled: true,
                          fillColor: const Color(0xFFF5F5F5),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide.none,
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
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            "MASUK",
                            style: TextStyle(
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
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
