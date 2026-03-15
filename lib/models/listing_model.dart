class ListingModel {
  final int id;
  final int userId;
  final String type;
  final String status;
  final String title;
  final String description;
  final int? categoryId;
  final String? categoryName;
  final String? city;
  final String? locationText;
  final String? eventDate;
  final bool isBoosted;
  final String? publishedAt;
  final String createdAt;
  final String? updatedAt;
  final String? coverPhotoUrl;
  final String? paymentStatus;

  ListingModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.status,
    required this.title,
    required this.description,
    required this.createdAt,
    this.categoryId,
    this.categoryName,
    this.city,
    this.locationText,
    this.eventDate,
    this.isBoosted = false,
    this.publishedAt,
    this.updatedAt,
    this.coverPhotoUrl,
    this.paymentStatus,
  });

  factory ListingModel.fromJson(Map<String, dynamic> json) {
    // Normalize booleans/ints that may arrive as string ("0"/"1").
    bool boosted = false;
    final dynamic boostedRaw = json['is_boosted'];
    if (boostedRaw is bool) {
      boosted = boostedRaw;
    } else if (boostedRaw is int) {
      boosted = boostedRaw == 1;
    } else if (boostedRaw is String) {
      boosted = boostedRaw == '1' || boostedRaw.toLowerCase() == 'true';
    }

    int? parsedCategoryId;
    final dynamic catRaw = json['category_id'];
    if (catRaw is int) {
      parsedCategoryId = catRaw;
    } else if (catRaw is String) {
      parsedCategoryId = int.tryParse(catRaw);
    }
    return ListingModel(
      id: json['id'] is String ? int.parse(json['id']) : json['id'] ?? 0,
      userId: json['user_id'] is String ? int.parse(json['user_id']) : json['user_id'] ?? 0,
      type: json['type'] ?? 'lost',
      status: json['status'] ?? 'draft',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      categoryId: parsedCategoryId,
      categoryName: json['category_name'] as String?,
      city: json['city'] as String?,
      locationText: json['location_text'] as String?,
      eventDate: json['event_date'] as String?,
      isBoosted: boosted,
      publishedAt: json['published_at'] as String?,
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] as String?,
      coverPhotoUrl: json['cover_photo_url'] as String?,
      paymentStatus: json['payment_status'] as String?,
    );
  }
}
