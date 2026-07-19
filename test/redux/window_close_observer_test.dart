import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:sidekick/global_keys.dart';
import 'package:sidekick/redux/actions/sync_actions.dart';
import 'package:sidekick/redux/app_store.dart';
import 'package:sidekick/theme/sidekick_color_scheme.dart';
import 'package:sidekick/window_close_observer.dart';

const _channel = MethodChannel('window_manager');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// Method calls the observer made on the plugin, in order.
  late List<String> pluginCalls;

  setUp(() {
    pluginCalls = [];

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, (call) async {
          pluginCalls.add(call.method);

          return switch (call.method) {
            'isPreventClose' => true,
            _ => null,
          };
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, null);

    // appStore is a global, so leave it clean for other tests.
    appStore.dispatch(NewProject());
  });

  /// Pumps the observer under a navigator reachable via [navigatorKey], then
  /// fires a close request at it.
  Future<void> pumpAndRequestClose(WidgetTester tester) async {
    await tester.pumpWidget(
      ShadcnApp(
        navigatorKey: navigatorKey,
        theme: const ThemeData.dark(colorScheme: sidekickDarkColorScheme),
        home: const WindowCloseObserver(child: SizedBox()),
      ),
    );

    final state = tester.state(find.byType(WindowCloseObserver)) as dynamic;

    state.onWindowClose();
    await tester.pumpAndSettle();
  }

  testWidgets('a clean project closes without prompting', (tester) async {
    await pumpAndRequestClose(tester);

    expect(find.text('Unsaved Changes'), findsNothing);
    expect(pluginCalls, contains('destroy'));
  });

  testWidgets('a dirty project prompts instead of closing', (tester) async {
    appStore.dispatch(SetMaxSequenceBreak('12'));
    expect(appStore.state.fileState.hasUnsavedChanges, isTrue);

    await pumpAndRequestClose(tester);

    expect(find.text('Unsaved Changes'), findsOneWidget);
    expect(pluginCalls, isNot(contains('destroy')));
  });

  testWidgets('dismissing the prompt via the barrier leaves the app running', (
    tester,
  ) async {
    appStore.dispatch(SetMaxSequenceBreak('12'));

    await pumpAndRequestClose(tester);

    // Tap the modal barrier, outside the dialog, to dismiss it.
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    expect(find.text('Unsaved Changes'), findsNothing);

    expect(pluginCalls, isNot(contains('destroy')));
    expect(appStore.state.fileState.hasUnsavedChanges, isTrue);
  });

  testWidgets('discarding closes without saving', (tester) async {
    appStore.dispatch(SetMaxSequenceBreak('12'));

    await pumpAndRequestClose(tester);
    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();

    expect(pluginCalls, contains('destroy'));
  });
}
