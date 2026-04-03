class StaffModel {
  final String id;
  final String name;
  final String accessKey;
  final String role; // "staff"
  final DateTime createdAt;
  final String? phone;
  final String? email;

  StaffModel({
    required this.id,
    required this.name,
    required this.accessKey,
    required this.role,
    required this.createdAt,
    this.phone,
    this.email,
  });
}
