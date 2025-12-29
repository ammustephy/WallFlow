import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/wallpaper.dart';

class UserCollectionsProvider with ChangeNotifier {
  List<Wallpaper> _favorites = [];
  List<Wallpaper> _downloads = [];
  String? _currentUserEmail;

  List<Wallpaper> get favorites => _favorites;
  List<Wallpaper> get downloads => _downloads;

  UserCollectionsProvider() {
    // Initial load will be empty until updateUser is called
  }

  void updateUser(String? email) {
    if (_currentUserEmail != email) {
      _currentUserEmail = email;
      if (_currentUserEmail != null) {
        _loadCollections();
      } else {
        _favorites = [];
        _downloads = [];
        notifyListeners();
      }
    }
  }

  String get _favoritesKey => _currentUserEmail != null
      ? 'favorites_${_currentUserEmail!.toLowerCase()}'
      : 'favorites';

  String get _downloadsKey => _currentUserEmail != null
      ? 'downloads_${_currentUserEmail!.toLowerCase()}'
      : 'downloads';

  Future<void> _loadCollections() async {
    final prefs = await SharedPreferences.getInstance();

    // Load Favorites
    final favoriteData = prefs.getStringList(_favoritesKey) ?? [];
    _favorites = favoriteData.map((item) => _wallpaperFromJson(item)).toList();

    // Load Downloads
    final downloadData = prefs.getStringList(_downloadsKey) ?? [];
    _downloads = downloadData.map((item) => _wallpaperFromJson(item)).toList();

    notifyListeners();
  }

  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final favoriteData = _favorites
        .map((item) => _wallpaperToJson(item))
        .toList();
    await prefs.setStringList(_favoritesKey, favoriteData);
  }

  Future<void> _saveDownloads() async {
    final prefs = await SharedPreferences.getInstance();
    final downloadData = _downloads
        .map((item) => _wallpaperToJson(item))
        .toList();
    await prefs.setStringList(_downloadsKey, downloadData);
  }

  void toggleFavorite(Wallpaper wallpaper) {
    if (_currentUserEmail == null) return;
    final index = _favorites.indexWhere((item) => item.id == wallpaper.id);
    if (index >= 0) {
      _favorites.removeAt(index);
    } else {
      _favorites.add(wallpaper);
    }
    notifyListeners();
    _saveFavorites();
  }

  bool isFavorite(String id) {
    return _favorites.any((item) => item.id == id);
  }

  void addDownload(Wallpaper wallpaper) {
    if (_currentUserEmail == null) return;
    if (!_downloads.any((item) => item.id == wallpaper.id)) {
      _downloads.insert(0, wallpaper);
      notifyListeners();
      _saveDownloads();
    }
  }

  // Simple serialization helpers since Wallpaper doesn't have fromMap/toMap
  String _wallpaperToJson(Wallpaper wallpaper) {
    return jsonEncode({
      'id': wallpaper.id,
      'description': wallpaper.description,
      'alt_description': wallpaper.altDescription,
      'urls': {
        'raw': wallpaper.rawUrl,
        'full': wallpaper.fullUrl,
        'regular': wallpaper.regularUrl,
        'small': wallpaper.smallUrl,
        'thumb': wallpaper.thumbUrl,
      },
      'user': {
        'name': wallpaper.userName,
        'profile_image': {'medium': wallpaper.userProfileImage},
      },
    });
  }

  Wallpaper _wallpaperFromJson(String source) {
    return Wallpaper.fromJson(jsonDecode(source));
  }
}
