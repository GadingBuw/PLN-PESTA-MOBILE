class UserModel {
  final int? id; // Primary Key bigint dari database
  final String username;
  final String password;
  final String nama;
  final String role;
  final String phone;
  final String unit; // Penambahan Field Unit untuk sistem Multi-Unit

  UserModel({
    this.id,
    required this.username,
    required this.password,
    required this.nama,
    required this.role,
    this.phone = '',
    required this.unit, // Wajib diisi agar data tidak bercampur antar unit
  });

  // 1. Konversi dari Map Supabase ke Objek Model (Data Masuk)
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'], 
      username: map['username'] ?? '',
      password: map['password'] ?? '',
      nama: map['nama'] ?? '',
      role: map['role'] ?? '',
      phone: map['phone'] ?? '', 
      unit: map['unit'] ?? '', // Mengambil data unit dari kolom baru di DB
    );
  }

  // 2. Konversi dari Objek Model ke Map (Data Keluar / Simpan Session)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'password': password,
      'nama': nama,
      'role': role,
      'phone': phone,
      'unit': unit,
    };
  }
}