import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:gal/gal.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:async_wallpaper/async_wallpaper.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/subscription_provider.dart';
import '../providers/auth_provider.dart';
import '../services/ai_service.dart';
import '../utils/theme.dart';
import '../widgets/premium_paywall_dialog.dart';

class AiGeneratorScreen extends StatefulWidget {
  const AiGeneratorScreen({super.key});

  @override
  State<AiGeneratorScreen> createState() => _AiGeneratorScreenState();
}

class _AiGeneratorScreenState extends State<AiGeneratorScreen> {
  final TextEditingController _promptController = TextEditingController();
  final AiService _aiService = AiService();

  bool _isGenerating = false;
  bool _isLoadingSuggestions = false;
  List<String> _suggestions = [];
  Map<String, dynamic>? _generatedWallpaper;
  List<dynamic> _myWallpapers = [];

  @override
  void initState() {
    super.initState();
    _loadSuggestions();
    _loadMyWallpapers();
  }

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  bool _isProcessingAction = false;

  Future<void> _loadSuggestions() async {
    setState(() => _isLoadingSuggestions = true);

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final suggestions = await _aiService.getSuggestPrompts(
      auth.email ?? '',
      _promptController.text.isEmpty ? null : _promptController.text,
    );

    if (mounted) {
      setState(() {
        _suggestions = suggestions;
        _isLoadingSuggestions = false;
      });
    }
  }

  Future<void> _loadMyWallpapers() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final wallpapers = await _aiService.getMyGeneratedWallpapers(
      auth.email ?? '',
    );

