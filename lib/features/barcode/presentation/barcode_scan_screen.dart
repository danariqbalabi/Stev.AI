import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/theme/stev_tokens.dart';
import '../../../shared/widgets/stev_design_system.dart';
import '../data/barcode_lookup_service.dart';
import '../domain/barcode_product.dart';
import '../domain/stable_barcode_reader.dart';

class BarcodeScanScreen extends StatefulWidget {
  const BarcodeScanScreen({
    super.key,
    this.lookup,
    this.enableCamera = true,
    this.now,
  });
  final BarcodeLookup? lookup;
  final bool enableCamera;
  final DateTime Function()? now;
  @override
  State<BarcodeScanScreen> createState() => _BarcodeScanScreenState();
}

class _BarcodeScanScreenState extends State<BarcodeScanScreen>
    with WidgetsBindingObserver {
  late final BarcodeLookup _lookup = widget.lookup ?? BarcodeLookupService();
  final _barcode = TextEditingController();
  final _focus = FocusNode();
  final _reader = StableBarcodeReader();
  MobileScannerController? _scanner;
  Timer? _hintTimer;
  Timer? _retryTimer;
  bool _hint = false, _editing = false, _loading = false, _navigating = false;
  String? _code, _error, _foundName;
  BarcodeFailure? _failure;
  DateTime? _retryAt;
  int get _retrySeconds {
    final ms =
        _retryAt?.difference((widget.now ?? DateTime.now)()).inMilliseconds ??
        0;
    return ms > 0 ? (ms / 1000).ceil() : 0;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.enableCamera) {
      _scanner = MobileScannerController(
        detectionSpeed: DetectionSpeed.normal,
        detectionTimeoutMs: 200,
        formats: const [
          BarcodeFormat.ean8,
          BarcodeFormat.ean13,
          BarcodeFormat.upcA,
        ],
      );
      _armHint();
    }
  }

  void _armHint() {
    _hintTimer?.cancel();
    _hint = false;
    if (widget.enableCamera) {
      _hintTimer = Timer(const Duration(seconds: 2), () {
        if (mounted && _code == null) setState(() => _hint = true);
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_code != null || _loading || _navigating) return;
    if (state == AppLifecycleState.inactive) {
      _reader.reset();
      _hintTimer?.cancel();
      unawaited(_camera(false));
    } else if (state == AppLifecycleState.resumed) {
      unawaited(_camera(true));
    }
  }

  Future<void> _camera(bool start) async {
    try {
      if (!start) {
        await _scanner?.stop();
      } else if (_scanner?.value.hasCameraPermission ?? false) {
        await _scanner?.start();
      }
    } catch (_) {
      /* Manual entry remains available without camera access. */
    }
  }

  void _detect(BarcodeCapture capture) {
    if (_editing || _loading || _navigating || _code != null) return;
    final code = _reader.observe(
      capture.barcodes
          .where(
            (b) => const [
              BarcodeFormat.ean8,
              BarcodeFormat.ean13,
              BarcodeFormat.upcA,
            ].contains(b.format),
          )
          .map((b) => b.rawValue ?? ''),
      (widget.now ?? DateTime.now)(),
    );
    if (code != null) {
      _barcode.text = code;
      unawaited(_find(code));
    }
  }

  Future<void> _open(String route) async {
    if (_navigating) return;
    setState(() => _navigating = true);
    await _camera(false);
    if (mounted) context.pushReplacement(route, extra: _code);
  }

  void _reset() {
    _reader.reset();
    _retryTimer?.cancel();
    _armHint();
    setState(() {
      _editing = false;
      _code = null;
      _error = null;
      _failure = null;
      _foundName = null;
      _retryAt = null;
      _barcode.clear();
    });
  }

  Future<void> _find(String raw) async {
    if (_loading || _navigating || _retrySeconds > 0) return;
    final code = validRetailBarcode(raw);
    if (code == null) {
      setState(() => _error = 'Periksa kembali angka barcode pada kemasan.');
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _code = code;
      _hintTimer?.cancel();
      _loading = true;
      _error = null;
      _failure = null;
      _foundName = null;
    });
    await _camera(false);
    try {
      final product = await _lookup.lookup(code);
      if (!mounted) return;
      final ml = product.packageMl;
      if (ml == null || product.portionMl == null) {
        throw BarcodeLookupException(
          'Ukuran belum lengkap.',
          failure: BarcodeFailure.unknownVolume,
          productName: product.name,
        );
      }
      final drink = product.selectionForVolume(ml, 1).drink;
      setState(() => _navigating = true);
      context.pushReplacement(
        Uri(
          path: '/result',
          queryParameters: {
            'barcodeMl': '$ml',
            if (product.requiresDrinkConfirmation) 'confirmDrink': 'true',
          },
        ).toString(),
        extra: drink,
      );
    } on BarcodeLookupException catch (e) {
      if (!mounted) return;
      _retryTimer?.cancel();
      setState(() {
        _error = e.message;
        _failure = e.failure;
        _foundName = e.productName;
        _retryAt = e.retryAt;
      });
      if (_retrySeconds > 0) {
        _retryTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (!mounted || _retrySeconds == 0) timer.cancel();
          if (mounted) setState(() {});
        });
      }
    } on FormatException {
      if (mounted) {
        setState(() {
          _error = 'Data belum lengkap.';
          _failure = BarcodeFailure.invalidData;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Koneksi lagi bermasalah.';
          _failure = BarcodeFailure.unavailable;
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _barcode.dispose();
    _focus.dispose();
    _hintTimer?.cancel();
    _retryTimer?.cancel();
    unawaited(_scanner?.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final failed = _code != null && _error != null;
    return Scaffold(
      key: const ValueKey('barcodeScanScreen'),
      appBar: AppBar(
        title: Text(failed ? '' : 'Scan barcode'),
        leading: failed ? BackButton(onPressed: _reset) : null,
      ),
      body: AuraBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: const EdgeInsets.all(StevSpace.s5),
                  child: failed
                      ? IntrinsicHeight(child: _failureContent())
                      : _cameraContent(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _failureContent() {
    final network =
        _failure == BarcodeFailure.unavailable ||
        _failure == BarcodeFailure.rateLimited;
    return Column(
      children: [
        const SizedBox(height: StevSpace.s14),
        const GlassCard(child: Icon(Icons.receipt_long_outlined, size: 56)),
        const SizedBox(height: StevSpace.s7),
        Text(
          _foundName ?? 'Belum ada di data kami',
          key: const ValueKey('barcodeKnownProduct'),
          textAlign: TextAlign.center,
          style: StevType.title,
        ),
        const SizedBox(height: StevSpace.s4),
        Text(
          network
              ? 'Koneksi lagi bermasalah.'
              : 'Foto label gizinya untuk melihat gula dalam kemasan ini.',
          key: const ValueKey('barcodeError'),
          textAlign: TextAlign.center,
          style: StevType.body.copyWith(color: StevColors.ink2),
        ),
        const Spacer(),
        const SizedBox(height: StevSpace.s7),
        if (network) ...[
          StevButton(
            key: const ValueKey('retryBarcodeLookup'),
            label: _retrySeconds > 0
                ? 'Coba lagi dalam $_retrySeconds dtk'
                : 'Coba lagi',
            onPressed: _retrySeconds > 0 ? null : () => _find(_code!),
          ),
          TextButton(
            key: const ValueKey('barcodeScanLabel'),
            style: TextButton.styleFrom(
              foregroundColor: StevColors.ink2,
              textStyle: StevType.caption,
            ),
            onPressed: () => _open('/scan/label'),
            child: const Text('Foto label gizi'),
          ),
        ] else
          StevButton(
            key: const ValueKey('barcodeScanLabel'),
            label: 'Foto label gizi',
            onPressed: () => _open('/scan/label'),
          ),
        TextButton(
          key: const ValueKey('barcodeManualLabel'),
          style: TextButton.styleFrom(
            foregroundColor: StevColors.ink2,
            textStyle: StevType.caption,
          ),
          onPressed: () => _open('/nutrition/manual'),
          child: const Text('Isi manual'),
        ),
      ],
    );
  }

  Widget _cameraContent() {
    if (_loading || _navigating) {
      return const Column(
        children: [
          SizedBox(height: StevSpace.s14),
          CircularProgressIndicator(),
          SizedBox(height: StevSpace.s5),
          Text('Mencari minuman…'),
        ],
      );
    }
    return Column(
      children: [
        Text('Arahkan ke garis barcode', style: StevType.heading),
        const SizedBox(height: StevSpace.s5),
        if (widget.enableCamera)
          ClipRRect(
            borderRadius: BorderRadius.circular(StevRadius.card),
            child: SizedBox(
              height: 280,
              child: MobileScanner(
                controller: _scanner,
                onDetect: _detect,
                errorBuilder: (_, _) => ColoredBox(
                  color: StevColors.ink,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(StevSpace.s5),
                      child: Text(
                        'Izinkan akses kamera, atau ketik kode barcode.',
                        textAlign: TextAlign.center,
                        style: StevType.body.copyWith(color: StevColors.onInk),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        if (_hint)
          Padding(
            padding: const EdgeInsets.only(top: StevSpace.s4),
            child: Text(
              'Dekatkan kamera dan tahan sebentar.',
              key: const ValueKey('barcodeFocusHint'),
              style: StevType.caption,
            ),
          ),
        if (!_editing)
          TextButton(
            key: const ValueKey('revealBarcodeInput'),
            style: TextButton.styleFrom(
              foregroundColor: StevColors.ink2,
              textStyle: StevType.caption,
            ),
            onPressed: () {
              _reader.reset();
              setState(() => _editing = true);
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) _focus.requestFocus();
              });
            },
            child: const Text('Ketik kode barcode'),
          ),
        if (_editing) ...[
          TextField(
            key: const ValueKey('barcodeInput'),
            controller: _barcode,
            focusNode: _focus,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.search,
            decoration: const InputDecoration(labelText: 'Angka barcode'),
            onSubmitted: _find,
          ),
          if (_error != null) Text(_error!, style: StevType.caption),
          const SizedBox(height: StevSpace.s5),
          StevButton(
            key: const ValueKey('lookupBarcodeButton'),
            label: 'Cari produk',
            onPressed: () => _find(_barcode.text),
          ),
        ],
        TextButton(
          style: TextButton.styleFrom(
            foregroundColor: StevColors.ink2,
            textStyle: StevType.caption,
          ),
          onPressed: () => _open('/manual'),
          child: const Text('Cari manual'),
        ),
      ],
    );
  }
}
