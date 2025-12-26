import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/wallpaper.dart';
import '../utils/constants.dart';

class UnsplashService {
  static const String _baseUrl = 'https://api.unsplash.com';

  Future<List<Wallpaper>> getWallpapers({
    int page = 1,
    int perPage = 20,
  }) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/photos?page=$page&per_page=$perPage'),
      headers: {'Authorization': 'Client-ID ${Constants.unsplashAccessKey}'},
    );

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((item) => Wallpaper.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load wallpapers');
    }
  }

  Future<List<Wallpaper>> searchWallpapers(
    String query, {
    int page = 1,
    int perPage = 20,
  }) async {
    final response = await http.get(
      Uri.parse(
        '$_baseUrl/search/photos?query=$query&page=$page&per_page=$perPage',
      ),
      headers: {'Authorization': 'Client-ID ${Constants.unsplashAccessKey}'},
    );

    if (response.statusCode == 200) {
      Map<String, dynamic> data = json.decode(response.body);
      List<dynamic> results = data['results'];
      return results.map((item) => Wallpaper.fromJson(item)).toList();
    } else {
      throw Exception('Failed to search wallpapers');
    }
  }
}
