import 'package:flutter/material.dart';
import 'models/user_model.dart';
import 'screens/admin_home.dart';
import 'screens/tech_home.dart';

// Gunakan 10.0.2.2 jika menggunakan Emulator Android Studio
// Gunakan IP Laptop jika menggunakan HP Fisik (contoh: 192.168.1.xxx)
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
      // Pastikan listUser sudah didefinisikan di user_model.dart
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Login Gagal!")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.bolt, size: 80, color: Color(0xFF00549B)),
            const Text(
              "PESTA MOBILE",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: u,
              decoration: const InputDecoration(
                labelText: "Username",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: p,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Password",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: login,
                child: const Text("MASUK"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
