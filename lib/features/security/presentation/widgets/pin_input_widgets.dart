import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

class PocketlyPinDots extends StatelessWidget {
  const PocketlyPinDots({
    required this.length,
    required this.hasError,
    super.key,
  });

  final int length;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$length dari 6 digit PIN terisi',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(6, (index) {
          final filled = index < length;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: filled ? 18 : 14,
            height: filled ? 18 : 14,
            margin: const EdgeInsets.symmetric(horizontal: 7),
            decoration: BoxDecoration(
              color: filled ? AppColors.primary : AppColors.background,
              shape: BoxShape.circle,
              border: Border.all(
                color: hasError ? AppColors.ink : AppColors.muted,
                width: 2,
              ),
            ),
          );
        }),
      ),
    );
  }
}

class PocketlyPinKeypad extends StatelessWidget {
  const PocketlyPinKeypad({
    required this.compact,
    required this.onDigit,
    required this.onDelete,
    this.enabled = true,
    super.key,
  });

  final bool compact;
  final bool enabled;
  final ValueChanged<String> onDigit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    const rows = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
    ];
    final buttonSize = compact ? 48.0 : 58.0;
    final rowGap = compact ? 5.0 : 9.0;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 310),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final row in rows) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: row
                  .map(
                    (digit) => _NumberButton(
                      digit: digit,
                      size: buttonSize,
                      onPressed: enabled ? () => onDigit(digit) : null,
                    ),
                  )
                  .toList(),
            ),
            SizedBox(height: rowGap),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              SizedBox(width: buttonSize, height: buttonSize),
              _NumberButton(
                digit: '0',
                size: buttonSize,
                onPressed: enabled ? () => onDigit('0') : null,
              ),
              SizedBox(
                width: buttonSize,
                height: buttonSize,
                child: IconButton(
                  key: const Key('pin-delete'),
                  onPressed: enabled ? onDelete : null,
                  tooltip: 'Hapus digit',
                  icon: const Icon(Icons.backspace_outlined),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NumberButton extends StatelessWidget {
  const _NumberButton({
    required this.digit,
    required this.size,
    required this.onPressed,
  });

  final String digit;
  final double size;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Material(
        color: AppColors.muted.withValues(alpha: 0.5),
        shape: const CircleBorder(),
        child: InkWell(
          key: Key('pin-key-$digit'),
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: Center(
            child: Text(
              digit,
              style: TextStyle(
                color: AppColors.ink.withValues(
                  alpha: onPressed == null ? 0.35 : 1,
                ),
                fontSize: 21,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
