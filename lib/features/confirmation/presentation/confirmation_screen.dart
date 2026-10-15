import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/stev_tokens.dart';
import '../../../shared/widgets/drink_photo.dart';
import '../../drinks/data/drink_catalog.dart';
import '../../recognition/domain/drink_recognition.dart';

class ConfirmationScreen extends StatelessWidget {
  const ConfirmationScreen({
    super.key,
    this.capturedPhoto,
    this.candidates = fallbackGuesses,
  });

  final Uint8List? capturedPhoto;
  final List<DrinkRecognitionCandidate> candidates;

  static const fallbackGuesses = [
    DrinkRecognitionCandidate(
      drink: DrinkCatalog.kopiSusuKalengNescafe,
      confidence: 0.92,
    ),
    DrinkRecognitionCandidate(
      drink: DrinkCatalog.esKopiSusuGulaAren,
      confidence: 0.76,
    ),
    DrinkRecognitionCandidate(
      drink: DrinkCatalog.bobaMilkTea,
      confidence: 0.63,
    ),
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
                  child: _ConfirmationSheet(
                    guesses: candidates.isEmpty
                        ? fallbackGuesses
                        : candidates.take(3).toList(growable: false),
                  ),
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
          child: Align(
            alignment: Alignment.centerLeft,
            child: _PhotoBackButton(onPressed: () => context.pop()),
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
  const _ConfirmationSheet({required this.guesses});

  final List<DrinkRecognitionCandidate> guesses;

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
                for (var index = 0; index < guesses.length; index++) ...[
                  _GuessCard(
                    key: index == 0
                        ? const ValueKey('showResultButton')
                        : ValueKey('guess-${guesses[index].drink.id}'),
                    candidate: guesses[index],
                    recommended: index == 0,
                  ),
                  if (index < guesses.length - 1)
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
  const _GuessCard({
    super.key,
    required this.candidate,
    required this.recommended,
  });

  final DrinkRecognitionCandidate candidate;
  final bool recommended;

  @override
  Widget build(BuildContext context) {
    final drink = candidate.drink;
    return Semantics(
      button: true,
      label:
          '${drink.name}, keyakinan ${candidate.confidencePercent} persen${recommended ? ', paling cocok' : ''}',
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
                    child: DrinkPhoto(drink: drink),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: StevSpace.s4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          drink.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: StevType.label,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${candidate.confidencePercent}% cocok',
                          style: StevType.micro.copyWith(
                            color: StevColors.ink2,
                          ),
                        ),
                      ],
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
