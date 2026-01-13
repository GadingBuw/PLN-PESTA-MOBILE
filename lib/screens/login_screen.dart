import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert'; // Untuk jsonEncode
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

  // Fungsi Login dengan Simpan Session
  void login() async {
    try {
      final user = listUser.firstWhere(
        (x) => x.username == u.text && x.password == p.text,
      );

      // SIMPAN SESSION KE HP
      final prefs = await SharedPreferences.getInstance();
      String userString = jsonEncode(user.toJson()); // Ubah objek user ke string JSON
      await prefs.setString('user_session', userString);

      if (!mounted) return;
      
      // Pindah Halaman
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (c) => user.role == "admin"
              ? AdminHome(user: user)
              : TechHome(user: user),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Username atau Password Salah!")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const Text(
                "PLN - Pemasangan & Pembongkaran Daya",
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
                        "Login ke Akun Anda",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
                      ),
                      const SizedBox(height: 25),
                      const Text("Username", style: TextStyle(color: Colors.grey, fontSize: 13)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: u,
                        decoration: InputDecoration(
                          hintText: "Masukkan Username",
                          prefixIcon: const Icon(Icons.person_outline, size: 20),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text("Password", style: TextStyle(color: Colors.grey, fontSize: 13)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: p,
                        obscureText: true,
                        decoration: InputDecoration(
                          hintText: "Masukkan Password",
                          prefixIcon: const Icon(Icons.lock_outline, size: 20),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
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
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          ),
                          child: const Text("Masuk", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 60),
              const Text("© 2026 PLN. All Rights Reserved.", style: TextStyle(color: Colors.white54, fontSize: 11)),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}