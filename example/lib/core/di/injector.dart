import 'package:get_it/get_it.dart';

import '../../features/session/data/repositories/profile_repository_impl.dart';
import '../../features/session/data/sources/fake_profile_api.dart';
import '../../features/session/domain/repositories/profile_repository.dart';
import '../../features/session/domain/usecases/get_profile.dart';
import '../../features/session/domain/usecases/update_profile_name.dart';
import '../../features/session/presentation/controllers/session_controller.dart';
import '../../features/team/data/repositories/member_repository_impl.dart';
import '../../features/team/data/sources/fake_team_api.dart';
import '../../features/team/domain/repositories/member_repository.dart';
import '../../features/team/domain/usecases/get_member.dart';
import '../../features/team/domain/usecases/get_members.dart';
import '../../features/team/domain/usecases/update_member_name.dart';
import '../../features/team/domain/usecases/watch_online_presence.dart';
import '../../features/team/presentation/controllers/member_detail_controller.dart';
import '../../features/team/presentation/controllers/members_controller.dart';

final getIt = GetIt.instance;

/// Composition root. Infrastructure is singleton-scoped; use cases are
/// stateless factories. Controllers come in two lifetimes:
///
/// - **factory** — page-scoped; the page that mounts it creates *and*
///   disposes it (MembersController, MemberDetailController);
/// - **lazy singleton** — app-scoped; lives for the whole session and is
///   read from anywhere (SessionController). Nobody disposes it.
///
/// [api] / [profileApi] are injectable so tests can supply fast,
/// deterministic backends.
void configureDependencies({FakeTeamApi? api, FakeProfileApi? profileApi}) {
  getIt
    // data
    ..registerLazySingleton<FakeTeamApi>(() => api ?? FakeTeamApi())
    ..registerLazySingleton<FakeProfileApi>(() => profileApi ?? FakeProfileApi())
    ..registerLazySingleton<MemberRepository>(
        () => MemberRepositoryImpl(getIt()))
    ..registerLazySingleton<ProfileRepository>(
        () => ProfileRepositoryImpl(getIt()))
    // domain
    ..registerFactory(() => GetMembers(getIt()))
    ..registerFactory(() => GetMember(getIt()))
    ..registerFactory(() => UpdateMemberName(getIt()))
    ..registerFactory(() => WatchOnlinePresence(getIt()))
    ..registerFactory(() => GetProfile(getIt()))
    ..registerFactory(() => UpdateProfileName(getIt()))
    // presentation
    ..registerLazySingleton<SessionController>(
      () => SessionController(getIt(), getIt()),
      // Only the container may dispose an app-scoped controller (on
      // getIt.reset() or scope pop) — pages never do.
      dispose: (controller) => controller.dispose(),
    )
    ..registerFactory(() => MembersController(getIt(), getIt()))
    ..registerFactoryParam<MemberDetailController, String, void>(
      (memberId, _) => MemberDetailController(memberId, getIt(), getIt()),
    );
}
