import 'package:base_core/base_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class SomeBloc extends BaseBloc {
  hello() {}
}

class SomeWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final _bloc = BlocProvider.of<SomeBloc>(context);
    return Container();
  }
}

class BlocWrappingWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      child: SomeWidget(),
      blocBuilder: () => SomeBloc(),
      blocDisposer: (bloc) => bloc.dispose(),
    );
  }
}

void main() {
  testWidgets("Test Bloc", (tester) async {
    await tester.pumpWidget(BlocWrappingWidget());
  });
}
