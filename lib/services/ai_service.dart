import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';

class AiService {
  // Generate wallpaper from prompt
  Future<Map<String, dynamic>?> generateWallpaper(
    String email,
    String prompt,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse('${Constants.baseUrl}/api/ai/generate-wallpaper'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'email': email, 'prompt': prompt}),
          )
          .timeout(const Duration(minutes: 3));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorData = json.decode(response.body);
        final errorMessage =
            errorData['message'] ??
            errorData['error'] ??
            'Failed to generate wallpaper (${response.statusCode})';
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        print('DEBUG: AiService.generateWallpaper Timeout: $e');
        throw Exception(
          'The request timed out. AI generation can take a few minutes. Please try again or check "My Generated Wallpapers" in a moment.',
        );
      }
      print('DEBUG: AiService.generateWallpaper Error: $e');
      rethrow;
    }
  }

  // Get AI prompt suggestions
  Future<List<String>> getSuggestPrompts(
    String email, [
    String? context,
  ]) async {
    try {
      final response = await http.post(
        Uri.parse('${Constants.baseUrl}/api/ai/suggest-prompts'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          if (context != null) 'context': context,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['suggestions'] != null) {
          return List<String>.from(data['suggestions']);
        }
      }
      return [];
    } catch (e) {
      print('DEBUG: AiService.getSuggestPrompts Error: $e');
      return [];
    }
  }

  // Get user's generated wallpapers
  Future<List<dynamic>> getMyGeneratedWallpapers(String email) async {
    try {
      final response = await http.get(
        Uri.parse('${Constants.baseUrl}/api/ai/my-generated?email=$email'),
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
      print('DEBUG: AiService.getMyGeneratedWallpapers Error: $e');
      return [];
    }
  }

  // Delete generated wallpaper
  Future<bool> deleteGeneratedWallpaper(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('${Constants.baseUrl}/api/ai/generated/$id'),
        headers: {'Content-Type': 'application/json'},
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error deleting wallpaper: $e');
      return false;
    }
  }
}
