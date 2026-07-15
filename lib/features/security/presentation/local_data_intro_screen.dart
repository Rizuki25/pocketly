import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';

class LocalDataIntroScreen extends StatelessWidget {
  const LocalDataIntroScreen({
    required this.onBack,
    required this.onContinue,
    super.key,
  });

  final VoidCallback onBack;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('local-data-screen'),
      body: SafeArea(
        child: Column(
          children: [
            _PageHeader(onBack: onBack, label: 'Data & pemulihan'),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _LocalDataArtwork(),
                    const SizedBox(height: 30),
                    Text(
                      'Data tetap dekat\ndenganmu.',
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Pocketly berjalan dalam mode lokal. Target dan transaksi '
                      'disimpan di perangkat ini, bukan di akun cloud.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.ink.withValues(alpha: 0.64),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const _InfoTile(
                      icon: Icons.phone_android_rounded,
                      title: 'Tersimpan di perangkat',
                      description:
                          'Aplikasi tetap dapat dipakai tanpa koneksi internet.',
                    ),
                    const SizedBox(height: 12),
                    const _InfoTile(
                      icon: Icons.lock_outline_rounded,
                      title: 'Backup terenkripsi',
                      description:
                          'Backup dibuat secara manual dan dilindungi kredensial terpisah.',
                    ),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.muted.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.info_outline_rounded,
                            color: AppColors.ink,
                            size: 21,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Jika PIN dan backup hilang, data lokal tidak dapat dipulihkan. '
                              'Pocketly tidak membuat backup secara otomatis.',
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(
                                    fontSize: 13,
                                    height: 1.45,
                                    fontWeight: FontWeight.w600,
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
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: FilledButton(
                key: const Key('local-data-continue'),
                onPressed: onContinue,
                child: const Text('Saya mengerti, lanjutkan'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({required this.onBack, required this.label});

  final VoidCallback onBack;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 24, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            tooltip: 'Kembali',
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          const SizedBox(width: 4),
          Text(label, style: Theme.of(context).textTheme.titleLarge),
        ],
      ),
    );
  }
}

class _LocalDataArtwork extends StatelessWidget {
  const _LocalDataArtwork();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 230,
        height: 170,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(36),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 96,
              height: 126,
              decoration: BoxDecoration(
                color: AppColors.background,
                border: Border.all(color: AppColors.ink, width: 3),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.ink.withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.savings_outlined,
                color: AppColors.primary,
                size: 42,
              ),
            ),
            Positioned(
              right: 35,
              bottom: 25,
              child: Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.background, width: 4),
                ),
                child: const Icon(
                  Icons.lock_rounded,
                  color: AppColors.ink,
                  size: 24,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.muted),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, color: AppColors.ink, size: 23),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: AppColors.ink.withValues(alpha: 0.58),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
