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
  final bool contactChat;
  final bool contactWhatsApp;
  final bool contactCall;
  final bool isBoosted;
  final String? publishedAt;
  final String createdAt;
  final String? updatedAt;
  final String? coverPhotoUrl;
  final String? paymentStatus;
  final List<String> photos;
  final List<ListingPhoto> photoObjects;
  final int likesCount;
  final int commentsCount;
  final bool likedByMe;

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
    this.contactChat = true,
    this.contactWhatsApp = true,
    this.contactCall = true,
    this.isBoosted = false,
    this.publishedAt,
    this.updatedAt,
    this.coverPhotoUrl,
    this.paymentStatus,
    this.photos = const [],
    this.photoObjects = const [],
    this.likesCount = 0,
    this.commentsCount = 0,
    this.likedByMe = false,
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
    int parseUserId() {
      final raw =
          json['user_id'] ??
          json['userId'] ??
          json['owner_id'] ??
          json['ownerId'] ??
          json['id_user'] ??
          json['idUser'];
      return raw is num
          ? raw.toInt()
          : int.tryParse(raw?.toString() ?? '0') ?? 0;
    }

    return ListingModel(
      id: json['id'] is String ? int.parse(json['id']) : json['id'] ?? 0,
      userId: parseUserId(),
      type: json['type'] ?? 'lost',
      status: json['status'] ?? 'draft',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      categoryId: parsedCategoryId,
      categoryName: json['category_name'] as String?,
      city: json['city'] as String?,
      locationText: json['location_text'] as String?,
      eventDate: json['event_date'] as String?,
      contactChat:
          (json['contact_chat'] == 1 ||
          json['contact_chat'] == '1' ||
          json['contact_chat'] == true),
      contactWhatsApp:
          (json['contact_whatsapp'] == 1 ||
          json['contact_whatsapp'] == '1' ||
          json['contact_whatsapp'] == true),
      contactCall:
          (json['contact_call'] == 1 ||
          json['contact_call'] == '1' ||
          json['contact_call'] == true),
      isBoosted: boosted,
      publishedAt: json['published_at'] as String?,
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] as String?,
      coverPhotoUrl: json['cover_photo_url'] as String?,
      photoObjects:
          (json['photos'] as List<dynamic>?)
              ?.map(ListingPhoto.fromDynamic)
              .whereType<ListingPhoto>()
              .toList() ??
          const [],
      photos:
          (json['photos'] as List<dynamic>?)
              ?.map(
                (e) => e is Map<String, dynamic>
                    ? e['url']?.toString() ?? ''
                    : e.toString(),
              )
              .where((e) => e.isNotEmpty)
              .toList() ??
          const [],
      likesCount: json['likes_count'] is num
          ? (json['likes_count'] as num).toInt()
          : int.tryParse(json['likes_count']?.toString() ?? '0') ?? 0,
      commentsCount: json['comments_count'] is num
          ? (json['comments_count'] as num).toInt()
          : int.tryParse(json['comments_count']?.toString() ?? '0') ?? 0,
      likedByMe:
          json['liked_by_me'] == 1 ||
          json['liked_by_me'] == true ||
          json['liked_by_me'] == '1',
      paymentStatus: json['payment_status'] as String?,
    );
  }
}

class ListingPhoto {
  final int id;
  final String url;
  ListingPhoto({required this.id, required this.url});

  factory ListingPhoto.fromDynamic(dynamic input) {
    if (input is Map<String, dynamic>) {
      final idRaw = input['id'];
      final id = idRaw is int ? idRaw : int.tryParse(idRaw?.toString() ?? '');
      final url = input['url']?.toString();
      if (id != null && url != null && url.isNotEmpty) {
        return ListingPhoto(id: id, url: url);
      }
    }
    return ListingPhoto(id: 0, url: input?.toString() ?? '');
  }
}
