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
    final hub = tester.getRect(find.byKey(SpinningWheel.hubKey));
    expect(hub.center, wheel.center);
  });

  testWidgets('turning the wheel does not paint its segments again', (
    tester,
  ) async {
    Widget wheel(double rotation) => MaterialApp(
      home: Center(
        child: SizedBox(
          width: 300,
          // New lists with the same choices, as the page makes when it
          // rebuilds.
          child: SpinningWheel(
            choices: ['A', 'B', 'C'].toList(),
            colors: [Colors.red, Colors.green, Colors.blue].toList(),
            weights: [1, 2, 1].toList(),
            rotation: rotation,
          ),
        ),
      ),
    );
    await tester.pumpWidget(wheel(0));

    await tester.pumpWidget(wheel(1), phase: EnginePhase.layout);

    final segments = tester.renderObject(
      find
          .descendant(
            of: find.byType(Transform),
            matching: find.byType(CustomPaint),
          )
          .first,
    );
    expect(segments.debugNeedsPaint, isFalse);
    // Finish the frame left half done.
    await tester.pump();
  });
}
