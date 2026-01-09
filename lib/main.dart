import 'package:flutter/material.dart';
import 'models/user_model.dart';
import 'screens/admin_home.dart';
import 'screens/tech_home.dart';

// URL API Anda
final String baseUrl = "http://10.5.224.202/pesta_api/index.php";

void main() => runApp(
  const MaterialApp(debugShowCheckedModeBanner: false, home: LoginScreen()),
);

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final u = TextEditingController();
  final p = TextEditingController();

  void login() {
    try {
      final user = listUser.firstWhere(
        (x) => x.username == u.text && x.password == p.text,
      );
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
        const SnackBar(content: Text("Email atau Password Salah!")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        // Latar belakang gradasi biru sesuai desain
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
                "PLN - Pemasangan & Pembongkaran Daya",
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 50),
              // Kotak Form Login
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
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF333333),
                        ),
                      ),
                      const SizedBox(height: 25),
                      const Text(
                        "Email atau ID Pegawai",
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: u,
                        decoration: InputDecoration(
                          hintText: "Email atau Username",
                          prefixIcon: const Icon(
                            Icons.email_outlined,
                            size: 20,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 15,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: const BorderSide(
                              color: Color(0xFFE0E0E0),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: const BorderSide(
                              color: Color(0xFFE0E0E0),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        "Password",
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: p,
                        obscureText: true,
                        decoration: InputDecoration(
                          hintText: "Masukkan Password",
                          prefixIcon: const Icon(Icons.lock_outline, size: 20),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 15,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: const BorderSide(
                              color: Color(0xFFE0E0E0),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: const BorderSide(
                              color: Color(0xFFE0E0E0),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 35),
                      // Tombol Masuk
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
                            elevation: 4,
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Masuk",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(width: 10),
                              Icon(
                                Icons.arrow_forward,
                                color: Colors.white,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 60),
              const Text(
                "© 2026 PLN. All Rights Reserved.",
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
