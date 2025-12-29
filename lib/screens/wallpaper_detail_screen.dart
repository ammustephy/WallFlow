import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:gal/gal.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:async_wallpaper/async_wallpaper.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/wallpaper.dart';
import '../utils/theme.dart';

import 'package:provider/provider.dart';
import '../providers/user_collections_provider.dart';
import '../providers/subscription_provider.dart';
import '../widgets/premium_paywall_dialog.dart';

class WallpaperDetailScreen extends StatefulWidget {
  final Wallpaper wallpaper;

  const WallpaperDetailScreen({super.key, required this.wallpaper});

  @override
  State<WallpaperDetailScreen> createState() => _WallpaperDetailScreenState();
}

class _WallpaperDetailScreenState extends State<WallpaperDetailScreen> {
  bool _isProcessing = false;
  double _downloadProgress = 0.0;

  Future<void> _downloadImage(String url, String quality) async {
    setState(() {
      _isProcessing = true;
      _downloadProgress = 0.0;
    });

    try {
      if (kIsWeb) {
        if (await canLaunchUrl(Uri.parse(url))) {
          await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
          _showSnackBar('Opening image in new tab...');
        } else {
          _showSnackBar('Could not open download link', isError: true);
        }
        return;
      }

      bool hasPermission = false;
      if (await Permission.photos.request().isGranted ||
          await Permission.storage.request().isGranted) {
        hasPermission = true;
      }

      if (hasPermission) {
        var response = await Dio().get(
          url,
          onReceiveProgress: (received, total) {
            if (total != -1) {
              setState(() => _downloadProgress = received / total);
            }
          },
          options: Options(responseType: ResponseType.bytes),
        );

        await Gal.putImageBytes(
          Uint8List.fromList(response.data),
          name: "WallFlow_${widget.wallpaper.id}_$quality",
        );

        if (mounted) {
          Provider.of<UserCollectionsProvider>(
            context,
            listen: false,
          ).addDownload(widget.wallpaper);
          _showSnackBar('Downloaded $quality quality image!');
        }
      } else {
        _showSnackBar('Permission denied', isError: true);
      }
    } catch (e) {
      _showSnackBar('Error: $e', isError: true);
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _setWallpaper(String url, int location) async {
    if (kIsWeb) {
      _showSnackBar('Not supported on Web', isError: true);
      return;
    }
    setState(() => _isProcessing = true);
    try {
      bool result = await AsyncWallpaper.setWallpaper(
        url: url,
        wallpaperLocation: location,
        goToHome: true,
      );
      if (mounted) {
        _showSnackBar(
          result ? 'Wallpaper set successfully' : 'Failed to set wallpaper',
        );
      }
    } catch (e) {
      _showSnackBar('Error: $e', isError: true);
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : AppTheme.accentColor,
      ),
    );
  }

  bool _checkPremiumAccess() {
    final subscription = Provider.of<SubscriptionProvider>(
      context,
      listen: false,
    );
    if (widget.wallpaper.isPremium && !subscription.isPremium) {
      PremiumPaywallDialog.show(
        context,
        featureName: 'Premium Wallpaper',
        featureDescription:
            'This is a premium wallpaper. Upgrade to WallFlow Premium to download and set it as your wallpaper.',
      );
      return false;
    }
    return true;
  }

  void _showSetOptions() {
    if (!_checkPremiumAccess()) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      elevation: 0,
      builder: (context) {
        return Container(
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(24),
          ),
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Set Wallpaper',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              ListTile(
                title: const Text('Home Screen'),
                onTap: () {
                  Navigator.pop(context);
                  _setWallpaper(
                    widget.wallpaper.regularUrl,
                    AsyncWallpaper.HOME_SCREEN,
                  );
                },
              ),
              ListTile(
                title: const Text('Lock Screen'),
                onTap: () {
                  Navigator.pop(context);
                  _setWallpaper(
                    widget.wallpaper.regularUrl,
                    AsyncWallpaper.LOCK_SCREEN,
                  );
                },
              ),
              ListTile(
                title: const Text('Both Screens'),
                onTap: () {
                  Navigator.pop(context);
                  _setWallpaper(
                    widget.wallpaper.regularUrl,
                    AsyncWallpaper.BOTH_SCREENS,
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDownloadOptions() {
    if (!_checkPremiumAccess()) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      elevation: 0,
      builder: (context) {
        return Container(
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(24),
          ),
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Select Quality',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              ListTile(
                title: const Text('Small (Quick)'),
                onTap: () {
                  Navigator.pop(context);
                  _downloadImage(widget.wallpaper.smallUrl, 'Small');
                },
              ),
              ListTile(
                title: const Text('Regular'),
                onTap: () {
                  Navigator.pop(context);
                  _downloadImage(widget.wallpaper.regularUrl, 'Regular');
                },
              ),
              ListTile(
                title: const Text('Full (High Resolution)'),
                onTap: () {
                  Navigator.pop(context);
                  _downloadImage(widget.wallpaper.fullUrl, 'Full');
                },
              ),
              ListTile(
                title: const Text('Raw (UHD)'),
                onTap: () {
                  Navigator.pop(context);
                  _downloadImage(widget.wallpaper.rawUrl, 'Raw');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          Consumer<UserCollectionsProvider>(
            builder: (context, provider, child) {
              final isFav = provider.isFavorite(widget.wallpaper.id);
              return IconButton(
                onPressed: () => provider.toggleFavorite(widget.wallpaper),
                icon: Icon(
                  isFav ? Icons.favorite : Icons.favorite_border,
                  color: isFav ? Colors.redAccent : Colors.white,
                ),
              );
            },
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Hero(
            tag: widget.wallpaper.id,
            child: CachedNetworkImage(
              imageUrl: widget.wallpaper.regularUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) =>
                  const Center(child: CircularProgressIndicator()),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.1),
                  Colors.black.withOpacity(0.6),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 60,
            left: 20,
            right: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.wallpaper.altDescription.toUpperCase(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'by ${widget.wallpaper.userName}',
                  style: const TextStyle(fontSize: 14, color: Colors.white70),
                ),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildActionButton(
                      icon: Icons.download,
                      label: 'Download',
                      onPressed: _showDownloadOptions,
                    ),
                    if (!kIsWeb)
                      _buildActionButton(
                        icon: Icons.wallpaper,
                        label: 'Set Wallpaper',
                        onPressed: _showSetOptions,
                      ),
                  ],
                ),
              ],
            ),
          ),
          if (_isProcessing)
            Container(
              color: Colors.black45,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(
                      color: AppTheme.accentColor,
                    ),
                    if (_downloadProgress > 0) ...[
                      const SizedBox(height: 10),
                      Text(
                        '${(_downloadProgress * 100).toInt()}%',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.deepPurpleAccent,
        shape: const CircleBorder(),
        padding: const EdgeInsets.all(20),
      ),
      child: Icon(icon, color: Colors.white),
    );
  }
}
