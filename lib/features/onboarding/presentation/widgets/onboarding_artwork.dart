import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

const _artSize = 286.0;

class GoalArtwork extends StatelessWidget {
  const GoalArtwork({super.key});

  @override
  Widget build(BuildContext context) {
    return const _ArtworkFrame(
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(top: 28, right: 34, child: _Sparkle(size: 18)),
          Positioned(bottom: 38, left: 25, child: _Dot(size: 11)),
          _GoalCard(),
        ],
      ),
    );
  }
}

class ProgressArtwork extends StatelessWidget {
  const ProgressArtwork({super.key});

  @override
  Widget build(BuildContext context) {
    return const _ArtworkFrame(
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(top: 25, left: 34, child: _Dot(size: 9)),
          Positioned(bottom: 30, right: 28, child: _Sparkle(size: 19)),
          _ProgressCard(),
        ],
      ),
    );
  }
}

class PrivacyArtwork extends StatelessWidget {
  const PrivacyArtwork({super.key});

  @override
  Widget build(BuildContext context) {
    return const _ArtworkFrame(
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(top: 30, right: 28, child: _Dot(size: 12)),
          Positioned(bottom: 33, left: 32, child: _Sparkle(size: 18)),
          _PrivacyCard(),
        ],
      ),
    );
  }
}

class _ArtworkFrame extends StatelessWidget {
  const _ArtworkFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _artSize,
      height: _artSize,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(44),
      ),
      child: child,
    );
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 196,
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _IconTile(icon: Icons.flag_rounded),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: const Text(
                  '68%',
                  style: TextStyle(
                    color: AppColors.ink,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          const Text(
            'Dana impian',
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 7),
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: AppColors.muted,
              borderRadius: BorderRadius.circular(99),
            ),
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: 0.68,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 208,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      decoration: _cardDecoration,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Expanded(
                child: Text(
                  'Progres bulan ini',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              SizedBox(width: 8),
              _IconTile(icon: Icons.trending_up_rounded, small: true),
            ],
          ),
          const SizedBox(height: 18),
          const SizedBox(
            height: 76,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _Bar(height: 30),
                _Bar(height: 45),
                _Bar(height: 38),
                _Bar(height: 62, active: true),
                _Bar(height: 52),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Row(
              children: [
                Icon(Icons.add_rounded, size: 17, color: AppColors.ink),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Setoran tercatat',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.ink,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
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

class _PrivacyCard extends StatelessWidget {
  const _PrivacyCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 204,
      padding: const EdgeInsets.all(22),
      decoration: _cardDecoration,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(26),
            ),
            child: const Icon(
              Icons.lock_outline_rounded,
              size: 30,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Tersimpan lokal',
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            'Aman di perangkatmu',
            style: TextStyle(
              color: AppColors.ink.withValues(alpha: 0.55),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.phone_android_rounded, size: 17),
              SizedBox(width: 8),
              Icon(Icons.more_horiz_rounded, size: 17),
              SizedBox(width: 8),
              Icon(Icons.backup_outlined, size: 17),
            ],
          ),
        ],
      ),
    );
  }
}

class _IconTile extends StatelessWidget {
  const _IconTile({required this.icon, this.small = false});

  final IconData icon;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final size = small ? 30.0 : 42.0;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(small ? 10 : 14),
      ),
      child: Icon(icon, size: small ? 17 : 22, color: AppColors.ink),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.height, this.active = false});

  final double height;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: height,
      decoration: BoxDecoration(
        color: active ? AppColors.primary : AppColors.muted,
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}

class _Sparkle extends StatelessWidget {
  const _Sparkle({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.auto_awesome_rounded,
      size: size,
      color: AppColors.primary,
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: AppColors.ink,
        shape: BoxShape.circle,
      ),
    );
  }
}

final _cardDecoration = BoxDecoration(
  color: AppColors.background,
  border: Border.all(color: AppColors.muted),
  borderRadius: BorderRadius.circular(26),
  boxShadow: [
    BoxShadow(
      color: AppColors.ink.withValues(alpha: 0.08),
      blurRadius: 24,
      offset: const Offset(0, 12),
    ),
  ],
);
