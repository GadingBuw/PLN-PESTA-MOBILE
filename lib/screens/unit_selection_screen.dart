import 'package:flutter/material.dart';
import 'login_screen.dart';

class UnitSelectionScreen extends StatelessWidget {
  const UnitSelectionScreen({super.key});

  // DAFTAR UNIT KERJA PLN (Madiun diganti Balong)
  final List<Map<String, dynamic>> units = const [
    {'name': 'Pacitan', 'icon': Icons.location_on_rounded},
    {'name': 'Ponorogo', 'icon': Icons.location_on_rounded},
    {'name': 'Trenggalek', 'icon': Icons.location_on_rounded},
    {'name': 'Balong', 'icon': Icons.location_on_rounded}, // Update di sini
  ];

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF1A56F0);

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
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 60),
              // Logo & Judul
              Container(
                width: 80,
                height: 80,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Image.asset(
                  'assets/images/logo_pln.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.bolt, size: 40, color: primaryBlue),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "PESTA MOBILE",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.5,
                ),
              ),
              const Text(
                "Pilih Unit Kerja Anda",
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 40),

              // Daftar Unit dalam Grid
              Expanded(
                child: Container(
                  padding: const EdgeInsets.only(top: 40, left: 25, right: 25),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF8F9FB),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(40),
                      topRight: Radius.circular(40),
                    ),
                  ),
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 15,
                      mainAxisSpacing: 15,
                      childAspectRatio: 1.1,
                    ),
                    itemCount: units.length,
                    itemBuilder: (context, index) {
                      final unit = units[index];
                      return InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (c) => LoginScreen(selectedUnit: unit['name']),
                            ),
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircleAvatar(
                                backgroundColor: primaryBlue.withOpacity(0.1),
                                child: Icon(unit['icon'], color: primaryBlue),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                "ULP ${unit['name']}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Color(0xFF333333),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}