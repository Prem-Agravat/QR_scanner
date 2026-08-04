import 'package:flutter/material.dart';
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
  String _qrData = '';

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
      );
      await StorageService.addRecord(record);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('QR Code saved successfully!'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Color(0xFF10B981),
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
                    const Color(0xFF0F172A), // Slate 900
                    const Color(0xFF881337), // Rose 950
                    const Color(0xFF020617), // Slate 955
                  ]
                : [
                    const Color(0xFFFEE2E2), // Light Red/Rose
                    const Color(0xFFFFE4E6),
                    const Color(0xFFF8FAFC),
                  ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      style: IconButton.styleFrom(
                        backgroundColor: theme.colorScheme.onBackground.withOpacity(0.05),
                        foregroundColor: theme.colorScheme.onBackground,
                        padding: const EdgeInsets.all(12),
                      ),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Text(
                      'Generator',
                      style: TextStyle(
                        color: theme.colorScheme.onBackground,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(width: 48), // Spacer to center title
                  ],
                ),
              ),
              
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 20),
                      
                      // QR Display Area
                      Center(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withOpacity(0.03) : Colors.white,
                            borderRadius: BorderRadius.circular(32),
                            border: Border.all(
                              color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05),
                              width: 1.0,
                            ),
                            boxShadow: isDark
                                ? []
                                : [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.04),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8),
                                    )
                                  ],
                          ),
                          child: _qrData.isEmpty
                              ? Container(
                                  width: 200,
                                  height: 200,
                                  decoration: BoxDecoration(
                                    color: isDark ? Colors.black.withOpacity(0.2) : Colors.black.withOpacity(0.03),
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.qr_code_2_rounded,
                                        size: 72,
                                        color: theme.colorScheme.onBackground.withOpacity(0.15),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'Waiting for text...',
                                        style: TextStyle(
                                          color: theme.colorScheme.onBackground.withOpacity(0.3),
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(24),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFFEC4899).withOpacity(0.25),
                                        blurRadius: 30,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: QrImageView(
                                    data: _qrData,
                                    version: QrVersions.auto,
                                    size: 200.0,
                                    gapless: false,
                                    errorStateBuilder: (cxt, err) {
                                      return const Center(
                                        child: Text(
                                          'Error generating QR code',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: Colors.redAccent,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                        ),
                      ),
                      
                      const SizedBox(height: 40),
                      
                      // Name Label
                      Text(
                        'QR Code Name / Label',
                        style: TextStyle(
                          color: theme.colorScheme.onBackground.withOpacity(0.7),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Name Text Field
                      TextField(
                        controller: _nameController,
                        maxLines: 1,
                        style: TextStyle(
                          color: theme.colorScheme.onBackground,
                          fontSize: 16,
                        ),
                        decoration: InputDecoration(
                          hintText: 'e.g. My Website QR',
                          hintStyle: TextStyle(
                            color: theme.colorScheme.onBackground.withOpacity(0.2),
                          ),
                          filled: true,
                          fillColor: theme.colorScheme.onBackground.withOpacity(0.04),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide(
                              color: theme.colorScheme.secondary,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Input Label
                      Text(
                        'Enter URL or Plain Text',
                        style: TextStyle(
                          color: theme.colorScheme.onBackground.withOpacity(0.7),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // Text Field
                      TextField(
                        controller: _textController,
                        maxLines: 4,
                        minLines: 1,
                        style: TextStyle(
                          color: theme.colorScheme.onBackground,
                          fontSize: 16,
                        ),
                        decoration: InputDecoration(
                          hintText: 'https://example.com',
                          hintStyle: TextStyle(
                            color: theme.colorScheme.onBackground.withOpacity(0.2),
                          ),
                          filled: true,
                          fillColor: theme.colorScheme.onBackground.withOpacity(0.04),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide(
                              color: theme.colorScheme.secondary,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Quick Actions
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.colorScheme.secondary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 0,
                                disabledBackgroundColor: theme.colorScheme.onBackground.withOpacity(0.05),
                                disabledForegroundColor: theme.colorScheme.onBackground.withOpacity(0.2),
                              ),
                              onPressed: _qrData.isEmpty
                                  ? null
                                  : () {
                                      SharePlus.instance.share(ShareParams(text: _qrData));
                                    },
                              icon: const Icon(Icons.share_rounded, size: 20),
                              label: const Text('Share'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF10B981), // Emerald 500
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 0,
                                disabledBackgroundColor: theme.colorScheme.onBackground.withOpacity(0.05),
                                disabledForegroundColor: theme.colorScheme.onBackground.withOpacity(0.2),
                              ),
                              onPressed: (_qrData.isEmpty || _nameController.text.trim().isEmpty)
                                  ? null
                                  : _saveQrCode,
                              icon: const Icon(Icons.bookmark_add_rounded, size: 20),
                              label: const Text('Save'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      
                      if (_qrData.isNotEmpty || _nameController.text.isNotEmpty) ...[
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.onBackground.withOpacity(0.05),
                            foregroundColor: theme.colorScheme.onBackground,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(color: theme.colorScheme.onBackground.withOpacity(0.1)),
                            ),
                            elevation: 0,
                          ),
                          onPressed: () {
                            setState(() {
                              _textController.clear();
                              _nameController.clear();
                            });
                          },
                          icon: const Icon(Icons.clear_all_rounded, size: 22),
                          label: const Text('Clear All'),
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
}
