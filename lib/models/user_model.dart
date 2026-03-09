class UserModel {
  final int id;
  final String role;
  final String fullName;
  final String email;
  final String? phone;
  final String? avatarUrl;
  final String preferredLang;
  final bool isBanned;

  const UserModel({
    required this.id,
    required this.role,
    required this.fullName,
    required this.email,
    this.phone,
    this.avatarUrl,
    required this.preferredLang,
    required this.isBanned,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] is String ? int.tryParse(json['id']) ?? 0 : (json['id'] ?? 0) as int,
      role: json['role'] ?? 'user',
      fullName: json['full_name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      avatarUrl: json['avatar_url'],
      preferredLang: json['preferred_lang'] ?? 'fr',
      isBanned: (json['is_banned'] ?? 0) == 1,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'role': role,
        'full_name': fullName,
        'email': email,
        'phone': phone,
        'avatar_url': avatarUrl,
        'preferred_lang': preferredLang,
        'is_banned': isBanned ? 1 : 0,
      };
}
