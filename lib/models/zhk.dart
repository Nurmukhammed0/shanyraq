/// Модель одного жилого комплекса — как проблемного, так и
/// завершённого под госгарантией.
class Zhk {
  final String id;
  final String name;
  final String? district;
  final String? address;
  final String? developer;
  final String status; // 'problematic' | 'completed_guaranteed'
  final String? documentation;
  final String? techStatus;
  final String? violations;
  final String? measures;
  final String? court;
  final double? lat;
  final double? lng;
  final String? photoUrl;
  // Статус стройки и год — видны всем бесплатно, в отличие от документации/
  // нарушений/суда, которые остаются за подпиской.
  final String? constructionStatus; // 'built' | 'in_progress'
  final int? completionYear;

  const Zhk({
    required this.id,
    required this.name,
    required this.status,
    this.district,
    this.address,
    this.developer,
    this.documentation,
    this.techStatus,
    this.violations,
    this.measures,
    this.court,
    this.lat,
    this.lng,
    this.photoUrl,
    this.constructionStatus,
    this.completionYear,
  });

  bool get isProblematic => status == 'problematic';
  bool get hasCoordinates => lat != null && lng != null;
  bool get isBuilt => constructionStatus == 'built';

  factory Zhk.fromJson(Map<String, dynamic> json) {
    return Zhk(
      id: json['id'] as String,
      name: json['name'] as String,
      status: json['status'] as String? ?? 'problematic',
      district: json['district'] as String?,
      address: json['address'] as String?,
      developer: json['developer'] as String?,
      documentation: json['documentation'] as String?,
      techStatus: json['tech_status'] as String?,
      violations: json['violations'] as String?,
      measures: json['measures'] as String?,
      court: json['court'] as String?,
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
      photoUrl: json['photo_url'] as String?,
      constructionStatus: json['construction_status'] as String?,
      completionYear: (json['completion_year'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'status': status,
        'district': district,
        'address': address,
        'developer': developer,
        'documentation': documentation,
        'tech_status': techStatus,
        'violations': violations,
        'measures': measures,
        'court': court,
        'lat': lat,
        'lng': lng,
        'photo_url': photoUrl,
        'construction_status': constructionStatus,
        'completion_year': completionYear,
      };
}
