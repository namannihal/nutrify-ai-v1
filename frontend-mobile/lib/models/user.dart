class UserModel {
  final String id;
  final String email;
  final String name;

  UserModel({required this.id, required this.email, required this.name});

  factory UserModel.fromMap(Map<String, dynamic> m) {
    return UserModel(id: m['id'] ?? '', email: m['email'] ?? '', name: m['name'] ?? '');
  }
}
