import 'package:base_core/src/data_manager.dart';

import 'usecases/get_user_usecase.dart';
import 'usecases/get_users_ages.dart';
import 'usecases/retryable_usecase.dart';
import 'usecases/stream_user_age_usecase.dart';
import 'usecases/update_user_usecase.dart';
import 'user_model.dart';
import 'user_usecase_generator.dart';

class UserDataManager extends DataManager<User> {
  UserDataManager(UserUseCaseGenerator generated) : super(generated);

  void getUser() {
    runUseCase<GetUserUseCase, int>(3);
  }

  void updateUser(String? name) {
    runUseCase<UpdateUserUseCase, String?>(name);
  }

  void getUsersAges() {
    runUseCase<GetUserAges, void>(null);
  }

  void registerAgeStream(TestingStreamUserAgeUseCaseParams params) {
    registerStreamingUseCase<StreamUserAgeUseCase,
        TestingStreamUserAgeUseCaseParams>(params);
  }

  void deRegisterAgeStream() {
    deRegisterUseCase<StreamUserAgeUseCase>();
  }

  void retryUser() {
    runUseCase<RetryableUseCase, bool>(true);
  }

  @override
  void close() {
    super.close();
  }
}
