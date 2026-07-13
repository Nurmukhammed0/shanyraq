enum ZhkStatus { problematic, completedGuaranteed, unknown }

ZhkStatus statusFromString(String? s) {
  switch (s) {
    case 'problematic':
      return ZhkStatus.problematic;
    case 'completed_guaranteed':
      return ZhkStatus.completedGuaranteed;
    default:
      return ZhkStatus.unknown;
  }
}

class Zhk {
  final String id;
  final String name;
  final String? district;
  final String? address;
  final String? developer;
  final ZhkStatus status;
  final String? documentation;
  final String? techStatus;
  final String? violations;
  final String? measures;
  final String? court;
  final double? lat;
  final double? lng;

  Zhk({
    required this.id,
    required this.name,
    this.district,
    this.address,
    this.developer,
    required this.status,
    this.documentation,
    this.techStatus,
    this.violations,
    this.measures,
    this.court,
    this.lat,
    this.lng,
  });

  bool get hasCoordinates => lat != null && lng != null;

  factory Zhk.fromJson(Map<String, dynamic> json, ZhkStatus fallbackStatus) {
    return Zhk(
      id: json['id'] as String,
      name: json['name'] as String,
      district: json['district'] as String?,
      address: json['address'] as String?,
      developer: json['developer'] as String?,
      status: statusFromString(json['status'] as String?) == ZhkStatus.unknown
          ? fallbackStatus
          : statusFromString(json['status'] as String?),
      documentation: json['documentation'] as String?,
      techStatus: json['tech_status'] as String?,
      violations: json['violations'] as String?,
      measures: json['measures'] as String?,
      court: json['court']?.toString(),
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
    );
  }

  factory Zhk.fromSupabaseRow(Map<String, dynamic> row) {
    return Zhk(
      id: row['id'] as String,
      name: row['name'] as String,
      district: row['district'] as String?,
      address: row['address'] as String?,
      developer: row['developer'] as String?,
      status: statusFromString(row['status'] as String?),
      documentation: row['documentation'] as String?,
      techStatus: row['tech_status'] as String?,
      violations: row['violations'] as String?,
      measures: row['measures'] as String?,
      court: row['court'] as String?,
      lat: (row['lat'] as num?)?.toDouble(),
      lng: (row['lng'] as num?)?.toDouble(),
    );
  }
}
