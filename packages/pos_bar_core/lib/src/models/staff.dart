class StaffCard {
  const StaffCard({
    required this.id,
    required this.name,
    required this.role,
    required this.avatarColor,
  });

  final int id;
  final String name;
  final String role;
  final String avatarColor;

  factory StaffCard.fromJson(Map<String, dynamic> json) => StaffCard(
        id: json['id'] as int,
        name: json['name'] as String,
        role: json['role'] as String,
        avatarColor: json['avatar_color'] as String? ?? '#6366f1',
      );
}

class StaffProfile {
  const StaffProfile({
    required this.id,
    required this.name,
    required this.role,
    required this.avatarColor,
    required this.venueId,
  });

  final int id;
  final String name;
  final String role;
  final String avatarColor;
  final int venueId;

  factory StaffProfile.fromJson(Map<String, dynamic> json) => StaffProfile(
        id: json['id'] as int,
        name: json['name'] as String,
        role: json['role'] as String,
        avatarColor: json['avatar_color'] as String? ?? '#6366f1',
        venueId: json['venue_id'] as int,
      );
}

class StaffSession {
  const StaffSession({required this.token, required this.staff});

  final String token;
  final StaffProfile staff;
}
