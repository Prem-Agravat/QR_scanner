import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';
import '../models/qr_record.dart';
import '../services/storage_service.dart';

class GenerateScreen extends StatefulWidget {
  const GenerateScreen({super.key});

  @override
  State<GenerateScreen> createState() => _GenerateScreenState();
}

class _GenerateScreenState extends State<GenerateScreen> {
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final GlobalKey _repaintKey = GlobalKey();

  String _qrData = '';
  Color _selectedColor = const Color(0xFF2563EB); // Cobalt primary
  String _selectedEyeStyle = 'square'; // 'square', 'circle'
  String _selectedDataStyle = 'square'; // 'square', 'circle'
  String _selectedLogo = 'none'; // 'none', 'link', 'text', 'wifi', 'email', 'phone'

  final List<Map<String, dynamic>> _colors = [
    {'name': 'Cobalt', 'color': const Color(0xFF2563EB)},
    {'name': 'Teal', 'color': const Color(0xFF0D9488)},
    {'name': 'Violet', 'color': const Color(0xFF8B5CF6)},
    {'name': 'Orange', 'color': const Color(0xFFF97316)},
    {'name': 'Gold', 'color': const Color(0xFFF59E0B)},
    {'name': 'Emerald', 'color': const Color(0xFF10B981)},
    {'name': 'Crimson', 'color': const Color(0xFFEF4444)},
    {'name': 'Midnight', 'color': const Color(0xFF0F172A)},
  ];

  final List<Map<String, dynamic>> _logos = [
    {'type': 'none', 'icon': Icons.block_flipped, 'label': 'None'},
    {'type': 'link', 'icon': Icons.link_rounded, 'label': 'Link'},
    {'type': 'text', 'icon': Icons.text_fields_rounded, 'label': 'Text'},
    {'type': 'wifi', 'icon': Icons.wifi_rounded, 'label': 'Wi-Fi'},
    {'type': 'email', 'icon': Icons.email_rounded, 'label': 'Mail'},
    {'type': 'phone', 'icon': Icons.phone_rounded, 'label': 'Phone'},
  ];

