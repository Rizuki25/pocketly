import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketly/app/pocketly_app.dart';

void main() {
  testWidgets('splash opens the first onboarding page', (tester) async {
    await tester.pumpWidget(const PocketlyApp());

    expect(find.byKey(const Key('splash-screen')), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('onboarding-screen')), findsOneWidget);
    expect(find.text('Rencana kecil,\nhasil yang berarti.'), findsOneWidget);
  });

  testWidgets('onboarding advances through all pages', (tester) async {
    await tester.pumpWidget(const PocketlyApp());
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('onboarding-next')));
    await tester.pumpAndSettle();
    expect(find.text('Setiap langkah\nlayak dirayakan.'), findsOneWidget);

    await tester.tap(find.byKey(const Key('onboarding-next')));
    await tester.pumpAndSettle();
    expect(find.text('Tetap privat.\nTetap milikmu.'), findsOneWidget);
    expect(find.text('Mulai sekarang'), findsOneWidget);
  });

  testWidgets('local data explanation leads to a validated PIN setup', (
    tester,
  ) async {
    await tester.pumpWidget(const PocketlyApp());
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Lewati'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mulai sekarang'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('local-data-screen')), findsOneWidget);
    await tester.tap(find.byKey(const Key('local-data-continue')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('pin-setup-screen')), findsOneWidget);

    await _enterPin(tester, '123456');
    await tester.tap(find.byKey(const Key('pin-continue')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('pin-error')), findsOneWidget);

    await _enterPin(tester, '135790');
    await tester.tap(find.byKey(const Key('pin-continue')));
    await tester.pumpAndSettle();
    expect(find.text('Ulangi PIN-mu'), findsOneWidget);

    await _enterPin(tester, '135790');
    await tester.tap(find.byKey(const Key('pin-continue')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('pin-success-title')), findsOneWidget);

    await tester.tap(find.byKey(const Key('pin-success-continue')));
    await tester.pumpAndSettle();
    expect(find.text('Keamanan dasar aktif'), findsOneWidget);
  });
}

Future<void> _enterPin(WidgetTester tester, String pin) async {
  for (final digit in pin.split('')) {
    await tester.tap(find.byKey(Key('pin-key-$digit')));
    await tester.pump();
  }
}
