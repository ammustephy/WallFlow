import 'package:flutter/material.dart';
import '../models/wallpaper.dart';
import '../services/unsplash_service.dart';

class WallpaperProvider with ChangeNotifier {
  final UnsplashService _unsplashService = UnsplashService();
  List<Wallpaper> _wallpapers = [];
  bool _isLoading = false;
  int _currentPage = 1;

  List<Wallpaper> get wallpapers => _wallpapers;
  bool get isLoading => _isLoading;

  Future<void> fetchWallpapers({bool isRefresh = false}) async {
    if (isRefresh) {
      _currentPage = 1;
      _wallpapers = [];
    }

    _isLoading = true;
    notifyListeners();

    try {
      final newWallpapers = await _unsplashService.getWallpapers(
        page: _currentPage,
      );
      _wallpapers.addAll(newWallpapers);
      _currentPage++;
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> searchWallpapers(String query) async {
    _isLoading = true;
    _wallpapers = [];
    notifyListeners();

    try {
      _wallpapers = await _unsplashService.searchWallpapers(query);
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
