import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/app_theme.dart';
import '../utils/app_strings.dart';
import 'login_screen.dart';

/// Settings screen
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        final user = authProvider.currentUser;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Account section
            _buildAccountCard(context, authProvider),

            const SizedBox(height: 16),

            // Notifications section
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.notifications),
                    title: const Text('Notifikasi'),
                    subtitle: const Text('Pengingat kadaluarsa SIM'),
                  ),
                  SwitchListTile(
                    secondary: const Icon(Icons.notification_add),
                    title: const Text(AppStrings.enableNotifications),
                    subtitle: const Text(AppStrings.notificationDesc),
                    value: user?.notificationsEnabled ?? true,
                    onChanged: (value) {
                      authProvider.updateNotificationSetting(value);
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // About section
            Card(
              child: Column(
                children: [
                  const ListTile(
                    leading: Icon(Icons.info),
                    title: Text(AppStrings.about),
                  ),
                  ListTile(
                    leading: const Icon(Icons.app_settings_alt),
                    title: const Text(AppStrings.version),
                    subtitle: const Text('1.0.0'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.code),
                    title: const Text('Developer'),
                    subtitle: const Text('SIM Reminder Team'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Sign out button
            SizedBox(
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () => _confirmSignOut(context, authProvider),
                icon: const Icon(Icons.logout),
                label: const Text(AppStrings.signOut),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.error,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAccountCard(BuildContext context, AuthProvider authProvider) {
    final user = authProvider.currentUser;

    if (user == null) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // User info
            Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: AppTheme.primaryBlue.withOpacity(0.1),
                  backgroundImage:
                      user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
                  child: user.photoUrl == null
                      ? Icon(
                          user.isGuest ? Icons.person_outline : Icons.person,
                          size: 32,
                          color: AppTheme.primaryBlue,
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.displayName ?? 'Pengguna',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      if (user.email != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          user.email!,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                      const SizedBox(height: 4),
                      _buildAccountTypeBadge(user.isGuest),
                    ],
                  ),
                ),
              ],
            ),

            // Upgrade button untuk guest
            if (user.isGuest) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.warning, color: AppTheme.warning, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Data akan hilang jika aplikasi dihapus',
                      style: TextStyle(fontSize: 12, color: AppTheme.darkGrey),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _upgradeToGoogle(context, authProvider),
                  icon: const Icon(Icons.upgrade),
                  label: const Text(AppStrings.convertToGoogle),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAccountTypeBadge(bool isGuest) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isGuest
            ? AppTheme.warning.withOpacity(0.1)
            : AppTheme.success.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isGuest ? AppTheme.warning : AppTheme.success,
        ),
      ),
      child: Text(
        isGuest ? 'Akun Tamu' : 'Akun Google',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isGuest ? AppTheme.warning : AppTheme.success,
        ),
      ),
    );
  }

  void _upgradeToGoogle(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upgrade ke Akun Google'),
        content: const Text(
          'Data SIM Anda akan dipindahkan dan disinkronkan ke akun Google Anda.\n\nLanjutkan?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(AppStrings.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await authProvider.convertGuestToGoogle();
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Berhasil upgrade ke akun Google'),
                  ),
                );
              } else if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      authProvider.errorMessage ?? 'Gagal upgrade akun',
                    ),
                    backgroundColor: AppTheme.error,
                  ),
                );
              }
            },
            child: const Text('Upgrade'),
          ),
        ],
      ),
    );
  }

  void _confirmSignOut(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.signOutConfirmation),
        content: authProvider.isGuest
            ? const Text(AppStrings.guestDataWarning)
            : null,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(AppStrings.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await authProvider.signOut();

              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
            ),
            child: const Text(AppStrings.signOut),
          ),
        ],
      ),
    );
  }
}
