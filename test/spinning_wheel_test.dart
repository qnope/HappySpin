import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:happyspin/src/spinning_wheel.dart';

void main() {
  testWidgets('the hub sits on the center of the wheel', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Center(
          child: SizedBox(
            width: 300,
            child: SpinningWheel(choices: ['A', 'B', 'C'], rotation: 0),
          ),
        ),
      ),
    );

    final wheel = tester.getRect(
      find
          .descendant(
            of: find.byType(Transform),
            matching: find.byType(CustomPaint),
          )
          .first,
    );
    final hub = tester.getRect(find.byIcon(Icons.auto_awesome));
    expect(hub.center, wheel.center);
  });
}
