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
import '../../scan/presentation/scan_mode_switcher.dart';

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
  final _portions = TextEditingController();
  final _volume = TextEditingController();
  double _fraction = 1;
  bool _confirmed = false;

  double? get _volumeMl {
    final ml = double.tryParse(_volume.text.replaceAll(',', '.'));
    return ml != null && ml.isFinite && ml > 0 && ml <= 10000 ? ml : null;
  }

  void _edited() => setState(() => _confirmed = false);

  double? get _total {
    final product = _product;
    if (product == null) return null;
    if (product.portionMl == null) {
      return _portionCount == null
          ? null
          : product.sugarGramsPerPortion * _portionCount!;
    }
    if (_volumeMl == null) return null;
    try {
      return product.selectionForVolume(_volumeMl!, _fraction).grams;
    } on FormatException {
      return null;
    }
  }

  String? _code;
  String? _error;
  DateTime? _retryAt;
  Timer? _retryTimer;
  int get _retrySeconds {
    final remaining =
        _retryAt?.difference((widget.now ?? DateTime.now)()).inMilliseconds ??
        0;
    return remaining > 0 ? (remaining / 1000).ceil() : 0;
  }

  BarcodeProduct? _product;
  bool _loading = false;
  bool _saving = false;
  bool _navigating = false;
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
    if (_navigating) return;
    setState(() => _navigating = true);
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
    if (_loading || _saving || _navigating || _product != null) return;
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
        _volume.text = product.packageMl == null
            ? ''
            : _format(product.packageMl!);
        _fraction = 1;
        _confirmed = false;
      });
    } on BarcodeLookupException catch (error) {
      if (mounted) {
        _retryTimer?.cancel();
        setState(() {
          _error = error.message;
          _retryAt = error.retryAt;
        });
        if (_retrySeconds > 0) {
          _retryTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
            if (!mounted || _retrySeconds == 0) timer.cancel();
            if (mounted) setState(() {});
          });
        }
      }
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
      _volume.clear();
      _fraction = 1;
      _confirmed = false;
    });
  }

  Future<void> _save() async {
    final product = _product;
    final count = _portionCount;
    if (product == null ||
        count == null ||
        _total == null ||
        !_confirmed ||
        _saving) {
      return;
    }
    setState(() => _saving = true);
    try {
      await DrinkLogScope.read(context).log(
        product.portionMl == null
            ? product.selectionFor(count)
            : product.selectionForVolume(_volumeMl!, _fraction),
      );
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
    _volume.dispose();
    _retryTimer?.cancel();
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
              ScanModeSwitcher(
                selected: ScanMode.barcode,
                onChanged: _loading || _saving || _navigating
                    ? null
                    : (mode) => _openFallback(mode.route),
              ),
              const SizedBox(height: StevSpace.s4),
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
                    onPressed: _retrySeconds > 0 ? null : () => _find(_code!),
                    child: Text(
                      _retrySeconds > 0
                          ? 'Coba lagi dalam $_retrySeconds dtk'
                          : 'Coba cari lagi',
                    ),
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
                  key: const ValueKey('barcodeManualLabel'),
                  onPressed: () => _openFallback('/nutrition/manual'),
                  child: const Text('Isi label manual'),
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
    final total = _total;
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
      if (product.cachedAt != null)
        Text(
          'Data tersimpan di perangkat (maksimal 7 hari). Tetap cocokkan dengan label kemasan.',
          key: const ValueKey('barcodeCachedNotice'),
          style: StevType.caption,
        ),
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
      if (product.portionMl != null) ...[
        Text(
          'Ukuran dari database: ${_format(product.packageMl!)} ml. Cocokkan dengan isi bersih pada botolmu.',
          style: StevType.body,
        ),
        const SizedBox(height: StevSpace.s3),
        TextField(
          key: const ValueKey('barcodeVolume'),
          controller: _volume,
          enabled: !_saving,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'Ukuran botolmu (ml)',
            errorText: _volumeMl == null
                ? 'Isi volume lebih dari 0, maksimal 10000 ml.'
                : null,
          ),
          onChanged: (_) => _edited(),
        ),
        if (_volumeMl != null && product.sizeCorrected(_volumeMl!))
          Text(
            'Ukuran berbeda dari database. Ini estimasi memakai kadar gula produk yang sama, bukan verifikasi varian. Jika varian atau angka gula berbeda, gunakan Scan Label Gizi.',
            key: const ValueKey('barcodeVolumeWarning'),
            style: StevType.body.copyWith(color: StevColors.over),
          ),
        const SizedBox(height: StevSpace.s3),
        DropdownButtonFormField<double>(
          key: const ValueKey('barcodeConsumedFraction'),
          initialValue: _fraction,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Bagian yang diminum'),
          items: const [
            DropdownMenuItem(value: 1, child: Text('Seluruh kemasan')),
            DropdownMenuItem(value: 0.5, child: Text('Setengah kemasan')),
            DropdownMenuItem(value: 0.25, child: Text('Seperempat kemasan')),
          ],
          onChanged: _saving
              ? null
              : (value) {
                  if (value != null) {
                    _fraction = value;
                    _edited();
                  }
                },
        ),
      ] else
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
          onChanged: (_) => _edited(),
        ),
      const SizedBox(height: StevSpace.s4),
      Text(
        total == null
            ? 'Total belum dapat dihitung'
            : 'Total: ${formatSugarGrams(total, false)} gula',
        key: const ValueKey('barcodeSugarTotal'),
        style: StevType.heading,
      ),
      const SizedBox(height: StevSpace.s4),
      Material(
        color: Colors.transparent,
        child: CheckboxListTile(
          key: const ValueKey('confirmBarcodeSize'),
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          title: const Text(
            'Varian minuman, ukuran kemasan, dan bagian yang diminum sudah sesuai.',
          ),
          value: _confirmed,
          onChanged: total == null || _saving
              ? null
              : (value) => setState(() => _confirmed = value ?? false),
        ),
      ),
      StevButton(
        key: const ValueKey('logBarcodeDrink'),
        label: _saving ? 'Menyimpan...' : 'Konfirmasi & catat',
        variant: StevButtonVariant.leaf,
        onPressed: total == null || !_confirmed || _saving ? null : _save,
      ),
    ];
  }
}

String _format(double value) =>
    value % 1 == 0 ? value.toStringAsFixed(0) : value.toString();
