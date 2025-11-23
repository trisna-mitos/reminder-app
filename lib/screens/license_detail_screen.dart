import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/auth_provider.dart';
import '../providers/license_provider.dart';
import '../models/license_model.dart';
import '../utils/app_theme.dart';
import '../utils/app_strings.dart';
import '../utils/date_helper.dart';

/// Screen untuk menampilkan detail SIM
class LicenseDetailScreen extends StatelessWidget {
  final String licenseId;

  const LicenseDetailScreen({Key? key, required this.licenseId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<LicenseProvider>(
      builder: (context, licenseProvider, _) {
        final license = licenseProvider.getLicenseById(licenseId);

        if (license == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Detail SIM')),
            body: const Center(child: Text('SIM tidak ditemukan')),
          );
        }

        return _LicenseDetailContent(license: license);
      },
    );
  }
}

class _LicenseDetailContent extends StatelessWidget {
  final LicenseModel license;

  const _LicenseDetailContent({required this.license});

  @override
  Widget build(BuildContext context) {
    final countdownStatus = DateHelper.getCountdownStatus(license.expirationDate);
    final countdownText = DateHelper.getCountdownText(license.expirationDate);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.licenseDetails),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Foto SIM
            _buildPhoto(context),

            // Info SIM
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status badge
                  _buildStatusBadge(countdownStatus, countdownText),

                  const SizedBox(height: 24),

                  // Tipe SIM
                  _buildInfoRow(
                    context,
                    Icons.credit_card,
                    'Tipe SIM',
                    license.licenseType,
                  ),

                  const Divider(height: 32),

                  // Nomor SIM
                  _buildInfoRow(
                    context,
                    Icons.numbers,
                    AppStrings.licenseNumber,
                    license.licenseNumber,
                  ),

                  const Divider(height: 32),

                  // Nama pemilik
                  _buildInfoRow(
                    context,
                    Icons.person,
                    AppStrings.ownerName,
                    license.ownerName,
                  ),

                  const Divider(height: 32),

                  // Tanggal kadaluarsa
                  _buildInfoRow(
                    context,
                    Icons.calendar_today,
                    AppStrings.expirationDate,
                    DateHelper.formatFullDate(license.expirationDate),
                  ),

                  const Divider(height: 32),

                  // Countdown
                  _buildCountdownCard(countdownStatus, countdownText),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhoto(BuildContext context) {
    if (license.photoUrl == null || license.photoUrl!.isEmpty) {
      return Container(
        height: 250,
        color: AppTheme.lightGrey,
        child: const Center(
          child: Icon(Icons.credit_card, size: 80, color: AppTheme.grey),
        ),
      );
    }

    final isNetworkImage = license.photoUrl!.startsWith('http');

    return GestureDetector(
      onTap: () => _showFullImage(context),
      child: Hero(
        tag: 'license_photo_${license.id}',
        child: isNetworkImage
            ? CachedNetworkImage(
                imageUrl: license.photoUrl!,
                height: 250,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  height: 250,
                  color: AppTheme.lightGrey,
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => Container(
                  height: 250,
                  color: AppTheme.lightGrey,
                  child: const Icon(Icons.error, color: AppTheme.error),
                ),
              )
            : Image.file(
                File(license.photoUrl!),
                height: 250,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
      ),
    );
  }

  Widget _buildStatusBadge(CountdownStatus status, String text) {
    Color color;
    IconData icon;
    String label;

    switch (status) {
      case CountdownStatus.expired:
        color = AppTheme.error;
        icon = Icons.cancel;
        label = 'KADALUARSA';
        break;
      case CountdownStatus.expiringSoon:
        color = AppTheme.warning;
        icon = Icons.warning;
        label = 'SEGERA KADALUARSA';
        break;
      case CountdownStatus.active:
        color = AppTheme.success;
        icon = Icons.check_circle;
        label = 'AKTIF';
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  text,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 24, color: AppTheme.primaryBlue),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCountdownCard(CountdownStatus status, String text) {
    final daysRemaining = license.daysUntilExpiration;
    Color color;

    switch (status) {
      case CountdownStatus.expired:
        color = AppTheme.error;
        break;
      case CountdownStatus.expiringSoon:
        color = AppTheme.warning;
        break;
      case CountdownStatus.active:
        color = AppTheme.success;
        break;
    }

    return Card(
      color: color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              daysRemaining < 0 ? 'Kadaluarsa' : 'Sisa Waktu',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              daysRemaining < 0
                  ? '${daysRemaining.abs()} hari'
                  : '$daysRemaining hari',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFullImage(BuildContext context) {
    if (license.photoUrl == null) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
          body: Center(
            child: Hero(
              tag: 'license_photo_${license.id}',
              child: InteractiveViewer(
                child: license.photoUrl!.startsWith('http')
                    ? CachedNetworkImage(imageUrl: license.photoUrl!)
                    : Image.file(File(license.photoUrl!)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.deleteConfirmation),
        content: const Text(AppStrings.deleteMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(AppStrings.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteLicense(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
            ),
            child: const Text(AppStrings.delete),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteLicense(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final licenseProvider = Provider.of<LicenseProvider>(context, listen: false);

    final success = await licenseProvider.deleteLicense(
      userId: authProvider.currentUser!.uid,
      isGuest: authProvider.isGuest,
      licenseId: license.id,
      photoUrl: license.photoUrl,
    );

    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.licenseDeleted)),
      );
      Navigator.pop(context);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(licenseProvider.errorMessage ?? 'Gagal menghapus SIM'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }
}
