import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/qr_record.dart';
import '../services/storage_service.dart';

class QrDetailsSheet extends StatefulWidget {
  final QrRecord record;
  final VoidCallback onUpdate;

  const QrDetailsSheet({
    super.key,
    required this.record,
    required this.onUpdate,
  });

  static void show(BuildContext context, QrRecord record, VoidCallback onUpdate) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) => QrDetailsSheet(record: record, onUpdate: onUpdate),
    );
  }

  @override
  State<QrDetailsSheet> createState() => _QrDetailsSheetState();
}

class _QrDetailsSheetState extends State<QrDetailsSheet> {
  late QrRecord _record;

  @override
  void initState() {
    super.initState();
    _record = widget.record;
  }

  String _formatDate(DateTime dt) {
    final year = dt.year;
    final month = dt.month.toString().padLeft(2, '0');
    final day = dt.day.toString().padLeft(2, '0');
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$year-$month-$day $hour:$minute';
  }

  Future<void> _toggleFavorite() async {
    final updated = _record.copyWith(isFavorite: !_record.isFavorite);
    // Load records, replace the item, and save
    final records = await StorageService.loadRecords();
    final index = records.indexWhere((r) => r.id == _record.id);
    if (index != -1) {
      records[index] = updated;
      await StorageService.saveRecords(records);
      setState(() {
        _record = updated;
      });
      widget.onUpdate();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isUrl = Uri.tryParse(_record.content)?.hasAbsolutePath ?? false;
    final isScanned = _record.type == 'scanned';

    // Extract color override if custom
    Color qrColor = isScanned ? theme.colorScheme.primary : theme.colorScheme.secondary;
    if (_record.qrColor != null) {
      try {
        qrColor = Color(int.parse(_record.qrColor!));
      } catch (_) {}
    }

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
            // Top drag handle
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

            // Header (Title, Date & Favorite toggle)
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: qrColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isScanned ? Icons.filter_center_focus_rounded : Icons.qr_code_rounded,
                    color: qrColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _record.name,
                        style: TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(_record.timestamp),
                        style: TextStyle(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    _record.isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: _record.isFavorite ? const Color(0xFFFBBF24) : theme.colorScheme.onSurface.withValues(alpha: 0.4),
                    size: 28,
                  ),
                  onPressed: _toggleFavorite,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // QR Code Renderer
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: QrImageView(
                  data: _record.content,
                  version: QrVersions.auto,
                  size: 160,
                  gapless: false,
                  eyeStyle: QrEyeStyle(
                    eyeShape: _record.qrEyeStyle == 'circle' ? QrEyeShape.circle : QrEyeShape.square,
                    color: _record.qrColor != null ? Color(int.parse(_record.qrColor!)) : Colors.black,
                  ),
                  dataModuleStyle: QrDataModuleStyle(
                    dataModuleShape: _record.qrDataStyle == 'circle' ? QrDataModuleShape.circle : QrDataModuleShape.square,
                    color: _record.qrColor != null ? Color(int.parse(_record.qrColor!)) : Colors.black,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Content Value Box
            Container(
              padding: const EdgeInsets.all(16),
              constraints: const BoxConstraints(maxHeight: 120),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.2)
                    : Colors.black.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
                ),
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: SelectableText(
                  _record.content,
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                    fontSize: 14,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Actions row
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
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
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _record.content));
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
                Expanded(
                  child: ElevatedButton.icon(
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
                    onPressed: () {
                      SharePlus.instance.share(ShareParams(text: _record.content));
                    },
                    icon: const Icon(Icons.share_rounded, size: 20),
                    label: const Text('Share'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (isUrl) ...[
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
                onPressed: () async {
                  final url = Uri.parse(_record.content);
                  if (await canLaunchUrl(url)) {
                    await launchUrl(
                      url,
                      mode: LaunchMode.externalApplication,
                    );
                  }
                },
                icon: const Icon(Icons.open_in_new_rounded, size: 20),
                label: const Text('Open Link'),
              ),
              const SizedBox(height: 12),
            ],

            // Delete Button
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent.withValues(alpha: 0.1),
                foregroundColor: Colors.redAccent,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: Colors.redAccent.withValues(alpha: 0.2),
                  ),
                ),
                elevation: 0,
              ),
              onPressed: () async {
                await StorageService.deleteRecord(_record.id);
                if (context.mounted) {
                  Navigator.pop(context); // close sheet
                  widget.onUpdate(); // refresh
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Removed from history'),
                      behavior: SnackBarBehavior.floating,
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.delete_outline_rounded, size: 20),
              label: const Text('Delete'),
            ),
          ],
        ),
      ),
    );
  }
}
