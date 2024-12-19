import 'package:base_core/base_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Test Blocs
class FirstBloc extends BaseBloc {
  String getValue() => 'first';
}

class SecondBloc extends BaseBloc {
  String getValue() => 'second';
}

// Test Widget that needs access to both blocs
class TestWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final firstBloc = BlocProvider.of<FirstBloc>(context);
    final secondBloc = BlocProvider.of<SecondBloc>(context);

    return Column(
      children: [
        Text(firstBloc?.getValue() ?? 'no first bloc'),
        Text(secondBloc?.getValue() ?? 'no second bloc'),
      ],
    );
  }
}

void main() {
  group('MultiBlocProvider Tests', () {
    testWidgets('should provide multiple blocs to widget tree', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MultiBlocProvider(
            blocs: [
              SingleBlocProvider<FirstBloc>(() => FirstBloc()),
              SingleBlocProvider<SecondBloc>(() => SecondBloc()),
            ],
            child: TestWidget(),
          ),
        ),
      );

      // Verify both bloc values are accessible and rendered
      expect(find.text('first'), findsOneWidget);
      expect(find.text('second'), findsOneWidget);
    });

    testWidgets('should dispose blocs when widget is removed', (tester) async {
      bool firstBlocDisposed = false;
      bool secondBlocDisposed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: MultiBlocProvider(
            blocs: [
              SingleBlocProvider<FirstBloc>(
                () => FirstBloc(),
                blocDispose: (_) => firstBlocDisposed = true,
              ),
              SingleBlocProvider<SecondBloc>(
                () => SecondBloc(),
                blocDispose: (_) => secondBlocDisposed = true,
              ),
            ],
            child: TestWidget(),
          ),
        ),
      );

      // Remove widget tree
      await tester.pumpWidget(Container());

      // Verify blocs were disposed
      expect(firstBlocDisposed, true);
      expect(secondBlocDisposed, true);
    });

    testWidgets('should maintain bloc order', (tester) async {
      late BuildContext capturedContext;

      await tester.pumpWidget(
        MaterialApp(
          home: MultiBlocProvider(
            blocs: [
              SingleBlocProvider<FirstBloc>(() => FirstBloc()),
              SingleBlocProvider<SecondBloc>(() => SecondBloc()),
            ],
            child: Builder(
              builder: (context) {
                capturedContext = context;
                return TestWidget();
              },
            ),
          ),
        ),
      );

      // Verify we can get both blocs
      expect(BlocProvider.of<FirstBloc>(capturedContext), isNotNull);
      expect(BlocProvider.of<SecondBloc>(capturedContext), isNotNull);
    });
  });
}
