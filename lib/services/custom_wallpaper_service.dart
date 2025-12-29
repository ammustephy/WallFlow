import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';

class CustomWallpaperService {
  // Save custom wallpaper
  Future<Map<String, dynamic>?> saveCustomWallpaper(
    String email,
    String imageData,
    Map<String, dynamic> metadata,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('${Constants.baseUrl}/api/wallpaper/save-custom'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'imageData': imageData,
          'metadata': metadata,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 403) {
        throw Exception('Premium subscription required');
      }
      return null;
    } catch (e) {
      print('Error saving custom wallpaper: $e');
      rethrow;
    }
  }

  // Get user's custom wallpapers
  Future<List<dynamic>> getMyCustomWallpapers(String email) async {
    try {
      final response = await http.get(
        Uri.parse('${Constants.baseUrl}/api/wallpaper/my-custom?email=$email'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['wallpapers'] != null) {
          return data['wallpapers'];
        }
      }
      return [];
    } catch (e) {
      print('Error getting custom wallpapers: $e');
      return [];
    }
  }

  // Delete custom wallpaper
  Future<bool> deleteCustomWallpaper(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('${Constants.baseUrl}/api/wallpaper/custom/$id'),
        headers: {'Content-Type': 'application/json'},
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error deleting wallpaper: $e');
      return false;
    }
  }
}