  @override
  void initState() {
    super.initState();
    _textController.addListener(() {
      setState(() {
        _qrData = _textController.text;
      });
    });
    _nameController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  IconData? _getLogoIcon(String type) {
    switch (type) {
      case 'link':
        return Icons.link_rounded;
      case 'text':
        return Icons.text_fields_rounded;
      case 'wifi':
        return Icons.wifi_rounded;
      case 'email':
        return Icons.email_rounded;
      case 'phone':
        return Icons.phone_rounded;
      default:
        return null;
    }
  }

  Future<Uint8List?> _capturePng() async {
    try {
      final boundary = _repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }

  Future<void> _shareQrCode() async {
    if (_qrData.isEmpty) return;
    final pngBytes = await _capturePng();
    if (pngBytes == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to generate image share package.')),
        );
      }
      return;
    }

    try {
      final tempDir = await getTemporaryDirectory();
      final file = await File('${tempDir.path}/qr_hub_share.png').create();
      await file.writeAsBytes(pngBytes);
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text: 'Generated with QR Hub: $_qrData',
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sharing code: $e')),
        );
      }
    }
  }

  Future<void> _exportToDevice() async {
    if (_qrData.isEmpty) return;
    final pngBytes = await _capturePng();
    if (pngBytes == null) return;

    try {
      final directory = await getApplicationDocumentsDirectory();
      final String filename = 'qr_hub_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File('${directory.path}/$filename');
      await file.writeAsBytes(pngBytes);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saved to Documents as: $filename'),
            backgroundColor: _selectedColor,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Share',
              textColor: Colors.white,
              onPressed: () async {
                await SharePlus.instance.share(
                  ShareParams(files: [XFile(file.path)]),
                );
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save file: $e')),
        );
      }
    }
  }

  Future<void> _saveQrCode() async {
    final name = _nameController.text.trim();
    final content = _textController.text.trim();
    if (name.isNotEmpty && content.isNotEmpty) {
      final record = QrRecord(
        id: const Uuid().v4(),
        name: name,
        content: content,
        type: 'generated',
        timestamp: DateTime.now(),
        qrColor: '0x${_selectedColor.toARGB32().toRadixString(16)}',
        qrEyeStyle: _selectedEyeStyle,
        qrDataStyle: _selectedDataStyle,
        logoType: _selectedLogo,
      );
      await StorageService.addRecord(record);
      if (mounted) {
        final theme = Theme.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('QR Code saved successfully to history!'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: theme.colorScheme.secondary,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    const Color(0xFF0B0F19),
                    const Color(0xFF0F172A),
                    const Color(0xFF020617),
                  ]
                : [
                    const Color(0xFFF8FAFC),
                    const Color(0xFFF1F5F9),
                    const Color(0xFFE2E8F0),
                  ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      style: IconButton.styleFrom(
                        backgroundColor: theme.colorScheme.onSurface.withValues(
                          alpha: 0.05,
                        ),
                        foregroundColor: theme.colorScheme.onSurface,
                        padding: const EdgeInsets.all(12),
                      ),
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 20,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Text(
                      'QR Designer',
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(width: 48), // spacer
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 16.0,
                  ),
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // QR Display Area
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.03)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(32),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : Colors.black.withValues(alpha: 0.05),
                              width: 1.0,
                            ),
                          ),
                          child: RepaintBoundary(
                            key: _repaintKey,
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: _qrData.isEmpty
                                    ? []
                                    : [
                                        BoxShadow(
                                          color: _selectedColor.withValues(
                                            alpha: 0.2,
                                          ),
                                          blurRadius: 30,
                                          offset: const Offset(0, 10),
                                        ),
                                      ],
                              ),
                              child: _qrData.isEmpty
                                  ? SizedBox(
                                      width: 200,
                                      height: 200,
                                      child: Icon(
                                        Icons.qr_code_2_rounded,
                                        size: 100,
                                        color: Colors.black.withValues(
                                          alpha: 0.15,
                                        ),
                                      ),
                                    )
                                  : Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        QrImageView(
                                          data: _qrData,
                                          version: QrVersions.auto,
                                          size: 200.0,
                                          gapless: false,
                                          eyeStyle: QrEyeStyle(
                                            eyeShape: _selectedEyeStyle == 'circle'
                                                ? QrEyeShape.circle
                                                : QrEyeShape.square,
                                            color: _selectedColor,
                                          ),
                                          dataModuleStyle: QrDataModuleStyle(
                                            dataModuleShape: _selectedDataStyle == 'circle'
                                                ? QrDataModuleShape.circle
                                                : QrDataModuleShape.square,
                                            color: _selectedColor,
                                          ),
                                          errorStateBuilder: (cxt, err) {
                                            return const Center(
                                              child: Text(
                                                'Rendering error',
                                                style: TextStyle(
                                                  color: Colors.redAccent,
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                        if (_selectedLogo != 'none')
                                          Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withValues(
                                                    alpha: 0.15,
                                                  ),
                                                  blurRadius: 5,
                                                ),
                                              ],
                                            ),
                                            child: Icon(
                                              _getLogoIcon(_selectedLogo),
                                              color: _selectedColor,
                                              size: 22,
                                            ),
                                          ),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 28),

                      // Styling Panel Title
                      Text(
                        'QR Customization Options',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Colors Selection
                      Text(
                        'Choose Theme Color',
                        style: TextStyle(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 42,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          itemCount: _colors.length,
                          itemBuilder: (context, index) {
                            final colItem = _colors[index];
                            final Color col = colItem['color'];
                            final isSel = _selectedColor == col;
                            return Padding(
                              padding: const EdgeInsets.only(right: 10.0),
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    _selectedColor = col;
                                  });
                                },
                                customBorder: const CircleBorder(),
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: col,
                                    shape: BoxShape.circle,
                                    border: isSel
                                        ? Border.all(
                                            color: isDark ? Colors.white : Colors.black,
                                            width: 3,
                                          )
                                        : null,
                                  ),
                                  child: isSel
                                      ? Icon(
                                          Icons.check_rounded,
                                          color: col == Colors.white || col == const Color(0xFFFBBF24)
                                              ? Colors.black
                                              : Colors.white,
                                          size: 20,
                                        )
                                      : null,
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Shapes Selection
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Corner Shapes',
                                  style: TextStyle(
                                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    _buildChoiceChip(
                                      label: 'Square',
                                      selected: _selectedEyeStyle == 'square',
                                      onSelected: () => setState(() => _selectedEyeStyle = 'square'),
                                    ),
                                    const SizedBox(width: 8),
                                    _buildChoiceChip(
                                      label: 'Circle',
                                      selected: _selectedEyeStyle == 'circle',
                                      onSelected: () => setState(() => _selectedEyeStyle = 'circle'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Body Pattern',
                                  style: TextStyle(
                                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    _buildChoiceChip(
                                      label: 'Square',
                                      selected: _selectedDataStyle == 'square',
                                      onSelected: () => setState(() => _selectedDataStyle = 'square'),
                                    ),
                                    const SizedBox(width: 8),
                                    _buildChoiceChip(
                                      label: 'Dots',
                                      selected: _selectedDataStyle == 'circle',
                                      onSelected: () => setState(() => _selectedDataStyle = 'circle'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Logo Selection
                      Text(
                        'Center Icon / Logo Overlay',
                        style: TextStyle(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 48,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          itemCount: _logos.length,
                          itemBuilder: (context, index) {
                            final item = _logos[index];
                            final type = item['type'];
                            final icon = item['icon'];
                            final isSel = _selectedLogo == type;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: ChoiceChip(
                                label: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(icon, size: 16, color: isSel ? Colors.white : theme.colorScheme.onSurface),
                                    const SizedBox(width: 6),
                                    Text(item['label']),
                                  ],
                                ),
                                selected: isSel,
                                selectedColor: _selectedColor,
                                labelStyle: TextStyle(
                                  color: isSel ? Colors.white : theme.colorScheme.onSurface,
                                  fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                                ),
                                showCheckmark: false,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                    color: isSel
                                        ? Colors.transparent
                                        : theme.colorScheme.onSurface.withValues(alpha: 0.1),
                                  ),
                                ),
                                onSelected: (_) {
                                  setState(() {
                                    _selectedLogo = type;
                                  });
                                },
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 28),

                      // Name Text Field
                      Text(
                        'QR Code Label',
                        style: TextStyle(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.7,
                          ),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _nameController,
                        maxLines: 1,
                        style: TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontSize: 16,
                        ),
                        decoration: InputDecoration(
                          hintText: 'e.g. Portfolio Link',
                          hintStyle: TextStyle(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.3,
                            ),
                          ),
                          filled: true,
                          fillColor: theme.colorScheme.onSurface.withValues(
                            alpha: 0.04,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: _selectedColor,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Content Text Field
                      Text(
                        'Enter URL or Plain Text',
                        style: TextStyle(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.7,
                          ),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _textController,
                        maxLines: 3,
                        minLines: 1,
                        style: TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontSize: 16,
                        ),
                        decoration: InputDecoration(
                          hintText: 'https://github.com/profile',
                          hintStyle: TextStyle(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.3,
                            ),
                          ),
                          filled: true,
                          fillColor: theme.colorScheme.onSurface.withValues(
                            alpha: 0.04,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: _selectedColor,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 28),

                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _selectedColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 0,
                                disabledBackgroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.05),
                                disabledForegroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                              ),
                              onPressed: _qrData.isEmpty ? null : _shareQrCode,
                              icon: const Icon(Icons.share_rounded, size: 20),
                              label: const Text('Share Code'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.colorScheme.secondary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 0,
                                disabledBackgroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.05),
                                disabledForegroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                              ),
                              onPressed: (_qrData.isEmpty || _nameController.text.trim().isEmpty) ? null : _saveQrCode,
                              icon: const Icon(Icons.bookmark_add_rounded, size: 20),
                              label: const Text('Save to Hist'),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      if (_qrData.isNotEmpty) ...[
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.05),
                            foregroundColor: theme.colorScheme.onSurface,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                              ),
                            ),
                            elevation: 0,
                          ),
                          onPressed: _exportToDevice,
                          icon: const Icon(Icons.download_rounded, size: 20),
                          label: const Text('Download PNG'),
                        ),
                        const SizedBox(height: 12),
                      ],

                      if (_qrData.isNotEmpty || _nameController.text.isNotEmpty) ...[
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.redAccent,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: () {
                            setState(() {
                              _textController.clear();
                              _nameController.clear();
                              _selectedLogo = 'none';
                            });
                          },
                          icon: const Icon(Icons.clear_all_rounded, size: 22),
                          label: const Text('Reset All Fields'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChoiceChip({
    required String label,
    required bool selected,
    required VoidCallback onSelected,
  }) {
    final theme = Theme.of(context);
    return Expanded(
      child: InkWell(
        onTap: onSelected,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? _selectedColor : theme.colorScheme.onSurface.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? Colors.transparent : theme.colorScheme.onSurface.withValues(alpha: 0.1),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : theme.colorScheme.onSurface,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
