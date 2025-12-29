class Wallpaper {
  final String id;
  final String description;
  final String altDescription;
  final String rawUrl;
  final String fullUrl;
  final String regularUrl;
  final String smallUrl;
  final String thumbUrl;
  final String userName;
  final String userProfileImage;
  final bool isPremium;

  Wallpaper({
    required this.id,
    required this.description,
    required this.altDescription,
    required this.rawUrl,
    required this.fullUrl,
    required this.regularUrl,
    required this.smallUrl,
    required this.thumbUrl,
    required this.userName,
    required this.userProfileImage,
    this.isPremium = false,
  });

  factory Wallpaper.fromJson(Map<String, dynamic> json) {
    // Randomly mark some as premium for demo purposes if not specified
    final bool premium = json['isPremium'] ?? (json['id'].hashCode % 5 == 0);

    return Wallpaper(
      id: json['id'] ?? '',
      description: json['description'] ?? '',
      altDescription: json['alt_description'] ?? '',
      rawUrl: json['urls']['raw'] ?? '',
      fullUrl: json['urls']['full'] ?? '',
      regularUrl: json['urls']['regular'] ?? '',
      smallUrl: json['urls']['small'] ?? '',
      thumbUrl: json['urls']['thumb'] ?? '',
      userName: json['user']['name'] ?? '',
      userProfileImage: json['user']['profile_image']['medium'] ?? '',
      isPremium: premium,
    );
  }
}
