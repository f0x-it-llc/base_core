import 'package:base_core/base_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rxdart/rxdart.dart';

import 'test_classes/failures.dart';
import 'test_classes/usecases/get_user_usecase.dart';
import 'test_classes/usecases/get_users_ages.dart';
import 'test_classes/usecases/stream_user_age_usecase.dart';
import 'test_classes/usecases/update_user_usecase.dart';
import 'test_classes/user_data_manager.dart';
import 'test_classes/user_model.dart';
import 'test_classes/user_usecase_generator.dart';

void main() {
  final subscription = CompositeSubscription();
  final userManager = UserDataManager(UserUseCaseGenerator());
  userManager.registerSubscription(subscription);

  group('Test DataManager', () {
    test('Should emit expected data', () async {
      final subscription = userManager.stream.listen(expectAsync1((event) {
        expect(event.runtimeType, User);
      }));

      userManager.getUser();

      await userManager.waitDone;
      subscription.cancel();
    });

    test('Should update name', () async {
      expect(
        userManager.stream.map(User.name.get),
        emitsInOrder(
          [WRONG_NAME, FIXED_NAME],
        ),
      );

      userManager.updateUser(FIXED_NAME);

      await userManager.waitDone;
    });

    test('Should emit loading', () async {
      expect(userManager.isLoading, emitsInOrder([false, true, false, true]));

      userManager.getUser();

      await userManager.waitDone;

      userManager.getUser();
      await userManager.waitDone;
    });

    test('Should emit failure', () async {
      final s = userManager.onFailure.listen(expectAsync1((event) {
        expect(event.runtimeType, NotFound);
      }));

      userManager.updateUser(null);
      await userManager.waitDone;
      await s.cancel();
    });

    test('Should map using map function', () async {
      expect(
          userManager.stream.map(User.age.get),
          emitsInOrder([
            INITIAL_AGE,
            UPDATED_AGE,
          ]));

      userManager.getUsersAges();
      await userManager.waitDone;
    });

    test('Should stream user age', () async {
      final params = TestingStreamUserAgeUseCaseParams(500);
      final numberOfEmits = 4;

      final currentAge = User.age.get(userManager.value);

      final emittingItems = List.generate(numberOfEmits + 1, (index) {
        if (index == 0) {
          return currentAge;
        } else {
          return currentAge + index;
        }
      });

      expect(userManager.stream.map(User.age.get), emitsInOrder(emittingItems));

      userManager.registerAgeStream(params);
      await Future.delayed(
        Duration(milliseconds: params.milliseconds * numberOfEmits),
      );
    });

    test('Should retry use case', () async {
      userManager.retryUser();

      await userManager.waitDone;
      await Future.delayed(Duration(milliseconds: 8000));

      // TODO: Test if the use case is retried
    });
  });
}
