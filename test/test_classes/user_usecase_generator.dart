import 'package:base_core/src/use_case_generator.dart';

import 'usecases/get_user_usecase.dart';
import 'usecases/get_users_ages.dart';
import 'usecases/retryable_usecase.dart';
import 'usecases/stream_user_age_usecase.dart';
import 'usecases/update_user_usecase.dart';
import 'user_model.dart';

class UserUseCaseGenerator extends UseCaseGenerator<User> {
  UserUseCaseGenerator() {
    addUseCase(GetUserUseCase());
    addUseCase(UpdateUserUseCase());
    addUseCaseWithMapFn(GetUserAges(), GetUserAges.mapToUser);
    addStreamingUseCase(StreamUserAgeUseCase());
    addUseCaseWithMapFn(RetryableUseCase(), (u, _) => u);
  }
}
