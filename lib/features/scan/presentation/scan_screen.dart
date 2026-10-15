import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../recognition/data/drink_recognition_service_factory.dart';
import '../../recognition/domain/drink_recognition.dart';
import '../../drinks/application/drink_catalog_controller.dart';
import '../../nutrition/data/remote_nutrition_label_reader.dart';
import '../../nutrition/domain/nutrition_label.dart';
import 'scan_mode_switcher.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({
    super.key,
    this.recognitionService,
    this.labelMode = false,
    this.nutritionReader,
  });

  final DrinkRecognitionService? recognitionService;
  final bool labelMode;
  final NutritionLabelReader? nutritionReader;

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> with WidgetsBindingObserver {
  final ImagePicker _imagePicker = ImagePicker();
  DrinkRecognitionService? _recognitionService;

  CameraController? _cameraController;
  Uint8List? _photoBytes;
  String? _errorMessage;
  bool _isInitializing = true;
  bool _isCapturing = false;
  bool _isPickingImage = false;
  bool _isRecognizing = false;
  String? _recognitionError;
  int _cameraGeneration = 0;
  Future<void>? _cameraInitialization;
  bool _isSwitchingMode = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_initializeCamera());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _recognitionService =
        widget.recognitionService ??
        DrinkRecognitionServiceFactory.create(
          catalog: DrinkCatalogScope.of(context).drinks,
        );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (kIsWeb || _isSwitchingMode) return;
    final controller = _cameraController;
    if (state == AppLifecycleState.inactive &&
        controller != null &&
        controller.value.isInitialized) {
      unawaited(_releaseCamera());
    } else if (state == AppLifecycleState.resumed &&
        _photoBytes == null &&
        !_isInitializing &&
        _cameraController == null) {
      unawaited(_initializeCamera());
    }
  }

  Future<void> _initializeCamera() {
    return _cameraInitialization = _startCamera();
  }

  Future<void> _startCamera() async {
    final generation = ++_cameraGeneration;
    if (mounted) {
      setState(() {
        _isInitializing = true;
        _errorMessage = null;
      });
    }

    final previousController = _cameraController;
    _cameraController = null;
    await previousController?.dispose();
    if (!mounted || generation != _cameraGeneration) return;

    CameraController? pending;
    try {
      final cameras = await availableCameras();
      if (!mounted || generation != _cameraGeneration) return;
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
        widget.labelMode ? ResolutionPreset.high : ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      pending = controller;
      await controller.initialize();

      if (!mounted || generation != _cameraGeneration) {
        return;
      }

      if (_photoBytes != null) {
        await _pausePreviewIfSupported(controller);
      }
      if (!mounted || generation != _cameraGeneration) return;
      setState(() {
        _cameraController = controller;
        _isInitializing = false;
      });
      pending = null;
    } on CameraException catch (error) {
      if (generation == _cameraGeneration) {
        _showCameraError(_messageForCameraError(error));
      }
    } catch (_) {
      if (generation == _cameraGeneration) {
        _showCameraError(
          'Kamera tidak dapat dimulai. Coba lagi atau pilih foto dari galeri.',
        );
      }
    } finally {
      await pending?.dispose();
    }
  }

  Future<void> _releaseCamera() async {
    ++_cameraGeneration;
    final controller = _cameraController;
    _cameraController = null;
    if (mounted) setState(() => _isInitializing = false);
    try {
      await controller?.dispose();
      await _cameraInitialization;
    } catch (_) {
      /* The manual path remains available. */
    }
  }

  Future<void> _switchMode(ScanMode mode) async {
    if (_isSwitchingMode || _isCapturing || _isPickingImage || _isRecognizing) {
      return;
    }
    setState(() => _isSwitchingMode = true);
    await _releaseCamera();
    if (mounted) context.pushReplacement(mode.route);
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
    setState(() {
      _photoBytes = null;
      _recognitionError = null;
    });

    // Restarting the controller is slightly slower than resumePreview, but it
    // reliably releases and reacquires the browser MediaStream. Reusing the
    // web controller can otherwise show a black/stale frame after retaking.
    await _initializeCamera();
  }

  Future<void> _openManualLabel() async {
    await _releaseCamera();
    if (!mounted) return;
    final retake = await context.push<bool>('/nutrition/manual');
    if (mounted && retake == true) {
      await _retakePhoto();
      return;
    }
    if (mounted &&
        _photoBytes == null &&
        ModalRoute.of(context)?.isCurrent == true) {
      await _initializeCamera();
    }
  }

  Future<void> _recognizePhoto() async {
    final photoBytes = _photoBytes;
    if (photoBytes == null || _isRecognizing) return;

    setState(() {
      _isRecognizing = true;
      _recognitionError = null;
    });
    try {
      if (widget.labelMode) {
        final label =
            await (widget.nutritionReader ?? const RemoteNutritionLabelReader())
                .read(photoBytes);
        if (!mounted) return;
        await _releaseCamera();
        if (!mounted) return;
        setState(() => _isRecognizing = false);
        final retake = await context.push<bool>(
          '/nutrition/confirm',
          extra: NutritionScanResult(photoBytes: photoBytes, label: label),
        );
        if (mounted && retake == true) await _retakePhoto();
        return;
      }
      final candidates = await _recognitionService!.identify(photoBytes);
      if (!mounted) return;
      if (candidates.isEmpty) {
        throw const DrinkRecognitionException(
          'Minuman belum dikenali. Coba foto lain atau cari manual.',
        );
      }

      setState(() => _isRecognizing = false);
      context.push(
        '/confirmation',
        extra: DrinkRecognitionResult(
          photoBytes: photoBytes,
          candidates: candidates,
        ),
      );
    } on NutritionLabelException catch (error) {
      if (!mounted) return;
      setState(() {
        _isRecognizing = false;
        _recognitionError = error.message;
      });
    } on DrinkRecognitionException catch (error) {
      if (!mounted) return;
      setState(() {
        _isRecognizing = false;
        _recognitionError = error.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isRecognizing = false;
        _recognitionError =
            'Stev belum bisa mengenali foto ini. Coba lagi atau cari manual.';
      });
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
    ++_cameraGeneration;
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_cameraController?.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasPhoto = _photoBytes != null;

    return Scaffold(
      key: ValueKey(widget.labelMode ? 'labelScanScreen' : 'photoScanScreen'),
      appBar: AppBar(
        title: Text(
          hasPhoto
              ? 'Preview foto'
              : widget.labelMode
              ? 'Scan label gizi'
              : 'Scan minuman',
        ),
      ),
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
        Text(
          widget.labelMode
              ? 'Foto seluruh tabel Informasi Nilai Gizi. Pastikan gula, takaran saji, dan sajian per kemasan terbaca jelas.'
              : 'Arahkan kamera ke minuman atau menu. Pastikan nama dan ukuran terlihat jelas.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Expanded(child: _buildCameraViewport()),
        const SizedBox(height: 12),
        ScanModeSwitcher(
          selected: widget.labelMode ? ScanMode.label : ScanMode.photo,
          onChanged: _isSwitchingMode || _isCapturing || _isPickingImage
              ? null
              : _switchMode,
        ),
        if (widget.labelMode)
          TextButton(
            key: const ValueKey('manualNutritionLabel'),
            onPressed: _openManualLabel,
            child: const Text('Isi label manual'),
          ),
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
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: TextButton.icon(
                key: const ValueKey('galleryButton'),
                onPressed: _isPickingImage ? null : _pickFromGallery,
                icon: const Icon(Icons.photo_library_outlined),
                label: Text(
                  _isPickingImage ? 'Membuka galeri...' : 'Pilih dari galeri',
                ),
              ),
            ),
            Flexible(
              child: TextButton(
                key: const ValueKey('manualSearchLink'),
                onPressed: () => context.push('/manual'),
                child: const Text('Cari manual'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCameraViewport() {
    if (_isInitializing) {
      return const _CameraFrame(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 16),
              Text(
                'Menyiapkan kamera...',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      );
    }

    final controller = _cameraController;
    if (_errorMessage != null || controller == null) {
      return _CameraFrame(
        child: SingleChildScrollView(
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
        Text(
          widget.labelMode
              ? 'Pastikan angka gula dan keterangan per sajian/per kemasan terlihat, tanpa pantulan cahaya.'
              : 'Pastikan minuman terlihat jelas sebelum dilanjutkan.',
          textAlign: TextAlign.center,
        ),
        if (_recognitionError case final error?) ...[
          const SizedBox(height: 12),
          Text(
            error,
            key: const ValueKey('recognitionError'),
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        const SizedBox(height: 16),
        FilledButton.icon(
          key: const ValueKey('usePhotoButton'),
          onPressed: _isRecognizing ? null : _recognizePhoto,
          icon: _isRecognizing
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.auto_awesome_outlined),
          label: Text(
            _isRecognizing
                ? (widget.labelMode
                      ? 'Membaca label...'
                      : 'Stev lagi mengenali...')
                : (widget.labelMode ? 'Baca label gizi' : 'Kenali minuman'),
          ),
        ),
        TextButton.icon(
          key: const ValueKey('retakeButton'),
          onPressed: _isRecognizing ? null : _retakePhoto,
          icon: const Icon(Icons.refresh),
          label: const Text('Foto ulang'),
        ),
        if (widget.labelMode)
          TextButton(
            key: const ValueKey('previewManualNutritionLabel'),
            onPressed: _isRecognizing ? null : _openManualLabel,
            child: const Text('Isi label manual'),
          ),
        TextButton(
          key: const ValueKey('previewManualSearchButton'),
          onPressed: _isRecognizing ? null : () => context.push('/manual'),
          child: const Text('Cari manual'),
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
