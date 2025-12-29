import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../providers/subscription_provider.dart';
import '../providers/auth_provider.dart';
import '../services/custom_wallpaper_service.dart';
import '../utils/theme.dart';
import '../widgets/premium_paywall_dialog.dart';

class CustomCreatorScreen extends StatefulWidget {
  const CustomCreatorScreen({super.key});

  @override
  State<CustomCreatorScreen> createState() => _CustomCreatorScreenState();
}

class _CustomCreatorScreenState extends State<CustomCreatorScreen> {
  final GlobalKey _canvasKey = GlobalKey();
  final CustomWallpaperService _wallpaperService = CustomWallpaperService();
  final ImagePicker _picker = ImagePicker();

  File? _backgroundImage;
  Color _backgroundColor = const Color(0xFF1a1a2e);
  List<TextElement> _textElements = [];
  List<ShapeElement> _shapes = [];

  double _brightness = 0;
  double _contrast = 0;
  double _saturation = 0;
  double _blur = 0;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _pickBackgroundImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
      );
      if (pickedFile != null) {
        setState(() {
          _backgroundImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
      }
    }
  }

  void _addText() {
    showDialog(
      context: context,
      builder: (ctx) => _TextDialog(
        onAdd: (text, color, fontSize) {
          setState(() {
            _textElements.add(
              TextElement(
                text: text,
                color: color,
                fontSize: fontSize,
                x: 50,
                y: 100 + (_textElements.length * 50.0),
              ),
            );
          });
        },
      ),
    );
  }

  void _addShape(String shapeType) {
    setState(() {
      _shapes.add(
        ShapeElement(
          type: shapeType,
          color: AppTheme.accentColor,
          x: 100,
          y: 200 + (_shapes.length * 80.0),
          width: 100,
          height: shapeType == 'circle' ? 100 : 80,
        ),
      );
    });
  }

  void _changeBackgroundColor() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        title: const Text('Pick Background Color'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: _backgroundColor,
            onColorChanged: (color) {
              setState(() => _backgroundColor = color);
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveWallpaper() async {
    final subscription = Provider.of<SubscriptionProvider>(
      context,
      listen: false,
    );

    if (!subscription.isPremium) {
      FocusScope.of(context).unfocus(); // Dismiss any open keyboards or focus
      PremiumPaywallDialog.show(
        context,
        featureName: 'Custom Wallpaper Creator',
        featureDescription:
            'Upgrade to premium to save your custom wallpapers and access advanced editing tools.',
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Capture the canvas as an image
      final boundary =
          _canvasKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();
      final base64Image = base64Encode(bytes);

      final auth = Provider.of<AuthProvider>(context, listen: false);
      final metadata = {
        'filters': {
          'brightness': _brightness,
          'contrast': _contrast,
          'saturation': _saturation,
          'blur': _blur,
        },
        'textElements': _textElements.map((e) => e.toJson()).toList(),
        'shapes': _shapes.map((e) => e.toJson()).toList(),
      };

      await _wallpaperService.saveCustomWallpaper(
        auth.email ?? '',
        base64Image,
        metadata,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Wallpaper saved successfully!'),
            backgroundColor: Colors.green,
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
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Custom Creator'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.save_rounded),
            onPressed: _isSaving ? null : _saveWallpaper,
          ),
        ],
      ),
      body: Column(
        children: [
          // Canvas
          Expanded(
            flex: 3,
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: RepaintBoundary(
                  key: _canvasKey,
                  child: Container(
                    color: _backgroundColor,
                    child: Stack(
                      children: [
                        // Background Image
                        if (_backgroundImage != null)
                          Positioned.fill(
                            child: Image.file(
                              _backgroundImage!,
                              fit: BoxFit.cover,
                            ),
                          ),

                        // Shapes
                        ..._shapes.map(
                          (shape) => Positioned(
                            left: shape.x,
                            top: shape.y,
                            child: CustomPaint(
                              size: Size(shape.width, shape.height),
                              painter: ShapePainter(shape),
                            ),
                          ),
                        ),

                        // Text Elements
                        ..._textElements.map(
                          (textEl) => Positioned(
                            left: textEl.x,
                            top: textEl.y,
                            child: Text(
                              textEl.text,
                              style: TextStyle(
                                color: textEl.color,
                                fontSize: textEl.fontSize,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Tools
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.cardBg,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tools',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Action Buttons
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildToolButton(
                          Icons.image_rounded,
                          'Background',
                          _pickBackgroundImage,
                        ),
                        _buildToolButton(
                          Icons.palette_rounded,
                          'Color',
                          _changeBackgroundColor,
                        ),
                        _buildToolButton(
                          Icons.text_fields_rounded,
                          'Add Text',
                          _addText,
                        ),
                        _buildToolButton(
                          Icons.crop_square_rounded,
                          'Rectangle',
                          () => _addShape('rectangle'),
                        ),
                        _buildToolButton(
                          Icons.circle_outlined,
                          'Circle',
                          () => _addShape('circle'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Filters
                    const Text(
                      'Filters',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildSlider('Brightness', _brightness, (val) {
                      setState(() => _brightness = val);
                    }),
                    _buildSlider('Contrast', _contrast, (val) {
                      setState(() => _contrast = val);
                    }),
                    _buildSlider('Saturation', _saturation, (val) {
                      setState(() => _saturation = val);
                    }),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolButton(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.darkBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.accentColor.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: AppTheme.accentColor),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildSlider(
    String label,
    double value,
    ValueChanged<double> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.7)),
        ),
        Slider(
          value: value,
          min: -1,
          max: 1,
          activeColor: AppTheme.accentColor,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

// Text Dialog
class _TextDialog extends StatefulWidget {
  final Function(String, Color, double) onAdd;

  const _TextDialog({required this.onAdd});

  @override
  State<_TextDialog> createState() => _TextDialogState();
}

class _TextDialogState extends State<_TextDialog> {
  final TextEditingController _controller = TextEditingController();
  Color _color = Colors.white;
  double _fontSize = 24;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.cardBg,
      title: const Text('Add Text'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            decoration: const InputDecoration(
              hintText: 'Enter text',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('Size: '),
              Expanded(
                child: Slider(
                  value: _fontSize,
                  min: 12,
                  max: 72,
                  onChanged: (val) => setState(() => _fontSize = val),
                ),
              ),
              Text(_fontSize.toInt().toString()),
            ],
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: AppTheme.cardBg,
                  title: const Text('Pick Color'),
                  content: SingleChildScrollView(
                    child: ColorPicker(
                      pickerColor: _color,
                      onColorChanged: (color) => setState(() => _color = color),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Done'),
                    ),
                  ],
                ),
              );
            },
            child: const Text('Choose Color'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            if (_controller.text.isNotEmpty) {
              widget.onAdd(_controller.text, _color, _fontSize);
              Navigator.pop(context);
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}

// Data Classes
class TextElement {
  final String text;
  final Color color;
  final double fontSize;
  final double x;
  final double y;

  TextElement({
    required this.text,
    required this.color,
    required this.fontSize,
    required this.x,
    required this.y,
  });

  Map<String, dynamic> toJson() => {
    'text': text,
    'color': color.value.toString(),
    'fontSize': fontSize,
    'x': x,
    'y': y,
  };
}

class ShapeElement {
  final String type;
  final Color color;
  final double x;
  final double y;
  final double width;
  final double height;

  ShapeElement({
    required this.type,
    required this.color,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  Map<String, dynamic> toJson() => {
    'type': type,
    'color': color.value.toString(),
    'x': x,
    'y': y,
    'width': width,
    'height': height,
  };
}

// Shape Painter
class ShapePainter extends CustomPainter {
  final ShapeElement shape;

  ShapePainter(this.shape);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = shape.color
      ..style = PaintingStyle.fill;

    if (shape.type == 'rectangle') {
      canvas.drawRect(Rect.fromLTWH(0, 0, shape.width, shape.height), paint);
    } else if (shape.type == 'circle') {
      canvas.drawCircle(
        Offset(shape.width / 2, shape.height / 2),
        shape.width / 2,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
