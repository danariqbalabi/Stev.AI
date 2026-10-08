import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> with WidgetsBindingObserver {
  final ImagePicker _imagePicker = ImagePicker();

  CameraController? _cameraController;
  Uint8List? _photoBytes;
  String? _errorMessage;
  bool _isInitializing = true;
  bool _isCapturing = false;
  bool _isPickingImage = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_initializeCamera());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized || kIsWeb) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      _cameraController = null;
      unawaited(controller.dispose());
    } else if (state == AppLifecycleState.resumed && _photoBytes == null) {
      unawaited(_initializeCamera());
    }
  }

  Future<void> _initializeCamera() async {
    if (mounted) {
      setState(() {
        _isInitializing = true;
        _errorMessage = null;
      });
    }

    final previousController = _cameraController;
    _cameraController = null;
    await previousController?.dispose();

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw CameraException(
          'NoCameraAvailable',
          'Tidak ada kamera yang ditemukan pada perangkat ini.',
        );
      }

      final selectedCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        selectedCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await controller.initialize();

      if (!mounted) {
        await controller.dispose();
        return;
      }

      if (_photoBytes != null) {
        await _pausePreviewIfSupported(controller);
      }
      setState(() {
        _cameraController = controller;
        _isInitializing = false;
      });
    } on CameraException catch (error) {
      _showCameraError(_messageForCameraError(error));
    } catch (_) {
      _showCameraError(
        'Kamera tidak dapat dimulai. Coba lagi atau pilih foto dari galeri.',
      );
    }
  }

  String _messageForCameraError(CameraException error) {
    return switch (error.code) {
      'CameraAccessDenied' ||
      'CameraAccessDeniedWithoutPrompt' ||
      'CameraAccessRestricted' => 'Izin kamera ditolak. Izinkan akses kamera dari pengaturan browser atau perangkat.',
      'NoCameraAvailable' =>
        'Tidak ada kamera yang ditemukan pada perangkat ini.',
      _ =>
        'Kamera tidak dapat dimulai (${error.code}). Coba lagi atau pilih foto dari galeri.',
    };
  }

  void _showCameraError(String message) {
    if (!mounted) {
      return;
    }

    setState(() {
      _isInitializing = false;
      _errorMessage = message;
    });
  }

  Future<void> _capturePhoto() async {
    final controller = _cameraController;
    if (controller == null ||
        !controller.value.isInitialized ||
        controller.value.isTakingPicture ||
        _isCapturing) {
      return;
    }

    setState(() => _isCapturing = true);
    try {
      final photo = await controller.takePicture();
      final bytes = await photo.readAsBytes();
      if (!mounted) {
        return;
      }

      await _pausePreviewIfSupported(controller);
      setState(() => _photoBytes = bytes);
    } on CameraException catch (error) {
      _showSnackBar('Foto gagal diambil: ${error.description ?? error.code}');
    } finally {
      if (mounted) {
        setState(() => _isCapturing = false);
      }
    }
  }

  Future<void> _pickFromGallery() async {
    if (_isPickingImage) {
      return;
    }

    setState(() => _isPickingImage = true);
    try {
      final photo = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1600,
      );
      if (photo == null) {
        return;
      }

      final bytes = await photo.readAsBytes();
      if (!mounted) {
        return;
      }

      final controller = _cameraController;
      if (controller != null && controller.value.isInitialized) {
        await _pausePreviewIfSupported(controller);
      }
      setState(() => _photoBytes = bytes);
    } catch (_) {
      _showSnackBar('Foto tidak dapat dibuka. Coba pilih gambar lain.');
    } finally {
      if (mounted) {
        setState(() => _isPickingImage = false);
      }
    }
  }

  Future<void> _retakePhoto() async {
    setState(() => _photoBytes = null);
    final controller = _cameraController;
    if (controller != null && controller.value.isInitialized) {
      if (kIsWeb) {
        return;
      }
      try {
        await controller.resumePreview();
      } on CameraException {
        await _initializeCamera();
      }
    } else {
      await _initializeCamera();
    }
  }

  Future<void> _pausePreviewIfSupported(CameraController controller) async {
    if (kIsWeb) {
      return;
    }

    try {
      await controller.pausePreview();
    } on CameraException {
      // Capturing succeeded; a platform that cannot pause preview should not
      // discard the photo or block the user from continuing.
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_cameraController?.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasPhoto = _photoBytes != null;

    return Scaffold(
      appBar: AppBar(title: Text(hasPhoto ? 'Preview foto' : 'Scan minuman')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: hasPhoto ? _buildPhotoPreview() : _buildCameraContent(),
        ),
      ),
    );
  }

  Widget _buildCameraContent() {
    return Column(
      children: [
        const Text(
          'Arahkan kamera ke minuman atau menu. Pastikan nama dan ukuran terlihat jelas.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Expanded(child: _buildCameraViewport()),
        const SizedBox(height: 20),
        if (_cameraController?.value.isInitialized ?? false)
          FilledButton.icon(
            key: const ValueKey('captureButton'),
            onPressed: _isCapturing ? null : _capturePhoto,
            icon: _isCapturing
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.camera_alt_outlined),
            label: Text(_isCapturing ? 'Mengambil foto...' : 'Ambil foto'),
          ),
        TextButton.icon(
          key: const ValueKey('galleryButton'),
          onPressed: _isPickingImage ? null : _pickFromGallery,
          icon: const Icon(Icons.photo_library_outlined),
          label: Text(
            _isPickingImage ? 'Membuka galeri...' : 'Pilih dari galeri',
          ),
        ),
      ],
    );
  }

  Widget _buildCameraViewport() {
    if (_isInitializing) {
      return const _CameraFrame(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text('Menyiapkan kamera...', style: TextStyle(color: Colors.white)),
          ],
        ),
      );
    }

    final controller = _cameraController;
    if (_errorMessage != null || controller == null) {
      return _CameraFrame(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.no_photography_outlined,
                color: Colors.white,
                size: 56,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage ?? 'Kamera tidak tersedia.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                key: const ValueKey('retryCameraButton'),
                onPressed: _initializeCamera,
                style: OutlinedButton.styleFrom(foregroundColor: Colors.white),
                icon: const Icon(Icons.refresh),
                label: const Text('Coba lagi'),
              ),
            ],
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: ColoredBox(
        color: Colors.black,
        child: Center(
          child: AspectRatio(
            aspectRatio: controller.value.aspectRatio,
            child: CameraPreview(controller),
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoPreview() {
    return Column(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: ColoredBox(
              color: Colors.black,
              child: Center(
                child: Image.memory(
                  _photoBytes!,
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.contain,
                  gaplessPlayback: true,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Pastikan minuman terlihat jelas sebelum dilanjutkan.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          key: const ValueKey('usePhotoButton'),
          onPressed: () => context.push('/confirmation'),
          icon: const Icon(Icons.check),
          label: const Text('Gunakan foto'),
        ),
        TextButton.icon(
          key: const ValueKey('retakeButton'),
          onPressed: _retakePhoto,
          icon: const Icon(Icons.refresh),
          label: const Text('Foto ulang'),
        ),
      ],
    );
  }
}

class _CameraFrame extends StatelessWidget {
  const _CameraFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(24),
      ),
      child: child,
    );
  }
}
