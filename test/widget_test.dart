import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chairside/state/demo_store.dart';
import 'package:chairside/ui/app.dart';

// Reveal the target and wait for layout before interacting with it.
Future<void> reveal(WidgetTester tester, Finder target) async {
  final scrollable = find.byWidgetPredicate((widget) {
    return widget is Scrollable &&
        (widget.axisDirection == AxisDirection.down ||
            widget.axisDirection == AxisDirection.up);
  }).last;

  final state = tester.state<ScrollableState>(scrollable);

  state.position.jumpTo(state.position.minScrollExtent);
  await tester.pumpAndSettle();

  await tester.scrollUntilVisible(
    target,
    160,
    scrollable: scrollable,
    maxScrolls: 60,
  );

  await tester.pumpAndSettle();
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();

  expect(target.hitTestable(), findsOneWidget);
}

Future<void> tapVisible(
  WidgetTester tester,
  Finder target,
) async {
  await reveal(tester, target);
  await tester.tap(target.hitTestable());
  await tester.pumpAndSettle();
}

Future<void> switchRole(
  WidgetTester tester,
  String role,
) async {
  await tester.tap(find.byKey(const Key('role-switch')));
  await tester.pumpAndSettle();

  await tester.tap(find.text(role).last);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'customer joins a queue, barber serves them, customer sees completion',
    (tester) async {
      final store = DemoStore(
        clock: () => DateTime(2026, 10, 19, 10),
        seedQueue: false,
      );

      addTearDown(store.dispose);

      await tester.pumpWidget(ChairsideApp(store: store));
      await tester.pumpAndSettle();

      await tapVisible(
        tester,
        find.byKey(const Key('view-p1')),
      );

      expect(
        find.byKey(const Key('queue-choice')),
        findsOneWidget,
      );

      await tapVisible(
        tester,
        find.byKey(const Key('queue-choice')),
      );

      await tapVisible(
        tester,
        find.byKey(const Key('confirm-visit')),
      );

      expect(
        find.text('You are #1 in the queue'),
        findsOneWidget,
      );

      await switchRole(tester, 'Barber');

      final id = store.mine.single.id;

      await tapVisible(
        tester,
        find.byKey(Key('start-$id')),
      );

      await tapVisible(
        tester,
        find.byKey(Key('finish-$id')),
      );

      await switchRole(tester, 'Customer');

      await tester.tap(find.text('My visits').last);
      await tester.pumpAndSettle();

      expect(find.text('Completed'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  for (final size in [
    const Size(390, 844),
    const Size(1440, 1000),
  ]) {
    testWidgets(
      'discovery renders without overflow at '
      '${size.width} x ${size.height}',
      (tester) async {
        final store = DemoStore(
          clock: () => DateTime(2026, 10, 19, 10),
        );

        addTearDown(store.dispose);
        addTearDown(() => tester.view.resetPhysicalSize());
        addTearDown(() => tester.view.resetDevicePixelRatio());

        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = size;

        await tester.pumpWidget(ChairsideApp(store: store));
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('role-switch')),
          findsOneWidget,
        );

        await reveal(
          tester,
          find.text('Find your chair'),
        );

        expect(
          find.text('Find your chair'),
          findsOneWidget,
        );

        expect(tester.takeException(), isNull);

        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
}
