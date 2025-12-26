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
  });

  factory Wallpaper.fromJson(Map<String, dynamic> json) {
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
    );
  }
}
