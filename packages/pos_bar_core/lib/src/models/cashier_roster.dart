class TillRoster {
  const TillRoster({required this.tills, required this.cashiers});

  final List<TillStatus> tills;
  final List<CashierRosterEntry> cashiers;

  factory TillRoster.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    return TillRoster(
      tills: (data['tills'] as List<dynamic>? ?? [])
          .map((e) => TillStatus.fromJson(e as Map<String, dynamic>))
          .toList(),
      cashiers: (data['cashiers'] as List<dynamic>? ?? [])
          .map((e) => CashierRosterEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class TillStatus {
  const TillStatus({
    required this.id,
    required this.name,
    required this.code,
    required this.isAvailable,
    this.activeShift,
  });

  final int id;
  final String name;
  final String code;
  final bool isAvailable;
  final TillActiveShift? activeShift;

  factory TillStatus.fromJson(Map<String, dynamic> json) => TillStatus(
        id: json['id'] as int,
        name: json['name'] as String,
        code: json['code'] as String,
        isAvailable: json['is_available'] as bool? ?? true,
        activeShift: json['active_shift'] != null
            ? TillActiveShift.fromJson(json['active_shift'] as Map<String, dynamic>)
            : null,
      );
}

class TillActiveShift {
  const TillActiveShift({
    required this.id,
    required this.staffId,
    required this.staffName,
    this.staffAvatarColor,
    this.startedAt,
    this.openingFloat,
  });

  final int id;
  final int staffId;
  final String staffName;
  final String? staffAvatarColor;
  final String? startedAt;
  final double? openingFloat;

  factory TillActiveShift.fromJson(Map<String, dynamic> json) => TillActiveShift(
        id: json['id'] as int,
        staffId: json['staff_id'] as int,
        staffName: json['staff_name'] as String,
        staffAvatarColor: json['staff_avatar_color'] as String?,
        startedAt: json['started_at'] as String?,
        openingFloat: json['opening_float'] != null
            ? double.parse(json['opening_float'].toString())
            : null,
      );
}

class CashierRosterEntry {
  const CashierRosterEntry({
    required this.id,
    required this.name,
    required this.avatarColor,
    this.activeShift,
  });

  final int id;
  final String name;
  final String avatarColor;
  final CashierActiveShift? activeShift;

  factory CashierRosterEntry.fromJson(Map<String, dynamic> json) => CashierRosterEntry(
        id: json['id'] as int,
        name: json['name'] as String,
        avatarColor: json['avatar_color'] as String? ?? '#6366f1',
        activeShift: json['active_shift'] != null
            ? CashierActiveShift.fromJson(json['active_shift'] as Map<String, dynamic>)
            : null,
      );
}

class CashierActiveShift {
  const CashierActiveShift({
    required this.id,
    required this.tillId,
    this.tillName,
    this.tillCode,
    this.startedAt,
  });

  final int id;
  final int tillId;
  final String? tillName;
  final String? tillCode;
  final String? startedAt;

  factory CashierActiveShift.fromJson(Map<String, dynamic> json) => CashierActiveShift(
        id: json['id'] as int,
        tillId: json['till_id'] as int,
        tillName: json['till_name'] as String?,
        tillCode: json['till_code'] as String?,
        startedAt: json['started_at'] as String?,
      );
}

class StaffShiftInfo {
  const StaffShiftInfo({
    required this.id,
    required this.tillId,
    this.tillName,
    this.tillCode,
    this.startedAt,
    this.openingFloat,
  });

  final int id;
  final int tillId;
  final String? tillName;
  final String? tillCode;
  final String? startedAt;
  final double? openingFloat;

  factory StaffShiftInfo.fromJson(Map<String, dynamic> json) => StaffShiftInfo(
        id: json['id'] as int,
        tillId: json['till_id'] as int,
        tillName: (json['till'] as Map<String, dynamic>?)?['name'] as String?,
        tillCode: (json['till'] as Map<String, dynamic>?)?['code'] as String?,
        startedAt: json['started_at'] as String?,
        openingFloat: json['opening_float'] != null
            ? double.parse(json['opening_float'].toString())
            : null,
      );
}
