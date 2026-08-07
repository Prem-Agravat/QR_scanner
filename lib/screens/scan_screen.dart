import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import '../models/qr_record.dart';
import '../services/storage_service.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  late MobileScannerController controller;
  bool isSheetOpen = false;

  @override
  void initState() {
    super.initState();
    controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _handleDetect(BarcodeCapture capture) {
    if (isSheetOpen) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final String? rawValue = barcodes.first.rawValue;
      if (rawValue != null) {
        setState(() {
          isSheetOpen = true;
        });
        controller.stop();
        _showResultBottomSheet(rawValue);
      }
    }
  }

  Future<void> _scanFromGallery() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      final BarcodeCapture? capture = await controller.analyzeImage(image.path);
      if (capture == null || capture.barcodes.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No QR code found in that image. Try another one.'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      } else {
        final String? rawValue = capture.barcodes.first.rawValue;
        if (rawValue != null) {
          setState(() {
            isSheetOpen = true;
          });
          controller.stop();
          _showResultBottomSheet(rawValue);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to read image: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  // Parser helper for QR codes
  _ParsedContent _parseContent(String value) {
    final clean = value.trim();
    
    // 1. Wi-Fi
    if (clean.toUpperCase().startsWith('WIFI:')) {
      final details = <String, String>{};
      final parts = clean.substring(5).split(';');
      for (final part in parts) {
        if (part.startsWith('S:')) details['SSID'] = part.substring(2);
        if (part.startsWith('P:')) details['Password'] = part.substring(2);
        if (part.startsWith('T:')) details['Security'] = part.substring(2);
      }
      return _ParsedContent(
        type: 'wifi',
        title: 'Wi-Fi Network',
        icon: Icons.wifi_rounded,
        details: details,
        primaryActionLabel: 'Copy Password',
        primaryAction: () {
          final pass = details['Password'] ?? '';
          Clipboard.setData(ClipboardData(text: pass));
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Wi-Fi Password copied to clipboard'), behavior: SnackBarBehavior.floating),
          );
        },
      );
    }

    // 2. Email
    if (clean.toLowerCase().startsWith('mailto:')) {
      final uri = Uri.parse(clean);
      final email = uri.path;
      final details = {'Email': email};
      final subject = uri.queryParameters['subject'];
      if (subject != null) details['Subject'] = subject;

      return _ParsedContent(
        type: 'email',
        title: 'Email Address',
        icon: Icons.email_rounded,
        details: details,
        primaryActionLabel: 'Send Email',
        primaryAction: () async {
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri);
          }
        },
      );
    }

    // 3. Phone Call
    if (clean.toLowerCase().startsWith('tel:')) {
      final number = clean.substring(4);
      return _ParsedContent(
        type: 'phone',
        title: 'Phone Number',
        icon: Icons.phone_rounded,
        details: {'Number': number},
        primaryActionLabel: 'Call Number',
        primaryAction: () async {
          final uri = Uri.parse(clean);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri);
          }
        },
      );
    }

    // 4. SMS
    if (clean.toLowerCase().startsWith('sms:')) {
      final details = <String, String>{};
      final uri = Uri.parse(clean);
      details['Number'] = uri.path;
      final body = uri.queryParameters['body'];
      if (body != null) details['Message'] = body;

      return _ParsedContent(
        type: 'sms',
        title: 'SMS Message',
        icon: Icons.sms_rounded,
        details: details,
        primaryActionLabel: 'Send SMS',
        primaryAction: () async {
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri);
          }
        },
      );
    }

    // 5. Geographic Location
    if (clean.toLowerCase().startsWith('geo:')) {
      final coords = clean.substring(4).split('?')[0];
      return _ParsedContent(
        type: 'geo',
        title: 'Location Maps',
        icon: Icons.map_rounded,
        details: {'Coordinates': coords},
        primaryActionLabel: 'Open in Maps',
        primaryAction: () async {
          final mapsUrl = Uri.parse('https://www.google.com/maps/search/?api=1&query=$coords');
          if (await canLaunchUrl(mapsUrl)) {
            await launchUrl(mapsUrl, mode: LaunchMode.externalApplication);
          }
        },
      );
    }

    // 6. vCard Contact
    if (clean.toUpperCase().contains('BEGIN:VCARD')) {
      final details = <String, String>{};
      final lines = clean.split('\n');
      for (final line in lines) {
        final upper = line.toUpperCase();
        if (upper.startsWith('FN:')) details['Name'] = line.substring(3).trim();
        if (upper.startsWith('TEL:')) details['Phone'] = line.substring(4).trim();
        if (upper.startsWith('EMAIL:')) details['Email'] = line.substring(6).trim();
        if (upper.startsWith('ORG:')) details['Company'] = line.substring(4).trim();
      }
      return _ParsedContent(
        type: 'vcard',
        title: 'vCard Contact Card',
        icon: Icons.contact_phone_rounded,
        details: details,
        primaryActionLabel: 'Copy Contact Details',
        primaryAction: () {
          final info = details.entries.map((e) => '${e.key}: ${e.value}').join('\n');
          Clipboard.setData(ClipboardData(text: info));
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Contact info copied to clipboard'), behavior: SnackBarBehavior.floating),
          );
        },
      );
    }

    // 7. URL
    final isUrl = Uri.tryParse(clean)?.hasAbsolutePath ?? false;
    if (isUrl) {
      return _ParsedContent(
        type: 'url',
        title: 'Web Link',
        icon: Icons.link_rounded,
        details: {'URL': clean},
        primaryActionLabel: 'Open in Browser',
        primaryAction: () async {
          final uri = Uri.parse(clean);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        },
      );
    }

    // 8. Plain Text (Default)
    return _ParsedContent(
      type: 'text',
      title: 'Scanned Text',
      icon: Icons.text_snippet_rounded,
      details: {'Content': clean},
      primaryActionLabel: 'Copy Text',
      primaryAction: () {
        Clipboard.setData(ClipboardData(text: clean));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Copied to clipboard'), behavior: SnackBarBehavior.floating),
        );
      },
    );
  }

  void _showResultBottomSheet(String value) {
    final parsed = _parseContent(value);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(32),
              topRight: Radius.circular(32),
            ),
            border: Border(
              top: BorderSide(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
                width: 1.0,
              ),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Title Section
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(
                          alpha: 0.15,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        parsed.icon,
                        color: theme.colorScheme.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      parsed.title,
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Scanned Details Cards
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.black.withValues(alpha: 0.2)
                        : Colors.black.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.05,
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: parsed.details.entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${entry.key}: ',
                              style: TextStyle(
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            Expanded(
                              child: SelectableText(
                                entry.value,
                                style: TextStyle(
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.9),
                                  fontSize: 14,
                                  fontFamily: entry.key == 'URL' || entry.key == 'Coordinates' ? 'monospace' : null,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 24),

                // Primary Action Button (e.g. Open Link / Send Email)
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  onPressed: parsed.primaryAction,
                  icon: const Icon(Icons.flash_on_rounded, size: 20),
                  label: Text(parsed.primaryActionLabel),
                ),
                const SizedBox(height: 12),

                // Share / Save / Copy actions row
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.onSurface
                              .withValues(alpha: 0.05),
                          foregroundColor: theme.colorScheme.onSurface,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.1,
                              ),
                            ),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: value));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Raw content copied to clipboard'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        icon: const Icon(Icons.copy_rounded, size: 20),
                        label: const Text('Copy Raw'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.onSurface
                              .withValues(alpha: 0.05),
                          foregroundColor: theme.colorScheme.onSurface,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.1,
                              ),
                            ),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () {
                          SharePlus.instance.share(ShareParams(text: value));
                        },
                        icon: const Icon(Icons.share_rounded, size: 20),
                        label: const Text('Share'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Save to History button
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.secondary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () {
                    _showSaveDialog(value);
                  },
                  icon: const Icon(Icons.bookmark_add_rounded, size: 20),
                  label: const Text('Save to History'),
                ),
                const SizedBox(height: 12),

                // Rescan button
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.onSurface.withValues(
                      alpha: 0.6,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Rescan Camera'),
                ),
              ],
            ),
          ),
        );
      },
    ).then((_) {
      setState(() {
        isSheetOpen = false;
      });
      controller.start();
    });
  }

  void _showSaveDialog(String value) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final TextEditingController nameController = TextEditingController(
      text: 'Scanned Code - ${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}',
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: theme.colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
            ),
          ),
          title: Text(
            'Save QR Code',
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Give this QR code a name:',
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameController,
                style: TextStyle(color: theme.colorScheme.onSurface),
                decoration: InputDecoration(
                  hintText: 'Enter name...',
                  hintStyle: TextStyle(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
                  filled: true,
                  fillColor: isDark
                      ? Colors.black.withValues(alpha: 0.2)
                      : Colors.black.withValues(alpha: 0.04),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: theme.colorScheme.secondary,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.secondary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isNotEmpty) {
                  final record = QrRecord(
                    id: const Uuid().v4(),
                    name: name,
                    content: value,
                    type: 'scanned',
                    timestamp: DateTime.now(),
                  );
                  await StorageService.addRecord(record);
                  if (context.mounted) {
                    Navigator.pop(context); // Close dialog
                    Navigator.pop(context); // Close bottom sheet
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Saved to history!'),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: theme.colorScheme.secondary,
                      ),
                    );
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final double scanWindowWidth = MediaQuery.of(context).size.width * 0.72;
    final double scanWindowHeight = scanWindowWidth;
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;

    final Rect scanWindow = Rect.fromLTWH(
      (screenWidth - scanWindowWidth) / 2,
      (screenHeight - scanWindowHeight) / 2 - 40,
      scanWindowWidth,
      scanWindowHeight,
    );

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Scanner camera view
          MobileScanner(
            controller: controller,
            scanWindow: scanWindow,
            onDetect: _handleDetect,
            errorBuilder: (context, error) {
              return Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        color: Colors.redAccent,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Camera Error',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        error.errorCode == MobileScannerErrorCode.controllerUninitialized
                            ? 'Scanner controller is initializing...'
                            : 'Camera permissions are required to scan QR codes.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // Transparent overlay with cutout
          CustomPaint(
            size: Size(screenWidth, screenHeight),
            painter: ScannerOverlay(scanWindow: scanWindow),
          ),

          // Laser sweeping animated line
          ScanningLine(scanWindow: scanWindow),

          // Header / Controls Overlay
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Back Button
                      IconButton(
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black.withValues(alpha: 0.5),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.all(12),
                        ),
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 20,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Text(
                        'Smart Scanner',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                      // Photo library gallery button
                      IconButton(
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black.withValues(alpha: 0.5),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.all(12),
                        ),
                        icon: const Icon(
                          Icons.photo_library_rounded,
                          size: 20,
                        ),
                        onPressed: _scanFromGallery,
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Camera control buttons
                  Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Flashlight Toggle
                        IconButton(
                          icon: ValueListenableBuilder<MobileScannerState>(
                            valueListenable: controller,
                            builder: (context, state, child) {
                              switch (state.torchState) {
                                case TorchState.on:
                                  return const Icon(
                                    Icons.flash_on_rounded,
                                    color: Color(0xFFFBBF24),
                                  );
                                case TorchState.off:
                                default:
                                  return const Icon(
                                    Icons.flash_off_rounded,
                                    color: Colors.white54,
                                  );
                              }
                            },
                          ),
                          onPressed: () => controller.toggleTorch(),
                        ),
                        const SizedBox(width: 24),
                        // Camera Switch Toggle
                        IconButton(
                          icon: ValueListenableBuilder<MobileScannerState>(
                            valueListenable: controller,
                            builder: (context, state, child) {
                              switch (state.cameraDirection) {
                                case CameraFacing.front:
                                  return const Icon(
                                    Icons.camera_front_rounded,
                                    color: Color(0xFF818CF8),
                                  );
                                case CameraFacing.back:
                                default:
                                  return const Icon(
                                    Icons.camera_rear_rounded,
                                    color: Colors.white54,
                                  );
                              }
                            },
                          ),
                          onPressed: () => controller.switchCamera(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Custom parser class for QR contents
class _ParsedContent {
  final String type;
  final String title;
  final IconData icon;
  final Map<String, String> details;
  final String primaryActionLabel;
  final VoidCallback? primaryAction;

  _ParsedContent({
    required this.type,
    required this.title,
    required this.icon,
    required this.details,
    required this.primaryActionLabel,
    this.primaryAction,
  });
}

// Custom Painter for scanner cutout
class ScannerOverlay extends CustomPainter {
  const ScannerOverlay({required this.scanWindow, this.borderRadius = 24.0});

  final Rect scanWindow;
  final double borderRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPath = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final cutoutPath = Path()
      ..addRRect(
        RRect.fromRectAndRadius(scanWindow, Radius.circular(borderRadius)),
      );

    final backgroundPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.65)
      ..style = PaintingStyle.fill;

    final backgroundPathWithCutout = Path.combine(
      PathOperation.difference,
      backgroundPath,
      cutoutPath,
    );

    canvas.drawPath(backgroundPathWithCutout, backgroundPaint);

    // Draw active glowing neon border corners
    final borderPaint = Paint()
      ..color = const Color(0xFF2563EB) // Cobalt Blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;

    final borderPath = Path();
    const double length = 24.0;

    // Top Left Corner
    borderPath.moveTo(scanWindow.left, scanWindow.top + length);
    borderPath.lineTo(scanWindow.left, scanWindow.top);
    borderPath.lineTo(scanWindow.left + length, scanWindow.top);

    // Top Right Corner
    borderPath.moveTo(scanWindow.right - length, scanWindow.top);
    borderPath.lineTo(scanWindow.right, scanWindow.top);
    borderPath.lineTo(scanWindow.right, scanWindow.top + length);

    // Bottom Left Corner
    borderPath.moveTo(scanWindow.left, scanWindow.bottom - length);
    borderPath.lineTo(scanWindow.left, scanWindow.bottom);
    borderPath.lineTo(scanWindow.left + length, scanWindow.bottom);

    // Bottom Right Corner
    borderPath.moveTo(scanWindow.right - length, scanWindow.bottom);
    borderPath.lineTo(scanWindow.right, scanWindow.bottom);
    borderPath.lineTo(scanWindow.right, scanWindow.bottom - length);

    canvas.drawPath(borderPath, borderPaint);
  }

  @override
  bool shouldRepaint(covariant ScannerOverlay oldDelegate) {
    return oldDelegate.scanWindow != scanWindow || oldDelegate.borderRadius != borderRadius;
  }
}

// Laser sweeping line widget
class ScanningLine extends StatefulWidget {
  final Rect scanWindow;
  const ScanningLine({super.key, required this.scanWindow});

  @override
  State<ScanningLine> createState() => _ScanningLineState();
}

class _ScanningLineState extends State<ScanningLine> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final position = widget.scanWindow.top + (widget.scanWindow.height * _controller.value);
        return Positioned(
          left: widget.scanWindow.left + 8,
          top: position,
          width: widget.scanWindow.width - 16,
          child: Container(
            height: 3,
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.8),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
              gradient: const LinearGradient(
                colors: [
                  Colors.transparent,
                  Color(0xFF2563EB),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
