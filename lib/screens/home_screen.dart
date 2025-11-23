import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/license_provider.dart';
import '../utils/app_theme.dart';
import '../utils/app_strings.dart';
import '../widgets/license_card.dart';
import 'add_license_screen.dart';
import 'license_detail_screen.dart';
import 'settings_screen.dart';

/// Home screen dengan daftar SIM dan bottom navigation
class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadLicenses();
  }

  Future<void> _loadLicenses() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final licenseProvider = Provider.of<LicenseProvider>(context, listen: false);

    if (authProvider.currentUser != null) {
      await licenseProvider.loadLicenses(
        userId: authProvider.currentUser!.uid,
        isGuest: authProvider.isGuest,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.myLicenses),
        actions: [
          Consumer<AuthProvider>(
            builder: (context, authProvider, _) {
              if (authProvider.isGuest) {
                return IconButton(
                  icon: const Icon(Icons.warning_amber),
                  tooltip: 'Mode Tamu',
                  onPressed: _showGuestWarning,
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: _currentIndex == 0 ? _buildLicenseList() : const SettingsScreen(),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton.extended(
              onPressed: _navigateToAddLicense,
              icon: const Icon(Icons.add),
              label: const Text('Tambah SIM'),
              backgroundColor: AppTheme.primaryBlue,
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Beranda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Pengaturan',
          ),
        ],
      ),
    );
  }

  Widget _buildLicenseList() {
    return Consumer<LicenseProvider>(
      builder: (context, licenseProvider, _) {
        if (licenseProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (licenseProvider.licenses.isEmpty) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          onRefresh: _loadLicenses,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Guest mode warning banner
              Consumer<AuthProvider>(
                builder: (context, authProvider, _) {
                  if (authProvider.isGuest) {
                    return _buildGuestBanner();
                  }
                  return const SizedBox.shrink();
                },
              ),

              // Expiring soon section
              if (licenseProvider.expiringSoonLicenses.isNotEmpty) ...[
                _buildSectionHeader(
                  'Segera Kadaluarsa',
                  Icons.warning,
                  AppTheme.warning,
                ),
                const SizedBox(height: 12),
                ...licenseProvider.expiringSoonLicenses.map(
                  (license) => LicenseCard(
                    license: license,
                    onTap: () => _navigateToDetail(license.id),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Expired section
              if (licenseProvider.expiredLicenses.isNotEmpty) ...[
                _buildSectionHeader(
                  'Sudah Kadaluarsa',
                  Icons.cancel,
                  AppTheme.error,
                ),
                const SizedBox(height: 12),
                ...licenseProvider.expiredLicenses.map(
                  (license) => LicenseCard(
                    license: license,
                    onTap: () => _navigateToDetail(license.id),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Active licenses section
              if (licenseProvider.activeLicenses.isNotEmpty) ...[
                _buildSectionHeader(
                  'Aktif',
                  Icons.check_circle,
                  AppTheme.success,
                ),
                const SizedBox(height: 12),
                ...licenseProvider.activeLicenses
                    .where((l) => !l.isExpiringSoon)
                    .map(
                      (license) => LicenseCard(
                        license: license,
                        onTap: () => _navigateToDetail(license.id),
                      ),
                    ),
              ],

              // Bottom padding for FAB
              const SizedBox(height: 80),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGuestBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.warning.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppTheme.warning),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Mode Tamu',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.darkGrey,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Data hanya tersimpan di perangkat ini',
                  style: TextStyle(fontSize: 12, color: AppTheme.darkGrey),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              // Navigate to settings to upgrade account
              setState(() {
                _currentIndex = 1;
              });
            },
            child: const Text('Upgrade'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppTheme.lightGrey,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.credit_card_outlined,
                size: 64,
                color: AppTheme.grey,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              AppStrings.noLicenses,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              AppStrings.noLicensesDesc,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _navigateToAddLicense,
              icon: const Icon(Icons.add),
              label: const Text('Tambah SIM Pertama'),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToAddLicense() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AddLicenseScreen()),
    ).then((_) => _loadLicenses());
  }

  void _navigateToDetail(String licenseId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LicenseDetailScreen(licenseId: licenseId),
      ),
    ).then((_) => _loadLicenses());
  }

  void _showGuestWarning() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mode Tamu'),
        content: const Text(
          'Anda sedang menggunakan mode tamu. Data akan hilang jika aplikasi dihapus atau Anda logout.\n\nUpgrade ke akun Google untuk menyimpan data secara permanen dan sinkronisasi antar perangkat.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(AppStrings.ok),
          ),
        ],
      ),
    );
  }
}
