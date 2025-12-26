import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  String? _token;
  String? _email;
  String? _profileImagePath;
  String? _displayName;
  bool _isLoading = false;

  String? get token => _token;
  String? get email => _email;
  String? get profileImagePath => _profileImagePath;
  String? get displayName => _displayName;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _token != null;

  Future<void> tryAutoLogin() async {
    _token = await _authService.getToken();
    _email = await _authService.getEmail();
    if (_email != null) {
      _email = _email!.toLowerCase(); // Normalize
      final prefs = await SharedPreferences.getInstance();
      _profileImagePath = prefs.getString('profile_image_path_${_email}');
      _displayName = prefs.getString('display_name_${_email}');
    }
    notifyListeners();
  }

  Future<void> setProfileImage(String path) async {
    if (_email == null) return;

    // Copy to permanent location
    try {
      final directory = await getApplicationDocumentsDirectory();
      final name = 'profile_${_email}.png';
      final newFile = File('${directory.path}/$name');
      final sourceFile = File(path);
      await sourceFile.copy(newFile.path);

      _profileImagePath = newFile.path;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profile_image_path_${_email}', newFile.path);
      notifyListeners();

      // Sync to backend
      final bytes = await newFile.readAsBytes();
      final base64Image = base64Encode(bytes);
      await _authService.updateUser(_email!, _displayName ?? '', base64Image);
    } catch (e) {
      print('DEBUG: Error setting profile image: $e');
    }
  }

  Future<void> removeProfileImage() async {
    if (_email == null) return;
    _profileImagePath = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('profile_image_path_${_email}');
    notifyListeners();

    // Sync removal to backend
    try {
      await _authService.updateUser(_email!, _displayName ?? '', null);
    } catch (e) {
      print('DEBUG: Error triggering background image removal sync: $e');
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final normalizedEmail = email.trim().toLowerCase();
      _token = await _authService.login(normalizedEmail, password);
      if (_token != null) {
        _email = normalizedEmail;
        final prefs = await SharedPreferences.getInstance();

        // Load user-specific details (image is local-only)
        _profileImagePath = prefs.getString('profile_image_path_${_email}');

        // Server-side displayName always takes precedence if available
        _displayName = prefs.getString('display_name');
        if (_displayName != null && _displayName!.isNotEmpty) {
          await prefs.setString('display_name_${_email}', _displayName!);
        } else {
          // Fallback to local persistence if server has no name set yet
          _displayName = prefs.getString('display_name_${_email}');
        }
      }
      return _token != null;
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> register(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    bool success = await _authService.register(email, password);

    _isLoading = false;
    notifyListeners();
    return success;
  }

  Future<bool> socialLogin(String platform) async {
    _isLoading = true;
    notifyListeners();

    try {
      if (platform.toLowerCase() == 'google') {
        final googleData = await _authService.signInWithGoogle();
        if (googleData != null) {
          _token = await _authService.socialLogin(
            googleData['email'],
            'google',
            googleData['displayName'],
          );

          if (_token != null) {
            _email = googleData['email'];
            _displayName = googleData['displayName'];
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('email', _email!);
            if (_displayName != null) {
              await prefs.setString('display_name', _displayName!);
            }
          }
        }
      } else {
        // Fallback for other platforms if needed
        // For now, only Google is officially implemented professionally
      }
    } catch (e) {
      print('DEBUG: Social Login Error: $e');
    }

    _isLoading = false;
    notifyListeners();
    return _token != null;
  }

  Future<void> logout() async {
    await _authService.logout();
    _token = null;
    _email = null;
    _profileImagePath = null;
    _displayName = null;
    notifyListeners();
  }

  Future<bool> updateDisplayName(String newName) async {
    if (_email == null) return false;

    _isLoading = true;
    notifyListeners();

    String? base64Image;
    if (_profileImagePath != null) {
      final file = File(_profileImagePath!);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        base64Image = base64Encode(bytes);
      }
    }

    bool success = await _authService.updateUser(_email!, newName, base64Image);
    if (success) {
      _displayName = newName;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'display_name',
        newName,
      ); // Global key for current session
      await prefs.setString(
        'display_name_${_email}',
        newName,
      ); // User-specific key for persistence
    }

    _isLoading = false;
    notifyListeners();
    return success;
  }
}
