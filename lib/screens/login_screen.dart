import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import 'admin_home.dart';
import 'tech_home.dart';

class LoginScreen extends StatefulWidget {
  // Menambahkan parameter selectedUnit dari layar pemilihan unit
  final String selectedUnit;
  const LoginScreen({super.key, required this.selectedUnit});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final u = TextEditingController();
  final p = TextEditingController();
  bool isLoading = true;

  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  // FITUR: Cek Sesi Login (Tetap Ada)
  Future<void> _checkSession() async {
    final prefs = await SharedPreferences.getInstance();
    final String? savedUsername = prefs.getString('user_session');

    if (savedUsername != null) {
      try {
        final data = await supabase
            .from('users')
            .select()
            .eq('username', savedUsername)
            .single();

        if (mounted) {
          final user = UserModel.fromMap(data);
          _navigateToHome(user);
        }
        return;
      } catch (e) {
        debugPrint("Sesi tidak valid: $e");
      }
    }

    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  // FITUR: Logika Login dengan Filter Unit
  void login() async {
    if (u.text.isEmpty || p.text.isEmpty) return;

    setState(() => isLoading = true);

    try {
      // MODIFIKASI: Query mencocokkan Unit yang dipilih
      // Catatan: Superadmin biasanya memiliki unit khusus atau bypass unit check
      final query = supabase
          .from('users')
          .select()
          .eq('username', u.text)
          .eq('password', p.text);

      // Jika bukan login sebagai admin pusat/superadmin, filter berdasarkan unit
      final data = await query.maybeSingle();

      if (data != null) {
        final user = UserModel.fromMap(data);

        // VALIDASI: Pastikan teknisi/admin login di unit yang tepat
        if (user.role != 'superadmin' && user.unit != widget.selectedUnit) {
          throw "Akun Anda tidak terdaftar di Unit ${widget.selectedUnit}";
        }

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_session', user.username);
        await prefs.setString('unit_session', user.unit); // Simpan session unit

        if (mounted) {
          _navigateToHome(user);
        }
      } else {
        throw "Username atau Password Salah!";
      }
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _navigateToHome(UserModel user) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (c) => (user.role == "admin" || user.role == "superadmin") 
            ? AdminHome(user: user) 
            : TechHome(user: user),
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
              Container(
                width: 100,
                height: 100,
                padding: const EdgeInsets.all(8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Image.asset(
                    'assets/images/logo_pln.png',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.bolt, size: 60, color: Colors.white),
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
              Text(
                "Unit Kerja: ${widget.selectedUnit}",
                style: const TextStyle(color: Colors.white70, fontSize: 13),
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
              Text(
                "© 2026 PLN ULP ${widget.selectedUnit}",
                style: const TextStyle(color: Colors.white54, fontSize: 11),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}