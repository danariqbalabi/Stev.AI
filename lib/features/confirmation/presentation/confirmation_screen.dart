import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/stev_tokens.dart';
import '../../drinks/data/drink_catalog.dart';
import '../../drinks/domain/drink.dart';

class ConfirmationScreen extends StatelessWidget {
  const ConfirmationScreen({super.key, this.capturedPhoto});

  final Uint8List? capturedPhoto;

  static const guesses = [
    DrinkCatalog.kopiSusuKalengNescafe,
    DrinkCatalog.esKopiSusuGulaAren,
    DrinkCatalog.bobaMilkTea,
  ];

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        key: const ValueKey('confirmationScreen'),
        backgroundColor: StevColors.ink,
        body: LayoutBuilder(
          builder: (context, constraints) {
            final sheetTop = (constraints.maxHeight - 574).clamp(250.0, 320.0);
            return Stack(
              fit: StackFit.expand,
              children: [
                _CapturedPhoto(bytes: capturedPhoto),
                const _PhotoShade(),
                Positioned(
                  left: 0,
                  right: 0,
                  top: sheetTop,
                  bottom: 0,
                  child: const _ConfirmationSheet(),
                ),
                const _PhotoHeader(),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CapturedPhoto extends StatelessWidget {
  const _CapturedPhoto({this.bytes});

  final Uint8List? bytes;

  @override
  Widget build(BuildContext context) {
    final image = bytes == null
        ? Image.asset(
            DrinkCatalog.kopiSusuKalengNescafe.photoAsset,
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
          )
        : Image.memory(
            bytes!,
            fit: BoxFit.cover,
            alignment: Alignment.center,
            gaplessPlayback: true,
          );

    return Align(
      alignment: Alignment.topCenter,
      child: SizedBox(
        width: double.infinity,
        height: 430,
        child: ColoredBox(color: StevColors.ink, child: image),
      ),
    );
  }
}

class _PhotoShade extends StatelessWidget {
  const _PhotoShade();

  @override
  Widget build(BuildContext context) {
    return const Align(
      alignment: Alignment.topCenter,
      child: SizedBox(
        height: 180,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x8A111113), Color(0x00111113)],
            ),
          ),
        ),
      ),
    );
  }
}

class _PhotoHeader extends StatelessWidget {
  const _PhotoHeader();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          StevSpace.s5,
          StevSpace.s2,
          StevSpace.s5,
          0,
        ),
        child: SizedBox(
          height: StevSize.roundButton,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: _PhotoBackButton(onPressed: () => context.pop()),
              ),
              Text(
                'Ini minuman apa?',
                style: StevType.label.copyWith(
                  color: StevColors.onInk,
                  fontWeight: StevType.w700,
                  shadows: const [
                    Shadow(color: Color(0x80111113), blurRadius: 10),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhotoBackButton extends StatelessWidget {
  const _PhotoBackButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: StevGlass.photoButtonBlur,
          sigmaY: StevGlass.photoButtonBlur,
        ),
        child: Material(
          color: StevColors.photoButton,
          child: InkWell(
            key: const ValueKey('confirmationBackButton'),
            onTap: onPressed,
            customBorder: const CircleBorder(),
            child: const SizedBox.square(
              dimension: StevSize.roundButton,
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 19,
                color: StevColors.onInk,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ConfirmationSheet extends StatelessWidget {
  const _ConfirmationSheet();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(StevRadius.sheet),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: StevGlass.blurSigma,
          sigmaY: StevGlass.blurSigma,
        ),
        child: DecoratedBox(
          decoration: const BoxDecoration(
            color: StevColors.glass,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(StevRadius.sheet),
            ),
            boxShadow: StevShadows.elevGlass,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              StevSpace.s5,
              StevSpace.s7,
              StevSpace.s5,
              StevSpace.s7,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pilih yang paling cocok', style: StevType.headingResult),
                const SizedBox(height: StevSpace.s5),
                for (
                  var index = 0;
                  index < ConfirmationScreen.guesses.length;
                  index++
                ) ...[
                  _GuessCard(
                    key: index == 0
                        ? const ValueKey('showResultButton')
                        : ValueKey(
                            'guess-${ConfirmationScreen.guesses[index].id}',
                          ),
                    drink: ConfirmationScreen.guesses[index],
                    recommended: index == 0,
                  ),
                  if (index < ConfirmationScreen.guesses.length - 1)
                    const SizedBox(height: StevSpace.s3),
                ],
                const SizedBox(height: StevSpace.s5),
                Center(
                  child: _ManualSearchButton(
                    onPressed: () => context.push('/manual'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GuessCard extends StatelessWidget {
  const _GuessCard({super.key, required this.drink, required this.recommended});

  final Drink drink;
  final bool recommended;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${drink.name}${recommended ? ', paling cocok' : ''}',
      child: Container(
        height: StevSize.guessCard,
        decoration: BoxDecoration(
          color: StevColors.card,
          borderRadius: BorderRadius.circular(StevRadius.row),
          boxShadow: [...StevShadows.pressCard, ...StevShadows.elevCard],
        ),
        clipBehavior: Clip.antiAlias,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => context.push('/result', extra: drink),
            child: Row(
              children: [
                SizedBox.square(
                  dimension: StevSize.guessCard,
                  child: ColoredBox(
                    color: StevColors.canvas,
                    child: Image.asset(
                      drink.photoAsset,
                      fit: drink.photoFit,
                      alignment: drink.photoAlignment,
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: StevSpace.s4),
                    child: Text(
                      drink.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: StevType.label,
                    ),
                  ),
                ),
                SizedBox(
                  width: 48,
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: StevColors.ink2,
                        size: 24,
                      ),
                      if (recommended)
                        Positioned(
                          top: 8,
                          right: 10,
                          child: Text(
                            'Paling cocok',
                            softWrap: false,
                            style: StevType.micro.copyWith(
                              color: StevColors.ink2,
                            ),
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
}

class _ManualSearchButton extends StatelessWidget {
  const _ManualSearchButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: StevColors.card,
        borderRadius: BorderRadius.circular(StevRadius.small),
        boxShadow: StevShadows.pressCard,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: const ValueKey('manualSearchButton'),
          onTap: onPressed,
          borderRadius: BorderRadius.circular(StevRadius.small),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: StevSpace.s4,
              vertical: 13,
            ),
            child: Text(
              'Bukan ini? Cari manual',
              style: StevType.caption.copyWith(
                color: StevColors.ink2,
                fontWeight: StevType.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
