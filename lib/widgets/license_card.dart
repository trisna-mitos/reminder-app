import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:io';
import '../models/license_model.dart';
import '../utils/app_theme.dart';
import '../utils/date_helper.dart';

/// Widget kartu untuk menampilkan license
class LicenseCard extends StatelessWidget {
  final LicenseModel license;
  final VoidCallback onTap;

  const LicenseCard({
    Key? key,
    required this.license,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final countdownStatus = DateHelper.getCountdownStatus(license.expirationDate);
    final countdownText = DateHelper.getCountdownText(license.expirationDate);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Foto SIM
              _buildPhoto(),

              const SizedBox(width: 16),

              // Info SIM
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tipe SIM & Nomor
                    Row(
                      children: [
                        _buildLicenseTypeBadge(),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            license.licenseNumber,
                            style: Theme.of(context).textTheme.bodyMedium,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    // Nama pemilik
                    Text(
                      license.ownerName,
                      style: Theme.of(context).textTheme.titleLarge,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 8),

                    // Tanggal kadaluarsa
                    Text(
                      DateHelper.formatDate(license.expirationDate),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),

                    const SizedBox(height: 4),

                    // Countdown
                    _buildCountdown(countdownText, countdownStatus),
                  ],
                ),
              ),

              // Status indicator
              _buildStatusIndicator(countdownStatus),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhoto() {
    if (license.photoUrl == null || license.photoUrl!.isEmpty) {
      return Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: AppTheme.lightGrey,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.credit_card,
          size: 40,
          color: AppTheme.grey,
        ),
      );
    }

    // Check if it's a network URL or local path
    final isNetworkImage = license.photoUrl!.startsWith('http');

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: isNetworkImage
          ? CachedNetworkImage(
              imageUrl: license.photoUrl!,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                width: 80,
                height: 80,
                color: AppTheme.lightGrey,
                child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                width: 80,
                height: 80,
                color: AppTheme.lightGrey,
                child: const Icon(Icons.error, color: AppTheme.error),
              ),
            )
          : Image.file(
              File(license.photoUrl!),
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 80,
                height: 80,
                color: AppTheme.lightGrey,
                child: const Icon(Icons.error, color: AppTheme.error),
              ),
            ),
    );
  }

  Widget _buildLicenseTypeBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.primaryBlue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        license.licenseType,
        style: const TextStyle(
          color: AppTheme.primaryBlue,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildCountdown(String text, CountdownStatus status) {
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

    return Row(
      children: [
        Icon(Icons.access_time, size: 14, color: color),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusIndicator(CountdownStatus status) {
    Color color;
    IconData icon;

    switch (status) {
      case CountdownStatus.expired:
        color = AppTheme.error;
        icon = Icons.cancel;
        break;
      case CountdownStatus.expiringSoon:
        color = AppTheme.warning;
        icon = Icons.warning;
        break;
      case CountdownStatus.active:
        color = AppTheme.success;
        icon = Icons.check_circle;
        break;
    }

    return Icon(icon, color: color, size: 24);
  }
}
