import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../providers/license_provider.dart';
import '../utils/app_theme.dart';
import '../utils/app_strings.dart';

/// Screen untuk menambah SIM baru
class AddLicenseScreen extends StatefulWidget {
  const AddLicenseScreen({Key? key}) : super(key: key);

  @override
  State<AddLicenseScreen> createState() => _AddLicenseScreenState();
}

class _AddLicenseScreenState extends State<AddLicenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _licenseNumberController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _expirationDateController = TextEditingController();

  File? _photoFile;
  String _selectedLicenseType = 'SIM A';
  DateTime? _selectedDate;
  bool _isProcessing = false;
  bool _isScanning = false;

  final ImagePicker _imagePicker = ImagePicker();

  final List<String> _licenseTypes = ['SIM A', 'SIM B', 'SIM C'];

  @override
  void dispose() {
    _licenseNumberController.dispose();
    _ownerNameController.dispose();
    _expirationDateController.dispose();
    super.dispose();
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (photo != null) {
        setState(() {
          _photoFile = File(photo.path);
          _isScanning = true;
        });

        // Ekstrak data dengan OCR
        await _extractDataFromPhoto();
      }
    } catch (e) {
      _showError('Gagal mengambil foto: $e');
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (photo != null) {
        setState(() {
          _photoFile = File(photo.path);
          _isScanning = true;
        });

        // Ekstrak data dengan OCR
        await _extractDataFromPhoto();
      }
    } catch (e) {
      _showError('Gagal memilih foto: $e');
    }
  }

  Future<void> _extractDataFromPhoto() async {
    if (_photoFile == null) return;

    final licenseProvider = Provider.of<LicenseProvider>(context, listen: false);

    try {
      final extractedData = await licenseProvider.extractDataFromPhoto(_photoFile!);

      setState(() {
        if (extractedData['licenseNumber'] != null) {
          _licenseNumberController.text = extractedData['licenseNumber']!;
        }
        if (extractedData['licenseType'] != null) {
          _selectedLicenseType = extractedData['licenseType']!;
        }
        if (extractedData['ownerName'] != null) {
          _ownerNameController.text = extractedData['ownerName']!;
        }
        if (extractedData['expirationDate'] != null) {
          _expirationDateController.text = extractedData['expirationDate']!;
          // Parse tanggal
          try {
            final parts = extractedData['expirationDate']!.split('-');
            if (parts.length == 3) {
              _selectedDate = DateTime(
                int.parse(parts[2]),
                int.parse(parts[1]),
                int.parse(parts[0]),
              );
            }
          } catch (e) {
            print('Error parsing date: $e');
          }
        }
        _isScanning = false;
      });

      if (extractedData.values.every((v) => v == null)) {
        _showError(AppStrings.scanFailed);
      }
    } catch (e) {
      setState(() => _isScanning = false);
      _showError('Gagal memindai: $e');
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      locale: const Locale('id', 'ID'),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _expirationDateController.text = DateFormat('dd-MM-yyyy').format(picked);
      });
    }
  }

  Future<void> _saveLicense() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_photoFile == null) {
      _showError('Silakan ambil foto SIM terlebih dahulu');
      return;
    }

    if (_selectedDate == null) {
      _showError('Silakan pilih tanggal kadaluarsa');
      return;
    }

    setState(() => _isProcessing = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final licenseProvider = Provider.of<LicenseProvider>(context, listen: false);

    final success = await licenseProvider.addLicense(
      userId: authProvider.currentUser!.uid,
      isGuest: authProvider.isGuest,
      licenseNumber: _licenseNumberController.text.trim(),
      licenseType: _selectedLicenseType,
      ownerName: _ownerNameController.text.trim(),
      expirationDate: _selectedDate!,
      photoFile: _photoFile,
    );

    setState(() => _isProcessing = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.licenseAdded)),
      );
      Navigator.pop(context);
    } else if (mounted) {
      _showError(licenseProvider.errorMessage ?? 'Gagal menyimpan SIM');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppTheme.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.addNewLicense),
      ),
      body: _isProcessing
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Foto SIM
                    _buildPhotoSection(),

                    const SizedBox(height: 24),

                    // Form input
                    _buildFormFields(),

                    const SizedBox(height: 24),

                    // Tombol simpan
                    SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _saveLicense,
                        child: const Text(AppStrings.save),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildPhotoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (_photoFile != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  _photoFile!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              if (_isScanning) ...[
                const SizedBox(height: 16),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 12),
                    Text(AppStrings.scanningLicense),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _takePhoto,
                icon: const Icon(Icons.camera_alt),
                label: const Text(AppStrings.retakePhoto),
              ),
            ] else ...[
              Icon(
                Icons.add_a_photo,
                size: 64,
                color: AppTheme.grey,
              ),
              const SizedBox(height: 16),
              const Text(
                'Ambil Foto SIM',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Data akan otomatis terisi dengan OCR',
                style: TextStyle(fontSize: 12, color: AppTheme.darkGrey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _takePhoto,
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Kamera'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickFromGallery,
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Galeri'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFormFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tipe SIM
        Text(
          AppStrings.licenseType,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedLicenseType,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.credit_card),
          ),
          items: _licenseTypes.map((type) {
            return DropdownMenuItem(value: type, child: Text(type));
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() => _selectedLicenseType = value);
            }
          },
        ),

        const SizedBox(height: 16),

        // Nomor SIM
        TextFormField(
          controller: _licenseNumberController,
          decoration: const InputDecoration(
            labelText: AppStrings.licenseNumber,
            hintText: '1234567890123456',
            prefixIcon: Icon(Icons.numbers),
          ),
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return AppStrings.fieldRequired;
            }
            return null;
          },
        ),

        const SizedBox(height: 16),

        // Nama pemilik
        TextFormField(
          controller: _ownerNameController,
          decoration: const InputDecoration(
            labelText: AppStrings.ownerName,
            hintText: 'Nama lengkap',
            prefixIcon: Icon(Icons.person),
          ),
          textCapitalization: TextCapitalization.words,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return AppStrings.fieldRequired;
            }
            return null;
          },
        ),

        const SizedBox(height: 16),

        // Tanggal kadaluarsa
        TextFormField(
          controller: _expirationDateController,
          decoration: const InputDecoration(
            labelText: AppStrings.expirationDate,
            hintText: 'DD-MM-YYYY',
            prefixIcon: Icon(Icons.calendar_today),
          ),
          readOnly: true,
          onTap: _selectDate,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return AppStrings.fieldRequired;
            }
            return null;
          },
        ),
      ],
    );
  }
}
