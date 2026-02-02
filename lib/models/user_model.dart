class UserModel {
  final int? id; // Tambahkan ID karena di DB kamu Primary Key-nya bigint
  final String username;
  final String password;
  final String nama;
  final String role;
  final String phone;

  UserModel({
    this.id,
    required this.username,
    required this.password,
    required this.nama,
    required this.role,
    this.phone = '',
  });

  // Konversi dari Map Supabase ke Objek Model
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'], 
      username: map['username'] ?? '',
      password: map['password'] ?? '',
      nama: map['nama'] ?? '',
      role: map['role'] ?? '',
      phone: map['phone'] ?? '', 
    );
  }
}