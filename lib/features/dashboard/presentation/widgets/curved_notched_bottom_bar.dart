import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

class CurvedNotchedBottomBar extends StatelessWidget {
  const CurvedNotchedBottomBar({
    required this.currentIndex,
    required this.onTap,
    this.backgroundColor = AppColors.background,
    this.selectedColor = AppColors.primary,
    this.unselectedColor = const Color(0xFFBFC0C5),
    this.height = 70,
    super.key,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final Color backgroundColor;
  final Color selectedColor;
  final Color unselectedColor;
  final double height;

  static const _labels = ['Beranda', 'Target', 'Tambah', 'Laporan', 'Profil'];

  @override
  Widget build(BuildContext context) {
    final barWidth = MediaQuery.sizeOf(context).width - 32;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return ColoredBox(
      color: Colors.transparent,
      child: SizedBox(
        key: const Key('main-navigation'),
        height: height + 24 + bottomInset,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: 16 + bottomInset,
            left: 16,
            right: 16,
          ),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              CustomPaint(
                size: Size(barWidth, height),
                painter: BottomNavBarPainter(
                  backgroundColor: backgroundColor,
                  shadowColor: Colors.black.withValues(alpha: 0.20),
                  elevation: 14,
                ),
              ),
              Positioned(
                bottom: height / 2 - 10,
                child: Semantics(
                  button: true,
                  selected: currentIndex == 2,
                  label: _labels[2],
                  child: Tooltip(
                    message: _labels[2],
                    child: GestureDetector(
                      key: const Key('nav-add'),
                      onTap: () => onTap(2),
                      behavior: HitTestBehavior.opaque,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          color: selectedColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: backgroundColor,
                            width: 3.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: selectedColor.withValues(alpha: 0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.savings_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: barWidth,
                height: height,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: _buildNavItem(
                          index: 0,
                          icon: Icons.home_rounded,
                          key: const Key('nav-home'),
                        ),
                      ),
                      Expanded(
                        child: _buildNavItem(
                          index: 1,
                          icon: Icons.flag_rounded,
                          key: const Key('nav-target'),
                        ),
                      ),
                      const SizedBox(width: 65),
                      Expanded(
                        child: _buildNavItem(
                          index: 3,
                          icon: Icons.bar_chart_rounded,
                          key: const Key('nav-reports'),
                        ),
                      ),
                      Expanded(
                        child: _buildNavItem(
                          index: 4,
                          icon: Icons.person_rounded,
                          key: const Key('nav-profile'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (currentIndex == 2)
                Positioned(
                  bottom: 8,
                  child: _IndicatorDot(color: selectedColor),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required Key key,
  }) {
    final isSelected = currentIndex == index;
    return Semantics(
      button: true,
      selected: isSelected,
      label: _labels[index],
      child: Tooltip(
        message: _labels[index],
        child: GestureDetector(
          key: key,
          onTap: () => onTap(index),
          behavior: HitTestBehavior.opaque,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                transform: Matrix4.translationValues(0, isSelected ? -3 : 0, 0),
                child: Icon(
                  icon,
                  color: isSelected ? selectedColor : unselectedColor,
                  size: 26,
                ),
              ),
              const SizedBox(height: 6),
              AnimatedOpacity(
                opacity: isSelected ? 1 : 0,
                duration: const Duration(milliseconds: 200),
                child: AnimatedScale(
                  scale: isSelected ? 1 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: _IndicatorDot(color: selectedColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IndicatorDot extends StatelessWidget {
  const _IndicatorDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class BottomNavBarPainter extends CustomPainter {
  const BottomNavBarPainter({
    required this.backgroundColor,
    required this.shadowColor,
    required this.elevation,
  });

  final Color backgroundColor;
  final Color shadowColor;
  final double elevation;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;

    final path = Path();
    final width = size.width;
    final height = size.height;
    final radius = height / 2;
    final centerX = width / 2;
    const notchWidth = 100.0;
    const notchHeight = 35.0;
    final leftStart = centerX - notchWidth / 2;
    final rightEnd = centerX + notchWidth / 2;

    path
      ..moveTo(radius, 0)
      ..lineTo(leftStart, 0)
      ..cubicTo(
        leftStart + 18,
        0,
        leftStart + 18,
        notchHeight,
        centerX,
        notchHeight,
      )
      ..cubicTo(rightEnd - 18, notchHeight, rightEnd - 18, 0, rightEnd, 0)
      ..lineTo(width - radius, 0)
      ..arcToPoint(
        Offset(width - radius, height),
        radius: Radius.circular(radius),
      )
      ..lineTo(radius, height)
      ..arcToPoint(Offset(radius, 0), radius: Radius.circular(radius))
      ..close();

    if (elevation > 0) {
      canvas.drawShadow(
        path.shift(const Offset(0, 3)),
        shadowColor,
        elevation,
        true,
      );
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant BottomNavBarPainter oldDelegate) {
    return oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.shadowColor != shadowColor ||
        oldDelegate.elevation != elevation;
  }
}
