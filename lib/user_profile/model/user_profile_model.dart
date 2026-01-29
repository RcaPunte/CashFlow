class UserProfile {
  final String id;
  final String? fullName;
  final String? phone;
  final String? role;

  UserProfile({required this.id, this.fullName, this.phone, this.role});

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      fullName: json['full_name'],
      phone: json['phone'],
      role: json['role'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'phone_no': phone,
      'role': role,
      'created_at': DateTime.now().toIso8601String(),
    };
  }
}
