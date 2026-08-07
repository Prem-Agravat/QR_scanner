import 'package:flutter/material.dart';
import '../main.dart';
import '../models/qr_record.dart';
import '../services/storage_service.dart';
import '../widgets/qr_details_sheet.dart';
import 'scan_screen.dart';
import 'generate_screen.dart';
import 'history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _scannedCount = 0;
  int _generatedCount = 0;
  int _favoritesCount = 0;
  List<QrRecord> _recentRecords = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() {
      _isLoading = true;
    });
    final records = await StorageService.loadRecords();
    int scanned = 0;
    int generated = 0;
    int favorites = 0;

    for (final r in records) {
      if (r.type == 'scanned') scanned++;
      if (r.type == 'generated') generated++;
      if (r.isFavorite) favorites++;
    }

    setState(() {
      _scannedCount = scanned;
      _generatedCount = generated;
      _favoritesCount = favorites;
      _recentRecords = records.take(3).toList();
      _isLoading = false;
    });
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
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
                    const Color(0xFF0B0F19), // Deep Slate Navy
                    const Color(0xFF0F172A), // Slate 900
                    const Color(0xFF020617), // Slate 955
                  ]
                : [
                    const Color(0xFFF8FAFC), // Slate 50
                    const Color(0xFFF1F5F9), // Slate 100
                    const Color(0xFFE2E8F0), // Slate 200
                  ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 16.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16),
                  // Header Row with Logo and Theme Toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.1,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.2,
                            ),
                            width: 1.0,
                          ),
                        ),
                        child: Icon(
                          Icons.qr_code_scanner_rounded,
                          color: theme.colorScheme.primary,
                          size: 32,
                        ),
                      ),
                      IconButton(
                        style: IconButton.styleFrom(
                          backgroundColor: isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.black.withValues(alpha: 0.05),
                          foregroundColor: theme.colorScheme.onSurface,
                          padding: const EdgeInsets.all(12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: (isDark ? Colors.white : Colors.black)
                                  .withValues(alpha: 0.1),
                            ),
                          ),
                        ),
                        icon: Icon(
                          isDark
                              ? Icons.light_mode_rounded
                              : Icons.dark_mode_rounded,
                          size: 24,
                        ),
                        onPressed: () {
                          themeNotifier.value = isDark
                              ? ThemeMode.light
                              : ThemeMode.dark;
                          // Trigger local rebuild for local variables
                          Future.delayed(const Duration(milliseconds: 50), () {
                            if (mounted) setState(() {});
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    '${_getGreeting()}, Explorer 👋',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Manage, scan and design customized QR codes.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Stats Panel
                  _buildStatsPanel(theme, isDark),

                  const SizedBox(height: 28),

                  // Quick Action Cards
                  _buildDashboardCard(
                    context,
                    title: 'Scan QR Code',
                    subtitle: 'Scan codes with camera or from gallery',
                    icon: Icons.filter_center_focus_rounded,
                    accentColor: theme.colorScheme.primary, // Cobalt Blue
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ScanScreen(),
                        ),
                      ).then((_) => _loadStats());
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildDashboardCard(
                    context,
                    title: 'Generate QR Code',
                    subtitle: 'Create codes with custom colors & logos',
                    icon: Icons.qr_code_rounded,
                    accentColor: theme.colorScheme.secondary, // Titanium Teal
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const GenerateScreen(),
                        ),
                      ).then((_) => _loadStats());
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildDashboardCard(
                    context,
                    title: 'Saved History',
                    subtitle: 'Manage scans, generated codes & favorites',
                    icon: Icons.history_rounded,
                    accentColor: const Color(0xFF6366F1), // Indigo
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const HistoryScreen(),
                        ),
                      ).then((_) => _loadStats());
                    },
                  ),
                  
                  const SizedBox(height: 28),

                  // Recent Activity Row
                  if (_recentRecords.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Recent Activity',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const HistoryScreen(),
                              ),
                            ).then((_) => _loadStats());
                          },
                          child: const Text('View All'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _recentRecords.length,
                      itemBuilder: (context, index) {
                        final record = _recentRecords[index];
                        final isScanned = record.type == 'scanned';
                        Color accentColor = isScanned
                            ? theme.colorScheme.primary
                            : theme.colorScheme.secondary;
                        if (record.qrColor != null) {
                          try {
                            accentColor = Color(int.parse(record.qrColor!));
                          } catch (_) {}
                        }
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          elevation: 0,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.02)
                              : Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.05,
                              ),
                            ),
                          ),
                          child: ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: accentColor.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isScanned
                                    ? Icons.filter_center_focus_rounded
                                    : Icons.qr_code_rounded,
                                color: accentColor,
                                size: 20,
                              ),
                            ),
                            title: Text(
                              record.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              record.content,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 14,
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.3),
                            ),
                            onTap: () {
                              QrDetailsSheet.show(context, record, () {
                                _loadStats();
                              });
                            },
                          ),
                        );
                      },
                    ),
                  ],

                  const SizedBox(height: 20),
                  // Footer
                  Text(
                    'QR Hub v1.1 • Flutter',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsPanel(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.02) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(
            alpha: isDark ? 0.06 : 0.08,
          ),
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      child: _isLoading
          ? const Center(
              child: SizedBox(
                height: 40,
                width: 40,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  theme,
                  label: 'Scanned',
                  value: _scannedCount.toString(),
                  icon: Icons.filter_center_focus_rounded,
                  color: theme.colorScheme.primary,
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                ),
                _buildStatItem(
                  theme,
                  label: 'Generated',
                  value: _generatedCount.toString(),
                  icon: Icons.qr_code_rounded,
                  color: theme.colorScheme.secondary,
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                ),
                _buildStatItem(
                  theme,
                  label: 'Starred',
                  value: _favoritesCount.toString(),
                  icon: Icons.star_rounded,
                  color: const Color(0xFFFBBF24), // Gold
                ),
              ],
            ),
    );
  }

  Widget _buildStatItem(
    ThemeData theme, {
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color.withValues(alpha: 0.8), size: 16),
            const SizedBox(width: 6),
            Text(
              value,
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildDashboardCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white,
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.05),
          width: 1.0,
        ),
        boxShadow: isDark
            ? [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.04),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          splashColor: accentColor.withValues(alpha: 0.1),
          highlightColor: accentColor.withValues(alpha: 0.05),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 18.0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.5,
                          ),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: accentColor.withValues(alpha: 0.2),
                      width: 1.0,
                    ),
                  ),
                  child: Icon(icon, color: accentColor, size: 24),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
