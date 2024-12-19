# Base Core

Yet another state management solution for Flutter applications.

## About

Base Core is an opinionated state management solution designed for large-scale Flutter applications. It provides a collection of utility classes that work together seamlessly to manage application state, handle use cases, and implement the BLoC (Business Logic Component) pattern.

*Note: This library heavily depends on [dartz](https://pub.dev/packages/dartz) and [rxdart](https://pub.dev/packages/rxdart)*

## Key Features

- BLoC pattern implementation
- Reactive state management
- Use case execution framework
- Error handling and retry mechanisms
- Activity tracking
- Structured logging

## Core Components

### BaseBloc
A foundational implementation of the BLoC pattern that provides:
- Automatic subscription management
- Built-in logging
- Disposable resources cleanup

### DataManager
A powerful state management solution that offers:
- Centralized state management
- Use case execution
- Automatic retry mechanism for failed operations
- Activity indication
- Error handling
- Stream-based state updates

### UseCase
Abstract classes for implementing business logic:
- `UseCase<P, R>`: For single-execution use cases
- `StreamingUseCase<P, R>`: For continuous data streams
- `DataManagerUseCase<P, R>`: Specialized use cases for DataManager

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  base_core: ^1.0.0
```

## Usage

### 1. Creating a Use Case

```dart
class GetUserProfile extends UseCase<String, UserProfile> {
  final UserRepository userRepository;

  GetUserProfile(this.userRepository);

  @override
  Future<Either<Failure, UserProfile>> execute(String userId) async {
    try {
      final profile = await userRepository.getProfile(userId);
      return right(profile);
    } catch (e) {
      return left(UnexpectedFailure(e.toString()));
    }
  }
}
```

### 2. Setting up a DataManager

```dart
class UserState {
  final UserProfile? profile;
  final bool isLoggedIn;
  final List<User> friends;
  // Add other state properties as needed
}

class UserUseCaseGenerator extends UseCaseGenerator<UserState> {
    UserUseCaseGenerator() {
        final userRepository = UserRepository();
        addUseCase(GetUserProfile(userRepository));
        addUseCase(UpdateUserUseCase(userRepository));
        addUseCaseWithMapFn(GetUserAges(userRepository), GetUserAges.mapToUser);
        addStreamingUseCase(StreamUserAgeUseCase(userRepository));
        addUseCaseWithMapFn(RetryableUseCase(userRepository), (u, _) => u);
    }
}

class UserDataManager extends DataManager<UserState> {
  UserDataManager() : super(UserUseCaseGenerator());

  void getUserProfile(String userId) {
    runUseCase<GetUserProfile, String>(userId);
  }

  void updateUser(UserProfile profile) {
    runUseCase<UpdateUserUseCase, UserProfile>(profile);
  }

  void getUsersAges() {
    runUseCase<GetUserAges, void>(null);
  }

  void registerAgeStream(TestingStreamUserAgeUseCaseParams params) {
    registerStreamingUseCase<StreamUserAgeUseCase, TestingStreamUserAgeUseCaseParams>(params);
  }

  void retryableUseCase() {
    runUseCase<RetryableUseCase, void>(null);
  }
}

```

### 3. Using BLoC Pattern

```dart
class UserBloc extends BaseBloc {
  final UserDataManager _dataManager;
  
  UserBloc(this._dataManager);
  
  void loadUserProfile(String userId) {
    _dataManager.getUserProfile(userId);
  }

  void updateUser(UserProfile profile) {
    _dataManager.updateUser(profile);
  }

  Stream<bool> get isLoading => _dataManager.isLoading;

  Stream<Failure> get onFailure => _dataManager.onFailure;
  
  Stream<UserState> get state => _dataManager.rx;
}
```

### 4. Implementing in UI

```dart
class UserProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final bloc = BlocProvider.of<UserBloc>(context);
    
    return ValueStreamBuilder<UserState>(
      stream: bloc.state,
      builder: (context, snapshot) {
        final state = snapshot.data;
        return // Your UI implementation
      },
    );
  }
}
```

## Advanced Features

### Activity Tracking
Monitor loading states across your application:

```dart
dataManager.isLoading.listen((isLoading) {
  // Handle loading state
});
```

### Error Handling
Handle failures and errors gracefully:

```dart
dataManager.onFailure.listen((failure) {
  // Handle failure
});
```

### Automatic Retries
The DataManager automatically handles retryable failures:

```dart
class NetworkFailure extends RetryableFailure {
    dynamic params; 
    NetworkFailure(this.params, Type runtimeType) : super(
        params: params,
        useCase: runtimeType,
        delay: Duration(milliseconds: 500),
    );
}

class GetUserProfile extends UseCase<String, UserProfile> {
  final UserRepository userRepository;

  GetUserProfile(this.userRepository);

  @override
  Future<Either<Failure, UserProfile>> execute(String userId) async {
    try {
      final profile = await userRepository.getProfile(userId);
      return right(profile);
    } catch (e) {
        // if the error code is 500, we want to retry the use case
        if (e.code == 500) {
            return left(NetworkFailure(userId, this.runtimeType));
        }
      return left(UnexpectedFailure(e.toString()));
    }
  }
}
```

## Best Practices

1. Keep use cases focused on single responsibilities
2. Implement proper error handling in use cases
3. Use appropriate failure types
4. Dispose of resources properly
5. Utilize the built-in logging system for debugging


## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.


