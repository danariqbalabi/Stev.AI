import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/stev_tokens.dart';
import '../../../shared/widgets/stev_design_system.dart';
import '../../drinks/application/drink_log_controller.dart';
import '../../drinks/domain/drink.dart';
import '../domain/nutrition_label.dart';

class NutritionConfirmationScreen extends StatefulWidget {
  const NutritionConfirmationScreen({super.key, this.result});

  final NutritionScanResult? result;

  @override
  State<NutritionConfirmationScreen> createState() =>
      _NutritionConfirmationScreenState();
}

class _NutritionConfirmationScreenState
    extends State<NutritionConfirmationScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _sugar;
  late final TextEditingController _servings;
  late final TextEditingController _volume;
  late final TextEditingController _servingMl;
  late bool _useVolume;
  late NutritionBasis _basis;
  double _fraction = 1;
  bool _confirmed = false;
  bool _saving = false;
  String? _error;
  late final String _identity = DateTime.now().microsecondsSinceEpoch
      .toString();

  @override
  void initState() {
    super.initState();
    final label = widget.result?.label;
    _name = TextEditingController(
      text: label?.productName ?? 'Minuman kemasan',
    );
    _sugar = TextEditingController(
      text: label == null ? '' : _format(label.sugarGrams),
    );
    _servings = TextEditingController(
      text: label?.servingsPerPackage == null
          ? ''
          : _format(label!.servingsPerPackage!),
    );
    _volume = TextEditingController(
      text: label?.packageMl == null ? '' : _format(label!.packageMl!),
    );
    _basis = label?.basis ?? NutritionBasis.perServing;
    _servingMl = TextEditingController(
      text: label?.servingMl == null ? '' : _format(label!.servingMl!),
    );
    _useVolume =
        widget.result == null ||
        label?.servingMl != null ||
        label?.packageMl != null;
  }

  double? _number(String raw) {
    final value = double.tryParse(raw.trim().replaceAll(',', '.'));
    return value != null && value.isFinite ? value : null;
  }

  double? get _total {
    final sugar = _number(_sugar.text);
    if (sugar == null) return null;
    try {
      return nutritionSugarFor(
        sugarGrams: sugar,
        basis: _basis,
        consumedFraction: _fraction,
        servingsPerPackage: _number(_servings.text),
        packageMl:
            _basis == NutritionBasis.per100Ml ||
                (_basis == NutritionBasis.perServing && _useVolume)
            ? _number(_volume.text)
            : null,
        servingMl: _basis == NutritionBasis.perServing && _useVolume
            ? _number(_servingMl.text)
            : null,
      );
    } on FormatException {
      return null;
    }
  }

  bool get _volumeConflict =>
      _basis == NutritionBasis.perServing &&
      nutritionVolumeMismatch(
        servingMl: _number(_servingMl.text),
        servingsPerPackage: _number(_servings.text),
        packageMl: _number(_volume.text),
      );

  bool get _volumeReady =>
      _basis != NutritionBasis.perServing ||
      !_useVolume ||
      (_number(_servingMl.text) != null && _number(_volume.text) != null);

  void _edited() => setState(() {
    _confirmed = false;
    _error = null;
  });

  Future<void> _save() async {
    if (_saving ||
        !_confirmed ||
        !_volumeReady ||
        !_form.currentState!.validate()) {
      return;
    }
    final grams = _total;
    if (grams == null) return;
    setState(() => _saving = true);
    try {
      await DrinkLogScope.read(context).log(
        nutritionSelection(
          name: _name.text,
          identity: _identity,
          grams: grams,
          fromPhoto: widget.result != null,
        ),
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
    _name.dispose();
    _sugar.dispose();
    _servings.dispose();
    _volume.dispose();
    _servingMl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = _volumeReady ? _total : null;
    return Scaffold(
      key: const ValueKey('nutritionConfirmationScreen'),
      appBar: AppBar(
        title: Text(
          widget.result == null ? 'Isi label manual' : 'Cek hasil label',
        ),
      ),
      body: AuraBackground(
        child: SafeArea(
          child: Form(
            key: _form,
            child: ListView(
              key: const ValueKey('nutritionFormList'),
              padding: const EdgeInsets.all(StevSpace.s5),
              children: [
                if (widget.result case final result?)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(StevRadius.card),
                    child: SizedBox(
                      height: 200,
                      child: Image.memory(
                        result.photoBytes,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                const SizedBox(height: StevSpace.s4),
                Text(
                  'Periksa dulu, baru catat.',
                  style: StevType.headingResult,
                ),
                const SizedBox(height: StevSpace.s2),
                Text(
                  widget.result == null
                      ? 'Salin angka Gula/Gula total dan keterangan takaran saji dari label kemasan.'
                      : 'Dibaca dari foto label, belum diverifikasi Stev.AI. Cocokkan angka dan kolom takaran saji dengan foto; koreksi jika perlu.',
                  style: StevType.body,
                ),
                const SizedBox(height: StevSpace.s3),
                if (widget.result case final result?)
                  GlassCard(
                    padding: const EdgeInsets.all(StevSpace.s4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Teks yang terbaca', style: StevType.label),
                        Text(result.label.sugarText, style: StevType.body),
                        Text(result.label.basisText, style: StevType.caption),
                        if (result.label.servingMl case final ml?)
                          Text(
                            'Takaran saji: ${_format(ml)} ml',
                            style: StevType.caption,
                          ),
                      ],
                    ),
                  ),
                const SizedBox(height: StevSpace.s4),
                TextFormField(
                  key: const ValueKey('nutritionName'),
                  controller: _name,
                  enabled: !_saving,
                  maxLength: 120,
                  decoration: const InputDecoration(labelText: 'Nama minuman'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Isi nama minuman.'
                      : null,
                  onChanged: (_) => _edited(),
                ),
                const SizedBox(height: StevSpace.s3),
                DropdownButtonFormField<NutritionBasis>(
                  key: ValueKey('nutritionBasis-${_basis.name}'),
                  initialValue: _basis,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Angka gula pada label berlaku untuk',
                  ),
                  items: [
                    for (final basis in NutritionBasis.values)
                      DropdownMenuItem(value: basis, child: Text(basis.label)),
                  ],
                  onChanged: _saving
                      ? null
                      : (value) {
                          if (value != null) {
                            _basis = value;
                            _edited();
                          }
                        },
                ),
                const SizedBox(height: StevSpace.s3),
                _numericField(
                  keyName: 'nutritionSugar',
                  controller: _sugar,
                  label: 'Gula ${_basis.label.toLowerCase()} (g)',
                  min: 0,
                  max: _basis == NutritionBasis.per100Ml ? 100 : 1000,
                ),
                if (_basis == NutritionBasis.perServing) ...[
                  Material(
                    color: Colors.transparent,
                    child: SwitchListTile(
                      key: const ValueKey('nutritionUseVolume'),
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Hitung dari volume botol (ml)'),
                      subtitle: const Text(
                        'Matikan jika takaran saji tidak tersedia dalam ml.',
                      ),
                      value: _useVolume,
                      onChanged: _saving
                          ? null
                          : (value) {
                              _useVolume = value;
                              _edited();
                            },
                    ),
                  ),
                  if (_useVolume) ...[
                    _numericField(
                      keyName: 'nutritionServingMl',
                      controller: _servingMl,
                      label: 'Takaran saji pada label (ml)',
                      min: 0.001,
                      max: 10000,
                    ),
                    const SizedBox(height: StevSpace.s3),
                    _numericField(
                      keyName: 'nutritionVolume',
                      controller: _volume,
                      label: 'Ukuran botolmu / isi bersih (ml)',
                      min: 0.001,
                      max: 10000,
                    ),
                    const SizedBox(height: StevSpace.s2),
                    Text(
                      'Baca isi bersih pada kemasan, bukan angka takaran saji. Total dihitung dari volume botol, bukan jumlah sajian yang mungkin dibulatkan.',
                      style: StevType.caption,
                    ),
                  ] else ...[
                    const SizedBox(height: StevSpace.s3),
                    _numericField(
                      keyName: 'nutritionServings',
                      controller: _servings,
                      label: 'Jumlah sajian per kemasan',
                      min: 0.001,
                      max: 100,
                    ),
                    Text(
                      'Contoh: 9 g per sajian × 2 sajian = 18 g per kemasan.',
                      style: StevType.caption,
                    ),
                  ],
                  if (_volumeConflict)
                    Text(
                      'Takaran saji × jumlah sajian menghasilkan ${_format(_number(_servingMl.text)! * _number(_servings.text)!)} ml, tetapi volume botol ${_volume.text} ml. '
                      '${_useVolume ? 'Hitungan memakai volume botol yang kamu isi' : 'Hitungan memakai jumlah sajian pada label'}. Periksa dan konfirmasi ukuran serta angka gula sebelum mencatat.',
                      key: const ValueKey('nutritionVolumeWarning'),
                      style: StevType.body.copyWith(color: StevColors.over),
                    ),
                  if (_useVolume && _number(_servings.text) != null)
                    Text(
                      'Jumlah sajian terbaca: ${_servings.text}. Tidak dipakai saat menghitung berdasarkan volume botol.',
                      style: StevType.caption,
                    ),
                ],
                if (_basis == NutritionBasis.per100Ml) ...[
                  const SizedBox(height: StevSpace.s3),
                  _numericField(
                    keyName: 'nutritionVolume',
                    controller: _volume,
                    label: 'Volume seluruh kemasan (ml)',
                    min: 0.001,
                    max: 10000,
                  ),
                ],
                const SizedBox(height: StevSpace.s4),
                DropdownButtonFormField<double>(
                  key: const ValueKey('nutritionConsumedFraction'),
                  isExpanded: true,
                  initialValue: _fraction,
                  decoration: const InputDecoration(
                    labelText: 'Bagian kemasan yang diminum',
                  ),
                  items: const [
                    DropdownMenuItem(value: 1, child: Text('Seluruh kemasan')),
                    DropdownMenuItem(
                      value: 0.75,
                      child: Text('Tiga perempat kemasan'),
                    ),
                    DropdownMenuItem(
                      value: 0.5,
                      child: Text('Setengah kemasan'),
                    ),
                    DropdownMenuItem(
                      value: 0.25,
                      child: Text('Seperempat kemasan'),
                    ),
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
                const SizedBox(height: StevSpace.s4),
                Text(
                  total == null
                      ? 'Lengkapi data untuk menghitung total.'
                      : 'Gula yang dicatat: ${formatSugarGrams(total, false)}',
                  key: const ValueKey('nutritionTotal'),
                  style: StevType.heading,
                ),
                if (_basis == NutritionBasis.perServing &&
                    _useVolume &&
                    total != null)
                  Text(
                    '${_sugar.text} g ÷ ${_servingMl.text} ml × ${_volume.text} ml × ${_format(_fraction)} bagian',
                    key: const ValueKey('nutritionVolumeFormula'),
                    style: StevType.caption,
                  ),
                Material(
                  color: Colors.transparent,
                  child: CheckboxListTile(
                    key: const ValueKey('confirmNutritionLabel'),
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      _volumeConflict
                          ? 'Saya sudah memeriksa perbedaan takaran, volume botol, dan dasar hitungan di atas.'
                          : 'Angka gula, takaran saji, ukuran kemasan, dan bagian yang diminum sudah sesuai.',
                    ),
                    value: _confirmed,
                    onChanged: total == null || _saving
                        ? null
                        : (value) =>
                              setState(() => _confirmed = value ?? false),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ),
                if (_error case final error?)
                  Text(
                    error,
                    style: StevType.body.copyWith(color: StevColors.over),
                  ),
                StevButton(
                  key: const ValueKey('logNutritionDrink'),
                  label: _saving ? 'Menyimpan...' : 'Konfirmasi & catat',
                  variant: StevButtonVariant.leaf,
                  onPressed: total == null || !_confirmed || _saving
                      ? null
                      : _save,
                ),
                TextButton(
                  onPressed: _saving
                      ? null
                      : () {
                          if (context.canPop()) {
                            context.pop(true);
                          } else {
                            context.go('/scan/label');
                          }
                        },
                  child: const Text('Foto ulang label'),
                ),
                Text(
                  'Hanya hasil yang kamu konfirmasi masuk catatan pribadi. Foto label tidak disimpan ke katalog publik.',
                  style: StevType.caption,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _numericField({
    required String keyName,
    required TextEditingController controller,
    required String label,
    required double min,
    required double max,
  }) => TextFormField(
    key: ValueKey(keyName),
    controller: controller,
    enabled: !_saving,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    decoration: InputDecoration(labelText: label),
    autovalidateMode: AutovalidateMode.onUserInteraction,
    validator: (raw) {
      final value = _number(raw ?? '');
      return value == null || value < min || value > max
          ? 'Masukkan angka ${_format(min)}–${_format(max)}.'
          : null;
    },
    onChanged: (_) => _edited(),
  );
}

String _format(double value) =>
    value % 1 == 0 ? value.toStringAsFixed(0) : value.toString();
