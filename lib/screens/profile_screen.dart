import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import '../providers/auth_provider.dart';
import '../utils/theme.dart';
import './collection_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _nameController = TextEditingController();
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    _nameController.text = auth.displayName ?? auth.email?.split('@')[0] ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (_nameController.text.trim().isEmpty) return;

    final success = await Provider.of<AuthProvider>(
      context,
      listen: false,
    ).updateDisplayName(_nameController.text.trim());

    if (success && mounted) {
      setState(() => _isEditing = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile updated!')));
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update profile'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _handleRemoveImage() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        title: const Text('Remove Photo?'),
        content: const Text(
          'Are you sure you want to remove your profile picture?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Remove',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await Provider.of<AuthProvider>(
        context,
        listen: false,
      ).removeProfileImage();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile picture removed')),
        );
      }
    }
  }

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            height: 4,
            width: 40,
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          ListTile(
            leading: const Icon(
              Icons.photo_library_outlined,
              color: Colors.white70,
            ),
            title: const Text('Choose from Gallery'),
            onTap: () async {
              Navigator.pop(ctx);
              try {
                final XFile? pickedFile = await _picker.pickImage(
                  source: ImageSource.gallery,
                  imageQuality: 100,
                );
                if (pickedFile != null && mounted) {
                  // Show loading indicator
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (ctx) => const Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.accentColor,
                      ),
                    ),
                  );

                  CroppedFile? croppedFile;
                  try {
                    croppedFile = await _cropImage(pickedFile);
                  } catch (e) {
                    // If cropper fails, use original image
                    print('Cropper error: $e');
                    if (mounted) {
                      Navigator.pop(context); // Dismiss loading
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Using original image (cropper unavailable)',
                          ),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    }
                  }

                  // Dismiss loading indicator
                  if (mounted) {
                    try {
                      Navigator.pop(context);
                    } catch (e) {
                      // Already dismissed
                    }
                  }

                  // Use cropped file if available, otherwise use original
                  final imagePathToUse = croppedFile?.path ?? pickedFile.path;

                  if (mounted) {
                    await Provider.of<AuthProvider>(
                      context,
                      listen: false,
                    ).setProfileImage(imagePathToUse);

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Profile picture updated!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  }
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
          ),
          ListTile(
            leading: const Icon(
              Icons.camera_alt_outlined,
              color: Colors.white70,
            ),
            title: const Text('Take a Photo'),
            onTap: () async {
              Navigator.pop(ctx);
              try {
                final XFile? pickedFile = await _picker.pickImage(
                  source: ImageSource.camera,
                  imageQuality: 100,
                );
                if (pickedFile != null && mounted) {
                  // Show loading indicator
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (ctx) => const Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.accentColor,
                      ),
                    ),
                  );

                  CroppedFile? croppedFile;
                  try {
                    croppedFile = await _cropImage(pickedFile);
                  } catch (e) {
                    // If cropper fails, use original image
                    print('Cropper error: $e');
                    if (mounted) {
                      Navigator.pop(context); // Dismiss loading
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Using original image (cropper unavailable)',
                          ),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    }
                  }

                  // Dismiss loading indicator
                  if (mounted) {
                    try {
                      Navigator.pop(context);
                    } catch (e) {
                      // Already dismissed
                    }
                  }

                  // Use cropped file if available, otherwise use original
                  final imagePathToUse = croppedFile?.path ?? pickedFile.path;

                  if (mounted) {
                    await Provider.of<AuthProvider>(
                      context,
                      listen: false,
                    ).setProfileImage(imagePathToUse);

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Profile picture updated!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  }
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
          ),
          if (Provider.of<AuthProvider>(
                context,
                listen: false,
              ).profileImagePath !=
              null)
            ListTile(
              leading: const Icon(
                Icons.delete_outline_rounded,
                color: Colors.redAccent,
              ),
              title: const Text(
                'Remove Photo',
                style: TextStyle(color: Colors.redAccent),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _handleRemoveImage();
              },
            ),
          const SizedBox(height: 12),
          const SizedBox(height: 30), // Added padding for better visibility
        ],
      ),
    );
  }

  Future<CroppedFile?> _cropImage(XFile pickedFile) async {
    return await ImageCropper().cropImage(
      sourcePath: pickedFile.path,
      compressQuality: 90, // High quality compression
      maxWidth: 1024, // Reasonable size for profile pictures
      maxHeight: 1024,
      compressFormat: ImageCompressFormat.jpg,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Adjust Profile Picture',
          toolbarColor: AppTheme.darkBg,
          toolbarWidgetColor: Colors.white,
          backgroundColor: AppTheme.darkBg,
          activeControlsWidgetColor: AppTheme.accentColor,
          initAspectRatio: CropAspectRatioPreset.square, // Start with square
          lockAspectRatio: false, // Allow changing aspect ratio
          hideBottomControls: false,
          cropGridRowCount: 3,
          cropGridColumnCount: 3,
          aspectRatioPresets: [
            CropAspectRatioPreset.square,
            CropAspectRatioPreset.original,
            CropAspectRatioPreset.ratio4x3,
            CropAspectRatioPreset.ratio16x9,
          ],
        ),
        IOSUiSettings(
          title: 'Adjust Profile Picture',
          aspectRatioLockEnabled: false,
          resetAspectRatioEnabled: true,
          aspectRatioPickerButtonHidden: false,
          aspectRatioPresets: [
            CropAspectRatioPreset.square,
            CropAspectRatioPreset.original,
            CropAspectRatioPreset.ratio4x3,
            CropAspectRatioPreset.ratio16x9,
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Center(
              child: Stack(
                children: [
                  Consumer<AuthProvider>(
                    builder: (ctx, auth, _) => GestureDetector(
                      onTap: _pickImage,
                      child: CircleAvatar(
                        radius: 60,
                        backgroundColor: AppTheme.accentColor.withValues(
                          alpha: 0.1,
                        ),
                        backgroundImage: auth.profileImagePath != null
                            ? FileImage(File(auth.profileImagePath!))
                            : null,
                        child: auth.profileImagePath == null
                            ? const Icon(
                                Icons.person,
                                size: 60,
                                color: AppTheme.accentColor,
                              )
                            : null,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: AppTheme.accentColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Consumer<AuthProvider>(
              builder: (ctx, auth, _) => Column(
                children: [
                  if (_isEditing)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: TextField(
                        controller: _nameController,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
                          hintText: 'Enter your name',
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.check, color: Colors.green),
                            onPressed: _handleSave,
                          ),
                        ),
                      ),
                    )
                  else
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          auth.displayName ??
                              auth.email?.split('@')[0] ??
                              'User',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.edit,
                            size: 20,
                            color: Colors.white54,
                          ),
                          onPressed: () => setState(() => _isEditing = true),
                        ),
                      ],
                    ),
                  Text(
                    auth.email ?? '',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            _buildProfileItem(
              context,
              icon: Icons.favorite,
              title: 'Favorites',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CollectionScreen(
                      title: 'Favorites',
                      isFavorites: true,
                    ),
                  ),
                );
              },
            ),
            _buildProfileItem(
              context,
              icon: Icons.download_done_rounded,
              title: 'Downloads',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CollectionScreen(
                      title: 'Downloads',
                      isFavorites: false,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Provider.of<AuthProvider>(context, listen: false).logout();
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent.withValues(alpha: 0.1),
                foregroundColor: Colors.redAccent,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.power_settings_new_rounded),
                  SizedBox(width: 12),
                  Text('Logout'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, color: AppTheme.accentColor),
                const SizedBox(width: 16),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.chevron_right, color: Colors.white24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
