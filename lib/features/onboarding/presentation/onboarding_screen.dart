import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import 'widgets/onboarding_artwork.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({required this.onFinished, super.key});

  final VoidCallback onFinished;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late final PageController _pageController;
  int _currentPage = 0;

  static const _pages = <_OnboardingPageData>[
    _OnboardingPageData(
      eyebrow: 'TUJUANMU',
      title: 'Rencana kecil,\nhasil yang berarti.',
      description:
          'Buat target yang jelas dan temukan ritme menabung yang paling nyaman untukmu.',
      artwork: GoalArtwork(),
    ),
    _OnboardingPageData(
      eyebrow: 'PROGRESMU',
      title: 'Setiap langkah\nlayak dirayakan.',
      description:
          'Catat setoran dalam hitungan detik dan lihat progres tumbuh tanpa tekanan.',
      artwork: ProgressArtwork(),
    ),
    _OnboardingPageData(
      eyebrow: 'PRIVASIMU',
      title: 'Tetap privat.\nTetap milikmu.',
      description:
          'Data disimpan di perangkat dan dapat dilindungi dengan backup terenkripsi.',
      artwork: PrivacyArtwork(),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goNext() {
    if (_currentPage == _pages.length - 1) {
      widget.onFinished();
      return;
    }
    _pageController.nextPage(
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
    );
  }

  void _skip() {
    _pageController.animateToPage(
      _pages.length - 1,
      duration: const Duration(milliseconds: 550),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('onboarding-screen'),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxHeight < 700;
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 16, 0),
                  child: Row(
                    children: [
                      const _BrandMark(),
                      const Spacer(),
                      AnimatedOpacity(
                        opacity: _currentPage == _pages.length - 1 ? 0 : 1,
                        duration: const Duration(milliseconds: 200),
                        child: TextButton(
                          onPressed: _currentPage == _pages.length - 1
                              ? null
                              : _skip,
                          child: const Text('Lewati'),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _pages.length,
                    onPageChanged: (index) =>
                        setState(() => _currentPage = index),
                    itemBuilder: (context, index) =>
                        _OnboardingPage(data: _pages[index], compact: compact),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(24, 12, 24, compact ? 14 : 24),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          _PageIndicator(
                            pageCount: _pages.length,
                            activePage: _currentPage,
                          ),
                          const Spacer(),
                          Text(
                            '${_currentPage + 1}/${_pages.length}',
                            style: TextStyle(
                              color: AppColors.ink.withValues(alpha: 0.45),
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      FilledButton(
                        key: const Key('onboarding-next'),
                        onPressed: _goNext,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 180),
                          child: Text(
                            _currentPage == _pages.length - 1
                                ? 'Mulai sekarang'
                                : 'Lanjut',
                            key: ValueKey(_currentPage),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({required this.data, required this.compact});

  final _OnboardingPageData data;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: compact ? 8 : 20),
          Expanded(
            flex: compact ? 5 : 6,
            child: Center(child: data.artwork),
          ),
          SizedBox(height: compact ? 12 : 24),
          Text(
            data.eyebrow,
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.8,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            data.title,
            style: Theme.of(
              context,
            ).textTheme.headlineLarge?.copyWith(fontSize: compact ? 29 : 34),
          ),
          const SizedBox(height: 12),
          Text(
            data.description,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppColors.ink.withValues(alpha: 0.64),
              fontSize: compact ? 14 : 16,
            ),
          ),
          SizedBox(height: compact ? 6 : 12),
        ],
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Image.asset(
          'assets/branding/pocketly_logo.png',
          width: 30,
          height: 30,
          semanticLabel: 'Logo Pocketly',
        ),
        const SizedBox(width: 8),
        const Text(
          'pocketly',
          style: TextStyle(
            color: AppColors.ink,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.6,
          ),
        ),
      ],
    );
  }
}

class _PageIndicator extends StatelessWidget {
  const _PageIndicator({required this.pageCount, required this.activePage});

  final int pageCount;
  final int activePage;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(pageCount, (index) {
        final active = index == activePage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          width: active ? 28 : 8,
          height: 8,
          margin: const EdgeInsets.only(right: 7),
          decoration: BoxDecoration(
            color: active ? AppColors.primary : AppColors.muted,
            borderRadius: BorderRadius.circular(99),
          ),
        );
      }),
    );
  }
}

class _OnboardingPageData {
  const _OnboardingPageData({
    required this.eyebrow,
    required this.title,
    required this.description,
    required this.artwork,
  });

  final String eyebrow;
  final String title;
  final String description;
  final Widget artwork;
}
