import 'package:flutter/material.dart';

enum ScanMode {
  photo('Foto', '/scan', Icons.camera_alt_outlined),
  barcode('Barcode', '/scan/barcode', Icons.qr_code_scanner),
  label('Label Gizi', '/scan/label', Icons.receipt_long_outlined);

  const ScanMode(this.title, this.route, this.icon);
  final String title;
  final String route;
  final IconData icon;
}

/// Inline modes keep the photo camera one tap away from the dashboard.
class ScanModeSwitcher extends StatelessWidget {
  const ScanModeSwitcher({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final ScanMode selected;
  final ValueChanged<ScanMode>? onChanged;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Mode scan',
    child: Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xff161616),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          for (final mode in ScanMode.values)
            Expanded(
              child: Semantics(
                selected: mode == selected,
                child: TextButton(
                  key: ValueKey('scanMode-${mode.name}'),
                  onPressed: onChanged == null || mode == selected
                      ? null
                      : () => onChanged!(mode),
                  style: TextButton.styleFrom(
                    minimumSize: const Size(0, 48),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 8,
                    ),
                    backgroundColor: mode == selected
                        ? Colors.white
                        : Colors.transparent,
                    foregroundColor: Colors.white,
                    disabledForegroundColor: mode == selected
                        ? Colors.black
                        : Colors.white54,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(mode.icon, size: 19),
                      const SizedBox(height: 3),
                      Text(
                        mode.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}
