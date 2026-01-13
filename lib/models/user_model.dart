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
}

List<UserModel> listUser = [
  UserModel(
    username: "gading",
    password: "123",
    role: "teknisi",
    nama: "Gading Buwono",
    nim: "124230052",
  ),
  UserModel(
    username: "admin",
    password: "123",
    role: "admin",
    nama: "Administrator Utama",
    nim: "001",
  ),
  UserModel(
    username: "budi",
    password: "123",
    role: "teknisi",
    nama: "Budi Santoso",
    nim: "124230099",
  ),
  UserModel(
    username: "y",
    password: "123",
    role: "teknisi",
    nama: "Yanto Santoso",
    nim: "124230077",
  ),
];
