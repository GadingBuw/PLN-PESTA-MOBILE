class UserModel {
  final String username;
  final String password;
  final String role;
  final String nama; 
  final String nim; 

  UserModel({
    required this.username,
    required this.password,
    required this.role,
    required this.nama,
    required this.nim,
  });

  // Fungsi untuk mengubah Object ke Map (JSON)
  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'password': password,
      'role': role,
      'nama': nama,
      'nim': nim,
    };
  }

  // Fungsi untuk mengubah Map (JSON) kembali ke Object UserModel
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      username: json['username'],
      password: json['password'],
      role: json['role'],
      nama: json['nama'],
      nim: json['nim'],
    );
  }
}

// Data Dummy User
List<UserModel> listUser = [
  UserModel(username: "gading", password: "123", role: "teknisi", nama: "Gading Buwono", nim: "124230052"),
  UserModel(username: "admin", password: "123", role: "admin", nama: "Administrator Utama", nim: "001"),
  UserModel(username: "budi", password: "123", role: "teknisi", nama: "Budi Santoso", nim: "124230099"),
];