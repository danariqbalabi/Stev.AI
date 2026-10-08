import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/placeholder_notice.dart';

class ScanScreen extends StatelessWidget {
  const ScanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan minuman')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            children: [
              const PlaceholderNotice(
                message: 'Kamera asli akan ditambahkan pada fitur berikutnya.',
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.local_drink_outlined,
                        color: Colors.white,
                        size: 72,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Arahkan kamera ke minuman\natau menu',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                key: const ValueKey('captureButton'),
                onPressed: () => context.push('/confirmation'),
                icon: const Icon(Icons.camera_alt_outlined),
                label: const Text('Ambil foto demo'),
              ),
              TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Pencarian manual masuk roadmap MVP.'),
                    ),
                  );
                },
                child: const Text('Cari manual'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
