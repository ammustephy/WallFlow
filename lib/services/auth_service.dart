import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:path_provider/path_provider.dart';
import '../utils/constants.dart';

class AuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'ngrok-skip-browser-warning': 'true',
  };

  Future<String?> getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<String?> getEmail() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('email');
  }

  Future<void> logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('email');
    await prefs.remove('display_name');
    await prefs.remove('profile_image_path');
    try {
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }
    } catch (e) {
      print('DEBUG: Google Sign Out Error: $e');
    }
  }

  Future<void> _saveLocalImage(String base64Image, String userEmail) async {
    try {
      final bytes = base64Decode(base64Image);
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/profile_${userEmail}.png');
      await file.writeAsBytes(bytes);
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('profile_image_path_${userEmail}', file.path);
    } catch (e) {
      print('DEBUG: Background image save failed: $e');
    }
  }

  Future<String?> login(String email, String password) async {
    final normalizedEmail = email.trim().toLowerCase();
    final url = '${Constants.baseUrl}/login';
    try {
      final response = await http
          .post(
            Uri.parse(url),
            headers: _headers,
            body: jsonEncode({'email': normalizedEmail, 'password': password}),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == true) {
          final token = data['token'];
          final userEmail = data['user']['email'];

          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', token);
          await prefs.setString('email', userEmail);

          if (data['user']['displayName'] != null &&
              data['user']['displayName'].toString().isNotEmpty) {
            await prefs.setString('display_name', data['user']['displayName']);
          } else {
            await prefs.remove('display_name');
          }

          if (data['user'] != null &&
              data['user']['profilePicture'] != null &&
              data['user']['profilePicture'].toString().isNotEmpty) {
            // Await to ensure UI can load it immediately
            final pPic = data['user']['profilePicture'];
            await _saveLocalImage(pPic, userEmail);
          }
          return token;
        } else {
          throw Exception(
            'Login Failed: ${data['message'] ?? data['error'] ?? response.body}',
          );
        }
      } else if (response.statusCode == 502) {
        throw Exception('Server Unreachable (502)');
      } else {
        throw Exception(
          'Login Failed: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('DEBUG: Login Error: $e');
      throw e; // Rethrow to show in UI
    }
  }

  Future<bool> register(String email, String password) async {
    final normalizedEmail = email.trim().toLowerCase();
    final url = '${Constants.baseUrl}/registration';
    try {
      final response = await http
          .post(
            Uri.parse(url),
            headers: _headers,
            body: jsonEncode({'email': normalizedEmail, 'password': password}),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['status'] == true;
      }
    } catch (e) {
      print('DEBUG: Registration Error: $e');
      throw Exception('Server Unreachable');
    }
    return false;
  }

  Future<Map<String, dynamic>?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      return {
        'email': googleUser.email,
        'displayName': googleUser.displayName,
        'photoUrl': googleUser.photoUrl,
      };
    } catch (e) {
      print('DEBUG: Google Sign-In Error: $e');
      return null;
    }
  }

  Future<String?> socialLogin(
    String email,
    String provider,
    String? displayName,
  ) async {
    final url = '${Constants.baseUrl}/social-login';
    try {
      final response = await http
          .post(
            Uri.parse(url),
            headers: _headers,
            body: jsonEncode({
              'email': email,
              'provider': provider,
              'displayName': displayName,
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == true) {
          final token = data['token'];
          final userEmail = data['user']['email'];

          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', token);
          await prefs.setString('email', userEmail);
          if (data['user']['displayName'] != null) {
            await prefs.setString('display_name', data['user']['displayName']);
          }
          if (data['user']['profilePicture'] != null &&
              data['user']['profilePicture'].toString().isNotEmpty) {
            final pPic = data['user']['profilePicture'];
            await _saveLocalImage(pPic, userEmail);
          }

          return token;
        }
      }
    } catch (e) {
      print('DEBUG: Social Login Error: $e');
    }
    return null;
  }

  Future<bool> updateUser(
    String email,
    String displayName,
    String? profilePicture,
  ) async {
    final url = '${Constants.baseUrl}/update-user';
    try {
      final response = await http
          .post(
            Uri.parse(url),
            headers: _headers,
            body: jsonEncode({
              'email': email,
              'displayName': displayName,
              'profilePicture': profilePicture,
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['status'] == true;
      }
    } catch (e) {
      print('DEBUG: Update User Error: $e');
    }
    return false;
  }
}
