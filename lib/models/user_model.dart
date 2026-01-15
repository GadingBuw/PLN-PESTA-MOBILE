class UserModel {
  final String username;
  final String password;
  final String nama;
  final String role;

  UserModel({
    required this.username,
    required this.password,
    required this.nama,
    required this.role,
  });

  // Tambahkan fungsi ini untuk konversi dari database
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      username: map['username'] ?? '',
      password: map['password'] ?? '',
      nama: map['nama'] ?? '',
      role: map['role'] ?? '',
    );
  }
}