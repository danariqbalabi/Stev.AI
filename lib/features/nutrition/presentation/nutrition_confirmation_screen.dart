import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/stev_tokens.dart';
import '../../../shared/widgets/stev_design_system.dart';
import '../../drinks/application/drink_log_controller.dart';
import '../domain/nutrition_label.dart';

class NutritionConfirmationScreen extends StatefulWidget {
  const NutritionConfirmationScreen({
    super.key,
    this.result,
    this.editMode = false,
    this.barcode,
  });
  final NutritionScanResult? result;
  final bool editMode;
  final String? barcode;
  @override
  State<NutritionConfirmationScreen> createState() =>
      _NutritionConfirmationScreenState();
}

class _NutritionConfirmationScreenState
    extends State<NutritionConfirmationScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name, _sugar, _serving, _volume;
  late final NutritionBasis _basis;
  late final String _identity = DateTime.now().microsecondsSinceEpoch
      .toString();
  bool _saving = false;
  String? _error;
  bool get _editing => widget.editMode || widget.result == null;

  @override
  void initState() {
    super.initState();
    final label = widget.result?.label;
    _name = TextEditingController(text: label?.productName ?? '');
    _sugar = TextEditingController(
      text: label == null ? '' : _format(label.sugarGrams),
    );
    final serving = switch (label?.basis) {
      NutritionBasis.per100Ml => 100.0,
      NutritionBasis.perPackage => label?.packageMl,
      _ => label?.servingMl,
    };
    _serving = TextEditingController(
      text: serving == null ? '' : _format(serving),
    );
    _volume = TextEditingController(
      text: label?.packageMl == null ? '' : _format(label!.packageMl!),
    );
    // Editing normalizes the displayed basis into the four explicit fields.
    // Never infer net volume from a serving or a rounded serving count.
    _basis = _editing ? NutritionBasis.perServing : label!.basis;
  }

  double? _number(String raw) {
    final value = double.tryParse(raw.trim().replaceAll(',', '.'));
    return value != null && value.isFinite ? value : null;
  }

  double? get _total {
    final sugar = _number(_sugar.text),
        volume = _number(_volume.text),
        serving = _number(_serving.text);
    if (sugar == null ||
        (_basis != NutritionBasis.perPackage &&
            (volume == null || serving == null))) {
      return null;
    }
    try {
      return nutritionSugarFor(
        sugarGrams: sugar,
        basis: _basis,
        consumedFraction: 1,
        packageMl: volume,
        servingMl: _basis == NutritionBasis.perServing ? serving : null,
      );
    } on FormatException {
      return null;
    }
  }

  void _edited(String _) => setState(() => _error = null);

  void _editNumbers() {
    final original = widget.result!;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => NutritionConfirmationScreen(
          editMode: true,
          result: NutritionScanResult(
            photoBytes: original.photoBytes,
            barcode: original.barcode,
            label: NutritionLabel(
              productName: _name.text,
              sugarGrams: original.label.sugarGrams,
              basis: original.label.basis,
              servingMl: original.label.servingMl,
              packageMl: original.label.packageMl,
              servingsPerPackage: original.label.servingsPerPackage,
              sugarText: original.label.sugarText,
              basisText: original.label.basisText,
              confidence: original.label.confidence,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;
    final grams = _total;
    if (grams == null) return;
    setState(() => _saving = true);
    try {
      await DrinkLogScope.read(context).log(
        nutritionSelection(
          name: _name.text,
          identity: _identity,
          grams: grams,
          fromPhoto: widget.result != null && !widget.editMode,
        ),
      );
      if (mounted) context.go('/');
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'Belum tersimpan. Coba lagi.';
        });
      }
    }
  }

  void _retake() {
    if (context.canPop()) {
      context.pop(true);
    } else {
      context.go(
        '/scan/label',
        extra: widget.result?.barcode ?? widget.barcode,
      );
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _sugar.dispose();
    _serving.dispose();
    _volume.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = _total;
    return Scaffold(
      key: const ValueKey('nutritionConfirmationScreen'),
      appBar: _editing ? AppBar(title: const Text('Isi dari label')) : null,
      body: AuraBackground(
        child: SafeArea(
          child: Form(
            key: _form,
            child: ListView(
              key: const ValueKey('nutritionFormList'),
              children: [
                if (!_editing)
                  Stack(
                    children: [
                      SizedBox(
                        height: 260,
                        width: double.infinity,
                        child: Image.memory(
                          widget.result!.photoBytes,
                          fit: BoxFit.contain,
                        ),
                      ),
                      Positioned(
                        top: StevSpace.s3,
                        left: StevSpace.s5,
                        child: IconButton.filledTonal(
                          style: IconButton.styleFrom(
                            backgroundColor: StevColors.photoButton,
                            foregroundColor: StevColors.ink,
                          ),
                          key: const ValueKey('retakeNutritionLabel'),
                          tooltip: 'Foto ulang label',
                          onPressed: _saving ? null : _retake,
                          icon: const Icon(Icons.arrow_back_ios_new_rounded),
                        ),
                      ),
                    ],
                  ),
                Padding(
                  padding: const EdgeInsets.all(StevSpace.s5),
                  child: Column(
                    children: [
                      if (_editing)
                        GlassCard(
                          padding: const EdgeInsets.all(StevSpace.s5),
                          child: Column(
                            children: [
                              _nameField(),
                              const SizedBox(height: StevSpace.s4),
                              _numericField(
                                'nutritionSugar',
                                _sugar,
                                'Gula per sajian (g)',
                                0,
                                1000,
                              ),
                              const SizedBox(height: StevSpace.s4),
                              _numericField(
                                'nutritionServingMl',
                                _serving,
                                'Takaran saji (ml)',
                                0.001,
                                10000,
                              ),
                              const SizedBox(height: StevSpace.s4),
                              _numericField(
                                'nutritionVolume',
                                _volume,
                                'Isi bersih kemasan (ml)',
                                0.001,
                                10000,
                              ),
                            ],
                          ),
                        )
                      else
                        _nameField(),
                      const SizedBox(height: StevSpace.s5),
                      if (!_editing || total != null)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(StevSpace.s7),
                          decoration: BoxDecoration(
                            color: StevColors.card,
                            borderRadius: BorderRadius.circular(
                              StevRadius.card,
                            ),
                            boxShadow: StevShadows.elevCard,
                          ),
                          child: Column(
                            children: [
                              Text(
                                total == null
                                    ? 'Lengkapi ukuran kemasan'
                                    : '${_display(total)} g',
                                key: const ValueKey('nutritionTotal'),
                                textAlign: TextAlign.center,
                                style: total == null
                                    ? StevType.heading
                                    : StevType.number,
                              ),
                              if (!_editing && total != null) ...[
                                const SizedBox(height: StevSpace.s2),
                                Text(
                                  _basis == NutritionBasis.perPackage
                                      ? 'Gula seluruh kemasan'
                                      : '${_display(_number(_sugar.text)!)} g per ${_display(_number(_serving.text)!)} ml · isi ${_display(_number(_volume.text)!)} ml',
                                  textAlign: TextAlign.center,
                                  style: StevType.caption.copyWith(
                                    color: StevColors.ink2,
                                  ),
                                ),
                              ],
                              if (!_editing)
                                TextButton(
                                  key: const ValueKey('editNutritionNumbers'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: StevColors.ink2,
                                    textStyle: StevType.caption,
                                  ),
                                  onPressed: _saving ? null : _editNumbers,
                                  child: const Text('Ubah angka'),
                                ),
                            ],
                          ),
                        ),
                      const SizedBox(height: StevSpace.s7),
                      if (_error != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: StevSpace.s3),
                          child: Text(_error!, style: StevType.caption),
                        ),
                      StevButton(
                        key: const ValueKey('logNutritionDrink'),
                        label: _saving
                            ? 'Menyimpan…'
                            : _editing
                            ? 'Catat'
                            : total == null
                            ? 'Lengkapi ukuran'
                            : 'Benar, catat',
                        onPressed: _saving
                            ? null
                            : !_editing && total == null
                            ? _editNumbers
                            : total == null
                            ? null
                            : _save,
                      ),
                      const SizedBox(height: StevSpace.s4),
                      Text(
                        'Disimpan untuk kamu saja',
                        textAlign: TextAlign.center,
                        style: StevType.caption.copyWith(
                          color: StevColors.ink2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _nameField() => TextFormField(
    key: const ValueKey('nutritionName'),
    controller: _name,
    enabled: !_saving,
    maxLength: 120,
    decoration: const InputDecoration(
      labelText: 'Nama minuman',
      counterText: '',
    ),
    validator: (value) =>
        value == null || value.trim().isEmpty ? 'Isi nama minuman.' : null,
    onChanged: _edited,
  );

  Widget _numericField(
    String keyName,
    TextEditingController controller,
    String label,
    double min,
    double max,
  ) => TextFormField(
    key: ValueKey(keyName),
    controller: controller,
    enabled: !_saving,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    decoration: InputDecoration(labelText: label),
    validator: (raw) {
      final value = _number(raw ?? '');
      return value == null || value < min || value > max
          ? 'Periksa angka pada label.'
          : null;
    },
    onChanged: _edited,
  );
}

String _format(double value) =>
    value % 1 == 0 ? value.toStringAsFixed(0) : value.toString();
String _display(double value) =>
    (value % 1 == 0 ? value.toStringAsFixed(0) : value.toStringAsFixed(1))
        .replaceAll('.', ',');