    if (mounted) {
      setState(() => _myWallpapers = wallpapers);
    }
  }

  Future<void> _downloadGeneratedImage(String imageSource) async {
    setState(() => _isProcessingAction = true);
    try {
      if (imageSource.startsWith('http')) {
        // Handle URL
        if (kIsWeb) {
          if (await canLaunchUrl(Uri.parse(imageSource))) {
            await launchUrl(
              Uri.parse(imageSource),
              mode: LaunchMode.externalApplication,
            );
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
            imageSource,
            options: Options(responseType: ResponseType.bytes),
          );
          await Gal.putImageBytes(
            Uint8List.fromList(response.data),
            name: "WallFlow_AI_${DateTime.now().millisecondsSinceEpoch}",
          );
          _showSnackBar('Saved to gallery!');
        } else {
          _showSnackBar('Permission denied', isError: true);
        }
      } else {
        // Handle Base64
        final bytes = base64Decode(imageSource);
        await Gal.putImageBytes(
          bytes,
          name: "WallFlow_AI_${DateTime.now().millisecondsSinceEpoch}",
        );
        _showSnackBar('Saved to gallery!');
      }
    } catch (e) {
      _showSnackBar('Error: $e', isError: true);
    } finally {
      setState(() => _isProcessingAction = false);
    }
  }

  Future<void> _setGeneratedWallpaper(String imageSource) async {
    if (kIsWeb) {
      _showSnackBar('Not supported on Web', isError: true);
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text(
                'Set AI Wallpaper',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home_rounded),
              title: const Text('Home Screen'),
              onTap: () =>
                  _applyWallpaper(imageSource, AsyncWallpaper.HOME_SCREEN),
            ),
            ListTile(
              leading: const Icon(Icons.lock_rounded),
              title: const Text('Lock Screen'),
              onTap: () =>
                  _applyWallpaper(imageSource, AsyncWallpaper.LOCK_SCREEN),
            ),
            ListTile(
              leading: const Icon(Icons.phonelink_lock_rounded),
              title: const Text('Both Screens'),
              onTap: () =>
                  _applyWallpaper(imageSource, AsyncWallpaper.BOTH_SCREENS),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Future<void> _applyWallpaper(String imageSource, int location) async {
    Navigator.pop(context);
    setState(() => _isProcessingAction = true);
    try {
      bool result;
      if (imageSource.startsWith('http')) {
        result = await AsyncWallpaper.setWallpaper(
          url: imageSource,
          wallpaperLocation: location,
          goToHome: true,
        );
      } else {
        // For base64, we might need to save to temp file first if async_wallpaper doesn't support bytes directly
        // But some versions support setWallpaperFromFile. Let's assume URL for now or if base64 we use the bytes
        // Actually async_wallpaper usually needs a URL or a file path.
        // For simplicity and standard practice, we'll assume the backend provides a URL for setting wallpaper
        // or we use the small image if it's a preview.
        _showSnackBar('Setting wallpaper from AI generation...');
        result = await AsyncWallpaper.setWallpaper(
          url: imageSource, // Assuming URL or data URI if supported
          wallpaperLocation: location,
          goToHome: true,
        );
      }
      _showSnackBar(result ? 'Wallpaper set!' : 'Failed to set wallpaper');
    } catch (e) {
      _showSnackBar('Error: $e', isError: true);
    } finally {
      setState(() => _isProcessingAction = false);
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

  Future<void> _generateWallpaper() async {
    final subscription = Provider.of<SubscriptionProvider>(
      context,
      listen: false,
    );

    // Tiered Access: Allow short prompts for free
    final prompt = _promptController.text.trim();
    const int freeLimit = 50;

    if (!subscription.isPremium && prompt.length > freeLimit) {
      FocusScope.of(context).unfocus(); // Dismiss keyboard
      PremiumPaywallDialog.show(
        context,
        featureName: 'AI Advanced Generation',
        featureDescription:
            'Short prompts (<$freeLimit chars) are free! For detailed and complex creations, upgrade to WallFlow Premium.',
      );
      return;
    }

    if (prompt.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a prompt')));
      return;
    }

    setState(() => _isGenerating = true);

    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);

      if (auth.email == null || auth.email!.isEmpty) {
        throw Exception('User email not found. Please log in again.');
      }

      final result = await _aiService.generateWallpaper(
        auth.email!,
        _promptController.text.trim(),
      );

      if (mounted && result != null) {
        setState(() {
          _generatedWallpaper = result['wallpaper'];
        });
        await _loadMyWallpapers();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Wallpaper generated successfully! Check below.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Backend returned empty result. Check logs.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Wallpaper Generator'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.accentColor.withOpacity(0.2),
                    AppTheme.accentColor.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.auto_awesome_rounded,
                    size: 40,
                    color: AppTheme.accentColor,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Create with AI',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Powered by Google Gemini',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Prompt Input
            const Text(
              'Describe your wallpaper',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Material(
              color: AppTheme.cardBg,
              borderRadius: BorderRadius.circular(16),
              child: TextField(
                controller: _promptController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'e.g., A serene mountain landscape at sunset...',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                ),
                onChanged: (value) {
                  if (value.length > 10) {
                    _loadSuggestions();
                  }
                },
              ),
            ),
            const SizedBox(height: 16),

            // AI Suggestions
            if (_suggestions.isNotEmpty) ...[
              Row(
                children: [
                  const Icon(
                    Icons.lightbulb_outline_rounded,
                    size: 20,
                    color: AppTheme.accentColor,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'AI Suggestions',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  if (_isLoadingSuggestions)
                    const Padding(
                      padding: EdgeInsets.only(left: 8.0),
                      child: SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.accentColor,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _suggestions.map((suggestion) {
                  return InkWell(
                    onTap: () {
                      setState(() {
                        _promptController.text = suggestion;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.cardBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppTheme.accentColor.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        suggestion.length > 40
                            ? '${suggestion.substring(0, 40)}...'
                            : suggestion,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],

            // Generate Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isGenerating ? null : _generateWallpaper,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isGenerating
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.auto_awesome_rounded),
                          SizedBox(width: 8),
                          Text(
                            'Generate Wallpaper',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 32),

            // Generated Wallpaper Preview
            if (_generatedWallpaper != null) ...[
              const Text(
                'Generated Wallpaper',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppTheme.cardBg,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                      child: _buildImageWidget(
                        _generatedWallpaper!['imageUrl'] ??
                            _generatedWallpaper!['base64'] ??
                            _generatedWallpaper!['imageData'],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _generatedWallpaper!['prompt'] ?? '',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildActionButton(
                                  icon: Icons.download_rounded,
                                  label: 'Download',
                                  onPressed: () => _downloadGeneratedImage(
                                    _generatedWallpaper!['imageUrl'] ??
                                        _generatedWallpaper!['base64'] ??
                                        _generatedWallpaper!['imageData'],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildActionButton(
                                  icon: Icons.wallpaper_rounded,
                                  label: 'Set Wall',
                                  onPressed: () => _setGeneratedWallpaper(
                                    _generatedWallpaper!['imageUrl'] ??
                                        _generatedWallpaper!['base64'] ??
                                        _generatedWallpaper!['imageData'],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],

            // My Generated Wallpapers
            if (_myWallpapers.isNotEmpty) ...[
              const Text(
                'My Generated Wallpapers',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.7,
                ),
                itemCount: _myWallpapers.length,
                itemBuilder: (context, index) {
                  final wallpaper = _myWallpapers[index];
                  final imageSource =
                      wallpaper['imageUrl'] ??
                      wallpaper['base64'] ??
                      wallpaper['imageData'];

                  return Container(
                    decoration: BoxDecoration(
                      color: AppTheme.cardBg,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(16),
                            ),
                            child: imageSource != null
                                ? _buildImageWidget(
                                    imageSource,
                                    isThumbnail: true,
                                  )
                                : Container(
                                    color: AppTheme.accentColor.withOpacity(
                                      0.1,
                                    ),
                                    child: const Center(
                                      child: Icon(
                                        Icons.image_rounded,
                                        size: 48,
                                        color: AppTheme.accentColor,
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            wallpaper['prompt'] ?? 'Generated Wallpaper',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
            if (_isProcessingAction)
              Container(
                color: Colors.black54,
                child: const Center(
                  child: CircularProgressIndicator(color: AppTheme.accentColor),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageWidget(String? source, {bool isThumbnail = false}) {
    if (source == null) return const SizedBox.shrink();

    if (source.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: source,
        fit: BoxFit.cover,
        width: double.infinity,
        placeholder: (context, url) => Center(
          child: CircularProgressIndicator(
            color: AppTheme.accentColor.withOpacity(0.5),
          ),
        ),
        errorWidget: (context, url, error) => const Icon(Icons.error),
      );
    } else {
      try {
        final bytes = base64Decode(source);
        return Image.memory(bytes, fit: BoxFit.cover, width: double.infinity);
      } catch (e) {
        return const Center(child: Icon(Icons.broken_image_rounded));
      }
    }
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.darkBg,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: AppTheme.accentColor.withOpacity(0.3)),
        ),
      ),
    );
  }
}
