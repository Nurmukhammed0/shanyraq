/// Объявление о продаже жилья, которое добавил сам собственник.
/// Мы не проверяем документы и договорённости по этим объявлениям —
/// в отличие от таблицы zhk, это не куратируемые нами данные.
class Listing {
  final String id;
  final String ownerId;
  final String title;
  final String? description;
  final double? price;
  final String city;
  final String? district;
  final String? address;
  final int? rooms;
  final double? areaSqm;
  final String phone;
  final String? contactName;
  final String? photoUrl;
  final DateTime? createdAt;

  const Listing({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.city,
    required this.phone,
    this.description,
    this.price,
    this.district,
    this.address,
    this.rooms,
    this.areaSqm,
    this.contactName,
    this.photoUrl,
    this.createdAt,
  });

  factory Listing.fromJson(Map<String, dynamic> json) => Listing(
        id: json['id'] as String,
        ownerId: json['owner_id'] as String,
        title: json['title'] as String,
        description: json['description'] as String?,
        price: (json['price'] as num?)?.toDouble(),
        city: json['city'] as String? ?? 'Алматы',
        district: json['district'] as String?,
        address: json['address'] as String?,
        rooms: (json['rooms'] as num?)?.toInt(),
        areaSqm: (json['area_sqm'] as num?)?.toDouble(),
        phone: json['phone'] as String,
        contactName: json['contact_name'] as String?,
        photoUrl: json['photo_url'] as String?,
        createdAt:
            json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
      );

  Map<String, dynamic> toInsertJson(String ownerId) => {
        'owner_id': ownerId,
        'title': title,
        'description': description,
        'price': price,
        'city': city,
        'district': district,
        'address': address,
        'rooms': rooms,
        'area_sqm': areaSqm,
        'phone': phone,
        'contact_name': contactName,
        'photo_url': photoUrl,
      };
}
