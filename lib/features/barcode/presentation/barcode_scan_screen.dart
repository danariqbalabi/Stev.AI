import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/theme/stev_tokens.dart';
import '../../../shared/widgets/drink_photo.dart';
import '../../../shared/widgets/stev_design_system.dart';
import '../../drinks/application/drink_log_controller.dart';
import '../../drinks/domain/drink.dart';
import '../data/barcode_lookup_service.dart';
import '../domain/barcode_product.dart';

class BarcodeScanScreen extends StatefulWidget {
  const BarcodeScanScreen({super.key, this.lookup, this.enableCamera = true});

  final BarcodeLookup? lookup;
  final bool enableCamera;

  @override
  State<BarcodeScanScreen> createState() => _BarcodeScanScreenState();
}

class _BarcodeScanScreenState extends State<BarcodeScanScreen>
    with WidgetsBindingObserver {
  late final BarcodeLookup _lookup = widget.lookup ?? BarcodeLookupService();
  final _barcode = TextEditingController();
  final _portions = TextEditingController();
  String? _code;
  String? _error;
  BarcodeProduct? _product;
  bool _loading = false;
  bool _saving = false;
  MobileScannerController? _scanner;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.enableCamera) {
      _scanner = MobileScannerController(
        formats: const [
          BarcodeFormat.ean8,
          BarcodeFormat.ean13,
          BarcodeFormat.upcA,
        ],
      );
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_code != null || _loading) return;
    if (state == AppLifecycleState.inactive) {
      unawaited(_updateCamera(false));
    } else if (state == AppLifecycleState.resumed) {
      unawaited(_updateCamera(true));
    }
  }

  Future<void> _updateCamera(bool start) async {
    try {
      if (start) {
        if (_scanner?.value.hasCameraPermission ?? false) {
          await _scanner?.start();
        }
      } else {
        await _scanner?.stop();
      }
    } catch (_) {
      // The scanner's error UI and manual barcode field remain available.
    }
  }

  Future<void> _openFallback(String route) async {
    try {
      await _scanner?.stop();
    } catch (_) {
      // Navigation and manual entry also work when camera permission is denied.
    }
    if (mounted) context.pushReplacement(route);
  }

  double? get _portionCount {
    final count = double.tryParse(_portions.text.replaceAll(',', '.'));
    return count != null && count.isFinite && count > 0 && count <= 100
        ? count
        : null;
  }

  Future<void> _find(String raw) async {
    if (_loading || _saving || _product != null) return;
    final code = validRetailBarcode(raw);
    if (code == null) {
      setState(
        () =>
            _error = 'Masukkan barcode EAN/UPC yang valid, bukan QR atau link.',
      );
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    // Removing MobileScanner stops its controller and releases the camera
    // before showing lookup/results or opening another capture flow.
    setState(() {
      _code = code;
      _loading = true;
      _error = null;
    });
    try {
      final product = await _lookup.lookup(code);
      if (!mounted) return;
      setState(() {
        _product = product;
        _portions.text = _format(product.defaultPortions);
      });
    } on BarcodeLookupException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(
          () =>
              _error = 'Pencarian belum berhasil. Coba lagi atau cari manual.',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _scanAgain() {
    setState(() {
      _code = null;
      _product = null;
      _error = null;
      _barcode.clear();
      _portions.clear();
    });
  }

  Future<void> _save() async {
    final product = _product;
    final count = _portionCount;
    if (product == null || count == null || _saving) return;
    setState(() => _saving = true);
    try {
      await DrinkLogScope.read(context).log(product.selectionFor(count));
      if (mounted) context.go('/');
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'Catatan belum tersimpan. Coba lagi.';
        });
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _barcode.dispose();
    _portions.dispose();
    unawaited(_scanner?.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final product = _product;
    return Scaffold(
      key: const ValueKey('barcodeScanScreen'),
      appBar: AppBar(title: const Text('Scan barcode')),
      body: AuraBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(StevSpace.s5),
            children: [
              if (_code == null) ...[
                Text(
                  'Arahkan ke garis barcode pada kemasan.',
                  style: StevType.heading,
                ),
                const SizedBox(height: StevSpace.s2),
                Text(
                  'Gunakan EAN atau UPC. Pastikan garis dan angka terlihat jelas.',
                  style: StevType.body,
                ),
                const SizedBox(height: StevSpace.s4),
                if (widget.enableCamera)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(StevRadius.card),
                    child: SizedBox(
                      height: 230,
                      child: MobileScanner(
                        controller: _scanner,
                        onDetect: (capture) {
                          for (final barcode in capture.barcodes) {
                            if (![
                              BarcodeFormat.ean8,
                              BarcodeFormat.ean13,
                              BarcodeFormat.upcA,
                            ].contains(barcode.format)) {
                              continue;
                            }
                            final value = barcode.rawValue;
                            if (value != null &&
                                validRetailBarcode(value) != null) {
                              _find(value);
                              break;
                            }
                          }
                        },
                        errorBuilder: (context, error) => ColoredBox(
                          color: StevColors.ink,
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(StevSpace.s5),
                              child: Text(
                                'Kamera belum tersedia. Izinkan akses kamera, atau ketik angka barcode di bawah.',
                                textAlign: TextAlign.center,
                                style: StevType.body.copyWith(
                                  color: StevColors.onInk,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: StevSpace.s4),
                TextField(
                  key: const ValueKey('barcodeInput'),
                  controller: _barcode,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.search,
                  decoration: const InputDecoration(
                    labelText: 'Angka barcode',
                    hintText: 'Ketik angka di bawah garis barcode',
                  ),
                  onSubmitted: _find,
                ),
                const SizedBox(height: StevSpace.s3),
                StevButton(
                  key: const ValueKey('lookupBarcodeButton'),
                  label: 'Cari produk',
                  onPressed: () => _find(_barcode.text),
                ),
              ],
              if (_loading) ...[
                const Center(child: CircularProgressIndicator()),
                const SizedBox(height: StevSpace.s4),
                Text(
                  'Mencari produk $_code...',
                  textAlign: TextAlign.center,
                  style: StevType.body,
                ),
              ],
              if (product != null) ..._productContent(product),
              if (_error case final error?) ...[
                const SizedBox(height: StevSpace.s4),
                Text(
                  error,
                  key: const ValueKey('barcodeError'),
                  style: StevType.body.copyWith(color: StevColors.over),
                ),
              ],
              if (_code != null && !_loading && !_saving) ...[
                const SizedBox(height: StevSpace.s4),
                TextButton.icon(
                  key: const ValueKey('scanBarcodeAgain'),
                  onPressed: _scanAgain,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Scan barcode lain'),
                ),
                if (product == null)
                  TextButton(
                    key: const ValueKey('retryBarcodeLookup'),
                    onPressed: () => _find(_code!),
                    child: const Text('Coba cari lagi'),
                  ),
              ],
              if (!_loading && !_saving) ...[
                TextButton(
                  key: const ValueKey('barcodeScanLabel'),
                  onPressed: () => _openFallback('/scan/label'),
                  child: const Text('Scan Label Gizi'),
                ),
                TextButton(
                  onPressed: () => _openFallback('/scan/photo'),
                  child: const Text('Pakai Foto Minuman'),
                ),
                TextButton(
                  onPressed: () => _openFallback('/manual'),
                  child: const Text('Cari manual'),
                ),
                TextButton(
                  key: const ValueKey('barcodeCustomDrink'),
                  onPressed: () => _openFallback('/manual/add'),
                  child: const Text('Tambah minuman sendiri'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _productContent(BarcodeProduct product) {
    final count = _portionCount;
    return [
      SizedBox(
        height: 150,
        child: DrinkPhoto(
          drink: product.selectionFor(1).drink,
          fit: BoxFit.contain,
        ),
      ),
      const SizedBox(height: StevSpace.s4),
      Text(product.name, style: StevType.headingResult),
      Text(product.barcode, style: StevType.caption),
      const SizedBox(height: StevSpace.s3),
      Text('Sumber: ${product.source}', style: StevType.caption),
      if (product.sourceUrl.isNotEmpty)
        SelectableText(product.sourceUrl, style: StevType.micro),
      const SizedBox(height: StevSpace.s3),
      Text(
        '${_format(product.sugarGramsPerPortion)} g gula per ${product.portionLabel}',
        style: StevType.label,
      ),
      const SizedBox(height: StevSpace.s3),
      Text(
        'Cek varian dan ukuran pada kemasan. Sesuaikan porsi yang kamu minum sebelum mencatat.',
        style: StevType.body,
      ),
      const SizedBox(height: StevSpace.s4),
      TextField(
        key: const ValueKey('barcodePortions'),
        controller: _portions,
        enabled: !_saving,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: 'Jumlah porsi (${product.portionLabel} per porsi)',
          errorText: count == null
              ? 'Masukkan porsi lebih dari 0, maksimal 100.'
              : null,
          helperText: 'Bisa desimal, misalnya 0,5 porsi.',
        ),
        onChanged: (_) => setState(() {}),
      ),
      const SizedBox(height: StevSpace.s4),
      Text(
        count == null
            ? 'Total belum dapat dihitung'
            : 'Total: ${formatSugarGrams(product.sugarGramsPerPortion * count, false)} gula',
        key: const ValueKey('barcodeSugarTotal'),
        style: StevType.heading,
      ),
      const SizedBox(height: StevSpace.s4),
      StevButton(
        key: const ValueKey('logBarcodeDrink'),
        label: _saving ? 'Menyimpan...' : 'Konfirmasi & catat',
        variant: StevButtonVariant.leaf,
        onPressed: count == null || _saving ? null : _save,
      ),
    ];
  }
}

String _format(double value) =>
    value % 1 == 0 ? value.toStringAsFixed(0) : value.toString();
