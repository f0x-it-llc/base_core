import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:team_directory/core/demo_users.dart';
import 'package:team_directory/core/di/injector.dart';
import 'package:team_directory/features/session/data/sources/fake_profile_api.dart';
import 'package:team_directory/features/session/presentation/controllers/session_controller.dart';
import 'package:team_directory/features/team/data/sources/fake_team_api.dart';
import 'package:team_directory/main.dart';

void main() {
  tearDown(() async {
    await getIt.reset();
  });

  Future<void> pumpApp(
    WidgetTester tester, {
    int failuresBeforeSuccess = 0,
  }) async {
    configureDependencies(
      api: FakeTeamApi(
        latency: const Duration(milliseconds: 30),
        failuresBeforeSuccess: failuresBeforeSuccess,
        presenceInterval: const Duration(hours: 1),
      ),
      profileApi: FakeProfileApi(latency: const Duration(milliseconds: 30)),
    );
    unawaited(getIt<SessionController>().signIn(demoUserIds.first));
    await tester.pumpWidget(const TeamDirectoryApp());
  }

  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  }

  Future<void> settleThrough(WidgetTester tester, Duration total) async {
    const step = Duration(milliseconds: 100);
    for (var elapsed = Duration.zero; elapsed < total; elapsed += step) {
      await tester.pump(step);
    }
  }

  testWidgets('loads and shows the member list', (tester) async {
    await pumpApp(tester);

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await settleThrough(tester, const Duration(milliseconds: 200));
    expect(find.text('Ava Chen'), findsOneWidget);
    expect(find.text('Bruno Costa'), findsOneWidget);

    await unmount(tester);
  });

  testWidgets('survives a flaky backend via the retry policy', (tester) async {
    // First two fetches return 500; RetryPolicy(maxAttempts: 3) absorbs them.
    await pumpApp(tester, failuresBeforeSuccess: 2);

    await settleThrough(tester, const Duration(seconds: 2));
    expect(find.text('Ava Chen'), findsOneWidget);

    await unmount(tester);
  });

  testWidgets('search filters the list via computed signal', (tester) async {
    await pumpApp(tester);
    await settleThrough(tester, const Duration(milliseconds: 200));

    await tester.enterText(find.byType(TextField), 'designer');
    await tester.pump();

    expect(find.text('Chidi Okafor'), findsOneWidget);
    expect(find.text('Ava Chen'), findsNothing);

    await unmount(tester);
  });

  testWidgets('navigates to detail and rejects an invalid rename',
      (tester) async {
    await pumpApp(tester);
    await settleThrough(tester, const Duration(milliseconds: 200));

    await tester.tap(find.text('Ava Chen'));
    await settleThrough(tester, const Duration(milliseconds: 400));

    expect(find.text('ava@team.dev'), findsOneWidget);

    // A one-character name violates the domain rule in UpdateMemberName;
    // the ValidationFailure surfaces through the failures stream as a snackbar.
    // (The list page's search field is still in the tree under the pushed
    // route, so target the name field by its prefilled text.)
    await tester.enterText(find.widgetWithText(TextField, 'Ava Chen'), 'A');
    await tester.tap(find.text('Save'));
    await settleThrough(tester, const Duration(milliseconds: 400));

    expect(find.text('Name must be at least 2 characters.'), findsOneWidget);

    await unmount(tester);
  });

  testWidgets('profile edits propagate to session readers on other pages',
      (tester) async {
    await pumpApp(tester);
    await settleThrough(tester, const Duration(milliseconds: 200));

    // The members page AppBar shows the signed-in user's initial ('R'iley),
    // read straight from the app-scoped SessionController.
    expect(find.text('R'), findsOneWidget);

    await tester.tap(find.byTooltip('Your profile'));
    await settleThrough(tester, const Duration(milliseconds: 400));
    expect(find.text('riley@team.dev'), findsOneWidget);

    // Rename so the initial changes: Riley -> Zoe.
    await tester.enterText(
        find.widgetWithText(TextField, 'Riley Park'), 'Zoe Park');
    await tester.tap(find.text('Save'));
    await settleThrough(tester, const Duration(milliseconds: 400));
    expect(find.text('Profile updated.'), findsOneWidget);

    // Back on the members page, the avatar chip already shows the new
    // initial — no wiring between the pages, both read the same signal.
    await tester.pageBack();
    await settleThrough(tester, const Duration(milliseconds: 400));
    expect(find.text('Z'), findsAtLeastNWidgets(1));
    expect(find.text('R'), findsNothing);

    await unmount(tester);
  });

  testWidgets('switching the demo user updates every session reader',
      (tester) async {
    await pumpApp(tester);
    await settleThrough(tester, const Duration(milliseconds: 200));

    await tester.tap(find.byTooltip('Your profile'));
    await settleThrough(tester, const Duration(milliseconds: 400));

    await tester.tap(find.text('Switch demo user'));
    await settleThrough(tester, const Duration(milliseconds: 400));
    expect(find.text('jordan@team.dev'), findsOneWidget);

    await tester.pageBack();
    await settleThrough(tester, const Duration(milliseconds: 400));
    expect(find.text('J'), findsAtLeastNWidgets(1));

    await unmount(tester);
  });
}
