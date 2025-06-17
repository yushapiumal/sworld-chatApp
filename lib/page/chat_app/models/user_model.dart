
class UserModel {
  final String id;
  final String name;
  final String? email;
  final String? profileImage;

  UserModel({
    required this.id,
    required this.name,
    this.email,
    this.profileImage,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'],
      profileImage: map['profileImage'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'profileImage': profileImage,
    };
  }
}