import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  void _showResultBottomSheet(String value) {
    final isUrl = Uri.tryParse(value)?.hasAbsolutePath ?? false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1E293B), // Slate 800
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(32),
              topRight: Radius.circular(32),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top drag handle
                Center(
                  child: Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Result Title
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isUrl ? Icons.link_rounded : Icons.text_snippet_rounded,
                        color: const Color(0xFF818CF8),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      isUrl ? 'Scanned Link' : 'Scanned Text',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Scanned Value Container
                Container(
                  padding: const EdgeInsets.all(16),
                  constraints: const BoxConstraints(maxHeight: 180),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.05),
                    ),
                  ),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: SelectableText(
                      value,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 15,
                        height: 1.4,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Action Buttons
                Row(
                  children: [
                    // Copy button
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.05),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: Colors.white.withOpacity(0.1)),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: value));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Copied to clipboard'),
                              behavior: SnackBarBehavior.floating,
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        icon: const Icon(Icons.copy_rounded, size: 20),
                        label: const Text('Copy'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    // Share button
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.05),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: Colors.white.withOpacity(0.1)),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () {
                          Share.share(value);
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
                    backgroundColor: const Color(0xFF10B981), // Emerald 500
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
                
                // URL launcher button if URL
                if (isUrl) ...[
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1), // Indigo 500
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () async {
                      final url = Uri.parse(value);
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url, mode: LaunchMode.externalApplication);
                      } else {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Could not open link'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.open_in_new_rounded, size: 20),
                    label: const Text('Open Link'),
                  ),
                  const SizedBox(height: 12),
                ],
                
                // Rescan button
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white54,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Scan Again'),
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
    final TextEditingController nameController = TextEditingController(
      text: 'Scanned Code - ${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}',
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E293B), // Slate 800
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: Colors.white.withOpacity(0.1)),
          ),
          title: const Text(
            'Save QR Code',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Give this QR code a specific name:',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Enter specific name...',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                  filled: true,
                  fillColor: Colors.black.withOpacity(0.2),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF10B981), width: 1.5),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981), // Emerald 500
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Saved to history successfully!'),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: Color(0xFF10B981),
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
    final double scanWindowWidth = MediaQuery.of(context).size.width * 0.7;
    final double scanWindowHeight = scanWindowWidth;
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    
    final Rect scanWindow = Rect.fromLTWH(
      (screenWidth - scanWindowWidth) / 2,
      (screenHeight - scanWindowHeight) / 2 - 30,
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
                      const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 48),
                      const SizedBox(height: 16),
                      const Text(
                        'Camera Error',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        error.errorCode == MobileScannerErrorCode.controllerUninitialized
                            ? 'The scanner controller is initializing...'
                            : 'Please verify camera permissions in settings.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white60, fontSize: 14),
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
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Back Button
                      IconButton(
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black.withOpacity(0.5),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.all(12),
                        ),
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Text(
                        'Scanner',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                      // Place holder to balance title alignment
                      const SizedBox(width: 48),
                    ],
                  ),
                  const Spacer(),
                  // Camera control buttons
                  Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
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
                                  return const Icon(Icons.flash_on_rounded, color: Color(0xFFFBBF24));
                                case TorchState.off:
                                default:
                                  return const Icon(Icons.flash_off_rounded, color: Colors.white54);
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
                                  return const Icon(Icons.camera_front_rounded, color: Color(0xFF818CF8));
                                case CameraFacing.back:
                                default:
                                  return const Icon(Icons.camera_rear_rounded, color: Colors.white54);
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

// Custom Painter for scanner cutout
class ScannerOverlay extends CustomPainter {
  const ScannerOverlay({
    required this.scanWindow,
    this.borderRadius = 24.0,
  });

  final Rect scanWindow;
  final double borderRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPath = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final cutoutPath = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          scanWindow,
          Radius.circular(borderRadius),
        ),
      );

    final backgroundPaint = Paint()
      ..color = Colors.black.withOpacity(0.65)
      ..style = PaintingStyle.fill;

    final backgroundPathWithCutout = Path.combine(
      PathOperation.difference,
      backgroundPath,
      cutoutPath,
    );

    canvas.drawPath(backgroundPathWithCutout, backgroundPaint);

    // Draw active-looking border corners
    final borderPaint = Paint()
      ..color = const Color(0xFF6366F1) // Indigo 500
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
                  color: const Color(0xFF6366F1).withOpacity(0.8),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
              gradient: const LinearGradient(
                colors: [
                  Colors.transparent,
                  Color(0xFF6366F1),
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
