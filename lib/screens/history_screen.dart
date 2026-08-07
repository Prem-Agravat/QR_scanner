import 'package:flutter/material.dart';
import '../models/qr_record.dart';
import '../services/storage_service.dart';
import '../widgets/qr_details_sheet.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<QrRecord> _records = [];
  bool _isLoading = true;
  String _filter = 'All'; // 'All', 'Scanned', 'Generated', 'Starred'
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
    });
    final list = await StorageService.loadRecords();
    setState(() {
      _records = list;
      _isLoading = false;
    });
  }

  List<QrRecord> get _filteredRecords {
    List<QrRecord> list = _records;

    // Apply category filter
    if (_filter == 'Scanned') {
      list = list.where((r) => r.type == 'scanned').toList();
    } else if (_filter == 'Generated') {
      list = list.where((r) => r.type == 'generated').toList();
    } else if (_filter == 'Starred') {
      list = list.where((r) => r.isFavorite).toList();
    }

    // Apply search query filter
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((r) => r.name.toLowerCase().contains(q) || r.content.toLowerCase().contains(q)).toList();
    }

    return list;
  }

  Map<String, List<QrRecord>> _groupRecordsByDate(List<QrRecord> list) {
    final Map<String, List<QrRecord>> groups = {
      'Today': [],
      'Yesterday': [],
      'Older': [],
    };

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    for (final record in list) {
      final recDate = DateTime(record.timestamp.year, record.timestamp.month, record.timestamp.day);
      if (recDate == today) {
        groups['Today']!.add(record);
      } else if (recDate == yesterday) {
        groups['Yesterday']!.add(record);
      } else {
        groups['Older']!.add(record);
      }
    }
    return groups;
  }

  String _formatDate(DateTime dt) {
    final year = dt.year;
    final month = dt.month.toString().padLeft(2, '0');
    final day = dt.day.toString().padLeft(2, '0');
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$year-$month-$day $hour:$minute';
  }

  Future<void> _clearHistory() async {
    final theme = Theme.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Clear All History?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('This will delete all scanned and generated codes forever. You cannot undo this action.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete Everything'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await StorageService.saveRecords([]);
      _loadHistory();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final filtered = _filteredRecords;
    final groups = _groupRecordsByDate(filtered);

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
            crossAxisAlignment: CrossAxisAlignment.stretch,
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
                      'Saved History',
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                    IconButton(
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.redAccent.withValues(alpha: 0.05),
                        foregroundColor: Colors.redAccent,
                        padding: const EdgeInsets.all(12),
                      ),
                      icon: const Icon(Icons.delete_sweep_rounded, size: 20),
                      onPressed: _records.isEmpty ? null : _clearHistory,
                    ),
                  ],
                ),
              ),

              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                child: TextField(
                  controller: _searchController,
                  style: TextStyle(color: theme.colorScheme.onSurface),
                  decoration: InputDecoration(
                    hintText: 'Search by label or content...',
                    hintStyle: TextStyle(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                    ),
                    prefixIcon: Icon(Icons.search_rounded, color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () => _searchController.clear(),
                          )
                        : null,
                    filled: true,
                    fillColor: theme.colorScheme.onSurface.withValues(alpha: 0.04),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),

              // Filter Tabs Row
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 8.0,
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: ['All', 'Scanned', 'Generated', 'Starred'].map((type) {
                      final isSelected = _filter == type;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _filter = type;
                            });
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurface.withValues(
                                      alpha: 0.05,
                                    ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.transparent
                                    : theme.colorScheme.onSurface.withValues(
                                        alpha: 0.1,
                                      ),
                              ),
                            ),
                            child: Text(
                              type,
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : theme.colorScheme.onSurface.withValues(
                                        alpha: 0.7,
                                      ),
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              // List area
              Expanded(
                child: _isLoading
                    ? Center(
                        child: CircularProgressIndicator(
                          color: theme.colorScheme.primary,
                        ),
                      )
                    : filtered.isEmpty
                        ? _buildEmptyState(theme)
                        : _buildGroupedListView(groups, theme, isDark),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.history_rounded,
          size: 72,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.15),
        ),
        const SizedBox(height: 16),
        Text(
          'No history found',
          style: TextStyle(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _searchQuery.isNotEmpty
              ? 'No items match your search query.'
              : _filter == 'Starred'
                  ? 'Star some QR codes for quick offline access!'
                  : 'Scan or generate QR codes to build history.',
          style: TextStyle(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            fontSize: 13,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildGroupedListView(Map<String, List<QrRecord>> groups, ThemeData theme, bool isDark) {
    final List<Widget> listItems = [];

    groups.forEach((groupName, items) {
      if (items.isNotEmpty) {
        // Group Header
        listItems.add(
          Padding(
            padding: const EdgeInsets.only(left: 24.0, top: 16.0, bottom: 8.0),
            child: Text(
              groupName,
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w800,
                fontSize: 14,
                letterSpacing: 0.5,
              ),
            ),
          ),
        );

        // Group cards
        for (final record in items) {
          listItems.add(
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 6.0),
              child: Dismissible(
                key: Key(record.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 24),
                ),
                onDismissed: (direction) async {
                  await StorageService.deleteRecord(record.id);
                  // Quick state reload to avoid UI glitches
                  final updatedList = await StorageService.loadRecords();
                  setState(() {
                    _records = updatedList;
                  });
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Removed from history'),
                        behavior: SnackBarBehavior.floating,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                },
                child: _buildRecordCard(record, theme, isDark),
              ),
            ),
          );
        }
      }
    });

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 24.0),
      children: listItems,
    );
  }

  Widget _buildRecordCard(QrRecord record, ThemeData theme, bool isDark) {
    final isScanned = record.type == 'scanned';
    Color accentColor = isScanned ? theme.colorScheme.primary : theme.colorScheme.secondary;
    if (record.qrColor != null) {
      try {
        accentColor = Color(int.parse(record.qrColor!));
      } catch (_) {}
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(
            alpha: isDark ? 0.06 : 0.08,
          ),
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => QrDetailsSheet.show(context, record, _loadHistory),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // Icon Type
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isScanned ? Icons.filter_center_focus_rounded : Icons.qr_code_rounded,
                    color: accentColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),

                // Titles
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        record.content,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.5,
                          ),
                          fontSize: 13,
                          fontFamily: record.content.startsWith('http') ? 'monospace' : null,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatDate(record.timestamp),
                        style: TextStyle(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.3,
                          ),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Quick Favorite Toggle
                IconButton(
                  icon: Icon(
                    record.isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: record.isFavorite ? const Color(0xFFFBBF24) : theme.colorScheme.onSurface.withValues(alpha: 0.2),
                    size: 22,
                  ),
                  onPressed: () async {
                    final updated = record.copyWith(isFavorite: !record.isFavorite);
                    final records = await StorageService.loadRecords();
                    final idx = records.indexWhere((r) => r.id == record.id);
                    if (idx != -1) {
                      records[idx] = updated;
                      await StorageService.saveRecords(records);
                      _loadHistory();
                    }
                  },
                ),
                
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.15),
                  size: 14,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
