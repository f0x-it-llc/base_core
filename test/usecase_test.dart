import 'package:base_core/base_core.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';

class NullValueFailure extends Failure {}

class ParsingFailure extends Failure {}

class TestUseCase extends UseCase<String?, int> {
  @override
  Future<Either<Failure, int>> execute(String? params) async {
    if (params == null) {
      return left(NullValueFailure());
    }
    try {
      final res = await Future.delayed(
        Duration(milliseconds: 500),
        () => int.parse(params),
      );

      return right(res);
    } catch (e) {
      return left(ParsingFailure());
    }
  }
}

void main() {
  test('Test usecase', () async {
    final useCase = TestUseCase();
    expect(await useCase.result(null, (e) => e.isLeft()), true);

    expect(await useCase.result('56', (e) => e.fold((_) => 0, (r) => r)), 56);

    final failure =
        await useCase.result('params', (e) => e.fold((l) => l, (_) => 0));

    expect(failure.runtimeType, ParsingFailure);
  });
}
